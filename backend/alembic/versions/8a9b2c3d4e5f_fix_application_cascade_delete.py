"""fix_application_cascade_delete

Revision ID: 8a9b2c3d4e5f
Revises: b24a7c5f5bf8
Create Date: 2026-05-06 23:30:00.000000

"""

from typing import Sequence, Union
from alembic import op
import sqlalchemy as sa

# revision identifiers, used by Alembic.
revision: str = '8a9b2c3d4e5f'
down_revision: Union[str, None] = '04b2afee29fa'
branch_labels: Union[str, Sequence[str], None] = None
depends_on: Union[str, Sequence[str], None] = None


def upgrade() -> None:
    # Drop existing foreign key if it exists and recreate with CASCADE
    # We use a try-except block in SQL or just drop it if we are sure of the name
    # In Alembic, we usually use drop_constraint
    try:
        op.drop_constraint('applications_chapter_id_fkey', 'applications', type_='foreignkey')
    except Exception:
        pass
        
    op.create_foreign_key(
        'applications_chapter_id_fkey',
        'applications', 'chapters',
        ['chapter_id'], ['id'],
        ondelete='CASCADE'
    )


def downgrade() -> None:
    op.drop_constraint('applications_chapter_id_fkey', 'applications', type_='foreignkey')
    op.create_foreign_key(
        'applications_chapter_id_fkey',
        'applications', 'chapters',
        ['chapter_id'], ['id']
    )
