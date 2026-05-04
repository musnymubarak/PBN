"""
Prime Business Network – Admin Router.

All endpoints restricted to SUPER_ADMIN role.
"""

from __future__ import annotations

from typing import Optional
from uuid import UUID

from fastapi import APIRouter, Depends, Query, BackgroundTasks
from fastapi.responses import ORJSONResponse
from sqlalchemy import select, func
from sqlalchemy.ext.asyncio import AsyncSession

from app.core.dependencies import get_db
from app.core.response import success_response
from app.features.auth.dependencies import require_role
from app.features.admin import service
from pydantic import BaseModel, Field
from app.models.user import User, UserRole
from app.models.marketplace import MarketplaceListing, ListingStatus
from app.features.matchmaking.tasks import process_new_marketplace_listing

router = APIRouter(tags=["Admin"])

admin_req = require_role([UserRole.SUPER_ADMIN])

class AdminClubUpdate(BaseModel):
    name: Optional[str] = None
    description: Optional[str] = None
    industry_ids: Optional[list[UUID]] = None
    min_members: Optional[int] = None
    is_active: Optional[bool] = None

class MarketplaceRejectRequest(BaseModel):
    reason: str = Field(..., min_length=5)


@router.get("/admin/users", summary="List all users (paginated)")
async def list_users_endpoint(
    role: Optional[str] = Query(None),
    is_active: Optional[bool] = Query(None),
    search: Optional[str] = Query(None),
    chapter_id: Optional[UUID] = Query(None),
    industry_id: Optional[UUID] = Query(None),
    page: int = Query(1, ge=1),
    page_size: int = Query(20, ge=1, le=100),
    current_user: User = Depends(admin_req),
    db: AsyncSession = Depends(get_db),
) -> ORJSONResponse:
    result = await service.list_users(
        role, is_active, search, page, page_size, db,
        chapter_id=chapter_id, industry_id=industry_id
    )
    return success_response(data=result)


@router.get("/admin/industries", summary="List all industry categories")
async def list_industries_endpoint(
    current_user: User = Depends(admin_req),
    db: AsyncSession = Depends(get_db),
) -> ORJSONResponse:
    """Helper for the admin panel to populate industry filters."""
    from app.models.industry_categories import IndustryCategory
    stmt = select(IndustryCategory).where(IndustryCategory.is_active == True).order_by(IndustryCategory.name)
    results = (await db.execute(stmt)).scalars().all()
    return success_response(data=[
        {"id": str(i.id), "name": i.name, "slug": i.slug} for i in results
    ])


@router.patch("/admin/users/{user_id}/deactivate", summary="Deactivate a user")
async def deactivate_user_endpoint(
    user_id: UUID,
    current_user: User = Depends(admin_req),
    db: AsyncSession = Depends(get_db),
) -> ORJSONResponse:
    result = await service.deactivate_user(user_id, current_user.id, db)
    return success_response(data=result, message="User deactivated successfully")


@router.patch("/admin/users/{user_id}/reactivate", summary="Reactivate a user")
async def reactivate_user_endpoint(
    user_id: UUID,
    current_user: User = Depends(admin_req),
    db: AsyncSession = Depends(get_db),
) -> ORJSONResponse:
    result = await service.reactivate_user(user_id, current_user.id, db)
    return success_response(data=result, message="User reactivated successfully")


@router.patch("/admin/users/{user_id}", summary="Update user account (Role/Status)")
async def update_user_endpoint(
    user_id: UUID,
    payload: dict,
    current_user: User = Depends(admin_req),
    db: AsyncSession = Depends(get_db),
) -> ORJSONResponse:
    result = await service.update_user(user_id, current_user.id, payload, db)
    return success_response(data=result, message="User updated successfully")


@router.delete("/admin/users/{user_id}/chapter", summary="Remove user from chapter")
async def remove_user_chapter_endpoint(
    user_id: UUID,
    current_user: User = Depends(admin_req),
    db: AsyncSession = Depends(get_db),
) -> ORJSONResponse:
    result = await service.remove_user_from_chapter(user_id, current_user.id, db)
    return success_response(data=result, message="User removed from chapter successfully")



@router.get("/admin/users/{user_id}/masked", summary="Get masked PII data")
async def masked_user_endpoint(
    user_id: UUID,
    current_user: User = Depends(admin_req),
    db: AsyncSession = Depends(get_db),
) -> ORJSONResponse:
    result = await service.get_masked_user_data(user_id, db)
    return success_response(data=result)


@router.get("/admin/audit-logs", summary="View audit trail (paginated)")
async def audit_logs_endpoint(
    entity_type: Optional[str] = Query(None),
    action: Optional[str] = Query(None),
    page: int = Query(1, ge=1),
    page_size: int = Query(20, ge=1, le=100),
    current_user: User = Depends(admin_req),
    db: AsyncSession = Depends(get_db),
) -> ORJSONResponse:
    result = await service.list_audit_logs(entity_type, action, page, page_size, db)
    return success_response(data=result)


@router.get("/admin/export", summary="Export platform aggregate data")
async def export_data_endpoint(
    current_user: User = Depends(admin_req),
    db: AsyncSession = Depends(get_db),
) -> ORJSONResponse:
    result = await service.export_platform_data(db)
    return success_response(data=result)


@router.get("/admin/referrals", summary="List all referrals (admin)")
async def list_all_referrals_endpoint(
    search: Optional[str] = Query(None),
    status: Optional[str] = Query(None),
    page: int = Query(1, ge=1),
    page_size: int = Query(20, ge=1, le=100),
    current_user: User = Depends(admin_req),
    db: AsyncSession = Depends(get_db),
) -> ORJSONResponse:
    result = await service.list_all_referrals(search, status, page, page_size, db)
    return success_response(data=result)


class AdminClubCreate(BaseModel):
    name: str
    description: Optional[str] = None
    industry_ids: list[UUID]
    min_members: int = 10

class AdminClubUpdate(BaseModel):
    name: Optional[str] = None
    description: Optional[str] = None
    industry_ids: Optional[list[UUID]] = None
    min_members: Optional[int] = None
    is_active: Optional[bool] = None


@router.post("/admin/clubs", summary="Create a new horizontal club")
async def create_club_endpoint(
    data: AdminClubCreate,
    current_user: User = Depends(admin_req),
    db: AsyncSession = Depends(get_db),
) -> ORJSONResponse:
    from app.models.horizontal_clubs import HorizontalClub, HorizontalClubIndustry
    club = HorizontalClub(
        name=data.name,
        description=data.description,
        min_members=data.min_members,
        is_active=True
    )
    db.add(club)
    await db.flush()
    
    for ind_id in data.industry_ids:
        db.add(HorizontalClubIndustry(club_id=club.id, industry_id=ind_id))
    
    await db.commit()
    await db.refresh(club)
    
    return success_response(
        data={"id": str(club.id), "name": club.name},
        message="Horizontal Club created successfully"
    )

@router.patch("/admin/clubs/{club_id}", summary="Update an existing horizontal club")
async def update_club_endpoint(
    club_id: UUID,
    data: AdminClubUpdate,
    current_user: User = Depends(admin_req),
    db: AsyncSession = Depends(get_db),
) -> ORJSONResponse:
    from app.models.horizontal_clubs import HorizontalClub, HorizontalClubIndustry
    from sqlalchemy.orm import selectinload
    
    stmt = select(HorizontalClub).where(HorizontalClub.id == club_id).options(selectinload(HorizontalClub.industries))
    club = (await db.execute(stmt)).scalar_one_or_none()
    
    if not club:
        return success_response(message="Club not found", status_code=404)
        
    if data.name is not None: club.name = data.name
    if data.description is not None: club.description = data.description
    if data.min_members is not None: club.min_members = data.min_members
    if data.is_active is not None: club.is_active = data.is_active
    
    if data.industry_ids is not None:
        # Clear existing and re-add
        from sqlalchemy import delete
        await db.execute(delete(HorizontalClubIndustry).where(HorizontalClubIndustry.club_id == club_id))
        for ind_id in data.industry_ids:
            db.add(HorizontalClubIndustry(club_id=club_id, industry_id=ind_id))
            
    await db.commit()
    await db.refresh(club)
    
    return success_response(data={"id": str(club.id), "name": club.name}, message="Club updated successfully")


@router.delete("/admin/clubs/{club_id}", summary="Delete a horizontal club")
async def delete_club_endpoint(
    club_id: UUID,
    current_user: User = Depends(admin_req),
    db: AsyncSession = Depends(get_db),
) -> ORJSONResponse:
    from app.models.horizontal_clubs import HorizontalClub
    stmt = select(HorizontalClub).where(HorizontalClub.id == club_id)
    club = (await db.execute(stmt)).scalar_one_or_none()
    
    if club:
        await db.delete(club)
        await db.commit()
        
    return success_response(message="Club deleted successfully")


@router.get("/admin/fees", summary="List all active fee schedules")
async def list_fees_endpoint(
    current_user: User = Depends(admin_req),
    db: AsyncSession = Depends(get_db),
) -> ORJSONResponse:
    from app.models.memberships import FeeSchedule
    stmt = select(FeeSchedule).where(FeeSchedule.is_active == True).order_by(FeeSchedule.membership_type)
    results = (await db.execute(stmt)).scalars().all()
    return success_response(data=[
        {
            "membership_type": f.membership_type.value,
            "annual_fee": float(f.annual_fee),
            "per_forum_fee": float(f.per_forum_fee),
            "currency": f.currency
        } for f in results
    ])


@router.patch("/admin/fees/{m_type}", summary="Update a fee schedule")
async def update_fee_endpoint(
    m_type: str,
    payload: dict,
    current_user: User = Depends(admin_req),
    db: AsyncSession = Depends(get_db),
) -> ORJSONResponse:
    from app.models.memberships import FeeSchedule
    stmt = select(FeeSchedule).where(FeeSchedule.membership_type == m_type)
    fee = (await db.execute(stmt)).scalar_one_or_none()
    
    if not fee:
        return success_response(message="Fee schedule not found", status_code=404)
        
    if "annual_fee" in payload: fee.annual_fee = payload["annual_fee"]
    if "per_forum_fee" in payload: fee.per_forum_fee = payload["per_forum_fee"]
    
    await db.commit()
    return success_response(message=f"Fee for {m_type} updated successfully")


@router.get("/admin/marketplace/listings", summary="List all marketplace listings for moderation")
async def admin_list_listings_endpoint(
    status: Optional[str] = Query(None),
    is_approved: Optional[bool] = Query(None),
    page: int = Query(1, ge=1),
    page_size: int = Query(20, ge=1, le=100),
    current_user: User = Depends(admin_req),
    db: AsyncSession = Depends(get_db),
) -> ORJSONResponse:
    from sqlalchemy import desc
    from sqlalchemy.orm import joinedload
    stmt = select(MarketplaceListing).options(
        joinedload(MarketplaceListing.seller),
        joinedload(MarketplaceListing.industry)
    ).order_by(desc(MarketplaceListing.created_at))

    if status:
        stmt = stmt.where(MarketplaceListing.status == status)
    if is_approved is not None:
        stmt = stmt.where(MarketplaceListing.is_approved == is_approved)

    # Count
    count_stmt = select(func.count(1)).select_from(stmt.subquery())
    total = (await db.execute(count_stmt)).scalar_one()

    # Paginate
    stmt = stmt.offset((page - 1) * page_size).limit(page_size)
    results = (await db.execute(stmt)).scalars().all()

    return success_response(data={
        "listings": [
            {
                "id": str(l.id),
                "title": l.title,
                "description": l.description,
                "price": float(l.price),
                "member_price": float(l.member_price) if l.member_price else None,
                "currency": l.currency,
                "image_urls": l.image_urls,
                "seller": {
                    "full_name": l.seller.full_name,
                    "business_name": getattr(l.seller, 'business_name', '—') # Assuming seller has business_name
                },
                "category": l.category.value,
                "status": l.status.value,
                "is_approved": l.is_approved,
                "rejection_reason": l.rejection_reason,
                "created_at": l.created_at.isoformat()
            } for l in results
        ],
        "total": total,
        "page": page,
        "page_size": page_size
    })


@router.patch("/admin/marketplace/listings/{listing_id}/approve", summary="Approve a listing")
async def approve_listing_endpoint(
    listing_id: UUID,
    background_tasks: BackgroundTasks,
    current_user: User = Depends(admin_req),
    db: AsyncSession = Depends(get_db),
) -> ORJSONResponse:
    stmt = select(MarketplaceListing).where(MarketplaceListing.id == listing_id)
    listing = (await db.execute(stmt)).scalar_one_or_none()

    if not listing:
        return success_response(message="Listing not found", status_code=404)

    if not listing.is_approved:
        listing.is_approved = True
        listing.rejection_reason = None # Clear previous reason
        await db.commit()
        # Trigger AI Matchmaking only AFTER approval
        background_tasks.add_task(process_new_marketplace_listing, listing.id)

    return success_response(message="Listing approved successfully")


@router.patch("/admin/marketplace/listings/{listing_id}/reject", summary="Reject/Unapprove a listing")
async def reject_listing_endpoint(
    listing_id: UUID,
    data: MarketplaceRejectRequest,
    current_user: User = Depends(admin_req),
    db: AsyncSession = Depends(get_db),
) -> ORJSONResponse:
    stmt = select(MarketplaceListing).where(MarketplaceListing.id == listing_id)
    listing = (await db.execute(stmt)).scalar_one_or_none()

    if not listing:
        return success_response(message="Listing not found", status_code=404)

    listing.is_approved = False
    listing.rejection_reason = data.reason
    await db.commit()
    return success_response(message="Listing rejected/unapproved with reason")
