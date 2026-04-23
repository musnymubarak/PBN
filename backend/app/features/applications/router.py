"""
Prime Business Network – Applications Router.

Public and Member endpoints for Applications.
"""

from __future__ import annotations

from typing import Optional
from uuid import UUID

from fastapi import APIRouter, Depends, Query
from fastapi.responses import ORJSONResponse
from sqlalchemy.ext.asyncio import AsyncSession

from app.core.dependencies import get_db
from app.core.response import success_response
from app.features.applications.schemas import (
    ApplicationCreate,
    ApplicationStatusUpdate,
)
from app.features.applications.service import (
    create_application,
    get_active_industry_categories,
    get_application_by_id,
    get_application_history,
    get_user_applications,
    list_applications,
    update_application_status,
    delete_application,
)
from app.features.auth.dependencies import get_current_user, require_role
from app.models.applications import ApplicationStatus
from app.models.user import User, UserRole

router = APIRouter(tags=["Applications"])

# ── Industry Categories ──────────────────────────────────────────────────────

@router.get("/industry-categories", summary="List active industry categories")
async def get_industry_categories_endpoint(
    db: AsyncSession = Depends(get_db),
) -> ORJSONResponse:
    categories = await get_active_industry_categories(db)
    return success_response(
        data=[
            {
                "id": str(c.id),
                "name": c.name,
                "slug": c.slug,
                "description": c.description,
                "is_active": c.is_active,
            }
            for c in categories
        ]
    )

# ── Applications ─────────────────────────────────────────────────────────────

@router.post("/applications", summary="Submit a new application (Public)", status_code=201)
async def submit_application_endpoint(
    data: ApplicationCreate,
    db: AsyncSession = Depends(get_db),
) -> ORJSONResponse:
    app = await create_application(data, db)
    return success_response(
        data={"id": str(app.id), "status": app.status.value},
        status_code=201,
    )


@router.get("/applications/my", summary="Get my applications")
async def get_my_applications_endpoint(
    current_user: User = Depends(get_current_user),
    db: AsyncSession = Depends(get_db),
) -> ORJSONResponse:
    apps = await get_user_applications(current_user.phone_number, db)
    data = []
    for app in apps:
        history = await get_application_history(app.id, db)
        app_dict = {
            "id": str(app.id),
            "full_name": app.full_name,
            "business_name": app.business_name,
            "contact_number": app.contact_number,
            "email": app.email,
            "district": app.district,
            "industry_category_id": str(app.industry_category_id),
            "status": app.status.value,
            "fit_call_date": app.fit_call_date.isoformat() if app.fit_call_date else None,
            "notes": app.notes,
            "created_at": app.created_at.isoformat(),
            "updated_at": app.updated_at.isoformat(),
            "history": [
                {
                    "id": str(h.id),
                    "old_status": h.old_status,
                    "new_status": h.new_status,
                    "notes": h.notes,
                    "changed_by_user_id": str(h.changed_by_user_id) if h.changed_by_user_id else None,
                    "created_at": h.created_at.isoformat(),
                }
                for h in history
            ],
        }
        data.append(app_dict)

    return success_response(data=data)


@router.get(
    "/applications",
    summary="List applications",
    dependencies=[Depends(require_role([UserRole.CHAPTER_ADMIN, UserRole.SUPER_ADMIN]))],
)
async def list_applications_endpoint(
    status: Optional[ApplicationStatus] = Query(None),
    industry_category_id: Optional[UUID] = Query(None),
    page: int = Query(1, ge=1),
    limit: int = Query(20, ge=1, le=100),
    db: AsyncSession = Depends(get_db),
) -> ORJSONResponse:
    apps, total = await list_applications(status, industry_category_id, page, limit, db)
    
    data = [
        {
            "id": str(app["id"]),
            "full_name": app["full_name"],
            "business_name": app["business_name"],
            "contact_number": app["contact_number"],
            "email": app["email"],
            "district": app["district"],
            "industry_category_id": str(app["industry_category_id"]),
            "chapter_id": str(app["chapter_id"]),
            "chapter_name": app["chapter_name"],
            "status": app["status"].value,
            "fit_call_date": app["fit_call_date"].isoformat() if app["fit_call_date"] else None,
            "notes": app["notes"],
            "created_at": app["created_at"].isoformat(),
            "updated_at": app["updated_at"].isoformat(),
        }
        for app in apps
    ]
    
    pages = (total + limit - 1) // limit

    return success_response(
        data={
            "data": data,
            "total": total,
            "page": page,
            "limit": limit,
            "pages": pages,
        }
    )


@router.get(
    "/applications/{app_id}",
    summary="Get application detail",
    dependencies=[Depends(require_role([UserRole.CHAPTER_ADMIN, UserRole.SUPER_ADMIN]))],
)
async def get_application_detail_endpoint(
    app_id: UUID,
    db: AsyncSession = Depends(get_db),
) -> ORJSONResponse:
    from app.models.chapters import Chapter
    from sqlalchemy import select
    
    app = await get_application_by_id(app_id, db)
    history = await get_application_history(app.id, db)
    
    # Get chapter name
    chap_stmt = select(Chapter.name).where(Chapter.id == app.chapter_id)
    chapter_name = (await db.execute(chap_stmt)).scalar() or "Unknown"
    
    return success_response(
        data={
            "id": str(app.id),
            "full_name": app.full_name,
            "business_name": app.business_name,
            "contact_number": app.contact_number,
            "email": app.email,
            "district": app.district,
            "industry_category_id": str(app.industry_category_id),
            "chapter_id": str(app.chapter_id),
            "chapter_name": chapter_name,
            "status": app.status.value,
            "fit_call_date": app.fit_call_date.isoformat() if app.fit_call_date else None,
            "notes": app.notes,
            "created_at": app.created_at.isoformat(),
            "updated_at": app.updated_at.isoformat(),
            "history": [
                {
                    "id": str(h.id),
                    "old_status": h.old_status,
                    "new_status": h.new_status,
                    "notes": h.notes,
                    "changed_by_user_id": str(h.changed_by_user_id) if h.changed_by_user_id else None,
                    "created_at": h.created_at.isoformat(),
                }
                for h in history
            ],
        }
    )


@router.patch(
    "/applications/{app_id}/status",
    summary="Update application status",
)
async def patch_application_status_endpoint(
    app_id: UUID,
    data: ApplicationStatusUpdate,
    current_user: User = Depends(require_role([UserRole.CHAPTER_ADMIN, UserRole.SUPER_ADMIN])),
    db: AsyncSession = Depends(get_db),
) -> ORJSONResponse:
    app = await update_application_status(app_id, current_user, data, db)
    return success_response(
        data={
            "id": str(app.id),
            "status": app.status.value,
        }
    )


@router.delete(
    "/applications/{app_id}",
    summary="Delete application",
    dependencies=[Depends(require_role([UserRole.SUPER_ADMIN]))],
)
async def delete_application_endpoint(
    app_id: UUID,
    db: AsyncSession = Depends(get_db),
) -> ORJSONResponse:
    await delete_application(app_id, db)
    return success_response(message="Application deleted successfully")
