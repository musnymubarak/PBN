"""add complement_types + member_complements

Introduces a complements ledger so the post-approval onboarding T-shirt size
is tracked as a fulfilment record (not just a frozen application field), and
so future add-ons (lapel pins, certificates, gift boxes…) can be tracked the
same way without schema changes.

  complement_types       — catalogue (e.g. founders_tshirt with size variants)
  member_complements     — per-member ledger (variant + fulfilment_status)

Also seeds the founders_tshirt complement type and backfills any existing
approved+onboarded applications so they appear in the ledger immediately.

`applications.tshirt_size` is intentionally NOT dropped — kept as a frozen
historical record of what the applicant first picked.

Revision ID: c9f3e1a7b5d2
Revises: b7c4a9f1e2d8
"""
from typing import Sequence, Union

import sqlalchemy as sa
from alembic import op
from sqlalchemy.dialects import postgresql


revision: str = "c9f3e1a7b5d2"
down_revision: Union[str, None] = "b7c4a9f1e2d8"
branch_labels: Union[str, Sequence[str], None] = None
depends_on: Union[str, Sequence[str], None] = None


fulfilment_status_enum = postgresql.ENUM(
    "pending", "in_progress", "shipped", "delivered", "cancelled",
    name="complement_fulfilment_status",
    create_type=False,
)


def upgrade() -> None:
    bind = op.get_bind()
    fulfilment_status_enum.create(bind, checkfirst=True)

    op.create_table(
        "complement_types",
        sa.Column("id", postgresql.UUID(as_uuid=True), primary_key=True, server_default=sa.text("gen_random_uuid()")),
        sa.Column("code", sa.String(length=50), nullable=False, unique=True),
        sa.Column("name", sa.String(length=150), nullable=False),
        sa.Column("description", sa.Text(), nullable=True),
        sa.Column("variants", postgresql.JSONB(astext_type=sa.Text()), nullable=True),
        sa.Column("is_active", sa.Boolean(), nullable=False, server_default=sa.text("true")),
        sa.Column("created_at", sa.DateTime(timezone=True), nullable=False, server_default=sa.text("now()")),
        sa.Column("updated_at", sa.DateTime(timezone=True), nullable=False, server_default=sa.text("now()")),
    )

    op.create_table(
        "member_complements",
        sa.Column("id", postgresql.UUID(as_uuid=True), primary_key=True, server_default=sa.text("gen_random_uuid()")),
        sa.Column("user_id", postgresql.UUID(as_uuid=True), sa.ForeignKey("users.id", ondelete="CASCADE"), nullable=False, index=True),
        sa.Column("complement_type_id", postgresql.UUID(as_uuid=True), sa.ForeignKey("complement_types.id", ondelete="RESTRICT"), nullable=False, index=True),
        sa.Column("variant", sa.String(length=50), nullable=True),
        sa.Column(
            "fulfilment_status",
            # Reuse the same enum-type object created above so SQLAlchemy doesn't
            # try to re-create the Postgres type during table creation.
            fulfilment_status_enum,
            nullable=False, server_default="pending",
        ),
        sa.Column("assigned_at", sa.DateTime(timezone=True), nullable=False, server_default=sa.text("now()")),
        sa.Column("fulfilled_at", sa.DateTime(timezone=True), nullable=True),
        sa.Column("fulfilled_by", postgresql.UUID(as_uuid=True), sa.ForeignKey("users.id", ondelete="SET NULL"), nullable=True),
        sa.Column("notes", sa.Text(), nullable=True),
        sa.Column("created_at", sa.DateTime(timezone=True), nullable=False, server_default=sa.text("now()")),
        sa.Column("updated_at", sa.DateTime(timezone=True), nullable=False, server_default=sa.text("now()")),
        sa.UniqueConstraint("user_id", "complement_type_id", name="uq_member_complements_user_type"),
    )

    # ── Seed: founders_tshirt ───────────────────────────────────────────────
    op.execute(sa.text("""
        INSERT INTO complement_types (code, name, description, variants, is_active)
        VALUES (
            'founders_tshirt',
            'Founder''s T-shirt',
            'PBN founding-member T-shirt issued on onboarding.',
            '["S","M","L","XL","XXL","XXXL"]'::jsonb,
            true
        )
        ON CONFLICT (code) DO NOTHING
    """))

    # ── Backfill from existing onboarded applications ──────────────────────
    # Match the application to a user via phone_number; if the user has already
    # got a row for this complement type, do nothing (idempotent).
    op.execute(sa.text("""
        INSERT INTO member_complements (
            user_id, complement_type_id, variant, fulfilment_status, assigned_at
        )
        SELECT
            u.id,
            ct.id,
            a.tshirt_size::text,
            'pending'::complement_fulfilment_status,
            COALESCE(a.onboarding_completed_at, now())
        FROM applications a
        JOIN users u ON u.phone_number = a.contact_number
        JOIN complement_types ct ON ct.code = 'founders_tshirt'
        WHERE a.tshirt_size IS NOT NULL
          AND a.onboarding_completed_at IS NOT NULL
        ON CONFLICT ON CONSTRAINT uq_member_complements_user_type DO NOTHING
    """))


def downgrade() -> None:
    op.drop_table("member_complements")
    op.drop_table("complement_types")
    bind = op.get_bind()
    fulfilment_status_enum.drop(bind, checkfirst=True)
