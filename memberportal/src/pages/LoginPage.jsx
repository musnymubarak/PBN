import React, { useState } from 'react';
import { useAuth } from '../context/AuthContext';
import { useNavigate, useLocation } from 'react-router-dom';
import { IconLock, IconMail, IconUsers, IconTrendingUp, IconBriefcase } from '@tabler/icons-react';

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
    <div className="login-page">
      {/* Premium floating orbs */}
      <div className="login-orb-1" />
      <div className="login-orb-2" />
      
      {/* Radial grid pattern background */}
      <div className="login-bg-pattern" />

      <div className="login-container">
        {/* Left column: Branding Panel */}
        <div className="login-branding">
          <div className="login-branding-grid" />
          
          <div style={{ position: 'relative', zIndex: 2 }}>
            {/* Premium Pill Badge */}
            <div className="login-badge">
              Member Portal
            </div>

            <h1 className="login-brand-title">
              Prime <span style={{ color: 'var(--brand-amber)' }}>Business</span><br />Network
            </h1>
            <p className="login-brand-desc" style={{ marginBottom: '1.5rem' }}>
              Centralized admin hub for managing the network's members, referrals, and business growth across chapters.
            </p>

            {/* Key Business Highlights */}
            <div className="login-features-list">
              <div className="login-feature-item">
                <span className="login-feature-icon">
                  <IconUsers size={20} />
                </span>
                <div>
                  <span className="login-feature-title">Elite Member Directory</span>
                  <p style={{ color: 'rgba(255, 255, 255, 0.65)', fontSize: '0.75rem', marginTop: '2px' }}>
                    Connect with high-caliber, verified professionals across all chapters.
                  </p>
                </div>
              </div>

              <div className="login-feature-item">
                <span className="login-feature-icon">
                  <IconTrendingUp size={20} />
                </span>
                <div>
                  <span className="login-feature-title">Referrals & Growth Tracker</span>
                  <p style={{ color: 'rgba(255, 255, 255, 0.65)', fontSize: '0.75rem', marginTop: '2px' }}>
                    Share and track business opportunities and referral statistics in real-time.
                  </p>
                </div>
              </div>

              <div className="login-feature-item">
                <span className="login-feature-icon">
                  <IconBriefcase size={20} />
                </span>
                <div>
                  <span className="login-feature-title">Marketplace & Deals</span>
                  <p style={{ color: 'rgba(255, 255, 255, 0.65)', fontSize: '0.75rem', marginTop: '2px' }}>
                    Discover special member offers, business proposals, and partnerships.
                  </p>
                </div>
              </div>
            </div>
          </div>

          <div className="login-brand-footer" style={{ position: 'relative', zIndex: 2 }}>
            &copy; 2025 Prime Business Network. All rights reserved.
          </div>
        </div>

        {/* Right column: Form Panel */}
        <div className="login-form-panel">
          <div className="login-form-inner">
            <h2 className="login-title">Welcome Back</h2>
            <p className="login-subtitle">Sign in to the Admin Dashboard</p>

            <form onSubmit={handleSubmit} style={{ marginTop: '2rem' }}>
              {error && (
                <div className="login-error">
                  {error}
                </div>
              )}

              <div className="login-field">
                <label htmlFor="identifier">Email or Phone</label>
                <div className="login-input-wrap">
                  <span className="login-input-icon">
                    <IconMail size={18} />
                  </span>
                  <input
                    id="identifier"
                    type="text"
                    value={identifier}
                    onChange={(e) => setIdentifier(e.target.value)}
                    placeholder="admin@pbn.lk"
                    required
                  />
                </div>
              </div>

              <div className="login-field">
                <label htmlFor="password">Password</label>
                <div className="login-input-wrap">
                  <span className="login-input-icon">
                    <IconLock size={18} />
                  </span>
                  <input
                    id="password"
                    type="password"
                    value={password}
                    onChange={(e) => setPassword(e.target.value)}
                    placeholder="••••••••"
                    required
                  />
                </div>
              </div>

              <button
                type="submit"
                className="login-btn"
                disabled={isSubmitting}
                style={{ marginTop: '2rem' }}
              >
                {isSubmitting ? (
                  <>
                    <div className="login-spinner" />
                    <span>Signing In...</span>
                  </>
                ) : (
                  'Sign In'
                )}
              </button>
            </form>
          </div>
        </div>
      </div>
    </div>
  );
}
