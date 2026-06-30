import React from 'react';
import { useNavigate } from 'react-router-dom';
import { IconCircleX } from '@tabler/icons-react';
import * as Ds from '../components/ui';

export default function PaymentCancelledPage() {
  const navigate = useNavigate();

  return (
    <div className="dashboard-body">
      <Ds.EmptyState
        icon={IconCircleX}
        title="Payment Cancelled"
        description="The card transaction was cancelled or failed to verify. No charges were made."
      />
      <div style={{ textAlign: 'center', marginTop: '1.5rem' }}>
        <Ds.Button variant="primary" onClick={() => navigate('/payments')}>
          Back to Payments
        </Ds.Button>
      </div>
    </div>
  );
}
