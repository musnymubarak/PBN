import { 
  IconUsers, 
  IconShare, 
  IconShoppingCart,
  IconSettings,
  IconDashboard,
  IconBuildingCommunity,
  IconCalendarEvent,
  IconMessages,
  IconCash,
  IconAward,
  IconHelp,
  IconFileText,
  IconBuildingSkyscraper
} from '@tabler/icons-react';

export const MAIN_MENU = [
  {
    title: 'Dashboard',
    path: '/dashboard',
    icon: IconDashboard,
    permission: 'all'
  },
  {
    title: 'Networking',
    isGroup: true,
    links: [
      { title: 'Directory', path: '/members', icon: IconUsers },
      { title: 'Chapters', path: '/chapters', icon: IconBuildingCommunity },
      { title: 'Clubs', path: '/clubs', icon: IconBuildingSkyscraper },
      { title: 'Community', path: '/community', icon: IconMessages },
      { title: 'Events', path: '/events', icon: IconCalendarEvent },
    ]
  },
  {
    title: 'Business',
    isGroup: true,
    links: [
      { title: 'Referrals', path: '/referrals', icon: IconShare },
      { title: 'Marketplace', path: '/marketplace', icon: IconShoppingCart },
      { title: 'Payments', path: '/payments', icon: IconCash },
      { title: 'Rewards', path: '/rewards', icon: IconAward },
    ]
  },
  {
    title: 'Account',
    isGroup: true,
    links: [
      { title: 'Applications', path: '/applications', icon: IconFileText },
      { title: 'Support', path: '/support', icon: IconHelp },
    ]
  }
];

export const BOTTOM_MENU = [
  {
    title: 'Email Settings',
    path: '/settings',
    icon: IconSettings,
    permission: 'all'
  }
];
