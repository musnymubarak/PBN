import React from 'react';
import { cx } from './classNames';

export function IconButton({
  badge,
  className,
  type = 'button',
  children,
  ...rest
}) {
  const showBadge = badge != null && badge !== 0 && badge !== '';
  return (
    <button
      type={type}
      data-badge={showBadge ? badge : undefined}
      className={cx('ds-iconbtn', showBadge && 'ds-iconbtn--badge', className)}
      {...rest}
    >
      {children}
    </button>
  );
}

export default IconButton;
