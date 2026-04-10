"""
Prime Business Network – Applications API Service.
"""

from __future__ import annotations

import math
import random
import string
from datetime import date, datetime, timedelta, timezone
from decimal import Decimal
from typing import List, Tuple
from uuid import UUID

from sqlalchemy import select, desc, func
from sqlalchemy.ext.asyncio import AsyncSession
from jose import jwt

from app.core.exceptions import BadRequestException, NotFoundException
from app.features.auth.service import hash_password
from app.features.applications.schemas import (
    ApplicationCreate,
    ApplicationStatusUpdate,
)
from app.models.applications import (
    Application,
    ApplicationStatus,
    ApplicationStatusHistory,
)
from app.models.audit_logs import AuditLog
from app.models.industry_categories import IndustryCategory
from app.models.memberships import ChapterMembership, MembershipType
from app.models.privilege_cards import PrivilegeCard
from app.models.user import User, UserRole
from app.models.chapters import Chapter
from app.models.payments import Payment, PaymentStatus, PaymentType
from app.core.config import get_settings

settings = get_settings()

VALID_TRANSITIONS = {
    ApplicationStatus.PENDING: [ApplicationStatus.FIT_CALL_SCHEDULED],
    ApplicationStatus.FIT_CALL_SCHEDULED: [
        ApplicationStatus.APPROVED,
        ApplicationStatus.REJECTED,
        ApplicationStatus.WAITLISTED,
    ],
    ApplicationStatus.WAITLISTED: [ApplicationStatus.APPROVED],
}


# ── Industry Categories ──────────────────────────────────────────────────────

async def get_active_industry_categories(db: AsyncSession) -> List[IndustryCategory]:
    stmt = select(IndustryCategory).where(IndustryCategory.is_active.is_(True)).order_by(IndustryCategory.name)
    result = await db.execute(stmt)
    return list(result.scalars().all())


# ── Applications ─────────────────────────────────────────────────────────────

async def create_application(
    data: ApplicationCreate,
    db: AsyncSession,
) -> Application:
    # Validate industry active
    stmt = select(IndustryCategory).where(
        IndustryCategory.id == data.industry_category_id,
        IndustryCategory.is_active.is_(True),
    )
    result = await db.execute(stmt)
    if result.scalar_one_or_none() is None:
        raise BadRequestException("Invalid or inactive industry category.", code="INVALID_INDUSTRY")

    # Check duplicates
    dup_stmt = select(Application).where(
        Application.contact_number == data.contact_number,
        Application.industry_category_id == data.industry_category_id,
    )
    dup_result = await db.execute(dup_stmt)
    if dup_result.scalar_one_or_none() is not None:
        raise BadRequestException("Application already exists.", code="DUPLICATE_APPLICATION")

    app = Application(
        full_name=data.full_name,
        business_name=data.business_name,
        contact_number=data.contact_number,
        email=data.email,
        district=data.district,
        industry_category_id=data.industry_category_id,
        status=ApplicationStatus.PENDING,
    )
    db.add(app)
    await db.flush()

    # Initial history
    history = ApplicationStatusHistory(
        application_id=app.id,
        old_status="",
        new_status=app.status.value,
        notes="Application submitted",
    )
    db.add(history)
    await db.flush()
    return app


async def get_user_applications(phone_number: str, db: AsyncSession) -> List[Application]:
    stmt = select(Application).where(Application.contact_number == phone_number).order_by(desc(Application.created_at))
    result = await db.execute(stmt)
    return list(result.scalars().all())


async def get_application_by_id(app_id: UUID, db: AsyncSession) -> Application:
    stmt = select(Application).where(Application.id == app_id)
    result = await db.execute(stmt)
    app = result.scalar_one_or_none()
    if not app:
        raise NotFoundException("Application not found")
    return app


async def get_application_history(app_id: UUID, db: AsyncSession) -> List[ApplicationStatusHistory]:
    stmt = select(ApplicationStatusHistory).where(ApplicationStatusHistory.application_id == app_id).order_by(ApplicationStatusHistory.created_at)
    res = await db.execute(stmt)
    return list(res.scalars().all())


async def list_applications(
    status: ApplicationStatus | None,
    industry_category_id: UUID | None,
    page: int,
    limit: int,
    db: AsyncSession,
) -> Tuple[List[Application], int]:
    stmt = select(Application)
    
    if status:
        stmt = stmt.where(Application.status == status)
    if industry_category_id:
        stmt = stmt.where(Application.industry_category_id == industry_category_id)
        
    count_stmt = select(func.count()).select_from(stmt.subquery())
    total = (await db.execute(count_stmt)).scalar() or 0
    
    stmt = stmt.order_by(desc(Application.created_at)).offset((page - 1) * limit).limit(limit)
    items = (await db.execute(stmt)).scalars().all()
    
    return list(items), total


async def _generate_privilege_card(user_id: UUID, db: AsyncSession) -> PrivilegeCard | None:
    # See if one already exists
    stmt = select(PrivilegeCard).where(PrivilegeCard.user_id == user_id)
    existing = (await db.execute(stmt)).scalar_one_or_none()
    if existing:
        return existing  # return existing card, not None
        
    # Generate random 10-char alphanum card number
    card_number = "PBN" + "".join(random.choices(string.digits, k=7))
    expiry = datetime.now(timezone.utc) + timedelta(days=365)
    
    payload = {
        "card_number": card_number,
        "user_id": str(user_id),
        "exp": expiry,
    }
    qr_data = jwt.encode(payload, settings.SECRET_KEY, algorithm="HS256")
    
    card = PrivilegeCard(
        user_id=user_id,
        card_number=card_number,
        qr_code_data=qr_data,
        issued_at=datetime.now(timezone.utc),
        expires_at=expiry,
    )
    db.add(card)
    return card


async def update_application_status(
    app_id: UUID,
    actor: User,
    data: ApplicationStatusUpdate,
    db: AsyncSession,
) -> Application:
    app = await get_application_by_id(app_id, db)
    
    old_status = app.status
    if data.status not in VALID_TRANSITIONS.get(old_status, []):
        raise BadRequestException(f"Invalid transition from {old_status.value} to {data.status.value}", code="INVALID_STATUS_TRANSITION")
        
    app.status = data.status
    if data.fit_call_date:
        app.fit_call_date = data.fit_call_date
        
    history = ApplicationStatusHistory(
        application_id=app.id,
        old_status=old_status.value,
        new_status=app.status.value,
        changed_by_user_id=actor.id,
        notes=data.notes,
    )
    db.add(history)
    
    # Audit log
    audit = AuditLog(
        actor_id=actor.id,
        entity_type="application",
        entity_id=app.id,
        action="status_update",
        old_value={"status": old_status.value},
        new_value={"status": app.status.value},
    )
    db.add(audit)
    
    # On Approval
    if data.status == ApplicationStatus.APPROVED:
        # Find or create user
        usr_stmt = select(User).where(User.phone_number == app.contact_number)
        user = (await db.execute(usr_stmt)).scalar_one_or_none()
        if not user:
            user = User(
                phone_number=app.contact_number,
                full_name=app.full_name,
                email=app.email,
                role=UserRole.PROSPECT,
                password_hash=hash_password("pbn123"), # Default password for initial login
            )
            db.add(user)
            await db.flush()
        else:
            if user.role != UserRole.SUPER_ADMIN: # Don't downgrade admins
                user.role = UserRole.PROSPECT
                user.full_name = app.full_name
                if app.email:
                    user.email = app.email
                if not user.password_hash:
                    user.password_hash = hash_password("pbn123")
                await db.flush()

        # Generate privilege card
        await _generate_privilege_card(user.id, db)
        
        # Determine chapter: use the admin's chapter, or fallback to any chapter if super admin, or data.chapter_id
        chapter_id = data.chapter_id
        if not chapter_id:
            # Let's see if admin is part of a chapter
            adm_chap_stmt = select(ChapterMembership.chapter_id).where(ChapterMembership.user_id == actor.id)
            actor_chapter = (await db.execute(adm_chap_stmt)).scalar_one_or_none()
            if actor_chapter:
                chapter_id = actor_chapter
            else:
                # Get the first chapter available
                chap_stmt = select(Chapter.id).limit(1)
                first_chap = (await db.execute(chap_stmt)).scalar_one_or_none()
                if first_chap:
                    chapter_id = first_chap
                else:
                    raise BadRequestException("No chapter available to assign", code="NO_CHAPTER")

        # Check if the slot is taken
        ind_stmt = select(ChapterMembership).where(
            ChapterMembership.chapter_id == chapter_id,
            ChapterMembership.industry_category_id == app.industry_category_id,
        )
        taken = (await db.execute(ind_stmt)).scalar_one_or_none()
        
        if taken:
            if taken.user_id != user.id:
                # Get names for better error message
                ic_stmt = select(IndustryCategory.name).where(IndustryCategory.id == app.industry_category_id)
                ch_stmt = select(Chapter.name).where(Chapter.id == chapter_id)
                ic_name = (await db.execute(ic_stmt)).scalar() or "Unknown"
                ch_name = (await db.execute(ch_stmt)).scalar() or "This Chapter"
                
                raise BadRequestException(
                    f'The "{ic_name}" slot is already occupied by another member in "{ch_name}".',
                    code="INDUSTRY_TAKEN"
                )
        else:
            new_mem = ChapterMembership(
                user_id=user.id,
                chapter_id=chapter_id,
                industry_category_id=app.industry_category_id,
                membership_type=MembershipType.STANDARD,
                start_date=date.today(),
                end_date=date.today() + timedelta(days=365),
                is_active=(data.payment_status == "completed") # Active if paid
            )
            db.add(new_mem)
            
            # Automatically create a payment record for the membership
            # Use data.payment_status if provided, else default to PENDING
            p_status = PaymentStatus.PENDING
            if data.payment_status == "completed":
                p_status = PaymentStatus.COMPLETED

            membership_payment = Payment(
                user_id=user.id,
                amount=Decimal("15000.00"),
                currency="LKR",
                payment_type=PaymentType.MEMBERSHIP,
                reason=f"Membership fee for {app.business_name}",
                status=p_status,
                recorded_by_id=actor.id,
            )
            db.add(membership_payment)
            
            # If payment is completed, upgrade the user role immediately
            if p_status == PaymentStatus.COMPLETED:
                user.role = UserRole.MEMBER

            # Also create the Business profile for the user
            from app.models.businesses import Business
            business = Business(
                owner_user_id=user.id,
                business_name=app.business_name,
                industry_category_id=app.industry_category_id,
                district=app.district,
            )
            db.add(business)

    await db.flush()
    return app
