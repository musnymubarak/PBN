import uuid
import logging
from datetime import datetime, timedelta
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
                    ChapterMembership.is_active == True
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

        # 4. Score each potential match
        suggestions = []
        for other_user, other_membership in others:
            try:
                score, breakdown, reasons = await self._calculate_score(
                    user, user_membership, 
                    other_user, other_membership,
                    rel_map
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
            
            # Generate Gemini Strategy if possible
            if settings.GEMINI_API_KEY:
                # We do this asynchronously or in background usually, but for now we do it here
                # Better to do it on demand when user views the match to save tokens
                pass 
                
            saved_suggestions.append(obj)

        await self.db.commit()
        return saved_suggestions

    async def _calculate_score(self, u1, m1, u2, m2, rel_map):
        """Weighted scoring algorithm."""
        score = 0.0
        breakdown = {}
        reasons = []

        # Weights
        W_INDUSTRY = 0.4
        W_CHAPTER = 0.2
        W_VERIFICATION = 0.1
        W_CLUBS = 0.1
        W_PROFILE = 0.2

        # 1. Industry Complementarity (The most important)
        industry_score = 0.2 # Base neutral score
        other_industry_id = m2.industry_category_id
        
        if m1.industry_category_id == m2.industry_category_id:
            industry_score = 0.0 # Competitors in same industry
            reasons.append("Same industry (competitors)")
        elif other_industry_id in rel_map:
            rel = rel_map[other_industry_id]
            if rel.relationship_type == IndustryRelationshipType.COMPLEMENTARY:
                industry_score = 1.0 * rel.strength
                reasons.append("High industry complementarity")
            elif rel.relationship_type == IndustryRelationshipType.ADJACENT:
                industry_score = 0.6 * rel.strength
                reasons.append("Adjacent industry sectors")
        
        score += industry_score * W_INDUSTRY
        breakdown["industry"] = industry_score

        # 2. Chapter / Network Gap (Priority for different chapters)
        chapter_score = 1.0
        if m1.chapter_id == m2.chapter_id:
            chapter_score = 0.3 # Already in same chapter, low priority
            reasons.append("Same chapter member")
        else:
            reasons.append("Cross-chapter opportunity")
        
        score += chapter_score * W_CHAPTER
        breakdown["chapter"] = chapter_score

        # 3. Verification & Trust
        v_map = {
            VerificationLevel.NONE: 0.1,
            VerificationLevel.VERIFIED: 0.5,
            VerificationLevel.SILVER: 0.7,
            VerificationLevel.GOLD: 0.9,
            VerificationLevel.PLATINUM: 1.0
        }
        v_score = v_map.get(u2.verification_level, 0.1)
        score += v_score * W_VERIFICATION
        breakdown["verification"] = v_score
        if v_score >= 0.7:
            reasons.append(f"Highly verified {u2.verification_level.value} creator")

        # 4. Profile & Needs (Basic keyword matching)
        profile_score = 0.2
        p1 = u1.matching_profile
        p2 = u2.matching_profile
        
        if p1 and p2:
            # Check if B offers what A is looking for
            matches_count = 0
            for need in p1.looking_for:
                for offer in p2.services_offered:
                    if need.lower() in offer.lower() or offer.lower() in need.lower():
                        matches_count += 1
            
            if matches_count > 0:
                profile_score = min(1.0, 0.4 + (matches_count * 0.2))
                reasons.append("Matches your stated needs")
            
            # Target sector overlap
            for sector in p1.target_sectors:
                # This would need industry name check
                pass

        score += profile_score * W_PROFILE
        breakdown["profile"] = profile_score

        return min(1.0, score), breakdown, reasons

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
        if match.partnership_strategy:
            return match.partnership_strategy

        u1 = match.user
        u2 = match.matched_user
        
        # Get industries
        m1_res = await self.db.execute(select(IndustryCategory).join(ChapterMembership).where(ChapterMembership.user_id == u1.id))
        ind1 = m1_res.scalar_one_or_none()
        m2_res = await self.db.execute(select(IndustryCategory).join(ChapterMembership).where(ChapterMembership.user_id == u2.id))
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
            # Use the new google-genai SDK with gemini-2.0-flash
            def _call_gemini():
                client = genai.Client(api_key=settings.GEMINI_API_KEY)
                response = client.models.generate_content(
                    model="gemini-2.5-flash",
                    contents=prompt
                )
                return response.text.strip()

            strategy = await asyncio.to_thread(_call_gemini)
            logger.info(f"Gemini strategy generated for match {match_id}: {strategy[:50]}...")
            
            match.partnership_strategy = strategy
            await self.db.commit()
            return strategy
        except Exception as e:
            error_str = str(e)
            logger.error(f"Gemini API Error for match {match_id}: {type(e).__name__}: {e}")
            if "429" in error_str or "RESOURCE_EXHAUSTED" in error_str:
                return "AI quota temporarily exceeded. Please wait a minute and try again."
            return "Failed to generate AI strategy. Please try again later."
