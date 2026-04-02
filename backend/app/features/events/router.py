"""
Prime Business Network – Events Router.
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
from app.features.events.schemas import (
    EventCreate,
    EventRSVPRequest,
    EventAttendanceRequest
)
from app.features.events.service import (
    create_event,
    list_events,
    mark_attendance,
    update_rsvp,
)
from app.models.user import User, UserRole

router = APIRouter(tags=["Events"])

admin_req = require_role([UserRole.CHAPTER_ADMIN, UserRole.SUPER_ADMIN])
member_req = require_role([UserRole.MEMBER, UserRole.CHAPTER_ADMIN, UserRole.SUPER_ADMIN])


@router.post("/events", summary="Create a new event", status_code=201)
async def create_event_endpoint(
    data: EventCreate,
    current_user: User = Depends(admin_req),
    db: AsyncSession = Depends(get_db),
) -> ORJSONResponse:
    event = await create_event(data, current_user.id, db)
    return success_response(
        data=event,
        message="Event created successfully",
        status_code=201
    )


@router.get("/events", summary="List events")
async def list_events_endpoint(
    chapter_id: Optional[UUID] = Query(None, description="Filter by chapter ID"),
    published_only: bool = Query(True, description="Only show published events"),
    current_user: User = Depends(member_req),
    db: AsyncSession = Depends(get_db),
) -> ORJSONResponse:
    # If not admin, force published_only to True
    if current_user.role not in (UserRole.CHAPTER_ADMIN, UserRole.SUPER_ADMIN):
        published_only = True
        
    events = await list_events(chapter_id, published_only, db)
    return success_response(data=events)


@router.post("/events/{event_id}/rsvp", summary="Update RSVP status", status_code=200)
async def update_rsvp_endpoint(
    event_id: UUID,
    data: EventRSVPRequest,
    current_user: User = Depends(get_current_user),
    db: AsyncSession = Depends(get_db),
) -> ORJSONResponse:
    updated_event = await update_rsvp(event_id, current_user.id, data.status, db)
    return success_response(
        data=updated_event,
        message="RSVP updated successfully"
    )


@router.post("/events/{event_id}/attendance", summary="Mark attendance manually (Admin)", status_code=200)
async def mark_attendance_endpoint(
    event_id: UUID,
    data: EventAttendanceRequest,
    current_user: User = Depends(admin_req),
    db: AsyncSession = Depends(get_db),
) -> ORJSONResponse:
    updated_event = await mark_attendance(event_id, data.user_id, current_user.id, db)
    return success_response(
        data=updated_event,
        message="Attendance marked successfully"
    )
