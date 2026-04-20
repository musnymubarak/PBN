"""
Prime Business Network – Community Models.

Handles Chapter-scoped social feed including posts, likes, and comments.
"""

from __future__ import annotations

import uuid
from typing import List

from sqlalchemy import Boolean, ForeignKey, String, Text, UniqueConstraint
from sqlalchemy.dialects.postgresql import UUID
from sqlalchemy.orm import Mapped, mapped_column, relationship

from app.models.base import Base, TimestampMixin


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

    # Relationships
    author = relationship("User", lazy="joined")
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
