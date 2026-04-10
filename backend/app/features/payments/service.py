"""
Prime Business Network – Payments Service.

Handles payment initiation (WebxPay), webhook verification, and
automated side-effects (RSVP creation, membership extension).
"""

from __future__ import annotations

import hashlib
import hmac
import uuid
from datetime import datetime, timezone, timedelta
from decimal import Decimal
from typing import Any, Dict, List
from uuid import UUID

from app.features.payments.schemas import PaymentCreateAdmin, PaymentUpdateAdmin

from sqlalchemy import select, desc
from sqlalchemy.ext.asyncio import AsyncSession
from sqlalchemy.orm import joinedload

from app.core.config import get_settings
from app.core.exceptions import BadRequestException, NotFoundException
from app.models.audit_logs import AuditLog
from app.models.events import EventRSVP
from app.models.memberships import ChapterMembership
from app.models.payments import Payment, PaymentStatus, PaymentType


def _generate_hmac(data: str, secret: str) -> str:
    """Generate HMAC-SHA256 signature for WebxPay."""
    return hmac.new(
        secret.encode("utf-8"),
        data.encode("utf-8"),
        hashlib.sha256,
    ).hexdigest().upper()


def _serialize_payment(p: Payment) -> Dict[str, Any]:
    return {
        "id": str(p.id),
        "user_id": str(p.user_id),
        "amount": float(p.amount),
        "currency": p.currency,
        "payment_type": p.payment_type.value,
        "reason": p.reason,
        "notes": p.notes,
        "reference_id": p.reference_id,
        "gateway_reference": p.gateway_reference,
        "status": p.status.value,
        "created_at": p.created_at.isoformat() if p.created_at else None,
        "updated_at": p.updated_at.isoformat() if p.updated_at else None,
        "user_name": p.user.full_name if "user" in p.__dict__ and p.user else None,
        "user_phone": p.user.phone_number if "user" in p.__dict__ and p.user else None,
    }


async def initiate_payment(
    user_id: UUID,
    payment_type: PaymentType,
    amount: Decimal,
    event_id: UUID | None,
    db: AsyncSession,
) -> Dict[str, Any]:
    """Create a pending Payment and return the WebxPay redirect URL."""
    settings = get_settings()

    order_id = f"PBN-{uuid.uuid4().hex[:12].upper()}"

    payment = Payment(
        user_id=user_id,
        amount=amount,
        currency="LKR",
        payment_type=payment_type,
        reference_id=str(event_id) if event_id else None,
        status=PaymentStatus.PENDING,
    )
    db.add(payment)
    await db.flush()

    # Build WebxPay signature payload
    sig_string = (
        f"{settings.WEBXPAY_MERCHANT_ID}{order_id}{float(amount):.2f}"
        f"LKR{hashlib.md5(settings.WEBXPAY_SECRET_KEY.encode()).hexdigest().upper()}"
    )
    signature = hashlib.md5(sig_string.encode()).hexdigest().upper()

    payment_url = (
        f"{settings.WEBXPAY_API_URL}?"
        f"merchant_id={settings.WEBXPAY_MERCHANT_ID}"
        f"&order_id={order_id}"
        f"&payment_id={payment.id}"
        f"&amount={float(amount):.2f}"
        f"&currency=LKR"
        f"&return_url={settings.WEBXPAY_RETURN_URL}"
        f"&cancel_url={settings.WEBXPAY_CANCEL_URL}"
        f"&notify_url={settings.WEBXPAY_NOTIFY_URL}"
        f"&hash={signature}"
    )

    # Store the order_id on the payment for later lookup
    payment.gateway_reference = order_id
    await db.flush()

    return {
        "payment_id": str(payment.id),
        "payment_url": payment_url,
        "order_id": order_id,
    }


async def verify_webhook_signature(payload: dict, secret: str) -> bool:
    """Verify the HMAC signature from WebxPay webhook callback."""
    received_sig = payload.get("md5sig", "")
    order_id = payload.get("order_id", "")
    status_code = payload.get("status_code", "")

    sig_string = (
        f"{order_id}{status_code}"
        f"{hashlib.md5(secret.encode()).hexdigest().upper()}"
    )
    expected_sig = hashlib.md5(sig_string.encode()).hexdigest().upper()
    return hmac.compare_digest(received_sig, expected_sig)


async def process_webhook(payload: dict, db: AsyncSession) -> Dict[str, Any]:
    """Process an incoming WebxPay webhook notification."""
    settings = get_settings()

    # Verify signature (skip verification for simulated webhooks)
    is_simulated = payload.get("simulated", False)
    if not is_simulated:
        valid = await verify_webhook_signature(payload, settings.WEBXPAY_SECRET_KEY)
        if not valid:
            raise BadRequestException("Invalid webhook signature", code="INVALID_SIGNATURE")

    payment_id = payload.get("payment_id")
    if not payment_id:
        raise BadRequestException("Missing payment_id")

    payment = (await db.execute(
        select(Payment).where(Payment.id == payment_id)
    )).scalar_one_or_none()

    if not payment:
        raise NotFoundException("Payment not found")

    if payment.status != PaymentStatus.PENDING:
        raise BadRequestException("Payment already processed")

    # Determine success or failure
    status_code = payload.get("status_code", "2")
    if str(status_code) == "2":  # WebxPay success code
        payment.status = PaymentStatus.COMPLETED
        payment.gateway_response = payload

        # Side effects
        await _apply_payment_side_effects(payment, db)
    else:
        payment.status = PaymentStatus.FAILED
        payment.gateway_response = payload

    # Audit
    audit = AuditLog(
        actor_id=None,
        entity_type="payment",
        entity_id=payment.id,
        action="webhook_processed",
        old_value={"status": "pending"},
        new_value={"status": payment.status.value},
    )
    db.add(audit)
    await db.flush()

    return {"status": payment.status.value, "payment_id": str(payment.id)}


async def _apply_payment_side_effects(payment: Payment, db: AsyncSession) -> None:
    """Apply automated side-effects after successful payment."""
    if payment.payment_type == PaymentType.MEETING_FEE and payment.reference_id:
        # Create EventRSVP with status going
        from app.models.events import EventRSVP, RSVPStatus
        existing = (await db.execute(
            select(EventRSVP).where(
                EventRSVP.event_id == payment.reference_id,
                EventRSVP.user_id == payment.user_id,
            )
        )).scalar_one_or_none()
        if not existing:
            rsvp = EventRSVP(
                event_id=uuid.UUID(payment.reference_id),
                user_id=payment.user_id,
                status=RSVPStatus.GOING,
            )
            db.add(rsvp)

    elif payment.payment_type == PaymentType.MEMBERSHIP:
        # 1. Activate the ChapterMembership for this user
        ship_stmt = select(ChapterMembership).where(
            ChapterMembership.user_id == payment.user_id,
            ChapterMembership.is_active.is_(False)
        ).order_by(desc(ChapterMembership.created_at)).limit(1)
        
        membership = (await db.execute(ship_stmt)).scalar_one_or_none()
        if membership:
            membership.is_active = True
            
        # 2. Upgrade user role from PROSPECT to MEMBER
        from app.models.user import User, UserRole
        usr_stmt = select(User).where(User.id == payment.user_id)
        user = (await db.execute(usr_stmt)).scalar_one_or_none()
        if user and user.role == UserRole.PROSPECT:
            user.role = UserRole.MEMBER


async def simulate_webhook(payment_id: UUID, db: AsyncSession) -> Dict[str, Any]:
    """Simulate a successful WebxPay webhook for dev/testing."""
    payload = {
        "payment_id": str(payment_id),
        "status_code": "2",
        "order_id": "SIMULATED",
        "md5sig": "SIMULATED",
        "simulated": True,
    }
    return await process_webhook(payload, db)


async def get_my_payments(user_id: UUID, db: AsyncSession) -> List[Dict[str, Any]]:
    """Return all payments for a user, newest first."""
    stmt = select(Payment).where(Payment.user_id == user_id).order_by(desc(Payment.created_at))
    result = await db.execute(stmt)
    return [_serialize_payment(p) for p in result.scalars().all()]


async def get_payment_status(payment_id: UUID, user_id: UUID | None, is_admin: bool, db: AsyncSession) -> Dict[str, Any]:
    """Get a single payment's status."""
    payment = (await db.execute(
        select(Payment).where(Payment.id == payment_id)
    )).scalar_one_or_none()

    if not payment:
        raise NotFoundException("Payment not found")

    if not is_admin and payment.user_id != user_id:
        from app.core.exceptions import ForbiddenException
        raise ForbiddenException("Cannot view another user's payment")

    return _serialize_payment(payment)


async def list_all_payments(
    status_filter: str | None, type_filter: str | None, db: AsyncSession
) -> List[Dict[str, Any]]:
    """Admin: list all payments with user info and optional filters."""
    stmt = select(Payment).options(joinedload(Payment.user)).order_by(desc(Payment.created_at))
    if status_filter:
        stmt = stmt.where(Payment.status == status_filter)
    if type_filter:
        stmt = stmt.where(Payment.payment_type == type_filter)
    result = await db.execute(stmt)
    return [_serialize_payment(p) for p in result.scalars().all()]


async def record_manual_payment(
    actor_id: UUID,
    data: PaymentCreateAdmin,
    db: AsyncSession,
) -> Payment:
    """Record a payment manually by an admin."""
    payment = Payment(
        user_id=data.user_id,
        amount=data.amount,
        currency="LKR",
        payment_type=data.payment_type,
        reason=data.reason,
        notes=data.notes,
        status=data.status,
        recorded_by_id=actor_id,
    )
    db.add(payment)
    await db.flush()
    
    # Audit
    audit = AuditLog(
        actor_id=actor_id,
        entity_type="payment",
        entity_id=payment.id,
        action="manual_record",
        new_value=_serialize_payment(payment),
    )
    db.add(audit)
    
    # Still apply side effects (RSVPs etc) if it's completed immediately
    if payment.status == PaymentStatus.COMPLETED:
        await _apply_payment_side_effects(payment, db)
        
    return payment


async def update_payment(
    payment_id: UUID,
    actor_id: UUID,
    data: PaymentUpdateAdmin,
    db: AsyncSession,
) -> Payment:
    """Update payment details manually (Admin only)."""
    stmt = select(Payment).where(Payment.id == payment_id)
    res = await db.execute(stmt)
    payment = res.scalar_one_or_none()
    if not payment:
        raise NotFoundException("Payment not found")

    old_val = _serialize_payment(payment)

    if data.amount is not None:
        payment.amount = data.amount
    if data.payment_type is not None:
        payment.payment_type = data.payment_type
    if data.reason is not None:
        payment.reason = data.reason
    if data.notes is not None:
        payment.notes = data.notes
    
    trigger_side_effects = False
    if data.status is not None:
        if payment.status != PaymentStatus.COMPLETED and data.status == PaymentStatus.COMPLETED:
            trigger_side_effects = True
        payment.status = data.status

    await db.flush()

    # Audit
    audit = AuditLog(
        actor_id=actor_id,
        entity_type="payment",
        entity_id=payment.id,
        action="admin_update",
        old_value=old_val,
        new_value=_serialize_payment(payment),
    )
    db.add(audit)

    if trigger_side_effects:
        await _apply_payment_side_effects(payment, db)

    return payment
