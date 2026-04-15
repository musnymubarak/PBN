"""
Prime Business Network – Admin Router.

All endpoints restricted to SUPER_ADMIN role.
"""

from __future__ import annotations

from typing import Optional
from uuid import UUID

from fastapi import APIRouter, Depends, Query
from fastapi.responses import ORJSONResponse
from sqlalchemy import select
from sqlalchemy.ext.asyncio import AsyncSession

from app.core.dependencies import get_db
from app.core.response import success_response
from app.features.auth.dependencies import require_role
from app.features.admin import service
from app.models.user import User, UserRole

router = APIRouter(tags=["Admin"])

admin_req = require_role([UserRole.SUPER_ADMIN])


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
    current_user: User = Depends(admin_req),
    db: AsyncSession = Depends(get_db),
) -> ORJSONResponse:
    result = await service.list_all_referrals(db)
    return success_response(data=result)
