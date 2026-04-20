"""
Prime Business Network – Chapters Router.
"""

from __future__ import annotations

from typing import List
from uuid import UUID

from fastapi import APIRouter, Depends
from fastapi.responses import ORJSONResponse
from sqlalchemy.ext.asyncio import AsyncSession

from app.core.dependencies import get_db
from app.core.response import success_response
from app.features.auth.dependencies import get_current_user, require_role
from app.features.chapters.schemas import ChapterMemberResponse, ChapterResponse, MyMembershipResponse
from app.features.chapters.service import (
    get_all_members,
    get_chapter_members,
    get_my_memberships,
    list_active_chapters,
    remove_member,
    get_occupied_industry_ids,
)
from app.models.user import User, UserRole

router = APIRouter(tags=["Chapters"])


@router.get(
    "/members/all",
    summary="List all active members across all chapters",
)
async def list_all_members_endpoint(
    current_user: User = Depends(get_current_user),
    db: AsyncSession = Depends(get_db),
) -> ORJSONResponse:
    members = await get_all_members(db, requester_id=current_user.id)
    for m in members:
        m["user_id"] = str(m["user_id"])
        m["industry_category"]["id"] = str(m["industry_category"]["id"])
        if m["business"]:
            m["business"]["id"] = str(m["business"]["id"])
            
    return success_response(data=members)


@router.get("", summary="List active chapters", response_model=None)
async def list_chapters_endpoint(
    db: AsyncSession = Depends(get_db),
    # Optional auth: depends on requirements, let's keep it public/accessible to all
) -> ORJSONResponse:
    chapters = await list_active_chapters(db)
    return success_response(
        data=[
            {
                "id": str(c.id),
                "name": c.name,
                "description": c.description,
                "meeting_schedule": c.meeting_schedule,
                "is_active": c.is_active,
            }
            for c in chapters
        ]
    )


@router.get(
    "/my-memberships",
    summary="Get my memberships",
)
async def my_memberships_endpoint(
    current_user: User = Depends(require_role([UserRole.MEMBER, UserRole.CHAPTER_ADMIN, UserRole.SUPER_ADMIN])),
    db: AsyncSession = Depends(get_db),
) -> ORJSONResponse:
    memberships = await get_my_memberships(current_user.id, db)
    # Convert UUIDs to strings in the response dictionary for consistency
    # (ORJSON handles UUIDs, but converting explicitly avoids schema validation issues if returning directly)
    for m in memberships:
        m["id"] = str(m["id"])
        m["chapter"]["id"] = str(m["chapter"]["id"])
        m["industry_category"]["id"] = str(m["industry_category"]["id"])
        
    return success_response(data=memberships)


@router.get(
    "/{chapter_id}/members",
    summary="List members of a chapter",
)
async def chapter_members_endpoint(
    chapter_id: UUID,
    # Any authenticated user can view members usually, or restrict if needed. Let's allow any authed user.
    current_user: User = Depends(get_current_user),
    db: AsyncSession = Depends(get_db),
) -> ORJSONResponse:
    members = await get_chapter_members(chapter_id, db)
    for m in members:
        m["user_id"] = str(m["user_id"])
        m["industry_category"]["id"] = str(m["industry_category"]["id"])
        if m["business"]:
            m["business"]["id"] = str(m["business"]["id"])
            
    return success_response(data=members)


@router.delete(
    "/{chapter_id}/members/{user_id}",
    summary="Remove member from chapter",
    dependencies=[Depends(require_role([UserRole.CHAPTER_ADMIN, UserRole.SUPER_ADMIN]))]
)
async def remove_member_endpoint(
    chapter_id: UUID,
    user_id: UUID,
    current_user: User = Depends(get_current_user),
    db: AsyncSession = Depends(get_db),
) -> ORJSONResponse:
    await remove_member(chapter_id, user_id, current_user.id, db)
    return success_response(
        data={"message": "Member removed successfully"}
    )


@router.get(
    "/{chapter_id}/occupied-industries",
    summary="Get list of occupied industry IDs for a chapter",
)
async def get_occupied_industries_endpoint(
    chapter_id: UUID,
    db: AsyncSession = Depends(get_db),
) -> ORJSONResponse:
    ids = await get_occupied_industry_ids(chapter_id, db)
    return success_response(data=[str(i) for i in ids])
