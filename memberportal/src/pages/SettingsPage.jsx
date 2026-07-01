import React, { useState } from 'react';
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
  
  const [isSubmitting, setIsSubmitting] = useState(false);
  const [success, setSuccess] = useState('');
  const [error, setError] = useState('');

  const handleChange = (e) => {
    setFormData({ ...formData, [e.target.name]: e.target.value });
  };

  const handleSubmit = async (e) => {
    e.preventDefault();
    setIsSubmitting(true);
    setError('');
    setSuccess('');

    try {
      await api.post('/community/members/smtp-settings', {
        host: formData.host,
        port: parseInt(formData.port),
        user: formData.user,
        password: formData.password,
        from_email: formData.from_email || null,
        from_name: formData.from_name || null
      });
      setSuccess('SMTP settings securely saved to your profile.');
    } catch (err) {
      setError(err.response?.data?.error?.message || 'Failed to save settings.');
    } finally {
      setIsSubmitting(false);
    }
  };

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
            <Ds.Field label="Password / App Password">
              <Ds.Input
                type="password"
                name="password"
                value={formData.password}
                onChange={handleChange}
                required
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
