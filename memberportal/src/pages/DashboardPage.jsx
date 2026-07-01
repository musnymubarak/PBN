import React from 'react';
import * as Ds from '../components/ui';
import { IconDashboard } from '@tabler/icons-react';

export default function DashboardPage() {
  return (
    <div className="dashboard-body">
      <Ds.PageHeader
        title="Dashboard"
        description="Welcome to your member portal."
      />
      
      <Ds.EmptyState 
        icon={IconDashboard}
        title="Dashboard Overview" 
        description="Stats and quick actions will appear here soon." 
      />
    </div>
  );
}
