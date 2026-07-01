import React, { useState, useEffect } from 'react';
import * as Ds from '../ui';
import { IconX, IconCheck, IconUpload, IconInfoCircle } from '@tabler/icons-react';
import api from '../../lib/api';

export default function CreateListingModal({ isOpen, onClose, listing, onSuccess }) {
  const [industries, setIndustries] = useState([]);
  const [loadingIndustries, setLoadingIndustries] = useState(false);
  const [isSubmitting, setIsSubmitting] = useState(false);
  const [error, setError] = useState('');
  
  const [formData, setFormData] = useState({
    title: '',
    description: '',
    category: 'product',
    industry_category_id: '',
    regular_price: '',
    member_price: '',
    currency: 'LKR',
    price_note: '',
    image_urls: [],
    whatsapp_number: '',
    contact_email: '',
    contact_phone: ''
  });

  const [uploading, setUploading] = useState(false);

  useEffect(() => {
    if (isOpen) {
      fetchIndustries();
      if (listing) {
        setFormData({
          title: listing.title || '',
          description: listing.description || '',
          category: listing.category || 'product',
          industry_category_id: listing.industry_category_id || '',
          regular_price: listing.regular_price || '',
          member_price: listing.member_price || '',
          currency: listing.currency || 'LKR',
          price_note: listing.price_note || '',
          image_urls: listing.image_urls || [],
          whatsapp_number: listing.whatsapp_number || '',
          contact_email: listing.contact_email || '',
          contact_phone: listing.contact_phone || ''
        });
      } else {
        setFormData({
          title: '',
          description: '',
          category: 'product',
          industry_category_id: '',
          regular_price: '',
          member_price: '',
          currency: 'LKR',
          price_note: '',
          image_urls: [],
          whatsapp_number: '',
          contact_email: '',
          contact_phone: ''
        });
      }
      setError('');
    }
  }, [isOpen, listing]);

  const fetchIndustries = async () => {
    setLoadingIndustries(true);
    try {
      const res = await api.get('/industry-categories');
      setIndustries(res.data?.data || res.data || []);
    } catch (err) {
      console.error('Failed to fetch industries', err);
    } finally {
      setLoadingIndustries(false);
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
        setFormData(prev => ({
          ...prev,
          image_urls: [url] // Store single primary image in list
        }));
      }
    } catch (err) {
      setError(err.response?.data?.error?.message || 'Failed to upload image.');
    } finally {
      setUploading(false);
    }
  };

  const handleSubmit = async (e) => {
    e.preventDefault();
    if (!formData.industry_category_id) {
      setError('Please select an industry category.');
      return;
    }

    setIsSubmitting(true);
    setError('');

    const payload = {
      ...formData,
      regular_price: formData.regular_price ? parseFloat(formData.regular_price) : null,
      member_price: formData.member_price ? parseFloat(formData.member_price) : null
    };

    try {
      if (listing) {
        await api.patch(`/marketplace/listings/${listing.id}`, payload);
      } else {
        await api.post('/marketplace/listings', payload);
      }
      onSuccess();
      onClose();
    } catch (err) {
      setError(err.response?.data?.error?.message || err.response?.data?.message || 'Failed to save listing.');
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
      <Ds.Card style={{ width: '100%', maxWidth: '650px', maxHeight: '90vh', display: 'flex', flexDirection: 'column', borderRadius: '24px', overflow: 'hidden' }}>
        
        {/* Modal Header */}
        <div style={{ padding: '1.5rem', borderBottom: '1px solid var(--border-subtle)', display: 'flex', justifyContent: 'space-between', alignItems: 'center' }}>
          <h2 style={{ fontSize: '1.25rem', fontWeight: 900, margin: 0, color: 'var(--fg-primary)' }}>
            {listing ? 'Edit Marketplace Offer' : 'Post a Marketplace Offer'}
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

          <form id="listing-form" onSubmit={handleSubmit}>
            <div style={{ display: 'flex', flexDirection: 'column', gap: '1.5rem' }}>
              
              <Ds.Section title="General Information">
                <div style={{ display: 'flex', flexDirection: 'column', gap: '1rem' }}>
                  <Ds.Field label="Offer Title" hint="Provide a clear, engaging title.">
                    <Ds.Input type="text" name="title" value={formData.title} onChange={handleChange} required placeholder="e.g., Premium Web Design Package" />
                  </Ds.Field>

                  <div style={{ display: 'grid', gridTemplateColumns: '1fr 1fr', gap: '1rem' }}>
                    <Ds.Field label="Category">
                      <select 
                        name="category" 
                        value={formData.category} 
                        onChange={handleChange}
                        style={{
                          width: '100%', padding: '0.75rem 1rem', borderRadius: '12px',
                          border: '1px solid var(--border-subtle)', background: 'var(--bg-canvas)',
                          color: 'var(--fg-primary)', fontSize: 'var(--text-sm)', fontWeight: 700
                        }}
                      >
                        <option value="product">Product</option>
                        <option value="service">Service</option>
                        <option value="consultation">Consultation</option>
                      </select>
                    </Ds.Field>

                    <Ds.Field label="Industry">
                      <select 
                        name="industry_category_id" 
                        value={formData.industry_category_id} 
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
                  </div>
                </div>
              </Ds.Section>

              <Ds.Section title="Pricing & Notes">
                <div style={{ display: 'flex', flexDirection: 'column', gap: '1rem' }}>
                  <div style={{ display: 'grid', gridTemplateColumns: '1fr 1fr', gap: '1rem' }}>
                    <Ds.Field label="Regular Price (LKR)" hint="Optional">
                      <Ds.Input type="number" name="regular_price" value={formData.regular_price} onChange={handleChange} placeholder="e.g. 15000" />
                    </Ds.Field>

                    <Ds.Field label="Exclusive Member Price (LKR)" hint="Optional">
                      <Ds.Input type="number" name="member_price" value={formData.member_price} onChange={handleChange} placeholder="e.g. 12000" />
                    </Ds.Field>
                  </div>

                  <Ds.Field label="Price Note" hint="e.g. 'one-time fee', 'per user/month', 'minimum 5 items'">
                    <Ds.Input type="text" name="price_note" value={formData.price_note} onChange={handleChange} placeholder="e.g., per user / month" />
                  </Ds.Field>
                </div>
              </Ds.Section>

              <Ds.Section title="Listing Media">
                <Ds.Field label="Offer Image" hint="Upload a primary product or service graphic (Max 5MB)">
                  <div style={{ display: 'flex', alignItems: 'center', gap: '1rem', marginTop: '0.25rem' }}>
                    {formData.image_urls[0] && (
                      <div style={{ position: 'relative', width: '80px', height: '80px', borderRadius: '12px', overflow: 'hidden', border: '1px solid var(--border-subtle)' }}>
                        <img src={formData.image_urls[0]} alt="Preview" style={{ width: '100%', height: '100%', objectFit: 'cover' }} />
                      </div>
                    )}
                    <label style={{
                      display: 'flex', flexDirection: 'column', alignItems: 'center', justifyContent: 'center',
                      width: formData.image_urls[0] ? '120px' : '100%', height: '80px',
                      border: '2px dashed var(--border-subtle)', borderRadius: '12px',
                      cursor: 'pointer', background: 'var(--bg-canvas)', color: 'var(--fg-secondary)',
                      fontSize: '0.8rem', fontWeight: 700, gap: '4px', transition: 'all 0.2s'
                    }}>
                      <IconUpload size={20} style={{ color: 'var(--brand-blue)' }} />
                      <span>{uploading ? 'Uploading...' : 'Choose File'}</span>
                      <input type="file" accept="image/*" onChange={handleImageUpload} style={{ display: 'none' }} disabled={uploading} />
                    </label>
                  </div>
                </Ds.Field>
              </Ds.Section>

              <Ds.Section title="Contact Information">
                <div style={{ display: 'grid', gridTemplateColumns: '1fr 1fr', gap: '1rem' }}>
                  <Ds.Field label="Contact Phone">
                    <Ds.Input type="text" name="contact_phone" value={formData.contact_phone} onChange={handleChange} placeholder="e.g. +94 777 123 456" />
                  </Ds.Field>
                  <Ds.Field label="WhatsApp Number">
                    <Ds.Input type="text" name="whatsapp_number" value={formData.whatsapp_number} onChange={handleChange} placeholder="e.g. +94777123456" />
                  </Ds.Field>
                </div>
                <div style={{ marginTop: '1rem' }}>
                  <Ds.Field label="Contact Email">
                    <Ds.Input type="email" name="contact_email" value={formData.contact_email} onChange={handleChange} placeholder="e.g. info@business.com" />
                  </Ds.Field>
                </div>
              </Ds.Section>

              <Ds.Section title="Offer Description">
                <Ds.Field label="Description" hint="Describe your B2B offer and exclusive benefits for PBN members.">
                  <Ds.Textarea name="description" value={formData.description} onChange={handleChange} required rows={4} placeholder="Detail your service features, delivery terms, and members discount..." />
                </Ds.Field>
              </Ds.Section>

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
            form="listing-form" 
            variant="primary" 
            loading={isSubmitting} 
            leftIcon={<IconCheck size={16} />}
          >
            {listing ? 'Save Offer' : 'Submit Offer'}
          </Ds.Button>
        </div>

      </Ds.Card>
    </div>
  );
}
