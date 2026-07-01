import React, { useState, useEffect } from 'react';
import * as Ds from '../ui';
import { 
  IconX, 
  IconCheck, 
  IconPhone, 
  IconMail, 
  IconBrandWhatsapp, 
  IconCoin, 
  IconMessageCircle, 
  IconEdit, 
  IconTrash, 
  IconStar, 
  IconExternalLink,
  IconArrowRight
} from '@tabler/icons-react';
import { useAuth } from '../../context/AuthContext';
import api from '../../lib/api';

export default function MarketplaceDetailsModal({ isOpen, onClose, listing, onEdit, onSuccess }) {
  const { user } = useAuth();
  
  const [inquiries, setInquiries] = useState([]);
  const [loadingInquiries, setLoadingInquiries] = useState(false);
  const [interestMsg, setInterestMsg] = useState('I am interested in this B2B offer. Let\'s connect and discuss the details.');
  
  const [submittingInterest, setSubmittingInterest] = useState(false);
  const [interestSent, setInterestSent] = useState(false);
  const [error, setError] = useState('');
  
  const [roiFormId, setRoiFormId] = useState(null); // Inquiry ID for confirming deal value
  const [businessValue, setBusinessValue] = useState('');
  const [updatingInquiryId, setUpdatingInquiryId] = useState(null);

  const isOwner = listing && user && (listing.seller_id === user.id);

  useEffect(() => {
    if (isOpen && listing) {
      setInterestSent(false);
      setRoiFormId(null);
      setBusinessValue('');
      setError('');
      
      if (isOwner) {
        fetchInquiries();
      } else {
        // Check if user has already expressed interest
        checkMyInterest();
      }
    }
  }, [isOpen, listing]);

  const fetchInquiries = async () => {
    setLoadingInquiries(true);
    try {
      const res = await api.get(`/marketplace/listings/${listing.id}/interests`);
      setInquiries(res.data?.data || res.data || []);
    } catch (err) {
      console.error('Failed to load inquiries', err);
    } finally {
      setLoadingInquiries(false);
    }
  };

  const checkMyInterest = async () => {
    // If listings response includes interest count or indicator, we can map it.
    // The backend listings model has interest_count. We check dynamically by fetching inquiries list if needed.
    // Or we just check interest status. If user tries to express interest again, the backend raises a unique constraint error,
    // so we can gracefully capture that.
  };

  const handleExpressInterest = async (e) => {
    e.preventDefault();
    setSubmittingInterest(true);
    setError('');

    try {
      await api.post(`/marketplace/listings/${listing.id}/interest`, { message: interestMsg });
      setInterestSent(true);
      if (onSuccess) onSuccess();
    } catch (err) {
      if (err.response?.data?.code === 'UNIQUE_VIOLATION' || err.response?.data?.message?.includes('already')) {
        setInterestSent(true); // Already expressed interest
      } else {
        setError(err.response?.data?.error?.message || 'Failed to submit interest.');
      }
    } finally {
      setSubmittingInterest(false);
    }
  };

  const handleUpdateInquiryStatus = async (inquiryId, status, value = 0) => {
    setUpdatingInquiryId(inquiryId);
    setError('');

    try {
      await api.patch(`/marketplace/interests/${inquiryId}`, {
        status,
        business_value: value ? parseFloat(value) : 0
      });
      setRoiFormId(null);
      setBusinessValue('');
      fetchInquiries();
      if (onSuccess) onSuccess();
    } catch (err) {
      setError(err.response?.data?.error?.message || 'Failed to update status.');
    } finally {
      setUpdatingInquiryId(null);
    }
  };

  const handleDeleteListing = async () => {
    if (!window.confirm('Are you sure you want to delete this listing permanently?')) return;
    
    try {
      await api.delete(`/marketplace/listings/${listing.id}`);
      if (onSuccess) onSuccess();
      onClose();
    } catch (err) {
      alert(err.response?.data?.error?.message || 'Failed to delete listing.');
    }
  };

  if (!isOpen || !listing) return null;

  const imageUrl = listing.image_urls?.[0] || 'https://images.unsplash.com/photo-1472851294608-062f824d296e?auto=format&fit=crop&q=80&w=800';

  return (
    <div style={{
      position: 'fixed', top: 0, left: 0, right: 0, bottom: 0,
      backgroundColor: 'rgba(0, 0, 0, 0.6)', zIndex: 1000,
      display: 'flex', alignItems: 'center', justifyContent: 'center',
      padding: '1rem', backdropFilter: 'blur(4px)'
    }}>
      <Ds.Card style={{ 
        width: '100%', 
        maxWidth: '580px', 
        maxHeight: '90vh',
        display: 'flex', 
        flexDirection: 'column',
        borderRadius: '24px',
        overflow: 'hidden',
        border: '1px solid var(--border-subtle)',
        boxShadow: '0 20px 40px rgba(0,0,0,0.3)'
      }}>
        
        {/* Header Hero Banner */}
        <div style={{ 
          background: 'linear-gradient(135deg, #0A2540 0%, #102E55 100%)', 
          padding: '1.5rem', 
          color: 'white',
          position: 'relative',
          display: 'flex',
          justifyContent: 'space-between',
          alignItems: 'flex-start'
        }}>
          <div>
            <div style={{ display: 'flex', alignItems: 'center', gap: '6px', color: 'var(--brand-amber)', fontSize: '0.7rem', fontWeight: 800, letterSpacing: '1px', textTransform: 'uppercase' }}>
              <IconStar size={14} />
              {listing.category} Offer &middot; {listing.industry_name || 'B2B'}
            </div>
            <h4 style={{ fontSize: '1.35rem', fontWeight: 900, margin: '6px 0 0 0', color: 'white', letterSpacing: '-0.02em', lineHeight: 1.2 }}>
              {listing.title}
            </h4>
          </div>
          <button 
            onClick={onClose}
            style={{
              background: 'rgba(255, 255, 255, 0.1)',
              border: 'none',
              borderRadius: '50%',
              width: '32px',
              height: '32px',
              display: 'flex',
              alignItems: 'center',
              justifyContent: 'center',
              color: 'white',
              cursor: 'pointer'
            }}
          >
            <IconX size={16} />
          </button>
        </div>

        {/* Scrollable Body */}
        <div style={{ padding: '1.5rem', overflowY: 'auto', flex: 1, display: 'flex', flexDirection: 'column', gap: '1.5rem' }}>
          {error && (
            <div style={{ padding: '1rem', background: 'rgba(239, 68, 68, 0.1)', border: '1px solid rgba(239, 68, 68, 0.2)', color: '#f87171', borderRadius: '12px', fontSize: '0.85rem' }}>
              {error}
            </div>
          )}

          {/* Listing cover image */}
          <div style={{ position: 'relative', width: '100%', height: '180px', borderRadius: '16px', overflow: 'hidden', border: '1px solid var(--border-subtle)' }}>
            <img src={imageUrl} alt={listing.title} style={{ width: '100%', height: '100%', objectFit: 'cover' }} />
            {listing.is_featured && (
              <span style={{
                position: 'absolute', top: '12px', right: '12px', background: 'linear-gradient(135deg, var(--brand-amber) 0%, #C6A54C 100%)',
                color: '#0A2540', fontSize: '10px', fontWeight: 900, padding: '4px 10px', borderRadius: '8px', boxShadow: '0 4px 10px rgba(198,165,76,0.35)'
              }}>
                FEATURED
              </span>
            )}
          </div>

          {/* Price boxes */}
          <div style={{ display: 'grid', gridTemplateColumns: '1fr 1fr', gap: '0.75rem' }}>
            <div style={{ padding: '0.85rem 1rem', background: 'var(--bg-canvas)', border: '1px solid var(--border-subtle)', borderRadius: '14px' }}>
              <div style={{ fontSize: '0.65rem', fontWeight: 800, color: 'var(--fg-muted)', letterSpacing: '0.5px' }}>REGULAR PRICE</div>
              <div style={{ fontSize: '1.15rem', fontWeight: 800, color: 'var(--fg-primary)', textDecoration: listing.member_price ? 'line-through' : 'none', opacity: listing.member_price ? 0.6 : 1 }}>
                {listing.regular_price ? `${listing.currency} ${Number(listing.regular_price).toLocaleString()}` : 'Contact for Price'}
              </div>
            </div>

            <div style={{ 
              padding: '0.85rem 1rem', 
              background: 'rgba(52, 211, 153, 0.06)', 
              border: '1px solid rgba(52, 211, 153, 0.2)', 
              borderRadius: '14px' 
            }}>
              <div style={{ fontSize: '0.65rem', fontWeight: 800, color: '#34d399', letterSpacing: '0.5px' }}>MEMBER PRICE</div>
              <div style={{ fontSize: '1.15rem', fontWeight: 950, color: '#34d399' }}>
                {listing.member_price ? `${listing.currency} ${Number(listing.member_price).toLocaleString()}` : 'Free / Complimentary'}
              </div>
            </div>
          </div>

          {listing.price_note && (
            <div style={{ fontSize: 'var(--text-xs)', color: 'var(--fg-muted)', fontStyle: 'italic', marginTop: '-0.75rem', paddingLeft: '4px' }}>
              * {listing.price_note}
            </div>
          )}

          {/* Seller / Contact Info */}
          <div style={{ 
            background: 'var(--bg-canvas)', 
            borderRadius: '16px', 
            border: '1px solid var(--border-subtle)',
            padding: '1rem',
            display: 'flex',
            flexDirection: 'column',
            gap: '0.75rem'
          }}>
            <div style={{ display: 'flex', alignItems: 'center', justifyContent: 'space-between', width: '100%' }}>
              <div>
                <div style={{ fontSize: '0.65rem', fontWeight: 800, color: 'var(--fg-muted)', letterSpacing: '0.5px' }}>SELLER PROFILE</div>
                <div style={{ fontSize: '0.95rem', fontWeight: 800, color: 'var(--fg-primary)' }}>{listing.seller_name}</div>
              </div>

              {/* Action buttons (WhatsApp direct) */}
              {listing.whatsapp_number && (
                <a 
                  href={`https://wa.me/${listing.whatsapp_number.replace('+', '')}`}
                  target="_blank" 
                  rel="noopener noreferrer"
                  style={{
                    display: 'flex', alignItems: 'center', gap: '6px', background: 'rgba(37, 211, 102, 0.1)',
                    color: '#25d366', border: '1px solid rgba(37, 211, 102, 0.25)', borderRadius: '10px',
                    padding: '6px 12px', fontSize: '0.75rem', fontWeight: 800, textDecoration: 'none'
                  }}
                >
                  <IconBrandWhatsapp size={16} />
                  WhatsApp
                </a>
              )}
            </div>

            <div style={{ height: '1px', background: 'var(--border-subtle)' }} />

            <div style={{ display: 'grid', gridTemplateColumns: 'repeat(auto-fit, minmax(200px, 1fr))', gap: '0.5rem', fontSize: '0.8rem', color: 'var(--fg-secondary)', fontWeight: 600 }}>
              {listing.contact_phone && (
                <div style={{ display: 'flex', alignItems: 'center', gap: '6px' }}>
                  <IconPhone size={14} style={{ color: 'var(--brand-blue)' }} />
                  {listing.contact_phone}
                </div>
              )}
              {listing.contact_email && (
                <div style={{ display: 'flex', alignItems: 'center', gap: '6px' }}>
                  <IconMail size={14} style={{ color: 'var(--brand-blue)' }} />
                  {listing.contact_email}
                </div>
              )}
            </div>
          </div>

          {/* Description */}
          <div>
            <div style={{ fontSize: '0.7rem', fontWeight: 900, color: 'var(--fg-muted)', letterSpacing: '1px', textTransform: 'uppercase', marginBottom: '0.5rem' }}>Description</div>
            <div style={{ 
              background: 'var(--bg-canvas)', 
              padding: '1rem', 
              borderRadius: '16px', 
              border: '1px solid var(--border-subtle)', 
              color: 'var(--fg-secondary)', 
              fontSize: 'var(--text-sm)', 
              lineHeight: 1.5,
              whiteSpace: 'pre-wrap'
            }}>
              {listing.description}
            </div>
          </div>

          {/* Express Interest panel */}
          {!isOwner && (
            <div style={{ borderTop: '1px solid var(--border-subtle)', paddingTop: '1.25rem' }}>
              <div style={{ fontSize: '0.7rem', fontWeight: 900, color: 'var(--fg-muted)', letterSpacing: '1px', textTransform: 'uppercase', marginBottom: '0.75rem' }}>Express Interest</div>
              
              {interestSent ? (
                <div style={{
                  background: 'rgba(52, 211, 153, 0.08)',
                  border: '1px solid rgba(52, 211, 153, 0.25)',
                  borderRadius: '12px',
                  padding: '1rem',
                  display: 'flex',
                  alignItems: 'center',
                  gap: '8px',
                  color: '#34d399',
                  fontSize: '0.85rem',
                  fontWeight: 700
                }}>
                  <IconCheck size={18} />
                  Inquiry Sent! The seller has been notified of your interest.
                </div>
              ) : (
                <form onSubmit={handleExpressInterest} style={{ display: 'flex', flexDirection: 'column', gap: '0.75rem' }}>
                  <textarea
                    value={interestMsg}
                    onChange={(e) => setInterestMsg(e.target.value)}
                    rows={3}
                    placeholder="Type your inquiry message..."
                    required
                    style={{
                      width: '100%', padding: '0.75rem 1rem', background: 'var(--bg-canvas)',
                      border: '1px solid var(--border-subtle)', borderRadius: '12px',
                      color: 'var(--fg-primary)', fontSize: 'var(--text-sm)', lineHeight: 1.4,
                      resize: 'none', fontFamily: 'inherit'
                    }}
                  />
                  <Ds.Button
                    type="submit"
                    variant="primary"
                    loading={submittingInterest}
                    leftIcon={<IconMessageCircle size={16} />}
                    style={{
                      alignSelf: 'flex-start'
                    }}
                  >
                    Send B2B Inquiry
                  </Ds.Button>
                </form>
              )}
            </div>
          )}

          {/* Inquiry list for owner */}
          {isOwner && (
            <div style={{ borderTop: '1px solid var(--border-subtle)', paddingTop: '1.25rem' }}>
              <div style={{ fontSize: '0.7rem', fontWeight: 900, color: 'var(--fg-muted)', letterSpacing: '1px', textTransform: 'uppercase', marginBottom: '0.75rem', display: 'flex', alignItems: 'center', gap: '6px' }}>
                <IconMessageCircle size={14} />
                Inquiries Received ({inquiries.length})
              </div>

              {loadingInquiries ? (
                <div style={{ fontSize: '0.8rem', color: 'var(--fg-muted)', padding: '1rem', textAlign: 'center' }}>Loading inquiries...</div>
              ) : inquiries.length === 0 ? (
                <div style={{ fontSize: '0.8rem', color: 'var(--fg-muted)', fontStyle: 'italic', padding: '1rem', textAlign: 'center' }}>No inquiries received yet.</div>
              ) : (
                <div style={{ display: 'flex', flexDirection: 'column', gap: '0.75rem' }}>
                  {inquiries.map(inq => {
                    const isConfirming = roiFormId === inq.id;
                    return (
                      <div key={inq.id} style={{
                        background: 'var(--bg-canvas)', border: '1px solid var(--border-subtle)',
                        borderRadius: '14px', padding: '1rem', display: 'flex', flexDirection: 'column', gap: '0.5rem'
                      }}>
                        <div style={{ display: 'flex', justifyContent: 'space-between', alignItems: 'center' }}>
                          <div>
                            <span style={{ fontSize: '0.85rem', fontWeight: 800, color: 'var(--fg-primary)' }}>{inq.interested_user_name}</span>
                            <span style={{ fontSize: '0.7rem', color: 'var(--fg-muted)', marginLeft: '6px' }}>
                              {new Date(inq.created_at).toLocaleDateString()}
                            </span>
                          </div>
                          
                          {/* Status Badge */}
                          <span style={{
                            fontSize: '9px', fontWeight: 900, padding: '2px 8px', borderRadius: '6px', textTransform: 'uppercase',
                            background: inq.status === 'deal_confirmed' ? 'rgba(52, 211, 153, 0.12)' : inq.status === 'cancelled' ? 'var(--border-subtle)' : 'rgba(245, 158, 11, 0.12)',
                            color: inq.status === 'deal_confirmed' ? '#34d399' : inq.status === 'cancelled' ? 'var(--fg-muted)' : 'var(--brand-amber)'
                          }}>
                            {inq.status.replace('_', ' ')}
                          </span>
                        </div>

                        <p style={{ fontSize: '0.8rem', color: 'var(--fg-secondary)', margin: 0, fontStyle: 'italic' }}>
                          "{inq.message}"
                        </p>

                        {/* Action details or forms */}
                        {inq.status === 'deal_confirmed' && (
                          <div style={{ fontSize: '0.8rem', color: '#34d399', fontWeight: 700, display: 'flex', alignItems: 'center', gap: '4px' }}>
                            <IconCoin size={14} />
                            Deal value: LKR {Number(inq.business_value).toLocaleString()} ROI generated
                          </div>
                        )}

                        {inq.status === 'pending' && !isConfirming && (
                          <div style={{ display: 'flex', gap: '0.5rem', marginTop: '0.25rem' }}>
                            <button
                              onClick={() => setRoiFormId(inq.id)}
                              style={{
                                background: '#34d399', color: '#0A2540', border: 'none', borderRadius: '8px',
                                padding: '4px 10px', fontSize: '0.7rem', fontWeight: 900, cursor: 'pointer'
                              }}
                            >
                              Confirm Deal
                            </button>
                            <button
                              onClick={() => handleUpdateInquiryStatus(inq.id, 'cancelled')}
                              style={{
                                background: 'transparent', border: '1px solid var(--border-subtle)', color: 'var(--fg-muted)',
                                borderRadius: '8px', padding: '4px 10px', fontSize: '0.7rem', fontWeight: 800, cursor: 'pointer'
                              }}
                            >
                              Decline
                            </button>
                          </div>
                        )}

                        {isConfirming && (
                          <div style={{ 
                            marginTop: '0.5rem', padding: '0.75rem', background: 'var(--bg-surface)', 
                            border: '1px solid var(--border-subtle)', borderRadius: '10px',
                            display: 'flex', flexDirection: 'column', gap: '0.5rem'
                          }}>
                            <div style={{ fontSize: '0.7rem', fontWeight: 800, color: 'var(--fg-muted)' }}>ENTER REALIZED B2B TRANSACTION VALUE (LKR)</div>
                            <div style={{ display: 'flex', gap: '0.5rem' }}>
                              <input 
                                type="number" 
                                value={businessValue}
                                onChange={(e) => setBusinessValue(e.target.value)}
                                placeholder="e.g. 100000"
                                style={{
                                  flex: 1, padding: '4px 8px', borderRadius: '6px', border: '1px solid var(--border-subtle)',
                                  background: 'var(--bg-canvas)', color: 'var(--fg-primary)', fontSize: '0.8rem', fontWeight: 700
                                }}
                              />
                              <button
                                onClick={() => handleUpdateInquiryStatus(inq.id, 'deal_confirmed', businessValue)}
                                disabled={updatingInquiryId === inq.id}
                                style={{
                                  background: 'linear-gradient(135deg, var(--brand-blue) 0%, #102E55 100%)', color: 'white',
                                  border: 'none', borderRadius: '6px', padding: '4px 12px', fontSize: '0.75rem', fontWeight: 900, cursor: 'pointer'
                                }}
                              >
                                Submit Value
                              </button>
                            </div>
                          </div>
                        )}
                      </div>
                    );
                  })}
                </div>
              )}
            </div>
          )}

        </div>

        {/* Footer Actions */}
        <div style={{ 
          padding: '1.25rem 1.5rem', 
          borderTop: '1px solid var(--border-subtle)', 
          display: 'flex', 
          justifyContent: 'flex-end', 
          gap: '1rem',
          background: 'var(--bg-surface)'
        }}>
          <Ds.Button variant="ghost" onClick={onClose}>
            Close
          </Ds.Button>
          
          {isOwner && (
            <div style={{ display: 'flex', gap: '0.75rem', marginRight: 'auto' }}>
              <Ds.Button 
                variant="ghost" 
                onClick={onEdit} 
                leftIcon={<IconEdit size={16} />}
                style={{ color: 'var(--brand-blue)' }}
              >
                Edit Offer
              </Ds.Button>
              <Ds.Button 
                variant="ghost" 
                onClick={handleDeleteListing} 
                leftIcon={<IconTrash size={16} />}
                style={{ color: '#ef4444' }}
              >
                Delete Offer
              </Ds.Button>
            </div>
          )}
        </div>

      </Ds.Card>
    </div>
  );
}
