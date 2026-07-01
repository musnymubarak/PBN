import React from 'react';
import { IconArrowUpRight, IconArrowDownRight } from '@tabler/icons-react';
import { cx } from './classNames';

export function StatCard({
  label,
  value,
  icon: Icon,
  iconColor,
  iconBg,
  trend,
  trendDirection = 'up',
  className,
  ...rest
}) {
  return (
    <div className={cx('ds-stat', className)} {...rest}>
      <div className="ds-stat__head">
        <span className="ds-stat__label">{label}</span>
        {Icon && (
          <span
            className="ds-stat__icon"
            style={{
              background: iconBg || 'var(--bg-subtle)',
              color: iconColor || 'var(--fg-secondary)',
            }}
          >
            <Icon size={18} />
          </span>
        )}
      </div>
      <div className="ds-stat__value">{value}</div>
      {trend != null && trend !== '' && (
        <div
          className={cx(
            'ds-stat__trend',
            trendDirection === 'down' && 'ds-stat__trend--down',
            trendDirection === 'neutral' && 'ds-stat__trend--neutral',
          )}
        >
          {trendDirection === 'down' ? <IconArrowDownRight size={14} /> : <IconArrowUpRight size={14} />}
          {trend}
        </div>
      )}
    </div>
  );
}

export default StatCard;
