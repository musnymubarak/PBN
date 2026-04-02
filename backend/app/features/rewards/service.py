"""
Prime Business Network – Rewards API Service.
"""

from __future__ import annotations

from typing import Any, Dict, List
from uuid import UUID
from datetime import datetime, timezone

from sqlalchemy import select, func
from sqlalchemy.ext.asyncio import AsyncSession
from sqlalchemy.orm import selectinload
from sqlalchemy.exc import IntegrityError

from app.core.exceptions import BadRequestException, NotFoundException
from app.features.rewards.schemas import PartnerCreate, OfferCreate
from app.models.privilege_cards import PrivilegeCard, Partner, Offer, OfferRedemption


async def _serialize_offer(offer: Offer) -> Dict[str, Any]:
    return {
        "id": str(offer.id),
        "title": offer.title,
        "description": offer.description,
        "offer_type": offer.offer_type.value,
        "discount_percentage": offer.discount_percentage,
        "start_date": offer.start_date.isoformat(),
        "end_date": offer.end_date.isoformat(),
        "is_active": offer.is_active,
        "redemption_instructions": offer.redemption_instructions,
        "redeemed_count": len(getattr(offer, "redemptions", [])),
    }


async def _serialize_partner(partner: Partner) -> Dict[str, Any]:
    return {
        "id": str(partner.id),
        "name": partner.name,
        "logo_url": partner.logo_url,
        "description": partner.description,
        "website": partner.website,
        "is_active": partner.is_active,
        "offers": [await _serialize_offer(o) for o in getattr(partner, "offers", [])]
    }


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
        redemption_instructions=data.redemption_instructions
    )
    db.add(offer)
    await db.flush()
    
    fresh_stmt = select(Offer).options(selectinload(Offer.redemptions)).where(Offer.id == offer.id)
    fresh_offer = (await db.execute(fresh_stmt)).scalar_one()
    
    return await _serialize_offer(fresh_offer)


async def list_partners(active_only: bool, db: AsyncSession) -> List[Dict[str, Any]]:
    stmt = select(Partner).options(selectinload(Partner.offers).selectinload(Offer.redemptions))
    if active_only:
         stmt = stmt.where(Partner.is_active.is_(True))
    
    result = await db.execute(stmt)
    partners = result.scalars().all()
    
    return [await _serialize_partner(p) for p in partners]


async def redeem_offer(offer_id: UUID, user_id: UUID, db: AsyncSession) -> Dict[str, Any]:
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
