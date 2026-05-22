"""extend applications: tier-1 profile fields, onboarding token, t-shirt size

Adds:
  - tier-1 profile fields (designation, decision_authority, years_in_operation,
    business_legal_type, business_registration_number, website_url, linkedin_url,
    referred_by_user_id, what_you_offer, what_you_seek)
  - tshirt_size (captured during onboarding, not on apply)
  - onboarding_token, onboarding_token_expires_at, onboarding_completed_at

All new columns are nullable so legacy applications remain valid. The frontend
public form will enforce required-ness for the new tier-1 fields (except BR).

Revision ID: b7c4a9f1e2d8
Revises: d8e7f6a4b2c1
"""
from typing import Sequence, Union

import sqlalchemy as sa
from alembic import op
from sqlalchemy.dialects import postgresql


revision: str = "b7c4a9f1e2d8"
down_revision: Union[str, None] = "d8e7f6a4b2c1"
branch_labels: Union[str, Sequence[str], None] = None
depends_on: Union[str, Sequence[str], None] = None


decision_authority_enum = postgresql.ENUM(
    "sole", "shared", "influencer",
    name="decision_authority",
    create_type=False,
)
business_legal_type_enum = postgresql.ENUM(
    "sole_proprietorship", "partnership", "pvt_ltd", "plc", "ngo", "other",
    name="business_legal_type",
    create_type=False,
)
tshirt_size_enum = postgresql.ENUM(
    "S", "M", "L", "XL", "XXL", "XXXL",
    name="tshirt_size",
    create_type=False,
)


def upgrade() -> None:
    bind = op.get_bind()
    decision_authority_enum.create(bind, checkfirst=True)
    business_legal_type_enum.create(bind, checkfirst=True)
    tshirt_size_enum.create(bind, checkfirst=True)

    op.add_column("applications", sa.Column("designation", sa.String(length=100), nullable=True))
    op.add_column("applications", sa.Column(
        "decision_authority",
        sa.Enum("sole", "shared", "influencer", name="decision_authority", create_type=False),
        nullable=True,
    ))
    op.add_column("applications", sa.Column("years_in_operation", sa.String(length=20), nullable=True))
    op.add_column("applications", sa.Column(
        "business_legal_type",
        sa.Enum(
            "sole_proprietorship", "partnership", "pvt_ltd", "plc", "ngo", "other",
            name="business_legal_type", create_type=False,
        ),
        nullable=True,
    ))
    op.add_column("applications", sa.Column("business_registration_number", sa.String(length=50), nullable=True))
    op.add_column("applications", sa.Column("website_url", sa.String(length=500), nullable=True))
    op.add_column("applications", sa.Column("linkedin_url", sa.String(length=500), nullable=True))
    op.add_column("applications", sa.Column(
        "referred_by_user_id",
        postgresql.UUID(as_uuid=True),
        sa.ForeignKey("users.id", ondelete="SET NULL"),
        nullable=True,
    ))
    op.add_column("applications", sa.Column("what_you_offer", sa.String(length=280), nullable=True))
    op.add_column("applications", sa.Column("what_you_seek", sa.String(length=280), nullable=True))

    op.add_column("applications", sa.Column(
        "tshirt_size",
        sa.Enum("S", "M", "L", "XL", "XXL", "XXXL", name="tshirt_size", create_type=False),
        nullable=True,
    ))

    op.add_column("applications", sa.Column("onboarding_token", sa.String(length=64), nullable=True))
    op.add_column("applications", sa.Column("onboarding_token_expires_at", sa.DateTime(timezone=True), nullable=True))
    op.add_column("applications", sa.Column("onboarding_completed_at", sa.DateTime(timezone=True), nullable=True))

    op.create_index("ix_applications_onboarding_token", "applications", ["onboarding_token"], unique=True)
    op.create_index("ix_applications_referred_by", "applications", ["referred_by_user_id"])


def downgrade() -> None:
    op.drop_index("ix_applications_referred_by", table_name="applications")
    op.drop_index("ix_applications_onboarding_token", table_name="applications")

    for col in (
        "onboarding_completed_at",
        "onboarding_token_expires_at",
        "onboarding_token",
        "tshirt_size",
        "what_you_seek",
        "what_you_offer",
        "referred_by_user_id",
        "linkedin_url",
        "website_url",
        "business_registration_number",
        "business_legal_type",
        "years_in_operation",
        "decision_authority",
        "designation",
    ):
        op.drop_column("applications", col)

    bind = op.get_bind()
    tshirt_size_enum.drop(bind, checkfirst=True)
    business_legal_type_enum.drop(bind, checkfirst=True)
    decision_authority_enum.drop(bind, checkfirst=True)
