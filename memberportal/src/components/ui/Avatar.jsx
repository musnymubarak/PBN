import React from 'react';
import { cx } from './classNames';

function initialsOf(name) {
  if (!name) return '?';
  const parts = String(name).trim().split(/\s+/);
  if (parts.length === 1) return parts[0][0] || '?';
  return (parts[0][0] || '') + (parts[parts.length - 1][0] || '');
}

export function Avatar({
  name,
  src,
  size = 'md',
  variant,
  ring = false,
  className,
  style,
  ...rest
}) {
  return (
    <span
      className={cx(
        'ds-avatar',
        `ds-avatar--${size}`,
        variant && `ds-avatar--${variant}`,
        ring && 'ds-avatar--ring',
        className,
      )}
      style={style}
      aria-label={name}
      {...rest}
    >
      {src ? <img src={src} alt={name || ''} /> : initialsOf(name)}
    </span>
  );
}

export default Avatar;
