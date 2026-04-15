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
from app.models.chapters import Chapter
from app.models.industry_categories import IndustryCategory
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


def _serialize_user(u: User, mask: bool = False, chapter_name: str | None = None, industry_name: str | None = None) -> Dict[str, Any]:
    return {
        "id": str(u.id),
        "phone_number": _mask_phone(u.phone_number) if mask else u.phone_number,
        "email": _mask_email(u.email) if mask else u.email,
        "full_name": u.full_name,
        "role": u.role.value,
        "is_active": u.is_active,
        "chapter_name": chapter_name,
        "industry_name": industry_name,
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
    chapter_id: UUID | None = None,
    industry_id: UUID | None = None,
) -> Dict[str, Any]:
    """List all users with optional filtering, search, and pagination."""
    # Use outer joins to include chapter and industry info if available
    stmt = (
        select(User, Chapter.name.label("chapter_name"), IndustryCategory.name.label("industry_name"))
        .outerjoin(ChapterMembership, (User.id == ChapterMembership.user_id) & (ChapterMembership.is_active == True))
        .outerjoin(Chapter, ChapterMembership.chapter_id == Chapter.id)
        .outerjoin(IndustryCategory, ChapterMembership.industry_category_id == IndustryCategory.id)
        .order_by(desc(User.created_at))
    )

    if role_filter:
        stmt = stmt.where(User.role == role_filter)
    if is_active is not None:
        stmt = stmt.where(User.is_active == is_active)
    if chapter_id:
        stmt = stmt.where(Chapter.id == chapter_id)
    if industry_id:
        stmt = stmt.where(IndustryCategory.id == industry_id)
        
    if search:
        pattern = f"%{search}%"
        stmt = stmt.where(
            (User.full_name.ilike(pattern)) | 
            (User.phone_number.ilike(pattern)) |
            (Chapter.name.ilike(pattern)) |
            (IndustryCategory.name.ilike(pattern))
        )

    # Count total
    count_stmt = select(func.count(1)).select_from(stmt.subquery())
    total = (await db.execute(count_stmt)).scalar_one()

    # Paginate
    stmt = stmt.offset((page - 1) * page_size).limit(page_size)
    results = await db.execute(stmt)
    
    # Process results (User, chapter_name, industry_name)
    user_list = []
    for row in results.all():
        u = row[0]
        c_name = row[1]
        i_name = row[2]
        user_list.append(_serialize_user(u, chapter_name=c_name, industry_name=i_name))

    return {
        "users": user_list,
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


async def update_user(
    user_id: UUID, 
    actor_id: UUID, 
    data: Dict[str, Any], 
    db: AsyncSession
) -> Dict[str, Any]:
    """Update user role or status manually (Admin only)."""
    user = (await db.execute(select(User).where(User.id == user_id))).scalar_one_or_none()
    if not user:
        raise NotFoundException("User not found")

    old_val = _serialize_user(user)
    
    if "role" in data:
        user.role = data["role"]
    if "is_active" in data:
        user.is_active = data["is_active"]
        # Also toggle chapter membership if it exists
        await db.execute(
            update(ChapterMembership)
            .where(ChapterMembership.user_id == user_id)
            .values(is_active=data["is_active"])
        )

    # Audit
    audit = AuditLog(
        actor_id=actor_id,
        entity_type="user",
        entity_id=user.id,
        action="admin_update",
        old_value=old_val,
        new_value=_serialize_user(user),
    )
    db.add(audit)
    await db.flush()
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


async def list_all_referrals(db: AsyncSession) -> List[Dict[str, Any]]:
    """List all referrals across the platform for the admin dashboard."""
    from sqlalchemy.orm import joinedload, selectinload
    from app.models.referrals import ReferralStatusHistory

    stmt = (
        select(Referral)
        .options(
            joinedload(Referral.from_member),
            joinedload(Referral.to_member),
            selectinload(Referral.history),
        )
        .order_by(desc(Referral.created_at))
    )
    result = await db.execute(stmt)
    referrals = result.scalars().unique().all()

    out: List[Dict[str, Any]] = []
    for ref in referrals:
        out.append({
            "id": str(ref.id),
            "from_user": {
                "id": str(ref.from_member.id),
                "full_name": ref.from_member.full_name,
                "phone_number": ref.from_member.phone_number,
            },
            "target_user": {
                "id": str(ref.to_member.id),
                "full_name": ref.to_member.full_name,
                "phone_number": ref.to_member.phone_number,
            },
            "lead_name": ref.client_name,
            "lead_contact": ref.client_phone,
            "lead_email": ref.client_email,
            "description": ref.description,
            "actual_value": float(ref.actual_value) if ref.actual_value is not None else None,
            "status": ref.status.value,
            "created_at": ref.created_at.isoformat() if ref.created_at else None,
            "updated_at": ref.updated_at.isoformat() if ref.updated_at else None,
            "history": [
                {
                    "id": str(h.id),
                    "old_status": h.old_status,
                    "new_status": h.new_status,
                    "description": h.notes,
                    "created_at": h.created_at.isoformat() if h.created_at else None,
                }
                for h in ref.history
            ],
        })
    return out


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
