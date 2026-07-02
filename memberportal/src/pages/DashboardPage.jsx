import React, { useState, useEffect } from 'react';
import { useNavigate } from 'react-router-dom';
import * as Ds from '../components/ui';
import { 
  IconDashboard, 
  IconCalendarEvent, 
  IconCoin, 
  IconAward, 
  IconShare, 
  IconShoppingCart, 
  IconUsers, 
  IconBuildingSkyscraper,
  IconArrowRight,
  IconClock,
  IconMapPin,
  IconSparkles,
  IconCircleCheckFilled,
  IconSquarePlus,
  IconChevronRight
} from '@tabler/icons-react';
import { useAuth } from '../context/AuthContext';
import api from '../lib/api';

export default function DashboardPage() {
  const { user } = useAuth();
  const navigate = useNavigate();

  const [points, setPoints] = useState(0);
  const [tier, setTier] = useState('Standard');
  const [upcomingEvent, setUpcomingEvent] = useState(null);
  const [recentOpps, setRecentOpps] = useState([]);
  const [loading, setLoading] = useState(true);

  useEffect(() => {
    const fetchDashboardData = async () => {
      setLoading(true);
      try {
        const [resCard, resEvents, resFeed] = await Promise.all([
          api.get('/rewards/my-card').catch(() => ({ data: null })),
          api.get('/events').catch(() => ({ data: [] })),
          api.get('/community/posts', { params: { limit: 15 } }).catch(() => ({ data: [] }))
        ]);

        // Points & Tier
        const cardData = resCard?.data?.data || resCard?.data;
        if (cardData) {
          setPoints(cardData.points || 0);
          setTier(cardData.tier || cardData.membership_type || 'Standard');
        }

        // Upcoming meeting
        const eventsData = resEvents?.data?.data || resEvents?.data || [];
        const upcoming = eventsData.filter(e => new Date(e.start_at) > new Date())
          .sort((a, b) => new Date(a.start_at) - new Date(b.start_at))[0];
        setUpcomingEvent(upcoming || null);

        // Recent B2B opportunities (Leads / RFPs)
        const feedData = resFeed?.data?.data || resFeed?.data || [];
        const opps = feedData.filter(p => p.post_type === 'lead' || p.post_type === 'rfp').slice(0, 3);
        setRecentOpps(opps);

      } catch (err) {
        console.error('Failed to load dashboard data', err);
      } finally {
        setLoading(false);
      }
    };

    fetchDashboardData();
  }, []);

  const totalValue = user?.cumulative_value_generated || 0;

  // Shortcut configs
  const shortcuts = [
    { title: 'Peer Directory', desc: 'Find members & contact info', path: '/members', icon: <IconUsers size={22} />, color: 'var(--brand-blue)', bg: 'rgba(10, 37, 64, 0.04)' },
    { title: 'Specialist Clubs', desc: 'Join horizontal networks', path: '/clubs', icon: <IconBuildingSkyscraper size={22} />, color: '#34d399', bg: 'rgba(52, 211, 153, 0.04)' },
    { title: 'Opportunities', desc: 'Browse leads and RFPs', path: '/community', icon: <IconCoin size={22} />, color: 'var(--brand-amber)', bg: 'rgba(245, 158, 11, 0.04)' },
    { title: 'My Privileges', desc: 'View merchant discounts', path: '/rewards', icon: <IconAward size={22} />, color: '#a855f7', bg: 'rgba(168, 85, 247, 0.04)' }
  ];

  const getTierBadgeStyle = (tierName) => {
    const t = tierName.toLowerCase();
    if (t.includes('gold')) {
      return { background: 'linear-gradient(135deg, #BF953F, #AA771C)', color: 'white', label: 'GOLD MEMBER' };
    } else if (t.includes('platinum')) {
      return { background: 'linear-gradient(135deg, #E5E4E2, #B0C4DE)', color: '#0A2540', label: 'PLATINUM MEMBER' };
    } else if (t.includes('vip') || t.includes('charter')) {
      return { background: 'linear-gradient(135deg, #6D28D9, #4C1D95)', color: 'white', label: 'VIP CHARTER MEMBER' };
    }
    return { background: 'linear-gradient(135deg, #1E3A8A, #3B82F6)', color: 'white', label: 'VERIFIED MEMBER' };
  };

  const badgeStyle = getTierBadgeStyle(tier);

  return (
    <div className="dashboard-body" style={{ position: 'relative', paddingBottom: '4rem' }}>
      
      {/* Page Title */}
      <Ds.PageHeader
        title="Dashboard"
        description="Portal summary and quick actions control deck."
      />

      {/* Hero Welcome Banner - Overhauled for maximum depth and gradients */}
      <div 
        className="event-hero-v3"
        style={{
          background: 'linear-gradient(135deg, #0A2540 0%, #102E55 60%, #080D24 100%)',
          boxShadow: '0 20px 40px rgba(10, 37, 64, 0.22), inset 0 1px 0 rgba(255,255,255,0.12)',
          borderRadius: '28px',
          padding: '2.25rem',
          position: 'relative',
          overflow: 'hidden'
        }}
      >
        {/* Glow effect background bubble */}
        <div style={{
          position: 'absolute', right: '-40px', top: '-40px', width: '220px', height: '220px',
          borderRadius: '50%', background: 'radial-gradient(circle, rgba(245,158,11,0.18) 0%, rgba(245,158,11,0) 70%)',
          pointerEvents: 'none'
        }} />

        <div style={{ display: 'flex', flexDirection: 'column', gap: '0.65rem', maxWidth: '80%', position: 'relative', zIndex: 1 }}>
          <div style={{ display: 'flex', alignItems: 'center', gap: '8px' }}>
            <IconDashboard size={18} style={{ color: 'var(--brand-amber)' }} />
            <span style={{ fontSize: '0.7rem', fontWeight: 900, color: 'var(--brand-amber)', letterSpacing: '0.18em', textTransform: 'uppercase' }}>MEMBER COMMAND DECK</span>
          </div>
          
          <h3 style={{ fontSize: '1.85rem', fontWeight: 950, color: 'white', letterSpacing: '-0.03em', margin: '4px 0 0 0', lineHeight: 1.15 }}>
            Welcome back, {user?.full_name}!
          </h3>
          
          <p style={{ color: 'rgba(255,255,255,0.85)', fontSize: '0.92rem', margin: '4px 0 14px 0', fontWeight: 550, lineHeight: 1.4 }}>
            Track your chapter status, RSVP to upcoming meetings, and browse peer business opportunities.
          </p>

          <div style={{ display: 'flex', gap: '0.85rem', flexWrap: 'wrap', alignItems: 'center' }}>
            <Ds.Button
              onClick={() => navigate('/events')}
              variant="primary"
              style={{
                background: 'linear-gradient(135deg, var(--brand-amber) 0%, #C6A54C 100%)',
                color: '#0A2540',
                border: 'none',
                fontWeight: 950,
                fontSize: '0.75rem',
                padding: '8px 18px',
                borderRadius: '10px',
                boxShadow: '0 8px 16px rgba(245, 158, 11, 0.25)'
              }}
            >
              View Meetings
            </Ds.Button>
            <Ds.Button
              onClick={() => navigate('/community')}
              variant="secondary"
              style={{
                background: 'rgba(255, 255, 255, 0.08)',
                color: 'white',
                border: '1px solid rgba(255, 255, 255, 0.15)',
                fontWeight: 800,
                fontSize: '0.75rem',
                padding: '8px 18px',
                borderRadius: '10px',
                backdropFilter: 'blur(8px)'
              }}
            >
              Share Opportunity
            </Ds.Button>
          </div>
        </div>
      </div>

      {/* Stats Counter Strip - Styled with border accents for rich depth */}
      <div style={{ display: 'grid', gridTemplateColumns: 'repeat(auto-fit, minmax(240px, 1fr))', gap: '1.25rem', margin: '1.5rem 0' }}>
        
        {/* Stat 1: Tier */}
        <div style={{
          background: 'var(--bg-surface)', border: '1px solid var(--border-subtle)', borderRadius: '20px',
          padding: '1.25rem 1.5rem', display: 'flex', alignItems: 'center', gap: '1rem',
          boxShadow: 'var(--shadow-sm)', position: 'relative', overflow: 'hidden'
        }}>
          <div style={{ position: 'absolute', left: 0, top: 0, bottom: 0, width: '4px', background: 'var(--brand-amber)' }} />
          <div style={{ 
            width: '44px', height: '44px', borderRadius: '12px', background: 'var(--brand-amber-50)', color: 'var(--brand-amber)',
            display: 'flex', alignItems: 'center', justifyContent: 'center', flexShrink: 0
          }}>
            <IconAward size={20} />
          </div>
          <div>
            <div style={{ fontSize: '1.15rem', fontWeight: 950, color: 'var(--fg-primary)', textTransform: 'capitalize' }}>
              {tier}
            </div>
            <div style={{ fontSize: '0.7rem', color: 'var(--fg-muted)', fontWeight: 800, textTransform: 'uppercase', letterSpacing: '0.5px', marginTop: '2px' }}>
              Membership Tier
            </div>
          </div>
        </div>

        {/* Stat 2: Points */}
        <div style={{
          background: 'var(--bg-surface)', border: '1px solid var(--border-subtle)', borderRadius: '20px',
          padding: '1.25rem 1.5rem', display: 'flex', alignItems: 'center', gap: '1rem',
          boxShadow: 'var(--shadow-sm)', position: 'relative', overflow: 'hidden'
        }}>
          <div style={{ position: 'absolute', left: 0, top: 0, bottom: 0, width: '4px', background: '#a855f7' }} />
          <div style={{ 
            width: '44px', height: '44px', borderRadius: '12px', background: 'rgba(168, 85, 247, 0.1)', color: '#a855f7',
            display: 'flex', alignItems: 'center', justifyContent: 'center', flexShrink: 0
          }}>
            <IconCoin size={20} />
          </div>
          <div>
            <div style={{ fontSize: '1.25rem', fontWeight: 950, color: 'var(--fg-primary)' }}>
              {points.toLocaleString()}
            </div>
            <div style={{ fontSize: '0.7rem', color: 'var(--fg-muted)', fontWeight: 800, textTransform: 'uppercase', letterSpacing: '0.5px', marginTop: '2px' }}>
              Points Balance
            </div>
          </div>
        </div>

        {/* Stat 3: Generated ROI */}
        <div style={{
          background: 'var(--bg-surface)', border: '1px solid var(--border-subtle)', borderRadius: '20px',
          padding: '1.25rem 1.5rem', display: 'flex', alignItems: 'center', gap: '1rem',
          boxShadow: 'var(--shadow-sm)', position: 'relative', overflow: 'hidden'
        }}>
          <div style={{ position: 'absolute', left: 0, top: 0, bottom: 0, width: '4px', background: '#34d399' }} />
          <div style={{ 
            width: '44px', height: '44px', borderRadius: '12px', background: 'rgba(52, 211, 153, 0.1)', color: '#34d399',
            display: 'flex', alignItems: 'center', justifyContent: 'center', flexShrink: 0
          }}>
            <IconShare size={20} />
          </div>
          <div>
            <div style={{ fontSize: '1.12rem', fontWeight: 950, color: '#34d399' }}>
              LKR {totalValue.toLocaleString()}
            </div>
            <div style={{ fontSize: '0.7rem', color: 'var(--fg-muted)', fontWeight: 800, textTransform: 'uppercase', letterSpacing: '0.5px', marginTop: '2px' }}>
              Business Value (TYFB)
            </div>
          </div>
        </div>

      </div>

      {/* Main Grid: Columns for Meetings & Opportunities */}
      {loading ? (
        <div style={{ padding: '6rem', textAlign: 'center', color: 'var(--fg-secondary)', fontWeight: 600 }}>
          Loading dashboard summary...
        </div>
      ) : (
        <div style={{ display: 'grid', gridTemplateColumns: 'repeat(auto-fit, minmax(360px, 1fr))', gap: '2rem', marginTop: '1rem' }}>
          
          {/* Left Column: Meeting ticket stub and Quick shortcuts */}
          <div style={{ display: 'flex', flexDirection: 'column', gap: '2rem' }}>
            
            {/* Upcoming Meeting Ticket Layout */}
            <div>
              <h4 style={{ fontSize: '1.05rem', fontWeight: 900, color: 'var(--fg-primary)', marginBottom: '1rem', display: 'flex', alignItems: 'center', gap: '8px' }}>
                <IconCalendarEvent size={18} style={{ color: 'var(--brand-blue)' }} />
                Next Chapter Meeting
              </h4>

              {upcomingEvent ? (
                <div 
                  style={{
                    background: 'var(--bg-surface)', border: '1px solid var(--border-subtle)', borderRadius: '24px',
                    display: 'flex', overflow: 'hidden', boxShadow: 'var(--shadow-md)', cursor: 'pointer',
                    transition: 'transform 0.2s, box-shadow 0.2s', position: 'relative'
                  }}
                  className="ds-list-item-hover"
                  onClick={() => navigate('/events')}
                >
                  {/* Left Calendar stub block */}
                  <div style={{
                    width: '90px', background: 'linear-gradient(135deg, #0A2540 0%, #102E55 100%)',
                    display: 'flex', flexDirection: 'column', alignItems: 'center', justifyContent: 'center',
                    color: 'white', borderRight: '1.5px dashed var(--border-subtle)', flexShrink: 0, padding: '1rem'
                  }}>
                    <span style={{ fontSize: '0.7rem', fontWeight: 900, color: 'var(--brand-amber)', textTransform: 'uppercase' }}>
                      {new Date(upcomingEvent.start_at).toLocaleString('en-US', { month: 'short' })}
                    </span>
                    <span style={{ fontSize: '1.85rem', fontWeight: 950, color: 'white', lineHeight: 1.1 }}>
                      {new Date(upcomingEvent.start_at).toLocaleString('en-US', { day: '2-digit' })}
                    </span>
                    <span style={{ fontSize: '0.65rem', fontWeight: 800, color: 'rgba(255,255,255,0.7)', marginTop: '4px' }}>
                      {new Date(upcomingEvent.start_at).toLocaleString('en-US', { weekday: 'short' }).toUpperCase()}
                    </span>
                  </div>

                  {/* Right stub details */}
                  <div style={{ padding: '1.25rem', flex: 1, display: 'flex', flexDirection: 'column', gap: '0.5rem' }}>
                    <div style={{ display: 'flex', justify: 'space-between', alignItems: 'center', justifyContent: 'space-between' }}>
                      <span style={{ 
                        background: 'rgba(10, 37, 64, 0.08)', color: 'var(--brand-blue)', fontSize: '8px', 
                        fontWeight: 900, padding: '2px 8px', borderRadius: '6px', textTransform: 'uppercase'
                      }}>
                        {upcomingEvent.meeting_type || 'regular'}
                      </span>
                      
                      <div style={{ display: 'flex', alignItems: 'center', gap: '4px', fontSize: '0.72rem', color: 'var(--fg-muted)', fontWeight: 700 }}>
                        <IconClock size={12} />
                        {new Date(upcomingEvent.start_at).toLocaleTimeString('en-US', { hour: '2-digit', minute: '2-digit' })}
                      </div>
                    </div>

                    <h5 style={{ fontSize: '1.02rem', fontWeight: 900, color: 'var(--fg-primary)', margin: 0, lineHeight: 1.25 }}>
                      {upcomingEvent.title}
                    </h5>

                    <p style={{ color: 'var(--fg-secondary)', fontSize: '0.8rem', margin: 0, display: 'flex', alignItems: 'center', gap: '4px', fontWeight: 550 }}>
                      <IconMapPin size={12} style={{ color: 'var(--brand-amber)' }} />
                      {upcomingEvent.location_name || 'Virtual Classroom'}
                    </p>

                    <div style={{ display: 'flex', alignItems: 'center', gap: '4px', fontSize: '0.72rem', fontWeight: 900, color: 'var(--brand-blue)', marginTop: '4px', borderTop: '1px solid var(--border-subtle)', paddingTop: '6px' }}>
                      OPEN EVENTS CALENDAR
                      <IconChevronRight size={12} />
                    </div>
                  </div>
                </div>
              ) : (
                <div style={{ 
                  background: 'var(--bg-surface)', border: '1px solid var(--border-subtle)', borderRadius: '24px', 
                  padding: '2rem', textAlign: 'center', color: 'var(--fg-muted)', fontWeight: 600,
                  boxShadow: 'var(--shadow-sm)'
                }}>
                  No upcoming meetings scheduled.
                </div>
              )}
            </div>

            {/* Quick shortcuts grid */}
            <div>
              <h4 style={{ fontSize: '1.05rem', fontWeight: 900, color: 'var(--fg-primary)', marginBottom: '1rem' }}>
                Quick Shortcuts
              </h4>
              <div style={{ display: 'grid', gridTemplateColumns: '1fr 1fr', gap: '1rem' }}>
                {shortcuts.map((sc, i) => (
                  <button
                    key={i}
                    onClick={() => navigate(sc.path)}
                    style={{
                      background: 'var(--bg-surface)', border: '1px solid var(--border-subtle)', borderRadius: '20px', padding: '1.25rem',
                      display: 'flex', flexDirection: 'column', gap: '0.65rem', alignItems: 'flex-start', cursor: 'pointer', textAlign: 'left',
                      transition: 'all 0.2s', boxShadow: 'var(--shadow-sm)', position: 'relative', overflow: 'hidden'
                    }}
                    className="ds-list-item-hover"
                  >
                    {/* Visual accent top highlights */}
                    <div style={{ position: 'absolute', top: 0, left: 0, right: 0, height: '3px', background: sc.color }} />
                    
                    <div style={{ 
                      width: '40px', height: '40px', borderRadius: '10px', background: sc.bg, color: sc.color,
                      display: 'flex', alignItems: 'center', justify: 'center', justifyContent: 'center'
                    }}>
                      {sc.icon}
                    </div>
                    <div>
                      <div style={{ fontSize: '0.82rem', fontWeight: 900, color: 'var(--fg-primary)' }}>{sc.title}</div>
                      <div style={{ fontSize: '0.7rem', color: 'var(--fg-muted)', marginTop: '2px', fontWeight: 550, lineHeight: 1.3 }}>{sc.desc}</div>
                    </div>
                  </button>
                ))}
              </div>
            </div>

          </div>

          {/* Right Column: Opportunities Feed */}
          <div>
            <h4 style={{ fontSize: '1.05rem', fontWeight: 900, color: 'var(--fg-primary)', marginBottom: '1rem', display: 'flex', alignItems: 'center', gap: '8px' }}>
              <IconCoin size={18} style={{ color: '#34d399' }} />
              Active Leads & RFPs
            </h4>

            {recentOpps.length > 0 ? (
              <div style={{ display: 'flex', flexDirection: 'column', gap: '1.25rem' }}>
                {recentOpps.map(opp => (
                  <div
                    key={opp.id}
                    style={{
                      background: 'var(--bg-surface)', border: '1px solid var(--border-subtle)', borderRadius: '24px', padding: '1.25rem',
                      display: 'flex', flexDirection: 'column', gap: '0.65rem', cursor: 'pointer',
                      transition: 'transform 0.2s, box-shadow 0.2s', boxShadow: 'var(--shadow-sm)',
                      position: 'relative'
                    }}
                    className="ds-list-item-hover"
                    onClick={() => navigate('/community')}
                  >
                    {/* Top edge accent indicator */}
                    <div style={{
                      position: 'absolute', left: 0, top: '24px', bottom: '24px', width: '3px',
                      background: opp.post_type === 'rfp' ? 'var(--brand-blue)' : '#34d399'
                    }} />

                    <div style={{ display: 'flex', justify: 'space-between', alignItems: 'center', justifyContent: 'space-between' }}>
                      <span style={{ fontSize: '0.62rem', fontWeight: 900, color: 'var(--fg-muted)', letterSpacing: '0.5px' }}>
                        BY {opp.author?.full_name?.toUpperCase()}
                      </span>
                      <span style={{
                        background: opp.post_type === 'rfp' ? 'rgba(var(--brand-blue-rgb), 0.12)' : 'rgba(52, 211, 153, 0.12)',
                        color: opp.post_type === 'rfp' ? 'var(--brand-blue)' : '#34d399',
                        fontSize: '8px', fontWeight: 950, padding: '2px 8px', borderRadius: '6px', textTransform: 'uppercase'
                      }}>
                        {opp.post_type}
                      </span>
                    </div>

                    <h5 style={{ fontSize: '0.9rem', fontWeight: 800, color: 'var(--fg-primary)', margin: 0, lineHeight: 1.35 }}>
                      {opp.content?.length > 90 ? `${opp.content.substring(0, 90)}...` : opp.content}
                    </h5>

                    <div style={{ 
                      display: 'flex', alignItems: 'center', gap: '1rem', fontSize: '0.72rem', 
                      color: 'var(--fg-secondary)', fontWeight: 700, marginTop: '4px',
                      borderTop: '1px solid var(--border-subtle)', paddingTop: '6px'
                    }}>
                      {opp.budget_range && (
                        <span style={{ display: 'flex', alignItems: 'center', gap: '3px' }}>
                          <IconSparkles size={12} style={{ color: 'var(--brand-amber)' }} />
                          Budget: {opp.budget_range}
                        </span>
                      )}
                      {opp.deadline && (
                        <span style={{ display: 'flex', alignItems: 'center', gap: '3px' }}>
                          <IconClock size={12} style={{ color: 'var(--fg-muted)' }} />
                          Due: {new Date(opp.deadline).toLocaleDateString()}
                        </span>
                      )}
                    </div>
                  </div>
                ))}
              </div>
            ) : (
              <div style={{ 
                background: 'var(--bg-surface)', border: '1px solid var(--border-subtle)', borderRadius: '24px', 
                padding: '2.5rem', textAlign: 'center', color: 'var(--fg-muted)', display: 'flex', 
                flexDirection: 'column', alignItems: 'center', gap: '12px', boxShadow: 'var(--shadow-sm)'
              }}>
                <div style={{ 
                  width: '56px', height: '56px', borderRadius: '50%', background: 'var(--bg-canvas)',
                  display: 'flex', alignItems: 'center', justifyContent: 'center', color: 'var(--fg-muted)'
                }}>
                  <IconCoin size={24} />
                </div>
                <div>
                  <div style={{ fontSize: '0.9rem', fontWeight: 900, color: 'var(--fg-primary)' }}>No Active Opportunities</div>
                  <p style={{ fontSize: '0.75rem', color: 'var(--fg-secondary)', margin: '4px 0 0 0', fontWeight: 550 }}>
                    Active Leads and RFPs in your chapter feed will show up here.
                  </p>
                </div>
                <Ds.Button
                  onClick={() => navigate('/community')}
                  variant="primary"
                  leftIcon={<IconSquarePlus size={16} />}
                  style={{
                    background: 'linear-gradient(135deg, var(--brand-blue) 0%, #102E55 100%)',
                    color: 'white', border: 'none', fontSize: '0.72rem', fontWeight: 900,
                    padding: '6px 14px', borderRadius: '8px', marginTop: '4px'
                  }}
                >
                  Post a Lead
                </Ds.Button>
              </div>
            )}
          </div>

        </div>
      )}

    </div>
  );
}
