import React, { useState, useEffect } from 'react';
import * as Ds from '../components/ui';
import { 
  IconShare, 
  IconBriefcase, 
  IconChevronRight, 
  IconPlus, 
  IconChevronLeft, 
  IconInbox, 
  IconSend, 
  IconClock, 
  IconCopy, 
  IconBulb, 
  IconCircleCheck, 
  IconTrophy, 
  IconAlertTriangle, 
  IconUserPlus, 
  IconHistory,
  IconUsers
} from '@tabler/icons-react';
import api from '../lib/api';
import GiveReferralModal from '../components/referrals/GiveReferralModal';
import UpdateReferralModal, { getStatusStyle } from '../components/referrals/UpdateReferralModal';

const INVITATION_TEXT = `Hi 👋, I'd like to introduce you to Prime Business Network (PBN) — a modern, technology-driven business growth ecosystem that helps entrepreneurs grow through structured, measurable results. It offers industry exclusivity (one member per category) and a digital system to track business opportunities and real business results.

Key Benefits:
• Exclusive industry seat (only one member per category)
• Consistent, high-quality business creation flow
• Digital tracking of business opportunities and ROI
• Increased visibility among trusted professionals
• Access to charter member benefits, events & training

By joining, you become part of a strong ecosystem built on reliable partnerships and accountable business creation, helping your business scale with purpose. Learn more and secure your spot here: https://primebusiness.network/`;

export default function ReferralsPage() {
  const [selectedTab, setSelectedTab] = useState('received'); // 'received' or 'given'
  const [receivedReferrals, setReceivedReferrals] = useState([]);
  const [givenReferrals, setGivenReferrals] = useState([]);
  const [loading, setLoading] = useState(true);
  const [loadError, setLoadError] = useState(false);

  const [isGiveModalOpen, setIsGiveModalOpen] = useState(false);
  const [updateModalData, setUpdateModalData] = useState(null);
  const [copySuccess, setCopySuccess] = useState(false);

  const loadData = async () => {
    setLoading(true);
    setLoadError(false);
    try {
      const [resReceived, resGiven] = await Promise.all([
        api.get('/referrals/my/received'),
        api.get('/referrals/my/given')
      ]);
      setReceivedReferrals(resReceived.data?.data || resReceived.data || []);
      setGivenReferrals(resGiven.data?.data || resGiven.data || []);
    } catch (err) {
      console.error('Failed to load referrals', err);
      setLoadError(true);
    } finally {
      setLoading(false);
    }
  };

  useEffect(() => {
    loadData();
  }, []);

  const formatDate = (iso) => {
    try {
      const dt = new Date(iso);
      return dt.toLocaleDateString('en-US', { day: 'numeric', month: 'short', year: 'numeric' });
    } catch (e) {
      return iso;
    }
  };

  const handleCopyInvitation = () => {
    navigator.clipboard.writeText(INVITATION_TEXT);
    setCopySuccess(true);
    setTimeout(() => setCopySuccess(false), 3000);
  };

  // Stats
  const receivedCount = receivedReferrals.length;
  const givenCount = givenReferrals.length;
  
  const isPending = (r) => r.status !== 'success' && r.status !== 'closed_lost';
  const pendingCount = 
    receivedReferrals.filter(isPending).length + 
    givenReferrals.filter(isPending).length;

  const totalActivity = receivedCount + givenCount;

  // Reciprocity Ratio Indicator
  const ratio = givenCount / Math.max(receivedCount, 1);
  let ratioLabel = '';
  let ratioColor = '#34d399';
  
  if (totalActivity > 0) {
    if (ratio >= 2.0) {
      ratioLabel = `High Giving Ratio · ${ratio.toFixed(1).replace('.0', '')}:1`;
      ratioColor = '#34d399';
    } else if (ratio >= 1.0) {
      ratioLabel = `Balanced · ${ratio.toFixed(1).replace('.0', '')}:1`;
      ratioColor = 'var(--brand-blue)';
    } else {
      const inv = receivedCount / Math.max(givenCount, 1);
      ratioLabel = `Receiving More Than Giving · 1:${inv.toFixed(1).replace('.0', '')}`;
      ratioColor = 'var(--brand-amber)';
    }
  }

  const currentList = selectedTab === 'received' ? receivedReferrals : givenReferrals;

  return (
    <div className="dashboard-body" style={{ position: 'relative', paddingBottom: '4rem' }}>
      
      {/* Title Header */}
      <div style={{ display: 'flex', justifyContent: 'space-between', alignItems: 'flex-start', marginBottom: '1.5rem' }}>
        <Ds.PageHeader
          title="Referrals"
          description="Track and manage business opportunities you have sent or received."
        />
        <Ds.Button 
          variant="primary" 
          leftIcon={<IconPlus size={16} />} 
          onClick={() => setIsGiveModalOpen(true)}
        >
          New Opportunity
        </Ds.Button>
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
            <IconBriefcase size={20} style={{ color: 'var(--brand-amber)' }} />
            <span style={{ fontSize: '0.7rem', fontWeight: 900, color: 'var(--brand-amber)', letterSpacing: '0.15em' }}>BUSINESS ACTIVITY</span>
          </div>
          <h3 style={{ fontSize: '1.6rem', fontWeight: 900, color: 'white', letterSpacing: '-0.02em', margin: '4px 0 0 0' }}>
            Pipeline & Reciprocity
          </h3>
          <p style={{ color: 'rgba(255,255,255,0.85)', fontSize: '0.9rem', margin: '4px 0 10px 0', fontWeight: 600 }}>
            {totalActivity} total opportunities logged
          </p>
          {ratioLabel && (
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
              <IconHistory size={12} />
              {ratioLabel}
            </div>
          )}
        </div>
      </div>

      {/* Stats Counter Row (styled like Event stats) */}
      <div className="event-stats-v3">
        <div className="event-stat-card-v3">
          <div className="event-stat-icon-v3" style={{ background: 'rgba(52, 211, 153, 0.1)', color: '#34d399' }}>
            <IconInbox size={18} />
          </div>
          <div className="event-stat-info-v3">
            <span className="event-stat-val-v3">{receivedCount}</span>
            <span className="event-stat-lbl-v3">Received</span>
          </div>
        </div>
        
        <div className="event-stat-card-v3">
          <div className="event-stat-icon-v3" style={{ background: 'var(--brand-blue-50)', color: 'var(--brand-blue)' }}>
            <IconSend size={18} />
          </div>
          <div className="event-stat-info-v3">
            <span className="event-stat-val-v3">{givenCount}</span>
            <span className="event-stat-lbl-v3">Given</span>
          </div>
        </div>

        <div className="event-stat-card-v3">
          <div className="event-stat-icon-v3" style={{ background: 'var(--brand-amber-50)', color: 'var(--brand-amber)' }}>
            <IconClock size={18} />
          </div>
          <div className="event-stat-info-v3">
            <span className="event-stat-val-v3">{pendingCount}</span>
            <span className="event-stat-lbl-v3">Pending</span>
          </div>
        </div>
      </div>

      {/* Tab Controller Bar (styled like Event tabs) */}
      <div className="events-tabs-v3">
        <button 
          className={`event-tab-btn-v3 ${selectedTab === 'received' ? 'is-active' : ''}`}
          onClick={() => setSelectedTab('received')}
        >
          Received Opportunities ({receivedCount})
        </button>
        <button 
          className={`event-tab-btn-v3 ${selectedTab === 'given' ? 'is-active' : ''}`}
          onClick={() => setSelectedTab('given')}
        >
          Given Opportunities ({givenCount})
        </button>
      </div>

      {/* Main List Display (Grid card list like Events Page) */}
      {loading ? (
        <div style={{ padding: '6rem', textAlign: 'center', color: 'var(--fg-secondary)', fontWeight: 600 }}>
          Loading referrals...
        </div>
      ) : currentList.length === 0 ? (
        <div style={{ marginTop: '1rem' }}>
          <Ds.EmptyState 
            icon={IconShare}
            title={selectedTab === 'received' ? "No referrals yet" : "You haven't given any referrals yet"} 
            description={selectedTab === 'received' 
              ? "When members refer leads to you, they'll appear here." 
              : "Refer a lead to a fellow member to start growing your chapter's business."} 
          />
        </div>
      ) : (
        <div style={{ 
          display: 'grid', 
          gridTemplateColumns: 'repeat(auto-fill, minmax(280px, 1fr))', 
          gap: '1.25rem',
          marginTop: '1.5rem',
          marginBottom: '3rem'
        }}>
          {currentList.map(ref => {
            const style = getStatusStyle(ref.status);
            return (
              <div 
                key={ref.id}
                className="event-card-v3"
                onClick={() => setUpdateModalData(ref)}
                style={{ cursor: 'pointer', display: 'flex', flexDirection: 'column' }}
              >
                {/* stylized solid color card top area */}
                <div style={{
                  height: '130px',
                  background: 'linear-gradient(135deg, #0A2540 0%, #102E55 100%)',
                  display: 'flex',
                  alignItems: 'center',
                  justifyContent: 'center',
                  position: 'relative',
                  borderTopLeftRadius: '16px',
                  borderTopRightRadius: '16px'
                }}>
                  <div style={{
                    width: '50px',
                    height: '50px',
                    borderRadius: '12px',
                    background: `${style.bg}`,
                    color: style.fg,
                    border: `1px solid ${style.border}`,
                    display: 'flex',
                    alignItems: 'center',
                    justifyContent: 'center'
                  }}>
                    <IconBriefcase size={24} />
                  </div>
                  
                  {/* Status Pill overlay */}
                  <div style={{
                    position: 'absolute',
                    bottom: '10px',
                    left: '12px',
                    background: style.bg,
                    color: style.fg,
                    border: `1px solid ${style.border}`,
                    padding: '2px 8px',
                    borderRadius: '6px',
                    fontSize: '9px',
                    fontWeight: 900,
                    letterSpacing: '0.5px',
                    display: 'flex',
                    alignItems: 'center',
                    gap: '4px',
                    textTransform: 'uppercase'
                  }}>
                    <span style={{ width: '4px', height: '4px', borderRadius: '50%', background: style.dot }} />
                    {style.label}
                  </div>
                </div>

                {/* Details Body */}
                <div style={{ padding: '1.25rem', display: 'flex', flexDirection: 'column', flex: 1 }}>
                  <div style={{ display: 'flex', alignItems: 'center', gap: '4px', color: 'var(--brand-amber)', fontSize: '0.75rem', fontWeight: 800 }}>
                    <IconClock size={12} />
                    {formatDate(ref.created_at)}
                  </div>

                  <h4 style={{ fontSize: '1.05rem', fontWeight: 900, color: 'var(--fg-primary)', margin: '0.5rem 0', lineHeight: 1.3 }}>
                    {ref.lead_name}
                  </h4>

                  <div style={{ display: 'flex', alignItems: 'center', gap: '8px', color: 'var(--fg-secondary)', fontSize: '0.8rem', fontWeight: 700, margin: '4px 0 8px 0' }}>
                    <IconUsers size={14} style={{ color: 'var(--brand-blue)' }} />
                    <span style={{ overflow: 'hidden', textOverflow: 'ellipsis', whiteSpace: 'nowrap' }}>
                      {selectedTab === 'received' ? `From: ${ref.from_user?.full_name}` : `To: ${ref.target_user?.full_name}`}
                    </span>
                  </div>

                  {ref.description && (
                    <p style={{ color: 'var(--fg-muted)', fontSize: '0.8125rem', lineHeight: 1.4, margin: '0 0 1rem 0' }}>
                      {ref.description.length > 70 ? `${ref.description.substring(0, 70)}...` : ref.description}
                    </p>
                  )}

                  {/* Card Footer ROI & View details */}
                  <div style={{ 
                    display: 'flex', 
                    alignItems: 'center', 
                    justifyContent: 'space-between', 
                    marginTop: 'auto',
                    borderTop: '1px solid var(--border-subtle)',
                    paddingTop: '0.75rem'
                  }}>
                    <span style={{ fontSize: '0.75rem', fontWeight: 800, color: 'var(--fg-muted)' }}>
                      {ref.actual_value ? `LKR ${Number(ref.actual_value).toLocaleString()}` : 'LKR 0 ROI'}
                    </span>
                    <span style={{ display: 'flex', alignItems: 'center', gap: '2px', color: 'var(--brand-blue)', fontSize: '0.75rem', fontWeight: 900 }}>
                      VIEW DETAILS
                      <IconChevronRight size={14} />
                    </span>
                  </div>
                </div>

              </div>
            );
          })}
        </div>
      )}

      {/* Referral Utility panels (styled nicely below the grids) */}
      <div style={{ display: 'grid', gridTemplateColumns: 'repeat(auto-fit, minmax(320px, 1fr))', gap: '1.5rem', marginTop: '2rem' }}>
        
        {/* Grow Your Network */}
        <div style={{
          background: 'var(--bg-surface)', borderRadius: '20px',
          border: '1px solid var(--border-subtle)', boxShadow: 'var(--shadow-md)',
          padding: '1.5rem', display: 'flex', flexDirection: 'column', gap: '1rem'
        }}>
          <div style={{ display: 'flex', alignItems: 'center', gap: '12px' }}>
            <div style={{
              width: '36px', height: '36px', borderRadius: '10px',
              background: 'rgba(245, 158, 11, 0.12)', color: 'var(--brand-amber)',
              display: 'flex', alignItems: 'center', justifyContent: 'center',
              border: '1px solid rgba(245, 158, 11, 0.22)'
            }}>
              <IconUserPlus size={18} />
            </div>
            <div style={{ fontSize: '0.95rem', fontWeight: 800, color: 'var(--fg-primary)' }}>Invite Quality Professionals</div>
          </div>
          
          <p style={{ fontSize: '0.85rem', color: 'var(--fg-secondary)', margin: 0, lineHeight: 1.5, fontWeight: 500 }}>
            Copy our professional template to invite business owners in your network to join PBN.
          </p>

          <button
            onClick={handleCopyInvitation}
            style={{
              width: '100%',
              padding: '0.75rem',
              borderRadius: '12px',
              background: 'transparent',
              border: `1.5px solid ${copySuccess ? '#34d399' : 'var(--brand-amber)'}`,
              color: copySuccess ? '#34d399' : 'var(--brand-amber)',
              fontWeight: 900,
              fontSize: '0.75rem',
              letterSpacing: '0.8px',
              cursor: 'pointer',
              display: 'flex',
              alignItems: 'center',
              justifyContent: 'center',
              gap: '8px',
              transition: 'all 0.2s',
              marginTop: 'auto'
            }}
          >
            {copySuccess ? <IconCircleCheck size={16} /> : <IconCopy size={16} />}
            {copySuccess ? 'INVITATION COPIED!' : 'COPY INVITATION TEXT'}
          </button>
        </div>

        {/* How It Works */}
        <div style={{
          background: 'var(--bg-surface)', borderRadius: '20px',
          border: '1px solid var(--border-subtle)', boxShadow: 'var(--shadow-md)',
          overflow: 'hidden'
        }}>
          {/* Step 1 */}
          <div style={{ padding: '1.15rem 1.25rem', display: 'flex', gap: '14px', alignItems: 'flex-start' }}>
            <div style={{ position: 'relative' }}>
              <div style={{ width: '36px', height: '36px', borderRadius: '10px', background: 'rgba(245, 158, 11, 0.12)', color: 'var(--brand-amber)', display: 'flex', alignItems: 'center', justifyContent: 'center', border: '1px solid rgba(245, 158, 11, 0.22)' }}>
                <IconBulb size={18} />
              </div>
              <span style={{ position: 'absolute', top: '-4px', right: '-4px', width: '16px', height: '16px', borderRadius: '50%', background: 'linear-gradient(135deg, var(--brand-amber) 0%, #C6A54C 100%)', color: '#0A2540', fontSize: '9px', fontWeight: 900, display: 'flex', alignItems: 'center', justify: 'center', border: '1px solid var(--bg-surface)', justifyContent: 'center' }}>1</span>
            </div>
            <div>
              <div style={{ fontSize: '0.88rem', fontWeight: 800, color: 'var(--fg-primary)' }}>Share a business opportunity</div>
              <div style={{ fontSize: '0.76rem', color: 'var(--fg-secondary)', marginTop: '4px', lineHeight: 1.4, fontWeight: 500 }}>Tap New Opportunity and fill in the lead so the right member can act.</div>
            </div>
          </div>

          <div style={{ height: '1px', background: 'var(--border-subtle)', marginLeft: '62px' }} />

          {/* Step 2 */}
          <div style={{ padding: '1.15rem 1.25rem', display: 'flex', gap: '14px', alignItems: 'flex-start' }}>
            <div style={{ position: 'relative' }}>
              <div style={{ width: '36px', height: '36px', borderRadius: '10px', background: 'rgba(var(--brand-blue-rgb), 0.12)', color: 'var(--brand-blue)', display: 'flex', alignItems: 'center', justifyContent: 'center', border: '1px solid rgba(var(--brand-blue-rgb), 0.22)' }}>
                <IconHistory size={18} />
              </div>
              <span style={{ position: 'absolute', top: '-4px', right: '-4px', width: '16px', height: '16px', borderRadius: '50%', background: 'linear-gradient(135deg, var(--brand-amber) 0%, #C6A54C 100%)', color: '#0A2540', fontSize: '9px', fontWeight: 900, display: 'flex', alignItems: 'center', justify: 'center', border: '1px solid var(--bg-surface)', justifyContent: 'center' }}>2</span>
            </div>
            <div>
              <div style={{ fontSize: '0.88rem', fontWeight: 800, color: 'var(--fg-primary)' }}>Track it through the stages</div>
              <div style={{ fontSize: '0.76rem', color: 'var(--fg-secondary)', marginTop: '4px', lineHeight: 1.4, fontWeight: 500 }}>Both sides update progress so the pipeline stays honest and current.</div>
            </div>
          </div>

          <div style={{ height: '1px', background: 'var(--border-subtle)', marginLeft: '62px' }} />

          {/* Step 3 */}
          <div style={{ padding: '1.15rem 1.25rem', display: 'flex', gap: '14px', alignItems: 'flex-start' }}>
            <div style={{ position: 'relative' }}>
              <div style={{ width: '36px', height: '36px', borderRadius: '10px', background: 'rgba(52, 211, 153, 0.12)', color: '#34d399', display: 'flex', alignItems: 'center', justifyContent: 'center', border: '1px solid rgba(52, 211, 153, 0.22)' }}>
                <IconTrophy size={18} />
              </div>
              <span style={{ position: 'absolute', top: '-4px', right: '-4px', width: '16px', height: '16px', borderRadius: '50%', background: 'linear-gradient(135deg, var(--brand-amber) 0%, #C6A54C 100%)', color: '#0A2540', fontSize: '9px', fontWeight: 900, display: 'flex', alignItems: 'center', justify: 'center', border: '1px solid var(--bg-surface)', justifyContent: 'center' }}>3</span>
            </div>
            <div>
              <div style={{ fontSize: '0.88rem', fontWeight: 800, color: 'var(--fg-primary)' }}>Log the ROI when it closes</div>
              <div style={{ fontSize: '0.76rem', color: 'var(--fg-secondary)', marginTop: '4px', lineHeight: 1.4, fontWeight: 500 }}>Recording value generated climbs the leaderboard and unlocks rewards.</div>
            </div>
          </div>
        </div>

      </div>

      <GiveReferralModal 
        isOpen={isGiveModalOpen} 
        onClose={() => setIsGiveModalOpen(false)} 
        onSuccess={loadData} 
      />

      <UpdateReferralModal 
        isOpen={!!updateModalData} 
        onClose={() => setUpdateModalData(null)} 
        referral={updateModalData} 
        onSuccess={loadData} 
      />
    </div>
  );
}
