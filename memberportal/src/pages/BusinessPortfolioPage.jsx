import React, { useState, useEffect } from 'react';
import { IconBriefcase, IconCheck, IconArrowLeft } from '@tabler/icons-react';
import { useNavigate } from 'react-router-dom';
import * as Ds from '../components/ui';
import api from '../lib/api';

export default function BusinessPortfolioPage() {
  const navigate = useNavigate();
  const [loading, setLoading] = useState(true);
  const [formData, setFormData] = useState({
    business_name: '',
    description: '',
    website: '',
    address: '',
    established_year: '',
    br_number: '',
    google_maps_url: '',
    linkedin_url: '',
    facebook_url: '',
    instagram_url: '',
    logo_url: ''
  });
  
  const [isSubmitting, setIsSubmitting] = useState(false);
  const [success, setSuccess] = useState('');
  const [error, setError] = useState('');

  useEffect(() => {
    const fetchBusiness = async () => {
      try {
        const res = await api.get('/auth/me/business');
        if (res.data) {
          setFormData({
            business_name: res.data.data?.business_name || res.data.business_name || '',
            description: res.data.data?.description || res.data.description || '',
            website: res.data.data?.website || res.data.website || '',
            address: res.data.data?.address || res.data.address || '',
            established_year: res.data.data?.established_year || res.data.established_year || '',
            br_number: res.data.data?.br_number || res.data.br_number || '',
            google_maps_url: res.data.data?.google_maps_url || res.data.google_maps_url || '',
            linkedin_url: res.data.data?.linkedin_url || res.data.linkedin_url || '',
            facebook_url: res.data.data?.facebook_url || res.data.facebook_url || '',
            instagram_url: res.data.data?.instagram_url || res.data.instagram_url || '',
            logo_url: res.data.data?.logo_url || res.data.logo_url || ''
          });
        }
      } catch (err) {
        if (err.response?.status !== 404) {
          console.error('Failed to fetch business', err);
          setError('Failed to load your business details.');
        }
      } finally {
        setLoading(false);
      }
    };
    fetchBusiness();
  }, []);

  const handleChange = (e) => {
    setFormData({ ...formData, [e.target.name]: e.target.value });
  };

  const logoInputRef = React.useRef(null);

  const handleSubmit = async (e) => {
    e.preventDefault();
    setIsSubmitting(true);
    setError('');
    setSuccess('');

    try {
      await api.put('/auth/me/business', formData);
      setSuccess('Business portfolio updated successfully.');
    } catch (err) {
      setError(err.response?.data?.error?.message || err.response?.data?.message || 'Failed to update business portfolio.');
    } finally {
      setIsSubmitting(false);
    }
  };

  const handleLogoUpload = async (e) => {
    const file = e.target.files[0];
    if (!file) return;

    const fd = new FormData();
    fd.append('file', file);

    try {
      setError('');
      const res = await api.post('/auth/me/business/logo', fd, {
        headers: { 'Content-Type': 'multipart/form-data' }
      });
      const newLogoUrl = res.data?.data?.logo_url || res.data?.logo_url;
      if (newLogoUrl) {
        setFormData(prev => ({ ...prev, logo_url: newLogoUrl }));
        setSuccess('Business logo uploaded successfully.');
      }
    } catch (err) {
      setError(err.response?.data?.error?.message || err.response?.data?.message || 'Failed to upload logo.');
    }
  };

  if (loading) {
    return (
      <div className="dashboard-body">
        <Ds.EmptyState icon={Ds.Spinner} title="Loading Portfolio..." />
      </div>
    );
  }

  return (
    <div className="dashboard-body" style={{ maxWidth: '1000px', margin: '0 auto', paddingBottom: '3rem' }}>
      <div style={{ marginBottom: '2rem' }}>
        <Ds.Button variant="ghost" leftIcon={<IconArrowLeft size={16} />} onClick={() => navigate('/profile')}>
          Back to Profile
        </Ds.Button>
      </div>

      <Ds.PageHeader
        title="Business Portfolio"
        description="Update your business details. A complete profile is required for verification and helps you get more referrals."
      />

      {success && (
        <div style={{ marginBottom: '1.5rem', padding: '1rem', background: 'var(--brand-green-50)', color: 'var(--brand-green-700)', borderRadius: 'var(--radius-md)', display: 'flex', alignItems: 'center', gap: '0.5rem' }}>
          <IconCheck size={18} />
          {success}
        </div>
      )}
      
      {error && (
        <div style={{ marginBottom: '1.5rem', padding: '1rem', background: 'var(--brand-red-50)', color: 'var(--brand-red-600)', borderRadius: 'var(--radius-md)' }}>
          {error}
        </div>
      )}

      <form onSubmit={handleSubmit}>
        <div style={{ display: 'grid', gridTemplateColumns: 'repeat(auto-fit, minmax(400px, 1fr))', gap: '2rem' }}>
          {/* Left Column */}
          <div style={{ display: 'flex', flexDirection: 'column', gap: '2rem' }}>
            <Ds.Section title="Company Overview">
              <div style={{ display: 'flex', alignItems: 'center', gap: '1.5rem', marginBottom: '1.5rem' }}>
                <Ds.Avatar 
                  name={formData.business_name} 
                  src={formData.logo_url} 
                  size="xl" 
                  style={{ width: 80, height: 80, borderRadius: '8px', border: '1px solid var(--border-color)' }}
                />
                <div>
                  <input
                    type="file"
                    accept="image/*"
                    style={{ display: 'none' }}
                    ref={logoInputRef}
                    onChange={handleLogoUpload}
                  />
                  <Ds.Button variant="secondary" size="sm" onClick={() => logoInputRef.current?.click()}>
                    Upload Logo
                  </Ds.Button>
                  <div style={{ fontSize: 'var(--text-xs)', color: 'var(--fg-secondary)', marginTop: '0.5rem' }}>
                    Recommended size: 400x400px
                  </div>
                </div>
              </div>

              <div style={{ display: 'grid', gridTemplateColumns: '1fr', gap: '1.5rem' }}>
                <Ds.Field label="Business Name">
                  <Ds.Input
                    type="text"
                    name="business_name"
                    value={formData.business_name}
                    onChange={handleChange}
                    required
                  />
                </Ds.Field>
                <Ds.Field label="Description" hint="A short summary of what your business does.">
                  <Ds.Textarea
                    name="description"
                    value={formData.description}
                    onChange={handleChange}
                    rows={4}
                  />
                </Ds.Field>
              </div>
            </Ds.Section>

            <Ds.Section title="Social Links">
              <div style={{ display: 'grid', gridTemplateColumns: '1fr', gap: '1.5rem' }}>
                <Ds.Field label="LinkedIn Profile">
                  <Ds.Input
                    type="url"
                    name="linkedin_url"
                    value={formData.linkedin_url}
                    onChange={handleChange}
                    placeholder="https://linkedin.com/company/..."
                  />
                </Ds.Field>
                <Ds.Field label="Facebook Page">
                  <Ds.Input
                    type="url"
                    name="facebook_url"
                    value={formData.facebook_url}
                    onChange={handleChange}
                    placeholder="https://facebook.com/..."
                  />
                </Ds.Field>
                <Ds.Field label="Instagram Profile">
                  <Ds.Input
                    type="url"
                    name="instagram_url"
                    value={formData.instagram_url}
                    onChange={handleChange}
                    placeholder="https://instagram.com/..."
                  />
                </Ds.Field>
              </div>
            </Ds.Section>
          </div>

          {/* Right Column */}
          <div style={{ display: 'flex', flexDirection: 'column', gap: '2rem' }}>
            <Ds.Section title="Business Details" description="These details help verify your business entity.">
              <div style={{ display: 'grid', gridTemplateColumns: '1fr 1fr', gap: '1.5rem' }}>
                <div style={{ gridColumn: '1 / -1' }}>
                  <Ds.Field label="Address">
                    <Ds.Textarea
                      name="address"
                      value={formData.address}
                      onChange={handleChange}
                      rows={2}
                    />
                  </Ds.Field>
                </div>
                <Ds.Field label="BR Number">
                  <Ds.Input
                    type="text"
                    name="br_number"
                    value={formData.br_number}
                    onChange={handleChange}
                  />
                </Ds.Field>
                <Ds.Field label="Established Year">
                  <Ds.Input
                    type="text"
                    name="established_year"
                    value={formData.established_year}
                    onChange={handleChange}
                    placeholder="YYYY"
                  />
                </Ds.Field>
                <div style={{ gridColumn: '1 / -1' }}>
                  <Ds.Field label="Website">
                    <Ds.Input
                      type="url"
                      name="website"
                      value={formData.website}
                      onChange={handleChange}
                      placeholder="https://"
                    />
                  </Ds.Field>
                </div>
                <div style={{ gridColumn: '1 / -1' }}>
                  <Ds.Field label="Google Maps URL">
                    <Ds.Input
                      type="url"
                      name="google_maps_url"
                      value={formData.google_maps_url}
                      onChange={handleChange}
                      placeholder="https://maps.app.goo.gl/..."
                    />
                  </Ds.Field>
                </div>
              </div>
            </Ds.Section>
          </div>
        </div>

        <div style={{ display: 'flex', justifyContent: 'flex-end', marginTop: '2rem', paddingBottom: '1rem' }}>
          <Ds.Button
            type="submit"
            variant="primary"
            loading={isSubmitting}
            leftIcon={<IconCheck size={16} />}
          >
            Save Portfolio
          </Ds.Button>
        </div>
      </form>
    </div>
  );
}
