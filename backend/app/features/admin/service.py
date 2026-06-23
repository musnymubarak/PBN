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
from sqlalchemy.orm import contains_eager, aliased
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
    role_val = u.role.value if hasattr(u.role, 'value') else u.role
    return {
        "id": str(u.id),
        "phone_number": _mask_phone(u.phone_number) if mask else u.phone_number,
        "email": _mask_email(u.email) if mask else u.email,
        "full_name": u.full_name,
        "role": str(role_val),
        "is_active": u.is_active,
        "profile_photo": u.profile_photo,
        "chapter_name": chapter_name,
        "industry_name": industry_name,
        "membership_type": u.membership_type if hasattr(u, 'membership_type') else None,
        "created_at": u.created_at.isoformat() if u.created_at else None,
    }



def _serialize_audit(a: AuditLog, actor: User | None = None) -> Dict[str, Any]:
    return {
        "id": str(a.id),
        "actor": {
            "id": str(actor.id) if actor else (str(a.actor_id) if a.actor_id else None),
            "full_name": actor.full_name if actor else None,
            "email": actor.email if actor else None,
            "role": (actor.role.value if actor and hasattr(actor.role, "value") else None),
        },
        "actor_id": str(a.actor_id) if a.actor_id else None,
        "entity_type": a.entity_type,
        "entity_id": str(a.entity_id) if a.entity_id else None,
        "action": a.action,
        "description": a.description,
        "method": a.method,
        "path": a.path,
        "status_code": a.status_code,
        "duration_ms": a.duration_ms,
        "request_id": a.request_id,
        "user_agent": a.user_agent,
        "ip_address": a.ip_address,
        "old_value": a.old_value,
        "new_value": a.new_value,
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
    district: str | None = None,
) -> Dict[str, Any]:
    """List all users with optional filtering, search, and pagination."""
    # Use outer joins to include chapter and industry info if available
    stmt = (
        select(
            User, 
            Chapter.name.label("chapter_name"), 
            IndustryCategory.name.label("industry_name"),
            ChapterMembership.membership_type.label("membership_type")
        )
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
    if district:
        stmt = stmt.where(Chapter.district == district)
        
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
        m_type = row[3]
        
        # Attach membership_type to the user object temporarily for serialization
        u.membership_type = m_type
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
    if user.role in (UserRole.SUPER_ADMIN, UserRole.ADMIN):
        raise BadRequestException("Cannot deactivate a Super Admin or Admin user.")

    old_active = user.is_active
    user.is_active = False
    
    # Also toggle chapter membership if it exists
    await db.execute(
        update(ChapterMembership)
        .where(ChapterMembership.user_id == user_id)
        .values(is_active=False)
    )

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

    # Also toggle chapter membership if it exists
    await db.execute(
        update(ChapterMembership)
        .where(ChapterMembership.user_id == user_id)
        .values(is_active=True)
    )

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
        old_role = user.role
        user.role = data["role"]
        
        if old_role == UserRole.PROSPECT and user.role == UserRole.MEMBER:
            # Mark pending membership payments as completed
            from app.models.payments import PaymentStatus, PaymentType
            await db.execute(
                update(Payment)
                .where(
                    Payment.user_id == user_id, 
                    Payment.payment_type == PaymentType.MEMBERSHIP,
                    Payment.status == PaymentStatus.PENDING
                )
                .values(status=PaymentStatus.COMPLETED)
            )

            from app.core.email_service import send_email, render_template
            import logging
            logger = logging.getLogger(__name__)
            if user.email:
                try:
                    html = render_template("membership_activated.html", {
                        "full_name": user.full_name,
                        "amount": None,
                    })
                    await send_email(user.email, "Your PBN Membership is Activated!", html)
                except Exception as e:
                    logger.error(f"Failed to send membership activation email to {user.email}: {e}")
    if "is_active" in data:
        user.is_active = data["is_active"]
        # Also toggle chapter membership if it exists
        await db.execute(
            update(ChapterMembership)
            .where(ChapterMembership.user_id == user_id)
            .values(is_active=data["is_active"])
        )
    
    if "membership_type" in data:
        await db.execute(
            update(ChapterMembership)
            .where(ChapterMembership.user_id == user_id)
            .values(membership_type=data["membership_type"])
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


async def delete_user(user_id: UUID, actor_id: UUID, db: AsyncSession) -> Dict[str, Any]:
    """Permanently delete a user account (any role, any status). Only self-delete is blocked."""
    if user_id == actor_id:
        raise BadRequestException("You cannot delete your own account.")

    user = (await db.execute(select(User).where(User.id == user_id))).scalar_one_or_none()
    if not user:
        raise NotFoundException("User not found")

    snapshot = _serialize_user(user)

    audit = AuditLog(
        actor_id=actor_id,
        entity_type="user",
        entity_id=user.id,
        action="delete",
        old_value=snapshot,
        new_value=None,
    )
    db.add(audit)

    await db.delete(user)
    await db.commit()

    return snapshot


async def remove_user_from_chapter(user_id: UUID, actor_id: UUID, db: AsyncSession) -> Dict[str, Any]:
    """Remove a user from every chapter membership they hold."""
    stmt = select(ChapterMembership).where(ChapterMembership.user_id == user_id)
    memberships = (await db.execute(stmt)).scalars().all()

    if not memberships:
        raise NotFoundException("Chapter membership not found for this user")

    for membership in memberships:
        db.add(AuditLog(
            actor_id=actor_id,
            entity_type="membership",
            entity_id=membership.id,
            action="remove_from_chapter",
            old_value={"user_id": str(user_id), "chapter_id": str(membership.chapter_id)},
            new_value=None,
        ))
        await db.delete(membership)

    # Also downgrade user to PROSPECT if they were a MEMBER
    user = (await db.execute(select(User).where(User.id == user_id))).scalar_one_or_none()
    if user and user.role == UserRole.MEMBER:
        user.role = UserRole.PROSPECT

    await db.commit()

    if user:
        return _serialize_user(user)
    return {"message": "User removed from chapter"}



async def list_audit_logs(
    entity_type: str | None,
    action: str | None,
    page: int,
    page_size: int,
    db: AsyncSession,
    actor_id: UUID | None = None,
    method: str | None = None,
    status_code: int | None = None,
    search: str | None = None,
    date_from: datetime | None = None,
    date_to: datetime | None = None,
) -> Dict[str, Any]:
    """Paginated audit log retriever for the admin dashboard.

    Returns rows joined with the acting user so the frontend can display
    `who` without a second query per row.
    """
    Actor = aliased(User)
    stmt = (
        select(AuditLog, Actor)
        .outerjoin(Actor, AuditLog.actor_id == Actor.id)
        .order_by(desc(AuditLog.created_at))
    )

    if entity_type:
        stmt = stmt.where(AuditLog.entity_type == entity_type)
    if action:
        stmt = stmt.where(AuditLog.action == action)
    if actor_id:
        stmt = stmt.where(AuditLog.actor_id == actor_id)
    if method:
        stmt = stmt.where(AuditLog.method == method.upper())
    if status_code is not None:
        stmt = stmt.where(AuditLog.status_code == status_code)
    if date_from is not None:
        stmt = stmt.where(AuditLog.created_at >= date_from)
    if date_to is not None:
        stmt = stmt.where(AuditLog.created_at <= date_to)
    if search:
        pattern = f"%{search}%"
        stmt = stmt.where(
            (AuditLog.path.ilike(pattern))
            | (AuditLog.action.ilike(pattern))
            | (AuditLog.description.ilike(pattern))
            | (AuditLog.entity_type.ilike(pattern))
            | (Actor.full_name.ilike(pattern))
            | (Actor.email.ilike(pattern))
        )

    count_stmt = select(func.count(1)).select_from(stmt.subquery())
    total = (await db.execute(count_stmt)).scalar_one()

    stmt = stmt.offset((page - 1) * page_size).limit(page_size)
    rows = (await db.execute(stmt)).all()

    return {
        "logs": [_serialize_audit(a, actor) for (a, actor) in rows],
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


async def get_member_profile(user_id: UUID, db: AsyncSession) -> Dict[str, Any]:
    """Aggregated member profile: user + chapter + business + application + activity counts."""
    from app.models.applications import Application
    from app.models.businesses import Business
    from app.models.referrals import Referral
    from app.models.payments import Payment
    from app.models.privilege_cards import PrivilegeCard
    from app.models.marketplace import MarketplaceListing
    from app.models.complements import ComplementType, MemberComplement
    from sqlalchemy import or_

    user = (await db.execute(select(User).where(User.id == user_id))).scalar_one_or_none()
    if not user:
        raise NotFoundException("User not found")

    # Chapter membership (active first)
    cm_stmt = (
        select(
            ChapterMembership,
            Chapter.name.label("chapter_name"),
            IndustryCategory.name.label("industry_name"),
        )
        .join(Chapter, ChapterMembership.chapter_id == Chapter.id, isouter=True)
        .join(IndustryCategory, ChapterMembership.industry_category_id == IndustryCategory.id, isouter=True)
        .where(ChapterMembership.user_id == user_id)
        .order_by(ChapterMembership.is_active.desc(), ChapterMembership.start_date.desc())
        .limit(1)
    )
    cm_row = (await db.execute(cm_stmt)).first()
    membership = None
    if cm_row:
        m, chapter_name, industry_name = cm_row
        membership = {
            "chapter_id": str(m.chapter_id) if m.chapter_id else None,
            "chapter_name": chapter_name,
            "industry_category_id": str(m.industry_category_id) if m.industry_category_id else None,
            "industry_name": industry_name,
            "membership_type": m.membership_type.value if hasattr(m.membership_type, "value") else m.membership_type,
            "is_active": m.is_active,
            "start_date": m.start_date.isoformat() if m.start_date else None,
            "end_date": m.end_date.isoformat() if m.end_date else None,
        }

    # Business profile
    biz = (await db.execute(
        select(Business).where(Business.owner_user_id == user_id)
    )).scalar_one_or_none()
    business = None
    if biz:
        business = {
            "business_name": biz.business_name,
            "description": biz.description,
            "website": biz.website,
            "logo_url": biz.logo_url,
            "district": biz.district,
        }

    # Linked application — match by phone OR email (whichever the applicant used)
    app_stmt = select(Application).where(
        or_(
            Application.contact_number == user.phone_number,
            (Application.email == user.email) if user.email else (Application.id == None),
        )
    ).order_by(Application.created_at.desc()).limit(1)
    app = (await db.execute(app_stmt)).scalar_one_or_none()

    # Resolve referrer name if present on the application
    referred_by_name = None
    if app and app.referred_by_user_id:
        referrer = (await db.execute(
            select(User.full_name).where(User.id == app.referred_by_user_id)
        )).scalar_one_or_none()
        referred_by_name = referrer

    application = None
    if app:
        application = {
            "id": str(app.id),
            "status": app.status.value,
            "designation": app.designation,
            "decision_authority": app.decision_authority.value if app.decision_authority else None,
            "years_in_operation": app.years_in_operation,
            "business_legal_type": app.business_legal_type.value if app.business_legal_type else None,
            "business_registration_number": app.business_registration_number,
            "website_url": app.website_url,
            "linkedin_url": app.linkedin_url,
            "referred_by_user_id": str(app.referred_by_user_id) if app.referred_by_user_id else None,
            "referred_by_name": referred_by_name,
            "what_you_offer": app.what_you_offer,
            "what_you_seek": app.what_you_seek,
            "tshirt_size": app.tshirt_size.value if app.tshirt_size else None,
            "onboarding_completed_at": app.onboarding_completed_at.isoformat() if app.onboarding_completed_at else None,
            "fit_call_date": app.fit_call_date.isoformat() if app.fit_call_date else None,
            "submitted_at": app.created_at.isoformat() if app.created_at else None,
        }

    # Activity counts
    async def _count(stmt):
        return (await db.execute(select(func.count()).select_from(stmt.subquery()))).scalar_one()

    referrals_given = await _count(select(Referral.id).where(Referral.from_member_id == user_id))
    referrals_received = await _count(select(Referral.id).where(Referral.to_member_id == user_id))
    payments_total = (await db.execute(
        select(func.coalesce(func.sum(Payment.amount), 0)).where(
            Payment.user_id == user_id,
            Payment.status == "completed",
        )
    )).scalar_one()
    payments_count = await _count(select(Payment.id).where(Payment.user_id == user_id))
    listings_count = await _count(select(MarketplaceListing.id).where(MarketplaceListing.seller_id == user_id))
    card = (await db.execute(
        select(PrivilegeCard).where(PrivilegeCard.user_id == user_id).limit(1)
    )).scalar_one_or_none()

    activity = {
        "referrals_given": referrals_given,
        "referrals_received": referrals_received,
        "payments_count": payments_count,
        "payments_total": float(payments_total) if payments_total else 0.0,
        "listings_count": listings_count,
        "privilege_card": (
            {
                "card_number": card.card_number,
                "issued_at": card.issued_at.isoformat() if card.issued_at else None,
                "expires_at": card.expires_at.isoformat() if card.expires_at else None,
            }
            if card else None
        ),
    }

    # Complements ledger for this member.
    comp_rows = (await db.execute(
        select(MemberComplement, ComplementType)
        .join(ComplementType, MemberComplement.complement_type_id == ComplementType.id)
        .where(MemberComplement.user_id == user_id)
        .order_by(desc(MemberComplement.assigned_at))
    )).all()
    complements = [
        {
            "id": str(c.id),
            "type_code": t.code,
            "type_name": t.name,
            "variant": c.variant,
            "fulfilment_status": c.fulfilment_status.value,
            "assigned_at": c.assigned_at.isoformat() if c.assigned_at else None,
            "fulfilled_at": c.fulfilled_at.isoformat() if c.fulfilled_at else None,
        }
        for (c, t) in comp_rows
    ]

    return {
        "user": {
            "id": str(user.id),
            "full_name": user.full_name,
            "phone_number": user.phone_number,
            "email": user.email,
            "role": user.role.value if hasattr(user.role, "value") else user.role,
            "is_active": user.is_active,
            "profile_photo": user.profile_photo,
            "verification_level": user.verification_level.value if hasattr(user.verification_level, "value") else user.verification_level,
            "cumulative_value_generated": float(user.cumulative_value_generated) if user.cumulative_value_generated else 0.0,
            "created_at": user.created_at.isoformat() if user.created_at else None,
            "must_change_password": user.must_change_password,
        },
        "membership": membership,
        "business": business,
        "application": application,
        "activity": activity,
        "complements": complements,
    }


async def list_all_referrals(
    search: str | None,
    status: str | None,
    page: int,
    page_size: int,
    db: AsyncSession
) -> Dict[str, Any]:
    """List all referrals with optional filtering, search, and pagination."""
    from sqlalchemy.orm import joinedload, selectinload
    from app.models.referrals import ReferralStatusHistory
    from app.models.user import User as UserModel

    # Subqueries for names to make searching easier
    FromUser = aliased(UserModel)
    ToUser = aliased(UserModel)

    stmt = (
        select(Referral)
        .join(FromUser, Referral.from_member_id == FromUser.id)
        .join(ToUser, Referral.to_member_id == ToUser.id)
        .options(
            contains_eager(Referral.from_member, alias=FromUser),
            contains_eager(Referral.to_member, alias=ToUser),
            selectinload(Referral.history),
        )
        .order_by(desc(Referral.created_at))
    )

    if status:
        stmt = stmt.where(Referral.status == status)

    if search:
        pattern = f"%{search}%"
        stmt = stmt.where(
            (Referral.client_name.ilike(pattern)) |
            (Referral.description.ilike(pattern)) |
            (FromUser.full_name.ilike(pattern)) |
            (ToUser.full_name.ilike(pattern))
        )

    # Count total
    count_stmt = select(func.count(1)).select_from(stmt.subquery())
    total = (await db.execute(count_stmt)).scalar_one()

    # Paginate
    stmt = stmt.offset((page - 1) * page_size).limit(page_size)
    result = await db.execute(stmt)
    referrals = result.scalars().unique().all()

    referral_list = []
    for ref in referrals:
        referral_list.append({
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

    return {
        "referrals": referral_list,
        "total": total,
        "page": page,
        "page_size": page_size,
    }


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

async def export_referrals_csv(db: AsyncSession):
    """Generate a CSV stream of all referrals."""
    import csv
    import io
    from app.models.user import User as UserModel
    
    FromUser = aliased(UserModel)
    ToUser = aliased(UserModel)
    
    stmt = (
        select(Referral)
        .join(FromUser, Referral.from_member_id == FromUser.id)
        .join(ToUser, Referral.to_member_id == ToUser.id)
        .options(
            contains_eager(Referral.from_member, alias=FromUser),
            contains_eager(Referral.to_member, alias=ToUser),
        )
        .order_by(desc(Referral.created_at))
    )
    
    results = (await db.execute(stmt)).scalars().unique().all()
    
    output = io.StringIO()
    writer = csv.writer(output)
    writer.writerow(["Referral ID", "From Member", "To Member", "Lead Name", "Lead Phone", "Lead Email", "Status", "Value", "Created At"])
    
    for ref in results:
        writer.writerow([
            str(ref.id),
            ref.from_member.full_name,
            ref.to_member.full_name,
            ref.client_name,
            ref.client_phone,
            ref.client_email,
            ref.status.value,
            float(ref.actual_value) if ref.actual_value else 0,
            ref.created_at.isoformat() if ref.created_at else ""
        ])
    
    output.seek(0)
    return output.getvalue()
