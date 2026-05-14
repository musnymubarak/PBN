import React from 'react';
import { cx } from './classNames';

export function EmptyState({
  icon: Icon,
  title,
  description,
  action,
  className,
}) {
  return (
    <div className={cx('ds-empty', className)}>
      {Icon && (
        <span className="ds-empty__icon">
          <Icon size={26} stroke={1.5} />
        </span>
      )}
      {title && <p className="ds-empty__title">{title}</p>}
      {description && <p className="ds-empty__desc">{description}</p>}
      {action && <div style={{ marginTop: 'var(--space-3)' }}>{action}</div>}
    </div>
  );
}

export default EmptyState;
