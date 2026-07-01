import React, { useState, useEffect } from 'react';
import * as Ds from '../components/ui';
import { IconShare, IconBriefcase, IconChevronRight, IconPlus } from '@tabler/icons-react';
import api from '../lib/api';
import GiveReferralModal from '../components/referrals/GiveReferralModal';
import UpdateReferralModal from '../components/referrals/UpdateReferralModal';

export default function ReferralsPage() {
  const [activeTab, setActiveTab] = useState('received'); // 'received' or 'given'
  const [receivedReferrals, setReceivedReferrals] = useState([]);
  const [givenReferrals, setGivenReferrals] = useState([]);
  const [loading, setLoading] = useState(true);

  const [isGiveModalOpen, setIsGiveModalOpen] = useState(false);
  const [updateModalData, setUpdateModalData] = useState(null);

  const loadData = async () => {
    setLoading(true);
    try {
      const [resReceived, resGiven] = await Promise.all([
        api.get('/referrals/my/received'),
        api.get('/referrals/my/given')
      ]);
      setReceivedReferrals(resReceived.data?.data || resReceived.data || []);
      setGivenReferrals(resGiven.data?.data || resGiven.data || []);
    } catch (err) {
      console.error('Failed to load referrals', err);
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
      return dt.toLocaleDateString('en-US', { day: 'numeric', month: 'short' }).toUpperCase();
    } catch (e) {
      return iso;
    }
  };

  const getStatusColor = (status) => {
    switch (status) {
      case 'NEW': return { bg: 'var(--brand-yellow-50)', fg: 'var(--brand-yellow-700)', border: 'var(--brand-yellow-200)' };
      case 'CONTACTED': return { bg: 'var(--brand-blue-50)', fg: 'var(--brand-blue-600)', border: 'var(--brand-blue-200)' };
      case 'IN_PROGRESS': return { bg: 'var(--brand-purple-50)', fg: 'var(--brand-purple-600)', border: 'var(--brand-purple-200)' };
      case 'CLOSED_WON': return { bg: 'var(--brand-green-50)', fg: 'var(--brand-green-700)', border: 'var(--brand-green-200)' };
      case 'CLOSED_LOST': return { bg: 'var(--brand-red-50)', fg: 'var(--brand-red-600)', border: 'var(--brand-red-200)' };
      default: return { bg: 'var(--bg-subtle)', fg: 'var(--fg-secondary)', border: 'var(--border-color)' };
    }
  };

  const renderCard = (ref, isReceived) => {
    const colors = getStatusColor(ref.status);
    return (
      <div 
        key={ref.id} 
        style={{
          background: 'var(--bg-surface)',
          borderRadius: '16px',
          border: '1px solid var(--border-color)',
          padding: '1.5rem',
          marginBottom: '1rem',
          display: 'flex',
          gap: '1rem',
          alignItems: 'flex-start',
          cursor: isReceived ? 'pointer' : 'default',
          transition: 'all 0.2s ease',
          boxShadow: 'var(--shadow-sm)'
        }}
        onClick={() => isReceived && setUpdateModalData(ref)}
        className={isReceived ? 'ds-list-item-hover' : ''}
      >
        <div style={{
          width: 48, height: 48, borderRadius: '12px',
          background: `rgba(var(--brand-blue-rgb), 0.1)`,
          display: 'flex', alignItems: 'center', justifyContent: 'center',
          color: 'var(--brand-blue)'
        }}>
          <IconBriefcase size={24} />
        </div>
        <div style={{ flex: 1 }}>
          <div style={{ fontSize: '1.1rem', fontWeight: 700, color: 'var(--fg-primary)' }}>{ref.lead_name}</div>
          <div style={{ fontSize: 'var(--text-sm)', color: 'var(--fg-secondary)', marginTop: '0.25rem' }}>
            {isReceived ? `From: ${ref.from_user?.full_name}` : `To: ${ref.target_user?.full_name}`}
          </div>
          <div style={{ marginTop: '0.75rem', display: 'flex', alignItems: 'center', gap: '0.5rem' }}>
            <span style={{
              background: colors.bg, color: colors.fg, border: `1px solid ${colors.border}`,
              padding: '0.25rem 0.75rem', borderRadius: '100px', fontSize: 'var(--text-xs)', fontWeight: 800, letterSpacing: '0.5px'
            }}>
              {ref.status.replace('_', ' ')}
            </span>
          </div>
        </div>
        <div style={{ display: 'flex', flexDirection: 'column', alignItems: 'flex-end', justifyContent: 'space-between', height: '100%' }}>
          {isReceived && <IconChevronRight size={20} color="var(--fg-muted)" />}
          {!isReceived && <div style={{ height: 20 }}></div>}
          <div style={{ fontSize: 'var(--text-xs)', fontWeight: 700, color: 'var(--fg-muted)', marginTop: '1.5rem' }}>
            {formatDate(ref.created_at)}
          </div>
        </div>
      </div>
    );
  };

  const currentList = activeTab === 'received' ? receivedReferrals : givenReferrals;

  return (
    <div className="dashboard-body" style={{ maxWidth: '1000px', margin: '0 auto', paddingBottom: '3rem' }}>
      <div style={{ display: 'flex', justifyContent: 'space-between', alignItems: 'flex-start', marginBottom: '2rem' }}>
        <Ds.PageHeader
          title="Referrals"
          description="Track and manage business opportunities you have sent or received."
        />
        <Ds.Button variant="primary" leftIcon={<IconPlus size={16} />} onClick={() => setIsGiveModalOpen(true)}>
          New Opportunity
        </Ds.Button>
      </div>

      <div style={{ display: 'flex', gap: '1rem', marginBottom: '2rem', borderBottom: '1px solid var(--border-color)' }}>
        <button
          onClick={() => setActiveTab('received')}
          style={{
            background: 'transparent', border: 'none', padding: '1rem 1.5rem',
            fontSize: 'var(--text-md)', fontWeight: activeTab === 'received' ? 700 : 500,
            color: activeTab === 'received' ? 'var(--brand-blue)' : 'var(--fg-secondary)',
            borderBottom: activeTab === 'received' ? '3px solid var(--brand-blue)' : '3px solid transparent',
            cursor: 'pointer'
          }}
        >
          Received Opportunities ({receivedReferrals.length})
        </button>
        <button
          onClick={() => setActiveTab('given')}
          style={{
            background: 'transparent', border: 'none', padding: '1rem 1.5rem',
            fontSize: 'var(--text-md)', fontWeight: activeTab === 'given' ? 700 : 500,
            color: activeTab === 'given' ? 'var(--brand-blue)' : 'var(--fg-secondary)',
            borderBottom: activeTab === 'given' ? '3px solid var(--brand-blue)' : '3px solid transparent',
            cursor: 'pointer'
          }}
        >
          Given Opportunities ({givenReferrals.length})
        </button>
      </div>

      {loading ? (
        <div style={{ padding: '4rem', textAlign: 'center', color: 'var(--fg-secondary)' }}>
          Loading referrals...
        </div>
      ) : currentList.length === 0 ? (
        <Ds.EmptyState 
          icon={IconShare}
          title={activeTab === 'received' ? "No referrals yet" : "You haven't given any referrals yet"} 
          description={activeTab === 'received' 
            ? "When members refer leads to you, they'll appear here." 
            : "Refer a lead to a fellow member to start growing your chapter's business."} 
        />
      ) : (
        <div>
          {currentList.map(ref => renderCard(ref, activeTab === 'received'))}
        </div>
      )}

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
