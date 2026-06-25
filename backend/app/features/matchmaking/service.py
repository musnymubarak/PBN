import uuid
import logging
from datetime import datetime, timedelta, timezone
from typing import List, Optional, Dict, Any
from decimal import Decimal

from sqlalchemy import select, and_, or_, func
from sqlalchemy.ext.asyncio import AsyncSession
from sqlalchemy.orm import joinedload

from app.models.user import User, VerificationLevel
from app.models.matchmaking import (
    MatchingProfile, 
    IndustryRelationship, 
    IndustryRelationshipType,
    MatchSuggestion,
    MatchSuggestionStatus
)
from app.models.memberships import ChapterMembership
from app.models.industry_categories import IndustryCategory
from app.models.referrals import Referral, ReferralStatus
from app.models.horizontal_clubs import HorizontalClubMembership
from app.core.config import get_settings

from google import genai

logger = logging.getLogger(__name__)
settings = get_settings()

class MatchmakingService:
    def __init__(self, db: AsyncSession):
        self.db = db

    async def get_or_create_profile(self, user_id: uuid.UUID) -> MatchingProfile:
        """Fetch matching profile or create default if missing."""
        result = await self.db.execute(
            select(MatchingProfile).where(MatchingProfile.user_id == user_id)
        )
        profile = result.unique().scalar_one_or_none()
        
        if not profile:
            profile = MatchingProfile(user_id=user_id)
            self.db.add(profile)
            await self.db.commit()
            await self.db.refresh(profile)
            
        return profile

    async def update_profile(self, user_id: uuid.UUID, data: Dict[str, Any]) -> MatchingProfile:
        """Update matching profile."""
        profile = await self.get_or_create_profile(user_id)
        for key, value in data.items():
            if hasattr(profile, key):
                setattr(profile, key, value)
        
        await self.db.commit()
        await self.db.refresh(profile)
        return profile

    async def compute_matches_for_user(self, user_id: uuid.UUID, limit: int = 10):
        """
        The Core Matching Engine.
        Computes compatibility scores against all other active members.
        """
        logger.info(f"Starting match computation for user {user_id}")
        # 1. Get current user data
        user_result = await self.db.execute(
            select(User).options(joinedload(User.matching_profile)).where(User.id == user_id)
        )
        user = user_result.unique().scalar_one()
        
        # Get user chapter and industry
        membership_result = await self.db.execute(
            select(ChapterMembership).where(
                and_(ChapterMembership.user_id == user_id, ChapterMembership.is_active == True)
            )
        )
        user_membership = membership_result.scalar_one_or_none()
        if not user_membership:
            logger.warning(f"User {user_id} has no active chapter membership. Skipping matches.")
            return [] # No industry seat, no matches (as per PBN model)

        user_chapter_id = user_membership.chapter_id
        user_industry_id = user_membership.industry_category_id
        logger.info(f"User industry: {user_industry_id}, Chapter: {user_chapter_id}")

        # 2. Get all other active members
        # We only match with active members who have industry seats
        others_query = (
            select(User, ChapterMembership)
            .join(ChapterMembership, User.id == ChapterMembership.user_id)
            .where(
                and_(
                    User.id != user_id,
                    User.is_active == True,
                    ChapterMembership.is_active == True,
                    User.full_name.not_ilike("%system lock%")
                )
            )
            .options(joinedload(User.matching_profile))
        )
        others_result = await self.db.execute(others_query)
        others = others_result.unique().all()
        logger.info(f"Found {len(others)} other active members to compare")

        # 3. Get relationship data for industry fit
        rel_result = await self.db.execute(
            select(IndustryRelationship).where(
                or_(
                    IndustryRelationship.industry_a_id == user_industry_id,
                    IndustryRelationship.industry_b_id == user_industry_id
                )
            )
        )
        relationships = rel_result.scalars().all()
        rel_map = {}
        for r in relationships:
            other_id = r.industry_b_id if r.industry_a_id == user_industry_id else r.industry_a_id
            rel_map[other_id] = r
        logger.info(f"Loaded {len(rel_map)} industry relationships")

        # 3b. Bulk-load industry names so target-sector reason matching can
        # compare u2's industry against u1's target_sectors free-text list.
        industry_names_result = await self.db.execute(
            select(IndustryCategory.id, IndustryCategory.name)
        )
        industry_name_map = {iid: name for iid, name in industry_names_result.all()}

        # 4. Score each potential match
        suggestions = []
        for other_user, other_membership in others:
            try:
                score, breakdown, reasons = await self._calculate_score(
                    user, user_membership,
                    other_user, other_membership,
                    rel_map,
                    industry_name_map,
                )
                
                if score > 0.3: # Minimum threshold
                    suggestions.append({
                        "user_id": user_id,
                        "matched_user_id": other_user.id,
                        "score": score,
                        "score_breakdown": breakdown,
                        "explanation": " • ".join(reasons[:3])
                    })
            except Exception as e:
                logger.error(f"Error scoring match between {user_id} and {other_user.id}: {e}")

        # Sort and take top matches
        suggestions.sort(key=lambda x: x["score"], reverse=True)
        top_matches = suggestions[:limit]
        logger.info(f"Computed top {len(top_matches)} matches")

        # 5. Save suggestions and generate Gemini strategies
        saved_suggestions = []
        for match in top_matches:
            # Check if exists
            existing_result = await self.db.execute(
                select(MatchSuggestion).where(
                    and_(
                        MatchSuggestion.user_id == user_id,
                        MatchSuggestion.matched_user_id == match["matched_user_id"]
                    )
                )
            )
            existing = existing_result.scalar_one_or_none()
            
            if existing:
                existing.score = match["score"]
                existing.score_breakdown = match["score_breakdown"]
                existing.explanation = match["explanation"]
                existing.status = MatchSuggestionStatus.PENDING # Reset to pending if recomputed
                obj = existing
            else:
                obj = MatchSuggestion(**match)
                self.db.add(obj)
            
            # IMPORTANT: do NOT generate Gemini strategies here.
            # Strategies are generated lazily in `get_partnership_strategy()`
            # the first time the user opens the match — then cached on the row
            # so subsequent views never hit Gemini again. This keeps free-tier
            # quota usage proportional to user engagement, not match volume.
            saved_suggestions.append(obj)

        await self.db.commit()
        return saved_suggestions

    async def _calculate_score(self, u1, m1, u2, m2, rel_map, industry_name_map):
        """Weighted scoring algorithm.

        Returns (score, breakdown, ordered_reasons). The caller joins the first
        three entries from `ordered_reasons` into the suggestion's `explanation`
        field — so reason ordering matters: highest-signal pushers go first,
        and `r_chapter` goes last because it fires for almost every pair and
        is the least-informative reason when it stands alone.
        """
        score = 0.0
        breakdown = {}

        # Weights
        W_INDUSTRY = 0.4
        W_CHAPTER = 0.2
        W_VERIFICATION = 0.1
        W_CLUBS = 0.1  # Reserved for future shared-horizontal-club bonus
        W_PROFILE = 0.2

        # Reason buckets — merged in priority order at the bottom of the function.
        r_industry: Optional[str] = None
        r_target_sector: Optional[str] = None
        r_profile: Optional[str] = None
        r_verification: Optional[str] = None
        r_quality: Optional[str] = None
        r_tenure: Optional[str] = None
        r_chapter: Optional[str] = None

        p1 = u1.matching_profile
        p2 = u2.matching_profile

        # 1. Industry Complementarity (the strongest signal when it fires)
        industry_score = 0.2  # Base neutral score
        other_industry_id = m2.industry_category_id

        # Detect target-sector match first — used both as a reason and as a
        # score fallback when no predefined industry_relationship row exists.
        target_sector_match = False
        if p1 and p1.target_sectors and other_industry_id:
            other_industry_name = industry_name_map.get(other_industry_id, "")
            if other_industry_name:
                name_lower = other_industry_name.lower()
                if any(
                    name_lower in str(s).lower() or str(s).lower() in name_lower
                    for s in p1.target_sectors if s
                ):
                    target_sector_match = True
                    r_target_sector = "In your target sectors"

        if m1.industry_category_id == m2.industry_category_id:
            industry_score = 0.0  # Competitors in same industry
            r_industry = "Same industry (competitors)"
        elif other_industry_id in rel_map:
            rel = rel_map[other_industry_id]
            if rel.relationship_type == IndustryRelationshipType.COMPLEMENTARY:
                industry_score = 1.0 * rel.strength
                r_industry = "High industry complementarity"
            elif rel.relationship_type == IndustryRelationshipType.ADJACENT:
                industry_score = 0.6 * rel.strength
                r_industry = "Adjacent industry sectors"
        elif target_sector_match:
            # No predefined relationship row, but the user explicitly listed this
            # industry as a target — treat as a user-overridable adjacent signal.
            industry_score = 0.6

        score += industry_score * W_INDUSTRY
        breakdown["industry"] = industry_score

        # 2. Chapter / Network Gap (cross-chapter is the higher-value case)
        chapter_score = 1.0
        if m1.chapter_id == m2.chapter_id:
            chapter_score = 0.3  # Already in same chapter, lower marginal value
            r_chapter = "Same chapter member"
        else:
            r_chapter = "Cross-chapter opportunity"

        score += chapter_score * W_CHAPTER
        breakdown["chapter"] = chapter_score

        # 3. Verification & Trust — graded so verified+ users always earn a reason
        v_map = {
            VerificationLevel.NONE: 0.1,
            VerificationLevel.VERIFIED: 0.5,
            VerificationLevel.SILVER: 0.7,
            VerificationLevel.GOLD: 0.9,
            VerificationLevel.PLATINUM: 1.0,
        }
        v_score = v_map.get(u2.verification_level, 0.1)
        score += v_score * W_VERIFICATION
        breakdown["verification"] = v_score

        v_value = u2.verification_level.value if u2.verification_level else None
        if v_score >= 0.9 and v_value:
            r_verification = f"Top-tier {v_value} member"
        elif v_score >= 0.7 and v_value:
            r_verification = f"Verified {v_value} member"
        elif v_score >= 0.5:
            r_verification = "Verified member"

        # 4. Profile & Needs — bi-directional keyword matching
        profile_score = 0.2
        if p1 and p2:
            a_to_b = sum(
                1
                for need in (p1.looking_for or [])
                for offer in (p2.services_offered or [])
                if need and offer and (
                    need.lower() in offer.lower() or offer.lower() in need.lower()
                )
            )
            b_to_a = sum(
                1
                for need in (p2.looking_for or [])
                for offer in (p1.services_offered or [])
                if need and offer and (
                    need.lower() in offer.lower() or offer.lower() in need.lower()
                )
            )
            total = a_to_b + b_to_a
            if total > 0:
                profile_score = min(1.0, 0.4 + (total * 0.2))

            if a_to_b > 0 and b_to_a > 0:
                r_profile = "Mutual service fit"
            elif a_to_b > 0:
                r_profile = "Matches your stated needs"
            elif b_to_a > 0:
                r_profile = "You offer what they need"

        score += profile_score * W_PROFILE
        breakdown["profile"] = profile_score

        # 5. Profile quality (explanation-only — no score impact, signals depth)
        if p2:
            has_description = bool(
                p2.business_description
                and len(p2.business_description.strip()) > 50
            )
            service_count = len(p2.services_offered or [])
            if has_description:
                r_quality = "Detailed business profile"
            elif service_count >= 4:
                r_quality = "Diversified service offering"

        # 6. Tenure signal (explanation-only, best-effort)
        try:
            if u2.created_at:
                created = u2.created_at
                if created.tzinfo is None:
                    created = created.replace(tzinfo=timezone.utc)
                age = datetime.now(timezone.utc) - created
                if age > timedelta(days=365):
                    r_tenure = "Senior network member"
                elif age < timedelta(days=30):
                    r_tenure = "New to the network"
        except Exception:
            pass  # Never block a match for a date arithmetic edge case

        # Merge reasons in priority order — caller takes [:3].
        ordered = [
            r for r in [
                r_industry,
                r_target_sector,
                r_profile,
                r_verification,
                r_quality,
                r_tenure,
                r_chapter,
            ]
            if r
        ]

        return min(1.0, score), breakdown, ordered

    # Strings that look like stored strategies but are actually error fallbacks
    # from earlier failed Gemini calls. If we find any of these in the DB they
    # must be treated as unset so we retry generation instead of serving the
    # stale error forever. The success path below overwrites them in place.
    _STRATEGY_ERROR_SENTINELS = (
        "AI quota temporarily exceeded",
        "The AI is busy right now",
        "Failed to generate AI strategy",
        "AI strategy generation is currently disabled",
        "No strategy could be generated",
        "Error loading strategy",
    )

    @classmethod
    def _is_stored_error(cls, text: Optional[str]) -> bool:
        if not text:
            return False
        for sentinel in cls._STRATEGY_ERROR_SENTINELS:
            if text.startswith(sentinel):
                return True
        return False

    async def get_partnership_strategy(self, match_id: uuid.UUID) -> str:
        """Generate AI partnership strategy using Gemini."""
        import asyncio

        if not settings.GEMINI_API_KEY:
            logger.warning("GEMINI_API_KEY not set")
            return "AI strategy generation is currently disabled."

        result = await self.db.execute(
            select(MatchSuggestion)
            .options(
                joinedload(MatchSuggestion.user).joinedload(User.matching_profile),
                joinedload(MatchSuggestion.matched_user).joinedload(User.matching_profile)
            )
            .where(MatchSuggestion.id == match_id)
        )
        match = result.unique().scalar_one_or_none()
        if not match:
            logger.warning(f"Match {match_id} not found")
            return ""

        # Cache hit — but only if it's a real strategy, not an old error
        # message that an earlier code path mistakenly persisted. Poisoned
        # rows fall through to regeneration below; the success-path commit
        # overwrites them with the new strategy.
        if match.partnership_strategy and not self._is_stored_error(match.partnership_strategy):
            return match.partnership_strategy
        if self._is_stored_error(match.partnership_strategy):
            logger.info(
                f"Match {match_id} has stale error text in partnership_strategy; regenerating"
            )

        u1 = match.user
        u2 = match.matched_user
        
        # Get industries (only active memberships)
        m1_res = await self.db.execute(
            select(IndustryCategory)
            .join(ChapterMembership)
            .where(and_(ChapterMembership.user_id == u1.id, ChapterMembership.is_active == True))
        )
        ind1 = m1_res.scalar_one_or_none()
        
        m2_res = await self.db.execute(
            select(IndustryCategory)
            .join(ChapterMembership)
            .where(and_(ChapterMembership.user_id == u2.id, ChapterMembership.is_active == True))
        )
        ind2 = m2_res.scalar_one_or_none()

        prompt = f"""Analyze these two business owners in the Prime Business Network (PBN) and suggest a specific partnership strategy.

MEMBER A:
Name: {u1.full_name}
Industry: {ind1.name if ind1 else 'Unknown'}
Services: {', '.join(u1.matching_profile.services_offered) if u1.matching_profile else 'Not listed'}
Looking for: {', '.join(u1.matching_profile.looking_for) if u1.matching_profile else 'Not listed'}

MEMBER B:
Name: {u2.full_name}
Industry: {ind2.name if ind2 else 'Unknown'}
Services: {', '.join(u2.matching_profile.services_offered) if u2.matching_profile else 'Not listed'}
Looking for: {', '.join(u2.matching_profile.looking_for) if u2.matching_profile else 'Not listed'}

Task: Suggest 2-3 high-value ways they can CREATE BUSINESS TOGETHER. 
Focus on referral paths, co-branding, or joint service delivery.
Keep the response professional, encouraging, and under 60 words.
Format: Return only the suggestion text."""

        try:
            # Using gemini-2.5-flash-lite:
            #   - gemini-2.0-flash was removed from the free tier (limit: 0)
            #   - gemini-2.5-flash has "thinking" enabled by default which
            #     blew past the proxy timeout (502) for our use case
            #   - flash-lite has thinking off by default → fast responses,
            #     and the free tier is generous (lighter model = more quota)
            # If this also fails, escalate to "gemini-1.5-flash", or enable
            # billing for ~$0.0001 per strategy.
            def _call_gemini():
                client = genai.Client(api_key=settings.GEMINI_API_KEY)
                response = client.models.generate_content(
                    model="gemini-2.5-flash-lite",
                    contents=prompt
                )
                if not response.text:
                    return "No strategy could be generated at this time."
                return response.text.strip()

            strategy = await asyncio.to_thread(_call_gemini)
            logger.info(f"Gemini strategy generated for match {match_id}: {strategy[:50]}...")
            
            match.partnership_strategy = strategy
            await self.db.commit()
            return strategy
        except Exception as e:
            error_str = str(e)
            logger.error(f"Gemini API Error for match {match_id}: {type(e).__name__}: {e}")
            # Important: do NOT save the error text to match.partnership_strategy.
            # Returning the message lets the user retry — the next tap will hit
            # Gemini again and the success result will be cached on the row.
            if "429" in error_str or "RESOURCE_EXHAUSTED" in error_str:
                # Free-tier `gemini-2.0-flash` is throttled at 15 RPM. Most 429s
                # here are per-minute bursts, not the daily cap.
                return (
                    "The AI is busy right now (rate-limited). "
                    "Please wait about a minute and try again."
                )
            return "Failed to generate AI strategy. Please try again later."
