"""
Prime Business Network – Verification Requests Router.
"""

from __future__ import annotations

import uuid
from typing import Optional
from fastapi import APIRouter, Depends, Query, HTTPException
from fastapi.responses import ORJSONResponse
from pydantic import BaseModel
from sqlalchemy import select, desc, and_
from sqlalchemy.ext.asyncio import AsyncSession

from app.core.dependencies import get_db
from app.core.exceptions import BadRequestException, NotFoundException
from app.core.response import success_response
from app.features.auth.dependencies import get_current_user
from app.models.user import User, VerificationLevel, UserRole
from app.models.businesses import Business
from app.models.verification_requests import VerificationRequest
from app.features.notifications.service import send_push_notification

router = APIRouter(prefix="/verification-requests", tags=["Verification Requests"])


class RejectRequest(BaseModel):
    reason: str


@router.get("/me/status", summary="Get verification status details for current user")
async def get_my_verification_status(
    current_user: User = Depends(get_current_user),
    db: AsyncSession = Depends(get_db)
) -> ORJSONResponse:
    # 1. Check generated business value
    business_value = float(current_user.cumulative_value_generated)
    business_value_met = business_value >= 25000.0

    # 2. Check portfolio completeness
    stmt = select(Business).where(Business.owner_user_id == current_user.id)
    business = (await db.execute(stmt)).scalar_one_or_none()

    portfolio_complete = False
    details = {}
    
    if business:
        has_logo = bool(business.logo_url)
        has_website = bool(business.website)
        has_address = bool(business.address)
        has_established = bool(business.established_year)
        has_br = bool(business.br_number)
        has_brochure = bool(business.brochure_url)
        has_social = bool(business.linkedin_url or business.facebook_url or business.instagram_url)
        
        portfolio_complete = all([
            has_logo,
            has_website,
            has_address,
            has_established,
            has_br,
            has_brochure,
            has_social
        ])
        
        details = {
            "has_logo": has_logo,
            "has_website": has_website,
            "has_address": has_address,
            "has_established": has_established,
            "has_br": has_br,
            "has_brochure": has_brochure,
            "has_social": has_social,
        }
    else:
        details = {
            "has_logo": False,
            "has_website": False,
            "has_address": False,
            "has_established": False,
            "has_br": False,
            "has_brochure": False,
            "has_social": False,
        }

    # 3. Get latest request
    req_stmt = (
        select(VerificationRequest)
        .where(VerificationRequest.user_id == current_user.id)
        .order_by(desc(VerificationRequest.created_at))
        .limit(1)
    )
    req = (await db.execute(req_stmt)).scalar_one_or_none()

    current_status = None
    rejection_reason = None
    request_id = None
    created_at = None

    if req:
        current_status = req.status
        rejection_reason = req.rejection_reason
        request_id = str(req.id)
        created_at = req.created_at.isoformat()

    # Can request verification if criteria is met and no pending/approved request exists
    can_request = (
        business_value_met and 
        portfolio_complete and 
        current_status != "pending" and 
        current_status != "approved"
    )

    return success_response(data={
        "business_value": business_value,
        "business_value_met": business_value_met,
        "portfolio_complete": portfolio_complete,
        "portfolio_checks": details,
        "can_request": can_request,
        "request_id": request_id,
        "status": current_status,
        "rejection_reason": rejection_reason,
        "created_at": created_at,
    })


@router.post("/me/request", summary="Submit a verification request")
async def request_verification(
    current_user: User = Depends(get_current_user),
    db: AsyncSession = Depends(get_db)
) -> ORJSONResponse:
    # 1. Run eligibility checks
    business_value = float(current_user.cumulative_value_generated)
    if business_value < 25000.0:
        raise BadRequestException(
            f"You have generated LKR {business_value:,.2f}. Verification requires a minimum of LKR 25,000.00.",
            code="INSUFFICIENT_VALUE"
        )

    stmt = select(Business).where(Business.owner_user_id == current_user.id)
    business = (await db.execute(stmt)).scalar_one_or_none()
    
    if not business:
        raise BadRequestException("Please complete your business portfolio profile first.", code="PORTFOLIO_INCOMPLETE")

    has_logo = bool(business.logo_url)
    has_website = bool(business.website)
    has_address = bool(business.address)
    has_established = bool(business.established_year)
    has_br = bool(business.br_number)
    has_brochure = bool(business.brochure_url)
    has_social = bool(business.linkedin_url or business.facebook_url or business.instagram_url)
    
    if not all([has_logo, has_website, has_address, has_established, has_br, has_brochure, has_social]):
        raise BadRequestException("All required portfolio fields must be filled to request verification.", code="PORTFOLIO_INCOMPLETE")

    # 2. Check if a pending or approved request already exists
    req_stmt = (
        select(VerificationRequest)
        .where(
            and_(
                VerificationRequest.user_id == current_user.id,
                VerificationRequest.status.in_(["pending", "approved"])
            )
        )
        .limit(1)
    )
    existing = (await db.execute(req_stmt)).first()
    if existing:
        raise BadRequestException("A verification request is already pending or approved.", code="REQUEST_ALREADY_EXISTS")

    # 3. Create request
    new_req = VerificationRequest(
        user_id=current_user.id,
        status="pending"
    )
    db.add(new_req)
    await db.commit()

    return success_response(
        data={
            "id": str(new_req.id),
            "status": new_req.status,
            "created_at": new_req.created_at.isoformat()
        },
        message="Verification request submitted successfully."
    )


# ── Admin Panel API ─────────────────────────────────────────────────────────

@router.get("/admin/list", summary="List verification requests (admin only)")
async def admin_list_verification_requests(
    status: Optional[str] = Query(None, regex="^(pending|approved|rejected)$"),
    page: int = Query(1, gt=0),
    limit: int = Query(20, gt=0, le=100),
    current_user: User = Depends(get_current_user),
    db: AsyncSession = Depends(get_db)
) -> ORJSONResponse:
    if current_user.role not in [UserRole.ADMIN, UserRole.SUPER_ADMIN]:
        raise HTTPException(status_code=403, detail="Admin privileges required")

    stmt = select(VerificationRequest).join(User, VerificationRequest.user_id == User.id)
    if status:
        stmt = stmt.where(VerificationRequest.status == status)

    stmt = stmt.order_by(desc(VerificationRequest.created_at))
    
    # Total count
    from sqlalchemy import func
    count_stmt = select(func.count(VerificationRequest.id))
    if status:
        count_stmt = count_stmt.where(VerificationRequest.status == status)
    total = (await db.execute(count_stmt)).scalar() or 0

    # Paginate
    stmt = stmt.offset((page - 1) * limit).limit(limit)
    result = await db.execute(stmt)
    requests = result.scalars().all()

    data = []
    for r in requests:
        # Fetch associated business
        biz_stmt = select(Business).where(Business.owner_user_id == r.user_id).limit(1)
        biz = (await db.execute(biz_stmt)).scalar_one_or_none()
        
        data.append({
            "id": str(r.id),
            "user_id": str(r.user_id),
            "user_name": r.user.full_name,
            "user_email": r.user.email,
            "user_phone": r.user.phone_number,
            "business_name": biz.business_name if biz else "N/A",
            "business_value": float(r.user.cumulative_value_generated),
            "status": r.status,
            "rejection_reason": r.rejection_reason,
            "created_at": r.created_at.isoformat(),
            "updated_at": r.updated_at.isoformat(),
            "business": {
                "description": biz.description if biz else None,
                "website": biz.website if biz else None,
                "logo_url": biz.logo_url if biz else None,
                "address": biz.address if biz else None,
                "established_year": biz.established_year if biz else None,
                "br_number": biz.br_number if biz else None,
                "brochure_url": biz.brochure_url if biz else None,
                "google_maps_url": biz.google_maps_url if biz else None,
                "linkedin_url": biz.linkedin_url if biz else None,
                "facebook_url": biz.facebook_url if biz else None,
                "instagram_url": biz.instagram_url if biz else None,
            } if biz else None
        })

    return success_response(data={
        "requests": data,
        "total": total,
        "page": page,
        "limit": limit
    })


@router.post("/admin/{request_id}/approve", summary="Approve verification request (admin only)")
async def admin_approve_request(
    request_id: uuid.UUID,
    current_user: User = Depends(get_current_user),
    db: AsyncSession = Depends(get_db)
) -> ORJSONResponse:
    if current_user.role not in [UserRole.ADMIN, UserRole.SUPER_ADMIN]:
        raise HTTPException(status_code=403, detail="Admin privileges required")

    stmt = select(VerificationRequest).where(VerificationRequest.id == request_id)
    req = (await db.execute(stmt)).scalar_one_or_none()
    if not req:
        raise NotFoundException("Verification request not found")

    if req.status != "pending":
        raise BadRequestException(f"Request is already {req.status}.", code="INVALID_STATUS")

    req.status = "approved"
    
    # Update user's verification level
    user_stmt = select(User).where(User.id == req.user_id)
    user = (await db.execute(user_stmt)).scalar_one_or_none()
    if user:
        user.verification_level = VerificationLevel.VERIFIED
        from datetime import datetime
        user.verification_updated_at = datetime.now()
        
        # Calculate their correct tier based on accumulated value
        val = user.cumulative_value_generated
        if val >= 5000000:
            user.verification_level = VerificationLevel.PLATINUM
        elif val >= 2500000:
            user.verification_level = VerificationLevel.GOLD
        elif val >= 1000000:
            user.verification_level = VerificationLevel.SILVER
            
        await db.flush()

        # Send celebration push notification
        try:
            await send_push_notification(
                user_id=user.id,
                title="Account Verified! 🏆",
                body=f"Congratulations! Your verification request has been approved. You are now a {user.verification_level.value.upper()} network member.",
                notification_type="VERIFICATION_UPGRADE",
                data={"level": user.verification_level.value, "route": "/profile"}
            )
        except Exception:
            pass

    await db.commit()
    return success_response(message="Verification request approved successfully.")


@router.post("/admin/{request_id}/reject", summary="Reject verification request (admin only)")
async def admin_reject_request(
    request_id: uuid.UUID,
    body: RejectRequest,
    current_user: User = Depends(get_current_user),
    db: AsyncSession = Depends(get_db)
) -> ORJSONResponse:
    if current_user.role not in [UserRole.ADMIN, UserRole.SUPER_ADMIN]:
        raise HTTPException(status_code=403, detail="Admin privileges required")

    stmt = select(VerificationRequest).where(VerificationRequest.id == request_id)
    req = (await db.execute(stmt)).scalar_one_or_none()
    if not req:
        raise NotFoundException("Verification request not found")

    if req.status != "pending":
        raise BadRequestException(f"Request is already {req.status}.", code="INVALID_STATUS")

    req.status = "rejected"
    req.rejection_reason = body.reason.strip()

    # Send rejection push notification
    try:
        await send_push_notification(
            user_id=req.user_id,
            title="Verification Rejected ❌",
            body=f"Your verification request was rejected: {body.reason}. Tap to fix and request again.",
            notification_type="VERIFICATION_REJECTED",
            data={"route": "/profile"}
        )
    except Exception:
        pass

    await db.commit()
    return success_response(message="Verification request rejected successfully.")
