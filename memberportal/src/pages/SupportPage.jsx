import React from 'react';
import * as Ds from '../components/ui';
import { IconHelp } from '@tabler/icons-react';

export default function SupportPage() {
  return (
    <div className="dashboard-body">
      <Ds.PageHeader
        title="Support"
        description="Get help and contact the support team."
      />
      
      <Ds.EmptyState 
        icon={IconHelp}
        title="Support Center" 
        description="The support desk is currently under development." 
      />
    </div>
  );
}
