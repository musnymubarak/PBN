import React, { useState, useRef, useEffect } from 'react';
import {
  IconBell,
  IconSearch,
  IconUser,
  IconLock,
  IconLogout,
  IconSettings,
  IconCheck,
} from '@tabler/icons-react';
import { Avatar } from '../ui/Avatar';
import { IconButton } from '../ui/IconButton';
import { cx } from '../ui/classNames';

/**
 * Topbar — search, notifications, settings, profile.
 *
 * Functional contract is identical to the legacy header inside App.jsx:
 *  - notifications: array (uses .id, .is_read, .title, .description, .created_at)
 *  - unreadCount: number
 *  - onDismissNotification(id): mark single read
 *  - onMarkAllRead(): mark all read
 *  - onOpenSettings(): nav to settings tab
 *  - onOpenProfile(): nav to settings tab
 *  - onChangePassword(): open change-password modal
 *  - onLogout(): sign out
 */
export function Topbar({
  adminUser,
  notifications = [],
  unreadCount = 0,
  onDismissNotification,
  onMarkAllRead,
  onOpenSettings,
  onOpenProfile,
  onChangePassword,
  onLogout,
}) {
  const [showNotifications, setShowNotifications] = useState(false);
  const [showProfileMenu, setShowProfileMenu] = useState(false);
  const notifRef = useRef(null);
  const profileRef = useRef(null);

  useEffect(() => {
    function onDocClick(e) {
      if (notifRef.current && !notifRef.current.contains(e.target)) setShowNotifications(false);
      if (profileRef.current && !profileRef.current.contains(e.target)) setShowProfileMenu(false);
    }
    document.addEventListener('mousedown', onDocClick);
    return () => document.removeEventListener('mousedown', onDocClick);
  }, []);

  return (
    <header className="ds-topbar">
      <div className="ds-topbar__left">
        <div className="ds-topbar__search">
          <IconSearch size={16} className="ds-topbar__search-icon" />
          <input
            type="text"
            placeholder="Search members, referrals, chapters…"
            aria-label="Quick search"
          />
        </div>
      </div>

      <div className="ds-topbar__right">
        {/* Notifications */}
        <div ref={notifRef} style={{ position: 'relative' }}>
          <IconButton
            aria-label="Notifications"
            badge={unreadCount > 0 ? unreadCount : undefined}
            onClick={(e) => {
              e.stopPropagation();
              setShowProfileMenu(false);
              setShowNotifications(v => !v);
            }}
          >
            <IconBell size={18} />
          </IconButton>

          {showNotifications && (
            <div
              className="ds-popover"
              style={{ position: 'absolute', top: 'calc(100% + 8px)', right: 0, width: 360, zIndex: 1000 }}
              onClick={e => e.stopPropagation()}
            >
              <div className="ds-popover__header">
                <span className="ds-popover__title">Notifications</span>
                {unreadCount > 0 && (
                  <button className="ds-popover__action" onClick={onMarkAllRead}>
                    <IconCheck size={12} style={{ marginRight: 4, verticalAlign: '-2px' }} />
                    Mark all read
                  </button>
                )}
              </div>
              <div className="ds-popover__list">
                {notifications.length === 0 ? (
                  <div style={{ padding: 'var(--space-8) var(--space-4)', textAlign: 'center', color: 'var(--fg-muted)', fontSize: 'var(--text-sm)' }}>
                    You're all caught up.
                  </div>
                ) : (
                  notifications.slice(0, 8).map(n => (
                    <div
                      key={n.id}
                      className={cx('ds-popover__item', !n.is_read && 'is-unread')}
                      onClick={() => onDismissNotification && onDismissNotification(n.id)}
                    >
                      <span style={{ width: 8, height: 8, borderRadius: '50%', background: !n.is_read ? 'var(--brand-blue)' : 'var(--neutral-300)', flexShrink: 0, marginTop: 6 }} />
                      <div style={{ minWidth: 0 }}>
                        <p style={{ fontSize: 'var(--text-sm)', fontWeight: 600, color: 'var(--fg-primary)', marginBottom: 2 }}>
                          {n.title || 'Notification'}
                        </p>
                        {n.description && (
                          <p style={{ fontSize: 'var(--text-xs)', color: 'var(--fg-secondary)', lineHeight: 1.45 }}>
                            {n.description}
                          </p>
                        )}
                        {n.created_at && (
                          <p style={{ fontSize: 'var(--text-xs)', color: 'var(--fg-muted)', marginTop: 4 }}>
                            {new Date(n.created_at).toLocaleString()}
                          </p>
                        )}
                      </div>
                    </div>
                  ))
                )}
              </div>
            </div>
          )}
        </div>

        <IconButton aria-label="Settings" onClick={onOpenSettings}>
          <IconSettings size={18} />
        </IconButton>

        <span className="ds-topbar__divider" aria-hidden />

        {/* Profile */}
        <div ref={profileRef} style={{ position: 'relative' }}>
          <button
            type="button"
            className="ds-topbar__profile"
            onClick={(e) => {
              e.stopPropagation();
              setShowNotifications(false);
              setShowProfileMenu(v => !v);
            }}
          >
            <span className="ds-topbar__profile-meta">
              <span className="ds-topbar__profile-name">{adminUser?.full_name || 'Admin User'}</span>
              <span className="ds-topbar__profile-role">{adminUser?.role || 'Administrator'}</span>
            </span>
            <Avatar
              size="sm"
              name={adminUser?.full_name || 'Admin'}
              variant="brand"
            />
          </button>

          {showProfileMenu && (
            <div
              className="ds-popover"
              style={{ position: 'absolute', top: 'calc(100% + 8px)', right: 0, zIndex: 1000 }}
              onClick={e => e.stopPropagation()}
            >
              <div className="ds-popover__menu">
                <button
                  type="button"
                  className="ds-popover__menu-item"
                  onClick={() => { setShowProfileMenu(false); onOpenProfile && onOpenProfile(); }}
                >
                  <IconUser size={16} /> My Profile
                </button>
                <button
                  type="button"
                  className="ds-popover__menu-item"
                  onClick={() => { setShowProfileMenu(false); onChangePassword && onChangePassword(); }}
                >
                  <IconLock size={16} /> Change Password
                </button>
                <div className="ds-popover__menu-divider" />
                <button
                  type="button"
                  className="ds-popover__menu-item is-danger"
                  onClick={() => { setShowProfileMenu(false); onLogout && onLogout(); }}
                >
                  <IconLogout size={16} /> Sign Out
                </button>
              </div>
            </div>
          )}
        </div>
      </div>
    </header>
  );
}

export default Topbar;
