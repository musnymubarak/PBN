import React, { useState, useEffect } from 'react';
import * as Ds from '../ui';
import { IconCheck, IconX, IconCoin, IconEdit } from '@tabler/icons-react';
import api from '../../lib/api';

export default function UpdateReferralModal({ isOpen, onClose, referral, onSuccess }) {
  const [formData, setFormData] = useState({
    status: '',
    description: '',
    actual_value: ''
  });
  
  const [isSubmitting, setIsSubmitting] = useState(false);
  const [error, setError] = useState('');

  useEffect(() => {
    if (isOpen && referral) {
      setFormData({
        status: referral.status || 'NEW',
        description: '',
        actual_value: referral.actual_value || ''
      });
      setError('');
    }
  }, [isOpen, referral]);

  const handleChange = (e) => {
    setFormData({ ...formData, [e.target.name]: e.target.value });
  };

  const handleSubmit = async (e) => {
    e.preventDefault();
    setIsSubmitting(true);
    setError('');

    const payload = {
      status: formData.status
    };

    if (formData.description) {
      payload.description = formData.description;
    }

    if (formData.actual_value) {
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

  if (!isOpen || !referral) return null;

  return (
    <div style={{
      position: 'fixed', top: 0, left: 0, right: 0, bottom: 0,
      backgroundColor: 'rgba(0, 0, 0, 0.5)', zIndex: 1000,
      display: 'flex', alignItems: 'center', justifyContent: 'center',
      padding: '1rem'
    }}>
      <Ds.Card style={{ width: '100%', maxWidth: '500px', display: 'flex', flexDirection: 'column' }}>
        <div style={{ padding: '1.5rem', borderBottom: '1px solid var(--border-color)', display: 'flex', justifyContent: 'space-between', alignItems: 'center' }}>
          <h2 style={{ fontSize: '1.25rem', fontWeight: 700, margin: 0 }}>Update Business Status</h2>
          <Ds.Button variant="ghost" size="sm" onClick={onClose}>
            <IconX size={20} />
          </Ds.Button>
        </div>

        <div style={{ padding: '1.5rem' }}>
          {error && (
            <div style={{ padding: '1rem', background: 'var(--brand-red-50)', color: 'var(--brand-red-600)', borderRadius: 'var(--radius-md)', marginBottom: '1.5rem' }}>
              {error}
            </div>
          )}

          <div style={{ marginBottom: '1.5rem', padding: '1rem', background: 'var(--bg-subtle)', borderRadius: 'var(--radius-md)', border: '1px solid var(--border-color)' }}>
            <div style={{ fontSize: 'var(--text-xs)', fontWeight: 700, color: 'var(--brand-blue)', letterSpacing: '1px', textTransform: 'uppercase', marginBottom: '0.25rem' }}>Lead Details</div>
            <div style={{ fontSize: '1.1rem', fontWeight: 700, color: 'var(--fg-primary)' }}>{referral.lead_name}</div>
            <div style={{ fontSize: 'var(--text-sm)', color: 'var(--fg-secondary)', marginTop: '0.25rem' }}>Referred by {referral.from_user?.full_name}</div>
          </div>

          <form id="update-status-form" onSubmit={handleSubmit}>
            <div style={{ display: 'flex', flexDirection: 'column', gap: '1.5rem' }}>
              
              <Ds.Field label="Current Status">
                <select 
                  name="status" 
                  value={formData.status} 
                  onChange={handleChange}
                  style={{
                    width: '100%',
                    padding: '0.75rem 1rem',
                    borderRadius: 'var(--radius-md)',
                    border: '1px solid var(--border-color)',
                    background: 'var(--bg-surface)',
                    color: 'var(--fg-primary)',
                    fontSize: 'var(--text-sm)'
                  }}
                >
                  <option value="NEW">NEW</option>
                  <option value="CONTACTED">CONTACTED</option>
                  <option value="IN_PROGRESS">IN PROGRESS</option>
                  <option value="CLOSED_WON">CLOSED WON</option>
                  <option value="CLOSED_LOST">CLOSED LOST</option>
                </select>
              </Ds.Field>

              <Ds.Field label="Realized ROI (LKR Amount)" hint="Required if you won the business.">
                <div style={{ position: 'relative' }}>
                  <div style={{ position: 'absolute', left: '1rem', top: '50%', transform: 'translateY(-50%)', color: 'var(--brand-yellow)' }}><IconCoin size={18} /></div>
                  <Ds.Input 
                    type="number" 
                    name="actual_value" 
                    value={formData.actual_value} 
                    onChange={handleChange} 
                    placeholder="e.g. 50000" 
                    style={{ paddingLeft: '2.5rem' }} 
                  />
                </div>
              </Ds.Field>

              <Ds.Field label="Update Notes" hint="Internal update notes... (Optional)">
                <div style={{ position: 'relative' }}>
                  <div style={{ position: 'absolute', left: '1rem', top: '1rem', color: 'var(--brand-blue)' }}><IconEdit size={18} /></div>
                  <Ds.Textarea 
                    name="description" 
                    value={formData.description} 
                    onChange={handleChange} 
                    rows={3}
                    style={{ paddingLeft: '2.5rem' }} 
                  />
                </div>
              </Ds.Field>

            </div>
          </form>
        </div>

        <div style={{ padding: '1.5rem', borderTop: '1px solid var(--border-color)', display: 'flex', justifyContent: 'flex-end', gap: '1rem' }}>
          <Ds.Button variant="ghost" onClick={onClose} disabled={isSubmitting}>
            Cancel
          </Ds.Button>
          <Ds.Button type="submit" form="update-status-form" variant="primary" loading={isSubmitting} leftIcon={<IconCheck size={16} />}>
            Save Update
          </Ds.Button>
        </div>
      </Ds.Card>
    </div>
  );
}
