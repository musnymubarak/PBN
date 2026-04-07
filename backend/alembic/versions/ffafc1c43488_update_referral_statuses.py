"""update_referral_statuses

Revision ID: ffafc1c43488
Revises: b9de2f4fa83a
Create Date: 2026-04-06 15:35:16.630056
"""

from typing import Sequence, Union

from alembic import op
import sqlalchemy as sa


# revision identifiers, used by Alembic.
revision: str = 'ffafc1c43488'
down_revision: Union[str, None] = 'b9de2f4fa83a'
branch_labels: Union[str, Sequence[str], None] = None
depends_on: Union[str, Sequence[str], None] = None


def upgrade() -> None:
    # Manual SQL to update ENUM type in Postgres. 
    # ADD VALUE cannot be run inside a transaction in Postgres, so we use autocommit.
    with op.get_context().autocommit_block():
        op.execute("ALTER TYPE referral_status ADD VALUE 'negotiation'")
        op.execute("ALTER TYPE referral_status ADD VALUE 'in_progress'")
        op.execute("ALTER TYPE referral_status ADD VALUE 'success'")


def downgrade() -> None:
    pass
