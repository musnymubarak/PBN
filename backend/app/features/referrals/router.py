"""
Prime Business Network – Referrals Router.
"""

from __future__ import annotations

from uuid import UUID

from fastapi import APIRouter, Depends
from fastapi.responses import ORJSONResponse
from sqlalchemy.ext.asyncio import AsyncSession

from app.core.dependencies import get_db
from app.core.response import success_response
from app.features.auth.dependencies import require_role
from app.features.referrals.schemas import ReferralCreate, ReferralStatusUpdate
from app.features.referrals.service import (
    create_referral,
    get_my_given_referrals,
    get_my_received_referrals,
    update_referral_status,
)
from app.models.user import User, UserRole

router = APIRouter(tags=["Referrals"])

# Referrals only available for MEMBERS and above.
member_req = require_role([UserRole.MEMBER, UserRole.CHAPTER_ADMIN, UserRole.SUPER_ADMIN])


@router.post("/referrals", summary="Submit a new referral", status_code=201)
async def submit_referral_endpoint(
    data: ReferralCreate,
    current_user: User = Depends(member_req),
    db: AsyncSession = Depends(get_db),
) -> ORJSONResponse:
    referral = await create_referral(data, current_user.id, db)
    return success_response(
        data=referral,
        message="Referral submitted successfully",
        status_code=201
    )


@router.get("/referrals/my/given", summary="Get my submitted referrals")
async def my_given_referrals_endpoint(
    current_user: User = Depends(member_req),
    db: AsyncSession = Depends(get_db),
) -> ORJSONResponse:
    referrals = await get_my_given_referrals(current_user.id, db)
    return success_response(data=referrals)


@router.get("/referrals/my/received", summary="Get referrals sent to me")
async def my_received_referrals_endpoint(
    current_user: User = Depends(member_req),
    db: AsyncSession = Depends(get_db),
) -> ORJSONResponse:
    referrals = await get_my_received_referrals(current_user.id, db)
    return success_response(data=referrals)


@router.patch("/referrals/{ref_id}/status", summary="Update referral status")
async def update_referral_status_endpoint(
    ref_id: UUID,
    data: ReferralStatusUpdate,
    current_user: User = Depends(member_req),
    db: AsyncSession = Depends(get_db),
) -> ORJSONResponse:
    updated = await update_referral_status(ref_id, data, current_user.id, db)
    return success_response(
        data=updated,
        message="Referral status updated"
    )
