"""
Prime Business Network – Horizontal Club Models.

Horizontal Clubs (Bylaws Article 6) are cross-industry clubs
extending from Primary Chapters to create deeper ecosystem density.
"""

from __future__ import annotations

import uuid
from datetime import date
from sqlalchemy import Boolean, ForeignKey, String, Text, UniqueConstraint
from sqlalchemy.dialects.postgresql import UUID
from sqlalchemy.orm import Mapped, mapped_column, relationship

from app.models.base import Base, TimestampMixin

class HorizontalClub(Base, TimestampMixin):
    __tablename__ = "horizontal_clubs"

    name: Mapped[str] = mapped_column(String(150), nullable=False)
    description: Mapped[str | None] = mapped_column(Text, nullable=True)
    target_vertical: Mapped[str] = mapped_column(String(100), nullable=False) # e.g. "real_estate"
    coordinator_user_id: Mapped[uuid.UUID | None] = mapped_column(
        UUID(as_uuid=True), ForeignKey("users.id", ondelete="SET NULL"), nullable=True
    )
    is_active: Mapped[bool] = mapped_column(Boolean, default=True, nullable=False)
    min_members: Mapped[int] = mapped_column(default=5, nullable=False) # Article 6.7

    # Relationships
    coordinator = relationship("User")
    memberships = relationship("HorizontalClubMembership", back_populates="club", cascade="all, delete-orphan")

    def __repr__(self) -> str:
        return f"<HorizontalClub {self.name}>"

class HorizontalClubMembership(Base, TimestampMixin):
    __tablename__ = "horizontal_club_memberships"

    club_id: Mapped[uuid.UUID] = mapped_column(
        UUID(as_uuid=True), ForeignKey("horizontal_clubs.id", ondelete="CASCADE"), nullable=False, index=True
    )
    user_id: Mapped[uuid.UUID] = mapped_column(
        UUID(as_uuid=True), ForeignKey("users.id", ondelete="CASCADE"), nullable=False, index=True
    )
    is_active: Mapped[bool] = mapped_column(Boolean, default=True, nullable=False)
    joined_at: Mapped[date] = mapped_column(default=date.today, nullable=False)

    # Relationships
    club = relationship("HorizontalClub", back_populates="memberships")
    user = relationship("User")

    __table_args__ = (
        UniqueConstraint("club_id", "user_id", name="unique_club_member"),
    )

    def __repr__(self) -> str:
        return f"<HorizontalClubMembership user={self.user_id} club={self.club_id}>"
