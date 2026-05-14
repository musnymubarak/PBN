import React from 'react';
import { cx } from './classNames';

export function ChipGroup({ value, onChange, options = [], className }) {
  return (
    <div className={cx('ds-chip-group', className)} role="tablist">
      {options.map(opt => (
        <button
          key={opt.value}
          type="button"
          role="tab"
          aria-selected={value === opt.value}
          className={cx('ds-chip', value === opt.value && 'is-active')}
          onClick={() => onChange(opt.value)}
        >
          {opt.label}
        </button>
      ))}
    </div>
  );
}

export default ChipGroup;
