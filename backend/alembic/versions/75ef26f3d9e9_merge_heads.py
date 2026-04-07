"""merge heads

Revision ID: 75ef26f3d9e9
Revises: 7dca487aaf51, a1b2c3d4e5f6
Create Date: 2026-04-07 10:49:31.342723
"""

from typing import Sequence, Union

from alembic import op
import sqlalchemy as sa


# revision identifiers, used by Alembic.
revision: str = '75ef26f3d9e9'
down_revision: Union[str, None] = ('7dca487aaf51', 'a1b2c3d4e5f6')
branch_labels: Union[str, Sequence[str], None] = None
depends_on: Union[str, Sequence[str], None] = None


def upgrade() -> None:
    pass


def downgrade() -> None:
    pass
