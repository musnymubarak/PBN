"""
Prime Business Network – Referrals API Service.
"""

from __future__ import annotations

from typing import Any, Dict, List
from uuid import UUID

from sqlalchemy import select
from sqlalchemy.ext.asyncio import AsyncSession
from sqlalchemy.orm import selectinload, joinedload

from app.core.exceptions import BadRequestException, NotFoundException, ForbiddenException
from app.features.referrals.schemas import ReferralCreate, ReferralStatusUpdate
from app.models.referrals import Referral, ReferralStatus, ReferralStatusHistory
from app.models.user import User


async def _serialize_referral(ref: Referral) -> Dict[str, Any]:
    """Helper to convert ORM model to dictionary with nested users and history."""
    return {
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
                "created_at": h.created_at.isoformat() if h.created_at else None
            }
            for h in ref.history
        ]
    }


async def create_referral(data: ReferralCreate, actor_id: UUID, db: AsyncSession) -> Dict[str, Any]:
    if data.target_user_id == actor_id:
        raise BadRequestException("You cannot refer yourself", code="SELF_REFERRAL")

    # Verify target user exists and is active
    stmt = select(User).where(User.id == data.target_user_id, User.is_active.is_(True))
    target = (await db.execute(stmt)).scalar_one_or_none()
    if not target:
        raise BadRequestException("Target user is not active or does not exist", code="INVALID_TARGET")

    referral = Referral(
        from_member_id=actor_id,
        to_member_id=data.target_user_id,
        client_name=data.lead_name,
        client_phone=data.lead_contact,
        client_email=data.lead_email,
        description=data.description,
        status=ReferralStatus.SUBMITTED,
    )
    db.add(referral)
    await db.flush()

    history = ReferralStatusHistory(
        referral_id=referral.id,
        old_status="",
        new_status=ReferralStatus.SUBMITTED.value,
        notes="Referral created",
        changed_by=actor_id
    )
    db.add(history)
    await db.flush()
    
    # Reload with relationships
    ref_stmt = (
        select(Referral)
        .options(
            joinedload(Referral.from_member),
            joinedload(Referral.to_member),
            selectinload(Referral.history)
        )
        .where(Referral.id == referral.id)
    )
    loaded_ref = (await db.execute(ref_stmt)).scalar_one()

    return await _serialize_referral(loaded_ref)


async def get_my_given_referrals(actor_id: UUID, db: AsyncSession) -> List[Dict[str, Any]]:
    stmt = (
        select(Referral)
        .options(
            joinedload(Referral.from_member),
            joinedload(Referral.to_member),
            selectinload(Referral.history)
        )
        .where(Referral.from_member_id == actor_id)
        .order_by(Referral.created_at.desc())
    )
    result = await db.execute(stmt)
    referrals = result.scalars().all()
    
    return [await _serialize_referral(r) for r in referrals]


async def get_my_received_referrals(actor_id: UUID, db: AsyncSession) -> List[Dict[str, Any]]:
    stmt = (
        select(Referral)
        .options(
            joinedload(Referral.from_member),
            joinedload(Referral.to_member),
            selectinload(Referral.history)
        )
        .where(Referral.to_member_id == actor_id)
        .order_by(Referral.created_at.desc())
    )
    result = await db.execute(stmt)
    referrals = result.scalars().all()
    
    return [await _serialize_referral(r) for r in referrals]


async def update_referral_status(ref_id: UUID, data: ReferralStatusUpdate, actor_id: UUID, db: AsyncSession) -> Dict[str, Any]:
    stmt = (
        select(Referral)
        .options(
            joinedload(Referral.from_member),
            joinedload(Referral.to_member),
            selectinload(Referral.history)
        )
        .where(Referral.id == ref_id)
    )
    ref = (await db.execute(stmt)).scalar_one_or_none()
    
    if not ref:
        raise NotFoundException("Referral not found")
        
    # Only the target user (the one who received it) is allowed to change the status
    if ref.to_member_id != actor_id:
        raise ForbiddenException("Only the recipient of the referral can update the status")
        
    if ref.status == data.status:
        raise BadRequestException("Referral is already in this status")
        
    old_status = ref.status.value
    ref.status = data.status
    if data.actual_value is not None:
        ref.actual_value = data.actual_value
    
    history = ReferralStatusHistory(
        referral_id=ref.id,
        old_status=old_status,
        new_status=data.status.value,
        notes=data.description or f"Status updated to {data.status.value}",
        changed_by=actor_id
    )
    db.add(history)
    await db.flush()
    
    # Reload history because we just added one, but the object in memory might not have it unless we append to collection or refresh
    await db.refresh(ref, ['history'])

    return await _serialize_referral(ref)
