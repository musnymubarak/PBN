import React from 'react';
import { cx } from './classNames';

export function Badge({
  variant = 'neutral',
  dot = false,
  className,
  children,
  ...rest
}) {
  return (
    <span
      className={cx(
        'ds-badge',
        `ds-badge--${variant}`,
        dot && 'ds-badge--dot',
        className,
      )}
      {...rest}
    >
      {children}
    </span>
  );
}

export default Badge;
