"""fix_referral_status_enum_values

Revision ID: a1b2c3d4e5f6
Revises: ffafc1c43488
Create Date: 2026-04-06 16:10:00.000000
"""

from typing import Sequence, Union

from alembic import op
import sqlalchemy as sa


# revision identifiers, used by Alembic.
revision: str = 'a1b2c3d4e5f6'
down_revision: Union[str, None] = 'ffafc1c43488'
branch_labels: Union[str, Sequence[str], None] = None
depends_on: Union[str, Sequence[str], None] = None


def upgrade() -> None:
    """
    The original migration created enum values in UPPERCASE:
      SUBMITTED, CONTACTED, MEETING_SCHEDULED, CLOSED_WON, CLOSED_LOST
    The update migration added lowercase values:
      negotiation, in_progress, success
    The Python enum expects all lowercase values.

    Strategy: Rename old enum values to lowercase + rename old status names
    to match the Python model. PostgreSQL 10+ supports ALTER TYPE RENAME VALUE.
    """
    # Rename the old UPPERCASE enum values to lowercase equivalents
    op.execute("ALTER TYPE referral_status RENAME VALUE 'SUBMITTED' TO 'submitted'")
    op.execute("ALTER TYPE referral_status RENAME VALUE 'CONTACTED' TO 'contacted'")
    op.execute("ALTER TYPE referral_status RENAME VALUE 'CLOSED_WON' TO 'closed_won'")
    op.execute("ALTER TYPE referral_status RENAME VALUE 'CLOSED_LOST' TO 'closed_lost'")
    op.execute("ALTER TYPE referral_status RENAME VALUE 'MEETING_SCHEDULED' TO 'meeting_scheduled'")


def downgrade() -> None:
    op.execute("ALTER TYPE referral_status RENAME VALUE 'submitted' TO 'SUBMITTED'")
    op.execute("ALTER TYPE referral_status RENAME VALUE 'contacted' TO 'CONTACTED'")
    op.execute("ALTER TYPE referral_status RENAME VALUE 'closed_won' TO 'CLOSED_WON'")
    op.execute("ALTER TYPE referral_status RENAME VALUE 'closed_lost' TO 'CLOSED_LOST'")
    op.execute("ALTER TYPE referral_status RENAME VALUE 'meeting_scheduled' TO 'MEETING_SCHEDULED'")
