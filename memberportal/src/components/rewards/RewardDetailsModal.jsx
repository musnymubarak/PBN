import React from 'react';
import * as Ds from '../ui';
import { 
  IconX, 
  IconAward, 
  IconDeviceMobile 
} from '@tabler/icons-react';

export default function RewardDetailsModal({ isOpen, onClose, offer, partner }) {
  if (!isOpen || !offer || !partner) return null;

  const logoUrl = partner.logo_url || 'https://images.unsplash.com/photo-1549465220-1a8b9238cd48?auto=format&fit=crop&q=80&w=300';

  return (
    <div style={{
      position: 'fixed', top: 0, left: 0, right: 0, bottom: 0,
      backgroundColor: 'rgba(0, 0, 0, 0.6)', zIndex: 1000,
      display: 'flex', alignItems: 'center', justifyContent: 'center',
      padding: '1rem', backdropFilter: 'blur(4px)'
    }}>
      <Ds.Card style={{ 
        width: '100%', 
        maxWidth: '520px', 
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
              <IconAward size={14} />
              EXCLUSIVE REWARD &middot; {partner.name}
            </div>
            <h4 style={{ fontSize: '1.25rem', fontWeight: 900, margin: '6px 0 0 0', color: 'white', letterSpacing: '-0.02em', lineHeight: 1.2 }}>
              {offer.title}
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

        {/* Modal Scrollable Body */}
        <div style={{ padding: '1.5rem', overflowY: 'auto', flex: 1, display: 'flex', flexDirection: 'column', gap: '1.5rem' }}>
          
          {/* Partner & Offer Cover layout */}
          <div style={{ display: 'flex', gap: '1.25rem', alignItems: 'center' }}>
            <div style={{ width: '80px', height: '80px', borderRadius: '16px', overflow: 'hidden', border: '1px solid var(--border-subtle)', background: 'white', display: 'flex', alignItems: 'center', justifyContent: 'center', flexShrink: 0 }}>
              <img src={logoUrl} alt={partner.name} style={{ width: '90%', height: '90%', objectFit: 'contain' }} />
            </div>
            <div>
              <div style={{ fontSize: '0.65rem', fontWeight: 800, color: 'var(--fg-muted)', letterSpacing: '0.5px' }}>OFFERING PARTNER</div>
              <div style={{ fontSize: '1.1rem', fontWeight: 900, color: 'var(--fg-primary)' }}>{partner.name}</div>
              <div style={{ display: 'flex', alignItems: 'center', gap: '6px', marginTop: '4px' }}>
                {offer.discount_percentage && (
                  <span style={{
                    background: 'rgba(52, 211, 153, 0.12)', color: '#34d399', fontSize: '10px', fontWeight: 900, padding: '2px 8px', borderRadius: '6px'
                  }}>
                    {offer.discount_percentage}% DISCOUNT
                  </span>
                )}
                <span style={{
                  background: 'var(--bg-canvas)', border: '1px solid var(--border-subtle)', color: 'var(--fg-secondary)', fontSize: '9px', fontWeight: 800, padding: '2px 8px', borderRadius: '6px', textTransform: 'uppercase'
                }}>
                  Mobile QR Redeem
                </span>
              </div>
            </div>
          </div>

          {/* Description */}
          <div>
            <div style={{ fontSize: '0.7rem', fontWeight: 900, color: 'var(--fg-muted)', letterSpacing: '1px', textTransform: 'uppercase', marginBottom: '0.5rem' }}>Reward Description</div>
            <div style={{ 
              background: 'var(--bg-canvas)', 
              padding: '1rem', 
              borderRadius: '16px', 
              border: '1px solid var(--border-subtle)', 
              color: 'var(--fg-secondary)', 
              fontSize: 'var(--text-sm)', 
              lineHeight: 1.5
            }}>
              {offer.description || 'This exclusive member discount is available to all active Prime Business Network members. Present your privilege details at checkout to claim.'}
            </div>
          </div>

          {/* Redemption logic */}
          <div style={{ borderTop: '1px solid var(--border-subtle)', paddingTop: '1.25rem' }}>
            <div style={{ fontSize: '0.7rem', fontWeight: 900, color: 'var(--fg-muted)', letterSpacing: '1px', textTransform: 'uppercase', marginBottom: '0.75rem' }}>Redeem Reward</div>

            <div style={{
              background: 'rgba(245, 158, 11, 0.08)',
              border: '1px solid rgba(245, 158, 11, 0.25)',
              borderRadius: '16px',
              padding: '1.25rem',
              display: 'flex',
              gap: '12px',
              alignItems: 'flex-start'
            }}>
              <div style={{ color: 'var(--brand-amber)', flexShrink: 0, marginTop: '2px' }}>
                <IconDeviceMobile size={22} />
              </div>
              <div>
                <div style={{ fontSize: '0.85rem', fontWeight: 800, color: 'var(--fg-primary)' }}>Mobile App Redemption Only</div>
                <p style={{ fontSize: '0.78rem', color: 'var(--fg-secondary)', margin: '4px 0 0 0', lineHeight: 1.4, fontWeight: 500 }}>
                  To redeem this reward in person, please open the <strong>PBN Mobile app</strong> on your smartphone, navigate to the Rewards tab, select this offer, and scan the merchant's physical QR code terminal.
                </p>
              </div>
            </div>
          </div>

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
        </div>

      </Ds.Card>
    </div>
  );
}
