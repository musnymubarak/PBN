"""restore_horizontal_club_coordinator

Revision ID: b24a7c5f5bf8
Revises: af224c632cec
Create Date: 2026-04-30 11:24:00.000000
"""

from typing import Sequence, Union
from alembic import op
import sqlalchemy as sa

# revision identifiers, used by Alembic.
revision: str = 'b24a7c5f5bf8'
down_revision: Union[str, None] = 'af224c632cec'
branch_labels: Union[str, Sequence[str], None] = None
depends_on: Union[str, Sequence[str], None] = None


def upgrade() -> None:
    # Add back the coordinator_user_id column which was accidentally dropped
    op.add_column('horizontal_clubs', sa.Column('coordinator_user_id', sa.UUID(), nullable=True))
    op.create_foreign_key('horizontal_clubs_coordinator_user_id_fkey', 'horizontal_clubs', 'users', ['coordinator_user_id'], ['id'], ondelete='SET NULL')


def downgrade() -> None:
    op.drop_constraint('horizontal_clubs_coordinator_user_id_fkey', 'horizontal_clubs', type_='foreignkey')
    op.drop_column('horizontal_clubs', 'coordinator_user_id')
