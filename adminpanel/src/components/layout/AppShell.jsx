import React from 'react';
import { Sidebar } from './Sidebar';
import { Topbar } from './Topbar';

/**
 * AppShell — the new dashboard chrome.
 *
 * Behavioral contract is identical to the previous inline sidebar/header in
 * App.jsx. All callbacks are passed through; this component owns no state
 * beyond its dropdowns (in Topbar).
 */
export function AppShell({
  activeTab,
  onChangeTab,
  adminUser,
  notifications,
  unreadCount,
  onDismissNotification,
  onOpenNotification,
  onMarkAllRead,
  onChangePassword,
  onLogout,
  children,
}) {
  return (
    <div className="ds-shell">
      <Sidebar
        activeTab={activeTab}
        onChangeTab={onChangeTab}
        adminUser={adminUser}
        onLogout={onLogout}
      />
      <div className="ds-shell__main">
        <Topbar
          adminUser={adminUser}
          notifications={notifications}
          unreadCount={unreadCount}
          onDismissNotification={onDismissNotification}
          onOpenNotification={onOpenNotification}
          onMarkAllRead={onMarkAllRead}
          onOpenSettings={() => onChangeTab('settings')}
          onOpenProfile={() => onChangeTab('settings')}
          onChangePassword={onChangePassword}
          onLogout={onLogout}
        />
        <main className="ds-shell__content">
          {children}
        </main>
      </div>
    </div>
  );
}

export default AppShell;
