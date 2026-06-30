import React from 'react';
import { cx } from './classNames';

export function Section({
  title,
  subtitle,
  actions,
  flush = false,
  className,
  children,
}) {
  return (
    <section className={cx('ds-section', className)}>
      {(title || actions) && (
        <header className="ds-section__head">
          <div>
            {title && <h2 className="ds-section__title">{title}</h2>}
            {subtitle && <p className="ds-section__subtitle">{subtitle}</p>}
          </div>
          {actions && <div className="ds-section__actions">{actions}</div>}
        </header>
      )}
      <div className={cx('ds-section__body', flush && 'ds-section__body--flush')}>
        {children}
      </div>
    </section>
  );
}

export default Section;
