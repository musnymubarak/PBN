"""
Prime Business Network – Chapters Router.
"""

from __future__ import annotations

from typing import List
from uuid import UUID

import os
import shutil
import uuid

from fastapi import APIRouter, Depends, Query, File, UploadFile
from fastapi.responses import ORJSONResponse
from sqlalchemy.ext.asyncio import AsyncSession

from sqlalchemy import select, func

from app.core.dependencies import get_db
from app.core.exceptions import BadRequestException, NotFoundException
from app.core.response import success_response
from app.features.auth.dependencies import get_current_user, require_role
from app.features.chapters.schemas import ChapterCreate, ChapterMemberResponse, ChapterResponse, ChapterUpdate, MyMembershipResponse
from app.models.chapters import Chapter
from app.features.chapters.service import (
    get_all_members,
    get_chapter_members,
    get_my_memberships,
    list_chapters,
    remove_member,
    get_occupied_industry_ids,
)
from app.models.memberships import ChapterMembership
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


@router.get("", summary="List chapters", response_model=None)
async def list_chapters_endpoint(
    district: str | None = None,
    active_only: bool = Query(True),
    db: AsyncSession = Depends(get_db),
) -> ORJSONResponse:
    from app.features.chapters.service import list_chapters
    chapters = await list_chapters(db, district=district, active_only=active_only)

    # Lookup active member counts per chapter in a single grouped query —
    # used by the admin Analytics Hub "Top Chapters" widget.
    counts_stmt = (
        select(
            ChapterMembership.chapter_id,
            func.count(1).label("members"),
        )
        .where(ChapterMembership.is_active.is_(True))
        .group_by(ChapterMembership.chapter_id)
    )
    counts_rows = (await db.execute(counts_stmt)).all()
    counts_by_chapter = {str(r.chapter_id): int(r.members) for r in counts_rows}

    return success_response(
        data=[
            {
                "id": str(c.id),
                "name": c.name,
                "district": c.district,
                "description": c.description,
                "meeting_schedule": c.meeting_schedule,
                "poster_url": c.poster_url,
                "is_active": c.is_active,
                "member_count": counts_by_chapter.get(str(c.id), 0),
            }
            for c in chapters
        ]
    )


@router.post("", summary="Create a new chapter", dependencies=[Depends(require_role([UserRole.SUPER_ADMIN, UserRole.ADMIN]))])
async def create_chapter_endpoint(
    data: ChapterCreate,
    db: AsyncSession = Depends(get_db),
) -> ORJSONResponse:
    from app.features.chapters.service import create_chapter
    chapter = await create_chapter(data, db)
    return success_response(
        data={"id": str(chapter.id), "name": chapter.name},
        message="Chapter created successfully"
    )


@router.patch("/{chapter_id}", summary="Update a chapter", dependencies=[Depends(require_role([UserRole.SUPER_ADMIN, UserRole.ADMIN]))])
async def update_chapter_endpoint(
    chapter_id: UUID,
    data: ChapterUpdate,
    db: AsyncSession = Depends(get_db),
) -> ORJSONResponse:
    from app.features.chapters.service import update_chapter
    chapter = await update_chapter(chapter_id, data, db)
    return success_response(
        data={"id": str(chapter.id), "name": chapter.name},
        message="Chapter updated successfully"
    )


@router.delete("/{chapter_id}", summary="Delete a chapter", dependencies=[Depends(require_role([UserRole.SUPER_ADMIN, UserRole.ADMIN]))])
async def delete_chapter_endpoint(
    chapter_id: UUID,
    db: AsyncSession = Depends(get_db),
) -> ORJSONResponse:
    from app.features.chapters.service import delete_chapter
    await delete_chapter(chapter_id, db)
    return success_response(
        message="Chapter deleted successfully"
    )


@router.get(
    "/my-memberships",
    summary="Get my memberships",
)
async def my_memberships_endpoint(
    current_user: User = Depends(require_role([UserRole.MEMBER, UserRole.CHAPTER_ADMIN, UserRole.SUPER_ADMIN, UserRole.ADMIN])),
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
    dependencies=[Depends(require_role([UserRole.SUPER_ADMIN, UserRole.ADMIN]))]
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


@router.post(
    "/{chapter_id}/upload-poster",
    summary="Upload a chapter poster image",
    dependencies=[Depends(require_role([UserRole.SUPER_ADMIN, UserRole.ADMIN]))],
)
async def upload_chapter_poster_endpoint(
    chapter_id: UUID,
    file: UploadFile = File(...),
    db: AsyncSession = Depends(get_db),
) -> ORJSONResponse:
    """Upload a poster/banner image for a chapter and persist its URL."""
    chapter = (await db.execute(select(Chapter).where(Chapter.id == chapter_id))).scalar_one_or_none()
    if not chapter:
        raise NotFoundException("Chapter not found")

    MAX_SIZE = 5 * 1024 * 1024  # 5MB
    if file.size and file.size > MAX_SIZE:
        raise BadRequestException(
            message="File too large. Maximum size allowed is 5MB.",
            code="FILE_TOO_LARGE",
        )

    ALLOWED_TYPES = ["image/jpeg", "image/png", "image/webp"]
    if file.content_type not in ALLOWED_TYPES:
        raise BadRequestException(
            message=f"Invalid file format: {file.content_type}. Only JPEG, PNG, and WebP images are allowed.",
            code="INVALID_FORMAT",
        )

    os.makedirs("uploads/chapter-posters", exist_ok=True)
    ext = file.filename.split(".")[-1].lower() if file.filename and "." in file.filename else "jpg"
    if ext not in ["jpg", "jpeg", "png", "webp"]:
        raise BadRequestException(message="Invalid file extension.", code="INVALID_EXTENSION")

    filename = f"chapter_{uuid.uuid4().hex[:8]}.{ext}"
    file_path = f"uploads/chapter-posters/{filename}"
    with open(file_path, "wb") as buffer:
        shutil.copyfileobj(file.file, buffer)

    poster_url = f"/static/chapter-posters/{filename}"
    chapter.poster_url = poster_url
    await db.commit()

    return success_response(data={"poster_url": poster_url}, message="Poster uploaded successfully")
