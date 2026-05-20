"""add_is_locked_to_industry_categories

Revision ID: c2d4e6f8a1b3
Revises: b1c2d3e4f5a6
Create Date: 2026-05-20 06:50:00.000000
"""

from typing import Sequence, Union

from alembic import op
import sqlalchemy as sa


revision: str = 'c2d4e6f8a1b3'
down_revision: Union[str, None] = 'b1c2d3e4f5a6'
branch_labels: Union[str, Sequence[str], None] = None
depends_on: Union[str, Sequence[str], None] = None


def upgrade() -> None:
    op.add_column(
        "industry_categories",
        sa.Column("is_locked", sa.Boolean(), nullable=False, server_default=sa.false()),
    )


def downgrade() -> None:
    op.drop_column("industry_categories", "is_locked")
