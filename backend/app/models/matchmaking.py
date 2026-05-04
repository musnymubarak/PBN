"""
Prime Business Network – Matchmaking Models.
"""

from __future__ import annotations

import enum
import uuid
from datetime import datetime
from typing import List, Optional

from sqlalchemy import Boolean, ForeignKey, String, Text, Float, JSON, DateTime
from sqlalchemy.dialects.postgresql import UUID, JSONB
from sqlalchemy.orm import Mapped, mapped_column, relationship

from app.models.base import Base, TimestampMixin


class MatchingProfile(Base, TimestampMixin):
    """
    Business matching profile (Bylaws Article 10).
    Extends user profile with business-specific matching data.
    """
    __tablename__ = "matching_profiles"

    user_id: Mapped[uuid.UUID] = mapped_column(
        UUID(as_uuid=True), ForeignKey("users.id", ondelete="CASCADE"), unique=True, nullable=False, index=True
    )
    business_description: Mapped[Optional[str]] = mapped_column(Text, nullable=True)
    services_offered: Mapped[List[str]] = mapped_column(JSONB, default=list, nullable=False)
    looking_for: Mapped[List[str]] = mapped_column(JSONB, default=list, nullable=False)
    target_sectors: Mapped[List[str]] = mapped_column(JSONB, default=list, nullable=False)
    
    matching_enabled: Mapped[bool] = mapped_column(Boolean, default=True, nullable=False)
    matching_preferences: Mapped[dict] = mapped_column(JSONB, default=dict, nullable=False)

    # Relationship to user
    user = relationship("User", backref="matching_profile", uselist=False)


class IndustryRelationshipType(str, enum.Enum):
    COMPLEMENTARY = "complementary"
    ADJACENT = "adjacent"
    NEUTRAL = "neutral"
    COMPETITOR = "competitor"


class IndustryRelationship(Base, TimestampMixin):
    """
    Defines complementarity between industry categories.
    Used for calculating industry fit score.
    """
    __tablename__ = "industry_relationships"

    industry_a_id: Mapped[uuid.UUID] = mapped_column(
        UUID(as_uuid=True), ForeignKey("industry_categories.id", ondelete="CASCADE"), nullable=False, index=True
    )
    industry_b_id: Mapped[uuid.UUID] = mapped_column(
        UUID(as_uuid=True), ForeignKey("industry_categories.id", ondelete="CASCADE"), nullable=False, index=True
    )
    relationship_type: Mapped[IndustryRelationshipType] = mapped_column(
        String(30), default=IndustryRelationshipType.COMPLEMENTARY, nullable=False
    )
    strength: Mapped[float] = mapped_column(Float, default=1.0, nullable=False)  # 0.0 to 1.0


class MatchSuggestionStatus(str, enum.Enum):
    PENDING = "pending"
    VIEWED = "viewed"
    ACCEPTED = "accepted"
    DISMISSED = "dismissed"


class MatchSuggestion(Base, TimestampMixin):
    """
    Stores pre-computed match suggestions for members.
    """
    __tablename__ = "match_suggestions"

    user_id: Mapped[uuid.UUID] = mapped_column(
        UUID(as_uuid=True), ForeignKey("users.id", ondelete="CASCADE"), nullable=False, index=True
    )
    matched_user_id: Mapped[uuid.UUID] = mapped_column(
        UUID(as_uuid=True), ForeignKey("users.id", ondelete="CASCADE"), nullable=False, index=True
    )
    score: Mapped[float] = mapped_column(Float, nullable=False)
    score_breakdown: Mapped[dict] = mapped_column(JSONB, default=dict, nullable=False)
    explanation: Mapped[Optional[str]] = mapped_column(Text, nullable=True)
    partnership_strategy: Mapped[Optional[str]] = mapped_column(Text, nullable=True)  # Gemini generated
    
    status: Mapped[MatchSuggestionStatus] = mapped_column(
        String(30), default=MatchSuggestionStatus.PENDING, nullable=False
    )
    context: Mapped[str] = mapped_column(String(50), default="general")  # general, forum_prep, notice_board
    
    expires_at: Mapped[Optional[datetime]] = mapped_column(DateTime(timezone=True), nullable=True)

    # Relationships
    user = relationship("User", foreign_keys=[user_id])
    matched_user = relationship("User", foreign_keys=[matched_user_id])
