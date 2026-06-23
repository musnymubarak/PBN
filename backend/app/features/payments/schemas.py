"""
Prime Business Network – Payments API Schemas.
"""

from __future__ import annotations

from typing import Optional
from uuid import UUID
from decimal import Decimal

from datetime import datetime
from pydantic import BaseModel, field_validator

from app.models.payments import PaymentType, PaymentStatus
from app.models.payment_proofs import PaymentProofType, PaymentProofStatus


class PaymentInitiate(BaseModel):
    payment_type: PaymentType
    event_id: Optional[UUID] = None
    amount: Decimal

    @field_validator("amount")
    @classmethod
    def amount_must_be_positive(cls, v: Decimal) -> Decimal:
        if v <= 0:
            raise ValueError("Amount must be positive")
        if v > 10_000_000:
            raise ValueError("Amount exceeds maximum (10,000,000 LKR)")
        return v


class SimulateWebhook(BaseModel):
    payment_id: UUID


class PaymentCreateAdmin(BaseModel):
    user_id: UUID
    amount: Decimal
    payment_type: PaymentType
    reason: Optional[str] = None
    notes: Optional[str] = None
    status: PaymentStatus = PaymentStatus.COMPLETED


class PaymentUpdateAdmin(BaseModel):
    amount: Optional[Decimal] = None
    payment_type: Optional[PaymentType] = None
    reason: Optional[str] = None
    notes: Optional[str] = None
    status: Optional[PaymentStatus] = None

class PaymentProofResponse(BaseModel):
    id: UUID
    payment_id: UUID
    user_id: UUID
    proof_type: Optional[PaymentProofType] = None
    file_path: Optional[str] = None
    reference_number: Optional[str] = None
    status: PaymentProofStatus
    admin_notes: Optional[str] = None
    reviewed_at: Optional[datetime] = None
    created_at: datetime
    
    # Optional nested info from joined tables
    user_name: Optional[str] = None
    user_phone: Optional[str] = None
    payment_amount: Optional[Decimal] = None
    payment_reason: Optional[str] = None

class PaymentProofUpload(BaseModel):
    proof_type: PaymentProofType
    reference_number: Optional[str] = None

class PaymentProofReview(BaseModel):
    notes: Optional[str] = None

