import React from 'react';
import { cx } from './classNames';

export function Spinner({ size = 'md', className, ...rest }) {
  return (
    <span
      className={cx('ds-spinner', size === 'lg' && 'ds-spinner--lg', className)}
      role="status"
      aria-label="Loading"
      {...rest}
    />
  );
}

export function LoadingRow({ label = 'Loading…' }) {
  return (
    <div className="ds-loading-row">
      <Spinner size="lg" />
      {label}
    </div>
  );
}

export default Spinner;
