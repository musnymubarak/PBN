"""
Prime Business Network – Payments Router.
"""

from __future__ import annotations

from typing import Optional
from uuid import UUID

from fastapi import APIRouter, Depends, Query
from fastapi.responses import ORJSONResponse
from sqlalchemy.ext.asyncio import AsyncSession

from app.core.config import get_settings
from app.core.dependencies import get_db
from app.core.response import success_response, error_response
from app.features.auth.dependencies import get_current_user, require_role
from app.features.payments.schemas import PaymentInitiate, SimulateWebhook, PaymentCreateAdmin, PaymentUpdateAdmin
from app.features.payments import service
from app.models.user import User, UserRole

router = APIRouter(tags=["Payments"])

member_req = require_role([UserRole.MEMBER, UserRole.CHAPTER_ADMIN, UserRole.SUPER_ADMIN])


@router.post("/payments/initiate", summary="Initiate a payment", status_code=201)
async def initiate_payment_endpoint(
    data: PaymentInitiate,
    current_user: User = Depends(member_req),
    db: AsyncSession = Depends(get_db),
) -> ORJSONResponse:
    result = await service.initiate_payment(
        user_id=current_user.id,
        payment_type=data.payment_type,
        amount=data.amount,
        event_id=data.event_id,
        db=db,
    )
    return success_response(data=result, message="Payment initiated", status_code=201)


@router.post("/payments/webhook", summary="WebxPay webhook callback")
async def webhook_endpoint(
    payload: dict,
    db: AsyncSession = Depends(get_db),
) -> ORJSONResponse:
    result = await service.process_webhook(payload, db)
    return success_response(data=result)


@router.post("/payments/simulate-webhook", summary="Simulate successful payment (dev only)")
async def simulate_webhook_endpoint(
    data: SimulateWebhook,
    db: AsyncSession = Depends(get_db),
) -> ORJSONResponse:
    settings = get_settings()
    if settings.ENVIRONMENT == "production":
        return error_response(
            message="Simulation not available in production",
            code="NOT_AVAILABLE",
            status_code=403,
        )
    result = await service.simulate_webhook(data.payment_id, db)
    return success_response(data=result, message="Payment simulated successfully")


@router.get("/payments/my", summary="My payment history")
async def my_payments_endpoint(
    current_user: User = Depends(member_req),
    db: AsyncSession = Depends(get_db),
) -> ORJSONResponse:
    payments = await service.get_my_payments(current_user.id, db)
    return success_response(data=payments)


@router.get("/payments/{payment_id}/status", summary="Get payment status")
async def payment_status_endpoint(
    payment_id: UUID,
    current_user: User = Depends(member_req),
    db: AsyncSession = Depends(get_db),
) -> ORJSONResponse:
    is_admin = current_user.role in (UserRole.CHAPTER_ADMIN, UserRole.SUPER_ADMIN)
    result = await service.get_payment_status(payment_id, current_user.id, is_admin, db)
    return success_response(data=result)


@router.get("/admin/payments", summary="Admin: list all payments")
async def admin_payments_endpoint(
    status: Optional[str] = Query(None),
    payment_type: Optional[str] = Query(None),
    current_user: User = Depends(require_role([UserRole.SUPER_ADMIN, UserRole.CHAPTER_ADMIN])),
    db: AsyncSession = Depends(get_db),
) -> ORJSONResponse:
    payments = await service.list_all_payments(status, payment_type, db)
    return success_response(data=payments)


@router.post("/admin/payments", summary="Admin: record manual payment", status_code=201)
async def admin_record_payment_endpoint(
    data: PaymentCreateAdmin,
    current_user: User = Depends(require_role([UserRole.SUPER_ADMIN, UserRole.CHAPTER_ADMIN])),
    db: AsyncSession = Depends(get_db),
) -> ORJSONResponse:
    result = await service.record_manual_payment(current_user.id, data, db)
    return success_response(data=service._serialize_payment(result), message="Manual payment recorded", status_code=201)


@router.patch("/admin/payments/{payment_id}", summary="Admin: update payment details")
async def admin_update_payment_endpoint(
    payment_id: UUID,
    data: PaymentUpdateAdmin,
    current_user: User = Depends(require_role([UserRole.SUPER_ADMIN, UserRole.CHAPTER_ADMIN])),
    db: AsyncSession = Depends(get_db),
) -> ORJSONResponse:
    result = await service.update_payment(payment_id, current_user.id, data, db)
    return success_response(data=service._serialize_payment(result), message="Payment updated successfully")
