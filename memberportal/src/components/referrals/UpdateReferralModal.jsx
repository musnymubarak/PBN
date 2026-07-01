import React, { useState, useEffect } from 'react';
import * as Ds from '../ui';
import { 
  IconCheck, 
  IconX, 
  IconPhone, 
  IconMail, 
  IconCoin, 
  IconEdit, 
  IconClock, 
  IconHistory, 
  IconBriefcase 
} from '@tabler/icons-react';
import { useAuth } from '../../context/AuthContext';
import api from '../../lib/api';

const STATUS_OPTIONS = [
  { value: 'submitted', label: 'Submitted', fg: 'var(--brand-blue)', bg: 'rgba(var(--brand-blue-rgb), 0.12)', border: 'rgba(var(--brand-blue-rgb), 0.3)', dot: 'var(--brand-blue)' },
  { value: 'contacted', label: 'Contacted', fg: 'var(--brand-blue)', bg: 'rgba(var(--brand-blue-rgb), 0.12)', border: 'rgba(var(--brand-blue-rgb), 0.3)', dot: 'var(--brand-blue)' },
  { value: 'negotiation', label: 'Negotiation', fg: 'var(--brand-amber)', bg: 'rgba(245, 158, 11, 0.12)', border: 'rgba(245, 158, 11, 0.3)', dot: '#f59e0b' },
  { value: 'in_progress', label: 'In Progress', fg: 'var(--brand-amber)', bg: 'rgba(245, 158, 11, 0.12)', border: 'rgba(245, 158, 11, 0.3)', dot: '#f59e0b' },
  { value: 'success', label: 'Success', fg: '#34d399', bg: 'rgba(52, 211, 153, 0.12)', border: 'rgba(52, 211, 153, 0.3)', dot: '#34d399' },
  { value: 'closed_lost', label: 'Lost', fg: 'var(--fg-muted)', bg: 'var(--bg-canvas)', border: 'var(--border-subtle)', dot: 'var(--fg-muted)' },
];

export const getStatusStyle = (status) => {
  const s = (status || '').toLowerCase();
  return STATUS_OPTIONS.find(opt => opt.value === s) || {
    label: status || 'Unknown',
    fg: 'var(--fg-muted)',
    bg: 'var(--bg-canvas)',
    border: 'var(--border-subtle)',
    dot: 'var(--fg-muted)'
  };
};

export default function UpdateReferralModal({ isOpen, onClose, referral, onSuccess }) {
  const { user } = useAuth();
  
  const [formData, setFormData] = useState({
    status: '',
    description: '',
    actual_value: ''
  });
  
  const [isSubmitting, setIsSubmitting] = useState(false);
  const [error, setError] = useState('');

  const isReceived = referral && user && (referral.target_user?.id === user.id);

  useEffect(() => {
    if (isOpen && referral) {
      setFormData({
        status: referral.status || 'submitted',
        description: '',
        actual_value: referral.actual_value || ''
      });
      setError('');
    }
  }, [isOpen, referral]);

  const handleSubmit = async (e) => {
    e.preventDefault();
    setIsSubmitting(true);
    setError('');

    const payload = {
      status: formData.status
    };

    if (formData.description.trim()) {
      payload.description = formData.description.trim();
    }

    if (formData.actual_value !== '') {
      payload.actual_value = parseFloat(formData.actual_value);
    }

    try {
      await api.patch(`/referrals/${referral.id}/status`, payload);
      onSuccess();
      onClose();
    } catch (err) {
      setError(err.response?.data?.error?.message || err.response?.data?.message || 'Failed to update referral status.');
    } finally {
      setIsSubmitting(false);
    }
  };

  const getRelativeTime = (iso) => {
    try {
      const dt = new Date(iso);
      const diffMs = new Date() - dt;
      const diffSec = Math.floor(diffMs / 1000);
      if (diffSec < 60) return 'Just now';
      const diffMin = Math.floor(diffSec / 60);
      if (diffMin < 60) return `${diffMin}m ago`;
      const diffHr = Math.floor(diffMin / 60);
      if (diffHr < 24) return `${diffHr}h ago`;
      const diffDays = Math.floor(diffHr / 24);
      if (diffDays < 7) return `${diffDays}d ago`;
      return dt.toLocaleDateString('en-US', { day: 'numeric', month: 'short' });
    } catch (e) {
      return iso;
    }
  };

  if (!isOpen || !referral) return null;

  return (
    <div style={{
      position: 'fixed', top: 0, left: 0, right: 0, bottom: 0,
      backgroundColor: 'rgba(0, 0, 0, 0.6)', zIndex: 1000,
      display: 'flex', alignItems: 'center', justifyContent: 'center',
      padding: '1rem', backdropFilter: 'blur(4px)'
    }}>
      <Ds.Card style={{ 
        width: '100%', 
        maxWidth: '560px', 
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
            <div style={{ display: 'flex', alignItems: 'center', gap: '6px', color: 'var(--brand-amber)', fontSize: '0.7rem', fontWeight: 800, letterSpacing: '1px' }}>
              <IconBriefcase size={14} />
              LEAD DETAILS
            </div>
            <h4 style={{ fontSize: '1.35rem', fontWeight: 900, margin: '6px 0 0 0', color: 'white', letterSpacing: '-0.02em', lineHeight: 1.2 }}>
              {referral.lead_name}
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
              cursor: 'pointer',
              transition: 'all 0.2s'
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

          {/* Lead Info Contact Card */}
          <div style={{ 
            background: 'var(--bg-canvas)', 
            borderRadius: '16px', 
            border: '1px solid var(--border-subtle)',
            overflow: 'hidden'
          }}>
            <div style={{ padding: '1rem', display: 'flex', alignItems: 'center', gap: '12px', borderBottom: '1px solid var(--border-subtle)' }}>
              <div style={{ width: '36px', height: '36px', borderRadius: '10px', background: 'rgba(var(--brand-blue-rgb), 0.1)', color: 'var(--brand-blue)', display: 'flex', alignItems: 'center', justifyContent: 'center' }}>
                <IconPhone size={18} />
              </div>
              <div style={{ flex: 1 }}>
                <div style={{ fontSize: '0.65rem', fontWeight: 800, color: 'var(--fg-muted)', letterSpacing: '0.5px' }}>CONTACT NUMBER</div>
                <div style={{ fontSize: '0.9rem', fontWeight: 800, color: 'var(--fg-primary)' }}>{referral.lead_contact}</div>
              </div>
            </div>

            {referral.lead_email && (
              <div style={{ padding: '1rem', display: 'flex', alignItems: 'center', gap: '12px', borderBottom: '1px solid var(--border-subtle)' }}>
                <div style={{ width: '36px', height: '36px', borderRadius: '10px', background: 'rgba(var(--brand-blue-rgb), 0.1)', color: 'var(--brand-blue)', display: 'flex', alignItems: 'center', justifyContent: 'center' }}>
                  <IconMail size={18} />
                </div>
                <div style={{ flex: 1 }}>
                  <div style={{ fontSize: '0.65rem', fontWeight: 800, color: 'var(--fg-muted)', letterSpacing: '0.5px' }}>LEAD EMAIL</div>
                  <div style={{ fontSize: '0.9rem', fontWeight: 800, color: 'var(--fg-primary)' }}>{referral.lead_email}</div>
                </div>
              </div>
            )}

            <div style={{ padding: '1rem', display: 'flex', alignItems: 'center', gap: '12px' }}>
              <div style={{ width: '36px', height: '36px', borderRadius: '10px', background: 'rgba(245, 158, 11, 0.1)', color: 'var(--brand-amber)', display: 'flex', alignItems: 'center', justifyContent: 'center' }}>
                <IconCoin size={18} />
              </div>
              <div style={{ flex: 1 }}>
                <div style={{ fontSize: '0.65rem', fontWeight: 800, color: 'var(--fg-muted)', letterSpacing: '0.5px' }}>REALIZED ROI</div>
                <div style={{ fontSize: '0.9rem', fontWeight: 800, color: 'var(--fg-primary)' }}>
                  {referral.actual_value ? `LKR ${Number(referral.actual_value).toLocaleString()}` : 'LKR 0'}
                </div>
              </div>
            </div>
          </div>

          {/* Opportunity Description */}
          <div>
            <div style={{ fontSize: '0.7rem', fontWeight: 900, color: 'var(--fg-muted)', letterSpacing: '1px', textTransform: 'uppercase', marginBottom: '0.5rem' }}>Opportunity Description</div>
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
              {referral.description || 'No description provided'}
            </div>
          </div>

          {/* Recipient update form */}
          {isReceived && (
            <div>
              <div style={{ fontSize: '0.7rem', fontWeight: 900, color: 'var(--fg-muted)', letterSpacing: '1px', textTransform: 'uppercase', marginBottom: '0.75rem' }}>Update Business Status</div>
              <form id="update-status-form" onSubmit={handleSubmit} style={{ display: 'flex', flexDirection: 'column', gap: '1.25rem' }}>
                
                {/* Status clickable buttons grid */}
                <div style={{ display: 'grid', gridTemplateColumns: 'repeat(3, 1fr)', gap: '0.5rem' }}>
                  {STATUS_OPTIONS.map(opt => {
                    const isSelected = formData.status === opt.value;
                    return (
                      <button
                        key={opt.value}
                        type="button"
                        onClick={() => setFormData({ ...formData, status: opt.value })}
                        style={{
                          background: isSelected ? opt.bg : 'transparent',
                          border: `1px solid ${isSelected ? opt.border : 'var(--border-subtle)'}`,
                          color: isSelected ? opt.fg : 'var(--fg-secondary)',
                          borderRadius: '10px',
                          padding: '0.6rem 0.5rem',
                          fontSize: '0.75rem',
                          fontWeight: 800,
                          cursor: 'pointer',
                          display: 'flex',
                          alignItems: 'center',
                          justifyContent: 'center',
                          gap: '6px',
                          transition: 'all 0.15s ease'
                        }}
                      >
                        <span style={{ width: '6px', height: '6px', borderRadius: '50%', background: opt.dot }} />
                        {opt.label}
                      </button>
                    );
                  })}
                </div>

                {/* Realized ROI */}
                <div>
                  <div style={{ fontSize: 'var(--text-xs)', fontWeight: 800, color: 'var(--fg-muted)', marginBottom: '0.4rem' }}>Realized ROI (LKR Amount)</div>
                  <div style={{ position: 'relative' }}>
                    <div style={{ position: 'absolute', left: '1rem', top: '50%', transform: 'translateY(-50%)', color: 'var(--brand-amber)' }}><IconCoin size={18} /></div>
                    <input 
                      type="number" 
                      name="actual_value" 
                      value={formData.actual_value} 
                      onChange={(e) => setFormData({ ...formData, actual_value: e.target.value })} 
                      placeholder="e.g. 50000" 
                      style={{ 
                        width: '100%',
                        padding: '0.75rem 1rem 0.75rem 2.5rem',
                        background: 'var(--bg-canvas)',
                        border: '1px solid var(--border-subtle)',
                        borderRadius: '12px',
                        color: 'var(--fg-primary)',
                        fontSize: 'var(--text-sm)',
                        fontWeight: 700
                      }} 
                    />
                  </div>
                </div>

                {/* Internal notes */}
                <div>
                  <div style={{ fontSize: 'var(--text-xs)', fontWeight: 800, color: 'var(--fg-muted)', marginBottom: '0.4rem' }}>Update Notes</div>
                  <div style={{ position: 'relative' }}>
                    <div style={{ position: 'absolute', left: '1rem', top: '1rem', color: 'var(--brand-blue)' }}><IconEdit size={18} /></div>
                    <textarea 
                      name="description" 
                      value={formData.description} 
                      onChange={(e) => setFormData({ ...formData, description: e.target.value })} 
                      placeholder="Discussed requirements, scheduled followup..."
                      rows={3}
                      style={{ 
                        width: '100%',
                        padding: '0.75rem 1rem 0.75rem 2.5rem',
                        background: 'var(--bg-canvas)',
                        border: '1px solid var(--border-subtle)',
                        borderRadius: '12px',
                        color: 'var(--fg-primary)',
                        fontSize: 'var(--text-sm)',
                        fontFamily: 'inherit',
                        lineHeight: 1.5,
                        resize: 'none'
                      }} 
                    />
                  </div>
                </div>
              </form>
            </div>
          )}

          {/* History Timeline */}
          {referral.history && referral.history.length > 0 && (
            <div>
              <div style={{ fontSize: '0.7rem', fontWeight: 900, color: 'var(--fg-muted)', letterSpacing: '1px', textTransform: 'uppercase', marginBottom: '0.75rem', display: 'flex', alignItems: 'center', gap: '6px' }}>
                <IconHistory size={14} />
                History Timeline
              </div>
              
              <div style={{ display: 'flex', flexDirection: 'column' }}>
                {[...referral.history].sort((a,b) => new Date(b.created_at) - new Date(a.created_at)).map((entry, index, arr) => {
                  const style = getStatusStyle(entry.new_status);
                  const isLast = index === arr.length - 1;
                  
                  const oldLabel = entry.old_status ? getStatusStyle(entry.old_status).label : null;
                  const newLabel = style.label;
                  
                  const primaryMsg = oldLabel 
                    ? `Status changed: ${oldLabel} → ${newLabel}` 
                    : `Created as ${newLabel}`;
                    
                  return (
                    <div key={entry.id || index} style={{ display: 'flex', minHeight: '50px' }}>
                      {/* Timeline dot column */}
                      <div style={{ width: '24px', display: 'flex', flexDirection: 'column', alignItems: 'center' }}>
                        <div style={{ 
                          width: '8px', 
                          height: '8px', 
                          borderRadius: '50%', 
                          background: style.dot,
                          border: `2px solid ${style.bg}`,
                          marginTop: '6px'
                        }} />
                        {!isLast && (
                          <div style={{ flex: 1, width: '2px', background: 'var(--border-subtle)', margin: '4px 0' }} />
                        )}
                      </div>
                      
                      {/* Text details */}
                      <div style={{ flex: 1, paddingBottom: isLast ? 0 : '1rem', paddingLeft: '8px' }}>
                        <div style={{ fontSize: '0.85rem', fontWeight: 700, color: 'var(--fg-primary)', lineHeight: 1.3 }}>
                          {primaryMsg}
                        </div>
                        <div style={{ fontSize: '0.75rem', color: 'var(--fg-muted)', marginTop: '2px' }}>
                          {getRelativeTime(entry.created_at)}
                          {entry.description && ` · ${entry.description}`}
                        </div>
                      </div>
                    </div>
                  );
                })}
              </div>
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
          <Ds.Button variant="ghost" onClick={onClose} disabled={isSubmitting}>
            Close
          </Ds.Button>
          {isReceived && (
            <Ds.Button 
              type="submit" 
              form="update-status-form" 
              variant="primary" 
              loading={isSubmitting} 
              leftIcon={<IconCheck size={16} />}
            >
              Save Updates
            </Ds.Button>
          )}
        </div>

      </Ds.Card>
    </div>
  );
}
