"""
Prime Business Network – Notifications Service.

Handles listing, marking as read, configuring FCM tokens natively against User,
and abstracting Push Notification delivery via Firebase Cloud Messaging.
"""

from __future__ import annotations

import logging
from datetime import datetime, timezone
from typing import Any, Dict, List
from uuid import UUID

from sqlalchemy import desc, select, update, func
from sqlalchemy.ext.asyncio import AsyncSession

import firebase_admin
from firebase_admin import credentials, messaging

from app.core.config import get_settings
from app.core.database import async_session_factory
from app.core.exceptions import NotFoundException
from app.models.notifications import Notification
from app.models.user import User

logger = logging.getLogger(__name__)

# Map internal type strings to user-facing settings keys
TYPE_TO_SETTING_MAP = {
    "community_post": "new_posts",
    "community_like": "post_activity",
    "community_comment": "post_activity",
    "RSVP_UPDATE": "meeting_updates",
    "CHAPTER_BROADCAST": "chapter_announcements",
    "new_reward": "new_rewards",
    "NEW_MEMBER_JOINED": "new_members",
    "NEW_REFERRAL": "referral_activity",
    "REFERRAL_UPDATE": "referral_activity",
    "NOTICE_MATCH": "notice_board_matches",
    "DEAL_ALERT": "deal_opportunity_alerts",
}

# Cache the Firebase app initialization state
_firebase_app_initialized = False


def _init_firebase() -> bool:
    """Initialize Firebase Admin SDK if credentials JSON path is provided."""
    global _firebase_app_initialized
    if _firebase_app_initialized:
        return True

    settings = get_settings()
    sa_path = settings.FIREBASE_SERVICE_ACCOUNT_JSON
    if sa_path:
        try:
            cred = credentials.Certificate(sa_path)
            firebase_admin.initialize_app(cred)
            _firebase_app_initialized = True
            logger.info("Firebase Admin initialized successfully.")
            return True
        except Exception as e:
            logger.error(f"Failed to initialize Firebase Admin: {e}")
            return False
    return False


async def update_fcm_token(user_id: UUID, fcm_token: str, db: AsyncSession) -> None:
    """Update a user's FCM token."""
    await db.execute(
        update(User)
        .where(User.id == user_id)
        .values(fcm_token=fcm_token)
    )
    await db.commit()


async def _should_send_push(user: User, notification_type: str) -> bool:
    """Check if the user has disabled this specific notification type."""
    if not user.notification_settings:
        return True # Default to ON if no settings configured
        
    setting_key = TYPE_TO_SETTING_MAP.get(notification_type)
    if not setting_key:
        return True # Unknown types default to ON (e.g., system alerts)
        
    return user.notification_settings.get(setting_key, True)


async def send_push_notification(
    user_id: UUID,
    title: str,
    body: str,
    notification_type: str,
    data: Dict[str, str] | None = None,
    db: AsyncSession | None = None,  # keep for backward compat but ignore
) -> None:
    """
    Background Task: Emits a structural Notification into DB and triggers FCM push.
    Gracefully degrades to Stub logging if Firebase is not linked.
    Creates its own DB session to avoid using a closed request-scoped session.
    """
    async with async_session_factory() as session:
        try:
            now = datetime.now(timezone.utc)

            # 1. DB Persistence
            notif = Notification(
                user_id=user_id,
                title=title,
                body=body,
                notification_type=notification_type,
                data=data,
                sent_at=now,
                is_read=False,
            )
            session.add(notif)
            await session.commit()

            # 2. Get User FCM Token & Check Preferences
            user = (await session.execute(select(User).where(User.id == user_id))).scalar_one_or_none()
            if not user:
                return
                
            if not user.fcm_token:
                logger.info(f"FCM [SKIPPED]: User {user_id} has no token. Notif={title}")
                return

            if not await _should_send_push(user, notification_type):
                logger.info(f"FCM [MUTED BY USER]: {user.full_name} disabled {notification_type}")
                return

            # 3. Dispatch
            if _init_firebase():
                try:
                    message = messaging.Message(
                        notification=messaging.Notification(title=title, body=body),
                        data=data if data else {},
                        token=user.fcm_token,
                    )
                    response = messaging.send(message)
                    logger.info(f"FCM [DISPATCHED]: {response}")
                except Exception as e:
                    logger.error(f"FCM [FAILED]: {e}")
            else:
                logger.info(f"FCM [STUB]: '{title}' → {user.fcm_token}")

        except Exception as e:
            await session.rollback()
            logger.error(f"send_push_notification failed: {e}")


async def broadcast_notification(
    title: str,
    body: str,
    notification_type: str,
    data: Dict[str, str] | None = None,
) -> None:
    """
    Background Task: Emits a structural Notification to ALL active users and triggers FCM broadcast.
    """
    async with async_session_factory() as session:
        try:
            now = datetime.now(timezone.utc)
            
            # 1. Fetch all active users
            stmt = select(User).where(User.is_active == True)
            users = (await session.execute(stmt)).scalars().all()
            
            if not users:
                logger.info("Broadcast [SKIPPED]: No active users found.")
                return

            # 2. Persistence and Dispatch
            if _init_firebase():
                try:
                    # 2a. Create notifications in DB for everyone
                    for u in users:
                        notif = Notification(
                            user_id=u.id,
                            title=title,
                            body=body,
                            notification_type=notification_type,
                            data=data,
                            sent_at=now,
                            is_read=False,
                        )
                        session.add(notif)
                    await session.commit()

                    # 2b. Individual Dispatch Loop (Proven reliability over Multicast)
                    success_count = 0
                    failure_count = 0
                    
                    for u in users:
                        # Only dispatch push if they have a valid token
                        token = u.fcm_token
                        if not token or len(token) < 20 or token.startswith('mock-'):
                            continue

                        try:
                            message = messaging.Message(
                                notification=messaging.Notification(title=title, body=body),
                                data=data if data else {},
                                token=token,
                            )
                            messaging.send(message)
                            success_count += 1
                        except Exception as e:
                            failure_count += 1
                            logger.warning(f"Broadcast item failed for user {u.id}: {e}")
                    
                    logger.info(f"Broadcast [COMPLETED]: {success_count} success, {failure_count} failure")

                except Exception as e:
                    logger.error(f"Broadcast [FAILED] during processing: {e}")
            else:
                logger.info(f"Broadcast [STUB]: '{title}' to {len(users)} users (Firebase not init).")

        except Exception as e:
            await session.rollback()
            logger.error(f"broadcast_notification failed: {e}")


async def notify_multiple_users(
    user_ids: List[UUID],
    title: str,
    body: str,
    notification_type: str,
    data: Dict[str, str] | None = None,
) -> None:
    """
    Background Task: Emits structural Notifications to a specific list of users and triggers FCM.
    """
    if not user_ids:
        return

    async with async_session_factory() as session:
        try:
            now = datetime.now(timezone.utc)
            
            # 1. Fetch all active users from the provided list
            stmt = select(User).where(User.id.in_(user_ids), User.is_active == True)
            users = (await session.execute(stmt)).scalars().all()
            
            if not users:
                logger.info(f"NotifyMultiple [SKIPPED]: No active users found in list of {len(user_ids)}.")
                return

            # 2. Persistence and Dispatch
            if _init_firebase():
                try:
                    # 2a. Create notifications in DB for everyone in the list
                    for u in users:
                        notif = Notification(
                            user_id=u.id,
                            title=title,
                            body=body,
                            notification_type=notification_type,
                            data=data,
                            sent_at=now,
                            is_read=False,
                        )
                        session.add(notif)
                    await session.commit()

                    # 2b. Individual Dispatch Loop
                    for u in users:
                        token = u.fcm_token
                        if not token or len(token) < 20 or token.startswith('mock-'):
                            continue
                            
                        # Check individual preferences even in mass notification
                        if not await _should_send_push(u, notification_type):
                            continue

                        try:
                            message = messaging.Message(
                                notification=messaging.Notification(title=title, body=body),
                                data=data if data else {},
                                token=token,
                            )
                            messaging.send(message)
                        except Exception as e:
                            logger.warning(f"NotifyMultiple item failed for user {u.id}: {e}")
                    
                except Exception as e:
                    logger.error(f"NotifyMultiple [FAILED] during processing: {e}")
            else:
                logger.info(f"NotifyMultiple [STUB]: '{title}' to {len(users)} users.")

        except Exception as e:
            await session.rollback()
            logger.error(f"notify_multiple_users failed: {e}")


def _serialize_notification(n: Notification) -> Dict[str, Any]:
    return {
        "id": str(n.id),
        "title": n.title,
        "body": n.body,
        "notification_type": n.notification_type,
        "data": n.data,
        "is_read": n.is_read,
        "sent_at": n.sent_at.isoformat() if n.sent_at else None,
        "read_at": n.read_at.isoformat() if n.read_at else None,
    }


async def list_my_notifications(user_id: UUID, db: AsyncSession) -> Dict[str, Any]:
    """List all notifications for a member, with total unread count."""
    stmt = (
        select(Notification)
        .where(Notification.user_id == user_id)
        .order_by(desc(Notification.sent_at))
        .limit(50)
    )
    results = (await db.execute(stmt)).scalars().all()

    unread_stmt = select(func.count(1)).where(Notification.user_id == user_id, Notification.is_read == False)
    total_unread = (await db.execute(unread_stmt)).scalar_one()

    return {
        "notifications": [_serialize_notification(n) for n in results],
        "total_unread": total_unread,
    }


async def get_unread_count(user_id: UUID, db: AsyncSession) -> int:
    """Fast-path unread count scalar resolver."""
    stmt = select(func.count(1)).where(Notification.user_id == user_id, Notification.is_read == False)
    return (await db.execute(stmt)).scalar_one()


async def mark_as_read(notification_id: UUID, user_id: UUID, db: AsyncSession) -> Dict[str, Any]:
    """Target a specific notification and mark read."""
    notif = (
        await db.execute(
            select(Notification).where(
                Notification.id == notification_id, Notification.user_id == user_id
            )
        )
    ).scalar_one_or_none()

    if not notif:
        raise NotFoundException("Notification not found")

    if not notif.is_read:
        notif.is_read = True
        notif.read_at = datetime.now(timezone.utc)
        await db.commit()

    return _serialize_notification(notif)


async def mark_all_read(user_id: UUID, db: AsyncSession) -> None:
    """Mark all unread notifications read bulk operation."""
    now = datetime.now(timezone.utc)
    stmt = (
        update(Notification)
        .where(Notification.user_id == user_id, Notification.is_read == False)
        .values(is_read=True, read_at=now)
    )
    await db.execute(stmt)
    await db.commit()


async def delete_notification(notification_id: UUID, user_id: UUID, db: AsyncSession) -> None:
    """Delete a specific notification."""
    notif = (
        await db.execute(
            select(Notification).where(
                Notification.id == notification_id, Notification.user_id == user_id
            )
        )
    ).scalar_one_or_none()

    if not notif:
        raise NotFoundException("Notification not found")

    await db.delete(notif)
    await db.commit()


async def get_notification_settings(user_id: UUID, db: AsyncSession) -> Dict[str, bool]:
    """Get a user's notification preferences with defaults merged."""
    user = (await db.execute(select(User).where(User.id == user_id))).scalar_one()
    
    defaults = {
        "new_posts": True,
        "post_activity": True,
        "meeting_updates": True,
        "chapter_announcements": True,
        "new_rewards": True,
        "new_members": True,
    }
    
    settings = user.notification_settings or {}
    # Merge defaults for any missing keys
    return {**defaults, **settings}


async def update_notification_settings(user_id: UUID, data: Dict[str, Any], db: AsyncSession) -> Dict[str, bool]:
    """Update user notification preferences."""
    user = (await db.execute(select(User).where(User.id == user_id))).scalar_one()
    
    # Create a fresh dict to ensure SQLAlchemy detects the change
    current = dict(user.notification_settings or {})
    
    # Only update keys that are provided in the payload
    for key, val in data.items():
        if val is not None:
            current[key] = val
            
    # Use an explicit update statement for JSONB fields to ensure persistence
    await db.execute(
        update(User)
        .where(User.id == user_id)
        .values(notification_settings=current)
    )
    await db.commit()
    
    # Merge with defaults before returning to ensure consistency
    defaults = {
        "new_posts": True,
        "post_activity": True,
        "meeting_updates": True,
        "chapter_announcements": True,
        "new_rewards": True,
        "new_members": True,
    }
    return {**defaults, **current}
