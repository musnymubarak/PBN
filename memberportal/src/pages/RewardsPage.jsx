import React, { useState, useEffect } from 'react';
import * as Ds from '../components/ui';
import { 
  IconAward, 
  IconStar, 
  IconTicket, 
  IconAlertTriangle, 
  IconCalendar, 
  IconUsers, 
  IconSearch, 
  IconDeviceMobile,
  IconCopy,
  IconClock,
  IconChevronRight
} from '@tabler/icons-react';
import api from '../lib/api';
import RewardDetailsModal from '../components/rewards/RewardDetailsModal';

export default function RewardsPage() {
  const [selectedTab, setSelectedTab] = useState('available'); // 'available' or 'redeemed'
  const [card, setCard] = useState(null);
  const [partners, setPartners] = useState([]);
  const [loading, setLoading] = useState(true);
  const [loadError, setLoadError] = useState(false);

  const [selectedOffer, setSelectedOffer] = useState(null);
  const [selectedPartner, setSelectedPartner] = useState(null);

  const loadData = async () => {
    setLoading(true);
    setLoadError(false);
    try {
      const [resCard, resPartners] = await Promise.all([
        api.get('/rewards/my-card').catch(() => ({ data: { data: null } })),
        api.get('/rewards/partners')
      ]);
      setCard(resCard.data?.data || resCard.data || null);
      setPartners(resPartners.data?.data || resPartners.data || []);
    } catch (err) {
      console.error('Failed to load rewards data', err);
      setLoadError(true);
    } finally {
      setLoading(false);
    }
  };

  useEffect(() => {
    loadData();
  }, []);

  // Compute stats
  const points = card?.points || 0;
  const tier = (card?.tier || card?.membership_type || 'standard').toLowerCase();
  
  // Flatten all offers
  const allOffers = [];
  partners.forEach(partner => {
    (partner.offers || []).forEach(offer => {
      allOffers.push({ ...offer, partner });
    });
  });

  const availableOffers = allOffers.filter(o => !o.is_redeemed_by_me);
  const redeemedOffers = allOffers.filter(o => o.is_redeemed_by_me);

  const activeList = selectedTab === 'available' ? availableOffers : redeemedOffers;

  // Digital Privilege Card tier styles
  const getCardStyle = () => {
    switch (tier) {
      case 'gold':
        return {
          background: 'linear-gradient(135deg, #BF953F 0%, #FCF6BA 25%, #B38728 50%, #FBF5B7 75%, #AA771C 100%)',
          color: '#0A2540',
          border: '1px solid #D4AF37',
          shadow: '0 15px 30px rgba(179, 135, 40, 0.35)',
          label: 'PBN GOLD MEMBER',
          textMuted: 'rgba(10, 37, 64, 0.7)'
        };
      case 'platinum':
        return {
          background: 'linear-gradient(135deg, #E5E4E2 0%, #F5F5F5 50%, #BCC6CC 100%)',
          color: '#0A2540',
          border: '1px solid #BCC6CC',
          shadow: '0 15px 30px rgba(188, 198, 204, 0.35)',
          label: 'PBN PLATINUM MEMBER',
          textMuted: 'rgba(10, 37, 64, 0.7)'
        };
      case 'vip':
        return {
          background: 'linear-gradient(135deg, #2B0B3F 0%, #7624B5 50%, #150521 100%)',
          color: 'white',
          border: '1px solid #7624B5',
          shadow: '0 15px 30px rgba(118, 36, 181, 0.35)',
          label: 'PBN VIP CHARTER MEMBER',
          textMuted: 'rgba(255, 255, 255, 0.7)'
        };
      default:
        return {
          background: 'linear-gradient(135deg, #0A2540 0%, #102E55 100%)',
          color: 'white',
          border: '1px solid rgba(255, 255, 255, 0.1)',
          shadow: '0 15px 30px rgba(10, 37, 64, 0.35)',
          label: 'PBN MEMBER',
          textMuted: 'rgba(255, 255, 255, 0.7)'
        };
    }
  };

  const cardStyle = getCardStyle();

  return (
    <div className="dashboard-body" style={{ position: 'relative', paddingBottom: '4rem' }}>
      
      {/* Title Header */}
      <div style={{ display: 'flex', justifyContent: 'space-between', alignItems: 'flex-start', marginBottom: '1.5rem' }}>
        <Ds.PageHeader
          title="Rewards & Privileges"
          description="Access members-only rewards and track your points."
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

      {/* Hero Banner Grid (Privilege Card Mockup on Right) */}
      <div className="event-hero-v3" style={{ display: 'flex', flexWrap: 'wrap', alignItems: 'center', gap: '2rem', minHeight: '240px' }}>
        {/* Left Side */}
        <div style={{ flex: '1 1 300px', display: 'flex', flexDirection: 'column', gap: '0.5rem' }}>
          <div style={{ display: 'flex', alignItems: 'center', gap: '8px' }}>
            <IconAward size={20} style={{ color: 'var(--brand-amber)' }} />
            <span style={{ fontSize: '0.7rem', fontWeight: 900, color: 'var(--brand-amber)', letterSpacing: '0.15em' }}>PBN PRIVILEGES</span>
          </div>
          <h3 style={{ fontSize: '1.6rem', fontWeight: 900, color: 'white', letterSpacing: '-0.02em', margin: '4px 0 0 0' }}>
            Exclusive Member Benefits
          </h3>
          <p style={{ color: 'rgba(255,255,255,0.85)', fontSize: '0.9rem', margin: '4px 0 10px 0', fontWeight: 600 }}>
            Present your virtual card at participating partner outlets to claim your privileges.
          </p>

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
            <IconTicket size={12} />
            {allOffers.length} Active Rewards Available
          </div>
        </div>

        {/* Right Side - Digital Card Mockup */}
        <div style={{ 
          flex: '0 0 340px', 
          height: '190px', 
          background: cardStyle.background,
          color: cardStyle.color,
          border: cardStyle.border,
          boxShadow: cardStyle.shadow,
          borderRadius: '20px',
          padding: '1.25rem',
          display: 'flex',
          flexDirection: 'column',
          justifyContent: 'space-between',
          position: 'relative',
          overflow: 'hidden'
        }}>
          {/* Card Accent Shapes */}
          <div style={{
            position: 'absolute', top: '-20px', right: '-20px', width: '120px', height: '120px',
            borderRadius: '50%', background: 'rgba(255,255,255,0.06)'
          }} />

          {/* Card Header */}
          <div style={{ display: 'flex', justifyContent: 'space-between', alignItems: 'center' }}>
            <div>
              <div style={{ fontSize: '1.05rem', fontWeight: 900, letterSpacing: '-0.02em', color: cardStyle.color }}>
                Prime <span style={{ color: 'var(--brand-amber)' }}>Business</span> Network
              </div>
              <div style={{ fontSize: '0.55rem', fontWeight: 700, letterSpacing: '0.5px', marginTop: '2px', color: cardStyle.textMuted }}>
                {cardStyle.label}
              </div>
            </div>
            {/* Gold EMV Chip Mockup */}
            <div style={{
              width: '36px',
              height: '26px',
              background: 'linear-gradient(135deg, #fef08a 0%, #ca8a04 100%)',
              borderRadius: '6px',
              position: 'relative',
              overflow: 'hidden',
              boxShadow: 'inset 0 1px 0 rgba(255,255,255,0.4), 0 2px 4px rgba(0,0,0,0.15)'
            }}>
              {/* EMV Grid Lines */}
              <div style={{
                position: 'absolute', inset: 0,
                backgroundImage: 'radial-gradient(rgba(0,0,0,0.15) 1px, transparent 1px)',
                backgroundSize: '6px 6px',
                opacity: 0.8
              }} />
            </div>
          </div>

          {/* Card Middle - Card Number */}
          <div style={{ 
            fontSize: '1.2rem', 
            fontWeight: 700, 
            letterSpacing: '3px', 
            fontFamily: 'monospace',
            margin: '0.5rem 0'
          }}>
            {card?.card_number || '•••• •••• •••• ••••'}
          </div>

          {/* Card Footer */}
          <div style={{ display: 'flex', justifyContent: 'space-between', alignItems: 'flex-end' }}>
            <div>
              <div style={{ fontSize: '0.55rem', color: cardStyle.textMuted, fontWeight: 800, textTransform: 'uppercase', letterSpacing: '0.5px' }}>
                {tier === 'charter' ? 'CHARTER MEMBER' : 'PREMIUM MEMBER'}
              </div>
              <div style={{ fontSize: '1.15rem', fontWeight: 900, marginTop: '2px' }}>
                {card?.member_name || 'Verified PBN Member'}
              </div>
            </div>
            
            {/* Gold Tier Badge */}
            <div style={{
              padding: '6px 14px',
              background: tier === 'gold' || tier === 'platinum' ? '#0e1535' : 'linear-gradient(135deg, #FFEAB2 0%, var(--brand-amber) 100%)',
              color: tier === 'gold' || tier === 'platinum' ? 'var(--brand-amber)' : '#0e1535',
              borderRadius: '20px',
              fontSize: '0.65rem',
              fontWeight: 900,
              letterSpacing: '0.5px',
              boxShadow: '0 4px 10px rgba(0,0,0,0.15)',
              textTransform: 'uppercase'
            }}>
              {tier === 'charter' ? 'FOUNDING' : (tier || 'MEMBER')}
            </div>
          </div>
        </div>
      </div>

      {/* Stats Counter Row (styled like Event stats) */}
      <div className="event-stats-v3">
        <div className="event-stat-card-v3">
          <div className="event-stat-icon-v3" style={{ background: 'rgba(52, 211, 153, 0.1)', color: '#34d399' }}>
            <IconStar size={18} />
          </div>
          <div className="event-stat-info-v3">
            <span className="event-stat-val-v3">{points}</span>
            <span className="event-stat-lbl-v3">Points Balance</span>
          </div>
        </div>
        
        <div className="event-stat-card-v3">
          <div className="event-stat-icon-v3" style={{ background: 'var(--brand-amber-50)', color: 'var(--brand-amber)' }}>
            <IconAward size={18} />
          </div>
          <div className="event-stat-info-v3">
            <span className="event-stat-val-v3" style={{ textTransform: 'capitalize' }}>{tier}</span>
            <span className="event-stat-lbl-v3">Privilege Tier</span>
          </div>
        </div>

        <div className="event-stat-card-v3">
          <div className="event-stat-icon-v3" style={{ background: 'var(--brand-blue-50)', color: 'var(--brand-blue)' }}>
            <IconTicket size={18} />
          </div>
          <div className="event-stat-info-v3">
            <span className="event-stat-val-v3">{allOffers.length}</span>
            <span className="event-stat-lbl-v3">Active Offers</span>
          </div>
        </div>
      </div>

      {/* Tab Controller Bar (styled like Event tabs) */}
      <div className="events-tabs-v3" style={{ marginBottom: '2rem' }}>
        <button 
          className={`event-tab-btn-v3 ${selectedTab === 'available' ? 'is-active' : ''}`}
          onClick={() => setSelectedTab('available')}
        >
          Available Rewards ({availableOffers.length})
        </button>
        <button 
          className={`event-tab-btn-v3 ${selectedTab === 'redeemed' ? 'is-active' : ''}`}
          onClick={() => setSelectedTab('redeemed')}
        >
          My Redemptions ({redeemedOffers.length})
        </button>
      </div>

      {/* main rewards grid */}
      {loading ? (
        <div style={{ padding: '6rem', textAlign: 'center', color: 'var(--fg-secondary)', fontWeight: 600 }}>
          Loading rewards...
        </div>
      ) : activeList.length === 0 ? (
        <div style={{ marginTop: '1rem' }}>
          <Ds.EmptyState 
            icon={IconAward}
            title={selectedTab === 'available' ? "No rewards available" : "You haven't redeemed any rewards yet"} 
            description={selectedTab === 'available' 
              ? "Check back later for new exclusive B2B partner discounts." 
              : "Redeem partner coupon codes online or scan QR codes in mobile app."} 
          />
        </div>
      ) : (
        <div style={{ 
          display: 'grid', 
          gridTemplateColumns: 'repeat(auto-fill, minmax(280px, 1fr))', 
          gap: '1.25rem',
          marginBottom: '3rem'
        }}>
          {activeList.map(offer => {
            const partner = offer.partner;
            const coverImage = partner.logo_url || 'https://images.unsplash.com/photo-1549465220-1a8b9238cd48?auto=format&fit=crop&q=80&w=300';
            
            return (
              <div 
                key={offer.id}
                className="event-card-v3"
                onClick={() => {
                  setSelectedOffer(offer);
                  setSelectedPartner(partner);
                }}
                style={{ cursor: 'pointer', display: 'flex', flexDirection: 'column' }}
              >
                {/* Media Logo Card Cover */}
                <div style={{
                  height: '130px',
                  background: 'white',
                  display: 'flex',
                  alignItems: 'center',
                  justifyContent: 'center',
                  borderTopLeftRadius: '16px',
                  borderTopRightRadius: '16px',
                  position: 'relative',
                  borderBottom: '1px solid var(--border-subtle)'
                }}>
                  <img src={coverImage} alt={partner.name} style={{ width: '80%', height: '80%', objectFit: 'contain' }} />
                  
                  {/* Discount percentage Overlay */}
                  {offer.discount_percentage && (
                    <div style={{
                      position: 'absolute',
                      top: '12px',
                      right: '12px',
                      background: 'linear-gradient(135deg, var(--brand-amber) 0%, #C6A54C 100%)',
                      color: '#0A2540',
                      fontSize: '10px',
                      fontWeight: 950,
                      padding: '4px 10px',
                      borderRadius: '8px',
                      boxShadow: '0 4px 10px rgba(198, 165, 76, 0.25)'
                    }}>
                      {offer.discount_percentage}% OFF
                    </div>
                  )}
                </div>

                {/* Body Details */}
                <div style={{ padding: '1.25rem', display: 'flex', flexDirection: 'column', flex: 1 }}>
                  <div style={{ display: 'flex', alignItems: 'center', gap: '4px', color: 'var(--brand-amber)', fontSize: '0.75rem', fontWeight: 800 }}>
                    <IconAward size={12} />
                    {partner.name}
                  </div>

                  <h4 style={{ fontSize: '1.02rem', fontWeight: 900, color: 'var(--fg-primary)', margin: '0.5rem 0', lineHeight: 1.3 }}>
                    {offer.title}
                  </h4>

                  {offer.description && (
                    <p style={{ color: 'var(--fg-muted)', fontSize: '0.8125rem', lineHeight: 1.4, margin: '0 0 1rem 0' }}>
                      {offer.description.length > 70 ? `${offer.description.substring(0, 70)}...` : offer.description}
                    </p>
                  )}

                  {/* Card Footer redemption type & action */}
                  <div style={{ 
                    display: 'flex', 
                    alignItems: 'center', 
                    justifyContent: 'space-between', 
                    marginTop: 'auto',
                    borderTop: '1px solid var(--border-subtle)',
                    paddingTop: '0.75rem'
                  }}>
                    <span style={{ fontSize: '0.72rem', fontWeight: 800, color: 'var(--fg-muted)', display: 'flex', alignItems: 'center', gap: '4px', textTransform: 'uppercase' }}>
                      <IconDeviceMobile size={14} />
                      {offer.redemption_method || 'qr'}
                    </span>
                    <span style={{ display: 'flex', alignItems: 'center', gap: '2px', color: 'var(--brand-blue)', fontSize: '0.75rem', fontWeight: 900 }}>
                      VIEW REWARD
                      <IconChevronRight size={14} />
                    </span>
                  </div>
                </div>

              </div>
            );
          })}
        </div>
      )}

      <RewardDetailsModal 
        isOpen={!!selectedOffer}
        onClose={() => {
          setSelectedOffer(null);
          setSelectedPartner(null);
        }}
        offer={selectedOffer}
        partner={selectedPartner}
        onSuccess={loadData}
      />
      
    </div>
  );
}
