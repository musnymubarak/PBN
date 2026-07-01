import React, { useState, useEffect } from 'react';
import * as Ds from '../ui';
import { IconX, IconCheck, IconUpload } from '@tabler/icons-react';
import api from '../../lib/api';

export default function CreatePostModal({ isOpen, onClose, onSuccess }) {
  const [isSubmitting, setIsSubmitting] = useState(false);
  const [error, setError] = useState('');
  
  const [industries, setIndustries] = useState([]);
  const [clubs, setClubs] = useState([]);
  const [uploading, setUploading] = useState(false);

  const [formData, setFormData] = useState({
    content: '',
    image_url: '',
    post_type: 'general', // 'general', 'lead', 'rfp'
    visibility: 'chapter', // 'chapter', 'network'
    budget_range: '',
    deadline: '',
    target_club_id: '',
    target_industry_id: ''
  });

  useEffect(() => {
    if (isOpen) {
      fetchMetadata();
      setFormData({
        content: '',
        image_url: '',
        post_type: 'general',
        visibility: 'chapter',
        budget_range: '',
        deadline: '',
        target_club_id: '',
        target_industry_id: ''
      });
      setError('');
    }
  }, [isOpen]);

  const fetchMetadata = async () => {
    try {
      const [resInd, resClubs] = await Promise.all([
        api.get('/industry-categories'),
        api.get('/horizontal-clubs').catch(() => ({ data: [] }))
      ]);
      setIndustries(resInd.data?.data || resInd.data || []);
      setClubs(resClubs.data?.data || resClubs.data || []);
    } catch (err) {
      console.error('Failed to load metadata', err);
    }
  };

  const handleChange = (e) => {
    setFormData({ ...formData, [e.target.name]: e.target.value });
  };

  const handleImageUpload = async (e) => {
    const file = e.target.files[0];
    if (!file) return;

    setUploading(true);
    setError('');

    const uploadData = new FormData();
    uploadData.append('file', file);

    try {
      const res = await api.post('/marketplace/listings/upload', uploadData, {
        headers: {
          'Content-Type': 'multipart/form-data'
        }
      });
      const url = res.data?.data?.image_url || res.data?.image_url;
      if (url) {
        setFormData(prev => ({ ...prev, image_url: url }));
      }
    } catch (err) {
      setError('Failed to upload image.');
    } finally {
      setUploading(false);
    }
  };

  const handleSubmit = async (e) => {
    e.preventDefault();
    setIsSubmitting(true);
    setError('');

    const payload = {
      content: formData.content,
      image_url: formData.image_url || null,
      post_type: formData.post_type,
      visibility: formData.visibility,
      budget_range: formData.budget_range || null,
      deadline: formData.deadline ? new Date(formData.deadline).toISOString() : null,
      target_club_id: formData.target_club_id || null,
      target_industry_id: formData.target_industry_id || null
    };

    try {
      await api.post('/community/posts', payload);
      onSuccess();
      onClose();
    } catch (err) {
      setError(err.response?.data?.error?.message || err.response?.data?.message || 'Failed to submit post.');
    } finally {
      setIsSubmitting(false);
    }
  };

  if (!isOpen) return null;

  return (
    <div style={{
      position: 'fixed', top: 0, left: 0, right: 0, bottom: 0,
      backgroundColor: 'rgba(0, 0, 0, 0.6)', zIndex: 1000,
      display: 'flex', alignItems: 'center', justifyContent: 'center',
      padding: '1rem', backdropFilter: 'blur(4px)'
    }}>
      <Ds.Card style={{ width: '100%', maxWidth: '580px', maxHeight: '90vh', display: 'flex', flexDirection: 'column', borderRadius: '24px', overflow: 'hidden' }}>
        
        {/* Modal Header */}
        <div style={{ padding: '1.5rem', borderBottom: '1px solid var(--border-subtle)', display: 'flex', justifyContent: 'space-between', alignItems: 'center' }}>
          <h2 style={{ fontSize: '1.25rem', fontWeight: 900, margin: 0, color: 'var(--fg-primary)' }}>
            Create Post / Opportunity
          </h2>
          <button 
            onClick={onClose}
            style={{ background: 'none', border: 'none', color: 'var(--fg-muted)', cursor: 'pointer' }}
          >
            <IconX size={20} />
          </button>
        </div>

        {/* Scrollable Form Body */}
        <div style={{ padding: '1.5rem', overflowY: 'auto', flex: 1 }}>
          {error && (
            <div style={{ padding: '1rem', background: 'rgba(239, 68, 68, 0.1)', border: '1px solid rgba(239, 68, 68, 0.2)', color: '#f87171', borderRadius: '12px', marginBottom: '1.5rem', fontSize: '0.85rem' }}>
              {error}
            </div>
          )}

          <form id="post-form" onSubmit={handleSubmit}>
            <div style={{ display: 'flex', flexDirection: 'column', gap: '1.25rem' }}>
              
              {/* Post Type Selector */}
              <Ds.Field label="What would you like to share?">
                <div style={{ display: 'grid', gridTemplateColumns: 'repeat(3, 1fr)', gap: '0.5rem' }}>
                  {['general', 'lead', 'rfp'].map(type => (
                    <button
                      key={type}
                      type="button"
                      onClick={() => setFormData(prev => ({ ...prev, post_type: type }))}
                      style={{
                        padding: '0.75rem', borderRadius: '12px',
                        border: `1.5px solid ${formData.post_type === type ? 'var(--brand-amber)' : 'var(--border-subtle)'}`,
                        background: formData.post_type === type ? 'rgba(245, 158, 11, 0.08)' : 'var(--bg-canvas)',
                        color: formData.post_type === type ? 'var(--brand-amber)' : 'var(--fg-secondary)',
                        fontWeight: 900, textTransform: 'uppercase', fontSize: '0.75rem', cursor: 'pointer',
                        transition: 'all 0.15s'
                      }}
                    >
                      {type}
                    </button>
                  ))}
                </div>
              </Ds.Field>

              {/* Visibility and Metadata */}
              <div style={{ display: 'grid', gridTemplateColumns: '1fr 1fr', gap: '1rem' }}>
                <Ds.Field label="Visibility">
                  <select
                    name="visibility"
                    value={formData.visibility}
                    onChange={handleChange}
                    style={{
                      width: '100%', padding: '0.75rem 1rem', borderRadius: '12px',
                      border: '1px solid var(--border-subtle)', background: 'var(--bg-canvas)',
                      color: 'var(--fg-primary)', fontSize: 'var(--text-sm)', fontWeight: 700
                    }}
                  >
                    <option value="chapter">Chapter Only</option>
                    <option value="network">Network-wide</option>
                  </select>
                </Ds.Field>

                {formData.post_type !== 'general' && (
                  <Ds.Field label="Target Industry">
                    <select
                      name="target_industry_id"
                      value={formData.target_industry_id}
                      onChange={handleChange}
                      required
                      style={{
                        width: '100%', padding: '0.75rem 1rem', borderRadius: '12px',
                        border: '1px solid var(--border-subtle)', background: 'var(--bg-canvas)',
                        color: 'var(--fg-primary)', fontSize: 'var(--text-sm)', fontWeight: 700
                      }}
                    >
                      <option value="">Select Industry...</option>
                      {industries.map(ind => (
                        <option key={ind.id} value={ind.id}>{ind.name}</option>
                      ))}
                    </select>
                  </Ds.Field>
                )}
              </div>

              {/* Economic Fields for Lead/RFP */}
              {formData.post_type !== 'general' && (
                <div style={{ display: 'grid', gridTemplateColumns: '1fr 1fr', gap: '1rem' }}>
                  <Ds.Field label="Budget Range" hint="e.g. LKR 10k - 50k">
                    <Ds.Input type="text" name="budget_range" value={formData.budget_range} onChange={handleChange} placeholder="e.g. LKR 100,000" />
                  </Ds.Field>
                  <Ds.Field label="Deadline">
                    <Ds.Input type="date" name="deadline" value={formData.deadline} onChange={handleChange} />
                  </Ds.Field>
                </div>
              )}

              {/* Targeted Club (Optional) */}
              {formData.post_type !== 'general' && clubs.length > 0 && (
                <Ds.Field label="Target Horizontal Club (Optional)" hint="Directs the opportunity to this circle.">
                  <select
                    name="target_club_id"
                    value={formData.target_club_id}
                    onChange={handleChange}
                    style={{
                      width: '100%', padding: '0.75rem 1rem', borderRadius: '12px',
                      border: '1px solid var(--border-subtle)', background: 'var(--bg-canvas)',
                      color: 'var(--fg-primary)', fontSize: 'var(--text-sm)', fontWeight: 700
                    }}
                  >
                    <option value="">Select horizontal club...</option>
                    {clubs.map(c => (
                      <option key={c.id} value={c.id}>{c.name}</option>
                    ))}
                  </select>
                </Ds.Field>
              )}

              {/* Core Content */}
              <Ds.Field label="Post Content" hint="Describe your request or update clearly.">
                <Ds.Textarea
                  name="content"
                  value={formData.content}
                  onChange={handleChange}
                  required
                  rows={4}
                  placeholder={formData.post_type === 'general' ? "Share what is happening in your business..." : "Detail the lead requirements, criteria, and what you are looking for..."}
                />
              </Ds.Field>

              {/* Image attachment */}
              <Ds.Field label="Attachment Image" hint="Optional">
                <div style={{ display: 'flex', alignItems: 'center', gap: '1rem', marginTop: '0.25rem' }}>
                  {formData.image_url && (
                    <div style={{ position: 'relative', width: '80px', height: '80px', borderRadius: '12px', overflow: 'hidden', border: '1px solid var(--border-subtle)' }}>
                      <img src={formData.image_url} alt="Attachment" style={{ width: '100%', height: '100%', objectFit: 'cover' }} />
                    </div>
                  )}
                  <label style={{
                    display: 'flex', flexDirection: 'column', alignItems: 'center', justifyContent: 'center',
                    width: formData.image_url ? '120px' : '100%', height: '80px',
                    border: '2px dashed var(--border-subtle)', borderRadius: '12px',
                    cursor: 'pointer', background: 'var(--bg-canvas)', color: 'var(--fg-secondary)',
                    fontSize: '0.8rem', fontWeight: 700, gap: '4px'
                  }}>
                    <IconUpload size={20} style={{ color: 'var(--brand-blue)' }} />
                    <span>{uploading ? 'Uploading...' : 'Upload Image'}</span>
                    <input type="file" accept="image/*" onChange={handleImageUpload} style={{ display: 'none' }} disabled={uploading} />
                  </label>
                </div>
              </Ds.Field>

            </div>
          </form>
        </div>

        {/* Modal Footer */}
        <div style={{ padding: '1.25rem 1.5rem', borderTop: '1px solid var(--border-subtle)', display: 'flex', justifyContent: 'flex-end', gap: '1rem' }}>
          <Ds.Button variant="ghost" onClick={onClose} disabled={isSubmitting}>
            Cancel
          </Ds.Button>
          <Ds.Button 
            type="submit" 
            form="post-form" 
            variant="primary" 
            loading={isSubmitting} 
            leftIcon={<IconCheck size={16} />}
          >
            Post Update
          </Ds.Button>
        </div>

      </Ds.Card>
    </div>
  );
}
