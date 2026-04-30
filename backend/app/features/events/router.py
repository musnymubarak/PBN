"""
Prime Business Network – Events Router.
"""

from __future__ import annotations

from typing import Optional
from uuid import UUID

from fastapi import APIRouter, Depends, Query, File, UploadFile
from fastapi.responses import ORJSONResponse
import os
import shutil
import uuid
import logging
from sqlalchemy.ext.asyncio import AsyncSession

from app.core.dependencies import get_db
from app.core.response import success_response
from app.features.auth.dependencies import get_current_user, require_role
from app.features.events.schemas import (
    EventCreate,
    EventRSVPRequest,
    EventRSVPApproval,
    EventAttendanceRequest,
    EventUpdate
)
from app.features.events.service import (
    create_event,
    list_events,
    mark_attendance,
    update_rsvp,
    approve_rsvp,
    update_event,
)
from app.models.user import User, UserRole

logger = logging.getLogger(__name__)

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


@router.post("/events/{event_id}/approve", summary="Approve/Reject RSVP (Admin)", status_code=200)
async def approve_rsvp_endpoint(
    event_id: UUID,
    data: EventRSVPApproval,
    current_user: User = Depends(admin_req),
    db: AsyncSession = Depends(get_db),
) -> ORJSONResponse:
    updated_event = await approve_rsvp(event_id, data.user_id, data.status, db)
    return success_response(
        data=updated_event,
        message=f"RSVP status updated to {data.status}"
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


@router.patch("/events/{event_id}", summary="Update an event")
async def update_event_endpoint(
    event_id: UUID,
    data: EventUpdate,
    current_user: User = Depends(admin_req),
    db: AsyncSession = Depends(get_db),
) -> ORJSONResponse:
    event = await update_event(event_id, data.model_dump(exclude_unset=True), db)
    return success_response(
        data=event,
        message="Event updated successfully"
    )


@router.post("/events/upload-image", summary="Upload event image")
async def upload_event_image_endpoint(
    file: UploadFile = File(...),
    current_user: User = Depends(admin_req),
) -> ORJSONResponse:
    """Upload an event image."""
    from app.core.exceptions import BadRequestException

    # 1. Size Validation (5MB limit for event images)
    MAX_SIZE = 5 * 1024 * 1024
    if file.size and file.size > MAX_SIZE:
        raise BadRequestException(
            message=f"File too large. Maximum size allowed is 5MB.",
            code="FILE_TOO_LARGE"
        )

    # 2. Format Validation
    ALLOWED_TYPES = ["image/jpeg", "image/png", "image/webp"]
    if file.content_type not in ALLOWED_TYPES:
        logger.error(f"Invalid content type: {file.content_type}")
        raise BadRequestException(
            message=f"Invalid file format: {file.content_type}. Only JPEG, PNG, and WebP images are allowed.",
            code="INVALID_FORMAT"
        )

    os.makedirs("uploads/events", exist_ok=True)
    ext = file.filename.split(".")[-1].lower() if "." in file.filename else "jpg"
    
    if ext not in ["jpg", "jpeg", "png", "webp"]:
         raise BadRequestException(
            message="Invalid file extension.",
            code="INVALID_EXTENSION"
        )

    filename = f"event_{uuid.uuid4().hex[:8]}.{ext}"
    file_path = f"uploads/events/{filename}"
    
    with open(file_path, "wb") as buffer:
        shutil.copyfileobj(file.file, buffer)
        
    image_url = f"/static/events/{filename}"
    
    return success_response(
        data={"image_url": image_url},
        message="Image uploaded successfully"
    )
