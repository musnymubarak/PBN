"""add_redemption_method_to_offer

Revision ID: f03cfac30799
Revises: 4ac1fa336316
Create Date: 2026-04-10 15:25:42.860218
"""

from typing import Sequence, Union

from alembic import op
import sqlalchemy as sa


# revision identifiers, used by Alembic.
revision: str = 'f03cfac30799'
down_revision: Union[str, None] = '4ac1fa336316'
branch_labels: Union[str, Sequence[str], None] = None
depends_on: Union[str, Sequence[str], None] = None


def upgrade() -> None:
    # Create the enum type manually first
    sa.Enum('qr', 'coupon', name='redemption_method').create(op.get_bind())
    op.add_column('offers', sa.Column('redemption_method', sa.Enum('qr', 'coupon', name='redemption_method'), nullable=False, server_default='qr'))


def downgrade() -> None:
    op.drop_column('offers', 'redemption_method')
    sa.Enum(name='redemption_method').drop(op.get_bind())
