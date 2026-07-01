import React from 'react';
import * as Ds from '../components/ui';
import { IconMessages } from '@tabler/icons-react';

export default function CommunityPage() {
  return (
    <div className="dashboard-body">
      <Ds.PageHeader
        title="Community"
        description="Engage with the PBN community."
      />
      
      <Ds.EmptyState 
        icon={IconMessages}
        title="Community Feed" 
        description="Community discussions are currently under development." 
      />
    </div>
  );
}
