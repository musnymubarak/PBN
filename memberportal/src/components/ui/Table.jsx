import React from 'react';
import { cx } from './classNames';
import { LoadingRow } from './Spinner';
import { EmptyState } from './EmptyState';

export function Table({ className, children, ...rest }) {
  return (
    <div className="ds-table-wrap">
      <table className={cx('ds-table', className)} {...rest}>
        {children}
      </table>
    </div>
  );
}

function TableLoadingRow({ colSpan, label = 'Loading…' }) {
  return (
    <tr>
      <td colSpan={colSpan}>
        <LoadingRow label={label} />
      </td>
    </tr>
  );
}

function TableEmptyRow({ colSpan, icon, title = 'Nothing here yet', description }) {
  return (
    <tr>
      <td colSpan={colSpan}>
        <EmptyState icon={icon} title={title} description={description} />
      </td>
    </tr>
  );
}

Table.LoadingRow = TableLoadingRow;
Table.EmptyRow = TableEmptyRow;

export default Table;
