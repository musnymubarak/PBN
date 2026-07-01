import React, { useState, useEffect } from 'react';
import * as Ds from '../components/ui';
import { 
  IconBuildingSkyscraper, 
  IconAlertTriangle, 
  IconCheck, 
  IconUsers, 
  IconChevronRight, 
  IconPlus,
  IconShield,
  IconCircleCheckFilled,
  IconUserCheck
} from '@tabler/icons-react';
import api from '../lib/api';

export default function ClubsPage() {
  const [selectedTab, setSelectedTab] = useState('browse'); // 'browse' or 'my_clubs'
  const [clubs, setClubs] = useState([]);
  const [loading, setLoading] = useState(true);
  const [loadError, setLoadError] = useState(false);
  const [actionLoadingId, setActionLoadingId] = useState(null);

  const loadData = async () => {
    setLoading(true);
    setLoadError(false);
    try {
      const res = await api.get('/horizontal-clubs');
      setClubs(res.data?.data || res.data || []);
    } catch (err) {
      console.error('Failed to load clubs', err);
      setLoadError(true);
    } finally {
      setLoading(false);
    }
  };

  useEffect(() => {
    loadData();
  }, []);

  const handleJoin = async (clubId) => {
    setActionLoadingId(clubId);
    try {
      await api.post(`/horizontal-clubs/${clubId}/join`);
      setClubs(prev => prev.map(c => {
        if (c.id === clubId) {
          return { ...c, is_member: true };
        }
        return c;
      }));
    } catch (err) {
      alert(err.response?.data?.error?.message || err.response?.data?.message || 'Failed to join club.');
    } finally {
      setActionLoadingId(null);
    }
  };

  const handleLeave = async (clubId) => {
    if (!window.confirm('Are you sure you want to leave this club?')) return;
    setActionLoadingId(clubId);
    try {
      await api.post(`/horizontal-clubs/${clubId}/leave`);
      setClubs(prev => prev.map(c => {
        if (c.id === clubId) {
          return { ...c, is_member: false };
        }
        return c;
      }));
    } catch (err) {
      alert('Failed to leave club.');
    } finally {
      setActionLoadingId(null);
    }
  };

  // Stats calculation
  const totalClubs = clubs.length;
  const myClubs = clubs.filter(c => c.is_member).length;
  const eligibleClubs = clubs.filter(c => c.is_eligible).length;

  const displayClubs = selectedTab === 'browse' ? clubs : clubs.filter(c => c.is_member);

  return (
    <div className="dashboard-body" style={{ position: 'relative', paddingBottom: '4rem' }}>
      
      {/* Title Header */}
      <div style={{ display: 'flex', justifyContent: 'space-between', alignItems: 'flex-start', marginBottom: '1.5rem' }}>
        <Ds.PageHeader
          title="Horizontal Clubs"
          description="Cross-industry specialist clubs extending from Primary Chapters."
        />
      </div>

      {/* Load Error Alert */}
      {loadError && (
        <div style={{ 
          padding: '1rem', background: 'rgba(239,68,68,0.1)', border: '1px solid rgba(239,68,68,0.2)',
          borderRadius: '16px', color: '#ef4444', marginBottom: '1.5rem',
          display: 'flex', alignItems: 'center', justifyContent: 'space-between', gap: '1rem'
        }}>
          <div style={{ display: 'flex', alignItems: 'center', gap: '10px', fontSize: '0.85rem', fontWeight: 600 }}>
            <IconAlertTriangle size={18} />
            An error occurred while fetching updates.
          </div>
          <button 
            onClick={loadData}
            style={{
              background: 'none', border: '1px solid rgba(239,68,68,0.3)',
              color: '#ef4444', borderRadius: '8px', padding: '6px 12px',
              fontSize: '0.75rem', fontWeight: 800, cursor: 'pointer'
            }}
          >
            RETRY
          </button>
        </div>
      )}

      {/* Hero Banner (styled like Event Hero) */}
      <div className="event-hero-v3">
        <div style={{ display: 'flex', flexDirection: 'column', gap: '0.5rem', maxWidth: '80%' }}>
          <div style={{ display: 'flex', alignItems: 'center', gap: '8px' }}>
            <IconBuildingSkyscraper size={20} style={{ color: 'var(--brand-amber)' }} />
            <span style={{ fontSize: '0.7rem', fontWeight: 900, color: 'var(--brand-amber)', letterSpacing: '0.15em' }}>BYLAWS ARTICLE 6</span>
          </div>
          <h3 style={{ fontSize: '1.6rem', fontWeight: 900, color: 'white', letterSpacing: '-0.02em', margin: '4px 0 0 0' }}>
            Specialist Ecosystems
          </h3>
          <p style={{ color: 'rgba(255,255,255,0.85)', fontSize: '0.9rem', margin: '4px 0 10px 0', fontWeight: 600 }}>
            Horizontal clubs unite chapter representatives from specific vertical integrations to collaborate on targeted business fields.
          </p>
          
          <div style={{
            background: 'var(--brand-blue)',
            color: 'white',
            alignSelf: 'flex-start',
            borderRadius: '8px',
            padding: '4px 10px',
            fontSize: '0.7rem',
            fontWeight: 900,
            display: 'flex',
            alignItems: 'center',
            gap: '4px'
          }}>
            <IconShield size={12} />
            Vertical Alignment Required
          </div>
        </div>
      </div>

      {/* Stats Counter Row (styled like Event stats) */}
      <div className="event-stats-v3">
        <div className="event-stat-card-v3">
          <div className="event-stat-icon-v3" style={{ background: 'var(--brand-blue-50)', color: 'var(--brand-blue)' }}>
            <IconBuildingSkyscraper size={18} />
          </div>
          <div className="event-stat-info-v3">
            <span className="event-stat-val-v3">{totalClubs}</span>
            <span className="event-stat-lbl-v3">Horizontal Clubs</span>
          </div>
        </div>
        
        <div className="event-stat-card-v3">
          <div className="event-stat-icon-v3" style={{ background: 'rgba(52, 211, 153, 0.1)', color: '#34d399' }}>
            <IconCircleCheckFilled size={18} />
          </div>
          <div className="event-stat-info-v3">
            <span className="event-stat-val-v3">{myClubs}</span>
            <span className="event-stat-lbl-v3">Joined Clubs</span>
          </div>
        </div>

        <div className="event-stat-card-v3">
          <div className="event-stat-icon-v3" style={{ background: 'var(--brand-amber-50)', color: 'var(--brand-amber)' }}>
            <IconUserCheck size={18} />
          </div>
          <div className="event-stat-info-v3">
            <span className="event-stat-val-v3">{eligibleClubs}</span>
            <span className="event-stat-lbl-v3">Eligible to Join</span>
          </div>
        </div>
      </div>

      {/* Tab Controller Bar (styled like Event tabs) */}
      <div className="events-tabs-v3" style={{ marginBottom: '1.5rem' }}>
        <button 
          className={`event-tab-btn-v3 ${selectedTab === 'browse' ? 'is-active' : ''}`}
          onClick={() => setSelectedTab('browse')}
        >
          Browse All Clubs
        </button>
        <button 
          className={`event-tab-btn-v3 ${selectedTab === 'my_clubs' ? 'is-active' : ''}`}
          onClick={() => setSelectedTab('my_clubs')}
        >
          My Joined Clubs ({myClubs})
        </button>
      </div>

      {/* Grid Card List */}
      {loading ? (
        <div style={{ padding: '6rem', textAlign: 'center', color: 'var(--fg-secondary)', fontWeight: 600 }}>
          Loading Horizontal Clubs...
        </div>
      ) : displayClubs.length === 0 ? (
        <div style={{ marginTop: '1rem' }}>
          <Ds.EmptyState 
            icon={IconBuildingSkyscraper}
            title={selectedTab === 'my_clubs' ? "No joined clubs" : "No clubs available"} 
            description={selectedTab === 'my_clubs' ? "You have not joined any horizontal clubs yet." : "Check back later for new specialist groups."}
          />
        </div>
      ) : (
        <div style={{ display: 'grid', gridTemplateColumns: 'repeat(auto-fill, minmax(320px, 1fr))', gap: '1.5rem' }}>
          {displayClubs.map(club => {
            return (
              <div 
                key={club.id}
                className="event-card-v3"
                style={{
                  display: 'flex',
                  flexDirection: 'column',
                  background: 'var(--bg-surface)',
                  border: '1px solid var(--border-subtle)',
                  borderRadius: '24px',
                  boxShadow: 'var(--shadow-sm)',
                  minHeight: '260px'
                }}
              >
                {/* Header Graphic */}
                <div style={{
                  height: '80px',
                  background: club.is_member 
                    ? 'linear-gradient(135deg, #0A2540 0%, #1A3E66 100%)' 
                    : 'linear-gradient(135deg, #102E55 0%, #080D24 100%)',
                  padding: '1.25rem',
                  color: 'white',
                  borderTopLeftRadius: '22px',
                  borderTopRightRadius: '22px',
                  display: 'flex',
                  justifyContent: 'space-between',
                  alignItems: 'center'
                }}>
                  <div style={{ display: 'flex', alignItems: 'center', gap: '8px' }}>
                    <IconBuildingSkyscraper size={20} style={{ color: 'var(--brand-amber)' }} />
                    <span style={{ fontSize: '0.65rem', fontWeight: 900, color: 'var(--brand-amber)', letterSpacing: '1px' }}>SPECIALIST INTEGRATION</span>
                  </div>
                  {club.is_member && (
                    <span style={{
                      background: 'rgba(52, 211, 153, 0.15)', color: '#34d399', fontSize: '9px', fontWeight: 900, padding: '2px 8px', borderRadius: '6px'
                    }}>
                      JOINED
                    </span>
                  )}
                </div>

                {/* Club Body */}
                <div style={{ padding: '1.25rem', display: 'flex', flexDirection: 'column', flex: 1, gap: '0.75rem' }}>
                  <h4 style={{ fontSize: '1.1rem', fontWeight: 900, color: 'var(--fg-primary)', margin: 0 }}>
                    {club.name}
                  </h4>
                  
                  <p style={{ color: 'var(--fg-secondary)', fontSize: '0.82rem', lineHeight: 1.45, margin: 0 }}>
                    {club.description || 'This horizontal club coordinates business actions and referrals across regional chapter representatives.'}
                  </p>

                  {/* Allowed Verticals / Industries */}
                  <div>
                    <div style={{ fontSize: '0.65rem', fontWeight: 800, color: 'var(--fg-muted)', letterSpacing: '0.5px', textTransform: 'uppercase', marginBottom: '4px' }}>
                      Allowed Verticals
                    </div>
                    <div style={{ display: 'flex', flexWrap: 'wrap', gap: '4px' }}>
                      {club.industries?.map((ind, i) => (
                        <span 
                          key={i} 
                          style={{
                            background: 'var(--bg-canvas)', border: '1px solid var(--border-subtle)',
                            color: 'var(--fg-secondary)', fontSize: '9px', fontWeight: 800, padding: '2px 6px', borderRadius: '4px'
                          }}
                        >
                          {ind}
                        </span>
                      ))}
                    </div>
                  </div>

                  {/* Action Controls */}
                  <div style={{ marginTop: 'auto', paddingTop: '1rem', borderTop: '1px solid var(--border-subtle)' }}>
                    {club.is_member ? (
                      <button
                        onClick={() => handleLeave(club.id)}
                        disabled={actionLoadingId === club.id}
                        className="ds-btn ds-btn--secondary"
                        style={{
                          width: '100%', padding: '0.65rem', borderRadius: '12px',
                          color: '#ef4444', borderColor: 'rgba(239, 68, 68, 0.3)',
                          fontSize: '0.75rem', fontWeight: 900,
                          cursor: 'pointer', transition: 'all 0.2s', textTransform: 'uppercase'
                        }}
                      >
                        {actionLoadingId === club.id ? 'Leaving...' : 'Leave Club'}
                      </button>
                    ) : club.is_eligible ? (
                      <button
                        onClick={() => handleJoin(club.id)}
                        disabled={actionLoadingId === club.id}
                        className="ds-btn ds-btn--primary"
                        style={{
                          width: '100%', padding: '0.65rem', borderRadius: '12px',
                          fontSize: '0.75rem', fontWeight: 900,
                          cursor: 'pointer', transition: 'all 0.2s', textTransform: 'uppercase',
                          boxShadow: '0 4px 10px rgba(10, 37, 64, 0.15)'
                        }}
                      >
                        {actionLoadingId === club.id ? 'Joining...' : 'Join Club'}
                      </button>
                    ) : (
                      <div style={{ display: 'flex', flexDirection: 'column', gap: '6px' }}>
                        <button
                          disabled
                          style={{
                            width: '100%', padding: '0.65rem', borderRadius: '12px',
                            background: 'var(--border-subtle)', border: 'none',
                            color: 'var(--fg-muted)', fontSize: '0.75rem', fontWeight: 900,
                            textTransform: 'uppercase'
                          }}
                        >
                          Not Eligible
                        </button>
                        <div style={{ fontSize: '0.7rem', color: 'var(--brand-amber)', fontWeight: 600, display: 'flex', alignItems: 'center', gap: '4px' }}>
                          <IconAlertTriangle size={12} />
                          Category does not match allowed verticals.
                        </div>
                      </div>
                    )}
                  </div>

                </div>

              </div>
            );
          })}
        </div>
      )}

    </div>
  );
}
