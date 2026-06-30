import React from 'react';
import * as Ds from '../components/ui';
import { IconShoppingCart } from '@tabler/icons-react';

export default function MarketplacePage() {
  return (
    <div className="dashboard-body">
      <Ds.PageHeader
        title="Marketplace Offers"
        description="Exclusive B2B offers available only to verified PBN members."
      />
      
      <Ds.EmptyState 
        icon={IconShoppingCart}
        title="Coming Soon" 
        description="The member marketplace is currently under development." 
      />
    </div>
  );
}
