import React, { useState, useEffect } from 'react';
import * as Ds from '../ui';
import { IconCheck, IconX, IconUser, IconBriefcase, IconMail, IconPhone, IconSearch } from '@tabler/icons-react';
import api from '../../lib/api';

export default function GiveReferralModal({ isOpen, onClose, onSuccess }) {
  const [members, setMembers] = useState([]);
  const [loadingMembers, setLoadingMembers] = useState(false);
  const [searchQuery, setSearchQuery] = useState('');
  
  const [formData, setFormData] = useState({
    target_user_id: '',
    lead_name: '',
    lead_contact: '',
    lead_email: '',
    description: ''
  });
  
  const [isSubmitting, setIsSubmitting] = useState(false);
  const [error, setError] = useState('');

  useEffect(() => {
    if (isOpen) {
      fetchMembers();
      setFormData({
        target_user_id: '',
        lead_name: '',
        lead_contact: '',
        lead_email: '',
        description: ''
      });
      setError('');
      setSearchQuery('');
    }
  }, [isOpen]);

  const fetchMembers = async () => {
    setLoadingMembers(true);
    try {
      // The API returns all active members
      const res = await api.get('/chapters/members/all');
      setMembers(res.data?.data || res.data || []);
    } catch (err) {
      console.error('Failed to fetch members', err);
    } finally {
      setLoadingMembers(false);
    }
  };

  const handleChange = (e) => {
    setFormData({ ...formData, [e.target.name]: e.target.value });
  };

  const handleSubmit = async (e) => {
    e.preventDefault();
    if (!formData.target_user_id) {
      setError('Please select a member to refer to.');
      return;
    }

    setIsSubmitting(true);
    setError('');

    try {
      await api.post('/referrals', formData);
      onSuccess();
      onClose();
    } catch (err) {
      setError(err.response?.data?.error?.message || err.response?.data?.message || 'Failed to submit referral.');
    } finally {
      setIsSubmitting(false);
    }
  };

  if (!isOpen) return null;

  const filteredMembers = members.filter(m => 
    m.full_name.toLowerCase().includes(searchQuery.toLowerCase()) ||
    m.business?.business_name?.toLowerCase().includes(searchQuery.toLowerCase()) ||
    m.industry_category?.name?.toLowerCase().includes(searchQuery.toLowerCase())
  );

  return (
    <div style={{
      position: 'fixed', top: 0, left: 0, right: 0, bottom: 0,
      backgroundColor: 'rgba(0, 0, 0, 0.5)', zIndex: 1000,
      display: 'flex', alignItems: 'center', justifyContent: 'center',
      padding: '1rem'
    }}>
      <Ds.Card style={{ width: '100%', maxWidth: '600px', maxHeight: '90vh', display: 'flex', flexDirection: 'column' }}>
        <div style={{ padding: '1.5rem', borderBottom: '1px solid var(--border-color)', display: 'flex', justifyContent: 'space-between', alignItems: 'center' }}>
          <h2 style={{ fontSize: '1.25rem', fontWeight: 700, margin: 0 }}>Give a Referral</h2>
          <Ds.Button variant="ghost" size="sm" onClick={onClose}>
            <IconX size={20} />
          </Ds.Button>
        </div>

        <div style={{ padding: '1.5rem', overflowY: 'auto' }}>
          {error && (
            <div style={{ padding: '1rem', background: 'var(--brand-red-50)', color: 'var(--brand-red-600)', borderRadius: 'var(--radius-md)', marginBottom: '1.5rem' }}>
              {error}
            </div>
          )}

          <form id="referral-form" onSubmit={handleSubmit}>
            <div style={{ display: 'flex', flexDirection: 'column', gap: '1.5rem' }}>
              
              <Ds.Section title="Target Recipient">
                <Ds.Field label="Select Member">
                  <div style={{ marginBottom: '1rem' }}>
                    <div style={{ position: 'relative' }}>
                      <div style={{ position: 'absolute', left: '1rem', top: '50%', transform: 'translateY(-50%)', color: 'var(--fg-muted)' }}>
                        <IconSearch size={16} />
                      </div>
                      <input 
                        type="text" 
                        placeholder="Search by name, company, or industry..."
                        value={searchQuery}
                        onChange={(e) => setSearchQuery(e.target.value)}
                        style={{
                          width: '100%',
                          padding: '0.75rem 1rem 0.75rem 2.5rem',
                          borderRadius: 'var(--radius-md)',
                          border: '1px solid var(--border-color)',
                          background: 'var(--bg-subtle)',
                          color: 'var(--fg-primary)'
                        }}
                      />
                    </div>
                  </div>
                  
                  <div style={{ maxHeight: '200px', overflowY: 'auto', border: '1px solid var(--border-color)', borderRadius: 'var(--radius-md)' }}>
                    {loadingMembers ? (
                      <div style={{ padding: '2rem', textAlign: 'center', color: 'var(--fg-secondary)' }}>Loading members...</div>
                    ) : filteredMembers.length === 0 ? (
                      <div style={{ padding: '2rem', textAlign: 'center', color: 'var(--fg-secondary)' }}>No members found.</div>
                    ) : (
                      filteredMembers.map(m => (
                        <div 
                          key={m.user_id}
                          onClick={() => setFormData({ ...formData, target_user_id: m.user_id })}
                          style={{
                            padding: '0.75rem 1rem',
                            borderBottom: '1px solid var(--border-color)',
                            background: formData.target_user_id === m.user_id ? 'var(--brand-blue-50)' : 'transparent',
                            cursor: 'pointer',
                            display: 'flex',
                            alignItems: 'center',
                            gap: '1rem'
                          }}
                          className="ds-list-item-hover"
                        >
                          <Ds.Avatar name={m.full_name} src={m.profile_photo} size="sm" />
                          <div style={{ flex: 1 }}>
                            <div style={{ fontSize: 'var(--text-sm)', fontWeight: formData.target_user_id === m.user_id ? 700 : 500, color: 'var(--fg-primary)' }}>
                              {m.full_name}
                            </div>
                            <div style={{ fontSize: 'var(--text-xs)', color: 'var(--fg-secondary)' }}>
                              {m.business?.business_name || 'No Company'} &middot; {m.industry_category?.name || 'No Industry'}
                            </div>
                          </div>
                          {formData.target_user_id === m.user_id && (
                            <IconCheck size={18} color="var(--brand-blue)" />
                          )}
                        </div>
                      ))
                    )}
                  </div>
                </Ds.Field>
              </Ds.Section>

              <Ds.Section title="Lead Contact Info">
                <div style={{ display: 'grid', gridTemplateColumns: '1fr', gap: '1rem' }}>
                  <Ds.Field label="Lead Full Name">
                    <div style={{ position: 'relative' }}>
                      <div style={{ position: 'absolute', left: '1rem', top: '50%', transform: 'translateY(-50%)', color: 'var(--brand-blue)' }}><IconUser size={18} /></div>
                      <Ds.Input type="text" name="lead_name" value={formData.lead_name} onChange={handleChange} required style={{ paddingLeft: '2.5rem' }} />
                    </div>
                  </Ds.Field>
                  <Ds.Field label="Contact Number">
                    <div style={{ position: 'relative' }}>
                      <div style={{ position: 'absolute', left: '1rem', top: '50%', transform: 'translateY(-50%)', color: 'var(--brand-blue)' }}><IconPhone size={18} /></div>
                      <Ds.Input type="text" name="lead_contact" value={formData.lead_contact} onChange={handleChange} required style={{ paddingLeft: '2.5rem' }} />
                    </div>
                  </Ds.Field>
                  <Ds.Field label="Email Address">
                    <div style={{ position: 'relative' }}>
                      <div style={{ position: 'absolute', left: '1rem', top: '50%', transform: 'translateY(-50%)', color: 'var(--brand-blue)' }}><IconMail size={18} /></div>
                      <Ds.Input type="email" name="lead_email" value={formData.lead_email} onChange={handleChange} required style={{ paddingLeft: '2.5rem' }} />
                    </div>
                  </Ds.Field>
                </div>
              </Ds.Section>

              <Ds.Section title="Opportunity Details">
                <Ds.Field label="Description" hint="Explain how the recipient can help this lead.">
                  <Ds.Textarea name="description" value={formData.description} onChange={handleChange} required rows={4} />
                </Ds.Field>
              </Ds.Section>

            </div>
          </form>
        </div>

        <div style={{ padding: '1.5rem', borderTop: '1px solid var(--border-color)', display: 'flex', justifyContent: 'flex-end', gap: '1rem' }}>
          <Ds.Button variant="ghost" onClick={onClose} disabled={isSubmitting}>
            Cancel
          </Ds.Button>
          <Ds.Button type="submit" form="referral-form" variant="primary" loading={isSubmitting} leftIcon={<IconCheck size={16} />}>
            Submit Opportunity
          </Ds.Button>
        </div>
      </Ds.Card>
    </div>
  );
}
