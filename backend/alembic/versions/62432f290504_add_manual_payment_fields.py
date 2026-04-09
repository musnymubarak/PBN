"""add_manual_payment_fields

Revision ID: 62432f290504
Revises: 75ef26f3d9e9
Create Date: 2026-04-09 10:55:28.432381
"""

from typing import Sequence, Union

from alembic import op
import sqlalchemy as sa


# revision identifiers, used by Alembic.
revision: str = '62432f290504'
down_revision: Union[str, None] = '75ef26f3d9e9'
branch_labels: Union[str, Sequence[str], None] = None
depends_on: Union[str, Sequence[str], None] = None


def upgrade() -> None:
    # Add manual payment fields
    op.add_column('payments', sa.Column('reason', sa.String(length=255), nullable=True))
    op.add_column('payments', sa.Column('notes', sa.String(length=1000), nullable=True))
    op.add_column('payments', sa.Column('recorded_by_id', sa.UUID(), sa.ForeignKey('users.id', ondelete='SET NULL'), nullable=True))


def downgrade() -> None:
    op.drop_column('payments', 'recorded_by_id')
    op.drop_column('payments', 'notes')
    op.drop_column('payments', 'reason')
