"""merge_horizontal_clubs_and_cumulative_value

Revision ID: af224c632cec
Revises: 4c970653ad56, ecbc08826376
Create Date: 2026-04-30 11:50:07.243221
"""

from typing import Sequence, Union

from alembic import op
import sqlalchemy as sa


# revision identifiers, used by Alembic.
revision: str = 'af224c632cec'
down_revision: Union[str, None] = ('4c970653ad56', 'ecbc08826376')
branch_labels: Union[str, Sequence[str], None] = None
depends_on: Union[str, Sequence[str], None] = None


def upgrade() -> None:
    pass


def downgrade() -> None:
    pass
