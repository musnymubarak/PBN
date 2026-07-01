import React from 'react';
import * as Ds from '../components/ui';
import { IconFileText } from '@tabler/icons-react';

export default function ApplicationsPage() {
  return (
    <div className="dashboard-body">
      <Ds.PageHeader
        title="Applications"
        description="Track the status of your membership or club applications."
      />
      
      <Ds.EmptyState 
        icon={IconFileText}
        title="No Applications" 
        description="You do not have any pending applications." 
      />
    </div>
  );
}
