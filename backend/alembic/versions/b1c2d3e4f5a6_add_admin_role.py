"""add_admin_role

Revision ID: b1c2d3e4f5a6
Revises: 260be11477f8
Create Date: 2026-05-20 00:00:00.000000
"""

from typing import Sequence, Union

from alembic import op


revision: str = 'b1c2d3e4f5a6'
down_revision: Union[str, None] = '260be11477f8'
branch_labels: Union[str, Sequence[str], None] = None
depends_on: Union[str, Sequence[str], None] = None


def upgrade() -> None:
    op.execute("ALTER TYPE user_role ADD VALUE IF NOT EXISTS 'ADMIN'")


def downgrade() -> None:
    # Postgres does not support removing enum values without recreating the type.
    pass
