import React from 'react';
import { cx } from '../ui/classNames';
import { MENU_GROUPS } from './menuConfig';

// Flatten the grouped menu config into a single list — no section labels
const NAV_ITEMS = MENU_GROUPS.flatMap(g => g.links);

export function Sidebar({ activeTab, onChangeTab, adminUser, onLogout }) {
  const role = adminUser?.role;
  const visibleItems = NAV_ITEMS.filter(item => !item.roles || item.roles.includes(role));
  return (
    <aside className="ds-sidebar">
      <div className="ds-sidebar__brand">
        <span className="ds-sidebar__brand-title">
          Prime <span className="ds-sidebar__brand-accent">Business</span> Network
        </span>
      </div>

      <nav className="ds-sidebar__nav" aria-label="Primary">
        <ul className="ds-sidebar__items">
          {visibleItems.map(link => {
            const Icon = link.icon;
            const active = activeTab === link.id;
            return (
              <li key={link.id} style={{ listStyle: 'none' }}>
                <button
                  type="button"
                  data-tooltip={link.label}
                  aria-current={active ? 'page' : undefined}
                  className={cx('ds-sidebar__item', active && 'is-active')}
                  onClick={() => onChangeTab(link.id)}
                >
                  <Icon className="ds-sidebar__item-icon" size={20} />
                  <span className="ds-sidebar__item-label">{link.label}</span>
                </button>
              </li>
            );
          })}
        </ul>
      </nav>
    </aside>
  );
}

export default Sidebar;
