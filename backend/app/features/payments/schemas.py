"""
Prime Business Network – Payments API Schemas.
"""

from __future__ import annotations

from typing import Optional
from uuid import UUID
from decimal import Decimal

from pydantic import BaseModel, field_validator

from app.models.payments import PaymentType, PaymentStatus


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
