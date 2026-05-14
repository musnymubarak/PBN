import React, { forwardRef } from 'react';
import { cx } from './classNames';

export const Textarea = forwardRef(function Textarea(
  { invalid = false, className, rows = 4, ...rest },
  ref,
) {
  return (
    <textarea
      ref={ref}
      rows={rows}
      className={cx('ds-textarea', invalid && 'ds-input--invalid', className)}
      {...rest}
    />
  );
});

export default Textarea;
