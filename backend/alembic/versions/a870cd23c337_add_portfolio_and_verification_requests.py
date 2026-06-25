"""add_portfolio_and_verification_requests

Revision ID: a870cd23c337
Revises: be7d8d8619a2
Create Date: 2026-06-25 06:45:15.525474
"""

from typing import Sequence, Union

from alembic import op
import sqlalchemy as sa
from sqlalchemy.dialects import postgresql


# revision identifiers, used by Alembic.
revision: str = 'a870cd23c337'
down_revision: Union[str, None] = 'be7d8d8619a2'
branch_labels: Union[str, Sequence[str], None] = None
depends_on: Union[str, Sequence[str], None] = None


def upgrade() -> None:
    # 1. Add portfolio columns to businesses table
    op.add_column('businesses', sa.Column('address', sa.Text(), nullable=True))
    op.add_column('businesses', sa.Column('established_year', sa.String(length=50), nullable=True))
    op.add_column('businesses', sa.Column('br_number', sa.String(length=100), nullable=True))
    op.add_column('businesses', sa.Column('brochure_url', sa.String(length=500), nullable=True))
    op.add_column('businesses', sa.Column('google_maps_url', sa.String(length=500), nullable=True))
    op.add_column('businesses', sa.Column('linkedin_url', sa.String(length=500), nullable=True))
    op.add_column('businesses', sa.Column('facebook_url', sa.String(length=500), nullable=True))
    op.add_column('businesses', sa.Column('instagram_url', sa.String(length=500), nullable=True))

    # 2. Create verification_requests table
    op.create_table(
        'verification_requests',
        sa.Column('id', sa.UUID(), nullable=False),
        sa.Column('user_id', sa.UUID(), nullable=False),
        sa.Column('status', sa.String(length=30), server_default='pending', nullable=False),
        sa.Column('rejection_reason', sa.Text(), nullable=True),
        sa.Column('created_at', sa.DateTime(timezone=True), server_default=sa.text('now()'), nullable=False),
        sa.Column('updated_at', sa.DateTime(timezone=True), server_default=sa.text('now()'), nullable=False),
        sa.ForeignKeyConstraint(['user_id'], ['users.id'], ondelete='CASCADE'),
        sa.PrimaryKeyConstraint('id')
    )
    op.create_index(op.f('ix_verification_requests_user_id'), 'verification_requests', ['user_id'], unique=False)


def downgrade() -> None:
    # 1. Drop verification_requests table
    op.drop_index(op.f('ix_verification_requests_user_id'), table_name='verification_requests')
    op.drop_table('verification_requests')

    # 2. Remove portfolio columns from businesses table
    op.drop_column('businesses', 'instagram_url')
    op.drop_column('businesses', 'facebook_url')
    op.drop_column('businesses', 'linkedin_url')
    op.drop_column('businesses', 'google_maps_url')
    op.drop_column('businesses', 'brochure_url')
    op.drop_column('businesses', 'br_number')
    op.drop_column('businesses', 'established_year')
    op.drop_column('businesses', 'address')
