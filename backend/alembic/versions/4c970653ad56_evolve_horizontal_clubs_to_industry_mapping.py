"""evolve_horizontal_clubs_to_industry_mapping

Revision ID: 4c970653ad56
Revises: 63c3a9c6b99a
Create Date: 2026-04-30 11:16:00.000000
"""

from typing import Sequence, Union
from alembic import op
import sqlalchemy as sa

# revision identifiers, used by Alembic.
revision: str = '4c970653ad56'
down_revision: Union[str, None] = '63c3a9c6b99a'
branch_labels: Union[str, Sequence[str], None] = None
depends_on: Union[str, Sequence[str], None] = None


def upgrade() -> None:
    # 1. Create junction table for clubs and industries
    op.create_table('horizontal_club_industries',
        sa.Column('club_id', sa.UUID(), nullable=False),
        sa.Column('industry_id', sa.UUID(), nullable=False),
        sa.ForeignKeyConstraint(['club_id'], ['horizontal_clubs.id'], ondelete='CASCADE'),
        sa.ForeignKeyConstraint(['industry_id'], ['industry_categories.id'], ondelete='CASCADE'),
        sa.PrimaryKeyConstraint('club_id', 'industry_id')
    )
    
    # 2. Drop legacy columns from horizontal_clubs
    # We do this after creating the junction table
    op.drop_column('horizontal_clubs', 'target_vertical')


def downgrade() -> None:
    op.add_column('horizontal_clubs', sa.Column('coordinator_user_id', sa.UUID(), nullable=True))
    op.create_foreign_key('horizontal_clubs_coordinator_user_id_fkey', 'horizontal_clubs', 'users', ['coordinator_user_id'], ['id'], ondelete='SET NULL')
    op.add_column('horizontal_clubs', sa.Column('target_vertical', sa.String(length=100), nullable=True))
    op.drop_table('horizontal_club_industries')
