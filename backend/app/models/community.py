"""
Prime Business Network – Community Models.

Handles Chapter-scoped social feed including posts, likes, and comments.
"""

from __future__ import annotations

import uuid
from datetime import datetime
from typing import List

import enum
from sqlalchemy import Boolean, ForeignKey, String, Text, UniqueConstraint, Enum, Numeric, DateTime
from sqlalchemy.dialects.postgresql import UUID
from sqlalchemy.orm import Mapped, mapped_column, relationship

from app.models.base import Base, TimestampMixin


class PostType(str, enum.Enum):
    GENERAL = "general"
    LEAD = "lead"
    RFP = "rfp"


class PostVisibility(str, enum.Enum):
    CHAPTER = "chapter"
    NETWORK = "network"
    CLUB = "club"


class LeadStatus(str, enum.Enum):
    OPEN = "open"
    IN_PROGRESS = "in_progress"
    CLOSED_WON = "closed_won"
    CLOSED_LOST = "closed_lost"


class CommunityPost(Base, TimestampMixin):
    __tablename__ = "community_posts"

    chapter_id: Mapped[uuid.UUID] = mapped_column(
        UUID(as_uuid=True), ForeignKey("chapters.id", ondelete="CASCADE"), nullable=False, index=True
    )
    author_id: Mapped[uuid.UUID] = mapped_column(
        UUID(as_uuid=True), ForeignKey("users.id", ondelete="CASCADE"), nullable=False, index=True
    )
    content: Mapped[str] = mapped_column(Text, nullable=False)
    image_url: Mapped[str | None] = mapped_column(String(500), nullable=True)
    is_pinned: Mapped[bool] = mapped_column(Boolean, default=False, nullable=False)
    is_active: Mapped[bool] = mapped_column(Boolean, default=True, nullable=False)

    # Economic Engine Fields
    post_type: Mapped[PostType] = mapped_column(
        Enum(PostType), default=PostType.GENERAL, nullable=False, index=True
    )
    visibility: Mapped[PostVisibility] = mapped_column(
        Enum(PostVisibility), default=PostVisibility.CHAPTER, nullable=False, index=True
    )
    lead_status: Mapped[LeadStatus | None] = mapped_column(
        Enum(LeadStatus), nullable=True, index=True
    )
    
    target_club_id: Mapped[uuid.UUID | None] = mapped_column(
        UUID(as_uuid=True), ForeignKey("horizontal_clubs.id", ondelete="SET NULL"), nullable=True
    )
    target_industry_id: Mapped[uuid.UUID | None] = mapped_column(
        UUID(as_uuid=True), ForeignKey("industry_categories.id", ondelete="SET NULL"), nullable=True
    )
    
    budget_range: Mapped[str | None] = mapped_column(String(100), nullable=True)
    deadline: Mapped[datetime | None] = mapped_column(DateTime, nullable=True)
    
    # Thank You For Business (TYFB) Value
    business_value: Mapped[float | None] = mapped_column(Numeric(15, 2), nullable=True)

    # Relationships
    author = relationship("User", lazy="joined")
    target_club = relationship("HorizontalClub", lazy="joined")
    target_industry = relationship("IndustryCategory", lazy="joined")
    likes = relationship("PostLike", back_populates="post", cascade="all, delete-orphan")
    comments = relationship("PostComment", back_populates="post", cascade="all, delete-orphan", order_by="PostComment.created_at")

    def __repr__(self) -> str:
        return f"<CommunityPost id={self.id} author={self.author_id}>"


class PostLike(Base, TimestampMixin):
    __tablename__ = "post_likes"

    post_id: Mapped[uuid.UUID] = mapped_column(
        UUID(as_uuid=True), ForeignKey("community_posts.id", ondelete="CASCADE"), nullable=False, index=True
    )
    user_id: Mapped[uuid.UUID] = mapped_column(
        UUID(as_uuid=True), ForeignKey("users.id", ondelete="CASCADE"), nullable=False, index=True
    )

    # Relationships
    post = relationship("CommunityPost", back_populates="likes")

    __table_args__ = (
        UniqueConstraint("post_id", "user_id", name="unique_user_post_like"),
    )


class PostComment(Base, TimestampMixin):
    __tablename__ = "post_comments"

    post_id: Mapped[uuid.UUID] = mapped_column(
        UUID(as_uuid=True), ForeignKey("community_posts.id", ondelete="CASCADE"), nullable=False, index=True
    )
    author_id: Mapped[uuid.UUID] = mapped_column(
        UUID(as_uuid=True), ForeignKey("users.id", ondelete="CASCADE"), nullable=False, index=True
    )
    content: Mapped[str] = mapped_column(Text, nullable=False)

    # Relationships
    post = relationship("CommunityPost", back_populates="comments")
    author = relationship("User", lazy="joined")

    def __repr__(self) -> str:
        return f"<PostComment id={self.id} author={self.author_id}>"
