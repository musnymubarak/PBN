import React from 'react';
import { cx } from './classNames';

export function PageHeader({
  title,
  description,
  actions,
  className,
}) {
  return (
    <header className={cx('ds-page-header', className)}>
      <div>
        <h1 className="ds-page-header__title">{title}</h1>
        {description && <p className="ds-page-header__description">{description}</p>}
      </div>
      {actions && <div className="ds-page-header__actions">{actions}</div>}
    </header>
  );
}

export default PageHeader;
