import React from 'react';
import { cx } from '../ui/classNames';
import { MAIN_MENU, BOTTOM_MENU } from './menuConfig';
import { Link, useLocation } from 'react-router-dom';

export function Sidebar({ user, onLogout }) {
  const location = useLocation();

  const renderLink = (link) => {
    const Icon = link.icon;
    const active = location.pathname.startsWith(link.path);
    return (
      <li key={link.path} style={{ listStyle: 'none' }}>
        <Link
          to={link.path}
          data-tooltip={link.title}
          aria-current={active ? 'page' : undefined}
          className={cx('ds-sidebar__item', active && 'is-active')}
          style={{ textDecoration: 'none' }}
        >
          <Icon className="ds-sidebar__item-icon" size={20} />
          <span className="ds-sidebar__item-label">{link.title}</span>
        </Link>
      </li>
    );
  };

  return (
    <aside className="ds-sidebar">
      <div className="ds-sidebar__brand">
        <span className="ds-sidebar__brand-title">
          PBN <span className="ds-sidebar__brand-accent">Portal</span>
        </span>
      </div>

      <nav className="ds-sidebar__nav flex flex-col justify-between h-full" aria-label="Primary">
        <div style={{ flex: 1, overflowY: 'auto' }}>
          {MAIN_MENU.map((item, idx) => {
            if (item.isGroup) {
              return (
                <div key={idx} style={{ marginBottom: '1.5rem' }}>
                  <div style={{ fontSize: '0.7rem', fontWeight: 700, color: 'rgba(255, 255, 255, 0.4)', textTransform: 'uppercase', letterSpacing: '0.1em', marginBottom: '0.5rem', paddingLeft: '1rem' }}>
                    {item.title}
                  </div>
                  <ul className="ds-sidebar__items">
                    {item.links.map(renderLink)}
                  </ul>
                </div>
              );
            }
            return (
              <ul key={idx} className="ds-sidebar__items" style={{ marginBottom: '1.5rem' }}>
                {renderLink(item)}
              </ul>
            );
          })}
        </div>

        <ul className="ds-sidebar__items mt-auto" style={{ borderTop: '1px solid rgba(255,255,255,0.1)', paddingTop: '1rem' }}>
          {BOTTOM_MENU.map(renderLink)}
        </ul>
      </nav>
    </aside>
  );
}

export default Sidebar;
