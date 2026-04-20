"""
Prime Business Network – Rewards API Service.
"""

from __future__ import annotations

import secrets
import string
from typing import Any, Dict, List
from uuid import UUID
from datetime import datetime, timedelta, timezone

from sqlalchemy import select, func, exists
from sqlalchemy.ext.asyncio import AsyncSession
from sqlalchemy.orm import selectinload
from sqlalchemy.exc import IntegrityError

from app.core.exceptions import BadRequestException, NotFoundException
from app.features.rewards.schemas import PartnerCreate, OfferCreate, PartnerUpdate
from app.features.notifications.service import broadcast_notification
from app.models.privilege_cards import (
    PrivilegeCard, Partner, Offer, OfferRedemption,
    RedemptionToken, CouponCode, TokenStatus, CouponStatus,
)

# ── Constants ────────────────────────────────────────────────

QR_TOKEN_EXPIRY_MINUTES = 15
COUPON_EXPIRY_HOURS = 48
BASE_VERIFY_URL = "http://localhost:8000/verify"


def _generate_coupon_code() -> str:
    """Generate a unique coupon code like PBN-A7X9K2."""
    chars = string.ascii_uppercase + string.digits
    random_part = "".join(secrets.choice(chars) for _ in range(6))
    return f"PBN-{random_part}"


# ── Serialization Helpers ────────────────────────────────────


async def _serialize_offer(offer: Offer, user_id: UUID | None = None, db: AsyncSession | None = None) -> Dict[str, Any]:
    is_redeemed = False
    if user_id and db:
        stmt = select(exists().where(
            OfferRedemption.offer_id == offer.id,
            OfferRedemption.user_id == user_id,
        ))
        is_redeemed = (await db.execute(stmt)).scalar() or False

    return {
        "id": str(offer.id),
        "title": offer.title,
        "description": offer.description,
        "offer_type": offer.offer_type.value,
        "discount_percentage": offer.discount_percentage,
        "start_date": offer.start_date.isoformat(),
        "end_date": offer.end_date.isoformat(),
        "is_active": offer.is_active,
        "redemption_method": offer.redemption_method.value if hasattr(offer.redemption_method, 'value') else offer.redemption_method,
        "redemption_instructions": offer.redemption_instructions,
        "redeemed_count": len(getattr(offer, "redemptions", [])),
        "is_redeemed_by_me": is_redeemed,
    }


async def _serialize_partner(partner: Partner, user_id: UUID | None = None, db: AsyncSession | None = None) -> Dict[str, Any]:
    return {
        "id": str(partner.id),
        "name": partner.name,
        "logo_url": partner.logo_url,
        "description": partner.description,
        "website": partner.website,
        "is_active": partner.is_active,
        "offers": [await _serialize_offer(o, user_id, db) for o in getattr(partner, "offers", [])]
    }


# ── Existing CRUD ────────────────────────────────────────────


async def get_my_card(user_id: UUID, db: AsyncSession) -> Dict[str, Any]:
    card = (await db.execute(select(PrivilegeCard).where(PrivilegeCard.user_id == user_id))).scalar_one_or_none()
    if not card:
        raise NotFoundException("Privilege card not found")

    return {
        "card_number": card.card_number,
        "qr_code_data": card.qr_code_data,
        "is_active": card.is_active,
        "issued_at": card.issued_at.isoformat(),
        "expires_at": card.expires_at.isoformat() if card.expires_at else None
    }


async def create_partner(data: PartnerCreate, db: AsyncSession) -> Dict[str, Any]:
    partner = Partner(
        name=data.name,
        logo_url=data.logo_url,
        description=data.description,
        website=data.website,
        is_active=data.is_active
    )
    db.add(partner)
    await db.flush()

    fresh_stmt = select(Partner).options(selectinload(Partner.offers).selectinload(Offer.redemptions)).where(Partner.id == partner.id)
    fresh_partner = (await db.execute(fresh_stmt)).scalar_one()

    return await _serialize_partner(fresh_partner)


async def update_partner(partner_id: UUID, data: PartnerUpdate, db: AsyncSession) -> Dict[str, Any]:
    partner = (await db.execute(select(Partner).where(Partner.id == partner_id))).scalar_one_or_none()
    if not partner:
        raise NotFoundException("Partner not found")

    update_data = data.model_dump(exclude_unset=True)
    for key, value in update_data.items():
        setattr(partner, key, value)

    await db.flush()

    fresh_stmt = select(Partner).options(selectinload(Partner.offers).selectinload(Offer.redemptions)).where(Partner.id == partner.id)
    fresh_partner = (await db.execute(fresh_stmt)).scalar_one()

    return await _serialize_partner(fresh_partner)


async def create_offer(partner_id: UUID, data: OfferCreate, db: AsyncSession) -> Dict[str, Any]:
    partner = (await db.execute(select(Partner).where(Partner.id == partner_id))).scalar_one_or_none()
    if not partner:
        raise NotFoundException("Partner not found")

    offer = Offer(
        partner_id=partner_id,
        title=data.title,
        description=data.description,
        offer_type=data.offer_type,
        discount_percentage=data.discount_percentage,
        start_date=data.start_date,
        end_date=data.end_date,
        is_active=data.is_active,
        redemption_method=data.redemption_method,
        redemption_instructions=data.redemption_instructions
    )
    db.add(offer)
    await db.flush()
    
    # Trigger Global Notification
    await broadcast_notification(
        title=f"🎁 New Reward: {offer.title}",
        body=f"Exclusive deal from {partner.name}. Check it out in the Rewards section!",
        notification_type="new_reward",
        data={"route": "/rewards"}
    )

    fresh_stmt = select(Offer).options(selectinload(Offer.redemptions)).where(Offer.id == offer.id)
    fresh_offer = (await db.execute(fresh_stmt)).scalar_one()

    return await _serialize_offer(fresh_offer)


async def list_partners(active_only: bool, db: AsyncSession, user_id: UUID | None = None) -> List[Dict[str, Any]]:
    stmt = select(Partner).options(selectinload(Partner.offers).selectinload(Offer.redemptions))
    if active_only:
         stmt = stmt.where(Partner.is_active.is_(True))

    result = await db.execute(stmt)
    partners = result.scalars().all()

    return [await _serialize_partner(p, user_id, db) for p in partners]


async def redeem_offer(offer_id: UUID, user_id: UUID, db: AsyncSession) -> Dict[str, Any]:
    """Legacy direct redemption — kept for backward compatibility."""
    offer = (await db.execute(select(Offer).where(Offer.id == offer_id))).scalar_one_or_none()
    if not offer:
        raise NotFoundException("Offer not found")

    if not offer.is_active:
        raise BadRequestException("Offer is no longer active")

    redemption = OfferRedemption(
        offer_id=offer_id,
        user_id=user_id,
        redeemed_at=datetime.now(timezone.utc)
    )
    db.add(redemption)

    try:
        await db.flush()
    except IntegrityError:
        await db.rollback()
        raise BadRequestException("Offer already redeemed by this user")

    return {
        "offer_id": str(redemption.offer_id),
        "user_id": str(redemption.user_id),
        "redeemed_at": redemption.redeemed_at.isoformat()
    }


# ── QR Code Redemption Flow ─────────────────────────────────


async def initiate_redeem(offer_id: UUID, user_id: UUID, db: AsyncSession) -> Dict[str, Any]:
    """
    User taps "Redeem" → creates a pending token, returns QR URL.
    """
    # Check offer exists and is active
    stmt = select(Offer).options(selectinload(Offer.partner)).where(Offer.id == offer_id)
    offer = (await db.execute(stmt)).scalar_one_or_none()
    if not offer:
        raise NotFoundException("Offer not found")
    if not offer.is_active:
        raise BadRequestException("Offer is no longer active")

    # Check if already redeemed
    already = (await db.execute(
        select(exists().where(OfferRedemption.offer_id == offer_id, OfferRedemption.user_id == user_id))
    )).scalar()
    if already:
        raise BadRequestException("Offer already redeemed")

    # Cancel any existing pending tokens for this user+offer
    existing_tokens_stmt = select(RedemptionToken).where(
        RedemptionToken.offer_id == offer_id,
        RedemptionToken.user_id == user_id,
        RedemptionToken.status == TokenStatus.PENDING,
    )
    existing_tokens = (await db.execute(existing_tokens_stmt)).scalars().all()
    for t in existing_tokens:
        t.status = TokenStatus.CANCELLED

    # Create new token
    now = datetime.now(timezone.utc)
    token = RedemptionToken(
        offer_id=offer_id,
        user_id=user_id,
        status=TokenStatus.PENDING,
        expires_at=now + timedelta(minutes=QR_TOKEN_EXPIRY_MINUTES),
    )
    db.add(token)
    await db.flush()

    qr_url = f"{BASE_VERIFY_URL}/{token.token}"

    return {
        "token": str(token.token),
        "qr_url": qr_url,
        "expires_at": token.expires_at.isoformat(),
        "offer_title": offer.title,
        "partner_name": offer.partner.name,
    }


async def get_verification_data(token_str: str, db: AsyncSession) -> Dict[str, Any]:
    """
    Load token + offer + partner data for the partner's verification web page.
    """
    stmt = (
        select(RedemptionToken)
        .options(
            selectinload(RedemptionToken.offer).selectinload(Offer.partner),
            selectinload(RedemptionToken.user),
        )
        .where(RedemptionToken.token == token_str)
    )
    rt = (await db.execute(stmt)).scalar_one_or_none()
    if not rt:
        raise NotFoundException("Invalid or expired verification link")

    now = datetime.now(timezone.utc)

    # Auto-expire if past deadline
    if rt.status == TokenStatus.PENDING and rt.expires_at < now:
        rt.status = TokenStatus.EXPIRED
        await db.flush()

    return {
        "token": str(rt.token),
        "status": rt.status.value,
        "offer_title": rt.offer.title,
        "offer_description": rt.offer.description,
        "offer_type": rt.offer.offer_type.value,
        "discount_percentage": rt.offer.discount_percentage,
        "partner_name": rt.offer.partner.name,
        "partner_logo": rt.offer.partner.logo_url,
        "user_name": rt.user.full_name,
        "expires_at": rt.expires_at.isoformat(),
        "confirmed_at": rt.confirmed_at.isoformat() if rt.confirmed_at else None,
        "signer_name": rt.signer_name,
    }


async def confirm_redemption(token_str: str, signer_name: str, signature_data: str, db: AsyncSession) -> Dict[str, Any]:
    """
    Partner confirms the redemption after user signs on the verification page.
    Creates the actual OfferRedemption record.
    """
    stmt = (
        select(RedemptionToken)
        .options(
            selectinload(RedemptionToken.offer).selectinload(Offer.partner),
            selectinload(RedemptionToken.user),
        )
        .where(RedemptionToken.token == token_str)
    )
    rt = (await db.execute(stmt)).scalar_one_or_none()
    if not rt:
        raise NotFoundException("Invalid verification token")

    now = datetime.now(timezone.utc)

    if rt.status == TokenStatus.CONFIRMED:
        raise BadRequestException("This offer has already been claimed")

    if rt.status in (TokenStatus.EXPIRED, TokenStatus.CANCELLED):
        raise BadRequestException("This QR code has expired or been cancelled")

    if rt.expires_at < now:
        rt.status = TokenStatus.EXPIRED
        await db.flush()
        raise BadRequestException("This QR code has expired. Please generate a new one.")

    # Update the token with signature info
    rt.status = TokenStatus.CONFIRMED
    rt.signer_name = signer_name
    rt.signature_data = signature_data
    rt.confirmed_at = now

    # Create the actual OfferRedemption record
    redemption = OfferRedemption(
        offer_id=rt.offer_id,
        user_id=rt.user_id,
        redeemed_at=now,
        redemption_token_id=rt.id,
    )
    db.add(redemption)

    try:
        await db.flush()
    except IntegrityError:
        await db.rollback()
        raise BadRequestException("Offer already redeemed by this user")

    return {
        "status": "confirmed",
        "offer_title": rt.offer.title,
        "partner_name": rt.offer.partner.name,
        "discount_percentage": rt.offer.discount_percentage,
        "signer_name": signer_name,
        "confirmed_at": now.isoformat(),
        "user_name": rt.user.full_name,
    }


async def check_redemption_status(token_str: str, db: AsyncSession) -> Dict[str, Any]:
    """
    Mobile polls this to check if partner has confirmed the QR.
    """
    rt = (await db.execute(
        select(RedemptionToken).where(RedemptionToken.token == token_str)
    )).scalar_one_or_none()
    if not rt:
        raise NotFoundException("Token not found")

    now = datetime.now(timezone.utc)

    # Auto-expire
    if rt.status == TokenStatus.PENDING and rt.expires_at < now:
        rt.status = TokenStatus.EXPIRED
        await db.flush()

    return {
        "status": rt.status.value,
        "confirmed_at": rt.confirmed_at.isoformat() if rt.confirmed_at else None,
        "signer_name": rt.signer_name,
    }


# ── Coupon Code Flow (Online Purchases) ─────────────────────


async def generate_coupon(offer_id: UUID, user_id: UUID, db: AsyncSession) -> Dict[str, Any]:
    """
    Generate a unique, one-time coupon code for an online purchase offer.
    """
    stmt = select(Offer).options(selectinload(Offer.partner)).where(Offer.id == offer_id)
    offer = (await db.execute(stmt)).scalar_one_or_none()
    if not offer:
        raise NotFoundException("Offer not found")
    if not offer.is_active:
        raise BadRequestException("Offer is no longer active")

    # Check if already redeemed
    already = (await db.execute(
        select(exists().where(OfferRedemption.offer_id == offer_id, OfferRedemption.user_id == user_id))
    )).scalar()
    if already:
        raise BadRequestException("Offer already redeemed")

    # Check if coupon already exists for this user+offer
    existing_coupon = (await db.execute(
        select(CouponCode).where(
            CouponCode.offer_id == offer_id,
            CouponCode.user_id == user_id,
            CouponCode.status == CouponStatus.ACTIVE,
        )
    )).scalar_one_or_none()

    if existing_coupon:
        # Return the existing active coupon
        return {
            "code": existing_coupon.code,
            "offer_title": offer.title,
            "partner_name": offer.partner.name,
            "discount_percentage": offer.discount_percentage,
            "expires_at": existing_coupon.expires_at.isoformat(),
        }

    now = datetime.now(timezone.utc)

    # Generate unique code with retry
    for _ in range(10):
        code = _generate_coupon_code()
        existing = (await db.execute(select(exists().where(CouponCode.code == code)))).scalar()
        if not existing:
            break
    else:
        raise BadRequestException("Unable to generate unique coupon code. Please try again.")

    coupon = CouponCode(
        offer_id=offer_id,
        user_id=user_id,
        code=code,
        status=CouponStatus.ACTIVE,
        expires_at=now + timedelta(hours=COUPON_EXPIRY_HOURS),
    )
    db.add(coupon)
    await db.flush()

    return {
        "code": coupon.code,
        "offer_title": offer.title,
        "partner_name": offer.partner.name,
        "discount_percentage": offer.discount_percentage,
        "expires_at": coupon.expires_at.isoformat(),
    }


# ── Partner Portal Flow ─────────────────────────────────────


async def get_partner_dashboard(partner_id: UUID, db: AsyncSession) -> Dict[str, Any]:
    """Returns aggregated stats for the partner dashboard."""
    partner = (await db.execute(select(Partner).where(Partner.id == partner_id))).scalar_one_or_none()
    if not partner:
        raise NotFoundException("Partner profile not found")

    # Active offers count
    active_offers = (await db.execute(
        select(func.count(Offer.id)).where(Offer.partner_id == partner_id, Offer.is_active.is_(True))
    )).scalar() or 0

    # Total redemptions count
    total_redemptions = (await db.execute(
        select(func.count(OfferRedemption.id))
        .join(Offer, OfferRedemption.offer_id == Offer.id)
        .where(Offer.partner_id == partner_id)
    )).scalar() or 0

    # Recent redemptions (last 5)
    recent_stmt = (
        select(OfferRedemption)
        .join(Offer, OfferRedemption.offer_id == Offer.id)
        .options(selectinload(OfferRedemption.offer), selectinload(OfferRedemption.user), selectinload(OfferRedemption.redemption_token))
        .where(Offer.partner_id == partner_id)
        .order_by(OfferRedemption.redeemed_at.desc())
        .limit(5)
    )
    recent_redemptions = (await db.execute(recent_stmt)).scalars().all()

    recent_data = []
    for r in recent_redemptions:
        recent_data.append({
            "id": str(r.id),
            "offer_title": r.offer.title,
            "user_name": r.user.full_name,
            "user_phone": r.user.phone_number,
            "user_email": r.user.email,
            "redeemed_at": r.redeemed_at.isoformat() if r.redeemed_at else None,
            "signer_name": r.redemption_token.signer_name if r.redemption_token else None,
        })

    return {
        "partner_name": partner.name,
        "total_redemptions": total_redemptions,
        "active_offers": active_offers,
        "recent_redemptions": recent_data,
    }


async def get_partner_redemptions(partner_id: UUID, db: AsyncSession) -> List[Dict[str, Any]]:
    """Returns a list of all redemptions for a specific partner."""
    stmt = (
        select(OfferRedemption)
        .join(Offer, OfferRedemption.offer_id == Offer.id)
        .options(selectinload(OfferRedemption.offer), selectinload(OfferRedemption.user), selectinload(OfferRedemption.redemption_token))
        .where(Offer.partner_id == partner_id)
        .order_by(OfferRedemption.redeemed_at.desc())
    )
    redemptions = (await db.execute(stmt)).scalars().all()

    data = []
    for r in redemptions:
        data.append({
            "id": str(r.id),
            "offer_title": r.offer.title,
            "user_name": r.user.full_name,
            "user_phone": r.user.phone_number,
            "user_email": r.user.email,
            "redeemed_at": r.redeemed_at.isoformat() if r.redeemed_at else None,
            "signer_name": r.redemption_token.signer_name if r.redemption_token else None,
        })
    return data


async def partner_scan_token(token_str: str, partner_id: UUID, db: AsyncSession) -> Dict[str, Any]:
    """Partner securely scans and consumes a user's QR token."""
    stmt = (
        select(RedemptionToken)
        .options(
            selectinload(RedemptionToken.offer).selectinload(Offer.partner),
            selectinload(RedemptionToken.user),
        )
        .where(RedemptionToken.token == token_str)
    )
    rt = (await db.execute(stmt)).scalar_one_or_none()
    if not rt:
        raise NotFoundException("Invalid verification token")

    if rt.offer.partner_id != partner_id:
        raise BadRequestException("This offer belongs to a different partner and cannot be scanned by you.")

    now = datetime.now(timezone.utc)

    if rt.status == TokenStatus.CONFIRMED:
        raise BadRequestException("This offer has already been claimed")

    if rt.status in (TokenStatus.EXPIRED, TokenStatus.CANCELLED) or rt.expires_at < now:
        rt.status = TokenStatus.EXPIRED
        await db.flush()
        raise BadRequestException("This QR code has expired. The user must generate a new one.")

    # Auto-confirm without signature since partner is authenticated in app
    rt.status = TokenStatus.CONFIRMED
    rt.confirmed_at = now
    rt.signer_name = "Confirmed via Partner App"

    # Create the OfferRedemption record
    redemption = OfferRedemption(
        offer_id=rt.offer_id,
        user_id=rt.user_id,
        redeemed_at=now,
        redemption_token_id=rt.id,
    )
    db.add(redemption)

    try:
        await db.flush()
    except IntegrityError:
        await db.rollback()
        raise BadRequestException("Offer already redeemed by this user")

    return {
        "status": "confirmed",
        "offer_title": rt.offer.title,
        "partner_name": rt.offer.partner.name,
        "user_name": rt.user.full_name,
        "user_email": rt.user.email,
        "confirmed_at": now.isoformat(),
    }

