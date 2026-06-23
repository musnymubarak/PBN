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
    ApplicationAdminUpdate,
    OnboardingDetailsUpdate,
    OnboardingTshirtUpdate,
)
from app.features.applications.service import (
    create_application,
    get_active_industry_categories,
    get_application_by_id,
    get_application_history,
    get_user_applications,
    list_applications,
    update_application_status,
    update_application_status,
    update_application_details,
    delete_application,
    get_onboarding_status,
    update_onboarding_details,
    submit_onboarding_tshirt,
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
    dependencies=[Depends(require_role([UserRole.SUPER_ADMIN, UserRole.ADMIN, UserRole.CHAPTER_ADMIN]))],
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
    dependencies=[Depends(require_role([UserRole.SUPER_ADMIN, UserRole.ADMIN, UserRole.CHAPTER_ADMIN]))],
)
async def get_application_detail_endpoint(
    app_id: UUID,
    db: AsyncSession = Depends(get_db),
) -> ORJSONResponse:
    from app.models.chapters import Chapter
    from app.models.industry_categories import IndustryCategory
    from sqlalchemy import select
    
    app = await get_application_by_id(app_id, db)
    history = await get_application_history(app.id, db)
    
    # Get chapter name
    chap_stmt = select(Chapter.name).where(Chapter.id == app.chapter_id)
    chapter_name = (await db.execute(chap_stmt)).scalar() or "Unknown"

    # Get industry name
    ind_stmt = select(IndustryCategory.name).where(IndustryCategory.id == app.industry_category_id)
    industry_name = (await db.execute(ind_stmt)).scalar() or "Unknown"
    
    return success_response(
        data={
            "id": str(app.id),
            "full_name": app.full_name,
            "business_name": app.business_name,
            "contact_number": app.contact_number,
            "email": app.email,
            "district": app.district,
            "industry_category_id": str(app.industry_category_id),
            "industry_name": industry_name,
            "chapter_id": str(app.chapter_id),
            "chapter_name": chapter_name,
            "status": app.status.value,
            "fit_call_date": app.fit_call_date.isoformat() if app.fit_call_date else None,
            "notes": app.notes,
            "designation": app.designation,
            "decision_authority": app.decision_authority.value if app.decision_authority else None,
            "years_in_operation": app.years_in_operation,
            "business_legal_type": app.business_legal_type.value if app.business_legal_type else None,
            "business_registration_number": app.business_registration_number,
            "website_url": app.website_url,
            "linkedin_url": app.linkedin_url,
            "referred_by_user_id": str(app.referred_by_user_id) if app.referred_by_user_id else None,
            "what_you_offer": app.what_you_offer,
            "what_you_seek": app.what_you_seek,
            "tshirt_size": app.tshirt_size.value if app.tshirt_size else None,
            "onboarding_completed_at": app.onboarding_completed_at.isoformat() if app.onboarding_completed_at else None,
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
    current_user: User = Depends(require_role([UserRole.SUPER_ADMIN, UserRole.ADMIN])),
    db: AsyncSession = Depends(get_db),
) -> ORJSONResponse:
    app = await update_application_status(app_id, current_user, data, db)
    return success_response(
        data={
            "id": str(app.id),
            "status": app.status.value,
        }
    )


@router.patch(
    "/applications/{app_id}",
    summary="Update application details (Admin)",
    dependencies=[Depends(require_role([UserRole.SUPER_ADMIN, UserRole.ADMIN]))],
)
async def patch_application_details_endpoint(
    app_id: UUID,
    data: ApplicationAdminUpdate,
    current_user: User = Depends(get_current_user),
    db: AsyncSession = Depends(get_db),
) -> ORJSONResponse:
    app = await update_application_details(app_id, current_user, data.model_dump(exclude_unset=True), db)
    return success_response(
        data={
            "id": str(app.id),
            "district": app.district,
            "chapter_id": str(app.chapter_id) if app.chapter_id else None,
        }
    )


@router.delete(
    "/applications/{app_id}",
    summary="Delete application",
    dependencies=[Depends(require_role([UserRole.SUPER_ADMIN, UserRole.ADMIN]))],
)
async def delete_application_endpoint(
    app_id: UUID,
    db: AsyncSession = Depends(get_db),
) -> ORJSONResponse:
    await delete_application(app_id, db)
    return success_response(message="Application deleted successfully")


# ── Onboarding (public; token-authenticated) ────────────────────────────────

@router.get(
    "/applications/onboard/{token}",
    summary="Resolve onboarding link (public, token-authenticated)",
)
async def get_onboarding_status_endpoint(
    token: str,
    db: AsyncSession = Depends(get_db),
) -> ORJSONResponse:
    result = await get_onboarding_status(token, db)
    return success_response(data={
        **result,
        "application_id": str(result["application_id"]),
        "expires_at": result["expires_at"].isoformat() if result.get("expires_at") else None,
        "decision_authority": (
            result["decision_authority"].value if result.get("decision_authority") else None
        ),
        "business_legal_type": (
            result["business_legal_type"].value if result.get("business_legal_type") else None
        ),
        "tshirt_size": (
            result["tshirt_size"].value if result.get("tshirt_size") else None
        ),
    })


@router.patch(
    "/applications/onboard/{token}/details",
    summary="Backfill missing Tier-1 fields during onboarding",
)
async def patch_onboarding_details_endpoint(
    token: str,
    data: OnboardingDetailsUpdate,
    db: AsyncSession = Depends(get_db),
) -> ORJSONResponse:
    result = await update_onboarding_details(token, data, db)
    return success_response(data={
        **result,
        "application_id": str(result["application_id"]),
        "expires_at": result["expires_at"].isoformat() if result.get("expires_at") else None,
        "decision_authority": (
            result["decision_authority"].value if result.get("decision_authority") else None
        ),
        "business_legal_type": (
            result["business_legal_type"].value if result.get("business_legal_type") else None
        ),
        "tshirt_size": (
            result["tshirt_size"].value if result.get("tshirt_size") else None
        ),
    })


@router.post(
    "/applications/onboard/{token}/tshirt",
    summary="Record T-shirt size and complete onboarding",
)
async def post_onboarding_tshirt_endpoint(
    token: str,
    data: OnboardingTshirtUpdate,
    db: AsyncSession = Depends(get_db),
) -> ORJSONResponse:
    result = await submit_onboarding_tshirt(token, data, db)
    return success_response(data=result, message="Onboarding completed")
