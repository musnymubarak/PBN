import React from 'react';
import * as Ds from '../components/ui';
import { IconAward } from '@tabler/icons-react';

export default function RewardsPage() {
  return (
    <div className="dashboard-body">
      <Ds.PageHeader
        title="Rewards"
        description="View your accumulated points and rewards."
      />
      
      <Ds.EmptyState 
        icon={IconAward}
        title="Rewards" 
        description="The rewards system is currently under development." 
      />
    </div>
  );
}
