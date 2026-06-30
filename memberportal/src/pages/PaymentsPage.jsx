import React from 'react';
import * as Ds from '../components/ui';
import { IconCash } from '@tabler/icons-react';

export default function PaymentsPage() {
  return (
    <div className="dashboard-body">
      <Ds.PageHeader
        title="Payments"
        description="View transaction history and upload payment proofs."
      />
      
      <Ds.EmptyState 
        icon={IconCash}
        title="Payments" 
        description="Payment history is currently under development." 
      />
    </div>
  );
}
