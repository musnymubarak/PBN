import React, { useState } from 'react';
import { IconLock, IconCheck, IconArrowLeft } from '@tabler/icons-react';
import { useNavigate } from 'react-router-dom';
import * as Ds from '../components/ui';
import api from '../lib/api';

export default function ChangePasswordPage() {
  const navigate = useNavigate();
  const [formData, setFormData] = useState({
    current_password: '',
    new_password: '',
    confirm_password: ''
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

    if (formData.new_password !== formData.confirm_password) {
      setError('New passwords do not match.');
      setIsSubmitting(false);
      return;
    }

    try {
      await api.put('/auth/change-password', {
        current_password: formData.current_password,
        new_password: formData.new_password,
        confirm_password: formData.confirm_password
      });
      setSuccess('Your password has been changed successfully.');
      setFormData({ current_password: '', new_password: '', confirm_password: '' });
    } catch (err) {
      setError(err.response?.data?.error?.message || err.response?.data?.message || 'Failed to change password.');
    } finally {
      setIsSubmitting(false);
    }
  };

  return (
    <div className="dashboard-body" style={{ maxWidth: '1000px', margin: '0 auto', paddingBottom: '3rem' }}>
      <div style={{ marginBottom: '2rem' }}>
        <Ds.Button variant="ghost" leftIcon={<IconArrowLeft size={16} />} onClick={() => navigate('/profile')}>
          Back to Profile
        </Ds.Button>
      </div>

      <Ds.PageHeader
        title="Change Password"
        description="Ensure your account is using a long, random password to stay secure."
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
        <Ds.Card padded>
          <div style={{ display: 'flex', flexDirection: 'column', gap: '1.5rem' }}>
            <Ds.Field label="Current Password">
              <Ds.Input
                type="password"
                name="current_password"
                value={formData.current_password}
                onChange={handleChange}
                required
              />
            </Ds.Field>
            <Ds.Field label="New Password">
              <Ds.Input
                type="password"
                name="new_password"
                value={formData.new_password}
                onChange={handleChange}
                required
              />
            </Ds.Field>
            <Ds.Field label="Confirm New Password">
              <Ds.Input
                type="password"
                name="confirm_password"
                value={formData.confirm_password}
                onChange={handleChange}
                required
              />
            </Ds.Field>
          </div>
        </Ds.Card>

        <div style={{ display: 'flex', justifyContent: 'flex-end', marginTop: '2rem' }}>
          <Ds.Button
            type="submit"
            variant="primary"
            loading={isSubmitting}
            leftIcon={<IconLock size={16} />}
          >
            Update Password
          </Ds.Button>
        </div>
      </form>
    </div>
  );
}
