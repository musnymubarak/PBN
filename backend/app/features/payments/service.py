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

from app.features.notifications.service import send_push_notification, notify_admins
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
    # Find the latest proof if loaded
    latest_proof = None
    if "proofs" in p.__dict__ and p.proofs:
        latest_proof = sorted(p.proofs, key=lambda x: x.created_at or datetime.min, reverse=True)[0]

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
        "proof_status": latest_proof.status.value if latest_proof else None,
        "proof_notes": latest_proof.admin_notes if latest_proof else None,
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


async def process_webhook(
    payload: dict,
    db: AsyncSession,
    *,
    _skip_signature_check: bool = False,
) -> Dict[str, Any]:
    """Process an incoming WebxPay webhook notification.

    `_skip_signature_check` is a keyword-only internal flag used by
    `simulate_webhook()` in non-prod environments. It is NOT readable
    from the request payload — the public webhook endpoint can never
    set it.
    """
    settings = get_settings()

    if not _skip_signature_check:
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
        
        # Notify User
        try:
            await send_push_notification(
                user_id=payment.user_id,
                title="Payment Successful",
                body=f"Your payment of LKR {float(payment.amount):,.0f} has been confirmed.",
                notification_type="PAYMENT_SUCCESS",
                data={"payment_id": str(payment.id), "route": "/payments"}
            )
        except Exception:
            pass

        # Notify admins (panel feed): money came in
        try:
            await notify_admins(
                title="💰 Payment Received",
                body=f"LKR {float(payment.amount):,.0f} received for {payment.payment_type.value}.",
                notification_type="ADMIN_PAYMENT_RECEIVED",
                data={"payment_id": str(payment.id), "route": "/payments"},
            )
        except Exception:
            pass
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
            
            # Send standard membership activated email
            from app.core.email_service import send_email, render_template
            import logging
            from app.models.applications import Application
            from app.features.applications.service import _missing_onboarding_fields
            logger = logging.getLogger(__name__)
            
            onboarding_url = None
            has_missing_fields = True
            if user.email:
                app_stmt = select(Application).where(Application.email == user.email).order_by(desc(Application.created_at))
                application = (await db.execute(app_stmt)).scalars().first()
                if application:
                    has_missing_fields = bool(_missing_onboarding_fields(application))
                    if application.onboarding_token:
                        onboarding_url = f"{get_settings().PUBLIC_SITE_URL.rstrip('/')}/onboard?token={application.onboarding_token}"
                    
                try:
                    html = render_template("membership_activated.html", {
                        "full_name": user.full_name,
                        "amount": float(payment.amount),
                        "onboarding_url": onboarding_url,
                        "has_missing_fields": has_missing_fields,
                        "app_store_url": get_settings().APP_STORE_URL,
                        "play_store_url": get_settings().PLAY_STORE_URL
                    })
                    await send_email(user.email, "Your PBN Membership is Activated!", html)
                except Exception as e:
                    logger.error(f"Failed to send membership activation email to {user.email}: {e}")


async def simulate_webhook(payment_id: UUID, db: AsyncSession) -> Dict[str, Any]:
    """Simulate a successful WebxPay webhook for dev/testing.

    Only reachable via the env-gated /payments/simulate-webhook endpoint;
    bypasses signature check via the internal _skip_signature_check flag.
    """
    payload = {
        "payment_id": str(payment_id),
        "status_code": "2",
        "order_id": "SIMULATED",
    }
    return await process_webhook(payload, db, _skip_signature_check=True)


async def get_my_payments(user_id: UUID, db: AsyncSession) -> List[Dict[str, Any]]:
    """Return all payments for a user, newest first."""
    from app.models.user import User, UserRole
    user = (await db.execute(select(User).where(User.id == user_id))).scalar_one_or_none()
    
    if user and user.role == UserRole.PROSPECT:
        m_stmt = select(Payment).where(
            Payment.user_id == user_id,
            Payment.payment_type == PaymentType.MEMBERSHIP
        )
        existing_mem_payment = (await db.execute(m_stmt)).scalars().first()
        if not existing_mem_payment:
            new_payment = Payment(
                user_id=user_id,
                amount=Decimal("15000.00"),
                currency="LKR",
                payment_type=PaymentType.MEMBERSHIP,
                reason="Membership fee",
                status=PaymentStatus.PENDING,
            )
            db.add(new_payment)
            await db.flush()
    stmt = select(Payment).options(joinedload(Payment.proofs)).where(Payment.user_id == user_id).order_by(desc(Payment.created_at))
    result = await db.execute(stmt)
    return [_serialize_payment(p) for p in result.scalars().all()]


async def get_payment_status(payment_id: UUID, user_id: UUID | None, is_admin: bool, db: AsyncSession) -> Dict[str, Any]:
    """Get a single payment's status."""
    payment = (await db.execute(
        select(Payment).options(joinedload(Payment.proofs)).where(Payment.id == payment_id)
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
    stmt = select(Payment).options(joinedload(Payment.user), joinedload(Payment.proofs)).order_by(desc(Payment.created_at))
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
        
        # Notify User
        try:
            await send_push_notification(
                user_id=payment.user_id,
                title="Payment Recorded",
                body=f"A payment for {payment.reason or payment.payment_type.value} has been recorded by admin.",
                notification_type="PAYMENT_RECORDED",
                data={"payment_id": str(payment.id), "route": "/payments"}
            )
        except Exception:
            pass

        # Notify admins (panel feed): payment recorded
        try:
            await notify_admins(
                title="💰 Payment Recorded",
                body=f"LKR {float(payment.amount):,.0f} recorded for {payment.payment_type.value}.",
                notification_type="ADMIN_PAYMENT_RECEIVED",
                data={"payment_id": str(payment.id), "route": "/payments"},
            )
        except Exception:
            pass

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

        # Notify admins (panel feed): payment marked completed
        try:
            await notify_admins(
                title="💰 Payment Received",
                body=f"LKR {float(payment.amount):,.0f} marked completed for {payment.payment_type.value}.",
                notification_type="ADMIN_PAYMENT_RECEIVED",
                data={"payment_id": str(payment.id), "route": "/payments"},
            )
        except Exception:
            pass

    return payment


# ── Payment Proofs ───────────────────────────────────────────────────────────

import os
import shutil
from fastapi import UploadFile
from app.models.payment_proofs import PaymentProof, PaymentProofStatus, PaymentProofType

async def get_proof_upload_status(token: str, db: AsyncSession) -> Dict[str, Any]:
    from app.models.user import User
    from app.models.payments import PaymentStatus
    stmt = (
        select(PaymentProof, Payment, User)
        .join(Payment, Payment.id == PaymentProof.payment_id)
        .join(User, User.id == PaymentProof.user_id)
        .where(PaymentProof.upload_token == token)
    )
    res = await db.execute(stmt)
    row = res.first()
    if not row:
        raise NotFoundException("Invalid or expired upload token.")
    
    proof, payment, user = row
    
    # 1. Check if token expired by time
    if proof.upload_token_expires_at < datetime.now(timezone.utc):
        raise BadRequestException("This upload link has expired.")

    # 2. Check if already paid (completed in other ways)
    if payment.status == PaymentStatus.COMPLETED:
        raise BadRequestException("Payment has already been made and completed.")

    # 3. Check if already uploaded and waiting for review
    if proof.status == PaymentProofStatus.APPROVED:
        raise BadRequestException("This payment proof has already been approved.")
        
    if proof.status == PaymentProofStatus.PENDING_REVIEW and proof.proof_type is not None:
        raise BadRequestException("Payment proof has already been uploaded and is pending review.")
    
    return {
        "status": proof.status.value,
        "payment_amount": str(payment.amount),
        "payment_reason": payment.reason,
        "user_name": user.full_name,
    }

async def submit_payment_proof(token: str, proof_type: PaymentProofType, reference_number: str | None, file: UploadFile | None, db: AsyncSession) -> Dict[str, Any]:
    from app.models.payments import Payment, PaymentStatus
    
    stmt = select(PaymentProof).where(PaymentProof.upload_token == token)
    res = await db.execute(stmt)
    proof = res.scalar_one_or_none()
    
    if not proof:
        raise NotFoundException("Invalid or expired upload token.")
        
    # 1. Check if token expired by time
    if proof.upload_token_expires_at < datetime.now(timezone.utc):
        raise BadRequestException("This upload link has expired.")

    # 2. Check if already paid (completed in other ways)
    pay_stmt = select(Payment).where(Payment.id == proof.payment_id)
    pay_res = await db.execute(pay_stmt)
    payment = pay_res.scalar_one_or_none()
    if payment and payment.status == PaymentStatus.COMPLETED:
        raise BadRequestException("Payment has already been made and completed.")

    # 3. Check if already uploaded and waiting for review
    if proof.status == PaymentProofStatus.APPROVED:
        raise BadRequestException("This payment proof has already been approved.")
        
    if proof.status == PaymentProofStatus.PENDING_REVIEW and proof.proof_type is not None:
        raise BadRequestException("Payment proof has already been uploaded and is pending review.")
        
    proof.proof_type = proof_type
    proof.reference_number = reference_number
    
    if file:
        upload_dir = "uploads/proofs"
        os.makedirs(upload_dir, exist_ok=True)
        ext = file.filename.split('.')[-1] if file.filename and '.' in file.filename else ''
        filename = f"{uuid.uuid4()}.{ext}"
        filepath = os.path.join(upload_dir, filename)
        
        with open(filepath, "wb") as buffer:
            shutil.copyfileobj(file.file, buffer)
            
        proof.file_path = f"/{filepath}"

    proof.status = PaymentProofStatus.PENDING_REVIEW
    await db.flush()

    # Notify admins of new payment proof submission
    try:
        from app.models.user import User
        user = (await db.execute(select(User).where(User.id == proof.user_id))).scalar_one_or_none()
        user_name = user.full_name if user else "Unknown Member"
        payment_reason = payment.reason if payment else "Membership Fee"
        payment_amount = str(payment.amount) if payment else "0"
        
        title = "New Payment Proof Submitted"
        body = f"{user_name} submitted a payment proof of LKR {payment_amount} for '{payment_reason}'."
        await notify_admins(
            title=title,
            body=body,
            notification_type="PAYMENT_PROOF_SUBMITTED",
            data={
                "proof_id": str(proof.id),
                "payment_id": str(proof.payment_id),
                "click_action": "/payments"
            }
        )
    except Exception as e:
        import logging
        logging.getLogger(__name__).error(f"Failed to notify admins of payment proof submission: {e}")
    
    return {"message": "Payment proof submitted successfully.", "status": proof.status.value}


async def submit_payment_proof_authenticated(payment_id: UUID, user_id: UUID, proof_type: PaymentProofType, reference_number: str | None, file: UploadFile | None, db: AsyncSession) -> Dict[str, Any]:
    from app.models.payments import Payment, PaymentStatus
    
    stmt = select(PaymentProof).where(PaymentProof.payment_id == payment_id, PaymentProof.user_id == user_id)
    res = await db.execute(stmt)
    proof = res.scalar_one_or_none()
    
    if not proof:
        # Create a payment proof record if one doesn't exist for this payment
        # This handles cases where older payments didn't generate a token automatically
        proof = PaymentProof(
            payment_id=payment_id,
            user_id=user_id,
            upload_token=uuid.uuid4().hex,
            upload_token_expires_at=datetime.now(timezone.utc) + timedelta(days=14)
        )
        db.add(proof)
        await db.flush()
        
    # Check if already paid
    pay_stmt = select(Payment).where(Payment.id == proof.payment_id)
    pay_res = await db.execute(pay_stmt)
    payment = pay_res.scalar_one_or_none()
    if payment and payment.status == PaymentStatus.COMPLETED:
        raise BadRequestException("Payment has already been made and completed.")

    # Check if already uploaded and waiting for review
    if proof.status == PaymentProofStatus.APPROVED:
        raise BadRequestException("This payment proof has already been approved.")
        
    if proof.status == PaymentProofStatus.PENDING_REVIEW and proof.proof_type is not None:
        raise BadRequestException("Payment proof has already been uploaded and is pending review.")
        
    proof.proof_type = proof_type
    proof.reference_number = reference_number
    
    if file:
        upload_dir = "uploads/proofs"
        os.makedirs(upload_dir, exist_ok=True)
        ext = file.filename.split('.')[-1] if file.filename and '.' in file.filename else ''
        filename = f"{uuid.uuid4()}.{ext}"
        filepath = os.path.join(upload_dir, filename)
        
        with open(filepath, "wb") as buffer:
            shutil.copyfileobj(file.file, buffer)
            
        proof.file_path = f"/{filepath}"

    proof.status = PaymentProofStatus.PENDING_REVIEW
    await db.flush()

    # Notify admins
    try:
        from app.models.user import User
        user = (await db.execute(select(User).where(User.id == proof.user_id))).scalar_one_or_none()
        user_name = user.full_name if user else "Unknown Member"
        payment_reason = payment.reason if payment else "Membership Fee"
        payment_amount = str(payment.amount) if payment else "0"
        
        title = "New Payment Proof Submitted"
        body = f"{user_name} submitted a payment proof of LKR {payment_amount} for '{payment_reason}'."
        await notify_admins(
            title=title,
            body=body,
            notification_type="PAYMENT_PROOF_SUBMITTED",
            data={
                "proof_id": str(proof.id),
                "payment_id": str(proof.payment_id),
                "click_action": "/payments"
            }
        )
    except Exception as e:
        import logging
        logging.getLogger(__name__).error(f"Failed to notify admins of payment proof submission: {e}")
    
    return {"message": "Payment proof submitted successfully.", "status": proof.status.value}


async def list_payment_proofs(status: PaymentProofStatus | None, db: AsyncSession) -> List[Dict[str, Any]]:
    from app.models.user import User
    stmt = (
        select(PaymentProof, Payment, User)
        .join(Payment, Payment.id == PaymentProof.payment_id)
        .join(User, User.id == PaymentProof.user_id)
        .order_by(desc(PaymentProof.created_at))
    )
    if status:
        stmt = stmt.where(PaymentProof.status == status)
        
    res = await db.execute(stmt)
    results = []
    for proof, payment, user in res.all():
        results.append({
            "id": str(proof.id),
            "payment_id": str(payment.id),
            "user_id": str(user.id),
            "user_name": user.full_name,
            "user_phone": user.phone_number,
            "payment_reason": payment.reason,
            "payment_amount": str(payment.amount),
            "proof_type": proof.proof_type.value if proof.proof_type else None,
            "file_path": proof.file_path,
            "reference_number": proof.reference_number,
            "status": proof.status.value,
            "admin_notes": proof.admin_notes,
            "created_at": proof.created_at.isoformat(),
        })
    return results


async def approve_payment_proof(proof_id: UUID, current_user: Any, notes: str | None, db: AsyncSession) -> Dict[str, Any]:
    stmt = select(PaymentProof).where(PaymentProof.id == proof_id)
    res = await db.execute(stmt)
    proof = res.scalar_one_or_none()
    
    if not proof:
        raise NotFoundException("Payment proof not found.")
        
    if proof.status == PaymentProofStatus.APPROVED:
        raise BadRequestException("Payment proof is already approved.")
        
    proof.status = PaymentProofStatus.APPROVED
    proof.admin_notes = notes
    proof.reviewed_by_id = current_user.id
    proof.reviewed_at = datetime.now(timezone.utc)
    
    # Update payment to completed
    pay_stmt = select(Payment).where(Payment.id == proof.payment_id)
    pay_res = await db.execute(pay_stmt)
    payment = pay_res.scalar_one_or_none()
    
    if payment and payment.status != PaymentStatus.COMPLETED:
        payment.status = PaymentStatus.COMPLETED
        await _apply_payment_side_effects(payment, db)
        
    await db.flush()
    return {"message": "Payment proof approved successfully."}


async def reject_payment_proof(proof_id: UUID, current_user: Any, notes: str | None, db: AsyncSession) -> Dict[str, Any]:
    stmt = select(PaymentProof).where(PaymentProof.id == proof_id)
    res = await db.execute(stmt)
    proof = res.scalar_one_or_none()
    
    if not proof:
        raise NotFoundException("Payment proof not found.")
        
    proof.status = PaymentProofStatus.REJECTED
    proof.admin_notes = notes
    proof.reviewed_by_id = current_user.id
    proof.reviewed_at = datetime.now(timezone.utc)
    
    await db.flush()
    return {"message": "Payment proof rejected successfully."}
