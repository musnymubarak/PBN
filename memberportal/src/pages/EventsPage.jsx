import React, { useState, useEffect } from 'react';
import { 
  IconCalendarEvent, 
  IconHistory, 
  IconClock, 
  IconMapPin, 
  IconLink,
  IconVideo,
  IconCrown,
  IconTicket,
  IconUsers,
  IconCircleCheck,
  IconChevronRight,
  IconX,
  IconAlertTriangle,
  IconCalendarMonth,
  IconExternalLink
} from '@tabler/icons-react';
import { useAuth } from '../context/AuthContext';
import * as Ds from '../components/ui';
import api from '../lib/api';

export default function EventsPage() {
  const { user } = useAuth();
  const [events, setEvents] = useState([]);
  const [memberships, setMemberships] = useState([]);
  const [loading, setLoading] = useState(true);
  const [loadError, setLoadError] = useState(false);
  const [selectedTab, setSelectedTab] = useState('upcoming');
  const [selectedEvent, setSelectedEvent] = useState(null);
  const [rsvpSubmitting, setRsvpSubmitting] = useState(false);

  const fetchEventsAndMemberships = async () => {
    setLoading(true);
    setLoadError(false);
    try {
      const [eventsRes, membershipsRes] = await Promise.all([
        api.get('/events'),
        api.get('/chapters/my-memberships')
      ]);
      
      if (eventsRes.data?.data) {
        setEvents(eventsRes.data.data);
      }
      if (membershipsRes.data?.data) {
        setMemberships(membershipsRes.data.data);
      }
    } catch (err) {
      console.error('Failed to load events and memberships', err);
      setLoadError(true);
    } finally {
      setLoading(false);
    }
  };

  useEffect(() => {
    fetchEventsAndMemberships();
  }, []);

  const handleRSVP = async (status) => {
    if (!selectedEvent) return;
    setRsvpSubmitting(true);
    try {
      const res = await api.post(`/events/${selectedEvent.id}/rsvp`, { status });
      if (res.data?.data) {
        const updatedEvent = res.data.data;
        // Update local events list
        setEvents(prev => prev.map(e => e.id === updatedEvent.id ? { ...e, rsvps: updatedEvent.rsvps } : e));
        setSelectedEvent(prev => ({ ...prev, rsvps: updatedEvent.rsvps }));
      }
    } catch (err) {
      console.error('Failed to update RSVP', err);
    } finally {
      setRsvpSubmitting(false);
    }
  };

  const handleReserveSpot = async (event) => {
    if (!event) return;
    setRsvpSubmitting(true);
    try {
      if (Number(event.fee) > 0) {
        // Initiate Card Payment
        const res = await api.post('/payments/initiate', {
          payment_type: 'meeting_fee',
          amount: parseFloat(event.fee),
          event_id: event.id,
        });

        if (res.data?.data?.payment_url) {
          const initUrl = res.data.data.payment_url;
          const separator = initUrl.includes('?') ? '&' : '?';
          window.location.href = `${initUrl}${separator}source=portal`;
        } else {
          alert('Failed to initiate online payment.');
        }
      } else {
        // Free event RSVP
        const res = await api.post(`/events/${event.id}/rsvp`, { status: 'going' });
        if (res.data?.data) {
          const updatedEvent = res.data.data;
          setEvents(prev => prev.map(e => e.id === updatedEvent.id ? { ...e, rsvps: updatedEvent.rsvps } : e));
          setSelectedEvent(prev => prev && prev.id === updatedEvent.id ? { ...prev, rsvps: updatedEvent.rsvps } : prev);
        }
      }
    } catch (err) {
      console.error(err);
      alert(err.response?.data?.error?.message || 'Action failed. Please try again.');
    } finally {
      setRsvpSubmitting(false);
    }
  };

  // Resilient chapter matching: filter to user's active chapter memberships,
  // fallback to all events if user doesn't have active chapter memberships (e.g. admins).
  const activeMemberships = memberships.filter(m => m.is_active);
  const myChapterIds = new Set(activeMemberships.map(m => m.chapter.id));
  const myEvents = myChapterIds.size > 0
    ? events.filter(e => myChapterIds.has(e.chapter_id))
    : events;

  const now = new Date();
  const upcomingEvents = myEvents
    .filter(e => new Date(e.start_at) > now)
    .sort((a, b) => new Date(a.start_at) - new Date(b.start_at));

  const finishedEvents = myEvents
    .filter(e => new Date(e.start_at) <= now)
    .sort((a, b) => new Date(b.start_at) - new Date(a.start_at));

  const currentList = selectedTab === 'upcoming' ? upcomingEvents : finishedEvents;

  // Stats
  const thisMonthCount = myEvents.filter(e => {
    const startDt = new Date(e.start_at);
    return startDt.getMonth() === now.getMonth() && startDt.getFullYear() === now.getFullYear();
  }).length;

  const attendingCount = myEvents.filter(e => {
    const userRsvp = e.rsvps?.find(r => r.user.id === user?.id);
    return userRsvp && (userRsvp.status === 'going' || userRsvp.status === 'requested');
  }).length;

  const getPlaceholderImage = (event) => {
    if (event.event_type === 'flagship') {
      return 'https://images.unsplash.com/photo-1486406146926-c627a92ad1ab?auto=format&fit=crop&q=80&w=800';
    }
    const t = (event.title || '').toLowerCase();
    if (t.includes('connect') || t.includes('network')) {
      return 'https://images.unsplash.com/photo-1556761175-b413da4baf72?auto=format&fit=crop&q=80&w=800';
    }
    return 'https://images.unsplash.com/photo-1497366216548-37526070297c?auto=format&fit=crop&q=80&w=800';
  };

  const getCountdownLabel = (startAt) => {
    const diffMs = new Date(startAt) - new Date();
    if (diffMs < 0) return null;
    const diffDays = Math.floor(diffMs / (1000 * 60 * 60 * 24));
    if (diffDays >= 1) {
      return diffDays === 1 ? 'TOMORROW' : `IN ${diffDays} DAYS`;
    }
    const diffHours = Math.floor(diffMs / (1000 * 60 * 60));
    if (diffHours >= 1) {
      return diffHours === 1 ? 'IN 1 HOUR' : `IN ${diffHours} HOURS`;
    }
    const diffMins = Math.floor(diffMs / (1000 * 60));
    if (diffMins > 0) return `IN ${diffMins} MIN`;
    return 'STARTING NOW';
  };

  const formatDate = (dateStr) => {
    const dt = new Date(dateStr);
    return dt.toLocaleDateString('en-US', { weekday: 'short', month: 'short', day: 'numeric' }) + ' • ' + 
           dt.toLocaleTimeString('en-US', { hour: 'numeric', minute: '2-digit', hour12: true });
  };

  if (loading) {
    return (
      <div className="dashboard-body">
        <Ds.PageHeader
          title="Meetings & Events"
          description="RSVP and view upcoming networking events."
        />
        <Ds.EmptyState
          icon={Ds.Spinner}
          title="Loading events..."
          description="Fetching chapter schedules from the PBN network."
        />
      </div>
    );
  }

  // Next upcoming event for Hero banner
  const nextEvent = upcomingEvents.length > 0 ? upcomingEvents[0] : null;
  const countdownLabel = nextEvent ? getCountdownLabel(nextEvent.start_at) : null;

  return (
    <div className="dashboard-body" style={{ position: 'relative' }}>
      <Ds.PageHeader
        title="Meetings & Events"
        description="RSVP and view upcoming networking events."
      />

      {/* Error Alert Banner */}
      {loadError && (
        <div style={{
          background: 'rgba(239, 68, 68, 0.08)',
          border: '1px solid rgba(239, 68, 68, 0.2)',
          borderRadius: 'var(--radius-lg)',
          padding: '1rem',
          display: 'flex',
          alignItems: 'center',
          justifyContent: 'space-between',
          marginBottom: '1.5rem',
          gap: '1rem'
        }}>
          <div style={{ display: 'flex', alignItems: 'center', gap: '0.75rem' }}>
            <IconAlertTriangle style={{ color: '#ef4444' }} />
            <div>
              <div style={{ fontWeight: 700, color: 'var(--fg-primary)' }}>Couldn't load meetings</div>
              <div style={{ fontSize: '0.8rem', color: 'var(--fg-secondary)' }}>An error occurred while fetching updates.</div>
            </div>
          </div>
          <button 
            onClick={fetchEventsAndMemberships}
            style={{
              background: 'none',
              border: '1px solid rgba(239,68,68,0.3)',
              color: '#ef4444',
              borderRadius: '8px',
              padding: '6px 12px',
              fontWeight: 800,
              fontSize: '0.75rem',
              cursor: 'pointer'
            }}
          >
            RETRY
          </button>
        </div>
      )}

      {/* Hero Banner Card */}
      {selectedTab === 'upcoming' && nextEvent ? (
        <div className="event-hero-v3" onClick={() => setSelectedEvent(nextEvent)} style={{ cursor: 'pointer' }}>
          <div style={{ display: 'flex', flexDirection: 'column', gap: '0.5rem', maxWidth: '80%' }}>
            <div style={{ display: 'flex', alignItems: 'center', gap: '8px' }}>
              <IconCalendarEvent size={20} style={{ color: 'var(--brand-amber)' }} />
              <span style={{ fontSize: '0.7rem', fontWeight: 900, color: 'var(--brand-amber)', letterSpacing: '0.15em' }}>NEXT MEETING</span>
            </div>
            <h3 style={{ fontSize: '1.6rem', fontWeight: 900, color: 'white', letterSpacing: '-0.02em', margin: '4px 0 0 0' }}>
              {nextEvent.title}
            </h3>
            <p style={{ color: 'rgba(255,255,255,0.85)', fontSize: '0.9rem', margin: '4px 0 10px 0', fontWeight: 600 }}>
              {formatDate(nextEvent.start_at)}
            </p>
            {countdownLabel && (
              <div style={{
                background: 'var(--brand-amber)',
                color: 'white',
                alignSelf: 'flex-start',
                borderRadius: '8px',
                padding: '4px 10px',
                fontSize: '0.7rem',
                fontWeight: 900,
                display: 'flex',
                alignItems: 'center',
                gap: '4px',
                boxShadow: '0 4px 10px rgba(198, 165, 76, 0.3)'
              }}>
                <IconClock size={12} />
                {countdownLabel}
              </div>
            )}
          </div>
        </div>
      ) : (
        <div className="event-hero-v3">
          <div style={{ display: 'flex', flexDirection: 'column', gap: '0.5rem' }}>
            <div style={{ display: 'flex', alignItems: 'center', gap: '8px' }}>
              <IconHistory size={20} style={{ color: 'var(--brand-amber)' }} />
              <span style={{ fontSize: '0.7rem', fontWeight: 900, color: 'var(--brand-amber)', letterSpacing: '0.15em' }}>MEETINGS COMPLETED</span>
            </div>
            <h3 style={{ fontSize: '2.5rem', fontWeight: 900, color: 'white', letterSpacing: '-0.03em', margin: '4px 0 0 0', lineHeight: 1 }}>
              {finishedEvents.length}
            </h3>
            <p style={{ color: 'rgba(255,255,255,0.75)', fontSize: '0.9rem', margin: '4px 0 0 0', fontWeight: 500 }}>
              Total past meetings and flagship networking events hosted by PBN.
            </p>
          </div>
        </div>
      )}

      {/* Stats Counter Row */}
      <div className="event-stats-v3">
        <div className="event-stat-card-v3">
          <div className="event-stat-icon-v3" style={{ background: 'var(--brand-blue-50)', color: 'var(--brand-blue)' }}>
            <IconCalendarEvent size={18} />
          </div>
          <div className="event-stat-info-v3">
            <span className="event-stat-val-v3">{currentList.length}</span>
            <span className="event-stat-lbl-v3">{selectedTab === 'upcoming' ? 'Upcoming' : 'Past'}</span>
          </div>
        </div>
        
        <div className="event-stat-card-v3">
          <div className="event-stat-icon-v3" style={{ background: 'var(--brand-amber-50)', color: 'var(--brand-amber)' }}>
            <IconCalendarMonth size={18} />
          </div>
          <div className="event-stat-info-v3">
            <span className="event-stat-val-v3">{thisMonthCount}</span>
            <span className="event-stat-lbl-v3">This Month</span>
          </div>
        </div>

        <div className="event-stat-card-v3">
          <div className="event-stat-icon-v3" style={{ background: 'rgba(52, 211, 153, 0.1)', color: '#34d399' }}>
            <IconCircleCheck size={18} />
          </div>
          <div className="event-stat-info-v3">
            <span className="event-stat-val-v3">{attendingCount}</span>
            <span className="event-stat-lbl-v3">Attending</span>
          </div>
        </div>
      </div>

      {/* Tab Controller Bar */}
      <div className="events-tabs-v3">
        <button 
          className={`event-tab-btn-v3 ${selectedTab === 'upcoming' ? 'is-active' : ''}`}
          onClick={() => setSelectedTab('upcoming')}
        >
          Upcoming
        </button>
        <button 
          className={`event-tab-btn-v3 ${selectedTab === 'finished' ? 'is-active' : ''}`}
          onClick={() => setSelectedTab('finished')}
        >
          Finished
        </button>
      </div>

      {/* Events Grid */}
      {currentList.length > 0 ? (
        <div className="events-grid-v3">
          {currentList.map(event => {
            const startDt = new Date(event.start_at);
            const day = startDt.getDate().toString().padStart(2, '0');
            const month = startDt.toLocaleString('en-US', { month: 'short' }).toUpperCase();
            
            const imageUrl = event.image_url 
              ? (event.image_url.startsWith('http') ? event.image_url : event.image_url) 
              : getPlaceholderImage(event);

            const isVirtual = event.event_type === 'virtual';
            const isFlagship = event.event_type === 'flagship';
            
            const typeLabel = isFlagship ? 'FLAGSHIP' : (isVirtual ? 'ONLINE' : 'IN-PERSON');
            const typeColor = isFlagship ? 'var(--brand-amber)' : (isVirtual ? 'var(--brand-blue)' : '#34d399');
            const typeIcon = isFlagship ? <IconCrown size={11} /> : (isVirtual ? <IconVideo size={11} /> : <IconMapPin size={11} />);

            const userRsvp = event.rsvps?.find(r => r.user.id === user?.id);
            const isAttending = userRsvp && (userRsvp.status === 'going' || userRsvp.status === 'requested');

            return (
              <div 
                key={event.id}
                className="event-card-v3"
                onClick={() => setSelectedEvent(event)}
              >
                {/* Cover Image & Badges */}
                <div className="event-card-img-wrap-v3">
                  <img src={imageUrl} alt={event.title} className="event-card-img-v3" />
                  
                  <div className="date-badge-v3">
                    <span className="date-badge-month-v3">{month}</span>
                    <span className="date-badge-day-v3">{day}</span>
                  </div>

                  <div className="event-type-pill-v3" style={{ color: typeColor }}>
                    {typeIcon}
                    {typeLabel}
                  </div>

                  {event.fee > 0 && (
                    <div className="event-fee-pill-v3">
                      <IconTicket size={12} />
                      LKR {Number(event.fee).toLocaleString()}
                    </div>
                  )}
                </div>

                {/* Details Body */}
                <div style={{ padding: '1.25rem', display: 'flex', flexDirection: 'column', flex: 1 }}>
                  <div style={{ display: 'flex', alignItems: 'center', gap: '4px', color: 'var(--brand-amber)', fontSize: '0.75rem', fontWeight: 800 }}>
                    <IconClock size={12} />
                    {formatDate(event.start_at)}
                  </div>

                  <h4 style={{ fontSize: '1.05rem', fontWeight: 900, color: 'var(--fg-primary)', margin: '0.5rem 0', lineHeight: 1.3 }}>
                    {event.title}
                  </h4>

                  <div style={{ display: 'flex', alignItems: 'center', gap: '8px', color: 'var(--fg-secondary)', fontSize: '0.8rem', fontWeight: 700, margin: '4px 0 8px 0' }}>
                    {isVirtual ? <IconLink size={14} style={{ color: 'var(--brand-blue)' }} /> : <IconMapPin size={14} style={{ color: 'var(--brand-blue)' }} />}
                    <span style={{ overflow: 'hidden', textOverflow: 'ellipsis', whiteSpace: 'nowrap' }}>
                      {isVirtual ? (event.meeting_link || 'Online link') : (event.location || 'Colombo')}
                    </span>
                  </div>

                  {event.description && (
                    <p style={{ color: 'var(--fg-muted)', fontSize: '0.8125rem', lineHeight: 1.4, margin: '0 0 1rem 0' }}>
                      {event.description.length > 90 ? `${event.description.substring(0, 90)}...` : event.description}
                    </p>
                  )}

                  {/* Card Footer RSVP */}
                  <div style={{ display: 'flex', alignItems: 'center', justifyContent: 'space-between', marginTop: 'auto' }}>
                    {(() => {
                      const goingCount = event.rsvps?.filter(r => r.status === 'going').length || 0;
                      const userRsvpStatus = userRsvp?.status || null;
                      
                      if (userRsvpStatus === 'going') {
                        return (
                          <div style={{ 
                            fontSize: '0.75rem', 
                            fontWeight: 800,
                            padding: '4px 8px',
                            borderRadius: '6px',
                            background: 'rgba(52, 211, 153, 0.12)',
                            border: '1px solid rgba(52, 211, 153, 0.25)',
                            color: '#34d399',
                            display: 'flex',
                            alignItems: 'center',
                            gap: '4px'
                          }}>
                            <IconCircleCheck size={12} />
                            {`You're going · ${goingCount}`}
                          </div>
                        );
                      } else if (userRsvpStatus === 'requested') {
                        return (
                          <div style={{ 
                            fontSize: '0.75rem', 
                            fontWeight: 800,
                            padding: '4px 8px',
                            borderRadius: '6px',
                            background: 'rgba(245, 158, 11, 0.12)',
                            border: '1px solid rgba(245, 158, 11, 0.25)',
                            color: '#f59e0b',
                            display: 'flex',
                            alignItems: 'center',
                            gap: '4px'
                          }}>
                            <IconClock size={12} />
                            Awaiting Approval
                          </div>
                        );
                      } else {
                        return (
                          <div style={{ 
                            fontSize: '0.75rem', 
                            fontWeight: 800,
                            padding: '4px 8px',
                            borderRadius: '6px',
                            background: 'rgba(0,0,0,0.04)',
                            border: '1px solid rgba(0,0,0,0.06)',
                            color: 'var(--fg-muted)',
                            display: 'flex',
                            alignItems: 'center',
                            gap: '4px'
                          }}>
                            <IconUsers size={12} />
                            {`${goingCount} attending`}
                          </div>
                        );
                      }
                    })()}

                    <IconChevronRight size={18} style={{ color: 'var(--fg-muted)' }} />
                  </div>
                </div>

              </div>
            );
          })}
        </div>
      ) : (
        <div style={{ marginTop: '1rem' }}>
          <Ds.EmptyState 
            icon={IconCalendarEvent}
            title={selectedTab === 'upcoming' ? 'No upcoming events' : 'No past events'}
            description={selectedTab === 'upcoming' 
              ? 'New chapter meetings will appear here as soon as they are published.'
              : 'There are no past events registered on your account.'
            }
          />
        </div>
      )}

      {/* Event Details Modal */}
      {selectedEvent && (
        <div style={{
          position: 'fixed',
          inset: 0,
          background: 'rgba(10, 37, 64, 0.4)',
          backdropFilter: 'blur(4px)',
          display: 'flex',
          alignItems: 'center',
          justifyContent: 'center',
          zIndex: 1000
        }} onClick={() => setSelectedEvent(null)}>
          <div style={{
            background: 'var(--bg-surface)',
            borderRadius: 'var(--radius-xl)',
            border: '1px solid var(--border-subtle)',
            width: '100%',
            maxWidth: '520px',
            padding: '2rem',
            position: 'relative',
            boxShadow: 'var(--elev-4)'
          }} onClick={e => e.stopPropagation()}>
            
            {/* Close Button */}
            <button 
              onClick={() => setSelectedEvent(null)}
              style={{
                position: 'absolute',
                top: '1.5rem',
                right: '1.5rem',
                background: 'none',
                border: 'none',
                color: 'var(--fg-muted)',
                cursor: 'pointer',
                padding: '4px'
              }}
            >
              <IconX size={20} />
            </button>

            {/* Banner details */}
            <div style={{ 
              background: 'linear-gradient(135deg, #0A2540 0%, #102E55 100%)', 
              borderRadius: '16px',
              padding: '1.25rem',
              color: 'white',
              marginBottom: '1.5rem',
              boxShadow: '0 4px 12px rgba(10, 37, 64, 0.15)'
            }}>
              <div style={{ display: 'flex', alignItems: 'center', gap: '6px', color: 'var(--brand-amber)', fontSize: '0.75rem', fontWeight: 800 }}>
                <IconCalendarEvent size={14} />
                {selectedEvent.event_type.toUpperCase()} EVENT
              </div>
              <h4 style={{ fontSize: '1.25rem', fontWeight: 900, margin: '6px 0 0 0', color: 'white', letterSpacing: '-0.02em', lineHeight: 1.3 }}>
                {selectedEvent.title}
              </h4>
            </div>

            {/* Description */}
            {selectedEvent.description && (
              <div style={{ marginBottom: '1.5rem' }}>
                <div style={{ fontSize: '0.65rem', fontWeight: 900, color: 'var(--fg-muted)', letterSpacing: '0.1em', textTransform: 'uppercase', marginBottom: '0.5rem' }}>About Event</div>
                <p style={{ color: 'var(--fg-secondary)', fontSize: '0.875rem', lineHeight: 1.5, margin: 0 }}>
                  {selectedEvent.description}
                </p>
              </div>
            )}

            {/* Quick Facts Grid */}
            <div style={{ marginBottom: '1.5rem' }}>
              <div style={{ fontSize: '0.65rem', fontWeight: 900, color: 'var(--fg-muted)', letterSpacing: '0.1em', textTransform: 'uppercase', marginBottom: '0.75rem' }}>Details</div>
              
              <div style={{ display: 'flex', flexDirection: 'column', gap: '0.75rem' }}>
                {/* Date & Time */}
                <div style={{ display: 'flex', alignItems: 'center', justifyContent: 'space-between', padding: '0.75rem 1rem', background: 'var(--bg-canvas)', borderRadius: '10px', border: '1px solid var(--border-subtle)' }}>
                  <div style={{ display: 'flex', alignItems: 'center', gap: '10px', color: 'var(--fg-secondary)', fontSize: '0.85rem', fontWeight: 600 }}>
                    <IconClock size={16} style={{ color: 'var(--brand-blue)' }} />
                    Date & Time
                  </div>
                  <span style={{ fontSize: '0.875rem', fontWeight: 800, color: 'var(--fg-primary)' }}>
                    {formatDate(selectedEvent.start_at)}
                  </span>
                </div>

                {/* Location */}
                {selectedEvent.location && (
                  <div style={{ display: 'flex', alignItems: 'center', justifyContent: 'space-between', padding: '0.75rem 1rem', background: 'var(--bg-canvas)', borderRadius: '10px', border: '1px solid var(--border-subtle)' }}>
                    <div style={{ display: 'flex', alignItems: 'center', gap: '10px', color: 'var(--fg-secondary)', fontSize: '0.85rem', fontWeight: 600 }}>
                      <IconMapPin size={16} style={{ color: 'var(--brand-amber)' }} />
                      Location
                    </div>
                    <div style={{ display: 'flex', alignItems: 'center', gap: '6px' }}>
                      <span style={{ fontSize: '0.875rem', fontWeight: 800, color: 'var(--fg-primary)', overflow: 'hidden', textOverflow: 'ellipsis', whiteSpace: 'nowrap', maxWidth: '180px' }}>
                        {selectedEvent.location}
                      </span>
                      <a 
                        href={`https://maps.google.com/?q=${encodeURIComponent(selectedEvent.location)}`} 
                        target="_blank" 
                        rel="noopener noreferrer"
                        style={{ display: 'flex', alignItems: 'center', color: 'var(--brand-blue)', padding: '2px' }}
                      >
                        <IconExternalLink size={14} />
                      </a>
                    </div>
                  </div>
                )}

                {/* Meeting Link */}
                {selectedEvent.meeting_link && (
                  <div style={{ display: 'flex', alignItems: 'center', justifyContent: 'space-between', padding: '0.75rem 1rem', background: 'var(--bg-canvas)', borderRadius: '10px', border: '1px solid var(--border-subtle)' }}>
                    <div style={{ display: 'flex', alignItems: 'center', gap: '10px', color: 'var(--fg-secondary)', fontSize: '0.85rem', fontWeight: 600 }}>
                      <IconLink size={16} style={{ color: 'var(--brand-blue)' }} />
                      Meeting Link
                    </div>
                    <div style={{ display: 'flex', alignItems: 'center', gap: '6px' }}>
                      <span style={{ fontSize: '0.875rem', fontWeight: 800, color: 'var(--fg-primary)', overflow: 'hidden', textOverflow: 'ellipsis', whiteSpace: 'nowrap', maxWidth: '180px' }}>
                        {selectedEvent.meeting_link}
                      </span>
                      <a 
                        href={selectedEvent.meeting_link.startsWith('http') ? selectedEvent.meeting_link : `https://${selectedEvent.meeting_link}`} 
                        target="_blank" 
                        rel="noopener noreferrer"
                        style={{ display: 'flex', alignItems: 'center', color: 'var(--brand-blue)', padding: '2px' }}
                      >
                        <IconExternalLink size={14} />
                      </a>
                    </div>
                  </div>
                )}

                {/* Ticket Fee */}
                <div style={{ display: 'flex', alignItems: 'center', justifyContent: 'space-between', padding: '0.75rem 1rem', background: 'var(--bg-canvas)', borderRadius: '10px', border: '1px solid var(--border-subtle)' }}>
                  <div style={{ display: 'flex', alignItems: 'center', gap: '10px', color: 'var(--fg-secondary)', fontSize: '0.85rem', fontWeight: 600 }}>
                    <IconTicket size={16} style={{ color: '#34d399' }} />
                    Ticket Fee
                  </div>
                  <span style={{ fontSize: '0.875rem', fontWeight: 800, color: 'var(--fg-primary)' }}>
                    {selectedEvent.fee > 0 ? `LKR ${Number(selectedEvent.fee).toLocaleString()}` : 'Free'}
                  </span>
                </div>

                {/* Chapter */}
                <div style={{ display: 'flex', alignItems: 'center', justifyContent: 'space-between', padding: '0.75rem 1rem', background: 'var(--bg-canvas)', borderRadius: '10px', border: '1px solid var(--border-subtle)' }}>
                  <div style={{ display: 'flex', alignItems: 'center', gap: '10px', color: 'var(--fg-secondary)', fontSize: '0.85rem', fontWeight: 600 }}>
                    <IconUsers size={16} style={{ color: 'var(--brand-amber)' }} />
                    Chapter
                  </div>
                  <span style={{ fontSize: '0.875rem', fontWeight: 800, color: 'var(--fg-primary)' }}>
                    {memberships.find(m => m.chapter.id === selectedEvent.chapter_id)?.chapter?.name || 'PBN Chapter'}
                  </span>
                </div>
              </div>
            </div>

            {/* RSVP Selection Buttons (Only for upcoming events) */}
            {selectedTab === 'upcoming' && (() => {
              const userRsvp = selectedEvent.rsvps?.find(r => r.user.id === user?.id);
              const rsvpStatus = userRsvp?.status || null;

              return (
                <div style={{ marginBottom: '2rem' }}>
                  <div style={{ fontSize: '0.65rem', fontWeight: 900, color: 'var(--fg-muted)', letterSpacing: '0.1em', textTransform: 'uppercase', marginBottom: '0.75rem' }}>Your RSVP</div>
                  
                  {rsvpStatus === 'going' ? (
                    <div style={{
                      background: 'rgba(52, 211, 153, 0.12)',
                      border: '1px solid rgba(52, 211, 153, 0.3)',
                      borderRadius: '12px',
                      padding: '1rem',
                      display: 'flex',
                      alignItems: 'center',
                      gap: '0.75rem'
                    }}>
                      <div style={{
                        background: 'rgba(52, 211, 153, 0.2)',
                        borderRadius: '8px',
                        padding: '6px',
                        display: 'flex',
                        alignItems: 'center',
                        justifyContent: 'center',
                        color: '#34d399'
                      }}>
                        <IconCircleCheck size={18} />
                      </div>
                      <div>
                        <div style={{ fontSize: '0.85rem', fontWeight: 900, color: '#34d399', letterSpacing: '0.05em' }}>YOU'RE REGISTERED</div>
                        <div style={{ fontSize: '0.8rem', color: 'var(--fg-secondary)', marginTop: '2px' }}>See you at the meeting.</div>
                      </div>
                    </div>
                  ) : rsvpStatus === 'requested' ? (
                    <div style={{
                      background: 'rgba(245, 158, 11, 0.12)',
                      border: '1px solid rgba(245, 158, 11, 0.3)',
                      borderRadius: '12px',
                      padding: '1rem',
                      display: 'flex',
                      alignItems: 'center',
                      gap: '0.75rem'
                    }}>
                      <div style={{
                        background: 'rgba(245, 158, 11, 0.2)',
                        borderRadius: '8px',
                        padding: '6px',
                        display: 'flex',
                        alignItems: 'center',
                        justifyContent: 'center',
                        color: '#f59e0b'
                      }}>
                        <IconClock size={18} />
                      </div>
                      <div>
                        <div style={{ fontSize: '0.85rem', fontWeight: 900, color: '#f59e0b', letterSpacing: '0.05em' }}>WAITING FOR APPROVAL</div>
                        <div style={{ fontSize: '0.8rem', color: 'var(--fg-secondary)', marginTop: '2px' }}>Your chapter lead will confirm shortly.</div>
                      </div>
                    </div>
                  ) : (
                    <div style={{ display: 'flex', gap: '0.75rem' }}>
                      <button
                        disabled={rsvpSubmitting}
                        onClick={() => handleReserveSpot(selectedEvent)}
                        style={{
                          flex: 2,
                          background: 'linear-gradient(135deg, var(--brand-amber) 0%, var(--brand-amber-600) 100%)',
                          color: 'white',
                          border: 'none',
                          borderRadius: '10px',
                          padding: '0.75rem 1.25rem',
                          fontSize: '0.875rem',
                          fontWeight: 800,
                          cursor: 'pointer',
                          display: 'flex',
                          alignItems: 'center',
                          justifyContent: 'center',
                          gap: '6px',
                          boxShadow: '0 4px 10px rgba(198, 165, 76, 0.2)'
                        }}
                      >
                        {rsvpSubmitting ? (
                          <Ds.Spinner size={14} style={{ color: 'white' }} />
                        ) : (
                          <>
                            RESERVE SPOT
                            {selectedEvent.fee > 0 && ` • LKR ${Number(selectedEvent.fee).toLocaleString()}`}
                          </>
                        )}
                      </button>
                      <button
                        disabled={rsvpSubmitting}
                        onClick={() => handleRSVP('not_going')}
                        style={{
                          flex: 1,
                          background: 'none',
                          border: `1px solid ${rsvpStatus === 'not_going' ? 'rgba(239, 68, 68, 0.3)' : 'var(--border-default)'}`,
                          color: rsvpStatus === 'not_going' ? '#ef4444' : 'var(--fg-secondary)',
                          borderRadius: '10px',
                          padding: '0.75rem 1.25rem',
                          fontSize: '0.875rem',
                          fontWeight: 800,
                          cursor: 'pointer',
                          display: 'flex',
                          alignItems: 'center',
                          justifyContent: 'center'
                        }}
                      >
                        {rsvpSubmitting ? (
                          <Ds.Spinner size={14} />
                        ) : (
                          rsvpStatus === 'not_going' ? 'IGNORED' : 'IGNORE'
                        )}
                      </button>
                    </div>
                  )}
                </div>
              );
            })()}

            {/* Action buttons */}
            <div style={{ display: 'flex', justifyContent: 'flex-end' }}>
              <button 
                onClick={() => setSelectedEvent(null)}
                style={{
                  background: 'var(--brand-blue)',
                  color: 'white',
                  border: 'none',
                  borderRadius: '10px',
                  padding: '0.75rem 1.5rem',
                  fontSize: '0.875rem',
                  fontWeight: 800,
                  cursor: 'pointer',
                  boxShadow: '0 4px 10px rgba(37, 99, 235, 0.2)'
                }}
              >
                Close
              </button>
            </div>

          </div>
        </div>
      )}

    </div>
  );
}
