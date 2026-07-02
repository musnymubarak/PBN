import React, { useState, useEffect } from 'react';
import { useAuth } from '../context/AuthContext';
import { useNavigate, useLocation } from 'react-router-dom';
import { 
  IconUsers, 
  IconBrandFacebook, 
  IconBrandLinkedin, 
  IconBrandYoutube,
  IconEye,
  IconEyeOff,
  IconLock,
  IconShieldCheck,
  IconArrowLeft
} from '@tabler/icons-react';
import api from '../lib/api';

export default function LoginPage() {
  const [view, setView] = useState('login'); // 'login' | 'tfa' | 'forgot_request' | 'forgot_reset'
  const [identifier, setIdentifier] = useState('');
  const [password, setPassword] = useState('');
  const [showPassword, setShowPassword] = useState(false);
  const [error, setError] = useState('');
  const [successMsg, setSuccessMsg] = useState('');
  const [isSubmitting, setIsSubmitting] = useState(false);
  
  // 2FA State
  const [tfaToken, setTfaToken] = useState('');
  const [tfaOtp, setTfaOtp] = useState('');

  // Forgot Password Reset State
  const [forgotOtp, setForgotOtp] = useState('');
  const [forgotNewPassword, setForgotNewPassword] = useState('');
  const [forgotConfirmPassword, setForgotConfirmPassword] = useState('');

  const { login, verify2FA } = useAuth();
  const navigate = useNavigate();
  const location = useLocation();

  const from = location.state?.from?.pathname || "/members";

  useEffect(() => {
    const originalBg = document.body.style.backgroundColor;
    const originalHtmlBg = document.documentElement.style.backgroundColor;
    const rootEl = document.getElementById('root');
    const originalRootBg = rootEl ? rootEl.style.backgroundColor : '';

    document.body.style.backgroundColor = '#0e1535';
    document.documentElement.style.backgroundColor = '#0e1535';
    if (rootEl) {
      rootEl.style.backgroundColor = '#0e1535';
    }

    return () => {
      document.body.style.backgroundColor = originalBg;
      document.documentElement.style.backgroundColor = originalHtmlBg;
      if (rootEl) {
        rootEl.style.backgroundColor = originalRootBg;
      }
    };
  }, []);

  // Login handler
  const handleLogin = async (e) => {
    e.preventDefault();
    setError('');
    setSuccessMsg('');
    setIsSubmitting(true);
    
    const result = await login(identifier, password);
    if (result.success) {
      if (result.requires2FA) {
        setTfaToken(result.tfaToken);
        setView('tfa');
        setIsSubmitting(false);
      } else {
        navigate(from, { replace: true });
      }
    } else {
      setError(result.error);
      setIsSubmitting(false);
    }
  };

  // 2FA Verification handler
  const handleVerify2FA = async (e) => {
    e.preventDefault();
    setError('');
    setSuccessMsg('');
    setIsSubmitting(true);

    const result = await verify2FA(tfaToken, tfaOtp);
    if (result.success) {
      navigate(from, { replace: true });
    } else {
      setError(result.error);
      setIsSubmitting(false);
    }
  };

  // 2FA Code Resend handler
  const handleResend2FA = async () => {
    setError('');
    setSuccessMsg('');
    setIsSubmitting(true);
    try {
      await api.post('/auth/resend-2fa', { tfa_token: tfaToken });
      setSuccessMsg('A new verification code has been sent to your email.');
      setIsSubmitting(false);
    } catch (err) {
      setError(err.response?.data?.error?.message || 'Failed to resend verification code.');
      setIsSubmitting(false);
    }
  };

  // Forgot password OTP Request handler
  const handleForgotRequest = async (e) => {
    e.preventDefault();
    setError('');
    setSuccessMsg('');
    setIsSubmitting(true);
    try {
      await api.post('/auth/forgot-password', { identifier });
      setSuccessMsg('An OTP has been sent to your registered email.');
      setView('forgot_reset');
      setIsSubmitting(false);
    } catch (err) {
      setError(err.response?.data?.error?.message || 'Failed to initiate password reset.');
      setIsSubmitting(false);
    }
  };

  // Password Reset Completion handler
  const handleForgotReset = async (e) => {
    e.preventDefault();
    setError('');
    setSuccessMsg('');

    if (forgotNewPassword.length < 6) {
      setError('Password must be at least 6 characters.');
      return;
    }
    if (forgotNewPassword !== forgotConfirmPassword) {
      setError('Passwords do not match.');
      return;
    }

    setIsSubmitting(true);
    try {
      await api.post('/auth/reset-password', {
        identifier,
        otp: forgotOtp,
        new_password: forgotNewPassword,
        confirm_password: forgotConfirmPassword
      });
      setSuccessMsg('Password reset successfully! Please sign in.');
      setView('login');
      setIsSubmitting(false);
    } catch (err) {
      setError(err.response?.data?.error?.message || 'Failed to reset password. Please check the OTP.');
      setIsSubmitting(false);
    }
  };

  const navigateToForgotRequest = () => {
    setError('');
    setSuccessMsg('');
    setView('forgot_request');
  };

  const navigateToLogin = () => {
    setError('');
    setSuccessMsg('');
    setView('login');
  };

  return (
    <div className="login-page-v2">
      {/* Premium floating background orbs wrapped to prevent bottom scroll overflow */}
      <div style={{ position: 'absolute', inset: 0, overflow: 'hidden', pointerEvents: 'none', zIndex: 0 }}>
        <div className="login-orb-1" />
      </div>

      {/* Header Bar */}
      <header className="login-header-v2">
        <div className="login-header-brand-v2">
          <div className="login-header-logo-v2">
            PRIME <span>BUSINESS</span> NETWORK
          </div>
          <div className="login-header-divider-v2" />
          <div className="login-header-title-v2">
            Member Portal
          </div>
        </div>
      </header>

      {/* Main Content Area */}
      <main className="login-content-v2">
        <div className="login-split-container-v3">
          {/* Left column: Branding Image Panel */}
          <div className="login-split-image-pane-v3">
            <img src="/ceo_forum.png" alt="PBN CEO Forum" className="login-split-image-v3" />
            <div className="login-split-image-overlay-v3" />
            
            <div className="login-split-image-content-v3">
              <div className="login-badge" style={{ marginBottom: '1rem' }}>Ecosystem</div>
              <h3 className="login-split-image-title-v3">
                Connecting <span>Leaders</span>
              </h3>
              <p className="login-split-image-desc-v3">
                Asia's No. 1 technology-driven Business Growth Ecosystem. Secure your exclusive industry seat today.
              </p>
            </div>
          </div>

          {/* Right column: Interactive Form Panel */}
          <div className="login-split-form-pane-v3">
            {error && (
              <div className="login-error" style={{ marginBottom: '1.5rem' }}>
                {error}
              </div>
            )}
            
            {successMsg && (
              <div className="login-success" style={{
                padding: '0.875rem 1.25rem',
                background: '#ecfdf5',
                border: '1px solid #a7f3d0',
                borderRadius: '14px',
                color: '#047857',
                fontSize: '0.875rem',
                fontWeight: 600,
                marginBottom: '1.5rem'
              }}>
                {successMsg}
              </div>
            )}

            {/* VIEW: LOGIN FORM */}
            {view === 'login' && (
              <>
                <div className="login-card-header-v2">
                  <div className="login-card-icon-wrap-v2">
                    <IconUsers size={28} />
                  </div>
                  <h2 className="login-card-title-v2">Login</h2>
                  <div className="login-card-underline-v2" />
                </div>

                <form onSubmit={handleLogin}>
                  <div className="login-field-v2">
                    <div className="login-field-header-v2">
                      <label htmlFor="identifier">Email Address</label>
                    </div>
                    <div className="login-input-wrap-v2">
                      <input
                        id="identifier"
                        type="text"
                        value={identifier}
                        onChange={(e) => setIdentifier(e.target.value)}
                        placeholder="you@example.com"
                        required
                      />
                    </div>
                  </div>

                  <div className="login-field-v2">
                    <div className="login-field-header-v2">
                      <label htmlFor="password">Password</label>
                      <button
                        type="button"
                        onClick={navigateToForgotRequest}
                        className="forgot-password-link-v2"
                        style={{ background: 'none', border: 'none', padding: 0, cursor: 'pointer' }}
                      >
                        Forgot password?
                      </button>
                    </div>
                    <div className="login-input-wrap-v2">
                      <input
                        id="password"
                        type={showPassword ? 'text' : 'password'}
                        value={password}
                        onChange={(e) => setPassword(e.target.value)}
                        placeholder="••••••••"
                        required
                        style={{ paddingRight: '44px' }}
                      />
                      <button
                        type="button"
                        onClick={() => setShowPassword(!showPassword)}
                        style={{
                          position: 'absolute',
                          right: '12px',
                          background: 'none',
                          border: 'none',
                          cursor: 'pointer',
                          color: 'var(--neutral-400)',
                          display: 'flex',
                          alignItems: 'center',
                          justifyContent: 'center',
                          padding: 0
                        }}
                      >
                        {showPassword ? <IconEyeOff size={18} /> : <IconEye size={18} />}
                      </button>
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

                  <div className="login-apply-link-v2">
                    New to PBN portal?{' '}
                    <a
                      href="https://www.primebusiness.network/#cta"
                      target="_blank"
                      rel="noopener noreferrer"
                    >
                      Apply for membership.
                    </a>
                  </div>
                </form>
              </>
            )}

            {/* VIEW: TWO-FACTOR AUTHENTICATION */}
            {view === 'tfa' && (
              <>
                <div className="login-card-header-v2">
                  <div className="login-card-icon-wrap-v2">
                    <IconShieldCheck size={28} />
                  </div>
                  <h2 className="login-card-title-v2">Verification</h2>
                  <div className="login-card-underline-v2" />
                </div>

                <p style={{
                  fontSize: '0.85rem',
                  color: 'var(--fg-secondary)',
                  textAlign: 'center',
                  marginBottom: '1.75rem',
                  lineHeight: 1.5
                }}>
                  Enter the 6-digit verification code sent to your registered email address.
                </p>

                <form onSubmit={handleVerify2FA}>
                  <div className="login-field-v2">
                    <div className="login-field-header-v2">
                      <label htmlFor="tfaOtp">Verification Code</label>
                    </div>
                    <div className="login-input-wrap-v2">
                      <input
                        id="tfaOtp"
                        type="text"
                        maxLength={6}
                        value={tfaOtp}
                        onChange={(e) => setTfaOtp(e.target.value.replace(/\D/g, ''))}
                        placeholder="••••••"
                        required
                        style={{ textAlign: 'center', letterSpacing: '0.25em', fontSize: '1.1rem' }}
                      />
                    </div>
                  </div>

                  <button
                    type="submit"
                    className="login-btn"
                    disabled={isSubmitting}
                    style={{ marginTop: '1.5rem' }}
                  >
                    {isSubmitting ? (
                      <>
                        <div className="login-spinner" />
                        <span>Verifying...</span>
                      </>
                    ) : (
                      'Verify Code'
                    )}
                  </button>

                  <div style={{ display: 'flex', justifyContent: 'space-between', marginTop: '1.5rem', fontSize: '0.8125rem' }}>
                    <button
                      type="button"
                      onClick={navigateToLogin}
                      style={{
                        background: 'none',
                        border: 'none',
                        color: 'var(--fg-secondary)',
                        cursor: 'pointer',
                        display: 'flex',
                        alignItems: 'center',
                        gap: '4px',
                        fontWeight: 600
                      }}
                    >
                      <IconArrowLeft size={14} /> Back to Sign In
                    </button>
                    
                    <button
                      type="button"
                      onClick={handleResend2FA}
                      disabled={isSubmitting}
                      style={{
                        background: 'none',
                        border: 'none',
                        color: 'var(--brand-blue)',
                        cursor: 'pointer',
                        fontWeight: 700
                      }}
                    >
                      Resend Code
                    </button>
                  </div>
                </form>
              </>
            )}

            {/* VIEW: FORGOT PASSWORD REQUEST */}
            {view === 'forgot_request' && (
              <>
                <div className="login-card-header-v2">
                  <div className="login-card-icon-wrap-v2">
                    <IconLock size={28} />
                  </div>
                  <h2 className="login-card-title-v2">Recovery</h2>
                  <div className="login-card-underline-v2" />
                </div>

                <p style={{
                  fontSize: '0.85rem',
                  color: 'var(--fg-secondary)',
                  textAlign: 'center',
                  marginBottom: '1.75rem',
                  lineHeight: 1.5
                }}>
                  Enter your registered email or phone number to receive a temporary recovery code.
                </p>

                <form onSubmit={handleForgotRequest}>
                  <div className="login-field-v2">
                    <div className="login-field-header-v2">
                      <label htmlFor="forgotIdentifier">Email or Phone</label>
                    </div>
                    <div className="login-input-wrap-v2">
                      <input
                        id="forgotIdentifier"
                        type="text"
                        value={identifier}
                        onChange={(e) => setIdentifier(e.target.value)}
                        placeholder="you@example.com"
                        required
                      />
                    </div>
                  </div>

                  <button
                    type="submit"
                    className="login-btn"
                    disabled={isSubmitting}
                    style={{ marginTop: '1.5rem' }}
                  >
                    {isSubmitting ? (
                      <>
                        <div className="login-spinner" />
                        <span>Sending...</span>
                      </>
                    ) : (
                      'Send Reset Code'
                    )}
                  </button>

                  <div style={{ textAlign: 'center', marginTop: '1.5rem', fontSize: '0.8125rem' }}>
                    <button
                      type="button"
                      onClick={navigateToLogin}
                      style={{
                        background: 'none',
                        border: 'none',
                        color: 'var(--fg-secondary)',
                        cursor: 'pointer',
                        display: 'inline-flex',
                        alignItems: 'center',
                        gap: '4px',
                        fontWeight: 600
                      }}
                    >
                      <IconArrowLeft size={14} /> Back to Sign In
                    </button>
                  </div>
                </form>
              </>
            )}

            {/* VIEW: FORGOT PASSWORD RESET */}
            {view === 'forgot_reset' && (
              <>
                <div className="login-card-header-v2">
                  <div className="login-card-icon-wrap-v2">
                    <IconLock size={28} />
                  </div>
                  <h2 className="login-card-title-v2">Reset Password</h2>
                  <div className="login-card-underline-v2" />
                </div>

                <p style={{
                  fontSize: '0.85rem',
                  color: 'var(--fg-secondary)',
                  textAlign: 'center',
                  marginBottom: '1.75rem',
                  lineHeight: 1.5
                }}>
                  Enter the 6-digit OTP code sent to your email and select your new password credentials.
                </p>

                <form onSubmit={handleForgotReset}>
                  <div className="login-field-v2">
                    <div className="login-field-header-v2">
                      <label htmlFor="forgotOtp">6-Digit OTP Code</label>
                    </div>
                    <div className="login-input-wrap-v2">
                      <input
                        id="forgotOtp"
                        type="text"
                        maxLength={6}
                        value={forgotOtp}
                        onChange={(e) => setForgotOtp(e.target.value.replace(/\D/g, ''))}
                        placeholder="••••••"
                        required
                        style={{ textAlign: 'center', letterSpacing: '0.25em', fontSize: '1.1rem' }}
                      />
                    </div>
                  </div>

                  <div className="login-field-v2">
                    <div className="login-field-header-v2">
                      <label htmlFor="forgotNewPassword">New Password</label>
                    </div>
                    <div className="login-input-wrap-v2">
                      <input
                        id="forgotNewPassword"
                        type={showPassword ? 'text' : 'password'}
                        value={forgotNewPassword}
                        onChange={(e) => setForgotNewPassword(e.target.value)}
                        placeholder="Min 6 characters"
                        required
                        style={{ paddingRight: '44px' }}
                      />
                      <button
                        type="button"
                        onClick={() => setShowPassword(!showPassword)}
                        style={{
                          position: 'absolute',
                          right: '12px',
                          background: 'none',
                          border: 'none',
                          cursor: 'pointer',
                          color: 'var(--neutral-400)',
                          display: 'flex',
                          alignItems: 'center',
                          justifyContent: 'center',
                          padding: 0
                        }}
                      >
                        {showPassword ? <IconEyeOff size={18} /> : <IconEye size={18} />}
                      </button>
                    </div>
                  </div>

                  <div className="login-field-v2">
                    <div className="login-field-header-v2">
                      <label htmlFor="forgotConfirmPassword">Confirm New Password</label>
                    </div>
                    <div className="login-input-wrap-v2">
                      <input
                        id="forgotConfirmPassword"
                        type={showPassword ? 'text' : 'password'}
                        value={forgotConfirmPassword}
                        onChange={(e) => setForgotConfirmPassword(e.target.value)}
                        placeholder="Confirm password"
                        required
                        style={{ paddingRight: '44px' }}
                      />
                    </div>
                  </div>

                  <button
                    type="submit"
                    className="login-btn"
                    disabled={isSubmitting}
                    style={{ marginTop: '1.5rem' }}
                  >
                    {isSubmitting ? (
                      <>
                        <div className="login-spinner" />
                        <span>Updating...</span>
                      </>
                    ) : (
                      'Reset Password'
                    )}
                  </button>

                  <div style={{ textAlign: 'center', marginTop: '1.5rem', fontSize: '0.8125rem' }}>
                    <button
                      type="button"
                      onClick={navigateToForgotRequest}
                      style={{
                        background: 'none',
                        border: 'none',
                        color: 'var(--brand-blue)',
                        cursor: 'pointer',
                        fontWeight: 700
                      }}
                    >
                      Change email/phone
                    </button>
                  </div>
                </form>
              </>
            )}

          </div>
        </div>
      </main>

      {/* SVG Wave Divider */}
      <div className="login-wave-divider-v2">
        <svg
          viewBox="0 0 1440 100"
          fill="#0e1535"
          style={{ display: 'block', width: '100%', height: 'auto', margin: 0, pointerEvents: 'none' }}
        >
          <path d="M0,50 Q360,100 720,50 T1440,50 L1440,100 L0,100 Z" />
        </svg>
      </div>

      {/* Brand Footer */}
      <footer className="login-footer-v2">
        <div className="login-footer-container-v2">
          <div className="login-footer-top-v2">
            <div className="login-footer-links-v2">
              <a href="https://www.primebusiness.network" target="_blank" rel="noopener noreferrer">About PBN</a>
              <a href="https://www.primebusiness.network/privacy-policy.html" target="_blank" rel="noopener noreferrer">Privacy Policy</a>
              <a href="https://www.primebusiness.network" target="_blank" rel="noopener noreferrer">Terms of Use</a>
              <a href="mailto:ilham@primebusiness.network">Contact Us</a>
            </div>
            
            <div className="login-footer-socials-v2">
              <a
                href="https://web.facebook.com/profile.php?id=61589257288388"
                target="_blank"
                rel="noopener noreferrer"
                className="login-footer-social-btn-v2"
                title="Facebook"
              >
                <IconBrandFacebook size={18} />
              </a>
              <a
                href="https://www.linkedin.com/company/prime-business-network/"
                target="_blank"
                rel="noopener noreferrer"
                className="login-footer-social-btn-v2"
                title="LinkedIn"
              >
                <IconBrandLinkedin size={18} />
              </a>
              <a
                href="https://www.youtube.com/channel/UCJHWSU9Zag3Y0yBM3DG60Hg"
                target="_blank"
                rel="noopener noreferrer"
                className="login-footer-social-btn-v2"
                title="YouTube"
              >
                <IconBrandYoutube size={18} />
              </a>
            </div>
          </div>

          <div className="login-footer-middle-v2">
            Prime Business Network (Pvt) Ltd &middot; Colombo, Sri Lanka &middot; +94 777 140 803
          </div>

          <div className="login-footer-bottom-v2">
            <div>
              &copy; 2026 Prime Business Network (Pvt) Ltd. All rights reserved.
            </div>
            <div>
              Powered by{' '}
              <a
                href="https://hashnate.com/"
                target="_blank"
                rel="noopener noreferrer"
                style={{ color: 'inherit', textDecoration: 'underline' }}
              >
                Hashnate
              </a>
            </div>
          </div>
        </div>
      </footer>
    </div>
  );
}
