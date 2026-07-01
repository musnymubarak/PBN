import React from 'react';
import * as Ds from '../components/ui';
import { IconCalendarEvent } from '@tabler/icons-react';

export default function EventsPage() {
  return (
    <div className="dashboard-body">
      <Ds.PageHeader
        title="Events"
        description="RSVP and view upcoming networking events."
      />
      
      <Ds.EmptyState 
        icon={IconCalendarEvent}
        title="Upcoming Events" 
        description="Event management is currently under development." 
      />
    </div>
  );
}
