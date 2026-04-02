"""
Prime Business Network – Admin Service.

Super Admin operations: audit log viewer, user management, data masking,
and platform-wide data export.
"""

from __future__ import annotations

import re
from datetime import datetime, timezone
from typing import Any, Dict, List
from uuid import UUID

from sqlalchemy import desc, select, update, func
from sqlalchemy.ext.asyncio import AsyncSession

from app.core.exceptions import NotFoundException, BadRequestException
from app.models.audit_logs import AuditLog
from app.models.user import User, UserRole
from app.models.memberships import ChapterMembership
from app.models.referrals import Referral
from app.models.payments import Payment


def _mask_phone(phone: str) -> str:
    """Mask a phone number: +947712XXXXX"""
    if len(phone) > 6:
        return phone[:6] + "X" * (len(phone) - 6)
    return phone


def _mask_email(email: str | None) -> str | None:
    if not email:
        return None
    parts = email.split("@")
    if len(parts) == 2:
        name = parts[0]
        masked = name[0] + "*" * (len(name) - 1) if len(name) > 1 else name
        return f"{masked}@{parts[1]}"
    return email


def _serialize_user(u: User, mask: bool = False) -> Dict[str, Any]:
    return {
        "id": str(u.id),
        "phone_number": _mask_phone(u.phone_number) if mask else u.phone_number,
        "email": _mask_email(u.email) if mask else u.email,
        "full_name": u.full_name,
        "role": u.role.value,
        "is_active": u.is_active,
        "created_at": u.created_at.isoformat() if u.created_at else None,
    }


def _serialize_audit(a: AuditLog) -> Dict[str, Any]:
    return {
        "id": str(a.id),
        "actor_id": str(a.actor_id) if a.actor_id else None,
        "entity_type": a.entity_type,
        "entity_id": str(a.entity_id),
        "action": a.action,
        "old_value": a.old_value,
        "new_value": a.new_value,
        "ip_address": a.ip_address,
        "created_at": a.created_at.isoformat() if a.created_at else None,
    }


async def list_users(
    role_filter: str | None,
    is_active: bool | None,
    search: str | None,
    page: int,
    page_size: int,
    db: AsyncSession,
) -> Dict[str, Any]:
    """List all users with optional filtering, search, and pagination."""
    stmt = select(User).order_by(desc(User.created_at))

    if role_filter:
        stmt = stmt.where(User.role == role_filter)
    if is_active is not None:
        stmt = stmt.where(User.is_active == is_active)
    if search:
        pattern = f"%{search}%"
        stmt = stmt.where(
            (User.full_name.ilike(pattern)) | (User.phone_number.ilike(pattern))
        )

    # Count total
    count_stmt = select(func.count(1)).select_from(stmt.subquery())
    total = (await db.execute(count_stmt)).scalar_one()

    # Paginate
    stmt = stmt.offset((page - 1) * page_size).limit(page_size)
    results = (await db.execute(stmt)).scalars().all()

    return {
        "users": [_serialize_user(u) for u in results],
        "total": total,
        "page": page,
        "page_size": page_size,
    }


async def deactivate_user(user_id: UUID, actor_id: UUID, db: AsyncSession) -> Dict[str, Any]:
    """Deactivate a user account."""
    user = (await db.execute(select(User).where(User.id == user_id))).scalar_one_or_none()
    if not user:
        raise NotFoundException("User not found")
    if user.role == UserRole.SUPER_ADMIN:
        raise BadRequestException("Cannot deactivate a Super Admin")

    old_active = user.is_active
    user.is_active = False

    # Audit
    audit = AuditLog(
        actor_id=actor_id,
        entity_type="user",
        entity_id=user.id,
        action="deactivate",
        old_value={"is_active": old_active},
        new_value={"is_active": False},
    )
    db.add(audit)
    await db.commit()

    return _serialize_user(user)


async def reactivate_user(user_id: UUID, actor_id: UUID, db: AsyncSession) -> Dict[str, Any]:
    """Reactivate a user account."""
    user = (await db.execute(select(User).where(User.id == user_id))).scalar_one_or_none()
    if not user:
        raise NotFoundException("User not found")

    user.is_active = True

    audit = AuditLog(
        actor_id=actor_id,
        entity_type="user",
        entity_id=user.id,
        action="reactivate",
        old_value={"is_active": False},
        new_value={"is_active": True},
    )
    db.add(audit)
    await db.commit()

    return _serialize_user(user)


async def list_audit_logs(
    entity_type: str | None,
    action: str | None,
    page: int,
    page_size: int,
    db: AsyncSession,
) -> Dict[str, Any]:
    """Paginated audit log retriever for the admin dashboard."""
    stmt = select(AuditLog).order_by(desc(AuditLog.created_at))

    if entity_type:
        stmt = stmt.where(AuditLog.entity_type == entity_type)
    if action:
        stmt = stmt.where(AuditLog.action == action)

    count_stmt = select(func.count(1)).select_from(stmt.subquery())
    total = (await db.execute(count_stmt)).scalar_one()

    stmt = stmt.offset((page - 1) * page_size).limit(page_size)
    results = (await db.execute(stmt)).scalars().all()

    return {
        "logs": [_serialize_audit(a) for a in results],
        "total": total,
        "page": page,
        "page_size": page_size,
    }


async def get_masked_user_data(user_id: UUID, db: AsyncSession) -> Dict[str, Any]:
    """Return user data with PII masked for compliance screens."""
    user = (await db.execute(select(User).where(User.id == user_id))).scalar_one_or_none()
    if not user:
        raise NotFoundException("User not found")
    return _serialize_user(user, mask=True)


async def export_platform_data(db: AsyncSession) -> Dict[str, Any]:
    """Export aggregate platform health metrics for admin dashboard."""
    total_users = (await db.execute(select(func.count(1)).select_from(User))).scalar_one()
    active_users = (await db.execute(
        select(func.count(1)).where(User.is_active == True)
    )).scalar_one()
    total_memberships = (await db.execute(
        select(func.count(1)).select_from(ChapterMembership)
    )).scalar_one()
    total_referrals = (await db.execute(
        select(func.count(1)).select_from(Referral)
    )).scalar_one()
    total_payments = (await db.execute(
        select(func.count(1)).select_from(Payment)
    )).scalar_one()
    total_revenue = (await db.execute(
        select(func.coalesce(func.sum(Payment.amount), 0)).where(Payment.status == "completed")
    )).scalar_one()

    return {
        "exported_at": datetime.now(timezone.utc).isoformat(),
        "total_users": total_users,
        "active_users": active_users,
        "inactive_users": total_users - active_users,
        "total_memberships": total_memberships,
        "total_referrals": total_referrals,
        "total_payments": total_payments,
        "total_revenue": float(total_revenue),
    }
