import {
  IconChartBar,
  IconUsers,
  IconHierarchy2,
  IconCoin,
  IconSettings,
  IconBell,
  IconClipboardList,
  IconCalendarEvent,
  IconBuildingStore,
  IconBuildingCommunity,
} from '@tabler/icons-react';

/**
 * Sidebar nav configuration. Identical structure to the old MENU_GROUPS,
 * just lifted out of App.jsx so layout components can consume it.
 *
 * `id` MUST match the `activeTab` switch in App.jsx — do not rename without
 * updating the renderContent() routing in App.jsx.
 */
export const MENU_GROUPS = [
  {
    label: 'Main Dashboard',
    links: [
      { id: 'overview', icon: IconChartBar, label: 'Analytics Hub' },
      { id: 'members', icon: IconUsers, label: 'Member Directory' },
    ],
  },
  {
    label: 'Operations',
    links: [
      { id: 'applications', icon: IconClipboardList, label: 'Applications' },
      { id: 'referrals', icon: IconHierarchy2, label: 'Referral Pipeline' },
      { id: 'events', icon: IconCalendarEvent, label: 'Event Management' },
      { id: 'marketplace', icon: IconBuildingStore, label: 'Marketplace' },
      { id: 'payments', icon: IconCoin, label: 'Payments' },
      { id: 'revenue', icon: IconChartBar, label: 'Revenue & ROI' },
    ],
  },
  {
    label: 'Expansion',
    links: [
      { id: 'rewards', icon: IconBuildingStore, label: 'Rewards Hub' },
      { id: 'chapters', icon: IconBuildingCommunity, label: 'Global Chapters' },
      { id: 'clubs', icon: IconHierarchy2, label: 'Horizontal Clubs' },
    ],
  },
  {
    label: 'System & Security',
    links: [
      { id: 'settings', icon: IconSettings, label: 'Global Settings' },
      { id: 'notifications', icon: IconBell, label: 'Security Logs' },
    ],
  },
];
