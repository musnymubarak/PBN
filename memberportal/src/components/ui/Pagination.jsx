import React from 'react';
import { IconChevronLeft, IconChevronRight } from '@tabler/icons-react';
import { Button } from './Button';

export function Pagination({
  page,
  totalPages,
  total,
  pageLabel = 'records',
  onPageChange,
}) {
  const showControls = totalPages > 1;
  return (
    <div className="ds-pagination">
      <p className="ds-pagination__info">
        {total > 0
          ? `Showing page ${page} of ${totalPages} · ${total} ${pageLabel}`
          : `No ${pageLabel} found`}
      </p>
      {showControls && (
        <div className="ds-pagination__controls">
          <Button
            size="sm"
            variant="secondary"
            disabled={page <= 1}
            onClick={() => onPageChange(page - 1)}
            leftIcon={<IconChevronLeft size={14} />}
          >
            Prev
          </Button>
          <Button
            size="sm"
            variant="secondary"
            disabled={page >= totalPages}
            onClick={() => onPageChange(page + 1)}
            rightIcon={<IconChevronRight size={14} />}
          >
            Next
          </Button>
        </div>
      )}
    </div>
  );
}

export default Pagination;
