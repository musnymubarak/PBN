"""
Prime Business Network – Analytics Router.
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
from app.models.user import User, UserRole

from app.features.analytics.service import (
    get_dashboard,
    get_leaderboard,
    get_analytics_roi,
    get_admin_overview
)

router = APIRouter(tags=["Dashboard & Analytics"])

admin_req = require_role([UserRole.CHAPTER_ADMIN, UserRole.SUPER_ADMIN])
member_req = require_role([UserRole.MEMBER, UserRole.CHAPTER_ADMIN, UserRole.SUPER_ADMIN])


@router.get("/dashboard", summary="User Dashboard Overview")
async def dashboard_endpoint(
    current_user: User = Depends(member_req),
    db: AsyncSession = Depends(get_db),
) -> ORJSONResponse:
    payload = await get_dashboard(current_user.id, db)
    return success_response(data=payload)


@router.get("/leaderboard", summary="Chapter Leaderboard")
async def leaderboard_endpoint(
    chapter_id: Optional[UUID] = Query(None),
    period: str = Query("this_month"),
    current_user: User = Depends(member_req),
    db: AsyncSession = Depends(get_db),
) -> ORJSONResponse:
    # If not admin, restrict chapter_id filtering
    if current_user.role not in (UserRole.CHAPTER_ADMIN, UserRole.SUPER_ADMIN):
        # Could force chapter_id = current_user's chapter_id
        pass

    results = await get_leaderboard(chapter_id, period, db)
    return success_response(data=results)


@router.get("/analytics/roi", summary="ROI Time-Series")
async def analytics_roi_endpoint(
    period: str = Query("last_6_months"),
    current_user: User = Depends(member_req),
    db: AsyncSession = Depends(get_db),
) -> ORJSONResponse:
    results = await get_analytics_roi(current_user.id, period, db)
    return success_response(data=results)


@router.get("/admin/analytics/overview", summary="Admin Platform Overview")
async def admin_overview_endpoint(
    current_user: User = Depends(require_role([UserRole.SUPER_ADMIN])),
    db: AsyncSession = Depends(get_db),
) -> ORJSONResponse:
    results = await get_admin_overview(db)
    return success_response(data=results)
