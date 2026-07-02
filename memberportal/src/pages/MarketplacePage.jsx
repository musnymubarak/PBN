import React, { useState, useEffect } from 'react';
import * as Ds from '../components/ui';
import { 
  IconShoppingCart, 
  IconStar, 
  IconUserCheck, 
  IconSearch, 
  IconPlus, 
  IconX, 
  IconChevronRight, 
  IconAlertTriangle, 
  IconPackage, 
  IconTool, 
  IconHeadset, 
  IconClock, 
  IconUsers,
  IconApps,
  IconCoin,
  IconMessageCircle
} from '@tabler/icons-react';
import api from '../lib/api';
import CreateListingModal from '../components/marketplace/CreateListingModal';
import MarketplaceDetailsModal from '../components/marketplace/MarketplaceDetailsModal';

export default function MarketplacePage() {
  const [selectedTab, setSelectedTab] = useState('browse'); // 'browse' or 'my'
  const [listings, setListings] = useState([]);
  const [featuredListings, setFeaturedListings] = useState([]);
  const [myListings, setMyListings] = useState([]);
  const [loading, setLoading] = useState(true);
  const [loadError, setLoadError] = useState(false);

  const [activeCategory, setActiveCategory] = useState(null); // null (all), 'product', 'service', 'consultation'
  const [searchQuery, setSearchQuery] = useState('');
  
  const [isCreateOpen, setIsCreateOpen] = useState(false);
  const [selectedListing, setSelectedListing] = useState(null);
  const [editListingData, setEditListingData] = useState(null);

  const loadData = async () => {
    setLoading(true);
    setLoadError(false);
    try {
      const params = {};
      if (searchQuery.trim()) params.search = searchQuery.trim();
      if (activeCategory) params.category = activeCategory;

      const [resListings, resFeatured, resMy] = await Promise.all([
        api.get('/marketplace/listings', { params }),
        api.get('/marketplace/listings', { params: { featured_only: true, limit: 5 } }),
        api.get('/marketplace/listings', { params: { my: true } }).catch(() => ({ data: [] }))
      ]);

      setListings(resListings.data || []);
      setFeaturedListings(resFeatured.data || []);
      setMyListings(resMy.data || []);
    } catch (err) {
      console.error('Failed to load marketplace listings', err);
      setLoadError(true);
    } finally {
      setLoading(false);
    }
  };

  useEffect(() => {
    loadData();
  }, [activeCategory, searchQuery]);

  const getCategoryIcon = (cat) => {
    switch (cat) {
      case 'product': return <IconPackage size={14} />;
      case 'service': return <IconTool size={14} />;
      case 'consultation': return <IconHeadset size={14} />;
      default: return <IconPackage size={14} />;
    }
  };

  const currentList = selectedTab === 'browse' ? listings : myListings;

  return (
    <div className="dashboard-body" style={{ position: 'relative', paddingBottom: '4rem' }}>
      
      {/* Title Header */}
      <div style={{ display: 'flex', justifyContent: 'space-between', alignItems: 'flex-start', marginBottom: '1.5rem' }}>
        <Ds.PageHeader
          title="Marketplace"
          description="Exclusive deals and B2B offers posted by verified PBN members."
        />
        <Ds.Button 
          variant="primary" 
          leftIcon={<IconPlus size={16} />} 
          onClick={() => {
            setEditListingData(null);
            setIsCreateOpen(true);
          }}
        >
          Post an Offer
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
            <IconShoppingCart size={20} style={{ color: 'var(--brand-amber)' }} />
            <span style={{ fontSize: '0.7rem', fontWeight: 900, color: 'var(--brand-amber)', letterSpacing: '0.15em' }}>MEMBER EXCLUSIVE</span>
          </div>
          <h3 style={{ fontSize: '1.6rem', fontWeight: 900, color: 'white', letterSpacing: '-0.02em', margin: '4px 0 0 0' }}>
            B2B Member Offers
          </h3>
          <p style={{ color: 'rgba(255,255,255,0.85)', fontSize: '0.9rem', margin: '4px 0 10px 0', fontWeight: 600 }}>
            Post offers, generate deals, and log business ROI value directly.
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
            <IconUserCheck size={12} />
            {myListings.length} Active Offers Posted
          </div>
        </div>
      </div>

      {/* Stats Counter Row (styled like Event stats) */}
      <div className="event-stats-v3">
        <div className="event-stat-card-v3">
          <div className="event-stat-icon-v3" style={{ background: 'rgba(52, 211, 153, 0.1)', color: '#34d399' }}>
            <IconShoppingCart size={18} />
          </div>
          <div className="event-stat-info-v3">
            <span className="event-stat-val-v3">{listings.length}</span>
            <span className="event-stat-lbl-v3">Total Offers</span>
          </div>
        </div>
        
        <div className="event-stat-card-v3">
          <div className="event-stat-icon-v3" style={{ background: 'var(--brand-amber-50)', color: 'var(--brand-amber)' }}>
            <IconStar size={18} />
          </div>
          <div className="event-stat-info-v3">
            <span className="event-stat-val-v3">{featuredListings.length}</span>
            <span className="event-stat-lbl-v3">Featured</span>
          </div>
        </div>

        <div className="event-stat-card-v3">
          <div className="event-stat-icon-v3" style={{ background: 'var(--brand-blue-50)', color: 'var(--brand-blue)' }}>
            <IconUserCheck size={18} />
          </div>
          <div className="event-stat-info-v3">
            <span className="event-stat-val-v3">{myListings.length}</span>
            <span className="event-stat-lbl-v3">Your Offers</span>
          </div>
        </div>
      </div>

      {/* Tab Controller Bar (styled like Event tabs) */}
      <div className="events-tabs-v3" style={{ marginBottom: '1.5rem' }}>
        <button 
          className={`event-tab-btn-v3 ${selectedTab === 'browse' ? 'is-active' : ''}`}
          onClick={() => setSelectedTab('browse')}
        >
          Browse Marketplace
        </button>
        <button 
          className={`event-tab-btn-v3 ${selectedTab === 'my' ? 'is-active' : ''}`}
          onClick={() => setSelectedTab('my')}
        >
          My Listings ({myListings.length})
        </button>
      </div>

      {/* Filters Search & Category Chips */}
      {selectedTab === 'browse' && (
        <div style={{ display: 'flex', flexDirection: 'column', gap: '1rem', marginBottom: '2rem' }}>
          {/* Search Input bar */}
          <div style={{ position: 'relative', width: '100%' }}>
            <div style={{ position: 'absolute', left: '1rem', top: '50%', transform: 'translateY(-50%)', color: 'var(--fg-muted)' }}>
              <IconSearch size={18} />
            </div>
            <input 
              type="text" 
              placeholder="Search B2B offers by title, seller, or description..."
              value={searchQuery}
              onChange={(e) => setSearchQuery(e.target.value)}
              style={{
                width: '100%',
                padding: '0.85rem 1rem 0.85rem 2.75rem',
                borderRadius: '16px',
                border: '1px solid var(--border-subtle)',
                background: 'var(--bg-surface)',
                color: 'var(--fg-primary)',
                fontWeight: 600,
                fontSize: '0.9rem',
                boxShadow: 'var(--shadow-sm)'
              }}
            />
            {searchQuery && (
              <button 
                onClick={() => setSearchQuery('')}
                style={{ position: 'absolute', right: '1rem', top: '50%', transform: 'translateY(-50%)', background: 'none', border: 'none', color: 'var(--fg-muted)', cursor: 'pointer' }}
              >
                <IconX size={16} />
              </button>
            )}
          </div>

          {/* Category Chips list */}
          <div style={{ display: 'flex', gap: '0.5rem', overflowX: 'auto', paddingBottom: '4px' }}>
            <button
              onClick={() => setActiveCategory(null)}
              style={{
                background: activeCategory === null ? 'var(--brand-amber)' : 'var(--bg-surface)',
                border: `1.5px solid ${activeCategory === null ? 'var(--brand-amber)' : 'var(--border-subtle)'}`,
                color: activeCategory === null ? 'white' : 'var(--fg-secondary)',
                borderRadius: '12px', padding: '0.5rem 1rem', fontSize: '0.8rem', fontWeight: 800,
                cursor: 'pointer', display: 'flex', alignItems: 'center', gap: '6px', transition: 'all 0.15s'
              }}
            >
              <IconApps size={14} />
              All Category
            </button>

            <button
              onClick={() => setActiveCategory('product')}
              style={{
                background: activeCategory === 'product' ? 'var(--brand-amber)' : 'var(--bg-surface)',
                border: `1.5px solid ${activeCategory === 'product' ? 'var(--brand-amber)' : 'var(--border-subtle)'}`,
                color: activeCategory === 'product' ? 'white' : 'var(--fg-secondary)',
                borderRadius: '12px', padding: '0.5rem 1rem', fontSize: '0.8rem', fontWeight: 800,
                cursor: 'pointer', display: 'flex', alignItems: 'center', gap: '6px', transition: 'all 0.15s'
              }}
            >
              <IconPackage size={14} />
              Products
            </button>

            <button
              onClick={() => setActiveCategory('service')}
              style={{
                background: activeCategory === 'service' ? 'var(--brand-amber)' : 'var(--bg-surface)',
                border: `1.5px solid ${activeCategory === 'service' ? 'var(--brand-amber)' : 'var(--border-subtle)'}`,
                color: activeCategory === 'service' ? 'white' : 'var(--fg-secondary)',
                borderRadius: '12px', padding: '0.5rem 1rem', fontSize: '0.8rem', fontWeight: 800,
                cursor: 'pointer', display: 'flex', alignItems: 'center', gap: '6px', transition: 'all 0.15s'
              }}
            >
              <IconTool size={14} />
              Services
            </button>

            <button
              onClick={() => setActiveCategory('consultation')}
              style={{
                background: activeCategory === 'consultation' ? 'var(--brand-amber)' : 'var(--bg-surface)',
                border: `1.5px solid ${activeCategory === 'consultation' ? 'var(--brand-amber)' : 'var(--border-subtle)'}`,
                color: activeCategory === 'consultation' ? 'white' : 'var(--fg-secondary)',
                borderRadius: '12px', padding: '0.5rem 1rem', fontSize: '0.8rem', fontWeight: 800,
                cursor: 'pointer', display: 'flex', alignItems: 'center', gap: '6px', transition: 'all 0.15s'
              }}
            >
              <IconHeadset size={14} />
              Consultations
            </button>
          </div>
        </div>
      )}

      {/* listings list */}
      {loading ? (
        <div style={{ padding: '6rem', textAlign: 'center', color: 'var(--fg-secondary)', fontWeight: 600 }}>
          Loading listings...
        </div>
      ) : currentList.length === 0 ? (
        <div style={{ marginTop: '1rem' }}>
          <Ds.EmptyState 
            icon={IconShoppingCart}
            title={selectedTab === 'browse' ? "No B2B offers match" : "You haven't posted any offers"} 
            description={selectedTab === 'browse' 
              ? "Try adjusting your category filter chips or type a different search."
              : "Generate business leads by posting your first service or product offer."} 
          />
        </div>
      ) : (
        <div style={{ 
          display: 'grid', 
          gridTemplateColumns: 'repeat(auto-fill, minmax(280px, 1fr))', 
          gap: '1.25rem',
          marginTop: '1rem',
          marginBottom: '3rem'
        }}>
          {currentList.map(item => {
            const coverImage = item.image_urls?.[0] || 'https://images.unsplash.com/photo-1472851294608-062f824d296e?auto=format&fit=crop&q=80&w=800';
            
            return (
              <div 
                key={item.id}
                className="event-card-v3"
                onClick={() => setSelectedListing(item)}
                style={{ cursor: 'pointer', display: 'flex', flexDirection: 'column' }}
              >
                {/* Media Image wrap */}
                <div className="event-card-img-wrap-v3" style={{ height: '140px' }}>
                  <img src={coverImage} alt={item.title} className="event-card-img-v3" />
                  
                  {/* Category Pill Overlay */}
                  <div className="event-type-pill-v3" style={{ color: 'var(--brand-amber)' }}>
                    {getCategoryIcon(item.category)}
                    {item.category.toUpperCase()}
                  </div>

                  {item.is_featured && (
                    <div className="event-fee-pill-v3" style={{ background: 'var(--brand-amber)', color: 'white' }}>
                      <IconStar size={12} />
                      FEATURED
                    </div>
                  )}
                </div>

                {/* Details Body */}
                <div style={{ padding: '1.25rem', display: 'flex', flexDirection: 'column', flex: 1 }}>
                  <div style={{ display: 'flex', alignItems: 'center', gap: '4px', color: 'var(--brand-amber)', fontSize: '0.75rem', fontWeight: 800 }}>
                    <IconPackage size={12} />
                    {item.industry_name || 'B2B Offer'}
                  </div>

                  <h4 style={{ fontSize: '1.05rem', fontWeight: 900, color: 'var(--fg-primary)', margin: '0.5rem 0', lineHeight: 1.3 }}>
                    {item.title}
                  </h4>

                  <div style={{ display: 'flex', alignItems: 'center', gap: '8px', color: 'var(--fg-secondary)', fontSize: '0.8rem', fontWeight: 700, margin: '4px 0 8px 0' }}>
                    <IconUsers size={14} style={{ color: 'var(--brand-blue)' }} />
                    <span style={{ overflow: 'hidden', textOverflow: 'ellipsis', whiteSpace: 'nowrap' }}>
                      {item.seller_name || 'Verified Member'}
                    </span>
                  </div>

                  {/* Price chart */}
                  <div style={{ display: 'flex', flexWrap: 'wrap', gap: '8px', margin: '4px 0 10px 0' }}>
                    <span style={{ fontSize: '0.75rem', color: 'var(--fg-muted)', textDecoration: item.member_price ? 'line-through' : 'none' }}>
                      {item.regular_price ? `LKR ${Number(item.regular_price).toLocaleString()}` : ''}
                    </span>
                    <span style={{ fontSize: '0.78rem', color: '#34d399', fontWeight: 900 }}>
                      {item.member_price ? `LKR ${Number(item.member_price).toLocaleString()} (Member)` : 'Free'}
                    </span>
                  </div>

                  {item.description && (
                    <p style={{ color: 'var(--fg-muted)', fontSize: '0.8125rem', lineHeight: 1.4, margin: '0 0 1rem 0' }}>
                      {item.description.length > 70 ? `${item.description.substring(0, 70)}...` : item.description}
                    </p>
                  )}

                  {/* Card Footer Inquiry tracker */}
                  <div style={{ 
                    display: 'flex', 
                    alignItems: 'center', 
                    justifyContent: 'space-between', 
                    marginTop: 'auto',
                    borderTop: '1px solid var(--border-subtle)',
                    paddingTop: '0.75rem'
                  }}>
                    <span style={{ fontSize: '0.75rem', fontWeight: 800, color: 'var(--fg-muted)', display: 'flex', alignItems: 'center', gap: '4px' }}>
                      <IconMessageCircle size={14} />
                      {item.interest_count || 0} inquiries
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

      {/* Disclaimers footnote */}
      <div style={{
        marginTop: '2rem', padding: '1rem', background: 'var(--bg-surface)', border: '1px solid var(--border-subtle)',
        borderRadius: '16px', color: 'var(--fg-muted)', fontSize: '0.75rem', lineHeight: 1.5, textAlign: 'center'
      }}>
        <strong>Disclaimer:</strong> Prime Business Network (PBN) provides the B2B marketplace platform for convenience and B2B connectivity only. PBN does not verify, warrant, or assume responsibility for any product quality, deal negotiations, financial terms, or transactions made between members.
      </div>

      <CreateListingModal 
        isOpen={isCreateOpen}
        onClose={() => setIsCreateOpen(false)}
        listing={editListingData}
        onSuccess={loadData}
      />

      <MarketplaceDetailsModal 
        isOpen={!!selectedListing}
        onClose={() => setSelectedListing(null)}
        listing={selectedListing}
        onEdit={() => {
          setEditListingData(selectedListing);
          setSelectedListing(null);
          setIsCreateOpen(true);
        }}
        onSuccess={loadData}
      />

    </div>
  );
}
