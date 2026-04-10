"""change the application flow

Revision ID: 723abf95f434
Revises: 62432f290504
Create Date: 2026-04-09 17:02:25.976886
"""

from typing import Sequence, Union

from alembic import op
import sqlalchemy as sa


# revision identifiers, used by Alembic.
revision: str = '723abf95f434'
down_revision: Union[str, None] = '62432f290504'
branch_labels: Union[str, Sequence[str], None] = None
depends_on: Union[str, Sequence[str], None] = None


def upgrade() -> None:
    pass


def downgrade() -> None:
    pass
