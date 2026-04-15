"""
Prime Business Network – Rewards API Schemas.
"""

from __future__ import annotations

from datetime import date, datetime
from typing import List, Optional
from uuid import UUID

from pydantic import BaseModel

from app.models.privilege_cards import OfferType, RedemptionMethod


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
    redemption_method: RedemptionMethod
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
    redemption_method: str
    discount_percentage: Optional[int]
    start_date: date
    end_date: date
    is_active: bool
    redemption_instructions: Optional[str]
    redeemed_count: Optional[int] = 0
    is_redeemed_by_me: bool = False


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


# ── QR Redemption Flow ──────────────────────────────────────


class InitiateRedeemResponse(BaseModel):
    """Returned when user taps Redeem — contains QR URL."""
    token: str
    qr_url: str
    expires_at: datetime
    offer_title: str
    partner_name: str


class RedemptionStatusResponse(BaseModel):
    """Mobile polls this to check if partner confirmed."""
    status: str  # pending | confirmed | expired | cancelled
    confirmed_at: Optional[datetime] = None
    signer_name: Optional[str] = None


class ConfirmRedemptionRequest(BaseModel):
    """Sent from the verification web page when user signs."""
    signer_name: str
    signature_data: str  # base64 encoded PNG of the signature


# ── Coupon Code Flow (Online Purchases) ─────────────────────


class GenerateCouponResponse(BaseModel):
    """Returned when user generates a coupon for an online offer."""
    code: str
    offer_title: str
    partner_name: str
    discount_percentage: Optional[int]
    expires_at: datetime


# ── Partner Portal (Mobile Scan) ────────────────────────────

class PartnerScanRequest(BaseModel):
    """The payload sent by the partner app when scanning a QR code."""
    token: str


class PartnerRedemptionItemResponse(BaseModel):
    id: UUID
    offer_title: str
    user_name: str
    user_phone: str
    redeemed_at: datetime
    signer_name: Optional[str]


class PartnerDashboardResponse(BaseModel):
    partner_name: str
    total_redemptions: int
    active_offers: int
    recent_redemptions: List[PartnerRedemptionItemResponse]

