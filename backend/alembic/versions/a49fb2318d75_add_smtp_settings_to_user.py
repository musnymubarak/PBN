"""add smtp_settings to user

Revision ID: a49fb2318d75
Revises: a870cd23c337
Create Date: 2026-06-30 07:51:44.604267
"""

from typing import Sequence, Union

from alembic import op
import sqlalchemy as sa
from sqlalchemy.dialects import postgresql

# revision identifiers, used by Alembic.
revision: str = 'a49fb2318d75'
down_revision: Union[str, None] = 'a870cd23c337'
branch_labels: Union[str, Sequence[str], None] = None
depends_on: Union[str, Sequence[str], None] = None


def upgrade() -> None:
    op.add_column('users', sa.Column('smtp_settings', postgresql.JSONB(astext_type=sa.Text()), nullable=True))

def downgrade() -> None:
    op.drop_column('users', 'smtp_settings')
