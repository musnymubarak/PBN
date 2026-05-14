"""add member_email to privilege_cards

Revision ID: c4e1a8d97f02
Revises: 3a409dd0fa33
Create Date: 2026-05-14 12:30:00.000000

The PrivilegeCard SQLAlchemy model declared `member_email` but no
migration was generated, so SELECT statements failed with
`UndefinedColumnError: column privilege_cards.member_email does not exist`.

This adds the missing nullable column to bring the schema in sync with
the model.
"""

from typing import Sequence, Union

from alembic import op
import sqlalchemy as sa


# revision identifiers, used by Alembic.
revision: str = 'c4e1a8d97f02'
down_revision: Union[str, None] = '3a409dd0fa33'
branch_labels: Union[str, Sequence[str], None] = None
depends_on: Union[str, Sequence[str], None] = None


def upgrade() -> None:
    op.add_column(
        'privilege_cards',
        sa.Column('member_email', sa.String(length=255), nullable=True),
    )


def downgrade() -> None:
    op.drop_column('privilege_cards', 'member_email')
