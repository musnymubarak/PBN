import React, { forwardRef } from 'react';
import { cx } from './classNames';

export const Input = forwardRef(function Input(
  { size = 'md', invalid = false, leftIcon, rightIcon, className, wrapClassName, ...rest },
  ref,
) {
  const input = (
    <input
      ref={ref}
      className={cx(
        'ds-input',
        size !== 'md' && `ds-input--${size}`,
        invalid && 'ds-input--invalid',
        className,
      )}
      {...rest}
    />
  );

  if (!leftIcon && !rightIcon) return input;

  return (
    <div
      className={cx(
        'ds-input-group',
        leftIcon && 'ds-input-group--with-left',
        rightIcon && 'ds-input-group--with-right',
        wrapClassName,
      )}
    >
      {leftIcon && <span className="ds-input-group__icon ds-input-group__icon--left">{leftIcon}</span>}
      {input}
      {rightIcon && <span className="ds-input-group__icon ds-input-group__icon--right">{rightIcon}</span>}
    </div>
  );
});

export default Input;
