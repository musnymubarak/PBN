"""
Prime Business Network – Rewards Router.
"""

from __future__ import annotations

from typing import Optional
from uuid import UUID

from fastapi import APIRouter, Depends, Query
from fastapi.responses import ORJSONResponse
from sqlalchemy.ext.asyncio import AsyncSession

from app.core.dependencies import get_db
from app.core.response import success_response
from app.features.auth.dependencies import get_current_user, require_role
from app.features.rewards.schemas import PartnerCreate, OfferCreate
from app.features.rewards.service import (
    create_offer,
    create_partner,
    get_my_card,
    list_partners,
    redeem_offer,
)
from app.models.user import User, UserRole


router = APIRouter(tags=["Rewards"])

admin_req = require_role([UserRole.CHAPTER_ADMIN, UserRole.SUPER_ADMIN])
member_req = require_role([UserRole.MEMBER, UserRole.CHAPTER_ADMIN, UserRole.SUPER_ADMIN])


@router.get("/rewards/my-card", summary="Get my active privilege card")
async def my_card_endpoint(
    current_user: User = Depends(member_req),
    db: AsyncSession = Depends(get_db),
) -> ORJSONResponse:
    card = await get_my_card(current_user.id, db)
    return success_response(data=card)


@router.get("/rewards/partners", summary="List partner businesses and their offers")
async def list_partners_endpoint(
    active_only: bool = Query(True, description="Only show active partners"),
    current_user: User = Depends(member_req),
    db: AsyncSession = Depends(get_db),
) -> ORJSONResponse:
    if current_user.role not in (UserRole.CHAPTER_ADMIN, UserRole.SUPER_ADMIN):
        active_only = True
        
    partners = await list_partners(active_only, db)
    return success_response(data=partners)


@router.post("/rewards/partners", summary="Create a new partner", status_code=201)
async def create_partner_endpoint(
    data: PartnerCreate,
    current_user: User = Depends(admin_req),
    db: AsyncSession = Depends(get_db),
) -> ORJSONResponse:
    partner = await create_partner(data, db)
    return success_response(data=partner, message="Partner created successfully", status_code=201)


@router.post("/rewards/partners/{partner_id}/offers", summary="Create a new offer for a partner", status_code=201)
async def create_offer_endpoint(
    partner_id: UUID,
    data: OfferCreate,
    current_user: User = Depends(admin_req),
    db: AsyncSession = Depends(get_db),
) -> ORJSONResponse:
    offer = await create_offer(partner_id, data, db)
    return success_response(data=offer, message="Offer created successfully", status_code=201)


@router.post("/rewards/offers/{offer_id}/redeem", summary="Redeem an offer", status_code=200)
async def redeem_offer_endpoint(
    offer_id: UUID,
    current_user: User = Depends(member_req),
    db: AsyncSession = Depends(get_db),
) -> ORJSONResponse:
    redemption = await redeem_offer(offer_id, current_user.id, db)
    return success_response(data=redemption, message="Offer redeemed successfully")
