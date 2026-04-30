"""
Prime Business Network – Chapter Membership Model.

UNIQUE CONSTRAINT: one member per industry per chapter.

Membership Categories (Bylaws Article 8):
  - Charter:       Founding seat, locked LKR 15,000 rate
  - Standard:      Post-launch, LKR 25,000/year
  - Founders Club: Premium tier, LKR 50,000/year
  - Associate:     No industry seat, community participation
  - Corporate:     Multi-chapter access for corporates
"""

from __future__ import annotations

import enum
import uuid
from datetime import date
from decimal import Decimal

from sqlalchemy import Boolean, Date, Enum, ForeignKey, Numeric, String, UniqueConstraint
from sqlalchemy.dialects.postgresql import UUID
from sqlalchemy.orm import Mapped, mapped_column

from app.models.base import Base, TimestampMixin


class MembershipType(str, enum.Enum):
    CHARTER = "charter"
    STANDARD = "standard"
    FOUNDERS_CLUB = "founders_club"
    ASSOCIATE = "associate"
    CORPORATE = "corporate"


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
        return f"<Membership user={self.user_id} chapter={self.chapter_id} type={self.membership_type.value}>"


class FeeSchedule(Base, TimestampMixin):
    """
    Fee schedule per membership tier (Bylaws Article 8.2).

    Charter Members have a LOCKED rate of LKR 15,000 for the duration
    of continuous membership. This table supports rate-locking via
    the effective_from/effective_to date range.
    """
    __tablename__ = "fee_schedules"

    membership_type: Mapped[MembershipType] = mapped_column(
        Enum(MembershipType, name="membership_type", create_type=False),
        nullable=False,
    )
    annual_fee: Mapped[Decimal] = mapped_column(
        Numeric(precision=12, scale=2), nullable=False
    )
    per_forum_fee: Mapped[Decimal] = mapped_column(
        Numeric(precision=10, scale=2), nullable=False, default=Decimal("5000.00")
    )
    currency: Mapped[str] = mapped_column(String(10), default="LKR", nullable=False)
    effective_from: Mapped[date] = mapped_column(Date, nullable=False)
    effective_to: Mapped[date | None] = mapped_column(Date, nullable=True)
    is_active: Mapped[bool] = mapped_column(Boolean, default=True, nullable=False)

    def __repr__(self) -> str:
        return f"<FeeSchedule {self.membership_type.value} {self.annual_fee} {self.currency}>"
