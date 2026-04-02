"""
Prime Business Network – Chapter Membership Model.

UNIQUE CONSTRAINT: one member per industry per chapter.
"""

from __future__ import annotations

import enum
import uuid
from datetime import date

from sqlalchemy import Boolean, Date, Enum, ForeignKey, UniqueConstraint
from sqlalchemy.dialects.postgresql import UUID
from sqlalchemy.orm import Mapped, mapped_column

from app.models.base import Base, TimestampMixin


class MembershipType(str, enum.Enum):
    CHARTER = "charter"
    STANDARD = "standard"


class ChapterMembership(Base, TimestampMixin):
    __tablename__ = "chapter_memberships"

    user_id: Mapped[uuid.UUID] = mapped_column(
        UUID(as_uuid=True), ForeignKey("users.id", ondelete="CASCADE"), nullable=False, index=True
    )
    chapter_id: Mapped[uuid.UUID] = mapped_column(
        UUID(as_uuid=True), ForeignKey("chapters.id", ondelete="CASCADE"), nullable=False, index=True
    )
    industry_category_id: Mapped[uuid.UUID] = mapped_column(
        UUID(as_uuid=True), ForeignKey("industry_categories.id"), nullable=False
    )
    membership_type: Mapped[MembershipType] = mapped_column(
        Enum(MembershipType, name="membership_type", create_type=True),
        nullable=False,
        default=MembershipType.STANDARD,
    )
    start_date: Mapped[date] = mapped_column(Date, nullable=False)
    end_date: Mapped[date | None] = mapped_column(Date, nullable=True)
    is_active: Mapped[bool] = mapped_column(Boolean, default=True, nullable=False)

    __table_args__ = (
        UniqueConstraint(
            "chapter_id", "industry_category_id",
            name="unique_industry_per_chapter",
        ),
    )

    def __repr__(self) -> str:
        return f"<Membership user={self.user_id} chapter={self.chapter_id}>"
