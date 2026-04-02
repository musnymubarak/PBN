"""
Prime Business Network – Referral & Status History Models.

CHECK CONSTRAINT: from_member_id != to_member_id (no self-referrals).
"""

from __future__ import annotations

import enum
import uuid
from datetime import datetime
from decimal import Decimal

from sqlalchemy import (
    CheckConstraint,
    DateTime,
    Enum,
    ForeignKey,
    Numeric,
    String,
    Text,
)
from sqlalchemy.dialects.postgresql import UUID
from sqlalchemy.orm import Mapped, mapped_column

from app.models.base import Base, TimestampMixin


class ReferralStatus(str, enum.Enum):
    SUBMITTED = "submitted"
    CONTACTED = "contacted"
    MEETING_SCHEDULED = "meeting_scheduled"
    CLOSED_WON = "closed_won"
    CLOSED_LOST = "closed_lost"


class Referral(Base, TimestampMixin):
    __tablename__ = "referrals"

    from_member_id: Mapped[uuid.UUID] = mapped_column(
        UUID(as_uuid=True), ForeignKey("users.id", ondelete="CASCADE"), nullable=False, index=True
    )
    to_member_id: Mapped[uuid.UUID] = mapped_column(
        UUID(as_uuid=True), ForeignKey("users.id", ondelete="CASCADE"), nullable=False, index=True
    )
    client_name: Mapped[str] = mapped_column(String(150), nullable=False)
    client_phone: Mapped[str | None] = mapped_column(String(20), nullable=True)
    client_email: Mapped[str | None] = mapped_column(String(255), nullable=True)
    description: Mapped[str | None] = mapped_column(Text, nullable=True)
    estimated_value: Mapped[Decimal | None] = mapped_column(
        Numeric(precision=14, scale=2), nullable=True
    )
    actual_value: Mapped[Decimal | None] = mapped_column(
        Numeric(precision=14, scale=2), nullable=True
    )
    status: Mapped[ReferralStatus] = mapped_column(
        Enum(ReferralStatus, name="referral_status", create_type=True),
        nullable=False,
        default=ReferralStatus.SUBMITTED,
    )
    closed_at: Mapped[datetime | None] = mapped_column(DateTime(timezone=True), nullable=True)

    __table_args__ = (
        CheckConstraint(
            "from_member_id != to_member_id",
            name="no_self_referral",
        ),
    )

    def __repr__(self) -> str:
        return f"<Referral {self.from_member_id}→{self.to_member_id} [{self.status.value}]>"


class ReferralStatusHistory(Base, TimestampMixin):
    __tablename__ = "referral_status_history"

    referral_id: Mapped[uuid.UUID] = mapped_column(
        UUID(as_uuid=True), ForeignKey("referrals.id", ondelete="CASCADE"), nullable=False, index=True
    )
    old_status: Mapped[str] = mapped_column(String(30), nullable=False)
    new_status: Mapped[str] = mapped_column(String(30), nullable=False)
    notes: Mapped[str | None] = mapped_column(Text, nullable=True)
    changed_by: Mapped[uuid.UUID | None] = mapped_column(
        UUID(as_uuid=True), ForeignKey("users.id", ondelete="SET NULL"), nullable=True
    )

    def __repr__(self) -> str:
        return f"<RefStatusHistory {self.old_status}→{self.new_status}>"
