import React from 'react';
import * as Ds from '../components/ui';
import { IconBuildingCommunity } from '@tabler/icons-react';

export default function ChaptersPage() {
  return (
    <div className="dashboard-body">
      <Ds.PageHeader
        title="Chapters"
        description="Explore PBN chapters across different regions."
      />
      
      <Ds.EmptyState 
        icon={IconBuildingCommunity}
        title="Chapters" 
        description="Chapter directory is currently under development." 
      />
    </div>
  );
}
