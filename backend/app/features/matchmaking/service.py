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

class CalculatedScore:
    def __init__(self, total_score: float, breakdown: dict, reasons: List[str]):
        self.total_score = total_score
        self.breakdown = breakdown
        self.reasons = reasons


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

    async def compute_match_score(self, user_id_1: uuid.UUID, user_id_2: uuid.UUID) -> CalculatedScore:
        """Helper for background tasks to calculate score between two arbitrary users."""
        u1_res = await self.db.execute(
            select(User).options(joinedload(User.matching_profile)).where(User.id == user_id_1)
        )
        u1 = u1_res.unique().scalar_one_or_none()
        
        u2_res = await self.db.execute(
            select(User).options(joinedload(User.matching_profile)).where(User.id == user_id_2)
        )
        u2 = u2_res.unique().scalar_one_or_none()
        
        if not u1 or not u2:
            return CalculatedScore(0.0, {}, [])
            
        m1_res = await self.db.execute(
            select(ChapterMembership).where(
                and_(ChapterMembership.user_id == user_id_1, ChapterMembership.is_active == True)
            )
        )
        m1 = m1_res.scalar_one_or_none()
        
        m2_res = await self.db.execute(
            select(ChapterMembership).where(
                and_(ChapterMembership.user_id == user_id_2, ChapterMembership.is_active == True)
            )
        )
        m2 = m2_res.scalar_one_or_none()
        
        if not m1 or not m2:
            return CalculatedScore(0.0, {}, [])
            
        rel_result = await self.db.execute(
            select(IndustryRelationship).where(
                or_(
                    IndustryRelationship.industry_a_id == m1.industry_category_id,
                    IndustryRelationship.industry_b_id == m1.industry_category_id
                )
            )
        )
        relationships = rel_result.scalars().all()
        rel_map = {}
        for r in relationships:
            other_id = r.industry_b_id if r.industry_a_id == m1.industry_category_id else r.industry_a_id
            rel_map[other_id] = r
            
        industry_names_result = await self.db.execute(
            select(IndustryCategory.id, IndustryCategory.name)
        )
        industry_name_map = {iid: name for iid, name in industry_names_result.all()}
        
        # Load referrals
        referrals_res = await self.db.execute(
            select(Referral).where(
                or_(
                    and_(Referral.from_member_id == user_id_1, Referral.to_member_id == user_id_2),
                    and_(Referral.from_member_id == user_id_2, Referral.to_member_id == user_id_1)
                )
            )
        )
        referrals = referrals_res.scalars().all()

        # Load shared clubs
        c1_res = await self.db.execute(
            select(HorizontalClubMembership.club_id).where(
                and_(HorizontalClubMembership.user_id == user_id_1, HorizontalClubMembership.is_active == True)
            )
        )
        c1_ids = set(c1_res.scalars().all())
        
        c2_res = await self.db.execute(
            select(HorizontalClubMembership.club_id).where(
                and_(HorizontalClubMembership.user_id == user_id_2, HorizontalClubMembership.is_active == True)
            )
        )
        c2_ids = set(c2_res.scalars().all())
        shared_club_ids = c1_ids.intersection(c2_ids)

        score, breakdown, reasons = await self._calculate_score(
            u1, m1, u2, m2, rel_map, industry_name_map,
            user_referrals=referrals,
            shared_club_ids=shared_club_ids
        )
        return CalculatedScore(score, breakdown, reasons)

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

        # 3c. Bulk-load referrals for the current user to prevent N+1 queries
        referrals_res = await self.db.execute(
            select(Referral).where(
                or_(
                    Referral.from_member_id == user_id,
                    Referral.to_member_id == user_id
                )
            )
        )
        referrals = referrals_res.scalars().all()
        referral_map = {}
        for r in referrals:
            other = r.to_member_id if r.from_member_id == user_id else r.from_member_id
            if other not in referral_map:
                referral_map[other] = []
            referral_map[other].append(r)

        # 3d. Bulk-load shared horizontal club memberships to prevent N+1 queries
        clubs_res = await self.db.execute(
            select(HorizontalClubMembership.club_id).where(
                and_(
                    HorizontalClubMembership.user_id == user_id,
                    HorizontalClubMembership.is_active == True
                )
            )
        )
        user_club_ids = set(clubs_res.scalars().all())
        
        all_clubs_res = await self.db.execute(
            select(HorizontalClubMembership.user_id, HorizontalClubMembership.club_id).where(
                HorizontalClubMembership.is_active == True
            )
        )
        other_clubs_map = {}
        for uid, cid in all_clubs_res.all():
            if uid not in other_clubs_map:
                other_clubs_map[uid] = set()
            other_clubs_map[uid].add(cid)

        # 4. Score each potential match
        suggestions = []
        for other_user, other_membership in others:
            try:
                other_id = other_user.id
                u_referrals = referral_map.get(other_id, [])
                u_shared_clubs = user_club_ids.intersection(other_clubs_map.get(other_id, set()))
                
                score, breakdown, reasons = await self._calculate_score(
                    user, user_membership,
                    other_user, other_membership,
                    rel_map,
                    industry_name_map,
                    user_referrals=u_referrals,
                    shared_club_ids=u_shared_clubs
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
            
            saved_suggestions.append(obj)

        await self.db.commit()
        return saved_suggestions

    async def _calculate_score(
        self, u1, m1, u2, m2, rel_map, industry_name_map,
        user_referrals: Optional[List[Referral]] = None,
        shared_club_ids: Optional[set] = None
    ):
        """Weighted scoring algorithm with Hybrid Semantic-Keyword profile similarity,
        shared horizontal club alignment, and transaction boost logic.

        Returns (score, breakdown, ordered_reasons).
        """
        if user_referrals is None:
            user_referrals = []
        if shared_club_ids is None:
            shared_club_ids = set()

        score = 0.0
        breakdown = {}

        # Weights
        W_INDUSTRY = 0.4
        W_CHAPTER = 0.2
        W_VERIFICATION = 0.1
        W_CLUBS = 0.1
        W_PROFILE = 0.2

        # Reason buckets
        r_industry: Optional[str] = None
        r_target_sector: Optional[str] = None
        r_profile: Optional[str] = None
        r_verification: Optional[str] = None
        r_quality: Optional[str] = None
        r_tenure: Optional[str] = None
        r_chapter: Optional[str] = None
        r_clubs: Optional[str] = None
        r_referrals: Optional[str] = None

        p1 = u1.matching_profile
        p2 = u2.matching_profile

        # 1. Industry Complementarity
        industry_score = 0.2  # Base neutral score
        other_industry_id = m2.industry_category_id

        # Target-sector check
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
            industry_score = 0.0  # Competitors
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
            industry_score = 0.6

        score += industry_score * W_INDUSTRY
        breakdown["industry"] = industry_score

        # 2. Chapter / Network Location
        chapter_score = 1.0
        if m1.chapter_id == m2.chapter_id:
            chapter_score = 0.3
            r_chapter = "Same chapter member"
        else:
            r_chapter = "Cross-chapter opportunity"

        score += chapter_score * W_CHAPTER
        breakdown["chapter"] = chapter_score

        # 3. Verification & Trust
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

        # 4. Profile & Needs — Hybrid Keyword + Semantic Matching
        profile_score = 0.2
        if p1 and p2:
            # Keyword matching
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
            keyword_score = 0.2
            if total > 0:
                keyword_score = min(1.0, 0.4 + (total * 0.2))

            # Semantic matching
            has_embeddings = (
                p1.looking_for_embedding is not None and p2.services_embedding is not None
            ) or (
                p2.looking_for_embedding is not None and p1.services_embedding is not None
            )

            if has_embeddings:
                sim_a_to_b = self._cosine_similarity(p1.looking_for_embedding, p2.services_embedding)
                sim_b_to_a = self._cosine_similarity(p2.looking_for_embedding, p1.services_embedding)
                semantic_score = max(sim_a_to_b, sim_b_to_a)
                
                # Hybrid: 60% semantic similarity + 40% keyword match
                profile_score = 0.6 * semantic_score + 0.4 * keyword_score
                
                if semantic_score > 0.65:
                    if sim_a_to_b > sim_b_to_a:
                        r_profile = "Strong semantic fit for your needs"
                    else:
                        r_profile = "Strong semantic match for your services"
            else:
                profile_score = keyword_score

            if not r_profile:
                if a_to_b > 0 and b_to_a > 0:
                    r_profile = "Mutual service fit"
                elif a_to_b > 0:
                    r_profile = "Matches your stated needs"
                elif b_to_a > 0:
                    r_profile = "You offer what they need"

        score += profile_score * W_PROFILE
        breakdown["profile"] = profile_score

        # 5. Shared Horizontal Clubs
        clubs_score = 0.0
        shared_clubs_count = len(shared_club_ids)
        if shared_clubs_count > 0:
            clubs_score = min(1.0, shared_clubs_count * 0.5)
            r_clubs = f"Shared horizontal club member ({shared_clubs_count} clubs)"
            
        score += clubs_score * W_CLUBS
        breakdown["clubs"] = clubs_score

        # 6. Referral & Transaction Interaction Boost
        interaction_boost = 0.0
        success_count = sum(1 for r in user_referrals if r.status == ReferralStatus.SUCCESS)
        active_count = sum(1 for r in user_referrals if r.status not in [ReferralStatus.SUCCESS, ReferralStatus.FAILED])
        
        if success_count > 0:
            interaction_boost += min(0.15, success_count * 0.05)
            r_referrals = "Proven referral partnership history"
        elif active_count > 0:
            interaction_boost += 0.05
            r_referrals = "Active business dialogue"
            
        score = min(1.0, score + interaction_boost)

        # 7. Profile Quality
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

        # 8. Tenure
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
            pass

        # Merge reasons in priority order
        ordered = [
            r for r in [
                r_industry,
                r_target_sector,
                r_profile,
                r_verification,
                r_referrals,
                r_clubs,
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

    def _cosine_similarity(self, v1: Optional[List[float]], v2: Optional[List[float]]) -> float:
        if not v1 or not v2:
            return 0.0
        try:
            dot_product = sum(a * b for a, b in zip(v1, v2))
            norm_v1 = sum(a * a for a in v1) ** 0.5
            norm_v2 = sum(b * b for b in v2) ** 0.5
            if norm_v1 == 0.0 or norm_v2 == 0.0:
                return 0.0
            return dot_product / (norm_v1 * norm_v2)
        except Exception as e:
            logger.error(f"Error computing cosine similarity: {e}")
            return 0.0

    async def enrich_and_embed_profile_task(self, user_id: uuid.UUID):
        """Asynchronously triggers the profile enrichment and embedding task."""
        from app.core.database import async_session_factory
        async with async_session_factory() as db:
            service = MatchmakingService(db)
            await service.enrich_and_embed_profile(user_id)

    async def enrich_and_embed_profile(self, user_id: uuid.UUID):
        """Extracts key tags using Gemini and computes embeddings for the profile."""
        profile = await self.get_or_create_profile(user_id)
        
        # 1. AI Profile Enrichment
        if profile.business_description and len(profile.business_description.strip()) > 10:
            enriched_services = await self._enrich_tags_via_gemini(
                text=profile.business_description,
                current_tags=profile.services_offered,
                tag_type="services_offered"
            )
            if enriched_services:
                # Merge and preserve unique
                profile.services_offered = list(set(profile.services_offered + enriched_services))
                
            enriched_looking_for = await self._enrich_tags_via_gemini(
                text=profile.business_description,
                current_tags=profile.looking_for,
                tag_type="looking_for"
            )
            if enriched_looking_for:
                profile.looking_for = list(set(profile.looking_for + enriched_looking_for))
                
        # 2. Semantic Embeddings
        services_text = ", ".join(profile.services_offered) if profile.services_offered else ""
        if profile.business_description:
            services_text += f"\nDescription: {profile.business_description}"
            
        looking_for_text = ", ".join(profile.looking_for) if profile.looking_for else ""
        
        if services_text.strip():
            profile.services_embedding = await self._generate_embedding_gemini(services_text)
            
        if looking_for_text.strip():
            profile.looking_for_embedding = await self._generate_embedding_gemini(looking_for_text)
            
        self.db.add(profile)
        await self.db.commit()
        logger.info(f"Generated semantic embeddings for user {user_id}")

    async def _generate_embedding_gemini(self, text: str) -> Optional[List[float]]:
        if not settings.GEMINI_API_KEY or not text.strip():
            return None
        import asyncio
        try:
            def _call():
                client = genai.Client(api_key=settings.GEMINI_API_KEY)
                response = client.models.embed_content(
                    model="gemini-embedding-2",
                    contents=text
                )
                if hasattr(response, "embeddings") and response.embeddings:
                    return response.embeddings[0].values
                return None
            return await asyncio.to_thread(_call)
        except Exception as e:
            logger.error(f"Failed to generate embedding: {e}")
            return None

    async def _enrich_tags_via_gemini(self, text: str, current_tags: List[str], tag_type: str) -> List[str]:
        if not settings.GEMINI_API_KEY or not text.strip():
            return []
        import asyncio
        import json
        
        prompt = f"""Given the following business description:
"{text}"

Identify relevant, concise keyword tags (under 3 words per tag) for: {tag_type}.
Already defined tags: {current_tags}
Return up to 5 additional highly specific tags in a JSON array of strings format.
Return ONLY the JSON array of strings e.g. ["tag1", "tag2"]."""
        
        try:
            def _call():
                client = genai.Client(api_key=settings.GEMINI_API_KEY)
                response = client.models.generate_content(
                    model="gemini-2.5-flash-lite",
                    contents=prompt
                )
                if not response.text:
                    return "[]"
                clean_text = response.text.strip()
                if clean_text.startswith("```"):
                    clean_text = clean_text.split("\n", 1)[-1].rsplit("\n", 1)[0].strip()
                    if clean_text.startswith("json"):
                        clean_text = clean_text[4:].strip()
                return clean_text
            json_str = await asyncio.to_thread(_call)
            tags = json.loads(json_str)
            if isinstance(tags, list):
                return [str(t).strip() for t in tags if t]
            return []
        except Exception as e:
            logger.error(f"Failed to enrich tags: {e}")
            return []
