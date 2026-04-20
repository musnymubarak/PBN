"""
Prime Business Network – Rewards Router.

Includes:
- Privilege card management
- Partner/Offer CRUD
- QR Code redemption flow (initiate → verify → confirm)
- Coupon code generation for online purchases
- Verification web page (public, served via Jinja2)
"""

from __future__ import annotations

from pathlib import Path
from typing import Optional
from uuid import UUID

from fastapi import APIRouter, Depends, Query, Request, UploadFile, File
from fastapi.responses import ORJSONResponse
import os
import shutil
import uuid
from sqlalchemy.ext.asyncio import AsyncSession

from app.core.dependencies import get_db
from app.core.response import success_response
from app.features.auth.dependencies import get_current_user, require_role
from app.features.rewards.schemas import (
    PartnerCreate, OfferCreate, ConfirmRedemptionRequest, PartnerUpdate
)
from app.features.rewards.service import (
    check_redemption_status,
    confirm_redemption,
    create_offer,
    create_partner,
    generate_coupon,
    get_my_card,
    get_verification_data,
    initiate_redeem,
    list_partners,
    redeem_offer,
    update_partner,
)
from app.models.user import User, UserRole


router = APIRouter(tags=["Rewards"])

# Template directory is at backend/templates/
# Removed Jinja templates

admin_req = require_role([UserRole.CHAPTER_ADMIN, UserRole.SUPER_ADMIN])
member_req = require_role([UserRole.MEMBER, UserRole.CHAPTER_ADMIN, UserRole.SUPER_ADMIN])
partner_req = require_role([UserRole.PARTNER_ADMIN, UserRole.SUPER_ADMIN])


# ── Privilege Card ──────────────────────────────────────────


@router.get("/rewards/my-card", summary="Get my active privilege card")
async def my_card_endpoint(
    current_user: User = Depends(member_req),
    db: AsyncSession = Depends(get_db),
) -> ORJSONResponse:
    card = await get_my_card(current_user.id, db)
    return success_response(data=card)


# ── Partners & Offers ───────────────────────────────────────


@router.get("/rewards/partners", summary="List partner businesses and their offers")
async def list_partners_endpoint(
    active_only: bool = Query(True, description="Only show active partners"),
    current_user: User = Depends(member_req),
    db: AsyncSession = Depends(get_db),
) -> ORJSONResponse:
    if current_user.role not in (UserRole.CHAPTER_ADMIN, UserRole.SUPER_ADMIN):
        active_only = True

    partners = await list_partners(active_only, db, user_id=current_user.id)
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


@router.patch("/rewards/partners/{partner_id}", summary="Update a partner")
async def update_partner_endpoint(
    partner_id: UUID,
    data: PartnerUpdate,
    current_user: User = Depends(admin_req),
    db: AsyncSession = Depends(get_db),
) -> ORJSONResponse:
    partner = await update_partner(partner_id, data, db)
    return success_response(data=partner, message="Partner updated successfully")


@router.post("/rewards/partners/upload-logo", summary="Upload partner logo")
async def upload_partner_logo_endpoint(
    file: UploadFile = File(...),
    current_user: User = Depends(admin_req),
) -> ORJSONResponse:
    """Upload a partner logo image."""
    from app.core.exceptions import BadRequestException

    # 1. Size Validation (2MB limit for logos)
    MAX_SIZE = 2 * 1024 * 1024
    if file.size and file.size > MAX_SIZE:
        raise BadRequestException(
            message=f"File too large. Maximum size allowed is 2MB.",
            code="FILE_TOO_LARGE"
        )

    # 2. Format Validation
    ALLOWED_TYPES = ["image/jpeg", "image/png", "image/webp", "image/svg+xml"]
    if file.content_type not in ALLOWED_TYPES:
        raise BadRequestException(
            message="Invalid file format. Only JPEG, PNG, WebP, and SVG images are allowed.",
            code="INVALID_FORMAT"
        )

    os.makedirs("uploads/partners", exist_ok=True)
    ext = file.filename.split(".")[-1].lower() if "." in file.filename else "jpg"
    
    if ext not in ["jpg", "jpeg", "png", "webp", "svg"]:
         raise BadRequestException(
            message="Invalid file extension.",
            code="INVALID_EXTENSION"
        )

    filename = f"partner_{uuid.uuid4().hex[:8]}.{ext}"
    file_path = f"uploads/partners/{filename}"
    
    with open(file_path, "wb") as buffer:
        shutil.copyfileobj(file.file, buffer)
        
    logo_url = f"/static/partners/{filename}"
    
    return success_response(
        data={"logo_url": logo_url},
        message="Logo uploaded successfully"
    )


# ── Legacy Direct Redeem (backward compatibility) ───────────


@router.post("/rewards/offers/{offer_id}/redeem", summary="Redeem an offer (legacy)", status_code=200)
async def redeem_offer_endpoint(
    offer_id: UUID,
    current_user: User = Depends(member_req),
    db: AsyncSession = Depends(get_db),
) -> ORJSONResponse:
    redemption = await redeem_offer(offer_id, current_user.id, db)
    return success_response(data=redemption, message="Offer redeemed successfully")


# ── QR Code Redemption Flow ─────────────────────────────────


@router.post("/rewards/offers/{offer_id}/initiate-redeem", summary="Start QR redemption flow")
async def initiate_redeem_endpoint(
    offer_id: UUID,
    current_user: User = Depends(member_req),
    db: AsyncSession = Depends(get_db),
) -> ORJSONResponse:
    result = await initiate_redeem(offer_id, current_user.id, db)
    return success_response(data=result, message="QR code generated. Show it to the partner.")


@router.get("/rewards/redemptions/status/{token}", summary="Check QR redemption status (polling)")
async def redemption_status_endpoint(
    token: str,
    current_user: User = Depends(member_req),
    db: AsyncSession = Depends(get_db),
) -> ORJSONResponse:
    status = await check_redemption_status(token, db)
    return success_response(data=status)


# ── Coupon Code (Online Purchases) ──────────────────────────


@router.post("/rewards/offers/{offer_id}/generate-coupon", summary="Generate coupon for online offer")
async def generate_coupon_endpoint(
    offer_id: UUID,
    current_user: User = Depends(member_req),
    db: AsyncSession = Depends(get_db),
) -> ORJSONResponse:
    coupon = await generate_coupon(offer_id, current_user.id, db)
    return success_response(data=coupon, message="Coupon code generated successfully")


# ── Partner Portal (Mobile Dashboard) ───────────────────────

from sqlalchemy import select as _select
from app.models.privilege_cards import Partner as _Partner
from app.core.exceptions import NotFoundException as _NotFoundExc
from app.features.rewards import service as _rewards_svc
from app.features.rewards import schemas as _rewards_schemas


@router.get("/rewards/partner/dashboard", summary="Get partner dashboard stats")
async def partner_dashboard_endpoint(
    db: AsyncSession = Depends(get_db),
    user: User = Depends(partner_req),
) -> ORJSONResponse:
    stmt = _select(_Partner).where(_Partner.admin_id == user.id)
    partner = (await db.execute(stmt)).scalar_one_or_none()
    if not partner:
        raise _NotFoundExc("You are not assigned to any partner profile.")

    stats = await _rewards_svc.get_partner_dashboard(partner.id, db)
    return success_response(data=stats)



@router.get("/rewards/partner/redemptions", summary="Get partner redemptions log")
async def partner_redemptions_endpoint(
    db: AsyncSession = Depends(get_db),
    user: User = Depends(partner_req),
) -> ORJSONResponse:
    stmt = _select(_Partner).where(_Partner.admin_id == user.id)
    partner = (await db.execute(stmt)).scalar_one_or_none()
    if not partner:
        raise _NotFoundExc("You are not assigned to any partner profile.")

    data = await _rewards_svc.get_partner_redemptions(partner.id, db)
    return success_response(data=data)


@router.post("/rewards/partner/scan", summary="Scan and confirm user QR code")
async def partner_scan_endpoint(
    body: _rewards_schemas.PartnerScanRequest,
    db: AsyncSession = Depends(get_db),
    user: User = Depends(partner_req),
) -> ORJSONResponse:
    stmt = _select(_Partner).where(_Partner.admin_id == user.id)
    partner = (await db.execute(stmt)).scalar_one_or_none()
    if not partner:
        raise _NotFoundExc("You are not assigned to any partner profile.")

    result = await _rewards_svc.partner_scan_token(body.token, partner.id, db)
    return success_response(data=result, message="QR Code scanned successfully!")

