"""
Prime Business Network – Rewards API Schemas.
"""

from __future__ import annotations

from datetime import date, datetime
from typing import List, Optional
from uuid import UUID

from pydantic import BaseModel

from app.models.privilege_cards import OfferType


class PrivilegeCardResponse(BaseModel):
    card_number: str
    qr_code_data: Optional[str]
    is_active: bool
    issued_at: datetime
    expires_at: Optional[datetime]


class PartnerCreate(BaseModel):
    name: str
    logo_url: Optional[str] = None
    description: Optional[str] = None
    website: Optional[str] = None
    is_active: bool = True


class OfferCreate(BaseModel):
    title: str
    description: Optional[str] = None
    offer_type: OfferType
    discount_percentage: Optional[int] = None
    start_date: date
    end_date: date
    is_active: bool = True
    redemption_instructions: Optional[str] = None


class OfferResponse(BaseModel):
    id: UUID
    title: str
    description: Optional[str]
    offer_type: str
    discount_percentage: Optional[int]
    start_date: date
    end_date: date
    is_active: bool
    redemption_instructions: Optional[str]
    redeemed_count: Optional[int] = 0


class PartnerResponse(BaseModel):
    id: UUID
    name: str
    logo_url: Optional[str]
    description: Optional[str]
    website: Optional[str]
    is_active: bool
    offers: List[OfferResponse] = []


class OfferRedemptionResponse(BaseModel):
    offer_id: UUID
    user_id: UUID
    redeemed_at: datetime
