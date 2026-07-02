import React, { useState, useRef, useEffect } from 'react';
import {
  IconBell,
  IconSearch,
  IconUser,
  IconLock,
  IconLogout,
  IconSettings,
  IconCheck,
  IconFileText,
  IconUserCheck,
  IconUserX,
  IconCash,
  IconRocket,
  IconShoppingCart,
  IconMessage,
  IconArrowsExchange,
  IconCalendarEvent,
  IconUsers,
  IconCircleCheckFilled,
} from '@tabler/icons-react';
import { Avatar } from '../ui/Avatar';
import { IconButton } from '../ui/IconButton';
import { cx } from '../ui/classNames';

/**
 * Visual identity per notification_type — icon + accent color.
 * Keep keys in sync with the backend `notification_type` strings emitted by
 * `notify_admins(...)` (see backend/app/features/notifications/service.py).
 */
const NOTIF_META = {
  NEW_APPLICATION:           { Icon: IconFileText,      color: '#2563eb' },
  ADMIN_MEMBER_APPROVED:     { Icon: IconUserCheck,     color: '#16a34a' },
  ADMIN_APPLICATION_REJECTED:{ Icon: IconUserX,         color: '#dc2626' },
  ADMIN_PAYMENT_RECEIVED:    { Icon: IconCash,          color: '#059669' },
  ADMIN_DEAL_ALERT:          { Icon: IconRocket,        color: '#d97706' },
  ADMIN_LISTING_PENDING:     { Icon: IconShoppingCart,  color: '#7c3aed' },
  ADMIN_NEW_LEAD:            { Icon: IconMessage,       color: '#0891b2' },
  ADMIN_NEW_REFERRAL:        { Icon: IconArrowsExchange,color: '#4f46e5' },
  ADMIN_EVENT_CREATED:       { Icon: IconCalendarEvent, color: '#db2777' },
  ADMIN_RSVP_REQUEST:        { Icon: IconCalendarEvent, color: '#db2777' },
  ADMIN_CLUB_JOIN:           { Icon: IconUsers,         color: '#0d9488' },
};

function notifMeta(type) {
  return NOTIF_META[type] || { Icon: IconBell, color: 'var(--brand-blue)' };
}

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
  onOpenNotification,
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
        <div style={{ display: 'flex', flexDirection: 'column' }}>
          <span style={{ fontSize: 'var(--text-lg)', fontWeight: 700, color: 'var(--fg-primary)' }}>
            Welcome back, {adminUser?.full_name?.split(' ')[0] || 'Member'}!
          </span>
          <span style={{ fontSize: 'var(--text-xs)', color: 'var(--fg-secondary)', marginTop: '0.125rem' }}>
            {new Date().toLocaleDateString('en-US', { weekday: 'long', month: 'long', day: 'numeric', year: 'numeric' })}
          </span>
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
                  notifications.slice(0, 8).map(n => {
                    const { Icon, color } = notifMeta(n.notification_type);
                    const bodyText = n.body || n.description;
                    const ts = n.sent_at || n.created_at;
                    const canOpen = !!(n.data && n.data.route);
                    return (
                    <div
                      key={n.id}
                      role="button"
                      tabIndex={0}
                      className={cx('ds-popover__item', !n.is_read && 'is-unread')}
                      style={{ cursor: 'pointer' }}
                      title={canOpen ? 'Open' : undefined}
                      onClick={() => {
                        if (onOpenNotification) {
                          onOpenNotification(n);
                          setShowNotifications(false);
                        } else if (onDismissNotification) {
                          onDismissNotification(n.id);
                        }
                      }}
                    >
                      <span
                        aria-hidden
                        style={{
                          width: 30, height: 30, borderRadius: '50%', flexShrink: 0,
                          display: 'flex', alignItems: 'center', justifyContent: 'center',
                          background: `color-mix(in srgb, ${color} 14%, transparent)`,
                          color,
                        }}
                      >
                        <Icon size={16} />
                      </span>
                      <div style={{ minWidth: 0, flex: 1 }}>
                        <p style={{ fontSize: 'var(--text-sm)', fontWeight: 600, color: 'var(--fg-primary)', marginBottom: 2 }}>
                          {n.title || 'Notification'}
                        </p>
                        {bodyText && (
                          <p style={{ fontSize: 'var(--text-xs)', color: 'var(--fg-secondary)', lineHeight: 1.45 }}>
                            {bodyText}
                          </p>
                        )}
                        {ts && (
                          <p style={{ fontSize: 'var(--text-xs)', color: 'var(--fg-muted)', marginTop: 4 }}>
                            {new Date(ts).toLocaleString()}
                          </p>
                        )}
                      </div>
                      {!n.is_read && (
                        <span style={{ width: 8, height: 8, borderRadius: '50%', background: 'var(--brand-blue)', flexShrink: 0, marginTop: 6 }} />
                      )}
                    </div>
                    );
                  })
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
            <div style={{ position: 'relative', display: 'inline-flex', flexShrink: 0 }}>
              <Avatar
                size="sm"
                src={adminUser?.profile_photo || undefined}
                name={adminUser?.full_name || 'Admin'}
                variant="brand"
              />
              {adminUser?.verification_level && adminUser.verification_level !== 'none' && (() => {
                const lvl = adminUser.verification_level.toLowerCase();
                const tierColor =
                  lvl === 'gold'     ? '#D97706' :   // amber — matches mobile accent
                  lvl === 'silver'   ? '#9CA3AF' :   // silver grey — matches mobile textMuted
                  lvl === 'platinum' ? '#E5E7EB' :   // light grey
                                      '#2563EB';     // blue — verified (mobile accentBlue)
                const tierLabel =
                  lvl === 'gold'     ? 'Gold Member' :
                  lvl === 'silver'   ? 'Silver Member' :
                  lvl === 'platinum' ? 'Platinum Member' :
                                      'Verified Member';
                return (
                  <span
                    title={tierLabel}
                    style={{
                      position: 'absolute',
                      bottom: '-3px',
                      right: '-3px',
                      width: '16px',
                      height: '16px',
                      borderRadius: '50%',
                      background: 'white',
                      display: 'flex',
                      alignItems: 'center',
                      justifyContent: 'center',
                      boxShadow: `0 0 0 1.5px white, 0 1px 4px rgba(0,0,0,0.18)`,
                      lineHeight: 1,
                    }}
                  >
                    <IconCircleCheckFilled size={16} style={{ color: tierColor }} />
                  </span>
                );
              })()}
            </div>
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
