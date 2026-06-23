"""prevent application cascade delete

Revision ID: 8a9b2c3d4e60
Revises: e7a1c4d9b2f0
Create Date: 2026-06-23 06:12:00.000000

"""
from alembic import op
import sqlalchemy as sa


# revision identifiers, used by Alembic.
revision = '8a9b2c3d4e60'
down_revision = 'e7a1c4d9b2f0'
branch_labels = None
depends_on = None


def upgrade():
    # Change chapter_id to allow NULL
    op.alter_column('applications', 'chapter_id',
               existing_type=sa.UUID(),
               nullable=True)
    
    # Drop existing foreign key constraint
    op.drop_constraint('applications_chapter_id_fkey', 'applications', type_='foreignkey')
    
    # Create new foreign key constraint with ON DELETE SET NULL
    op.create_foreign_key('applications_chapter_id_fkey', 'applications', 'chapters', ['chapter_id'], ['id'], ondelete='SET NULL')


def downgrade():
    op.drop_constraint('applications_chapter_id_fkey', 'applications', type_='foreignkey')
    op.create_foreign_key('applications_chapter_id_fkey', 'applications', 'chapters', ['chapter_id'], ['id'], ondelete='CASCADE')
    op.alter_column('applications', 'chapter_id',
               existing_type=sa.UUID(),
               nullable=False)
