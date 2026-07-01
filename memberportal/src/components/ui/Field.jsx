import React from 'react';
import { cx } from './classNames';

export function Field({
  label,
  htmlFor,
  required = false,
  hint,
  error,
  className,
  children,
}) {
  return (
    <div className={cx('ds-field', className)}>
      {label && (
        <label
          htmlFor={htmlFor}
          className={cx('ds-label', required && 'ds-label--required')}
        >
          {label}
        </label>
      )}
      {children}
      {hint && !error && <p className="ds-help">{hint}</p>}
      {error && <p className="ds-error">{error}</p>}
    </div>
  );
}

export default Field;
