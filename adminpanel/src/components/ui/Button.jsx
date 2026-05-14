import React from 'react';
import { cx } from './classNames';

export function Button({
  variant = 'primary',
  size = 'md',
  block = false,
  leftIcon,
  rightIcon,
  loading = false,
  disabled = false,
  className,
  type = 'button',
  children,
  ...rest
}) {
  return (
    <button
      type={type}
      disabled={disabled || loading}
      aria-busy={loading || undefined}
      className={cx(
        'ds-btn',
        `ds-btn--${variant}`,
        `ds-btn--${size}`,
        block && 'ds-btn--block',
        className,
      )}
      {...rest}
    >
      {loading ? <span className="ds-btn__spinner" aria-hidden /> : leftIcon}
      {children && <span>{children}</span>}
      {!loading && rightIcon}
    </button>
  );
}

export default Button;
