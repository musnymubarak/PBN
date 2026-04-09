"""
Prime Business Network – Payment Model.
"""

from __future__ import annotations

import enum
import uuid
from decimal import Decimal

from sqlalchemy import Enum, ForeignKey, Numeric, String
from sqlalchemy.dialects.postgresql import JSONB, UUID
from sqlalchemy.orm import Mapped, mapped_column, relationship

from app.models.base import Base, TimestampMixin
from typing import TYPE_CHECKING

if TYPE_CHECKING:
    from app.models.user import User


class PaymentType(str, enum.Enum):
    MEMBERSHIP = "membership"
    MEETING_FEE = "meeting_fee"
    RENEWAL = "renewal"


class PaymentStatus(str, enum.Enum):
    PENDING = "pending"
    COMPLETED = "completed"
    FAILED = "failed"
    REFUNDED = "refunded"


class Payment(Base, TimestampMixin):
    __tablename__ = "payments"

    user_id: Mapped[uuid.UUID] = mapped_column(
        UUID(as_uuid=True), ForeignKey("users.id", ondelete="CASCADE"), nullable=False, index=True
    )
    amount: Mapped[Decimal] = mapped_column(
        Numeric(precision=12, scale=2), nullable=False
    )
    currency: Mapped[str] = mapped_column(String(10), default="LKR", nullable=False)
    payment_type: Mapped[PaymentType] = mapped_column(
        Enum(PaymentType, name="payment_type", create_type=True), nullable=False
    )
    reason: Mapped[str | None] = mapped_column(String(255), nullable=True)
    notes: Mapped[str | None] = mapped_column(String(1000), nullable=True)
    reference_id: Mapped[str | None] = mapped_column(String(255), nullable=True)
    gateway_reference: Mapped[str | None] = mapped_column(String(255), nullable=True)
    recorded_by_id: Mapped[uuid.UUID | None] = mapped_column(
        UUID(as_uuid=True), ForeignKey("users.id", ondelete="SET NULL"), nullable=True
    )
    status: Mapped[PaymentStatus] = mapped_column(
        Enum(PaymentStatus, name="payment_status", create_type=True),
        nullable=False,
        default=PaymentStatus.PENDING,
    )
    gateway_response: Mapped[dict | None] = mapped_column(JSONB, nullable=True)

    # Relationships
    user: Mapped["User"] = relationship("User", foreign_keys=[user_id])
    recorded_by: Mapped["User | None"] = relationship("User", foreign_keys=[recorded_by_id])

    def __repr__(self) -> str:
        return f"<Payment {self.amount} {self.currency} [{self.status.value}]>"
