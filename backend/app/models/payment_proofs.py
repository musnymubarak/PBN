"""
Prime Business Network – Payment Proofs Model.
"""

from __future__ import annotations

import enum
import uuid
from datetime import datetime

from sqlalchemy import Enum, ForeignKey, String, DateTime
from sqlalchemy.dialects.postgresql import UUID
from sqlalchemy.orm import Mapped, mapped_column, relationship

from app.models.base import Base, TimestampMixin
from typing import TYPE_CHECKING

if TYPE_CHECKING:
    from app.models.payments import Payment
    from app.models.user import User


class PaymentProofType(str, enum.Enum):
    IMAGE = "image"
    PDF = "pdf"
    REFERENCE_NUMBER = "reference_number"

class PaymentProofStatus(str, enum.Enum):
    PENDING_REVIEW = "pending_review"
    APPROVED = "approved"
    REJECTED = "rejected"

class PaymentProof(Base, TimestampMixin):
    __tablename__ = "payment_proofs"

    payment_id: Mapped[uuid.UUID] = mapped_column(
        UUID(as_uuid=True), ForeignKey("payments.id", ondelete="CASCADE"), nullable=False, index=True
    )
    user_id: Mapped[uuid.UUID] = mapped_column(
        UUID(as_uuid=True), ForeignKey("users.id", ondelete="CASCADE"), nullable=False, index=True
    )
    proof_type: Mapped[PaymentProofType | None] = mapped_column(
        Enum(PaymentProofType, name="payment_proof_type", create_type=True), nullable=True
    )
    file_path: Mapped[str | None] = mapped_column(String(500), nullable=True)
    reference_number: Mapped[str | None] = mapped_column(String(255), nullable=True)
    
    upload_token: Mapped[str] = mapped_column(String(255), unique=True, index=True, nullable=False)
    upload_token_expires_at: Mapped[datetime] = mapped_column(DateTime(timezone=True), nullable=False)
    
    status: Mapped[PaymentProofStatus] = mapped_column(
        Enum(PaymentProofStatus, name="payment_proof_status", create_type=True),
        nullable=False,
        default=PaymentProofStatus.PENDING_REVIEW,
    )
    
    admin_notes: Mapped[str | None] = mapped_column(String(1000), nullable=True)
    reviewed_by_id: Mapped[uuid.UUID | None] = mapped_column(
        UUID(as_uuid=True), ForeignKey("users.id", ondelete="SET NULL"), nullable=True
    )
    reviewed_at: Mapped[datetime | None] = mapped_column(DateTime(timezone=True), nullable=True)

    # Relationships
    payment: Mapped["Payment"] = relationship("Payment", back_populates="proofs")
    user: Mapped["User"] = relationship("User", foreign_keys=[user_id])
    reviewed_by: Mapped["User | None"] = relationship("User", foreign_keys=[reviewed_by_id])
