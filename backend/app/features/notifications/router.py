"""
Prime Business Network – Notifications Router.
"""

from __future__ import annotations

from typing import Dict
from uuid import UUID

from fastapi import APIRouter, Depends, BackgroundTasks
from fastapi.responses import ORJSONResponse
from sqlalchemy.ext.asyncio import AsyncSession

from app.core.dependencies import get_db
from app.core.response import success_response
from app.features.auth.dependencies import get_current_user, require_role
from app.models.user import User, UserRole

from app.features.notifications.schemas import FCMTokenUpdate
from app.features.notifications import service

router = APIRouter(tags=["Notifications"])

auth_req = require_role([UserRole.PROSPECT, UserRole.MEMBER, UserRole.CHAPTER_ADMIN, UserRole.SUPER_ADMIN])


@router.post("/notifications/token", summary="Update FCM Device Token")
async def update_fcm_token_endpoint(
    data: FCMTokenUpdate,
    current_user: User = Depends(auth_req),
    db: AsyncSession = Depends(get_db),
) -> ORJSONResponse:
    await service.update_fcm_token(current_user.id, data.fcm_token, db)
    return success_response(message="FCM token updated successfully")


@router.get("/notifications", summary="List My Notifications")
async def list_notifications_endpoint(
    current_user: User = Depends(auth_req),
    db: AsyncSession = Depends(get_db),
) -> ORJSONResponse:
    result = await service.list_my_notifications(current_user.id, db)
    return success_response(data=result)


@router.get("/notifications/unread-count", summary="Get unread notification count badge")
async def unread_count_endpoint(
    current_user: User = Depends(auth_req),
    db: AsyncSession = Depends(get_db),
) -> ORJSONResponse:
    count = await service.get_unread_count(current_user.id, db)
    return success_response(data={"count": count})


@router.patch("/notifications/{notification_id}/read", summary="Mark specific notification as read")
async def mark_read_endpoint(
    notification_id: UUID,
    current_user: User = Depends(auth_req),
    db: AsyncSession = Depends(get_db),
) -> ORJSONResponse:
    result = await service.mark_as_read(notification_id, current_user.id, db)
    return success_response(data=result)


@router.patch("/notifications/read-all", summary="Mark all notifications as read")
async def mark_all_read_endpoint(
    current_user: User = Depends(auth_req),
    db: AsyncSession = Depends(get_db),
) -> ORJSONResponse:
    await service.mark_all_read(current_user.id, db)
    return success_response(message="All notifications marked as read")


@router.post("/notifications/dev/test-push", summary="Trigger a test push notification (dev only)")
async def test_push_endpoint(
    background_tasks: BackgroundTasks,
    current_user: User = Depends(auth_req),
    db: AsyncSession = Depends(get_db),
) -> ORJSONResponse:
    """Helper purely to test the FCM flow or the logging stub without waiting for a real system event."""
    from app.core.config import get_settings
    if get_settings().ENVIRONMENT == "production":
        return success_response(message="Simulation blocked in production.")
        
    background_tasks.add_task(
        service.send_push_notification,
        user_id=current_user.id,
        title="Test Notification 🎉",
        body="If you read this, the FCM module is functioning correctly for your device.",
        notification_type="system_test",
        data={"route": "/profile"},
        db=db,
    )
    return success_response(message="Background push task scheduled")
