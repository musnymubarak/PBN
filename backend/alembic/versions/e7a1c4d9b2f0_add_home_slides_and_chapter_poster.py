"""add home_slides table + chapters.poster_url

Introduces the dynamic home carousel so admins can change the home slides
(content, order, schedule, audience) from the admin panel without shipping a
new mobile build, plus a poster image for chapters.  See
docs/dynamic-home-content-plan.md.

  home_slides           — carousel slides (custom + auto-event types)
  chapters.poster_url   — chapter banner/hero image

Seeds the three slides the app currently hardcodes so the home screen looks
identical immediately after migrating.

Revision ID: e7a1c4d9b2f0
Revises: c9f3e1a7b5d2
Create Date: 2026-06-08
"""

from typing import Sequence, Union

import sqlalchemy as sa
from alembic import op
from sqlalchemy.dialects import postgresql


revision: str = "e7a1c4d9b2f0"
down_revision: Union[str, None] = "c9f3e1a7b5d2"
branch_labels: Union[str, Sequence[str], None] = None
depends_on: Union[str, Sequence[str], None] = None


# Enum labels are the lowercase string values (matching the model's
# values_callable) so DB, seed, API and clients all agree.
slide_type_enum = postgresql.ENUM(
    "custom", "next_virtual_event", "next_physical_event",
    name="home_slide_type",
    create_type=False,
)
cta_action_enum = postgresql.ENUM(
    "none", "route", "url", "event", "maps",
    name="home_slide_cta_action",
    create_type=False,
)


def upgrade() -> None:
    bind = op.get_bind()
    slide_type_enum.create(bind, checkfirst=True)
    cta_action_enum.create(bind, checkfirst=True)

    op.create_table(
        "home_slides",
        sa.Column("id", postgresql.UUID(as_uuid=True), primary_key=True, server_default=sa.text("gen_random_uuid()")),
        sa.Column("slide_type", slide_type_enum, nullable=False, server_default="custom"),
        sa.Column("badge_label", sa.String(length=60), nullable=True),
        sa.Column("title", sa.String(length=160), nullable=True),
        sa.Column("subtitle", sa.Text(), nullable=True),
        sa.Column("image_url", sa.String(length=500), nullable=True),
        sa.Column("cta_label", sa.String(length=60), nullable=True),
        sa.Column("cta_action_type", cta_action_enum, nullable=False, server_default="none"),
        sa.Column("cta_action_value", sa.String(length=500), nullable=True),
        sa.Column("sort_order", sa.Integer(), nullable=False, server_default="0"),
        sa.Column("is_active", sa.Boolean(), nullable=False, server_default=sa.text("true")),
        sa.Column("starts_at", sa.DateTime(timezone=True), nullable=True),
        sa.Column("ends_at", sa.DateTime(timezone=True), nullable=True),
        sa.Column("audience_roles", postgresql.JSONB(astext_type=sa.Text()), nullable=True),
        sa.Column("audience_chapter_ids", postgresql.JSONB(astext_type=sa.Text()), nullable=True),
        sa.Column("created_at", sa.DateTime(timezone=True), nullable=False, server_default=sa.text("now()")),
        sa.Column("updated_at", sa.DateTime(timezone=True), nullable=False, server_default=sa.text("now()")),
    )
    op.create_index("ix_home_slides_sort_order", "home_slides", ["sort_order"])

    op.add_column("chapters", sa.Column("poster_url", sa.String(length=500), nullable=True))

    # ── Seed the 3 slides the app hardcodes today ───────────────────────────
    op.execute(sa.text("""
        INSERT INTO home_slides
            (slide_type, badge_label, title, image_url, cta_label, cta_action_type, cta_action_value, sort_order, is_active)
        VALUES
            (
                'custom',
                'NETWORK GROWTH',
                'Expand your business reach effortlessly.',
                'https://images.unsplash.com/photo-1556761175-b413da4baf72?auto=format&fit=crop&q=80&w=600',
                'SUBMIT OPPORTUNITY',
                'route',
                'create_referral',
                0,
                true
            ),
            (
                'next_virtual_event',
                'NEXT ONLINE SESSION',
                NULL,
                NULL,
                'JOIN ZOOM',
                'url',
                NULL,
                1,
                true
            ),
            (
                'next_physical_event',
                'CHAPTER MEETUP',
                NULL,
                NULL,
                'VIEW LOCATION',
                'maps',
                NULL,
                2,
                true
            )
    """))


def downgrade() -> None:
    op.drop_column("chapters", "poster_url")
    op.drop_index("ix_home_slides_sort_order", table_name="home_slides")
    op.drop_table("home_slides")
    bind = op.get_bind()
    cta_action_enum.drop(bind, checkfirst=True)
    slide_type_enum.drop(bind, checkfirst=True)
