import React from 'react';
import { cx } from './classNames';

export function Card({
  elevated = false,
  flat = false,
  padded = false,
  paddedLg = false,
  className,
  children,
  ...rest
}) {
  return (
    <div
      className={cx(
        'ds-card',
        elevated && 'ds-card--elevated',
        flat && 'ds-card--flat',
        padded && 'ds-card--padded',
        paddedLg && 'ds-card--padded-lg',
        className,
      )}
      {...rest}
    >
      {children}
    </div>
  );
}

export default Card;
