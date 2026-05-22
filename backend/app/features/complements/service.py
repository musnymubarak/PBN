"""Service layer for Complements admin operations."""

from __future__ import annotations

from datetime import datetime, timezone
from typing import Any, Dict, Optional
from uuid import UUID

from sqlalchemy import desc, func, select
from sqlalchemy.ext.asyncio import AsyncSession

from app.core.exceptions import BadRequestException, NotFoundException
from app.models.audit_logs import AuditLog
from app.models.chapters import Chapter
from app.models.complements import ComplementType, FulfilmentStatus, MemberComplement
from app.models.memberships import ChapterMembership
from app.models.user import User


def _serialize(c: MemberComplement, user: User | None, ctype: ComplementType, chapter_name: str | None) -> Dict[str, Any]:
    return {
        "id": str(c.id),
        "user_id": str(c.user_id),
        "user_full_name": user.full_name if user else None,
        "user_phone_number": user.phone_number if user else None,
        "chapter_name": chapter_name,
        "complement_type_id": str(c.complement_type_id),
        "complement_type_code": ctype.code,
        "complement_type_name": ctype.name,
        "variant": c.variant,
        "fulfilment_status": c.fulfilment_status.value,
        "assigned_at": c.assigned_at.isoformat() if c.assigned_at else None,
        "fulfilled_at": c.fulfilled_at.isoformat() if c.fulfilled_at else None,
        "fulfilled_by": str(c.fulfilled_by) if c.fulfilled_by else None,
        "notes": c.notes,
        "updated_at": c.updated_at.isoformat() if c.updated_at else None,
    }


async def list_complements(
    db: AsyncSession,
    *,
    type_code: Optional[str] = None,
    status: Optional[FulfilmentStatus] = None,
    chapter_id: Optional[UUID] = None,
    search: Optional[str] = None,
    page: int = 1,
    page_size: int = 25,
) -> Dict[str, Any]:
    """Paginated list with optional filters. Joins user / chapter / type."""
    stmt = (
        select(MemberComplement, User, ComplementType, Chapter.name.label("chapter_name"))
        .join(User, MemberComplement.user_id == User.id)
        .join(ComplementType, MemberComplement.complement_type_id == ComplementType.id)
        .outerjoin(
            ChapterMembership,
            (ChapterMembership.user_id == User.id) & (ChapterMembership.is_active.is_(True)),
        )
        .outerjoin(Chapter, ChapterMembership.chapter_id == Chapter.id)
        .order_by(desc(MemberComplement.updated_at))
    )

    if type_code:
        stmt = stmt.where(ComplementType.code == type_code)
    if status:
        stmt = stmt.where(MemberComplement.fulfilment_status == status)
    if chapter_id:
        stmt = stmt.where(Chapter.id == chapter_id)
    if search:
        pattern = f"%{search}%"
        stmt = stmt.where(
            User.full_name.ilike(pattern)
            | User.phone_number.ilike(pattern)
            | User.email.ilike(pattern)
            | MemberComplement.notes.ilike(pattern)
        )

    count_stmt = select(func.count()).select_from(stmt.subquery())
    total = (await db.execute(count_stmt)).scalar_one()

    stmt = stmt.offset((page - 1) * page_size).limit(page_size)
    rows = (await db.execute(stmt)).all()

    items = [_serialize(c, u, t, ch) for (c, u, t, ch) in rows]

    return {"items": items, "total": total, "page": page, "page_size": page_size}


async def update_status(
    complement_id: UUID,
    new_status: FulfilmentStatus,
    notes: Optional[str],
    actor: User,
    db: AsyncSession,
) -> Dict[str, Any]:
    row = (await db.execute(
        select(MemberComplement).where(MemberComplement.id == complement_id)
    )).scalar_one_or_none()
    if not row:
        raise NotFoundException("Complement record not found")

    old_status = row.fulfilment_status
    row.fulfilment_status = new_status

    # Track delivery
    if new_status == FulfilmentStatus.DELIVERED and not row.fulfilled_at:
        row.fulfilled_at = datetime.now(timezone.utc)
        row.fulfilled_by = actor.id
    if new_status != FulfilmentStatus.DELIVERED:
        # Going back to a non-delivered status — clear the fulfilment stamp.
        row.fulfilled_at = None
        row.fulfilled_by = None

    if notes is not None:
        row.notes = notes

    db.add(AuditLog(
        actor_id=actor.id,
        entity_type="member_complement",
        entity_id=row.id,
        action="status_update",
        old_value={"fulfilment_status": old_status.value},
        new_value={"fulfilment_status": new_status.value, "notes": row.notes},
    ))

    await db.commit()
    await db.refresh(row)

    # Refetch joined data for the response payload.
    bundle = await list_complements(db, page=1, page_size=1, search=None)
    # Cheaper: fetch by id explicitly.
    out_row = (await db.execute(
        select(MemberComplement, User, ComplementType, Chapter.name.label("chapter_name"))
        .join(User, MemberComplement.user_id == User.id)
        .join(ComplementType, MemberComplement.complement_type_id == ComplementType.id)
        .outerjoin(
            ChapterMembership,
            (ChapterMembership.user_id == User.id) & (ChapterMembership.is_active.is_(True)),
        )
        .outerjoin(Chapter, ChapterMembership.chapter_id == Chapter.id)
        .where(MemberComplement.id == row.id)
    )).first()
    c, u, t, ch = out_row
    return _serialize(c, u, t, ch)


async def list_types(db: AsyncSession, *, active_only: bool = True) -> list[Dict[str, Any]]:
    stmt = select(ComplementType).order_by(ComplementType.name)
    if active_only:
        stmt = stmt.where(ComplementType.is_active.is_(True))
    rows = (await db.execute(stmt)).scalars().all()
    return [
        {
            "id": str(t.id),
            "code": t.code,
            "name": t.name,
            "description": t.description,
            "variants": t.variants,
            "is_active": t.is_active,
        }
        for t in rows
    ]


async def create_type(
    code: str,
    name: str,
    description: Optional[str],
    variants: Optional[list],
    is_active: bool,
    actor: User,
    db: AsyncSession,
) -> Dict[str, Any]:
    existing = (await db.execute(
        select(ComplementType).where(ComplementType.code == code)
    )).scalar_one_or_none()
    if existing:
        raise BadRequestException(f"A complement type with code '{code}' already exists.")

    t = ComplementType(
        code=code, name=name, description=description, variants=variants, is_active=is_active
    )
    db.add(t)
    db.add(AuditLog(
        actor_id=actor.id,
        entity_type="complement_type",
        entity_id=None,
        action="create",
        new_value={"code": code, "name": name},
    ))
    await db.commit()
    await db.refresh(t)
    return {
        "id": str(t.id),
        "code": t.code,
        "name": t.name,
        "description": t.description,
        "variants": t.variants,
        "is_active": t.is_active,
    }


async def assign_complement(
    user_id: UUID,
    type_code: str,
    variant: Optional[str],
    db: AsyncSession,
    *,
    notes: Optional[str] = None,
) -> Dict[str, Any]:
    """Upsert a complement assignment for a member. Used by onboarding wizard
    and admin-side manual assignment. Idempotent on (user_id, type)."""
    ctype = (await db.execute(
        select(ComplementType).where(ComplementType.code == type_code)
    )).scalar_one_or_none()
    if not ctype:
        raise NotFoundException(f"Complement type '{type_code}' is not configured.")

    existing = (await db.execute(
        select(MemberComplement).where(
            MemberComplement.user_id == user_id,
            MemberComplement.complement_type_id == ctype.id,
        )
    )).scalar_one_or_none()

    if existing:
        # Allow the member to change their pick while still pending.
        if existing.fulfilment_status == FulfilmentStatus.PENDING:
            existing.variant = variant
            if notes is not None:
                existing.notes = notes
            await db.commit()
            await db.refresh(existing)
            return {"id": str(existing.id), "updated": True}
        # Already in-progress/shipped/delivered — leave as-is.
        return {"id": str(existing.id), "updated": False}

    row = MemberComplement(
        user_id=user_id,
        complement_type_id=ctype.id,
        variant=variant,
        fulfilment_status=FulfilmentStatus.PENDING,
        notes=notes,
    )
    db.add(row)
    await db.commit()
    await db.refresh(row)
    return {"id": str(row.id), "updated": False}
