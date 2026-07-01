import React from 'react';
import { useNavigate } from 'react-router-dom';
import { IconCircleCheck } from '@tabler/icons-react';
import * as Ds from '../components/ui';

export default function PaymentSuccessPage() {
  const navigate = useNavigate();

  return (
    <div className="dashboard-body">
      <Ds.EmptyState
        icon={IconCircleCheck}
        title="Payment Successful!"
        description="Your card transaction has been completed and verified. Thank you!"
      />
      <div style={{ textAlign: 'center', marginTop: '1.5rem' }}>
        <Ds.Button variant="primary" onClick={() => navigate('/payments')}>
          Back to Payments
        </Ds.Button>
      </div>
    </div>
  );
}
