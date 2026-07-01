import React from 'react';
import * as Ds from '../components/ui';
import { IconBuildingSkyscraper } from '@tabler/icons-react';

export default function ClubsPage() {
  return (
    <div className="dashboard-body">
      <Ds.PageHeader
        title="Clubs"
        description="Join specialized networking groups and clubs."
      />
      
      <Ds.EmptyState 
        icon={IconBuildingSkyscraper}
        title="Networking Clubs" 
        description="Club listings are currently under development." 
      />
    </div>
  );
}
