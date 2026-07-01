"""
Prime Business Network – Payments Router.
"""

from __future__ import annotations

from typing import Optional
from uuid import UUID

from fastapi import APIRouter, Depends, Query, File, UploadFile, Form
from fastapi.responses import ORJSONResponse, RedirectResponse
from sqlalchemy.ext.asyncio import AsyncSession

from app.core.config import get_settings
from app.core.dependencies import get_db
from app.core.response import success_response, error_response
from app.features.auth.dependencies import get_current_user, require_role
from app.features.payments.schemas import (
    PaymentInitiate, SimulateWebhook, PaymentCreateAdmin, PaymentUpdateAdmin,
    PaymentProofUpload, PaymentProofReview, PaymentProofResponse
)
from app.features.payments import service
from app.models.payment_proofs import PaymentProofStatus
from app.models.user import User, UserRole

router = APIRouter(tags=["Payments"])

member_req = require_role([UserRole.MEMBER, UserRole.CHAPTER_ADMIN, UserRole.SUPER_ADMIN, UserRole.ADMIN])


@router.post("/payments/initiate", summary="Initiate a payment", status_code=201)
async def initiate_payment_endpoint(
    data: PaymentInitiate,
    current_user: User = Depends(get_current_user),
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


@router.get("/payments/bancstac/return", summary="Bancstac return callback")
async def bancstac_return_endpoint(
    reqid_upper: Optional[str] = Query(None, alias="ReqID"),
    reqid_lower: Optional[str] = Query(None, alias="reqid"),
    source: Optional[str] = Query(None),
    db: AsyncSession = Depends(get_db),
) -> RedirectResponse:
    reqid = reqid_upper or reqid_lower
    settings = get_settings()
    if not reqid:
        return RedirectResponse(url=f"{settings.PUBLIC_SITE_URL}/payment-cancelled.html?error=missing_reqid")

    try:
        payment_details = await service.complete_bancstac_payment(reqid, db)
        is_success = payment_details.get("status") == "completed"
    except Exception:
        is_success = False

    if source == "portal":
        base_redirect_url = "https://portal.primebusiness.network"
        if is_success:
            return RedirectResponse(url=f"{base_redirect_url}/payment-success")
        else:
            return RedirectResponse(url=f"{base_redirect_url}/payment-cancelled")
    else:
        if is_success:
            return RedirectResponse(url=f"{settings.PUBLIC_SITE_URL}/payment-success.html?req_id={reqid}")
        else:
            return RedirectResponse(url=f"{settings.PUBLIC_SITE_URL}/payment-cancelled.html?req_id={reqid}")



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
    current_user: User = Depends(get_current_user),
    db: AsyncSession = Depends(get_db),
) -> ORJSONResponse:
    payments = await service.get_my_payments(current_user.id, db)
    return success_response(data=payments)


@router.get("/payments/{payment_id}/status", summary="Get payment status")
async def payment_status_endpoint(
    payment_id: UUID,
    current_user: User = Depends(get_current_user),
    db: AsyncSession = Depends(get_db),
) -> ORJSONResponse:
    is_admin = current_user.role in (UserRole.CHAPTER_ADMIN, UserRole.SUPER_ADMIN, UserRole.ADMIN)
    result = await service.get_payment_status(payment_id, current_user.id, is_admin, db)
    return success_response(data=result)


@router.get("/admin/payments", summary="Admin: list all payments")
async def admin_payments_endpoint(
    status: Optional[str] = Query(None),
    payment_type: Optional[str] = Query(None),
    current_user: User = Depends(require_role([UserRole.SUPER_ADMIN, UserRole.ADMIN, UserRole.CHAPTER_ADMIN])),
    db: AsyncSession = Depends(get_db),
) -> ORJSONResponse:
    payments = await service.list_all_payments(status, payment_type, db)
    return success_response(data=payments)


@router.post("/admin/payments", summary="Admin: record manual payment", status_code=201)
async def admin_record_payment_endpoint(
    data: PaymentCreateAdmin,
    current_user: User = Depends(require_role([UserRole.SUPER_ADMIN, UserRole.ADMIN, UserRole.CHAPTER_ADMIN])),
    db: AsyncSession = Depends(get_db),
) -> ORJSONResponse:
    result = await service.record_manual_payment(current_user.id, data, db)
    return success_response(data=service._serialize_payment(result), message="Manual payment recorded", status_code=201)


@router.patch("/admin/payments/{payment_id}", summary="Admin: update payment details")
async def admin_update_payment_endpoint(
    payment_id: UUID,
    data: PaymentUpdateAdmin,
    current_user: User = Depends(require_role([UserRole.SUPER_ADMIN, UserRole.ADMIN, UserRole.CHAPTER_ADMIN])),
    db: AsyncSession = Depends(get_db),
) -> ORJSONResponse:
    result = await service.update_payment(payment_id, current_user.id, data, db)
    return success_response(data=service._serialize_payment(result), message="Payment updated successfully")


# ── Payment Proofs (Public & Admin) ──────────────────────────────────────────

@router.get("/payments/proof/{token}", summary="Get payment proof upload status (Public)")
async def get_payment_proof_status_endpoint(
    token: str,
    db: AsyncSession = Depends(get_db),
) -> ORJSONResponse:
    result = await service.get_proof_upload_status(token, db)
    return success_response(data=result)


@router.post("/payments/proof/{token}/upload", summary="Upload payment proof (Public)")
async def upload_payment_proof_endpoint(
    token: str,
    proof_type: str = Form(...),
    reference_number: Optional[str] = Form(None),
    file: Optional[UploadFile] = File(None),
    db: AsyncSession = Depends(get_db),
) -> ORJSONResponse:
    from app.models.payment_proofs import PaymentProofType
    result = await service.submit_payment_proof(
        token,
        PaymentProofType(proof_type.lower()),
        reference_number,
        file,
        db
    )
    return success_response(data=result)


@router.post("/payments/proof/{token}/pay-online", summary="Initiate online card payment for proof token (Public)")
async def initiate_online_payment_by_token_endpoint(
    token: str,
    db: AsyncSession = Depends(get_db),
) -> ORJSONResponse:
    result = await service.initiate_online_payment_by_token(token, db)
    return success_response(data=result, message="Online payment initiated")



@router.post("/payments/{payment_id}/proof", summary="Upload payment proof (Authenticated)")
async def upload_payment_proof_authenticated_endpoint(
    payment_id: UUID,
    proof_type: str = Form(...),
    reference_number: Optional[str] = Form(None),
    file: Optional[UploadFile] = File(None),
    current_user: User = Depends(get_current_user),
    db: AsyncSession = Depends(get_db),
) -> ORJSONResponse:
    from app.models.payment_proofs import PaymentProofType
    result = await service.submit_payment_proof_authenticated(
        payment_id,
        current_user.id,
        PaymentProofType(proof_type.lower()),
        reference_number,
        file,
        db
    )
    return success_response(data=result)


@router.get("/admin/payment-proofs", summary="Admin: list payment proofs")
async def admin_list_payment_proofs_endpoint(
    status: Optional[PaymentProofStatus] = Query(None),
    current_user: User = Depends(require_role([UserRole.SUPER_ADMIN, UserRole.ADMIN])),
    db: AsyncSession = Depends(get_db),
) -> ORJSONResponse:
    proofs = await service.list_payment_proofs(status, db)
    return success_response(data=proofs)


@router.post("/admin/payment-proofs/{proof_id}/approve", summary="Admin: approve payment proof")
async def admin_approve_payment_proof_endpoint(
    proof_id: UUID,
    data: PaymentProofReview,
    current_user: User = Depends(require_role([UserRole.SUPER_ADMIN, UserRole.ADMIN])),
    db: AsyncSession = Depends(get_db),
) -> ORJSONResponse:
    result = await service.approve_payment_proof(proof_id, current_user, data.notes, db)
    return success_response(data=result)


@router.post("/admin/payment-proofs/{proof_id}/reject", summary="Admin: reject payment proof")
async def admin_reject_payment_proof_endpoint(
    proof_id: UUID,
    data: PaymentProofReview,
    current_user: User = Depends(require_role([UserRole.SUPER_ADMIN, UserRole.ADMIN])),
    db: AsyncSession = Depends(get_db),
) -> ORJSONResponse:
    result = await service.reject_payment_proof(proof_id, current_user, data.notes, db)
    return success_response(data=result)
