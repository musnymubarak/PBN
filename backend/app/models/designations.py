"""
Prime Business Network – Governance Designations Model.

Designations (Bylaws Article 4) define specific leadership roles
within chapters and the overall platform.
"""

from __future__ import annotations

import enum
import uuid
from datetime import date
from sqlalchemy import Boolean, Enum, ForeignKey, String, Date
from sqlalchemy.dialects.postgresql import UUID
from sqlalchemy.orm import Mapped, mapped_column, relationship

from app.models.base import Base, TimestampMixin

class Designation(str, enum.Enum):
    CHAPTER_PRESIDENT = "chapter_president"
    CHAPTER_VICE_PRESIDENT = "chapter_vice_president"
    CHAPTER_SECRETARY = "chapter_secretary"
    CLUB_COORDINATOR = "club_coordinator"
    VP_OPERATIONS = "vp_operations"
    VP_GROWTH = "vp_growth"
    VP_COMMUNICATIONS = "vp_communications"
    PLATFORM_MANAGER = "platform_manager"

class UserDesignation(Base, TimestampMixin):
    __tablename__ = "user_designations"

    user_id: Mapped[uuid.UUID] = mapped_column(
        UUID(as_uuid=True), ForeignKey("users.id", ondelete="CASCADE"), nullable=False, index=True
    )
    designation: Mapped[Designation] = mapped_column(
        Enum(Designation, name="designation", create_type=True), nullable=False
    )
    chapter_id: Mapped[uuid.UUID | None] = mapped_column(
        UUID(as_uuid=True), ForeignKey("chapters.id", ondelete="CASCADE"), nullable=True
    )
    club_id: Mapped[uuid.UUID | None] = mapped_column(
        UUID(as_uuid=True), ForeignKey("horizontal_clubs.id", ondelete="CASCADE"), nullable=True
    )
    appointed_at: Mapped[date] = mapped_column(default=date.today, nullable=False)
    term_ends_at: Mapped[date | None] = mapped_column(Date, nullable=True)
    is_active: Mapped[bool] = mapped_column(Boolean, default=True, nullable=False)

    # Relationships
    user = relationship("User")
    chapter = relationship("Chapter")
    club = relationship("HorizontalClub")

    def __repr__(self) -> str:
        return f"<UserDesignation user={self.user_id} designation={self.designation.value}>"
