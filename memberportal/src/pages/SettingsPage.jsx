import React, { useState, useEffect } from 'react';
import { IconServer, IconCheck } from '@tabler/icons-react';
import * as Ds from '../components/ui';
import api from '../lib/api';

export default function SettingsPage() {
  const [formData, setFormData] = useState({
    host: '',
    port: 587,
    user: '',
    password: '',
    from_email: '',
    from_name: ''
  });
  
  const [loading, setLoading] = useState(true);
  const [hasPassword, setHasPassword] = useState(false);
  const [isSubmitting, setIsSubmitting] = useState(false);
  const [success, setSuccess] = useState('');
  const [error, setError] = useState('');

  useEffect(() => {
    const fetchSettings = async () => {
      try {
        const res = await api.get('/members/smtp-settings');
        if (res.data?.data) {
          const s = res.data.data;
          setFormData({
            host: s.host || '',
            port: s.port || 587,
            user: s.user || '',
            password: '', // keep empty on load
            from_email: s.from_email || '',
            from_name: s.from_name || ''
          });
          setHasPassword(s.has_password || false);
        }
      } catch (err) {
        console.error('Failed to fetch SMTP settings', err);
      } finally {
        setLoading(false);
      }
    };
    fetchSettings();
  }, []);

  const handleChange = (e) => {
    setFormData({ ...formData, [e.target.name]: e.target.value });
  };

  const handleSubmit = async (e) => {
    e.preventDefault();
    setIsSubmitting(true);
    setError('');
    setSuccess('');

    try {
      await api.post('/members/smtp-settings', {
        host: formData.host,
        port: parseInt(formData.port),
        user: formData.user,
        password: formData.password || null, // send null if unchanged/empty
        from_email: formData.from_email || null,
        from_name: formData.from_name || null
      });
      setSuccess('SMTP settings securely saved to your profile.');
      setHasPassword(true); // user saved/updated a password successfully
      setFormData(prev => ({ ...prev, password: '' })); // clear the field
    } catch (err) {
      setError(err.response?.data?.error?.message || 'Failed to save settings.');
    } finally {
      setIsSubmitting(false);
    }
  };

  if (loading) {
    return (
      <div className="dashboard-body">
        <Ds.PageHeader
          title="Email Configuration"
          description="Connect your personal or corporate email server to send messages directly from your own address."
        />
        <div style={{ display: 'flex', justifyContent: 'center', padding: '4rem' }}>
          <Ds.Spinner size="lg" />
        </div>
      </div>
    );
  }

  return (
    <div className="dashboard-body">
      <Ds.PageHeader
        title="Email Configuration"
        description="Connect your personal or corporate email server to send messages directly from your own address."
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
        <Ds.Section
          title="SMTP Credentials"
          description="Your password is encrypted before saving to our database."
        >
          <div style={{ display: 'grid', gridTemplateColumns: '1fr 1fr', gap: '1.5rem' }}>
            <Ds.Field label="SMTP Host">
              <Ds.Input
                type="text"
                name="host"
                value={formData.host}
                onChange={handleChange}
                placeholder="smtp.gmail.com"
                required
              />
            </Ds.Field>
            <Ds.Field label="SMTP Port">
              <Ds.Input
                type="number"
                name="port"
                value={formData.port}
                onChange={handleChange}
                required
              />
            </Ds.Field>
            <Ds.Field label="Username">
              <Ds.Input
                type="text"
                name="user"
                value={formData.user}
                onChange={handleChange}
                placeholder="you@example.com"
                required
              />
            </Ds.Field>
            <Ds.Field label="Password / App Password" hint={hasPassword ? "Password is configured. Leave blank to keep existing password." : ""}>
              <Ds.Input
                type="password"
                name="password"
                value={formData.password}
                onChange={handleChange}
                placeholder={hasPassword ? "••••••••" : "Your email password"}
                required={!hasPassword}
              />
            </Ds.Field>
          </div>
        </Ds.Section>

        <Ds.Section
          title="Sender Identity"
          description="Optional: Override the default sender name and email address."
        >
          <div style={{ display: 'grid', gridTemplateColumns: '1fr 1fr', gap: '1.5rem' }}>
            <Ds.Field label="From Email" hint="Leave blank to use username">
              <Ds.Input
                type="email"
                name="from_email"
                value={formData.from_email}
                onChange={handleChange}
                placeholder="you@company.com"
              />
            </Ds.Field>
            <Ds.Field label="From Name" hint="e.g. John Doe">
              <Ds.Input
                type="text"
                name="from_name"
                value={formData.from_name}
                onChange={handleChange}
                placeholder="John Doe"
              />
            </Ds.Field>
          </div>
        </Ds.Section>

        <div style={{ display: 'flex', justifyContent: 'flex-end', marginTop: '2rem' }}>
          <Ds.Button
            type="submit"
            variant="primary"
            loading={isSubmitting}
            leftIcon={<IconCheck size={16} />}
          >
            Save Configuration
          </Ds.Button>
        </div>
      </form>
    </div>
  );
}
