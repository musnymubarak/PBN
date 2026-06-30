import React, { useState } from 'react';
import { useAuth } from '../context/AuthContext';
import { useNavigate, useLocation } from 'react-router-dom';
import { IconLock, IconMail } from '@tabler/icons-react';
import * as Ds from '../components/ui';

export default function LoginPage() {
  const [identifier, setIdentifier] = useState('');
  const [password, setPassword] = useState('');
  const [error, setError] = useState('');
  const [isSubmitting, setIsSubmitting] = useState(false);
  
  const { login } = useAuth();
  const navigate = useNavigate();
  const location = useLocation();

  const from = location.state?.from?.pathname || "/members";

  const handleSubmit = async (e) => {
    e.preventDefault();
    setError('');
    setIsSubmitting(true);
    
    const result = await login(identifier, password);
    if (result.success) {
      navigate(from, { replace: true });
    } else {
      setError(result.error);
      setIsSubmitting(false);
    }
  };

  return (
    <div style={{ minHeight: '100vh', display: 'flex', alignItems: 'center', justifyContent: 'center', background: 'var(--bg-subtle)' }}>
      <div style={{ width: '100%', maxWidth: 420, padding: '2rem' }}>
        <div style={{ textAlign: 'center', marginBottom: '2rem' }}>
          <h1 style={{ fontSize: '1.5rem', fontWeight: 800, color: 'var(--fg-primary)' }}>
            PBN <span style={{ color: 'var(--brand-blue)' }}>Portal</span>
          </h1>
          <p style={{ color: 'var(--fg-secondary)', marginTop: '0.5rem' }}>Sign in to your member account</p>
        </div>

        <Ds.Card style={{ padding: '2rem' }}>
          {error && (
            <div style={{ marginBottom: '1.5rem', padding: '1rem', background: 'var(--brand-red-50)', color: 'var(--brand-red-600)', borderRadius: 'var(--radius-md)', fontSize: 'var(--text-sm)' }}>
              {error}
            </div>
          )}

          <form onSubmit={handleSubmit}>
            <Ds.Field label="Email or Phone">
              <Ds.Input
                type="text"
                value={identifier}
                onChange={(e) => setIdentifier(e.target.value)}
                placeholder="you@example.com"
                leftIcon={<IconMail size={16} />}
                required
              />
            </Ds.Field>

            <Ds.Field label="Password">
              <Ds.Input
                type="password"
                value={password}
                onChange={(e) => setPassword(e.target.value)}
                placeholder="••••••••"
                leftIcon={<IconLock size={16} />}
                required
              />
            </Ds.Field>

            <Ds.Button
              type="submit"
              variant="primary"
              style={{ width: '100%', marginTop: '1rem' }}
              loading={isSubmitting}
            >
              Sign In
            </Ds.Button>
          </form>
        </Ds.Card>
      </div>
    </div>
  );
}
