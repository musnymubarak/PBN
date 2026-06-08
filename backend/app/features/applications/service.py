"""
Prime Business Network – Applications API Service.
"""

from __future__ import annotations

import math
import random
import string
from datetime import date, datetime, timedelta, timezone
from decimal import Decimal
import logging
from typing import List, Tuple, TYPE_CHECKING, Optional
from uuid import UUID
import secrets

logger = logging.getLogger(__name__)

from sqlalchemy import select, desc, func
from sqlalchemy.ext.asyncio import AsyncSession
from jose import jwt

from app.core.exceptions import BadRequestException, NotFoundException
from app.features.auth.service import hash_password
from app.features.notifications.service import send_push_notification, notify_multiple_users, notify_admins
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
from app.core.email_service import send_email, render_template

settings = get_settings()

VALID_TRANSITIONS = {
    ApplicationStatus.PENDING: [
        ApplicationStatus.FIT_CALL_SCHEDULED,
        ApplicationStatus.APPROVED,
        ApplicationStatus.REJECTED
    ],
    ApplicationStatus.FIT_CALL_SCHEDULED: [
        ApplicationStatus.APPROVED,
        ApplicationStatus.REJECTED,
        ApplicationStatus.WAITLISTED,
    ],
    ApplicationStatus.WAITLISTED: [ApplicationStatus.APPROVED],
}


def generate_temp_password(length=10) -> str:
    """Generates a secure alphanumeric password."""
    alphabet = string.ascii_letters + string.digits
    while True:
        pwd = ''.join(secrets.choice(alphabet) for _ in range(length))
        if any(c.isupper() for c in pwd) and any(c.isdigit() for c in pwd):
            return pwd

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
    # Normalize email (lowercased, trimmed) for consistent uniqueness checks
    normalized_email = (data.email or "").strip().lower() or None

    # Validate industry active
    stmt = select(IndustryCategory).where(
        IndustryCategory.id == data.industry_category_id,
        IndustryCategory.is_active.is_(True),
    )
    result = await db.execute(stmt)
    if result.scalar_one_or_none() is None:
        raise BadRequestException("Invalid or inactive industry category.", code="INVALID_INDUSTRY")

    # ── Email uniqueness ─────────────────────────────────────────────────
    # Reject if the email is already linked to a registered user/member.
    if normalized_email:
        existing_user_stmt = select(User.id).where(func.lower(User.email) == normalized_email).limit(1)
        if (await db.execute(existing_user_stmt)).first() is not None:
            raise BadRequestException(
                "This email is already registered to an existing member. Please login or use a different email.",
                code="EMAIL_REGISTERED",
            )

        # Reject if an active (non-rejected) application already uses this email.
        existing_app_email_stmt = select(Application.id).where(
            func.lower(Application.email) == normalized_email,
            Application.status.notin_([ApplicationStatus.REJECTED]),
        ).limit(1)
        if (await db.execute(existing_app_email_stmt)).first() is not None:
            raise BadRequestException(
                "An application with this email already exists. Please wait for review or contact support.",
                code="EMAIL_APPLICATION_EXISTS",
            )

    # ── Phone uniqueness ─────────────────────────────────────────────────
    # Reject if the phone number is already linked to a registered user/member.
    existing_phone_stmt = select(User.id).where(User.phone_number == data.contact_number).limit(1)
    if (await db.execute(existing_phone_stmt)).first() is not None:
        raise BadRequestException(
            "This contact number is already registered to an existing member. Please login or use a different number.",
            code="PHONE_REGISTERED",
        )

    # Reject if an active (non-rejected) application already uses this phone.
    existing_app_phone_stmt = select(Application.id).where(
        Application.contact_number == data.contact_number,
        Application.status.notin_([ApplicationStatus.REJECTED]),
    ).limit(1)
    if (await db.execute(existing_app_phone_stmt)).first() is not None:
        raise BadRequestException(
            "An application with this contact number already exists. Please wait for review or contact support.",
            code="PHONE_APPLICATION_EXISTS",
        )

    # Check if industry is already occupied by a member in this chapter
    occ_stmt = select(ChapterMembership).where(
        ChapterMembership.chapter_id == data.chapter_id,
        ChapterMembership.industry_category_id == data.industry_category_id,
        ChapterMembership.is_active.is_(True)
    )
    if (await db.execute(occ_stmt)).scalar_one_or_none() is not None:
        raise BadRequestException("This industry is already occupied in the selected chapter.", code="INDUSTRY_OCCUPIED")

    app = Application(
        full_name=data.full_name,
        business_name=data.business_name,
        contact_number=data.contact_number,
        email=normalized_email,
        district=data.district,
        industry_category_id=data.industry_category_id,
        chapter_id=data.chapter_id,
        status=ApplicationStatus.PENDING,
        designation=data.designation,
        decision_authority=data.decision_authority,
        years_in_operation=data.years_in_operation,
        business_legal_type=data.business_legal_type,
        business_registration_number=data.business_registration_number,
        website_url=data.website_url,
        linkedin_url=data.linkedin_url,
        referred_by_user_id=data.referred_by_user_id,
        what_you_offer=data.what_you_offer,
        what_you_seek=data.what_you_seek,
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

    # Notify Super Admins about the new application
    try:
        from app.features.notifications.service import send_push_notification
        # Find all Super Admins
        admin_stmt = select(User.id).where(User.role.in_([UserRole.SUPER_ADMIN, UserRole.ADMIN]), User.is_active == True)
        admin_ids = (await db.execute(admin_stmt)).scalars().all()
        
        for admin_id in admin_ids:
            await send_push_notification(
                user_id=admin_id,
                title="New Membership Application",
                body=f"{data.full_name} from {data.business_name} has applied for membership.",
                notification_type="NEW_APPLICATION",
                data={"application_id": str(app.id), "route": "/applications"}
            )
    except Exception as e:
        logger.error(f"Failed to notify admins of new application: {e}")

    # Send confirmation email to applicant
    if app.email:
        try:
            html = render_template("application_received.html", {
                "full_name": app.full_name,
                "business_name": app.business_name
            })
            await send_email(app.email, "Application Received - Prime Business Network", html)
        except Exception as e:
            logger.error(f"Failed to send confirmation email to {app.email}: {e}")

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
) -> Tuple[List[dict], int]:
    stmt = select(
        Application,
        Chapter.name.label("chapter_name")
    ).outerjoin(Chapter, Application.chapter_id == Chapter.id)
    
    if status:
        stmt = stmt.where(Application.status == status)
    if industry_category_id:
        stmt = stmt.where(Application.industry_category_id == industry_category_id)
        
    count_stmt = select(func.count()).select_from(stmt.subquery())
    total = (await db.execute(count_stmt)).scalar() or 0
    
    stmt = stmt.order_by(desc(Application.created_at)).offset((page - 1) * limit).limit(limit)
    result = await db.execute(stmt)
    
    data = []
    for row in result.all():
        app = row[0]
        chapter_name = row[1]
        app_dict = {
            "id": app.id,
            "full_name": app.full_name,
            "business_name": app.business_name,
            "contact_number": app.contact_number,
            "email": app.email,
            "district": app.district,
            "industry_category_id": app.industry_category_id,
            "chapter_id": app.chapter_id,
            "chapter_name": chapter_name,
            "status": app.status,
            "fit_call_date": app.fit_call_date,
            "notes": app.notes,
            "created_at": app.created_at,
            "updated_at": app.updated_at,
        }
        data.append(app_dict)
    
    return data, total



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
        # Allow admin to backfill a missing email at approval time.
        if data.email and not app.email:
            app.email = data.email.strip().lower() or None

        # Hard guard: we cannot deliver the onboarding link without an email.
        if not app.email:
            raise BadRequestException(
                "Email is required to approve and send the onboarding link. "
                "Add the applicant's email and try again.",
                code="EMAIL_REQUIRED_FOR_APPROVAL",
            )

        # Find or create user
        usr_stmt = select(User).where(User.phone_number == app.contact_number)
        user = (await db.execute(usr_stmt)).scalar_one_or_none()

        # Generate new password
        temp_password = generate_temp_password()
        
        if not user:
            user = User(
                phone_number=app.contact_number,
                full_name=app.full_name,
                email=app.email,
                role=UserRole.PROSPECT,
                password_hash=hash_password(temp_password),
                must_change_password=True,
            )
            db.add(user)
            await db.flush()
        else:
            if user.role not in (UserRole.SUPER_ADMIN, UserRole.ADMIN): # Don't downgrade admins
                user.role = UserRole.PROSPECT
                user.full_name = app.full_name
                if app.email:
                    user.email = app.email
                user.password_hash = hash_password(temp_password)
                user.must_change_password = True
                await db.flush()

        # Generate privilege card
        await _generate_privilege_card(user.id, db)

        # Issue a single-use onboarding token (14-day expiry) and build the link
        # for the approval email. We do this before sending so the link is in the
        # email body. Token is regenerated on every approval to prevent reuse of
        # any prior link.
        app.onboarding_token = secrets.token_urlsafe(32)
        app.onboarding_token_expires_at = datetime.now(timezone.utc) + timedelta(days=14)
        app.onboarding_completed_at = None
        onboarding_url = f"{settings.PUBLIC_SITE_URL.rstrip('/')}/onboard?token={app.onboarding_token}"

        # Send Approval Email
        try:
            missing_fields = _missing_onboarding_fields(app)
            html = render_template("application_approved.html", {
                "full_name": app.full_name,
                "business_name": app.business_name,
                "email": app.email,
                "password": temp_password,
                "onboarding_url": onboarding_url,
                "has_missing_fields": bool(missing_fields),
                "play_store_url": settings.PLAY_STORE_URL,
                "app_store_url": settings.APP_STORE_URL,
            })
            await send_email(app.email, "Welcome to PBN! Your Application is Approved", html)
        except Exception as e:
            logger.error(f"Failed to send approval email to {app.email}: {e}")
        
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

        # Notify User via Push
        try:
            await send_push_notification(
                user_id=user.id,
                title="Application Approved!",
                body=f"Welcome to PBN! Your application for {app.business_name} has been approved.",
                notification_type="APPLICATION_APPROVED",
                data={"application_id": str(app.id), "route": "/my-applications"}
            )
        except Exception:
            pass

        # Notify Chapter about new member
        try:
            # Find active members in this chapter (excluding the new one)
            other_members_stmt = select(User.id).join(ChapterMembership).where(
                ChapterMembership.chapter_id == chapter_id,
                User.id != user.id,
                User.is_active == True
            )
            other_member_ids = (await db.execute(other_members_stmt)).scalars().all()
            if other_member_ids:
                await notify_multiple_users(
                    other_member_ids,
                    "🤝 New Member Joined!",
                    f"Please welcome {app.full_name} from {app.business_name} to our chapter!",
                    "NEW_MEMBER_JOINED",
                    {"user_id": str(user.id), "route": "/members"}
                )
        except Exception:
            pass

        # Notify admins (panel feed): a member was approved & onboarded
        try:
            await notify_admins(
                title="✅ Application Approved",
                body=f"{app.full_name} ({app.business_name}) was approved and onboarded.",
                notification_type="ADMIN_MEMBER_APPROVED",
                data={"member_id": str(user.id), "application_id": str(app.id), "route": "/members"},
            )
        except Exception:
            pass

    # Handle Fit Call Scheduled Email
    if data.status == ApplicationStatus.FIT_CALL_SCHEDULED and app.email and app.fit_call_date:
        try:
            html = render_template("fit_call_scheduled.html", {
                "full_name": app.full_name,
                "business_name": app.business_name,
                "fit_call_date": app.fit_call_date.strftime("%Y-%m-%d %I:%M %p")
            })
            await send_email(app.email, "Fit Call Scheduled - Prime Business Network", html)
        except Exception as e:
            logger.error(f"Failed to send fit call email to {app.email}: {e}")

    # Handle Rejected Email
    if data.status == ApplicationStatus.REJECTED and app.email:
        try:
            html = render_template("application_rejected.html", {
                "full_name": app.full_name,
                "business_name": app.business_name,
                "reason": data.notes or "No specific reason provided."
            })
            await send_email(app.email, "Update on your PBN Application", html)
        except Exception as e:
            logger.error(f"Failed to send rejection email to {app.email}: {e}")

    if data.status == ApplicationStatus.REJECTED:
        try:
            await notify_admins(
                title="Application Rejected",
                body=f"{app.full_name}'s application ({app.business_name}) was rejected.",
                notification_type="ADMIN_APPLICATION_REJECTED",
                data={"application_id": str(app.id), "route": "/applications"},
            )
        except Exception:
            pass

    await db.flush()
    return app


async def delete_application(app_id: UUID, db: AsyncSession) -> None:
    """Permanently delete an application and its history (via CASCADE)."""
    app = await get_application_by_id(app_id, db)
    await db.delete(app)
    await db.commit()


# ── Onboarding ───────────────────────────────────────────────────────────────

from app.features.applications.schemas import (
    ONBOARDING_REQUIRED_FIELDS,
    OnboardingDetailsUpdate,
    OnboardingTshirtUpdate,
)


def _missing_onboarding_fields(app: Application) -> list[str]:
    """Return Tier-1 field names that are still empty on the application."""
    return [f for f in ONBOARDING_REQUIRED_FIELDS if not getattr(app, f, None)]


async def _get_app_by_onboarding_token(token: str, db: AsyncSession) -> Application:
    stmt = select(Application).where(Application.onboarding_token == token)
    app = (await db.execute(stmt)).scalar_one_or_none()
    if not app:
        raise NotFoundException("Onboarding link is invalid or has already been used.")
    if app.onboarding_token_expires_at and app.onboarding_token_expires_at < datetime.now(timezone.utc):
        raise BadRequestException(
            "This onboarding link has expired. Please contact PBN support to receive a new link.",
            code="ONBOARDING_TOKEN_EXPIRED",
        )
    return app


async def get_onboarding_status(token: str, db: AsyncSession) -> dict:
    app = await _get_app_by_onboarding_token(token, db)
    return {
        "application_id": app.id,
        "full_name": app.full_name,
        "business_name": app.business_name,
        "email": app.email,
        "missing_fields": _missing_onboarding_fields(app),
        "tshirt_size": app.tshirt_size,
        "completed": app.onboarding_completed_at is not None,
        "expires_at": app.onboarding_token_expires_at,
        "designation": app.designation,
        "decision_authority": app.decision_authority,
        "years_in_operation": app.years_in_operation,
        "business_legal_type": app.business_legal_type,
        "business_registration_number": app.business_registration_number,
        "website_url": app.website_url,
        "linkedin_url": app.linkedin_url,
        "what_you_offer": app.what_you_offer,
        "what_you_seek": app.what_you_seek,
    }


async def update_onboarding_details(
    token: str,
    data: OnboardingDetailsUpdate,
    db: AsyncSession,
) -> dict:
    """Backfill missing Tier-1 fields. Only non-null values in the payload are written."""
    app = await _get_app_by_onboarding_token(token, db)

    updates = data.model_dump(exclude_unset=True, exclude_none=True)
    for field, value in updates.items():
        setattr(app, field, value)

    await db.commit()
    await db.refresh(app)
    return await get_onboarding_status(token, db)


async def submit_onboarding_tshirt(
    token: str,
    data: OnboardingTshirtUpdate,
    db: AsyncSession,
) -> dict:
    """Record T-shirt size in the complements ledger and finalize onboarding.

    The size is persisted on `member_complements` (sole truth for fulfilment),
    NOT on `applications.tshirt_size` — that column is left untouched as a
    frozen historical record from earlier flows.

    Token is invalidated on success.
    """
    from app.features.complements.service import assign_complement

    app = await _get_app_by_onboarding_token(token, db)

    missing = _missing_onboarding_fields(app)
    if missing:
        raise BadRequestException(
            f"Cannot finalize onboarding while these fields are still missing: {', '.join(missing)}.",
            code="ONBOARDING_FIELDS_MISSING",
        )

    # Find the approved member account created at application-approval time.
    user_stmt = select(User).where(User.phone_number == app.contact_number)
    user = (await db.execute(user_stmt)).scalar_one_or_none()
    if not user:
        raise BadRequestException(
            "Member account is not provisioned yet. Please try again in a few minutes.",
            code="MEMBER_ACCOUNT_MISSING",
        )

    await assign_complement(
        user_id=user.id,
        type_code="founders_tshirt",
        variant=data.size.value,
        db=db,
    )

    app.onboarding_completed_at = datetime.now(timezone.utc)
    app.onboarding_token = None  # invalidate single-use token

    await db.commit()
    return {
        "application_id": str(app.id),
        "tshirt_size": data.size.value,
        "completed_at": app.onboarding_completed_at.isoformat(),
    }
