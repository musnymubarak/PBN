import React, { useState, useEffect, useCallback, useRef, useMemo } from 'react';
import {
  IconChartBar,
  IconEdit,
  IconUsers,
  IconHierarchy2,
  IconCoin,
  IconSettings,
  IconBell,
  IconSearch,
  IconUser,
  IconFilter,
  IconDotsVertical,
  IconArrowUpRight,
  IconClock,
  IconChevronRight,
  IconLogout,
  IconFileExport,
  IconClipboardList,
  IconCheck,
  IconX,
  IconCalendarEvent,
  IconEye,
  IconChevronLeft,
  IconRefresh,
  IconListDetails,
  IconLock,
  IconMail,
  IconAlertCircle,
  IconChevronDown,
  IconPlus,
  IconBuildingStore,
  IconGift,
  IconStackPop,
  IconUserCheck,
  IconTrash,
  IconPencil,
  IconStar,
  IconStarFilled,
  IconBuildingCommunity,
  IconMapPin,
  IconInbox,
  IconSend,
  IconArrowBackUp,
  IconPointFilled,
  IconMessages,
} from '@tabler/icons-react';
import { api, STATIC_BASE_URL } from './lib/api';
import { useApi } from './hooks/useApi';
import { AppShell } from './components/layout/AppShell';
import * as Ds from './components/ui';
import DatePicker from 'react-datepicker';
import 'react-datepicker/dist/react-datepicker.css';
import OnboardingPage from './onboarding/OnboardingPage';
import MemberDetailPage from './members/MemberDetailPage';
import HomeSlidesPage from './home-content/HomeSlidesPage';
import ComplementsPage from './complements/ComplementsPage';
import PaymentProofsTab from './payments/PaymentProofsTab';


// ── Login Page ──────────────────────────────────────────────────────────────

function LoginPage({ onLogin }) {
  const [username, setUsername] = useState('');
  const [password, setPassword] = useState('');
  const [loading, setLoading] = useState(false);
  const [error, setError] = useState('');

  const handleSubmit = async (e) => {
    e.preventDefault();
    setError('');
    setLoading(true);
    try {
      const data = await api.adminLogin(username, password);
      localStorage.setItem('access_token', data.access_token);
      if (data.refresh_token) localStorage.setItem('refresh_token', data.refresh_token);
      onLogin(data.user);
    } catch (err) {
      setError(err.message || 'Login failed. Check your credentials.');
    } finally {
      setLoading(false);
    }
  };

  return (
    <div className="login-page">
      <div className="login-bg-pattern" />
      <div className="login-container">
        {/* Left branding panel */}
        <div className="login-branding">
          <div>
            <h1 className="login-brand-title">Prime <span style={{ color: 'var(--accent)' }}>Business</span> Network</h1>
            <p className="login-brand-desc">
              Centralized admin hub for managing the network's members, referrals, and business growth across chapters.
            </p>
          </div>
          <p className="login-brand-footer">
            © 2025 Prime Business Network. All rights reserved.
          </p>
        </div>

        {/* Right login form */}
        <div className="login-form-panel">
          <div className="login-form-inner">
            <div style={{ textAlign: 'center', marginBottom: '2.5rem' }}>
              <h2 className="login-title">Welcome Back</h2>
              <p className="login-subtitle">Sign in to the Admin Dashboard</p>
            </div>

            {error && (
              <div className="login-error">
                <IconAlertCircle size={18} />
                {error}
              </div>
            )}

            <form onSubmit={handleSubmit}>
              <div className="login-field">
                <label htmlFor="username">Email or Phone</label>
                <div className="login-input-wrap">
                  <IconMail size={18} className="login-input-icon" />
                  <input
                    id="username"
                    type="text"
                    placeholder="admin@pbn.lk"
                    value={username}
                    onChange={e => setUsername(e.target.value)}
                    required
                    autoFocus
                  />
                </div>
              </div>

              <div className="login-field">
                <label htmlFor="password">Password</label>
                <div className="login-input-wrap">
                  <IconLock size={18} className="login-input-icon" />
                  <input
                    id="password"
                    type="password"
                    placeholder="••••••••"
                    value={password}
                    onChange={e => setPassword(e.target.value)}
                    required
                  />
                </div>
              </div>

              <button type="submit" className="login-btn" disabled={loading}>
                {loading ? (
                  <>
                    <div className="login-spinner" />
                    Signing in...
                  </>
                ) : 'Sign In'}
              </button>
            </form>
          </div>
        </div>
      </div>
    </div>
  );
}

// MENU_GROUPS extracted to ./components/layout/menuConfig.js

const StatCard = ({ title, value, icon, trend, color }) => (
  <div className="modern-card">
    <div className="card-icon-container" style={{ background: `${color}15`, color }}>
      {React.createElement(icon, { size: 28 })}
    </div>
    <div className="card-val">{value}</div>
    <p className="card-desc">{title}</p>
    {trend && (
      <div className="card-trend">
        <IconArrowUpRight size={14} />
        {trend}% Since Last Month
      </div>
    )}
  </div>
);

const formatCurrency = (val) => {
  if (val == null) return '—';
  if (val >= 1_000_000) return `LKR ${(val / 1_000_000).toFixed(1)}M`;
  if (val >= 1_000) return `LKR ${(val / 1_000).toFixed(1)}K`;
  return `LKR ${val}`;
};

const formatRelativeTime = (dateStr) => {
  if (!dateStr) return '';
  const date = new Date(dateStr);
  if (isNaN(date.getTime())) return '';
  const diffSec = Math.round((Date.now() - date.getTime()) / 1000);
  if (diffSec < 60) return 'just now';
  const diffMin = Math.floor(diffSec / 60);
  if (diffMin < 60) return `${diffMin}m ago`;
  const diffHr = Math.floor(diffMin / 60);
  if (diffHr < 24) return `${diffHr}h ago`;
  const diffDay = Math.floor(diffHr / 24);
  if (diffDay === 1) return 'yesterday';
  if (diffDay < 7) return `${diffDay}d ago`;
  return date.toLocaleDateString(undefined, { month: 'short', day: 'numeric' });
};

// ── Status Helpers ──────────────────────────────────────────────────────────

const STATUS_CONFIG = {
  pending: { label: 'Pending', class: 'pill-pending', color: '#f59e0b', bg: '#fffbeb' },
  fit_call_scheduled: { label: 'Fit Call Scheduled', class: 'pill-scheduled', color: '#8b5cf6', bg: '#f5f3ff' },
  approved: { label: 'Approved', class: 'pill-approved', color: '#059669', bg: '#ecfdf5' },
  rejected: { label: 'Rejected', class: 'pill-rejected', color: '#dc2626', bg: '#fef2f2' },
  waitlisted: { label: 'Waitlisted', class: 'pill-waitlisted', color: '#6b7280', bg: '#f9fafb' },
};

// Referral pipeline status → Ds.Badge variant + label
function referralStatusVariant(status) {
  switch (status) {
    case 'closed_won': return 'success';
    case 'closed_lost': return 'danger';
    case 'in_progress':
    case 'pending': return 'warning';
    case 'qualified': return 'info';
    default: return 'neutral';
  }
}

function referralStatusLabel(status) {
  if (!status) return 'Unknown';
  return String(status).replace(/_/g, ' ').replace(/\b\w/g, c => c.toUpperCase());
}

const getStatusConfig = (status) => STATUS_CONFIG[status] || { label: status, class: '', color: '#6b7280', bg: '#f9fafb' };

const STATUS_BADGE_VARIANT = {
  pending: 'warning',
  fit_call_scheduled: 'info',
  approved: 'success',
  rejected: 'danger',
  waitlisted: 'neutral',
};

const StatusPill = ({ status }) => {
  const cfg = getStatusConfig(status);
  const variant = STATUS_BADGE_VARIANT[status] || 'neutral';
  return (
    <Ds.Badge dot variant={variant}>
      {cfg.label}
    </Ds.Badge>
  );
};


// ── Application Detail Modal ────────────────────────────────────────────────

function ApplicationDetailModal({ appId, onClose, onStatusUpdated }) {
  const [detail, setDetail] = useState(null);
  const [loading, setLoading] = useState(true);
  const [updating, setUpdating] = useState(false);
  const [actionNotes, setActionNotes] = useState('');
  const [showActions, setShowActions] = useState(false);
  const [modalStatus, setModalStatus] = useState(null); // Local choice for status
  const [chapters, setChapters] = useState([]);
  const [selectedChapterId, setSelectedChapterId] = useState('');
  const [paymentStatus, setPaymentStatus] = useState('pending');
  const [errorMessage, setErrorMessage] = useState('');
  const [fitCallDate, setFitCallDate] = useState(new Date());
  const [approvalEmail, setApprovalEmail] = useState('');
  const [isEditing, setIsEditing] = useState(false);
  const [editData, setEditData] = useState({ district: '', chapter_id: '' });
  const [filteredEditChapters, setFilteredEditChapters] = useState([]);
  const [industries, setIndustries] = useState([]);

  useEffect(() => {
    setLoading(true);
    setErrorMessage('');
    Promise.all([
      api.getApplication(appId),
      api.listChapters({ active_only: true }).catch(() => []),
      api.listIndustryCategories().catch(() => []),
    ])
      .then(([appData, chaptersData, industriesData]) => {
        setDetail(appData);
        setChapters(chaptersData || []);
        setIndustries(industriesData || []);
        if (appData.chapter_id) setSelectedChapterId(appData.chapter_id);
        setEditData({ district: appData.district || '', chapter_id: appData.chapter_id || '' });
        setFilteredEditChapters((chaptersData || []).filter(c => c.district === appData.district));
      })
      .catch(err => {
        console.error(err);
        setErrorMessage('Failed to load application data.');
      })
      .finally(() => setLoading(false));
  }, [appId]);

  const parseErrorMessage = (msg) => {
    if (!msg) return 'An unexpected error occurred.';
    // Remove "API 400: /path - " technical parts
    const parts = msg.split(' - ');
    if (parts.length > 1) return parts[1].split(' (')[0];
    return msg;
  };

  const handleStatusUpdate = async (newStatus) => {
    setErrorMessage('');
    if (newStatus === 'approved' && modalStatus !== 'approved') {
      setModalStatus('approved');
      return;
    }

    if (newStatus === 'fit_call_scheduled' && modalStatus !== 'fit_call_scheduled') {
      setModalStatus('fit_call_scheduled');
      return;
    }

    // Approval requires an email — backend sends the onboarding link there.
    if (newStatus === 'approved' && !detail.email) {
      const trimmed = approvalEmail.trim();
      if (!trimmed) {
        setErrorMessage('Email is required to approve. Add the applicant’s email below to send the onboarding link.');
        return;
      }
      if (!/^[^\s@]+@[^\s@]+\.[^\s@]+$/.test(trimmed)) {
        setErrorMessage('Please enter a valid email address.');
        return;
      }
    }

    setUpdating(true);
    try {
      await api.updateApplicationStatus(appId, {
        status: newStatus,
        notes: actionNotes || undefined,
        chapter_id: selectedChapterId || undefined,
        payment_status: newStatus === 'approved' ? paymentStatus : undefined,
        fit_call_date: newStatus === 'fit_call_scheduled' ? fitCallDate.toISOString() : undefined,
        email: (newStatus === 'approved' && !detail.email) ? approvalEmail.trim() : undefined,
      });
      onStatusUpdated();
      onClose();
    } catch (err) {
      console.error('Failed to update:', err);
      setErrorMessage(parseErrorMessage(err.message));
    } finally {
      setUpdating(false);
    }
  };

  const handleEditChange = (field, val) => {
    const newData = { ...editData, [field]: val };
    if (field === 'district') {
      newData.chapter_id = '';
      setFilteredEditChapters(chapters.filter(c => c.district === val));
    }
    setEditData(newData);
  };

  const handleSaveDetails = async () => {
    setUpdating(true);
    setErrorMessage('');
    try {
      await api.patchApplication(appId, editData);
      const freshData = await api.getApplication(appId);
      setDetail(freshData);
      setIsEditing(false);
      onStatusUpdated();
    } catch (err) {
      console.error('Failed to update details:', err);
      setErrorMessage(parseErrorMessage(err.message));
    } finally {
      setUpdating(false);
    }
  };

  const handleDelete = async () => {
    if (!window.confirm('Are you absolutely sure you want to permanently delete this application? This cannot be undone.')) return;
    
    setUpdating(true);
    try {
      await api.deleteApplication(appId);
      onStatusUpdated();
      onClose();
    } catch (err) {
      console.error('Failed to delete:', err);
      setErrorMessage(parseErrorMessage(err.message));
    } finally {
      setUpdating(false);
    }
  };

  if (loading) return (
    <div className="modal-overlay" onClick={(e) => e.target === e.currentTarget && onClose()}>
      <div className="modal-content" onClick={e => e.stopPropagation()}>
        <div style={{ padding: '3rem', textAlign: 'center', color: '#94a3b8' }}>Loading application...</div>
      </div>
    </div>
  );

  if (!detail) return null;

  const statusActions = {
    pending: [
      { status: 'fit_call_scheduled', label: 'Schedule Fit Call', icon: IconCalendarEvent, color: '#8b5cf6' },
      { status: 'approved', label: 'Approve', icon: IconCheck, color: '#059669' },
      { status: 'rejected', label: 'Reject', icon: IconX, color: '#dc2626' },
      { status: 'waitlisted', label: 'Waitlist', icon: IconClock, color: '#6b7280' },
    ],
    fit_call_scheduled: [
      { status: 'approved', label: 'Approve', icon: IconCheck, color: '#059669' },
      { status: 'rejected', label: 'Reject', icon: IconX, color: '#dc2626' },
      { status: 'waitlisted', label: 'Waitlist', icon: IconClock, color: '#6b7280' },
    ],
    waitlisted: [
      { status: 'approved', label: 'Approve', icon: IconCheck, color: '#059669' },
    ],
  };

  const availableActions = statusActions[detail.status] || [];

  return (
    <div className="modal-overlay" onClick={(e) => e.target === e.currentTarget && onClose()}>
      <div className="modal-content app-detail-modal" onClick={e => e.stopPropagation()}>
        {/* Header */}
        <div className="modal-header">
          <div>
            <h2 style={{ fontSize: '1.5rem', fontWeight: 800, margin: 0 }}>Application Details</h2>
            <p style={{ color: 'var(--text-secondary)', fontSize: '0.875rem', marginTop: '0.25rem' }}>
              Review and manage this membership application
            </p>
          </div>
          <div style={{ display: 'flex', gap: '0.75rem', alignItems: 'center' }}>
            {!isEditing ? (
              <Ds.Button 
                variant="outline" 
                size="sm" 
                onClick={() => setIsEditing(true)} 
                leftIcon={<IconEdit size={16} />}
              >
                Edit
              </Ds.Button>
            ) : (
              <>
                <Ds.Button 
                  variant="outline" 
                  size="sm" 
                  onClick={() => { setIsEditing(false); setEditData({ ...detail }); }} 
                  disabled={updating}
                >
                  Cancel
                </Ds.Button>
                <Ds.Button 
                  variant="primary" 
                  size="sm" 
                  onClick={handleSaveDetails} 
                  loading={updating}
                >
                  Save
                </Ds.Button>
              </>
            )}
            <button 
              type="button" 
              className="view-detail-btn" 
              style={{ color: '#ef4444', borderColor: 'transparent', background: '#fef2f2' }} 
              onClick={handleDelete}
              title="Delete Application"
            >
              <IconTrash size={20} />
            </button>
            <button type="button" className="modal-close-btn" onClick={onClose} title="Close">
              <IconX size={20} />
            </button>
          </div>
        </div>

        {/* Body */}
        <div className="modal-body">
          {errorMessage && (
            <div className="modal-error-banner">
              <IconAlertCircle size={20} />
              <div style={{ flex: 1 }}>{errorMessage}</div>
              <button className="error-close" onClick={() => setErrorMessage('')}><IconX size={14} /></button>
            </div>
          )}

          {/* Status Banner */}
          <div className="app-status-banner" style={{ background: getStatusConfig(detail.status).bg, borderLeft: `4px solid ${getStatusConfig(detail.status).color}` }}>
            <div style={{ display: 'flex', alignItems: 'center', gap: '0.75rem' }}>
              <StatusPill status={detail.status} />
              <span style={{ fontSize: '0.875rem', color: 'var(--text-secondary)' }}>
                Applied {new Date(detail.created_at).toLocaleDateString('en-US', { year: 'numeric', month: 'long', day: 'numeric' })}
              </span>
            </div>
          </div>

          {/* Info Grid */}
          {isEditing ? (
            <div style={{ display: 'grid', gridTemplateColumns: '1fr 1fr', gap: '1rem', marginTop: '1rem', background: '#f8fafc', padding: '1.5rem', borderRadius: '8px', border: '1px solid #e2e8f0' }}>
              <div className="form-group">
                <label style={{ display: 'block', marginBottom: '0.5rem', fontSize: '0.875rem', fontWeight: 600, color: 'var(--text-primary)' }}>Full Name</label>
                <Ds.Input type="text" value={editData.full_name || ''} onChange={e => handleEditChange('full_name', e.target.value)} />
              </div>
              <div className="form-group">
                <label style={{ display: 'block', marginBottom: '0.5rem', fontSize: '0.875rem', fontWeight: 600, color: 'var(--text-primary)' }}>Email</label>
                <Ds.Input type="email" value={editData.email || ''} onChange={e => handleEditChange('email', e.target.value)} />
              </div>
              <div className="form-group">
                <label style={{ display: 'block', marginBottom: '0.5rem', fontSize: '0.875rem', fontWeight: 600, color: 'var(--text-primary)' }}>Contact Number</label>
                <Ds.Input type="text" value={editData.contact_number || ''} onChange={e => handleEditChange('contact_number', e.target.value)} />
              </div>
              <div className="form-group">
                <label style={{ display: 'block', marginBottom: '0.5rem', fontSize: '0.875rem', fontWeight: 600, color: 'var(--text-primary)' }}>Business Name</label>
                <Ds.Input type="text" value={editData.business_name || ''} onChange={e => handleEditChange('business_name', e.target.value)} />
              </div>
              <div className="form-group">
                <label style={{ display: 'block', marginBottom: '0.5rem', fontSize: '0.875rem', fontWeight: 600, color: 'var(--text-primary)' }}>District</label>
                <Ds.Select 
                  value={editData.district || ''} 
                  onChange={val => handleEditChange('district', val)}
                  options={Array.from(new Set(chapters.map(c => c.district).filter(Boolean))).map(d => ({ id: d, name: d }))}
                  placeholder="Select District..."
                />
              </div>
              <div className="form-group">
                <label style={{ display: 'block', marginBottom: '0.5rem', fontSize: '0.875rem', fontWeight: 600, color: 'var(--text-primary)' }}>Target Chapter</label>
                <Ds.Select 
                  value={editData.chapter_id || ''} 
                  onChange={val => handleEditChange('chapter_id', val)} 
                  disabled={!editData.district}
                  options={filteredEditChapters}
                  placeholder={editData.district ? 'Select Chapter...' : 'Select District first'}
                />
              </div>
              <div className="form-group" style={{ gridColumn: '1 / -1' }}>
                <label style={{ display: 'block', marginBottom: '0.5rem', fontSize: '0.875rem', fontWeight: 600, color: 'var(--text-primary)' }}>Industry</label>
                <Ds.Select 
                  value={editData.industry_category_id || ''} 
                  onChange={val => handleEditChange('industry_category_id', val)}
                  options={industries}
                  placeholder="Select Industry..."
                />
              </div>
            </div>
          ) : (
            <div className="detail-grid">
              <div className="detail-item"><label>Full Name</label><p>{detail.full_name}</p></div>
              <div className="detail-item"><label>Business Name</label><p>{detail.business_name}</p></div>
              <div className="detail-item"><label>Contact Number</label><p>{detail.contact_number}</p></div>
              <div className="detail-item"><label>Email</label><p>{detail.email || '—'}</p></div>
              <div className="detail-item"><label>District</label><p>{detail.district || '—'}</p></div>
              <div className="detail-item"><label>Industry</label><p>{detail.industry_name || '—'}</p></div>
              <div className="detail-item">
                <label>Targetted Chapter</label>
                <p style={{ fontWeight: 600 }}>{detail.chapter_name || 'No Chapter Assigned'} {detail.district ? `(${detail.district})` : ''}</p>
              </div>
              <div className="detail-item">
                <label>Fit Call Date</label>
                <p>{detail.fit_call_date ? new Date(detail.fit_call_date).toLocaleDateString() : '—'}</p>
              </div>
            </div>
          )}

          {/* Founding-member profile (Tier-1 fields) */}
          {(detail.designation || detail.decision_authority || detail.years_in_operation || detail.business_legal_type || detail.business_registration_number || detail.website_url || detail.linkedin_url || detail.what_you_offer || detail.what_you_seek || detail.tshirt_size) && (
            <div style={{ marginTop: '2rem' }}>
              <h4 style={{ fontSize: '0.95rem', fontWeight: 700, marginBottom: '0.75rem' }}>Founding-member profile</h4>
              <div className="detail-grid">
                {detail.designation && (
                  <div className="detail-item"><label>Designation</label><p>{detail.designation}</p></div>
                )}
                {detail.decision_authority && (
                  <div className="detail-item"><label>Decision authority</label><p style={{ textTransform: 'capitalize' }}>{detail.decision_authority.replace(/_/g, ' ')}</p></div>
                )}
                {detail.years_in_operation && (
                  <div className="detail-item"><label>Years in operation</label><p>{detail.years_in_operation}</p></div>
                )}
                {detail.business_legal_type && (
                  <div className="detail-item"><label>Legal type</label><p style={{ textTransform: 'uppercase' }}>{detail.business_legal_type.replace(/_/g, ' ')}</p></div>
                )}
                {detail.business_registration_number && (
                  <div className="detail-item"><label>BR Number</label><p>{detail.business_registration_number}</p></div>
                )}
                {detail.website_url && (
                  <div className="detail-item"><label>Website</label><p><a href={detail.website_url} target="_blank" rel="noreferrer" style={{ color: 'var(--brand-navy-600, #1e3a8a)' }}>{detail.website_url}</a></p></div>
                )}
                {detail.linkedin_url && (
                  <div className="detail-item"><label>LinkedIn</label><p><a href={detail.linkedin_url} target="_blank" rel="noreferrer" style={{ color: 'var(--brand-navy-600, #1e3a8a)' }}>{detail.linkedin_url}</a></p></div>
                )}
                {detail.tshirt_size && (
                  <div className="detail-item"><label>T-shirt size</label><p>{detail.tshirt_size}</p></div>
                )}
              </div>
              {detail.what_you_offer && (
                <div style={{ marginTop: '1rem' }}>
                  <label style={{ fontSize: '0.75rem', fontWeight: 700, color: 'var(--text-secondary)', textTransform: 'uppercase', letterSpacing: '0.05em' }}>What they offer</label>
                  <p style={{ marginTop: '0.5rem', fontSize: '0.9375rem', color: 'var(--text-primary)', background: '#f8fafc', padding: '0.85rem 1rem', borderRadius: '12px', lineHeight: 1.6 }}>{detail.what_you_offer}</p>
                </div>
              )}
              {detail.what_you_seek && (
                <div style={{ marginTop: '0.75rem' }}>
                  <label style={{ fontSize: '0.75rem', fontWeight: 700, color: 'var(--text-secondary)', textTransform: 'uppercase', letterSpacing: '0.05em' }}>What they seek</label>
                  <p style={{ marginTop: '0.5rem', fontSize: '0.9375rem', color: 'var(--text-primary)', background: '#f8fafc', padding: '0.85rem 1rem', borderRadius: '12px', lineHeight: 1.6 }}>{detail.what_you_seek}</p>
                </div>
              )}
            </div>
          )}

          {/* Notes */}
          {detail.notes && (
            <div style={{ marginTop: '1.5rem' }}>
              <label style={{ fontSize: '0.75rem', fontWeight: 700, color: 'var(--text-secondary)', textTransform: 'uppercase', letterSpacing: '0.05em' }}>Notes</label>
              <p style={{ marginTop: '0.5rem', fontSize: '0.9375rem', color: 'var(--text-primary)', background: '#f8fafc', padding: '1rem', borderRadius: '12px', lineHeight: 1.6 }}>{detail.notes}</p>
            </div>
          )}

          {/* History Timeline */}
          {detail.history && detail.history.length > 0 && (
            <div style={{ marginTop: '2rem' }}>
              <h4 style={{ fontSize: '0.95rem', fontWeight: 700, marginBottom: '1rem' }}>Status History</h4>
              <div className="history-timeline">
                {detail.history.map((h, i) => (
                  <div key={h.id || i} className="history-item">
                    <div className="history-dot" />
                    <div className="history-content">
                      <div style={{ display: 'flex', gap: '0.5rem', alignItems: 'center', flexWrap: 'wrap' }}>
                        <StatusPill status={h.old_status} />
                        <IconChevronRight size={14} color="#94a3b8" />
                        <StatusPill status={h.new_status} />
                      </div>
                      {h.notes && <p style={{ fontSize: '0.8rem', color: 'var(--text-secondary)', marginTop: '0.35rem' }}>{h.notes}</p>}
                      <p style={{ fontSize: '0.75rem', color: '#94a3b8', marginTop: '0.25rem' }}>{new Date(h.created_at).toLocaleString()}</p>
                    </div>
                  </div>
                ))}
              </div>
            </div>
          )}

          {/* Actions Section */}
          <div className="modal-actions-panel">
            {modalStatus === 'approved' ? (
              <div className="approval-form" style={{ background: '#f0fdf4', padding: '1.5rem', borderRadius: '16px', border: '1px solid #bbf7d0', marginBottom: '1.5rem' }}>
                <h4 style={{ fontSize: '0.95rem', fontWeight: 700, color: '#166534', marginBottom: '1rem', display: 'flex', alignItems: 'center', gap: '0.5rem' }}>
                  <IconCheck size={18} /> Approve Application
                </h4>
                <p style={{ fontSize: '0.85rem', color: '#166534', marginBottom: '1.25rem' }}>
                  Select the chapter and confirming the initial payment status if previously received. The applicant receives a welcome email with login credentials and an onboarding link.
                </p>
                {!detail.email && (
                  <div style={{ marginBottom: '1.25rem' }}>
                    <label style={{ color: '#92400e', fontSize: '0.75rem', fontWeight: 700, textTransform: 'uppercase', marginBottom: '0.5rem', display: 'block' }}>
                      Email (required to send the onboarding link)
                    </label>
                    <input
                      type="email"
                      value={approvalEmail}
                      onChange={e => setApprovalEmail(e.target.value)}
                      placeholder="applicant@example.com"
                      style={{ width: '100%', padding: '0.75rem 1rem', border: '1px solid #fcd34d', borderRadius: '12px', fontSize: '0.9375rem', background: '#fffbeb', height: '52px' }}
                    />
                    <p style={{ fontSize: '0.75rem', color: '#92400e', marginTop: '0.4rem' }}>
                      This application was submitted without an email. Add one to proceed.
                    </p>
                  </div>
                )}
                <div style={{ display: 'grid', gridTemplateColumns: '1fr 1fr', gap: '1rem', marginBottom: '1.25rem' }}>
                  <div>
                    <label style={{ color: '#166534', fontSize: '0.75rem', fontWeight: 700, textTransform: 'uppercase', marginBottom: '0.5rem', display: 'block' }}>Target Chapter</label>
                    <div style={{ background: 'white', padding: '0.75rem 1rem', borderRadius: '12px', border: '1px solid #bbf7d0', fontSize: '0.9375rem', fontWeight: 600, color: '#166534', height: '52px', display: 'flex', alignItems: 'center' }}>
                      {detail.chapter_name || 'Not assigned'}
                    </div>
                  </div>
                  <div>
                    <label style={{ color: '#166534', fontSize: '0.75rem', fontWeight: 700, textTransform: 'uppercase', marginBottom: '0.5rem', display: 'block' }}>Payment status</label>
                    <CustomSelect
                      label="Payment status..."
                      value={paymentStatus}
                      options={[
                        { id: 'pending', name: 'Pending (Pay later)' },
                        { id: 'completed', name: 'Completed (Paid)' }
                      ]}
                      onChange={setPaymentStatus}
                      style={{ background: 'white' }}
                    />
                  </div>
                </div>
                <div style={{ display: 'flex', gap: '0.75rem' }}>
                  <button
                    className="login-btn"
                    style={{ flex: 1, background: '#10b981', padding: '0.75rem', height: '52px' }}
                    onClick={() => handleStatusUpdate('approved')}
                    disabled={updating || !selectedChapterId}
                  >
                    Confirm & Approve
                  </button>
                  <button
                    className="login-btn"
                    style={{ flex: 1, background: '#94a3b8', padding: '0.75rem', height: '52px' }}
                    onClick={() => { setModalStatus(null); }}
                  >
                    Cancel
                  </button>
                </div>
              </div>
            ) : modalStatus === 'fit_call_scheduled' ? (
              <div className="approval-form" style={{ background: '#f5f3ff', padding: '1.5rem', borderRadius: '16px', border: '1px solid #ddd6fe', marginBottom: '1.5rem' }}>
                <h4 style={{ fontSize: '0.95rem', fontWeight: 700, color: '#7c3aed', marginBottom: '1rem', display: 'flex', alignItems: 'center', gap: '0.5rem' }}>
                  <IconCalendarEvent size={18} /> Schedule Fit Call
                </h4>
                <p style={{ fontSize: '0.85rem', color: '#7c3aed', marginBottom: '1.25rem' }}>
                  Select the date and time for the member's introductory interview.
                </p>
                <div style={{ marginBottom: '1.25rem' }}>
                  <label style={{ color: '#7c3aed', fontSize: '0.75rem', fontWeight: 700, textTransform: 'uppercase', marginBottom: '0.5rem', display: 'block' }}>Meeting Date & Time</label>
                  <DatePicker
                    selected={fitCallDate}
                    onChange={date => setFitCallDate(date)}
                    showTimeSelect
                    timeFormat="HH:mm"
                    dateFormat="MMMM d, yyyy h:mm aa"
                    className="modern-datepicker-input"
                    style={{ background: 'white' }}
                  />
                </div>
                <div style={{ display: 'flex', gap: '0.75rem' }}>
                  <button
                    className="login-btn"
                    style={{ flex: 1, background: '#8b5cf6', padding: '0.75rem', height: '52px' }}
                    onClick={() => handleStatusUpdate('fit_call_scheduled')}
                    disabled={updating}
                  >
                    Confirm & Schedule
                  </button>
                  <button
                    className="login-btn"
                    style={{ flex: 1, background: '#94a3b8', padding: '0.75rem', height: '52px' }}
                    onClick={() => { setModalStatus(null); }}
                  >
                    Cancel
                  </button>
                </div>
              </div>
            ) : (
              <>
                <div style={{ marginBottom: '1.25rem' }}>
                  <label style={{ fontSize: '0.75rem', fontWeight: 700, color: 'var(--text-secondary)', textTransform: 'uppercase', letterSpacing: '0.05em', display: 'block', marginBottom: '0.5rem' }}>Action Notes</label>
                  <textarea
                    placeholder="Add notes about this decision..."
                    value={actionNotes}
                    onChange={e => setActionNotes(e.target.value)}
                    className="action-textarea"
                  />
                </div>
                <div className="action-buttons">
                  {availableActions.map(action => {
                    const isDecision = ['approved', 'rejected', 'waitlisted'].includes(action.status);
                    const needsFitCall = detail.status === 'pending' && isDecision;

                    return (
                      <button
                        key={action.status}
                        className={`action-btn-main ${needsFitCall ? 'btn-disabled-visual' : ''}`}
                        style={{ '--btn-color': needsFitCall ? '#cbd5e1' : action.color }}
                        disabled={updating}
                        onClick={() => handleStatusUpdate(action.status)}
                        title={needsFitCall ? "Schedule a Fit Call first" : ""}
                      >
                        <action.icon size={18} />
                        {updating ? 'Updating...' : action.label}
                      </button>
                    );
                  })}
                </div>
              </>
            )}
          </div>
        </div>
      </div>
    </div>
  );
}



const SRI_LANKA_DISTRICTS = [
  'Ampara', 'Anuradhapura', 'Badulla', 'Batticaloa', 'Colombo', 'Galle', 'Gampaha',
  'Hambantota', 'Jaffna', 'Kalutara', 'Kandy', 'Kegalle', 'Kilinochchi', 'Kurunegala',
  'Mannar', 'Matale', 'Matara', 'Moneragala', 'Mullaitivu', 'Nuwara Eliya',
  'Polonnaruwa', 'Puttalam', 'Ratnapura', 'Trincomalee', 'Vavuniya'
];

function CreateApplicationModal({ onClose, onCreated }) {
  const [formData, setFormData] = useState({
    full_name: '',
    business_name: '',
    contact_number: '',
    email: '',
    district: '',
    industry_category_id: '',
    chapter_id: ''
  });
  const [industries, setIndustries] = useState([]);
  const [chapters, setChapters] = useState([]);
  const [filteredChapters, setFilteredChapters] = useState([]);
  const [occupiedIndustries, setOccupiedIndustries] = useState([]);
  const [loading, setLoading] = useState(false);
  const [loadingInitial, setLoadingInitial] = useState(true);
  const [loadingOccupancy, setLoadingOccupancy] = useState(false);
  const [error, setError] = useState('');

  useEffect(() => {
    const init = async () => {
      try {
        const [indData, chapData] = await Promise.all([
          api.listIndustryCategories(),
          api.listChapters({ active_only: true })
        ]);
        setIndustries(indData);
        setChapters(chapData);
      } catch (err) {
        console.error('Failed to load initial data:', err);
      } finally {
        setLoadingInitial(false);
      }
    };
    init();
  }, []);

  // Filter chapters whenever district or full chapters list changes
  useEffect(() => {
    if (formData.district) {
      setFilteredChapters(chapters.filter(c => c.district === formData.district));
    } else {
      setFilteredChapters([]);
    }
  }, [formData.district, chapters]);

  useEffect(() => {
    if (formData.chapter_id) {
      setLoadingOccupancy(true);
      api.getOccupiedIndustries(formData.chapter_id)
        .then(ids => setOccupiedIndustries(ids))
        .catch(err => console.error('Failed to fetch occupancy:', err))
        .finally(() => setLoadingOccupancy(false));
    } else {
      setOccupiedIndustries([]);
    }
  }, [formData.chapter_id]);

  const handleSubmit = async (e) => {
    e.preventDefault();
    if (!formData.district) {
      setError('Please select a district');
      return;
    }
    if (!formData.chapter_id) {
      setError('Please select a target chapter');
      return;
    }
    if (!formData.industry_category_id) {
      setError('Please select an industry category');
      return;
    }
    setLoading(true);
    setError('');
    try {
      await api.createApplication(formData);
      onCreated();
    } catch (err) {
      setError(err.message || 'Failed to create application');
    } finally {
      setLoading(false);
    }
  };

  return (
    <div className="modal-overlay" onClick={(e) => e.target === e.currentTarget && onClose()}>
      <div className="modal-content" onClick={e => e.stopPropagation()} style={{ maxWidth: 550 }}>
        <div className="modal-header">
          <div>
            <h2 style={{ fontSize: '1.25rem', fontWeight: 800 }}>New Application</h2>
            <p style={{ color: 'var(--text-secondary)', fontSize: '0.85rem' }}>Manual application entry</p>
          </div>
          <button type="button" className="modal-close-btn" onClick={onClose}>
            <IconX size={20} />
          </button>
        </div>

        <form onSubmit={handleSubmit} style={{ padding: '1.5rem 1.5rem 10rem' }}>
          {error && <div className="login-error" style={{ marginBottom: '1.25rem' }}>{error}</div>}

          <div style={{ display: 'grid', gridTemplateColumns: '1fr 1fr', gap: '1rem', marginBottom: '1.25rem' }}>
            <div className="login-field" style={{ marginBottom: 0 }}>
              <label>Applicant Name *</label>
              <input
                type="text"
                className="filter-input v2"
                placeholder="Full Name"
                required
                value={formData.full_name}
                onChange={e => setFormData({ ...formData, full_name: e.target.value })}
              />
            </div>
            <div className="login-field" style={{ marginBottom: 0 }}>
              <label>Business Name *</label>
              <input
                type="text"
                className="filter-input v2"
                placeholder="Trade Name"
                required
                value={formData.business_name}
                onChange={e => setFormData({ ...formData, business_name: e.target.value })}
              />
            </div>
          </div>

          <div style={{ display: 'grid', gridTemplateColumns: '1fr 1fr', gap: '1rem', marginBottom: '1.25rem' }}>
            <div className="login-field" style={{ marginBottom: 0 }}>
              <label>Contact Number *</label>
              <input
                type="tel"
                className="filter-input v2"
                placeholder="+94..."
                required
                value={formData.contact_number}
                onChange={e => setFormData({ ...formData, contact_number: e.target.value })}
              />
            </div>
            <div className="login-field" style={{ marginBottom: 0 }}>
              <label>Email Address *</label>
              <input
                type="email"
                className="filter-input v2"
                placeholder="name@email.com"
                required
                value={formData.email}
                onChange={e => setFormData({ ...formData, email: e.target.value })}
              />
            </div>
          </div>

          <div style={{ marginBottom: '1.25rem' }}>
            <label style={{ fontSize: '0.75rem', fontWeight: 700, color: 'var(--text-secondary)', textTransform: 'uppercase', letterSpacing: '0.05em', display: 'block', marginBottom: '0.5rem' }}>District *</label>
            <CustomSelect
              label="Select District..."
              value={formData.district}
              options={SRI_LANKA_DISTRICTS.map(d => ({ id: d, name: d }))}
              onChange={val => setFormData({ ...formData, district: val, chapter_id: '', industry_category_id: '' })}
            />
          </div>

          <div style={{ display: 'grid', gridTemplateColumns: '1fr 1fr', gap: '1rem', marginBottom: '1.5rem' }}>
            <div>
              <label style={{ fontSize: '0.75rem', fontWeight: 700, color: 'var(--text-secondary)', textTransform: 'uppercase', letterSpacing: '0.05em', display: 'block', marginBottom: '0.5rem' }}>Target Chapter *</label>
              <CustomSelect
                label={!formData.district ? "Select District first" : (loadingInitial ? "Loading..." : "Select Chapter...")}
                value={formData.chapter_id}
                options={filteredChapters}
                onChange={val => setFormData({ ...formData, chapter_id: val, industry_category_id: '' })}
              />
            </div>
            <div>
              <label style={{ fontSize: '0.75rem', fontWeight: 700, color: 'var(--text-secondary)', textTransform: 'uppercase', letterSpacing: '0.05em', display: 'block', marginBottom: '0.5rem' }}>Industry *</label>
              <CustomSelect
                label={loadingInitial ? "Loading..." : (loadingOccupancy ? "Checking..." : "Select Industry...")}
                value={formData.industry_category_id}
                options={industries}
                disabledOptions={occupiedIndustries}
                onChange={val => setFormData({ ...formData, industry_category_id: val })}
              />
              {!formData.chapter_id && <p style={{ fontSize: '0.65rem', color: 'var(--text-secondary)', marginTop: '0.4rem' }}>Please select a chapter first</p>}
            </div>
          </div>

          <div style={{ display: 'flex', gap: '1rem', marginTop: '1rem' }}>
            <button
              type="submit"
              className="login-btn"
              disabled={loading}
              style={{ flex: 2 }}
            >
              {loading ? 'Creating...' : 'Create Application'}
            </button>
            <button
              type="button"
              className="login-btn"
              onClick={onClose}
              style={{ flex: 1, background: '#94a3b8' }}
            >
              Cancel
            </button>
          </div>
        </form>
      </div>
    </div>
  );
}

function ApplicationActionMenu({ app, onView }) {
  const [isOpen, setIsOpen] = useState(false);
  const menuRef = useRef(null);

  useEffect(() => {
    const handleClickOutside = (e) => {
      if (menuRef.current && !menuRef.current.contains(e.target)) setIsOpen(false);
    };
    document.addEventListener('mousedown', handleClickOutside);
    return () => document.removeEventListener('mousedown', handleClickOutside);
  }, []);

  return (
    <div className="action-menu-container" ref={menuRef}>
      <button className="view-detail-btn" title="Actions" onClick={() => setIsOpen(!isOpen)}>
        <IconSettings size={20} />
      </button>
      
      {isOpen && (
        <div className="action-dropdown" style={{ right: 0, left: 'auto' }}>
          <button className="action-item" onClick={() => { onView(); setIsOpen(false); }}>
            <IconEye size={16} /> View Details
          </button>
        </div>
      )}
    </div>
  );
}

// ── Applications Page ───────────────────────────────────────────────────────

function ApplicationsPage() {
  const [apps, setApps] = useState([]);
  const [total, setTotal] = useState(0);
  const [pages, setPages] = useState(0);
  const [loading, setLoading] = useState(true);
  const [statusFilter, setStatusFilter] = useState('');
  const [page, setPage] = useState(1);
  const [selectedAppId, setSelectedAppId] = useState(null);
  const [showCreateModal, setShowCreateModal] = useState(false);

  const fetchApps = useCallback(async () => {
    setLoading(true);
    try {
      const params = { page, limit: 15 };
      if (statusFilter) params.status = statusFilter;
      const result = await api.listApplications(params);
      setApps(result.data || []);
      setTotal(result.total || 0);
      setPages(result.pages || 0);
    } catch (err) {
      console.error('Failed to load applications:', err);
      setApps([]);
    } finally {
      setLoading(false);
    }
  }, [statusFilter, page]);

  useEffect(() => { fetchApps(); }, [fetchApps]);

  const statusFilters = [
    { value: '', label: 'All' },
    { value: 'pending', label: 'Pending' },
    { value: 'fit_call_scheduled', label: 'Fit Call' },
    { value: 'approved', label: 'Approved' },
    { value: 'rejected', label: 'Rejected' },
    { value: 'waitlisted', label: 'Waitlisted' },
  ];

  return (
    <section className="ds-page">
      <Ds.PageHeader
        title="Member Applications"
        description="Review, approve, and manage membership applications across the network."
        actions={
          <>
            <Ds.Button
              variant="secondary"
              leftIcon={<IconRefresh size={14} />}
              onClick={fetchApps}
            >
              Refresh
            </Ds.Button>
            <Ds.Button
              variant="primary"
              leftIcon={<IconPlus size={14} />}
              onClick={() => setShowCreateModal(true)}
            >
              New Application
            </Ds.Button>
          </>
        }
      />

      <div className="ds-stat-grid">
        <Ds.StatCard
          label="Total"
          value={total}
          icon={IconClipboardList}
          iconColor="var(--brand-blue)"
          iconBg="var(--brand-blue-50)"
        />
        <Ds.StatCard
          label="Pending review"
          value={apps.filter(a => a.status === 'pending').length}
          icon={IconClock}
          iconColor="var(--warning)"
          iconBg="var(--warning-bg)"
        />
        <Ds.StatCard
          label="Approved"
          value={apps.filter(a => a.status === 'approved').length}
          icon={IconCheck}
          iconColor="var(--success)"
          iconBg="var(--success-bg)"
        />
        <Ds.StatCard
          label="Rejected"
          value={apps.filter(a => a.status === 'rejected').length}
          icon={IconX}
          iconColor="var(--danger)"
          iconBg="var(--danger-bg)"
        />
      </div>

      <Ds.Section
        title="Application Queue"
        subtitle="Click any row to view details and take action."
        flush
        actions={
          <Ds.ChipGroup
            value={statusFilter}
            onChange={val => { setStatusFilter(val); setPage(1); }}
            options={statusFilters.map(f => ({ value: f.value, label: f.label }))}
          />
        }
      >
        <Ds.Table>
          <thead>
            <tr>
              <th>Applicant</th>
              <th>Business</th>
              <th>Contact</th>
              <th>Target chapter</th>
              <th>Status</th>
              <th>Applied</th>
              <th className="ds-table__actions" />
            </tr>
          </thead>
          <tbody>
            {loading ? (
              <Ds.Table.LoadingRow colSpan={7} label="Loading applications…" />
            ) : apps.length === 0 ? (
              <Ds.Table.EmptyRow
                colSpan={7}
                icon={IconClipboardList}
                title="No applications found"
                description="Try changing the status filter above."
              />
            ) : apps.map((app, idx) => (
              <tr key={app.id || idx} className="is-clickable" onClick={() => setSelectedAppId(app.id)}>
                <td>
                  <div style={{ display: 'flex', alignItems: 'center', gap: 'var(--space-3)' }}>
                    <Ds.Avatar size="sm" name={app.full_name || '?'} />
                    <span className="ds-table__primary">{app.full_name}</span>
                  </div>
                </td>
                <td className="ds-table__primary">{app.business_name}</td>
                <td className="ds-table__muted">{app.contact_number}</td>
                <td className="ds-table__muted">{app.chapter_name || '—'}</td>
                <td><StatusPill status={app.status} /></td>
                <td className="ds-table__muted">
                  {new Date(app.created_at).toLocaleDateString()}
                </td>
                <td className="ds-table__actions" onClick={e => e.stopPropagation()}>
                  <ApplicationActionMenu app={app} onView={() => setSelectedAppId(app.id)} />
                </td>
              </tr>
            ))}
          </tbody>
        </Ds.Table>

        <Ds.Pagination
          page={page}
          totalPages={pages}
          total={total}
          pageLabel="applications"
          onPageChange={p => setPage(Math.max(1, p))}
        />
      </Ds.Section>

      {selectedAppId && (
        <ApplicationDetailModal
          appId={selectedAppId}
          onClose={() => setSelectedAppId(null)}
          onStatusUpdated={fetchApps}
        />
      )}

      {showCreateModal && (
        <CreateApplicationModal
          onClose={() => setShowCreateModal(false)}
          onCreated={() => {
            setShowCreateModal(false);
            fetchApps();
          }}
        />
      )}
    </section>
  );
}

// ── Custom Select Component ──────────────────────────────────────────────────

function CustomSelect({ label, value, options, onChange, style, disabledOptions = [] }) {
  const [isOpen, setIsOpen] = useState(false);
  const containerRef = useRef(null);

  useEffect(() => {
    const handleClickOutside = (event) => {
      if (containerRef.current && !containerRef.current.contains(event.target)) {
        setIsOpen(false);
      }
    };
    document.addEventListener('mousedown', handleClickOutside);
    return () => document.removeEventListener('mousedown', handleClickOutside);
  }, []);

  const selectedOption = (options || []).find(opt => String(opt.id) === String(value)) || { name: label };

  return (
    <div className="custom-select-container" ref={containerRef} style={style}>
      <button
        type="button"
        className={`custom-select-trigger ${isOpen ? 'active' : ''}`}
        onClick={() => setIsOpen(!isOpen)}
      >
        <span>{selectedOption.name || selectedOption.label || label}</span>
        <IconChevronDown size={18} className={`select-arrow ${isOpen ? 'rotated' : ''}`} />
      </button>

      {isOpen && (
        <div className="custom-select-menu">
          <div
            className="custom-select-option"
            onClick={() => { onChange(''); setIsOpen(false); }}
            style={{ fontWeight: 700, borderBottom: '1px solid var(--border)' }}
          >
            {label}
          </div>
          {options.map((opt) => {
            const isDisabled = disabledOptions.includes(String(opt.id));
            return (
              <div
                key={opt.id}
                className={`custom-select-option ${String(value) === String(opt.id) ? 'selected' : ''} ${isDisabled ? 'disabled' : ''}`}
                onClick={() => {
                  if (!isDisabled) {
                    onChange(opt.id);
                    setIsOpen(false);
                  }
                }}
                style={{
                  display: 'flex',
                  alignItems: 'center',
                  gap: '0.5rem',
                  ...(isDisabled ? { color: '#94a3b8', cursor: 'not-allowed', background: '#f8fafc', pointerEvents: 'none' } : {}),
                }}
              >
                <span>{opt.name || opt.label}</span>
                {isDisabled && <span style={{ marginLeft: 'auto', fontSize: '0.65rem', fontWeight: 800, color: 'var(--text-secondary)', background: '#e2e8f0', padding: '2px 6px', borderRadius: '4px' }}>OCCUPIED</span>}
              </div>
            );
          })}
        </div>
      )}
    </div>
  );
}

// ── User Edit Modal ──────────────────────────────────────────────────────────

function UserEditModal({ user, onClose, onUpdate, chapters = [] }) {
  const [role, setRole] = useState(user.role);
  const [isActive, setIsActive] = useState(user.is_active);
  const [membershipType, setMembershipType] = useState(user.membership_type || 'standard');
  const [loading, setLoading] = useState(false);
  const [error, setError] = useState('');

  const handleSubmit = async (e) => {
    e.preventDefault();
    setLoading(true);
    try {
      await api.updateUser(user.id, { role, is_active: isActive, membership_type: membershipType });
      onUpdate();
      onClose();
    } catch (err) {
      setError(err.message);
    } finally {
      setLoading(false);
    }
  };

  const handleRemoveFromChapter = async () => {
    if (!window.confirm(`Are you sure you want to remove ${user.full_name} from ${user.chapter_name}? This will also downgrade them to PROSPECT.`)) return;
    setLoading(true);
    try {
      await api.removeUserFromChapter(user.id);
      onUpdate();
      onClose();
    } catch (err) {
      setError(err.message);
    } finally {
      setLoading(false);
    }
  };

  const handleDelete = async () => {
    if (!window.confirm(`Permanently delete ${user.full_name}? This removes their account, memberships, referrals, listings, and related data. This cannot be undone.`)) return;
    setLoading(true);
    try {
      await api.deleteUser(user.id);
      onUpdate();
      onClose();
    } catch (err) {
      setError(err.message);
    } finally {
      setLoading(false);
    }
  };

  return (
    <div className="modal-overlay" onClick={(e) => e.target === e.currentTarget && onClose()}>
      <div className="modal-content" onClick={e => e.stopPropagation()} style={{ maxWidth: 450 }}>
        <div className="modal-header">
          <h2 style={{ fontSize: '1.25rem', fontWeight: 800 }}>Manage Member</h2>
          <button type="button" className="modal-close-btn" onClick={onClose}>
            <IconX size={20} />
          </button>
        </div>
        <form onSubmit={handleSubmit} style={{ padding: '1.5rem' }}>
          {error && <div className="login-error" style={{ marginBottom: '1rem' }}>{error}</div>}

          <div style={{ marginBottom: '1.5rem', textAlign: 'center' }}>
            <div className="avatar-sm" style={{ width: 64, height: 64, fontSize: '1.5rem', margin: '0 auto 0.75rem', background: '#f1f5f9', color: 'var(--primary)' }}>
              {user.full_name ? user.full_name[0] : '?'}
            </div>
            <h3 style={{ fontWeight: 800 }}>{user.full_name}</h3>
            <p style={{ color: 'var(--text-secondary)', fontSize: '0.875rem' }}>{user.phone_number}</p>
            {user.chapter_name && (
              <div style={{ marginTop: '0.5rem' }}>
                <span className="id-badge" style={{ background: '#e0f2fe', color: '#0369a1' }}>{user.chapter_name}</span>
              </div>
            )}
          </div>

          <div style={{ marginBottom: '1rem' }}>
            <label style={{ fontSize: '0.75rem', fontWeight: 700, color: 'var(--text-secondary)', textTransform: 'uppercase', letterSpacing: '0.05em', display: 'block', marginBottom: '0.5rem' }}>User Role</label>
            <CustomSelect
              label="Select role..."
              value={role}
              options={[
                { id: 'PROSPECT', name: 'Prospect (Pending Payment)' },
                { id: 'MEMBER', name: 'Member (Verified)' },
                { id: 'CHAPTER_ADMIN', name: 'Chapter Admin' },
                { id: 'SUPER_ADMIN', name: 'Super Admin' }
              ]}
              onChange={setRole}
            />
          </div>

          <div style={{ marginBottom: '1rem' }}>
            <label style={{ fontSize: '0.75rem', fontWeight: 700, color: 'var(--text-secondary)', textTransform: 'uppercase', letterSpacing: '0.05em', display: 'block', marginBottom: '0.5rem' }}>Membership Tier</label>
            <CustomSelect
              label="Select category..."
              value={membershipType}
              options={[
                { id: 'founders_club', name: 'Founders Club Member' },
                { id: 'standard', name: 'Standard Member' },
                { id: 'associate', name: 'Associate Member' },
                { id: 'corporate', name: 'Corporate Member' },
                { id: 'charter', name: 'Charter Member' }
              ]}
              onChange={setMembershipType}
            />
          </div>

          <div style={{ display: 'flex', alignItems: 'center', gap: '0.75rem', marginBottom: '1.5rem', padding: '1rem', background: '#f8fafc', borderRadius: '12px' }}>
            <div style={{ flex: 1 }}>
              <div style={{ fontWeight: 700, fontSize: '0.9rem' }}>Account & Membership Active</div>
              <div style={{ fontSize: '0.8rem', color: 'var(--text-secondary)' }}>Toggle access to network features</div>
            </div>
            <input
              type="checkbox"
              checked={isActive}
              onChange={e => setIsActive(e.target.checked)}
              style={{ width: 20, height: 20, cursor: 'pointer' }}
            />
          </div>

          <div style={{ display: 'flex', gap: '0.75rem' }}>
            <button type="submit" className="login-btn" disabled={loading} style={{ flex: 2 }}>
              {loading ? 'Saving...' : 'Update Status'}
            </button>
            {user.chapter_name && (
              <button
                type="button"
                className="login-btn"
                onClick={handleRemoveFromChapter}
                disabled={loading}
                style={{ flex: 1, background: '#fee2e2', color: '#dc2626', border: '1px solid #fecaca' }}
                title="Remove from chapter"
              >
                <IconTrash size={18} />
              </button>
            )}
          </div>

          <div style={{ marginTop: '1.25rem', paddingTop: '1.25rem', borderTop: '1px solid #e2e8f0' }}>
            <button
              type="button"
              className="login-btn"
              onClick={handleDelete}
              disabled={loading}
              style={{ width: '100%', background: '#dc2626', color: '#fff', border: '1px solid #b91c1c', display: 'flex', alignItems: 'center', justifyContent: 'center', gap: '0.5rem' }}
              title="Permanently delete this member"
            >
              <IconTrash size={16} />
              Permanently delete member
            </button>
            <p style={{ marginTop: '0.5rem', fontSize: '0.75rem', color: 'var(--text-secondary)', textAlign: 'center' }}>
              Removes the account and all related data (memberships, referrals, listings). Cannot be undone.
            </p>
          </div>
        </form>
      </div>
    </div>
  );
}



function UserActionMenu({ user, onEdit }) {
  const [isOpen, setIsOpen] = useState(false);
  const menuRef = useRef(null);

  useEffect(() => {
    const handleClickOutside = (e) => {
      if (menuRef.current && !menuRef.current.contains(e.target)) setIsOpen(false);
    };
    document.addEventListener('mousedown', handleClickOutside);
    return () => document.removeEventListener('mousedown', handleClickOutside);
  }, []);

  return (
    <div className="action-menu-container" ref={menuRef}>
      <button className="view-detail-btn" title="Actions" onClick={() => setIsOpen(!isOpen)}>
        <IconSettings size={20} />
      </button>
      
      {isOpen && (
        <div className="action-dropdown" style={{ right: 0, left: 'auto' }}>
          <button className="action-item" onClick={() => { onEdit(); setIsOpen(false); }}>
            <IconPencil size={16} /> Edit Profile
          </button>
        </div>
      )}
    </div>
  );
}

// ── Members Directory Page ──────────────────────────────────────────────────

function MembersPage() {
  const [users, setUsers] = useState([]);
  const [loading, setLoading] = useState(true);
  const [total, setTotal] = useState(0);
  const [pages, setPages] = useState(0);
  const [page, setPage] = useState(1);
  const [search, setSearch] = useState('');
  const [districtFilter, setDistrictFilter] = useState('');
  const [chapterFilter, setChapterFilter] = useState('');
  const [industryFilter, setIndustryFilter] = useState('');
  const [roleFilter, setRoleFilter] = useState('');
  const [selectedUser, setSelectedUser] = useState(null);

  // Member detail page is navigated to via ?member=<uuid>. We track the id
  // here so clicks update the URL (bookmarkable) and Back works as expected.
  const readMemberFromUrl = () => new URLSearchParams(window.location.search).get('member');
  const [detailMemberId, setDetailMemberId] = useState(readMemberFromUrl);

  useEffect(() => {
    const onPop = () => setDetailMemberId(readMemberFromUrl());
    window.addEventListener('popstate', onPop);
    return () => window.removeEventListener('popstate', onPop);
  }, []);

  const openMember = (id) => {
    const url = new URL(window.location.href);
    url.searchParams.set('member', id);
    window.history.pushState({}, '', url);
    setDetailMemberId(id);
  };
  const closeMember = () => {
    const url = new URL(window.location.href);
    url.searchParams.delete('member');
    window.history.pushState({}, '', url);
    setDetailMemberId(null);
  };

  const [chapters, setChapters] = useState([]);
  const [industries, setIndustries] = useState([]);

  const filteredChapters = useMemo(() => {
    if (!districtFilter) return chapters;
    return chapters.filter(c => c.district === districtFilter);
  }, [chapters, districtFilter]);

  const fetchMembers = useCallback(async () => {
    setLoading(true);
    try {
      const params = { page, limit: 15 };
      if (search) params.search = search;
      if (chapterFilter) params.chapter_id = chapterFilter;
      if (industryFilter) params.industry_id = industryFilter;
      if (roleFilter) params.role = roleFilter;
      if (districtFilter) params.district = districtFilter;

      const result = await api.listUsers(params);
      setUsers(result.users || []);
      setTotal(result.total || 0);
      setPages(Math.ceil(result.total / (result.page_size || 15)) || 1);
    } catch (err) {
      console.error('Failed to load members:', err);
    } finally {
      setLoading(false);
    }
  }, [page, search, chapterFilter, industryFilter, roleFilter, districtFilter]);

  useEffect(() => {
    fetchMembers();
  }, [fetchMembers]);

  useEffect(() => {
    Promise.all([
      api.listChapters().catch(() => []),
      api.listIndustries().catch(() => [])
    ]).then(([cData, iData]) => {
      setChapters(Array.isArray(cData) ? cData : []);
      setIndustries(Array.isArray(iData) ? iData : []);
    });
  }, []);

  const roleOptions = [
    { id: 'MEMBER', name: 'Members' },
    { id: 'PROSPECT', name: 'Prospects' },
    { id: 'CHAPTER_ADMIN', name: 'Chapter Admins' },
    { id: 'PARTNER_ADMIN', name: 'Partner Admins' },
  ];

  if (detailMemberId) {
    return <MemberDetailPage memberId={detailMemberId} onBack={closeMember} />;
  }

  return (
    <section className="ds-page">
      <Ds.PageHeader
        title="Member Directory"
        description="Browse, filter, and search every member and prospect across the network."
        actions={
          <Ds.Button
            variant="secondary"
            leftIcon={<IconRefresh size={14} />}
            onClick={() => { setPage(1); fetchMembers(); }}
          >
            Refresh
          </Ds.Button>
        }
      />

      <Ds.Section
        title="Network Registry"
        subtitle={total > 0 ? `${total.toLocaleString()} people in the directory` : undefined}
        flush
      >
        <div style={{ display: 'flex', gap: 'var(--space-3)', flexWrap: 'wrap', padding: 'var(--space-5) var(--space-6)', borderBottom: '1px solid var(--border-subtle)' }}>
          <Ds.Input
            placeholder="Search by name, phone or chapter…"
            value={search}
            onChange={e => { setSearch(e.target.value); setPage(1); }}
            leftIcon={<IconSearch size={14} />}
            wrapClassName=""
            style={{ flex: 1, minWidth: 240 }}
          />
          <Ds.Select
            placeholder="All districts"
            value={districtFilter}
            options={SRI_LANKA_DISTRICTS.map(d => ({ id: d, name: d }))}
            allowClear
            onChange={val => {
              setDistrictFilter(val);
              setPage(1);
              if (val && chapterFilter) {
                const selectedChap = chapters.find(c => c.id === chapterFilter);
                if (selectedChap && selectedChap.district !== val) {
                  setChapterFilter('');
                }
              }
            }}
            style={{ width: 180 }}
          />
          <Ds.Select
            placeholder="All chapters"
            value={chapterFilter}
            options={filteredChapters}
            allowClear
            onChange={val => { setChapterFilter(val); setPage(1); }}
            style={{ width: 200 }}
          />
          <Ds.Select
            placeholder="All industries"
            value={industryFilter}
            options={industries}
            allowClear
            onChange={val => { setIndustryFilter(val); setPage(1); }}
            style={{ width: 220 }}
          />
          <Ds.Select
            placeholder="All roles"
            value={roleFilter}
            options={roleOptions}
            allowClear
            onChange={val => { setRoleFilter(val); setPage(1); }}
            style={{ width: 180 }}
          />
        </div>

        <Ds.Table>
          <thead>
            <tr>
              <th>Member</th>
              <th>Chapter</th>
              <th>Industry</th>
              <th>Role</th>
              <th>Status</th>
              <th>Joined</th>
              <th className="ds-table__actions" />
            </tr>
          </thead>
          <tbody>
            {loading ? (
              <Ds.Table.LoadingRow colSpan={7} label="Loading directory…" />
            ) : users.length === 0 ? (
              <Ds.Table.EmptyRow
                colSpan={7}
                icon={IconUsers}
                title="No members found"
                description="Try clearing filters or adjusting your search."
              />
            ) : users.map(user => (
              <tr key={user.id} className="is-clickable" onClick={() => openMember(user.id)}>
                <td>
                  <div style={{ display: 'flex', alignItems: 'center', gap: 'var(--space-3)' }}>
                    <Ds.Avatar size="sm" name={user.full_name || '?'} src={user.profile_photo ? `${STATIC_BASE_URL}${user.profile_photo}` : undefined} />
                    <div style={{ minWidth: 0 }}>
                      <div className="ds-table__primary">{user.full_name || 'Unnamed User'}</div>
                      <div style={{ fontSize: 'var(--text-xs)', color: 'var(--fg-muted)', fontWeight: 'var(--weight-medium)' }}>
                        {user.phone_number}
                      </div>
                      <div style={{ fontSize: 'var(--text-xs)', color: 'var(--fg-muted)', fontWeight: 'var(--weight-medium)' }}>
                        {user.email || '—'}
                      </div>
                    </div>
                  </div>
                </td>
                <td>
                  {user.chapter_name
                    ? <Ds.Badge variant="brand">{user.chapter_name}</Ds.Badge>
                    : <span style={{ color: 'var(--fg-muted)', fontSize: 'var(--text-sm)' }}>No chapter</span>}
                </td>
                <td className="ds-table__muted">{user.industry_name || '—'}</td>
                <td>
                  <div style={{ display: 'flex', alignItems: 'center', gap: 6 }}>
                    <span style={{
                      fontSize: 'var(--text-sm)',
                      fontWeight: 'var(--weight-semibold)',
                      color: user.role === 'PROSPECT' ? 'var(--brand-amber-600)' : 'var(--fg-secondary)',
                    }}>
                      {user.role}
                    </span>
                    {user.membership_type && user.membership_type !== 'standard' && (
                      <Ds.Badge variant="accent">
                        {user.membership_type.replace(/_/g, ' ').toUpperCase()}
                      </Ds.Badge>
                    )}
                  </div>
                </td>
                <td>
                  <Ds.Badge
                    dot
                    variant={
                      user.is_active ? 'success' : user.role === 'PROSPECT' ? 'warning' : 'danger'
                    }
                  >
                    {user.is_active ? 'Active' : user.role === 'PROSPECT' ? 'Awaiting payment' : 'Inactive'}
                  </Ds.Badge>
                </td>
                <td className="ds-table__muted">
                  {user.created_at ? new Date(user.created_at).toLocaleDateString() : '—'}
                </td>
                <td className="ds-table__actions" onClick={e => e.stopPropagation()}>
                  <UserActionMenu user={user} onEdit={() => setSelectedUser(user)} />
                </td>
              </tr>
            ))}
          </tbody>
        </Ds.Table>

        <Ds.Pagination
          page={page}
          totalPages={pages}
          total={total}
          pageLabel="members"
          onPageChange={setPage}
        />
      </Ds.Section>

      {selectedUser && (
        <UserEditModal
          user={selectedUser}
          chapters={chapters}
          onClose={() => setSelectedUser(null)}
          onUpdate={fetchMembers}
        />
      )}
    </section>
  );
}


// ── Staff Edit Modal ─────────────────────────────────────────────────────────

function StaffEditModal({ user, currentUserId, onClose, onUpdate }) {
  const [role, setRole] = useState(user.role);
  const [isActive, setIsActive] = useState(user.is_active);
  const [loading, setLoading] = useState(false);
  const [error, setError] = useState('');
  const isSelf = currentUserId === user.id;

  const handleSubmit = async (e) => {
    e.preventDefault();
    setLoading(true);
    try {
      await api.updateUser(user.id, { role, is_active: isActive });
      onUpdate();
      onClose();
    } catch (err) {
      setError(err.message);
    } finally {
      setLoading(false);
    }
  };

  const handleDelete = async () => {
    if (!window.confirm(`Delete admin user ${user.full_name}? This cannot be undone.`)) return;
    setLoading(true);
    try {
      await api.deleteStaff(user.id);
      onUpdate();
      onClose();
    } catch (err) {
      setError(err.message);
    } finally {
      setLoading(false);
    }
  };

  return (
    <div className="modal-overlay" onClick={(e) => e.target === e.currentTarget && onClose()}>
      <div className="modal-content" onClick={e => e.stopPropagation()} style={{ maxWidth: 420 }}>
        <div className="modal-header">
          <h2 style={{ fontSize: '1.25rem', fontWeight: 800 }}>Manage Admin User</h2>
          <button type="button" className="modal-close-btn" onClick={onClose}>
            <IconX size={20} />
          </button>
        </div>
        <form onSubmit={handleSubmit} style={{ padding: '1.5rem' }}>
          {error && <div className="login-error" style={{ marginBottom: '1rem' }}>{error}</div>}

          <div style={{ marginBottom: '1.5rem', textAlign: 'center' }}>
            <div className="avatar-sm" style={{ width: 64, height: 64, fontSize: '1.5rem', margin: '0 auto 0.75rem', background: '#f1f5f9', color: 'var(--primary)' }}>
              {user.full_name ? user.full_name[0] : '?'}
            </div>
            <h3 style={{ fontWeight: 800 }}>{user.full_name}</h3>
            <p style={{ color: 'var(--text-secondary)', fontSize: '0.875rem' }}>{user.email || user.phone_number}</p>
          </div>

          <div style={{ marginBottom: '1rem' }}>
            <label style={{ fontSize: '0.75rem', fontWeight: 700, color: 'var(--text-secondary)', textTransform: 'uppercase', letterSpacing: '0.05em', display: 'block', marginBottom: '0.5rem' }}>Admin Role</label>
            <CustomSelect
              label="Select role..."
              value={role}
              options={[
                { id: 'SUPER_ADMIN', name: 'Super Admin' },
                { id: 'ADMIN', name: 'Admin' },
                { id: 'CHAPTER_ADMIN', name: 'Chapter Admin' },
                { id: 'PARTNER_ADMIN', name: 'Partner Admin' },
              ]}
              onChange={setRole}
            />
          </div>

          <div style={{ display: 'flex', alignItems: 'center', gap: '0.75rem', marginBottom: '1.5rem', padding: '1rem', background: '#f8fafc', borderRadius: '12px' }}>
            <div style={{ flex: 1 }}>
              <div style={{ fontWeight: 700, fontSize: '0.9rem' }}>Account Active</div>
              <div style={{ fontSize: '0.8rem', color: 'var(--text-secondary)' }}>Toggle login access to the admin panel</div>
            </div>
            <input
              type="checkbox"
              checked={isActive}
              onChange={e => setIsActive(e.target.checked)}
              style={{ width: 20, height: 20, cursor: 'pointer' }}
            />
          </div>

          <div style={{ display: 'flex', gap: '0.75rem' }}>
            <button type="submit" className="login-btn" disabled={loading} style={{ flex: 2 }}>
              {loading ? 'Saving...' : 'Save Changes'}
            </button>
            {!isSelf && (
              <button
                type="button"
                className="login-btn"
                onClick={handleDelete}
                disabled={loading}
                style={{ flex: 1, background: '#fee2e2', color: '#dc2626', border: '1px solid #fecaca' }}
                title="Delete user"
              >
                <IconTrash size={18} />
              </button>
            )}
          </div>
        </form>
      </div>
    </div>
  );
}


// ── Staff Create Modal ──────────────────────────────────────────────────────

function StaffCreateModal({ onClose, onCreate }) {
  const [fullName, setFullName] = useState('');
  const [phone, setPhone] = useState('');
  const [email, setEmail] = useState('');
  const [role, setRole] = useState('ADMIN');
  const [password, setPassword] = useState('');
  const [loading, setLoading] = useState(false);
  const [error, setError] = useState('');

  const handleSubmit = async (e) => {
    e.preventDefault();
    setLoading(true);
    setError('');
    try {
      await api.createStaff({
        full_name: fullName,
        phone_number: phone,
        email: email || null,
        role,
        password,
      });
      onCreate();
      onClose();
    } catch (err) {
      setError(err.message);
    } finally {
      setLoading(false);
    }
  };

  return (
    <div className="modal-overlay" onClick={(e) => e.target === e.currentTarget && onClose()}>
      <div className="modal-content" onClick={e => e.stopPropagation()} style={{ maxWidth: 420 }}>
        <div className="modal-header">
          <h2 style={{ fontSize: '1.25rem', fontWeight: 800 }}>Add Admin User</h2>
          <button type="button" className="modal-close-btn" onClick={onClose}>
            <IconX size={20} />
          </button>
        </div>
        <form onSubmit={handleSubmit} style={{ padding: '1.5rem' }}>
          {error && <div className="login-error" style={{ marginBottom: '1rem' }}>{error}</div>}

          <div style={{ marginBottom: '1rem' }}>
            <label style={{ fontSize: '0.75rem', fontWeight: 700, color: 'var(--text-secondary)', textTransform: 'uppercase', letterSpacing: '0.05em', display: 'block', marginBottom: '0.5rem' }}>Full Name</label>
            <Ds.Input value={fullName} onChange={e => setFullName(e.target.value)} required />
          </div>

          <div style={{ marginBottom: '1rem' }}>
            <label style={{ fontSize: '0.75rem', fontWeight: 700, color: 'var(--text-secondary)', textTransform: 'uppercase', letterSpacing: '0.05em', display: 'block', marginBottom: '0.5rem' }}>Phone Number</label>
            <Ds.Input value={phone} onChange={e => setPhone(e.target.value)} placeholder="+947XXXXXXXX" required />
          </div>

          <div style={{ marginBottom: '1rem' }}>
            <label style={{ fontSize: '0.75rem', fontWeight: 700, color: 'var(--text-secondary)', textTransform: 'uppercase', letterSpacing: '0.05em', display: 'block', marginBottom: '0.5rem' }}>Email</label>
            <Ds.Input type="email" value={email} onChange={e => setEmail(e.target.value)} />
          </div>

          <div style={{ marginBottom: '1rem' }}>
            <label style={{ fontSize: '0.75rem', fontWeight: 700, color: 'var(--text-secondary)', textTransform: 'uppercase', letterSpacing: '0.05em', display: 'block', marginBottom: '0.5rem' }}>Role</label>
            <CustomSelect
              label="Select role..."
              value={role}
              options={[
                { id: 'SUPER_ADMIN', name: 'Super Admin' },
                { id: 'ADMIN', name: 'Admin' },
                { id: 'CHAPTER_ADMIN', name: 'Chapter Admin' },
                { id: 'PARTNER_ADMIN', name: 'Partner Admin' },
              ]}
              onChange={setRole}
            />
          </div>

          <div style={{ marginBottom: '1.5rem' }}>
            <label style={{ fontSize: '0.75rem', fontWeight: 700, color: 'var(--text-secondary)', textTransform: 'uppercase', letterSpacing: '0.05em', display: 'block', marginBottom: '0.5rem' }}>Temporary Password</label>
            <Ds.Input type="password" value={password} onChange={e => setPassword(e.target.value)} minLength={8} required />
            <div style={{ fontSize: '0.75rem', color: 'var(--text-secondary)', marginTop: '0.25rem' }}>
              The user will be required to change this on first login.
            </div>
          </div>

          <button type="submit" className="login-btn" disabled={loading} style={{ width: '100%' }}>
            {loading ? 'Creating...' : 'Create User'}
          </button>
        </form>
      </div>
    </div>
  );
}


// ── User Management Page (admin-panel users only) ───────────────────────────

function UserManagementPage({ adminUser }) {
  const [users, setUsers] = useState([]);
  const [loading, setLoading] = useState(true);
  const [total, setTotal] = useState(0);
  const [search, setSearch] = useState('');
  const [roleFilter, setRoleFilter] = useState('');
  const [selectedUser, setSelectedUser] = useState(null);
  const [showCreate, setShowCreate] = useState(false);

  const fetchStaff = useCallback(async () => {
    setLoading(true);
    try {
      const params = { page_size: 100 };
      if (search) params.search = search;
      if (roleFilter) params.role = roleFilter;
      const result = await api.listStaff(params);
      setUsers(result.users || []);
      setTotal(result.total || 0);
    } catch (err) {
      console.error('Failed to load admin users:', err);
    } finally {
      setLoading(false);
    }
  }, [search, roleFilter]);

  useEffect(() => { fetchStaff(); }, [fetchStaff]);

  const roleOptions = [
    { id: 'SUPER_ADMIN', name: 'Super Admin' },
    { id: 'ADMIN', name: 'Admin' },
    { id: 'CHAPTER_ADMIN', name: 'Chapter Admin' },
    { id: 'PARTNER_ADMIN', name: 'Partner Admin' },
  ];

  return (
    <section className="ds-page">
      <Ds.PageHeader
        title="User Management"
        description="Manage admin-panel access: roles, status, and login privileges for staff users."
        actions={
          <>
            <Ds.Button
              variant="secondary"
              leftIcon={<IconRefresh size={14} />}
              onClick={fetchStaff}
            >
              Refresh
            </Ds.Button>
            <Ds.Button
              leftIcon={<IconPlus size={14} />}
              onClick={() => setShowCreate(true)}
            >
              Add User
            </Ds.Button>
          </>
        }
      />

      <Ds.Section
        title="Admin Users"
        subtitle={total > 0 ? `${total.toLocaleString()} staff accounts` : undefined}
        flush
      >
        <div style={{ display: 'flex', gap: 'var(--space-3)', flexWrap: 'wrap', padding: 'var(--space-5) var(--space-6)', borderBottom: '1px solid var(--border-subtle)' }}>
          <Ds.Input
            placeholder="Search by name, email or phone…"
            value={search}
            onChange={e => setSearch(e.target.value)}
            leftIcon={<IconSearch size={14} />}
            wrapClassName=""
            style={{ flex: 1, minWidth: 240 }}
          />
          <Ds.Select
            placeholder="All roles"
            value={roleFilter}
            options={roleOptions}
            allowClear
            onChange={setRoleFilter}
            style={{ width: 200 }}
          />
        </div>

        <Ds.Table>
          <thead>
            <tr>
              <th>User</th>
              <th>Contact</th>
              <th>Role</th>
              <th>Status</th>
              <th>Created</th>
              <th className="ds-table__actions" />
            </tr>
          </thead>
          <tbody>
            {loading ? (
              <Ds.Table.LoadingRow colSpan={6} label="Loading admin users…" />
            ) : users.length === 0 ? (
              <Ds.Table.EmptyRow
                colSpan={6}
                icon={IconUsers}
                title="No admin users found"
                description="No staff accounts match the current filters."
              />
            ) : users.map(user => (
              <tr key={user.id} className="is-clickable" onClick={() => setSelectedUser(user)}>
                <td>
                  <div style={{ display: 'flex', alignItems: 'center', gap: 'var(--space-3)' }}>
                    <Ds.Avatar size="sm" name={user.full_name || '?'} />
                    <div className="ds-table__primary">{user.full_name || 'Unnamed'}</div>
                  </div>
                </td>
                <td className="ds-table__muted">
                  <div>{user.email || '—'}</div>
                  <div style={{ fontSize: 'var(--text-xs)' }}>{user.phone_number}</div>
                </td>
                <td>
                  <Ds.Badge variant={
                    user.role === 'SUPER_ADMIN' ? 'danger' :
                    user.role === 'ADMIN' ? 'brand' :
                    user.role === 'PARTNER_ADMIN' ? 'warning' :
                    user.role === 'CHAPTER_ADMIN' ? 'success' : 'neutral'
                  }>{user.role}</Ds.Badge>
                </td>
                <td>
                  <Ds.Badge dot variant={user.is_active ? 'success' : 'danger'}>
                    {user.is_active ? 'Active' : 'Inactive'}
                  </Ds.Badge>
                </td>
                <td className="ds-table__muted">
                  {user.created_at ? new Date(user.created_at).toLocaleDateString() : '—'}
                </td>
                <td className="ds-table__actions" onClick={e => e.stopPropagation()}>
                  <UserActionMenu user={user} onEdit={() => setSelectedUser(user)} />
                </td>
              </tr>
            ))}
          </tbody>
        </Ds.Table>
      </Ds.Section>

      {selectedUser && (
        <StaffEditModal
          user={selectedUser}
          currentUserId={adminUser?.id}
          onClose={() => setSelectedUser(null)}
          onUpdate={fetchStaff}
        />
      )}

      {showCreate && (
        <StaffCreateModal
          onClose={() => setShowCreate(false)}
          onCreate={fetchStaff}
        />
      )}
    </section>
  );
}


function PaymentActionMenu({ payment, onEdit }) {
  const [isOpen, setIsOpen] = useState(false);
  const menuRef = useRef(null);

  useEffect(() => {
    const handleClickOutside = (e) => {
      if (menuRef.current && !menuRef.current.contains(e.target)) setIsOpen(false);
    };
    document.addEventListener('mousedown', handleClickOutside);
    return () => document.removeEventListener('mousedown', handleClickOutside);
  }, []);

  return (
    <div className="action-menu-container" ref={menuRef}>
      <button className="view-detail-btn" title="Actions" onClick={() => setIsOpen(!isOpen)}>
        <IconSettings size={20} />
      </button>
      
      {isOpen && (
        <div className="action-dropdown" style={{ right: 0, left: 'auto' }}>
          <button className="action-item" onClick={() => { onEdit(); setIsOpen(false); }}>
            <IconPencil size={16} /> Update Payment
          </button>
        </div>
      )}
    </div>
  );
}

// ── Payments Page ─────────────────────────────────────────────────────────────

function RecordPaymentModal({ onClose, onRecord, users = [] }) {
  const [userId, setUserId] = useState('');
  const [amount, setAmount] = useState('0');
  const [paymentType, setPaymentType] = useState('');
  const [reason, setReason] = useState('');
  const [notes, setNotes] = useState('');
  const [loading, setLoading] = useState(false);
  const [error, setError] = useState('');
  const [fees, setFees] = useState([]);

  // Fetch current master fees to enable auto-calculation
  useEffect(() => {
    api.listFees().then(data => setFees(data || [])).catch(console.error);
  }, []);

  // Auto-calculate amount when user or type changes
  useEffect(() => {
    if (!userId || !paymentType || fees.length === 0) return;
    
    const selectedUser = users.find(u => u.id === userId);
    if (!selectedUser) return;

    // Default to 'standard' if not specified
    const mType = selectedUser.membership_type || 'standard';
    const schedule = fees.find(f => f.membership_type === mType);
    
    if (schedule) {
      if (paymentType === 'membership' || paymentType === 'renewal') {
        setAmount(String(schedule.annual_fee));
        if (!reason) setReason(`Annual Membership Fee - ${mType.toUpperCase()}`);
      } else if (paymentType === 'meeting_fee') {
        setAmount(String(schedule.per_forum_fee));
        if (!reason) setReason(`Forum Meeting Fee - ${new Date().toLocaleString('default', { month: 'long' })}`);
      }
    }
  }, [userId, paymentType, fees, users]);

  const handleSubmit = async (e) => {
    e.preventDefault();
    if (!userId) return setError('Please select a user');
    if (!paymentType) return setError('Please select a payment type');
    if (!reason) return setError('Please provide a payment reason');

    setLoading(true);
    setError('');
    try {
      await api.recordPayment({
        user_id: userId,
        amount: parseFloat(amount),
        payment_type: paymentType,
        reason,
        notes,
        status: 'completed'
      });
      onRecord();
      onClose();
    } catch (err) {
      setError(err.message);
    } finally {
      setLoading(false);
    }
  };

  return (
    <div className="modal-overlay" onClick={(e) => e.target === e.currentTarget && onClose()}>
      <div className="modal-content" onClick={e => e.stopPropagation()} style={{ maxWidth: 500 }}>
        <div className="modal-header">
          <h2 style={{ fontSize: '1.25rem', fontWeight: 800 }}>Record Manual Payment</h2>
          <button type="button" className="modal-close-btn" onClick={onClose}>
            <IconX size={20} />
          </button>
        </div>
        <form onSubmit={handleSubmit} style={{ padding: '1.5rem 1.5rem 8rem' }}>
          {error && <div className="login-error" style={{ marginBottom: '1rem' }}>{error}</div>}

          <div style={{ marginBottom: '1rem' }}>
            <label style={{ fontSize: '0.75rem', fontWeight: 700, color: 'var(--text-secondary)', textTransform: 'uppercase', letterSpacing: '0.05em', display: 'block', marginBottom: '0.5rem' }}>Select User</label>
            <CustomSelect
              label="Choose a member/prospect..."
              value={userId}
              options={users.map(u => ({ id: u.id, name: `${u.full_name} (${u.phone_number})` }))}
              onChange={setUserId}
            />
          </div>

          <div style={{ display: 'grid', gridTemplateColumns: '1fr 1fr', gap: '1rem', marginBottom: '1rem' }}>
             <div>
              <label style={{ fontSize: '0.75rem', fontWeight: 700, color: 'var(--text-secondary)', textTransform: 'uppercase', letterSpacing: '0.05em', display: 'block', marginBottom: '0.5rem' }}>Type</label>
              <CustomSelect
                label="Select type..."
                value={paymentType}
                options={[
                  { id: 'membership', name: 'Annual Membership' },
                  { id: 'meeting_fee', name: 'Meeting Fee' },
                  { id: 'renewal', name: 'Renewal' }
                ]}
                onChange={setPaymentType}
              />
            </div>
            <div className="login-field">
              <label>Amount (LKR)</label>
              <input type="number" value={amount} onChange={e => setAmount(e.target.value)} required className="filter-input" style={{ height: '52px' }} />
            </div>
          </div>

          <div className="login-field" style={{ marginBottom: '1rem' }}>
            <label>Payment Reason</label>
            <input
              type="text"
              placeholder="e.g. Annual Membership Fee 2025"
              value={reason}
              onChange={e => setReason(e.target.value)}
              className="filter-input"
              required
            />
          </div>

          <div className="login-field" style={{ marginBottom: '1.5rem' }}>
            <label>Admin Notes</label>
            <textarea
              value={notes}
              onChange={e => setNotes(e.target.value)}
              className="action-textarea"
              placeholder="Internal notes..."
              style={{ minHeight: 80 }}
            />
          </div>

          <button type="submit" className="login-btn" disabled={loading}>
            {loading ? 'Recording...' : 'Record Payment'}
          </button>
        </form>
      </div>
    </div>
  );
}

function UpdatePaymentModal({ payment, onClose, onUpdate }) {
  const [reason, setReason] = useState(payment.reason || '');
  const [notes, setNotes] = useState(payment.notes || '');
  const [status, setStatus] = useState(payment.status || 'completed');
  const [loading, setLoading] = useState(false);
  const [error, setError] = useState('');

  const handleSubmit = async (e) => {
    e.preventDefault();
    setLoading(true);
    try {
      await api.updatePayment(payment.id, { reason, notes, status });
      onUpdate();
      onClose();
    } catch (err) {
      setError(err.message);
    } finally {
      setLoading(false);
    }
  };

  return (
    <div className="modal-overlay" onClick={(e) => e.target === e.currentTarget && onClose()}>
      <div className="modal-content" onClick={e => e.stopPropagation()} style={{ maxWidth: 500 }}>
        <div className="modal-header">
          <h2 style={{ fontSize: '1.25rem', fontWeight: 800 }}>Update Payment</h2>
          <button type="button" className="modal-close-btn" onClick={onClose}>
            <IconX size={20} />
          </button>
        </div>
        <form onSubmit={handleSubmit} style={{ padding: '1.5rem' }}>
          {error && <div className="login-error" style={{ marginBottom: '1rem' }}>{error}</div>}

          <div className="login-field" style={{ marginBottom: '1rem' }}>
            <label>Payment Reason</label>
            <input type="text" value={reason} onChange={e => setReason(e.target.value)} className="filter-input" required />
          </div>

          <div style={{ marginBottom: '1.5rem' }}>
            <label style={{ fontSize: '0.75rem', fontWeight: 700, color: 'var(--text-secondary)', textTransform: 'uppercase', letterSpacing: '0.05em', display: 'block', marginBottom: '0.5rem' }}>Status</label>
            <CustomSelect
              label="Select status..."
              value={status}
              options={[
                { id: 'pending', name: 'Pending' },
                { id: 'completed', name: 'Completed' },
                { id: 'failed', name: 'Failed' },
                { id: 'refunded', name: 'Refunded' }
              ]}
              onChange={setStatus}
            />
          </div>

          <div className="login-field" style={{ marginBottom: '1.5rem' }}>
            <label>Admin Notes</label>
            <textarea value={notes} onChange={e => setNotes(e.target.value)} className="action-textarea" style={{ minHeight: 80 }} />
          </div>

          <button type="submit" className="login-btn" disabled={loading}>
            {loading ? 'Updating...' : 'Save Changes'}
          </button>
        </form>
      </div>
    </div>
  );
}

function PaymentsPage() {
  const [activeTab, setActiveTab] = useState('transactions');
  const [payments, setPayments] = useState([]);
  const [loading, setLoading] = useState(true);
  const [showRecordModal, setShowRecordModal] = useState(false);
  const [editingPayment, setEditingPayment] = useState(null);
  const [users, setUsers] = useState([]);

  const fetchPayments = useCallback(async () => {
    setLoading(true);
    try {
      const data = await api.listPayments();
      setPayments(data || []);
    } catch (err) {
      console.error(err);
    } finally {
      setLoading(false);
    }
  }, []);

  useEffect(() => {
    fetchPayments();
    api.listUsers({ limit: 1000 }).then(data => setUsers(data.users || []));
  }, [fetchPayments]);

  const completedTotal = payments
    .filter(p => p.status === 'completed')
    .reduce((sum, p) => sum + (Number(p.amount) || 0), 0);
  const pendingCount = payments.filter(p => p.status === 'pending').length;

  return (
    <section className="ds-page">
      <Ds.PageHeader
        title="Payments"
        description="Track and record all network transactions and membership fees."
        actions={
          <>
            <Ds.Button
              variant="secondary"
              leftIcon={<IconRefresh size={14} />}
              onClick={fetchPayments}
            >
              Refresh
            </Ds.Button>
            <Ds.Button
              variant="primary"
              leftIcon={<IconCoin size={14} />}
              onClick={() => setShowRecordModal(true)}
            >
              Record payment
            </Ds.Button>
          </>
        }
      />

      <div className="ds-tabs" style={{ marginBottom: '1.5rem', borderBottom: '1px solid var(--border-subtle)', display: 'flex', gap: '2rem' }}>
        <button className={`ds-tab ${activeTab === 'transactions' ? 'active' : ''}`} onClick={() => setActiveTab('transactions')} style={{ background: 'none', border: 'none', padding: '0.75rem 0', fontWeight: 600, color: activeTab === 'transactions' ? 'var(--brand-blue)' : 'var(--fg-muted)', borderBottom: activeTab === 'transactions' ? '2px solid var(--brand-blue)' : '2px solid transparent', cursor: 'pointer' }}>Transactions</button>
        <button className={`ds-tab ${activeTab === 'proofs' ? 'active' : ''}`} onClick={() => setActiveTab('proofs')} style={{ background: 'none', border: 'none', padding: '0.75rem 0', fontWeight: 600, color: activeTab === 'proofs' ? 'var(--brand-blue)' : 'var(--fg-muted)', borderBottom: activeTab === 'proofs' ? '2px solid var(--brand-blue)' : '2px solid transparent', cursor: 'pointer' }}>Payment Proofs</button>
      </div>

      {activeTab === 'transactions' ? (
        <>
          <div className="ds-stat-grid">
        <Ds.StatCard
          label="Transactions"
          value={payments.length}
          icon={IconCoin}
          iconColor="var(--brand-blue)"
          iconBg="var(--brand-blue-50)"
        />
        <Ds.StatCard
          label="Completed value"
          value={formatCurrency(completedTotal)}
          icon={IconCheck}
          iconColor="var(--success)"
          iconBg="var(--success-bg)"
        />
        <Ds.StatCard
          label="Pending"
          value={pendingCount}
          icon={IconClock}
          iconColor="var(--warning)"
          iconBg="var(--warning-bg)"
        />
      </div>

      <Ds.Section title="Transaction History" flush>
        <Ds.Table>
          <thead>
            <tr>
              <th>Date</th>
              <th>Member</th>
              <th>Reason</th>
              <th>Type</th>
              <th>Amount</th>
              <th>Status</th>
              <th className="ds-table__actions" />
            </tr>
          </thead>
          <tbody>
            {loading ? (
              <Ds.Table.LoadingRow colSpan={7} label="Loading payments…" />
            ) : payments.length === 0 ? (
              <Ds.Table.EmptyRow
                colSpan={7}
                icon={IconCoin}
                title="No payments yet"
                description="Recorded transactions will appear here."
              />
            ) : payments.map(p => (
              <tr key={p.id}>
                <td className="ds-table__muted">
                  {new Date(p.created_at).toLocaleDateString()}
                </td>
                <td>
                  <div className="ds-table__primary">{p.user_name || 'Unknown'}</div>
                  <div style={{ fontSize: 'var(--text-xs)', color: 'var(--fg-muted)', fontWeight: 'var(--weight-medium)' }}>
                    {p.user_phone}
                  </div>
                </td>
                <td style={{ maxWidth: 220, overflow: 'hidden', textOverflow: 'ellipsis', whiteSpace: 'nowrap' }} className="ds-table__muted">
                  {p.reason || '—'}
                </td>
                <td>
                  <Ds.Badge variant="neutral">{p.payment_type}</Ds.Badge>
                </td>
                <td className="ds-table__primary" style={{ fontWeight: 'var(--weight-bold)' }}>
                  {formatCurrency(p.amount)}
                </td>
                <td>
                  <Ds.Badge dot variant={p.status === 'completed' ? 'success' : p.status === 'failed' ? 'danger' : 'warning'}>
                    {p.status}
                  </Ds.Badge>
                </td>
                <td className="ds-table__actions">
                  <PaymentActionMenu payment={p} onEdit={() => setEditingPayment(p)} />
                </td>
              </tr>
            ))}
          </tbody>
        </Ds.Table>
      </Ds.Section>

      {showRecordModal && (
        <RecordPaymentModal
          users={users}
          onClose={() => setShowRecordModal(false)}
          onRecord={fetchPayments}
        />
      )}
      {editingPayment && (
        <UpdatePaymentModal
          payment={editingPayment}
          onClose={() => setEditingPayment(null)}
          onUpdate={fetchPayments}
        />
      )}
        </>
      ) : (
        <PaymentProofsTab />
      )}
    </section>
  );
}




// ── Partners & Rewards Page ────────────────────────────────────────────────

function CreatePartnerModal({ onClose, onCreated }) {
  const [formData, setFormData] = useState({
    name: '',
    description: '',
    logo_url: '',
    website: '',
    is_active: true
  });
  const [loading, setLoading] = useState(false);
  const [uploading, setUploading] = useState(false);
  const [error, setError] = useState('');

  const handleFileUpload = async (e) => {
    const file = e.target.files[0];
    if (!file) return;

    setUploading(true);
    setError('');
    try {
      const result = await api.uploadPartnerLogo(file);
      setFormData(prev => ({ ...prev, logo_url: result.logo_url }));
    } catch (err) {
      setError('Logo upload failed: ' + err.message);
    } finally {
      setUploading(false);
    }
  };

  const handleSubmit = async (e) => {
    e.preventDefault();
    setLoading(true);
    setError('');
    try {
      await api.createPartner(formData);
      onCreated();
    } catch (err) {
      setError(err.message || 'Failed to create partner');
    } finally {
      setLoading(false);
    }
  };

  return (
    <div className="modal-overlay" onClick={(e) => e.target === e.currentTarget && onClose()}>
      <div className="modal-content" onClick={e => e.stopPropagation()} style={{ maxWidth: 500 }}>
        <div className="modal-header">
          <h2 style={{ fontSize: '1.25rem', fontWeight: 800 }}>Add New Partner</h2>
          <button type="button" className="modal-close-btn" onClick={onClose}>
            <IconX size={20} />
          </button>
        </div>
        <form onSubmit={handleSubmit} style={{ padding: '1.5rem 1.5rem 2rem' }}>
          {error && <div className="login-error" style={{ marginBottom: '1rem' }}>{error}</div>}
          
          <div className="login-field">
            <label>Business Name *</label>
            <input
              type="text"
              className="filter-input v2"
              required
              value={formData.name}
              onChange={e => setFormData({ ...formData, name: e.target.value })}
            />
          </div>

          <div className="login-field">
            <label>Partner Logo</label>
            <div style={{ display: 'flex', gap: '1rem', alignItems: 'center' }}>
              <div style={{ width: 64, height: 64, borderRadius: '12px', background: '#f8fafc', overflow: 'hidden', display: 'flex', alignItems: 'center', justifyContent: 'center', border: '1px solid #e2e8f0' }}>
                {formData.logo_url ? <img src={formData.logo_url.startsWith('http') ? formData.logo_url : `${STATIC_BASE_URL}${formData.logo_url}`} style={{ width: '100%', height: '100%', objectFit: 'contain' }} /> : <IconBuildingStore size={24} color="#94a3b8" />}
              </div>
              <div style={{ flex: 1 }}>
                <input
                  type="file"
                  id="partner-logo-upload"
                  accept="image/*,image/svg+xml"
                  style={{ display: 'none' }}
                  onChange={handleFileUpload}
                />
                <label 
                  htmlFor="partner-logo-upload" 
                  className="btn-secondary" 
                  style={{ display: 'inline-flex', alignItems: 'center', gap: '0.5rem', cursor: 'pointer', fontSize: '0.85rem', padding: '0.6rem 1rem' }}
                >
                  <IconPlus size={16} /> {uploading ? 'Uploading...' : formData.logo_url ? 'Change Logo' : 'Upload Logo'}
                </label>
                {formData.logo_url && (
                  <button 
                    type="button" 
                    style={{ marginLeft: '0.5rem', fontSize: '0.75rem', color: '#ef4444', border: 'none', background: 'none', cursor: 'pointer', fontWeight: 600 }}
                    onClick={() => setFormData({ ...formData, logo_url: '' })}
                  >
                    Remove
                  </button>
                )}
              </div>
            </div>
          </div>

          <div className="login-field">
            <label>Website</label>
            <input 
              type="url" 
              className="filter-input v2"
              placeholder="https://partner-website.com"
              value={formData.website}
              onChange={e => setFormData({...formData, website: e.target.value})}
            />
          </div>
          <div className="login-field">
            <label>Description</label>
            <textarea 
              className="action-textarea"
              style={{ minHeight: 80 }}
              value={formData.description}
              onChange={e => setFormData({...formData, description: e.target.value})}
            />
          </div>
          <button type="submit" className="login-btn" disabled={loading || uploading}>
            {loading ? 'Creating...' : 'Create Partner'}
          </button>
        </form>
      </div>
    </div>
  );
}

function EditPartnerModal({ partner, onClose, onUpdated }) {
  const [formData, setFormData] = useState({
    name: partner.name || '',
    description: partner.description || '',
    logo_url: partner.logo_url || '',
    website: partner.website || '',
    is_active: partner.is_active ?? true
  });
  const [loading, setLoading] = useState(false);
  const [uploading, setUploading] = useState(false);
  const [error, setError] = useState('');

  const handleFileUpload = async (e) => {
    const file = e.target.files[0];
    if (!file) return;

    setUploading(true);
    setError('');
    try {
      const result = await api.uploadPartnerLogo(file);
      setFormData(prev => ({ ...prev, logo_url: result.logo_url }));
    } catch (err) {
      setError('Logo upload failed: ' + err.message);
    } finally {
      setUploading(false);
    }
  };

  const handleSubmit = async (e) => {
    e.preventDefault();
    setLoading(true);
    setError('');
    try {
      await api.updatePartner(partner.id, formData);
      onUpdated();
    } catch (err) {
      setError(err.message || 'Failed to update partner');
    } finally {
      setLoading(false);
    }
  };

  return (
    <div className="modal-overlay" onClick={(e) => e.target === e.currentTarget && onClose()}>
      <div className="modal-content" onClick={e => e.stopPropagation()} style={{ maxWidth: 500 }}>
        <div className="modal-header">
          <h2 style={{ fontSize: '1.25rem', fontWeight: 800 }}>Edit Partner</h2>
          <button type="button" className="modal-close-btn" onClick={onClose}>
            <IconX size={20} />
          </button>
        </div>
        <form onSubmit={handleSubmit} style={{ padding: '1.5rem 1.5rem 2rem' }}>
          {error && <div className="login-error" style={{ marginBottom: '1rem' }}>{error}</div>}
          
          <div className="login-field">
            <label>Business Name *</label>
            <input
              type="text"
              className="filter-input v2"
              required
              value={formData.name}
              onChange={e => setFormData({ ...formData, name: e.target.value })}
            />
          </div>

          <div className="login-field">
            <label>Partner Logo</label>
            <div style={{ display: 'flex', gap: '1rem', alignItems: 'center' }}>
              <div style={{ width: 64, height: 64, borderRadius: '12px', background: '#f8fafc', overflow: 'hidden', display: 'flex', alignItems: 'center', justifyContent: 'center', border: '1px solid #e2e8f0' }}>
                {formData.logo_url ? <img src={formData.logo_url.startsWith('http') ? formData.logo_url : `${STATIC_BASE_URL}${formData.logo_url}`} style={{ width: '100%', height: '100%', objectFit: 'contain' }} /> : <IconBuildingStore size={24} color="#94a3b8" />}
              </div>
              <div style={{ flex: 1 }}>
                <input
                  type="file"
                  id="partner-logo-edit-upload"
                  accept="image/*,image/svg+xml"
                  style={{ display: 'none' }}
                  onChange={handleFileUpload}
                />
                <label 
                  htmlFor="partner-logo-edit-upload" 
                  className="btn-secondary" 
                  style={{ display: 'inline-flex', alignItems: 'center', gap: '0.5rem', cursor: 'pointer', fontSize: '0.85rem', padding: '0.6rem 1rem' }}
                >
                  <IconPlus size={16} /> {uploading ? 'Uploading...' : formData.logo_url ? 'Change Logo' : 'Upload Logo'}
                </label>
                {formData.logo_url && (
                  <button 
                    type="button" 
                    style={{ marginLeft: '0.5rem', fontSize: '0.75rem', color: '#ef4444', border: 'none', background: 'none', cursor: 'pointer', fontWeight: 600 }}
                    onClick={() => setFormData({ ...formData, logo_url: '' })}
                  >
                    Remove
                  </button>
                )}
              </div>
            </div>
          </div>

          <div className="login-field">
            <label>Website</label>
            <input 
              type="url" 
              className="filter-input v2"
              placeholder="https://partner-website.com"
              value={formData.website}
              onChange={e => setFormData({...formData, website: e.target.value})}
            />
          </div>
          <div className="login-field">
            <label>Description</label>
            <textarea 
              className="action-textarea"
              style={{ minHeight: 80 }}
              value={formData.description}
              onChange={e => setFormData({...formData, description: e.target.value})}
            />
          </div>
          
          <div style={{ display: 'flex', alignItems: 'center', gap: '0.75rem', marginBottom: '1.5rem', background: '#f8fafc', padding: '1rem', borderRadius: '12px' }}>
            <input 
              type="checkbox" 
              id="partner-active" 
              checked={formData.is_active}
              onChange={e => setFormData({...formData, is_active: e.target.checked})}
              style={{ width: 18, height: 18 }}
            />
            <label htmlFor="partner-active" style={{ fontWeight: 700, fontSize: '0.85rem' }}>Partner is active & visible in app</label>
          </div>

          <button type="submit" className="login-btn" disabled={loading || uploading}>
            {loading ? 'Saving...' : 'Save Changes'}
          </button>
        </form>
      </div>
    </div>
  );
}

function CreateOfferModal({ partner, onClose, onCreated }) {
  const [formData, setFormData] = useState({
    title: '',
    description: '',
    offer_type: 'discount',
    redemption_method: 'qr',
    discount_percentage: 10,
    start_date: new Date(),
    end_date: new Date(Date.now() + 30 * 24 * 60 * 60 * 1000),
    redemption_instructions: 'Show your PBN Privilege Card at the counter.',
    is_active: true
  });
  const [loading, setLoading] = useState(false);
  const [error, setError] = useState('');

  const handleSubmit = async (e) => {
    e.preventDefault();
    setLoading(true);
    setError('');
    try {
      await api.createOffer(partner.id, {
        ...formData,
        start_date: formData.start_date.toISOString().split('T')[0],
        end_date: formData.end_date.toISOString().split('T')[0],
      });
      onCreated();
    } catch (err) {
      setError(err.message || 'Failed to create reward');
    } finally {
      setLoading(false);
    }
  };

  return (
    <div className="modal-overlay" onClick={(e) => e.target === e.currentTarget && onClose()}>
      <div className="modal-content" onClick={e => e.stopPropagation()} style={{ maxWidth: 550 }}>
        <div className="modal-header">
          <div>
            <h2 style={{ fontSize: '1.25rem', fontWeight: 800 }}>New Reward Offer</h2>
            <p style={{ fontSize: '0.85rem', color: 'var(--text-secondary)' }}>Adding for {partner.name}</p>
          </div>
          <button type="button" className="modal-close-btn" onClick={onClose}>
            <IconX size={20} />
          </button>
        </div>
        <form onSubmit={handleSubmit} style={{ padding: '1.5rem' }}>
          {error && <div className="login-error" style={{ marginBottom: '1rem' }}>{error}</div>}
          
          <div className="login-field">
            <label>Offer Title *</label>
            <input 
              type="text" 
              className="filter-input v2"
              placeholder="e.g., 20% Off All Purchases"
              required 
              value={formData.title}
              onChange={e => setFormData({...formData, title: e.target.value})}
            />
          </div>

          <div style={{ display: 'grid', gridTemplateColumns: '1fr 1fr', gap: '1rem', marginBottom: '1rem' }}>
            <div className="login-field" style={{ marginBottom: 0 }}>
              <label>Deal Category</label>
              <select 
                className="filter-input v2" 
                style={{ height: 48 }}
                value={formData.offer_type}
                onChange={e => setFormData({...formData, offer_type: e.target.value})}
              >
                <option value="discount">Direct Discount</option>
                <option value="free_item">Free Item/Gift</option>
                <option value="service">Complimentary Service</option>
              </select>
            </div>
            <div className="login-field" style={{ marginBottom: 0 }}>
              <label>Redemption Method</label>
              <select 
                className="filter-input v2" 
                style={{ height: 48 }}
                value={formData.redemption_method}
                onChange={e => setFormData({...formData, redemption_method: e.target.value})}
              >
                <option value="qr">In-Person (QR Scan)</option>
                <option value="coupon">Online (Coupon Code)</option>
              </select>
            </div>
          </div>

          <div className="login-field">
            <label>Discount % (if applicable)</label>
            <input 
              type="number" 
              className="filter-input v2"
              value={formData.discount_percentage}
              onChange={e => setFormData({...formData, discount_percentage: parseInt(e.target.value)})}
            />
          </div>

          <div style={{ display: 'grid', gridTemplateColumns: '1fr 1fr', gap: '1rem', marginBottom: '1rem' }}>
             <div className="login-field" style={{ marginBottom: 0 }}>
              <label>Start Date</label>
              <DatePicker
                selected={formData.start_date}
                onChange={date => setFormData({ ...formData, start_date: date })}
                dateFormat="MMMM d, yyyy"
                className="modern-datepicker-input"
              />
            </div>
            <div className="login-field" style={{ marginBottom: 0 }}>
              <label>End Date</label>
              <DatePicker
                selected={formData.end_date}
                onChange={date => setFormData({ ...formData, end_date: date })}
                dateFormat="MMMM d, yyyy"
                className="modern-datepicker-input"
                minDate={formData.start_date}
              />
            </div>
          </div>

          <div className="login-field">
            <label>Redemption Instructions</label>
            <textarea 
              className="action-textarea"
              style={{ minHeight: 60 }}
              value={formData.redemption_instructions}
              onChange={e => setFormData({...formData, redemption_instructions: e.target.value})}
            />
          </div>

          <div className="modal-info-box" style={{ background: '#f0fdf4', color: '#166534', padding: '1rem', borderRadius: '12px', fontSize: '0.85rem', marginBottom: '1.5rem', display: 'flex', gap: '0.75rem' }}>
            <IconBell size={20} />
            <p><strong>Note:</strong> Creating this reward will automatically notify all app members via push notification.</p>
          </div>

          <button type="submit" className="login-btn" disabled={loading}>
            {loading ? 'Processing...' : 'Create & Notify Users'}
          </button>
        </form>
      </div>
    </div>
  );
}

function SearchableSelect({ label, value, options, onChange, placeholder = "Search...", style }) {
  const [isOpen, setIsOpen] = useState(false);
  const [search, setSearch] = useState('');
  const containerRef = useRef(null);

  useEffect(() => {
    const handleClickOutside = (event) => {
      if (containerRef.current && !containerRef.current.contains(event.target)) {
        setIsOpen(false);
      }
    };
    document.addEventListener('mousedown', handleClickOutside);
    return () => document.removeEventListener('mousedown', handleClickOutside);
  }, []);

  const filteredOptions = (options || []).filter(opt => 
    (opt.name || opt.label || '').toLowerCase().includes(search.toLowerCase()) ||
    (opt.email || '').toLowerCase().includes(search.toLowerCase())
  );

  const selectedOption = (options || []).find(opt => String(opt.id) === String(value));

  return (
    <div className="custom-select-container" ref={containerRef} style={style}>
      <button
        type="button"
        className={`custom-select-trigger ${isOpen ? 'active' : ''}`}
        onClick={() => setIsOpen(!isOpen)}
      >
        <span>{selectedOption ? (selectedOption.name || selectedOption.label) : label}</span>
        <IconChevronDown size={18} className={`select-arrow ${isOpen ? 'rotated' : ''}`} />
      </button>

      {isOpen && (
        <div className="custom-select-menu">
          <div style={{ padding: '0.75rem', borderBottom: '1px solid var(--border)' }}>
            <input 
              type="text" 
              className="form-input" 
              style={{ height: '36px', fontSize: '0.8rem', borderRadius: '8px' }}
              placeholder={placeholder}
              value={search}
              onChange={e => setSearch(e.target.value)}
              autoFocus
              onClick={e => e.stopPropagation()}
            />
          </div>
          <div style={{ maxHeight: '250px', overflowY: 'auto' }}>
            {filteredOptions.length === 0 ? (
              <div style={{ padding: '1rem', textAlign: 'center', color: 'var(--text-secondary)', fontSize: '0.8rem' }}>
                No results found
              </div>
            ) : (
              filteredOptions.map((opt) => (
                <div
                  key={opt.id}
                  className={`custom-select-option ${String(value) === String(opt.id) ? 'selected' : ''}`}
                  onClick={() => { 
                    onChange(opt.id); 
                    setIsOpen(false); 
                    setSearch('');
                  }}
                >
                  <div style={{ display: 'flex', flexDirection: 'column', gap: '2px' }}>
                    <span style={{ fontWeight: 600 }}>{opt.name || opt.label}</span>
                    {opt.email && <span style={{ fontSize: '0.7rem', color: 'var(--text-secondary)' }}>{opt.email}</span>}
                  </div>
                </div>
              ))
            )}
          </div>
        </div>
      )}
    </div>
  );
}

function IssueCardModal({ onClose, onIssued }) {
  const [loading, setLoading] = useState(false);
  const [userId, setUserId] = useState('');
  const [nfcUid, setNfcUid] = useState('');
  const [physicalIssued, setPhysicalIssued] = useState(false);
  const [users, setUsers] = useState([]);

  useEffect(() => {
    api.listUsers({ limit: 1000 }).then(data => {
      setUsers(data?.users || []);
    }).catch(console.error);
  }, []);

  const handleSubmit = async (e) => {
    e.preventDefault();
    setLoading(true);
    try {
      await api.issuePrivilegeCard({
        user_id: userId,
        nfc_uid: nfcUid || null,
        physical_issued: physicalIssued
      });
      onIssued();
    } catch (err) {
      alert(err.message);
    } finally {
      setLoading(false);
    }
  };

  return (
    <div className="modal-overlay" onClick={(e) => e.target === e.currentTarget && onClose()}>
      <div className="modal-content" onClick={e => e.stopPropagation()} style={{ maxWidth: '500px' }}>
        <div className="modal-header">
          <h2>Issue Privilege Card</h2>
          <button type="button" className="modal-close-btn" onClick={onClose}><IconX size={20} /></button>
        </div>
        <form className="modal-body" onSubmit={handleSubmit} style={{ padding: '2rem' }}>
          <div className="form-group">
            <label className="form-label">Member</label>
            <SearchableSelect 
              label="Select Member..."
              value={userId}
              onChange={val => setUserId(val)}
              options={users.map(u => ({ id: u.id, name: u.full_name, email: u.email }))}
              placeholder="Search by name or email..."
            />
          </div>
          <div className="form-group">
            <label className="form-label">NFC UID (Optional)</label>
            <input 
              type="text" 
              className="form-input" 
              value={nfcUid} 
              onChange={e => setNfcUid(e.target.value)} 
              placeholder="Tap card or enter hex manually" 
            />
          </div>
          <div className="form-group">
            <div className="form-checkbox-group" onClick={() => setPhysicalIssued(!physicalIssued)}>
              <input 
                type="checkbox" 
                id="physical_issued" 
                checked={physicalIssued} 
                onChange={e => setPhysicalIssued(e.target.checked)} 
                onClick={e => e.stopPropagation()}
              />
              <label htmlFor="physical_issued">Physical Card Handed Over</label>
            </div>
          </div>
          <button type="submit" className="btn-primary" style={{ width: '100%', marginTop: '1rem', height: '52px' }} disabled={loading || !userId}>
            {loading ? 'Processing...' : 'Issue Card'}
          </button>
        </form>
      </div>
    </div>
  );
}

function CardHistoryModal({ card, onClose }) {
  const [history, setHistory] = useState([]);
  const [loading, setLoading] = useState(true);

  useEffect(() => {
    api.listPrivilegeCardHistory(card.id).then(setHistory).catch(console.error).finally(() => setLoading(false));
  }, [card.id]);

  const getActionColor = (action) => {
    switch(action) {
      case 'issued': return '#10b981';
      case 'suspended': return '#f59e0b';
      case 'replaced': return '#ef4444';
      case 'reactivated': return '#3b82f6';
      default: return 'var(--text-secondary)';
    }
  };

  return (
    <div className="modal-overlay" onClick={(e) => e.target === e.currentTarget && onClose()}>
      <div className="modal-content" onClick={e => e.stopPropagation()} style={{ maxWidth: '650px' }}>
        <div className="modal-header">
          <div>
            <h2 style={{ marginBottom: '4px' }}>Card Lifecycle History</h2>
            <p style={{ fontSize: '0.85rem', color: 'var(--text-secondary)' }}>{card.card_number} — {card.member_name}</p>
          </div>
          <button type="button" className="modal-close-btn" onClick={onClose}><IconX size={20} /></button>
        </div>
        <div className="modal-body" style={{ padding: '1.5rem', maxHeight: '70vh', overflowY: 'auto' }}>
          {loading ? (
            <div style={{ textAlign: 'center', padding: '2rem' }}>Loading history...</div>
          ) : history.length === 0 ? (
            <div style={{ textAlign: 'center', padding: '2rem', color: 'var(--text-secondary)' }}>No history found for this card.</div>
          ) : (
            <div className="timeline" style={{ paddingLeft: '1.5rem', borderLeft: '2px solid var(--border)', position: 'relative', display: 'flex', flexDirection: 'column', gap: '2rem' }}>
              {history.map((h, i) => (
                <div key={h.id} style={{ position: 'relative' }}>
                  <div style={{ 
                    position: 'absolute', 
                    left: '-23px', 
                    top: '4px', 
                    width: '14px', 
                    height: '14px', 
                    borderRadius: '50%', 
                    background: getActionColor(h.action),
                    border: '3px solid white',
                    boxShadow: '0 0 0 2px ' + getActionColor(h.action)
                  }} />
                  <div style={{ display: 'flex', justifyContent: 'space-between', alignItems: 'flex-start', marginBottom: '8px' }}>
                    <h4 style={{ margin: 0, textTransform: 'uppercase', fontSize: '0.75rem', letterSpacing: '0.05em', color: getActionColor(h.action) }}>
                      {h.action}
                    </h4>
                    <span style={{ fontSize: '0.75rem', color: 'var(--text-secondary)' }}>
                      {new Date(h.performed_at).toLocaleString()}
                    </span>
                  </div>
                  <div style={{ background: '#f8fafc', padding: '1rem', borderRadius: '12px', border: '1px solid var(--border)' }}>
                    <div style={{ display: 'grid', gridTemplateColumns: '1fr 1fr', gap: '1rem', fontSize: '0.85rem' }}>
                      {h.new_card_number && h.old_card_number !== h.new_card_number && (
                        <div>
                          <label style={{ display: 'block', fontSize: '0.7rem', color: 'var(--text-secondary)', marginBottom: '2px' }}>Card Number</label>
                          <span style={{ fontWeight: 600 }}>{h.old_card_number || 'None'} → {h.new_card_number}</span>
                        </div>
                      )}
                      {(h.old_nfc_uid || h.new_nfc_uid) && (
                        <div>
                          <label style={{ display: 'block', fontSize: '0.7rem', color: 'var(--text-secondary)', marginBottom: '2px' }}>NFC UID</label>
                          <span style={{ fontWeight: 600, fontFamily: 'monospace' }}>{h.old_nfc_uid || 'None'} → {h.new_nfc_uid || 'Cleared'}</span>
                        </div>
                      )}
                      {h.new_version && h.old_version !== h.new_version && (
                        <div>
                          <label style={{ display: 'block', fontSize: '0.7rem', color: 'var(--text-secondary)', marginBottom: '2px' }}>Version</label>
                          <span>v{h.old_version || 0} → v{h.new_version}</span>
                        </div>
                      )}
                    </div>
                    {h.notes && (
                      <div style={{ marginTop: '0.75rem', fontSize: '0.85rem', color: 'var(--text-secondary)', fontStyle: 'italic', borderTop: '1px dashed var(--border)', paddingTop: '0.75rem' }}>
                        "{h.notes}"
                      </div>
                    )}
                  </div>
                </div>
              ))}
            </div>
          )}
        </div>
      </div>
    </div>
  );
}

function EditCardModal({ card, onClose, onUpdated }) {
  const [loading, setLoading] = useState(false);
  const [nfcUid, setNfcUid] = useState(card.nfc_uid || '');
  const [physicalIssued, setPhysicalIssued] = useState(card.physical_issued);
  const [status, setStatus] = useState(card.card_status);

  const handleSubmit = async (e) => {
    e.preventDefault();
    setLoading(true);
    try {
      await api.updatePrivilegeCard(card.id, {
        nfc_uid: nfcUid || null,
        physical_issued: physicalIssued,
        card_status: status
      });
      onUpdated();
    } catch (err) {
      alert(err.message);
    } finally {
      setLoading(false);
    }
  };

  return (
    <div className="modal-overlay" onClick={(e) => e.target === e.currentTarget && onClose()}>
      <div className="modal-content" onClick={e => e.stopPropagation()} style={{ maxWidth: '500px' }}>
        <div className="modal-header">
          <h2>Edit Privilege Card</h2>
          <button type="button" className="modal-close-btn" onClick={onClose}><IconX size={20} /></button>
        </div>
        <form className="modal-body" onSubmit={handleSubmit} style={{ padding: '2rem' }}>
          <div className="form-group">
            <label className="form-label">Member</label>
            <div className="form-input" style={{ background: '#f8fafc', color: 'var(--text-secondary)' }}>
              {card.member_name}
            </div>
          </div>
          <div className="form-group">
            <label className="form-label">Card Number</label>
            <div className="form-input" style={{ background: '#f8fafc', color: 'var(--text-secondary)' }}>
              {card.card_number}
            </div>
          </div>
          <div className="form-group">
            <label className="form-label">Status</label>
            <select className="form-select" value={status} onChange={e => setStatus(e.target.value)}>
              <option value="active">Active</option>
              <option value="suspended">Suspended</option>
              <option value="replaced">Replaced</option>
            </select>
          </div>
          <div className="form-group">
            <label className="form-label">NFC UID</label>
            <input 
              type="text" 
              className="form-input" 
              value={nfcUid} 
              onChange={e => setNfcUid(e.target.value)} 
              placeholder="NFC Hex UID" 
            />
          </div>
          <div className="form-group">
            <div className="form-checkbox-group" onClick={() => setPhysicalIssued(!physicalIssued)}>
              <input 
                type="checkbox" 
                id="edit_physical_issued" 
                checked={physicalIssued} 
                onChange={e => setPhysicalIssued(e.target.checked)} 
                onClick={e => e.stopPropagation()}
              />
              <label htmlFor="edit_physical_issued">Physical Card Handed Over</label>
            </div>
          </div>
          <button type="submit" className="btn-primary" style={{ width: '100%', marginTop: '1rem', height: '52px' }} disabled={loading}>
            {loading ? 'Saving...' : 'Save Changes'}
          </button>
        </form>
      </div>
    </div>
  );
}

function CardActionMenu({ card, onEdit, onHistory, onSuspend, onReplace, onActivate }) {
  const [isOpen, setIsOpen] = useState(false);
  const menuRef = useRef(null);

  useEffect(() => {
    const handleClickOutside = (e) => {
      if (menuRef.current && !menuRef.current.contains(e.target)) setIsOpen(false);
    };
    document.addEventListener('mousedown', handleClickOutside);
    return () => document.removeEventListener('mousedown', handleClickOutside);
  }, []);

  return (
    <div className="action-menu-container" ref={menuRef}>
      <button className="view-detail-btn" title="Actions" onClick={() => setIsOpen(!isOpen)}>
        <IconSettings size={20} />
      </button>
      
      {isOpen && (
        <div className="action-dropdown">
          <button className="action-item" onClick={() => { onEdit(); setIsOpen(false); }}>
            <IconPencil size={16} /> Edit
          </button>
          <button className="action-item" onClick={() => { onHistory(); setIsOpen(false); }}>
            <IconClock size={16} /> History
          </button>
          
          {card.card_status === 'suspended' && (
            <>
              <div className="action-divider" />
              <button className="action-item" style={{ color: '#166534' }} onClick={() => { onActivate(); setIsOpen(false); }}>
                <IconCheck size={16} /> Activate
              </button>
            </>
          )}

          {card.card_status === 'active' && (
            <>
              <div className="action-divider" />
              <button className="action-item danger" onClick={() => { onSuspend(); setIsOpen(false); }}>
                <IconLock size={16} /> Suspend
              </button>
              <button className="action-item" onClick={() => { onReplace(); setIsOpen(false); }}>
                <IconRefresh size={16} /> Replace
              </button>
            </>
          )}

          <div className="action-divider" />
          <div style={{ padding: '0.5rem 0.75rem', fontSize: '0.7rem', color: 'var(--text-secondary)', background: '#f8fafc', borderRadius: '0 0 8px 8px' }}>
            <div style={{ fontWeight: 600, marginBottom: '2px' }}>NFC UID</div>
            <div style={{ fontFamily: 'monospace' }}>{card.nfc_uid || 'Not Linked'}</div>
          </div>
        </div>
      )}
    </div>
  );
}

function PrivilegeCardsTab() {
  const [cards, setCards] = useState([]);
  const [loading, setLoading] = useState(true);
  const [showIssueModal, setShowIssueModal] = useState(false);
  const [editingCard, setEditingCard] = useState(null);
  const [historyCard, setHistoryCard] = useState(null);
  const [searchTerm, setSearchTerm] = useState('');
  const [statusFilter, setStatusFilter] = useState('all');

  const fetchCards = useCallback(async () => {
    setLoading(true);
    try {
      const data = await api.listPrivilegeCards();
      setCards(data || []);
    } catch (err) {
      console.error('Failed to load cards:', err);
    } finally {
      setLoading(false);
    }
  }, []);

  useEffect(() => { fetchCards(); }, [fetchCards]);

  const filteredCards = cards.filter(card => {
    const matchesSearch = 
      card.card_number.toLowerCase().includes(searchTerm.toLowerCase()) ||
      card.member_name.toLowerCase().includes(searchTerm.toLowerCase()) ||
      (card.member_email || '').toLowerCase().includes(searchTerm.toLowerCase());
    
    const matchesStatus = statusFilter === 'all' || card.card_status === statusFilter;
    
    return matchesSearch && matchesStatus;
  });

  const handleSuspend = async (id) => {
    if (!confirm('Suspend this card?')) return;
    try {
      await api.suspendPrivilegeCard(id);
      fetchCards();
    } catch (err) { alert(err.message); }
  };

  const handleReplace = async (id) => {
    if (!confirm('Replace this card? This conceptually charges a Rs. 1000 fee.')) return;
    try {
      await api.replacePrivilegeCard(id);
      fetchCards();
    } catch (err) { alert(err.message); }
  };

  const handleActivate = async (id) => {
    if (!confirm('Reactivate this card?')) return;
    try {
      await api.updatePrivilegeCard(id, { card_status: 'active', is_active: true });
      fetchCards();
    } catch (err) { alert(err.message); }
  };

  return (
    <Ds.Section
      title="Issued Cards"
      subtitle={`${filteredCards.length} of ${cards.length} cards`}
      flush
      actions={
        <>
          <Ds.Input
            placeholder="Search by card #, name or email…"
            value={searchTerm}
            onChange={e => setSearchTerm(e.target.value)}
            leftIcon={<IconSearch size={14} />}
            size="sm"
            style={{ width: 280 }}
          />
          <Ds.Select
            value={statusFilter}
            onChange={setStatusFilter}
            options={[
              { id: 'all', name: 'All statuses' },
              { id: 'active', name: 'Active' },
              { id: 'suspended', name: 'Suspended' },
              { id: 'replaced', name: 'Replaced' },
            ]}
            style={{ width: 160 }}
            size="sm"
          />
          <Ds.Button
            variant="primary"
            size="sm"
            leftIcon={<IconPlus size={14} />}
            onClick={() => setShowIssueModal(true)}
          >
            Issue card
          </Ds.Button>
        </>
      }
    >
      <Ds.Table>
        <thead>
          <tr>
            <th>Card #</th>
            <th>Member</th>
            <th>Status</th>
            <th>Physical</th>
            <th className="ds-table__actions" />
          </tr>
        </thead>
        <tbody>
          {loading ? (
            <Ds.Table.LoadingRow colSpan={5} label="Loading cards…" />
          ) : filteredCards.length === 0 ? (
            <Ds.Table.EmptyRow
              colSpan={5}
              icon={IconGift}
              title={searchTerm || statusFilter !== 'all' ? 'No matching cards' : 'No cards issued yet'}
              description={searchTerm || statusFilter !== 'all' ? 'Adjust filters to see more.' : 'Issue your first privilege card to get started.'}
            />
          ) : filteredCards.map(card => (
            <tr key={card.id}>
              <td className="ds-table__primary" style={{ fontFamily: 'ui-monospace, monospace' }}>
                {card.card_number}
              </td>
              <td>
                <div className="ds-table__primary">{card.member_name}</div>
                <div style={{ fontSize: 'var(--text-xs)', color: 'var(--fg-muted)' }}>{card.member_email}</div>
              </td>
              <td>
                <Ds.Badge
                  dot
                  variant={card.card_status === 'active' ? 'success' : card.card_status === 'suspended' ? 'warning' : 'danger'}
                >
                  {card.card_status}
                </Ds.Badge>
              </td>
              <td>
                {card.physical_issued ? (
                  <span style={{ display: 'inline-flex', alignItems: 'center', gap: 4, color: 'var(--success)', fontWeight: 'var(--weight-semibold)', fontSize: 'var(--text-sm)' }}>
                    <IconCheck size={14} /> Yes
                  </span>
                ) : (
                  <span style={{ display: 'inline-flex', alignItems: 'center', gap: 4, color: 'var(--fg-muted)', fontSize: 'var(--text-sm)' }}>
                    <IconX size={14} /> No
                  </span>
                )}
              </td>
              <td className="ds-table__actions">
                <CardActionMenu
                  card={card}
                  onEdit={() => setEditingCard(card)}
                  onHistory={() => setHistoryCard(card)}
                  onSuspend={() => handleSuspend(card.id)}
                  onReplace={() => handleReplace(card.id)}
                  onActivate={() => handleActivate(card.id)}
                />
              </td>
            </tr>
          ))}
        </tbody>
      </Ds.Table>

      {showIssueModal && <IssueCardModal onClose={() => setShowIssueModal(false)} onIssued={() => { setShowIssueModal(false); fetchCards(); }} />}
      {editingCard && <EditCardModal card={editingCard} onClose={() => setEditingCard(null)} onUpdated={() => { setEditingCard(null); fetchCards(); }} />}
      {historyCard && <CardHistoryModal card={historyCard} onClose={() => setHistoryCard(null)} />}
    </Ds.Section>
  );
}

function RewardsHubPage() {
  const [activeSubTab, setActiveSubTab] = useState('cards');

  return (
    <section className="ds-page">
      <Ds.PageHeader
        title="Rewards Hub"
        description="Manage privilege cards, partners, and exclusive member offers."
        actions={
          <Ds.ChipGroup
            value={activeSubTab}
            onChange={setActiveSubTab}
            options={[
              { value: 'cards', label: 'Privilege Cards' },
              { value: 'partners', label: 'Partners & Offers' },
            ]}
          />
        }
      />

      {activeSubTab === 'cards' ? <PrivilegeCardsTab /> : <PartnersTab />}
    </section>
  );
}

function PartnersTab() {
  const [partners, setPartners] = useState([]);
  const [loading, setLoading] = useState(true);
  const [showAddPartner, setShowAddPartner] = useState(false);
  const [editingPartner, setEditingPartner] = useState(null);
  const [addingOfferTo, setAddingOfferTo] = useState(null);

  const fetchPartners = useCallback(async () => {
    setLoading(true);
    try {
      const data = await api.listPartners(false);
      setPartners(data || []);
    } catch (err) {
      console.error('Failed to load partners:', err);
    } finally {
      setLoading(false);
    }
  }, []);

  useEffect(() => { fetchPartners(); }, [fetchPartners]);

  return (
    <div>
      <div className="ds-stat-grid">
        <Ds.StatCard
          label="Total partners"
          value={partners.length}
          icon={IconBuildingStore}
          iconColor="var(--brand-blue)"
          iconBg="var(--brand-blue-50)"
        />
        <Ds.StatCard
          label="Active offers"
          value={partners.reduce((acc, p) => acc + (p.offers?.length || 0), 0)}
          icon={IconGift}
          iconColor="var(--success)"
          iconBg="var(--success-bg)"
        />
        <Ds.StatCard
          label="Partner revenue"
          value="LKR 4.2M"
          icon={IconCoin}
          iconColor="var(--brand-amber-600)"
          iconBg="var(--brand-amber-50)"
        />
      </div>

      <Ds.Section
        title="Partner Directory"
        subtitle={`${partners.length} ${partners.length === 1 ? 'partner' : 'partners'}`}
        actions={
          <Ds.Button
            variant="primary"
            size="sm"
            leftIcon={<IconPlus size={14} />}
            onClick={() => setShowAddPartner(true)}
          >
            Add partner
          </Ds.Button>
        }
      >
        {loading ? (
          <Ds.LoadingRow label="Loading partners…" />
        ) : partners.length === 0 ? (
          <Ds.EmptyState
            icon={IconBuildingStore}
            title="No partners yet"
            description="Add your first partner to start offering member rewards."
          />
        ) : (
          <div style={{ display: 'flex', flexDirection: 'column', gap: 'var(--space-3)' }}>
            {partners.map(partner => (
              <div
                key={partner.id}
                style={{
                  display: 'flex',
                  alignItems: 'center',
                  gap: 'var(--space-4)',
                  padding: 'var(--space-4)',
                  border: '1px solid var(--border-subtle)',
                  borderRadius: 'var(--radius-lg)',
                  background: 'var(--bg-surface)',
                  transition: 'border-color var(--duration-fast) var(--ease-out)',
                }}
                onMouseEnter={e => e.currentTarget.style.borderColor = 'var(--border-default)'}
                onMouseLeave={e => e.currentTarget.style.borderColor = 'var(--border-subtle)'}
              >
                <div style={{
                  width: 56, height: 56,
                  borderRadius: 'var(--radius-md)',
                  background: 'var(--bg-subtle)',
                  overflow: 'hidden',
                  display: 'flex', alignItems: 'center', justifyContent: 'center',
                  flexShrink: 0,
                }}>
                  {partner.logo_url
                    ? <img src={partner.logo_url.startsWith('http') ? partner.logo_url : `${STATIC_BASE_URL}${partner.logo_url}`} alt="" style={{ width: '100%', height: '100%', objectFit: 'contain' }} />
                    : <IconBuildingStore size={22} color="var(--fg-muted)" />}
                </div>
                <div style={{ flex: 1, minWidth: 0 }}>
                  <h4 style={{ fontSize: 'var(--text-lg)', fontWeight: 'var(--weight-bold)', color: 'var(--fg-primary)' }}>
                    {partner.name}
                  </h4>
                  <p style={{ fontSize: 'var(--text-sm)', color: 'var(--fg-secondary)', marginTop: 2 }}>
                    {partner.offers?.length || 0} active reward{(partner.offers?.length || 0) === 1 ? '' : 's'}
                  </p>
                  {partner.website && (
                    <a
                      href={partner.website}
                      target="_blank"
                      rel="noreferrer"
                      style={{ fontSize: 'var(--text-xs)', color: 'var(--brand-blue)', textDecoration: 'none', marginTop: 2, display: 'inline-block' }}
                    >
                      {partner.website}
                    </a>
                  )}
                </div>
                <div style={{ display: 'flex', gap: 'var(--space-2)' }}>
                  <Ds.Button
                    variant="secondary"
                    size="sm"
                    leftIcon={<IconPlus size={14} />}
                    onClick={() => setAddingOfferTo(partner)}
                  >
                    Add reward
                  </Ds.Button>
                  <Ds.IconButton aria-label="Edit partner" onClick={() => setEditingPartner(partner)}>
                    <IconPencil size={16} />
                  </Ds.IconButton>
                </div>
              </div>
            ))}
          </div>
        )}
      </Ds.Section>

      {showAddPartner && (
        <CreatePartnerModal
          onClose={() => setShowAddPartner(false)}
          onCreated={() => { setShowAddPartner(false); fetchPartners(); }}
        />
      )}
      {editingPartner && (
        <EditPartnerModal
          partner={editingPartner}
          onClose={() => setEditingPartner(null)}
          onUpdated={() => { setEditingPartner(null); fetchPartners(); }}
        />
      )}
      {addingOfferTo && (
        <CreateOfferModal
          partner={addingOfferTo}
          onClose={() => setAddingOfferTo(null)}
          onCreated={() => { setAddingOfferTo(null); fetchPartners(); }}
        />
      )}
    </div>
  );
}


function ReferralActionMenu({ referral }) {
  const [isOpen, setIsOpen] = useState(false);
  const menuRef = useRef(null);

  useEffect(() => {
    const handleClickOutside = (e) => {
      if (menuRef.current && !menuRef.current.contains(e.target)) setIsOpen(false);
    };
    document.addEventListener('mousedown', handleClickOutside);
    return () => document.removeEventListener('mousedown', handleClickOutside);
  }, []);

  return (
    <div className="action-menu-container" ref={menuRef}>
      <button className="view-detail-btn" title="Actions" onClick={() => setIsOpen(!isOpen)}>
        <IconSettings size={20} />
      </button>
      
      {isOpen && (
        <div className="action-dropdown" style={{ right: 0, left: 'auto' }}>
          <div style={{ padding: '0.5rem 1rem', fontSize: '0.75rem', color: '#94a3b8', fontStyle: 'italic' }}>
            No actions available
          </div>
        </div>
      )}
    </div>
  );
}

// ── Referrals Page ────────────────────────────────────────────────────────
function ReferralsPage() {
  const [referrals, setReferrals] = useState([]);
  const [loading, setLoading] = useState(true);
  const [total, setTotal] = useState(0);
  const [pages, setPages] = useState(0);
  const [page, setPage] = useState(1);
  const [search, setSearch] = useState('');
  const [statusFilter, setStatusFilter] = useState('');

  const fetchReferrals = useCallback(async () => {
    setLoading(true);
    try {
      const result = await api.listAllReferrals({ 
        page, 
        limit: 15,
        search,
        status: statusFilter
      });
      // Handle both old array response and new paginated object response
      if (result.referrals) {
        setReferrals(result.referrals);
        setTotal(result.total);
        setPages(Math.ceil(result.total / (result.page_size || 15)));
      } else {
        setReferrals(result || []);
        setTotal(result?.length || 0);
        setPages(1);
      }
    } catch (err) {
      console.error('Failed to load referrals:', err);
    } finally {
      setLoading(false);
    }
  }, [page, search, statusFilter]);
  
  useEffect(() => { fetchReferrals(); }, [fetchReferrals]);
  
  const statusOptions = [
    { id: 'submitted', name: 'Submitted' },
    { id: 'contacted', name: 'Contacted' },
    { id: 'negotiation', name: 'Negotiation' },
    { id: 'in_progress', name: 'In Progress' },
    { id: 'success', name: 'Closed Won' },
    { id: 'closed_lost', name: 'Closed Lost' },
  ];

  return (
    <section className="ds-page">
      <Ds.PageHeader
        title="Referral Pipeline"
        description="Monitor business exchanges and conversion velocity across the network."
        actions={
          <Ds.Button
            variant="secondary"
            leftIcon={<IconRefresh size={14} />}
            onClick={() => { setPage(1); fetchReferrals(); }}
          >
            Refresh
          </Ds.Button>
        }
      />

      <Ds.Section
        title="Global Referral Stream"
        subtitle={total > 0 ? `${total.toLocaleString()} referrals tracked` : undefined}
        flush
      >
        <div style={{ display: 'flex', gap: 'var(--space-3)', flexWrap: 'wrap', padding: 'var(--space-5) var(--space-6)', borderBottom: '1px solid var(--border-subtle)' }}>
          <Ds.Input
            placeholder="Search lead, description or member…"
            value={search}
            onChange={e => { setSearch(e.target.value); setPage(1); }}
            leftIcon={<IconSearch size={14} />}
            style={{ flex: 1, minWidth: 280 }}
          />
          <Ds.Select
            placeholder="All statuses"
            value={statusFilter}
            options={statusOptions}
            allowClear
            onChange={val => { setStatusFilter(val); setPage(1); }}
            style={{ width: 220 }}
          />
        </div>

        <Ds.Table>
          <thead>
            <tr>
              <th>ID</th>
              <th>From</th>
              <th>To</th>
              <th>Lead</th>
              <th>Value</th>
              <th>Status</th>
              <th>Date</th>
              <th className="ds-table__actions" />
            </tr>
          </thead>
          <tbody>
            {loading ? (
              <Ds.Table.LoadingRow colSpan={8} label="Loading referrals…" />
            ) : !referrals || referrals.length === 0 ? (
              <Ds.Table.EmptyRow
                colSpan={8}
                icon={IconHierarchy2}
                title="No referrals found"
                description="Adjust filters or search terms to see results."
              />
            ) : referrals.map((ref, idx) => (
              <tr key={ref.id || idx}>
                <td>
                  <span style={{ color: 'var(--brand-blue)', fontWeight: 'var(--weight-bold)', fontSize: 'var(--text-sm)' }}>
                    REF-{String(ref.id || idx).slice(0, 4)}
                  </span>
                </td>
                <td className="ds-table__primary">{ref.from_user?.full_name || '—'}</td>
                <td className="ds-table__muted">{ref.target_user?.full_name || '—'}</td>
                <td className="ds-table__primary">{ref.lead_name || '—'}</td>
                <td className="ds-table__primary" style={{ fontWeight: 'var(--weight-bold)' }}>
                  {ref.actual_value ? `LKR ${ref.actual_value.toLocaleString()}` : '—'}
                </td>
                <td>
                  <Ds.Badge dot variant={referralStatusVariant(ref.status === 'success' ? 'closed_won' : ref.status)}>
                    {referralStatusLabel(ref.status)}
                  </Ds.Badge>
                </td>
                <td className="ds-table__muted">{new Date(ref.created_at).toLocaleDateString()}</td>
                <td className="ds-table__actions">
                  <ReferralActionMenu referral={ref} />
                </td>
              </tr>
            ))}
          </tbody>
        </Ds.Table>

        <Ds.Pagination
          page={page}
          totalPages={pages}
          total={total}
          pageLabel="referrals"
          onPageChange={setPage}
        />
      </Ds.Section>
    </section>
  );
}

function EditFeeModal({ fee, onClose, onUpdate }) {
  const [annual, setAnnual] = useState(fee.annual_fee);
  const [forum, setForum] = useState(fee.per_forum_fee);
  const [loading, setLoading] = useState(false);
  const [error, setError] = useState('');

  const handleSubmit = async (e) => {
    e.preventDefault();
    setLoading(true);
    try {
      await api.updateFee(fee.membership_type, { annual_fee: annual, per_forum_fee: forum });
      onUpdate();
      onClose();
    } catch (err) {
      setError(err.message);
    } finally {
      setLoading(false);
    }
  };

  return (
    <div className="modal-overlay" onClick={(e) => e.target === e.currentTarget && onClose()}>
      <div className="modal-content" onClick={e => e.stopPropagation()} style={{ maxWidth: 400 }}>
        <div className="modal-header">
          <h2 style={{ fontSize: '1.25rem', fontWeight: 800 }}>Edit {fee.membership_type.replace('_', ' ').toUpperCase()} Rate</h2>
          <button type="button" className="modal-close-btn" onClick={onClose}>
            <IconX size={20} />
          </button>
        </div>
        <form onSubmit={handleSubmit} style={{ padding: '1.5rem' }}>
          {error && <div className="login-error" style={{ marginBottom: '1rem' }}>{error}</div>}
          <div className="login-field">
            <label>Annual Fee (LKR)</label>
            <input type="number" value={annual} onChange={e => setAnnual(e.target.value)} className="filter-input v2" required />
          </div>
          <div className="login-field">
            <label>Per Forum Fee (LKR)</label>
            <input type="number" value={forum} onChange={e => setForum(e.target.value)} className="filter-input v2" required />
          </div>
          <button type="submit" className="login-btn" disabled={loading}>
            {loading ? 'Saving...' : 'Update Master Rate'}
          </button>
        </form>
      </div>
    </div>
  );
}

// ── Revenue Page ──────────────────────────────────────────────────────────
function RevenuePage({ onNavigateToGovernance }) {
  const { data: overview } = useApi(api.getAdminOverview, []);
  const { data: payments, loading: paymentsLoading } = useApi(api.listPayments, []);

  const recent = (Array.isArray(payments) ? payments : payments?.data || []).slice(0, 10);

  return (
    <section className="ds-page">
      <Ds.PageHeader
        title="Revenue & ROI"
        description="Financial health and network growth metrics."
        actions={
          <Ds.Button
            variant="secondary"
            leftIcon={<IconSettings size={14} />}
            onClick={onNavigateToGovernance}
          >
            Manage fee schedules
          </Ds.Button>
        }
      />

      <div className="ds-stat-grid">
        <Ds.StatCard
          label="Total revenue"
          value={formatCurrency(overview?.total_value)}
          icon={IconCoin}
          iconColor="var(--success)"
          iconBg="var(--success-bg)"
        />
        <Ds.StatCard
          label="Pending payments"
          value={payments?.filter(p => p.status === 'pending').length || 0}
          icon={IconClock}
          iconColor="var(--warning)"
          iconBg="var(--warning-bg)"
        />
        <Ds.StatCard
          label="Avg conversion"
          value={overview?.conversion_rate ? `${overview.conversion_rate}%` : '—'}
          icon={IconChartBar}
          iconColor="var(--brand-blue)"
          iconBg="var(--brand-blue-50)"
        />
      </div>

      <Ds.Section title="Recent Financial Activity" flush>
        <Ds.Table>
          <thead>
            <tr>
              <th>Date</th>
              <th>Member</th>
              <th>Type</th>
              <th>Amount</th>
              <th>Status</th>
            </tr>
          </thead>
          <tbody>
            {paymentsLoading ? (
              <Ds.Table.LoadingRow colSpan={5} label="Loading payments…" />
            ) : recent.length === 0 ? (
              <Ds.Table.EmptyRow
                colSpan={5}
                icon={IconCoin}
                title="No financial activity yet"
              />
            ) : recent.map(p => (
              <tr key={p.id}>
                <td className="ds-table__muted">{new Date(p.created_at).toLocaleDateString()}</td>
                <td className="ds-table__primary">{p.user_name}</td>
                <td><Ds.Badge variant="neutral">{p.payment_type}</Ds.Badge></td>
                <td className="ds-table__primary" style={{ fontWeight: 'var(--weight-bold)' }}>
                  {formatCurrency(p.amount)}
                </td>
                <td>
                  <Ds.Badge dot variant={p.status === 'completed' ? 'success' : p.status === 'failed' ? 'danger' : 'warning'}>
                    {p.status}
                  </Ds.Badge>
                </td>
              </tr>
            ))}
          </tbody>
        </Ds.Table>
      </Ds.Section>
    </section>
  );
}

function GovernancePage({ onBack }) {
  const [fees, setFees] = useState([]);
  const [editingFee, setEditingFee] = useState(null);
  const [loading, setLoading] = useState(true);

  const fetchFees = useCallback(async () => {
    setLoading(true);
    try {
      const data = await api.listFees();
      setFees(data || []);
    } catch (err) { console.error(err); }
    finally { setLoading(false); }
  }, []);

  useEffect(() => { fetchFees(); }, [fetchFees]);

  return (
    <section className="ds-page">
      <div style={{ marginBottom: 'var(--space-3)' }}>
        <Ds.Button variant="ghost" size="sm" leftIcon={<IconChevronLeft size={14} />} onClick={onBack}>
          Back to Revenue
        </Ds.Button>
      </div>
      <Ds.PageHeader
        title="Fee Governance"
        description="Official master rates as per Bylaws Article 8."
      />

      <Ds.Section
        title="Master Rate Schedules"
        subtitle={`${fees.length} membership tiers configured`}
      >
        {loading ? (
          <div className="ds-loading-row"><Ds.Spinner size="lg" /> Loading governance data…</div>
        ) : fees.length === 0 ? (
          <Ds.EmptyState icon={IconCoin} title="No fee schedules configured" />
        ) : (
          <div style={{ display: 'grid', gridTemplateColumns: 'repeat(auto-fill, minmax(280px, 1fr))', gap: 'var(--space-4)' }}>
            {fees.map(f => (
              <Ds.Card key={f.membership_type} padded>
                <div style={{ display: 'flex', justifyContent: 'space-between', alignItems: 'flex-start', marginBottom: 'var(--space-4)' }}>
                  <Ds.Badge variant="brand">{f.membership_type.toUpperCase()}</Ds.Badge>
                  <Ds.IconButton aria-label="Edit fee" onClick={() => setEditingFee(f)}>
                    <IconPencil size={16} />
                  </Ds.IconButton>
                </div>
                <div style={{ display: 'flex', flexDirection: 'column', gap: 'var(--space-3)' }}>
                  <div style={{ background: 'var(--bg-subtle)', padding: 'var(--space-4)', borderRadius: 'var(--radius-md)' }}>
                    <span style={{ fontSize: 'var(--text-xs)', color: 'var(--fg-muted)', fontWeight: 'var(--weight-semibold)', textTransform: 'uppercase', letterSpacing: 'var(--tracking-wide)' }}>
                      Annual Membership
                    </span>
                    <div style={{ fontSize: 'var(--text-2xl)', fontWeight: 'var(--weight-bold)', color: 'var(--brand-navy)', marginTop: 'var(--space-1)', letterSpacing: 'var(--tracking-tight)' }}>
                      {formatCurrency(f.annual_fee)}
                    </div>
                  </div>
                  <div style={{ background: 'var(--bg-subtle)', padding: 'var(--space-4)', borderRadius: 'var(--radius-md)' }}>
                    <span style={{ fontSize: 'var(--text-xs)', color: 'var(--fg-muted)', fontWeight: 'var(--weight-semibold)', textTransform: 'uppercase', letterSpacing: 'var(--tracking-wide)' }}>
                      Per Forum Meeting
                    </span>
                    <div style={{ fontSize: 'var(--text-xl)', fontWeight: 'var(--weight-bold)', color: 'var(--fg-primary)', marginTop: 'var(--space-1)' }}>
                      {formatCurrency(f.per_forum_fee)}
                    </div>
                  </div>
                </div>
              </Ds.Card>
            ))}
          </div>
        )}
      </Ds.Section>

      {editingFee && (
        <EditFeeModal
          fee={editingFee}
          onClose={() => setEditingFee(null)}
          onUpdate={fetchFees}
        />
      )}
    </section>
  );
}

// ── Toast System ───────────────────────────────────────────────────────────
const useToast = () => {
  const [toasts, setToasts] = useState([]);

  const showToast = useCallback((message, type = 'success') => {
    const id = Date.now();
    setToasts(prev => [...prev, { id, message, type }]);
    setTimeout(() => {
      setToasts(prev => prev.filter(t => t.id !== id));
    }, 4000);
  }, []);

  return { toasts, showToast };
};

const ToastContainer = ({ toasts }) => {
  const getColor = (type) => {
    switch(type) {
      case 'error': return '#ef4444';
      case 'warning': return '#f59e0b';
      default: return '#059669';
    }
  };

  return (
    <div className="toast-container">
      {toasts.map(t => (
        <div key={t.id} className="toast" style={{ '--toast-color': getColor(t.type) }}>
          {t.type === 'error' ? <IconAlertCircle color={getColor(t.type)} size={20} /> : <IconCheck color={getColor(t.type)} size={20} />}
          <span style={{ fontWeight: 600, fontSize: '0.875rem' }}>{t.message}</span>
        </div>
      ))}
    </div>
  );
};

// ── Change Password Modal ───────────────────────────────────────────────────
function ChangePasswordModal({ onClose, showToast }) {
  const [formData, setFormData] = useState({ current_password: '', new_password: '', confirm_password: '' });
  const [loading, setLoading] = useState(false);
  const [error, setError] = useState('');

  const handleSubmit = async (e) => {
    e.preventDefault();
    if (formData.new_password !== formData.confirm_password) {
      setError('Passwords do not match');
      return;
    }
    setLoading(true);
    setError('');
    try {
      await api.changePassword(formData);
      showToast('Password changed successfully');
      onClose();
    } catch (err) {
      setError(err.message || 'Failed to change password');
    } finally {
      setLoading(false);
    }
  };

  return (
    <div className="modal-overlay" onClick={(e) => e.target === e.currentTarget && onClose()}>
      <div className="modal-content" onClick={e => e.stopPropagation()} style={{ maxWidth: 400 }}>
        <div className="modal-header">
          <h2 style={{ fontSize: '1.25rem', fontWeight: 800 }}>Change Password</h2>
          <button type="button" className="modal-close-btn" onClick={onClose}>
            <IconX size={20} />
          </button>
        </div>
        <form onSubmit={handleSubmit} style={{ padding: '1.5rem' }}>
          {error && <div className="login-error" style={{ marginBottom: '1rem' }}>{error}</div>}
          <div className="login-field">
            <label>Current Password</label>
            <div className="login-input-wrap">
               <IconLock size={18} className="login-input-icon" />
               <input type="password" value={formData.current_password} onChange={e => setFormData({...formData, current_password: e.target.value})} required placeholder="••••••••" style={{ paddingLeft: '2.75rem' }} />
            </div>
          </div>
          <div className="login-field">
            <label>New Password</label>
             <div className="login-input-wrap">
               <IconLock size={18} className="login-input-icon" />
               <input type="password" value={formData.new_password} onChange={e => setFormData({...formData, new_password: e.target.value})} required placeholder="••••••••" style={{ paddingLeft: '2.75rem' }} />
            </div>
          </div>
          <div className="login-field">
            <label>Confirm New Password</label>
             <div className="login-input-wrap">
               <IconLock size={18} className="login-input-icon" />
               <input type="password" value={formData.confirm_password} onChange={e => setFormData({...formData, confirm_password: e.target.value})} required placeholder="••••••••" style={{ paddingLeft: '2.75rem' }} />
            </div>
          </div>
          <button type="submit" className="login-btn" disabled={loading}>
            {loading ? 'Changing...' : 'Update Password'}
          </button>
        </form>
      </div>
    </div>
  );
}

// ── Notification Panel ───────────────────────────────────────────────────────
const getNotificationIcon = (type) => {
  switch (type) {
    case 'NEW_APPLICATION': return { icon: IconClipboardList, color: '#2563eb' };
    case 'APPLICATION_APPROVED': return { icon: IconUserCheck, color: '#059669' };
    case 'PAYMENT_RECEIVED': return { icon: IconCoin, color: '#059669' };
    case 'MEETING_REMINDER': return { icon: IconClock, color: '#f59e0b' };
    case 'SYSTEM_ALERT': return { icon: IconAlertCircle, color: '#ef4444' };
    default: return { icon: IconBell, color: '#64748b' };
  }
};

function NotificationPanel({ notifications, onDismiss, onMarkAllRead, onClose }) {
  return (
    <div className="notifications-panel" onClick={e => e.stopPropagation()}>
      <div className="notifications-header">
        <h3 style={{ fontSize: '1rem', fontWeight: 800 }}>Notifications</h3>
        <button 
          onClick={onMarkAllRead}
          style={{ background: 'none', border: 'none', color: 'var(--secondary)', fontSize: '0.75rem', fontWeight: 700, cursor: 'pointer' }}
        >
          Mark all as read
        </button>
      </div>
      <div className="notifications-list">
        {notifications.length === 0 ? (
          <div style={{ padding: '3rem', textAlign: 'center', color: '#94a3b8' }}>
            <IconBell size={32} stroke={1.5} style={{ marginBottom: '0.75rem', opacity: 0.5 }} />
            <p style={{ fontSize: '0.875rem', fontWeight: 600 }}>All caught up!</p>
          </div>
        ) : notifications.map(n => {
          const { icon: NotifIcon, color: iconColor } = getNotificationIcon(n.notification_type);
          return (
            <div key={n.id} className={`notification-item ${!n.is_read ? 'unread' : ''}`} onClick={() => onDismiss(n.id)}>
              <div className="notif-icon-wrap" style={{ background: iconColor + '15', color: iconColor }}>
                <NotifIcon size={20} />
              </div>
              <div className="notif-content">
                <div className="notif-title">{n.title}</div>
                <div className="notif-desc">{n.body}</div>
                <div className="notif-time">{n.sent_at ? new Date(n.sent_at).toLocaleTimeString([], { hour: '2-digit', minute: '2-digit' }) : ''}</div>
              </div>
            </div>
          );
        })}
      </div>
    </div>
  );
}

// ── Settings Page ─────────────────────────────────────────────────────────
function MailboxSettingsSection({ showToast }) {
  const [settings, setSettings] = useState(null);
  const [loading, setLoading] = useState(true);
  const [saving, setSaving] = useState(false);
  const [form, setForm] = useState({
    smtp_host: '',
    smtp_port: '',
    smtp_user: '',
    smtp_password: '',
    smtp_from_name: '',
    smtp_from_email: '',
  });

  useEffect(() => {
    api.getMailboxSettings()
      .then(data => {
        setSettings(data);
        setForm({
          smtp_host: data.smtp_host || '',
          smtp_port: String(data.smtp_port || '465'),
          smtp_user: data.smtp_user || '',
          smtp_password: '',
          smtp_from_name: data.smtp_from_name || '',
          smtp_from_email: data.smtp_from_email || '',
        });
      })
      .catch(() => {})
      .finally(() => setLoading(false));
  }, []);

  const handleSave = async (e) => {
    e.preventDefault();
    setSaving(true);
    try {
      const payload = {
        smtp_host: form.smtp_host || undefined,
        smtp_port: form.smtp_port ? parseInt(form.smtp_port, 10) : undefined,
        smtp_user: form.smtp_user || undefined,
        smtp_from_name: form.smtp_from_name || undefined,
        smtp_from_email: form.smtp_from_email || undefined,
      };
      if (form.smtp_password) payload.smtp_password = form.smtp_password;
      await api.updateMailboxSettings(payload);
      showToast('Mailbox settings saved. Restart the API service to apply.', 'success');
      setForm(f => ({ ...f, smtp_password: '' }));
    } catch (err) {
      showToast(err.message || 'Failed to save settings', 'error');
    } finally {
      setSaving(false);
    }
  };

  if (loading) return (
    <Ds.Section title="Mailbox Settings" subtitle="SMTP / IMAP configuration for info@primebusiness.network">
      <div style={{ display: 'flex', justifyContent: 'center', padding: 'var(--space-6)' }}><Ds.Spinner size="md" /></div>
    </Ds.Section>
  );

  return (
    <Ds.Section
      title="Mailbox Settings"
      subtitle="SMTP / IMAP configuration for the admin mailbox"
    >
      <form onSubmit={handleSave} style={{ display: 'flex', flexDirection: 'column', gap: 'var(--space-3)' }}>
        <div style={{ display: 'grid', gridTemplateColumns: '1fr auto', gap: 'var(--space-2)', alignItems: 'end' }}>
          <div>
            <label style={{ fontSize: '0.75rem', fontWeight: 700, color: 'var(--text-secondary)', textTransform: 'uppercase', letterSpacing: '0.05em', display: 'block', marginBottom: '0.5rem' }}>Mail Server Host</label>
            <Ds.Input
              value={form.smtp_host}
              onChange={e => setForm(f => ({ ...f, smtp_host: e.target.value }))}
              placeholder="mail.example.com"
            />
          </div>
          <div>
            <label style={{ fontSize: '0.75rem', fontWeight: 700, color: 'var(--text-secondary)', textTransform: 'uppercase', letterSpacing: '0.05em', display: 'block', marginBottom: '0.5rem' }}>SMTP Port</label>
            <Ds.Input
              value={form.smtp_port}
              onChange={e => setForm(f => ({ ...f, smtp_port: e.target.value }))}
              placeholder="465"
              style={{ width: '90px' }}
            />
          </div>
        </div>

        <div>
          <label style={{ fontSize: '0.75rem', fontWeight: 700, color: 'var(--text-secondary)', textTransform: 'uppercase', letterSpacing: '0.05em', display: 'block', marginBottom: '0.5rem' }}>Mailbox Email (SMTP User)</label>
          <Ds.Input
            type="email"
            value={form.smtp_user}
            onChange={e => setForm(f => ({ ...f, smtp_user: e.target.value }))}
            placeholder="info@example.com"
          />
        </div>

        <div>
          <label style={{ fontSize: '0.75rem', fontWeight: 700, color: 'var(--text-secondary)', textTransform: 'uppercase', letterSpacing: '0.05em', display: 'block', marginBottom: '0.5rem' }}>
            Password {settings?.has_password ? <span style={{ color: 'var(--success)', fontSize: '0.65rem', fontWeight: 600, marginLeft: 4 }}>● Saved</span> : <span style={{ color: 'var(--danger)', fontSize: '0.65rem', marginLeft: 4 }}>● Not set</span>}
          </label>
          <Ds.Input
            type="password"
            value={form.smtp_password}
            onChange={e => setForm(f => ({ ...f, smtp_password: e.target.value }))}
            placeholder="Leave blank to keep existing password"
          />
        </div>

        <div style={{ display: 'grid', gridTemplateColumns: '1fr 1fr', gap: 'var(--space-2)' }}>
          <div>
            <label style={{ fontSize: '0.75rem', fontWeight: 700, color: 'var(--text-secondary)', textTransform: 'uppercase', letterSpacing: '0.05em', display: 'block', marginBottom: '0.5rem' }}>From Name</label>
            <Ds.Input
              value={form.smtp_from_name}
              onChange={e => setForm(f => ({ ...f, smtp_from_name: e.target.value }))}
              placeholder="Prime Business Network"
            />
          </div>
          <div>
            <label style={{ fontSize: '0.75rem', fontWeight: 700, color: 'var(--text-secondary)', textTransform: 'uppercase', letterSpacing: '0.05em', display: 'block', marginBottom: '0.5rem' }}>From Email</label>
            <Ds.Input
              type="email"
              value={form.smtp_from_email}
              onChange={e => setForm(f => ({ ...f, smtp_from_email: e.target.value }))}
              placeholder="info@example.com"
            />
          </div>
        </div>

        <div style={{ marginTop: 'var(--space-2)', padding: 'var(--space-3)', background: 'var(--bg-subtle)', borderRadius: 'var(--radius-md)', fontSize: 'var(--text-xs)', color: 'var(--fg-muted)' }}>
          <strong>Note:</strong> IMAP (port 993) uses the same host and credentials as SMTP above. After saving, the API service must be restarted for changes to take effect.
        </div>

        <Ds.Button type="submit" variant="primary" loading={saving} leftIcon={<IconMail size={14} />}>
          Save Mailbox Settings
        </Ds.Button>
      </form>
    </Ds.Section>
  );
}

function SettingsPage({ adminUser, onShowChangePassword, showToast }) {
  const [notifPreferences, setNotifPreferences] = useState({
    applications: true,
    payments: true,
    reminders: true,
    security: false
  });

  const toggleNotif = (key) => {
    setNotifPreferences(prev => ({ ...prev, [key]: !prev[key] }));
    showToast(`Preference updated for ${key}`);
  };

  const notifRows = [
    { key: 'applications', title: 'New Applications', desc: 'Notify when a potential member submits an application' },
    { key: 'payments', title: 'Payment Alerts', desc: 'Real-time updates on membership and renewal fees' },
    { key: 'reminders', title: 'Meeting Reminders', desc: 'Automated nudges for upcoming chapter fit-calls' },
  ];

  return (
    <section className="ds-page">
      <Ds.PageHeader
        title="Settings"
        description="Manage your administrative profile and platform preferences."
      />

      <div style={{ display: 'grid', gridTemplateColumns: 'repeat(auto-fit, minmax(360px, 1fr))', gap: 'var(--space-5)' }}>
        <Ds.Section
          title="My Profile"
          subtitle="Personal account details"
        >
          <div style={{ display: 'flex', flexDirection: 'column', alignItems: 'center', gap: 'var(--space-3)', padding: 'var(--space-4) 0', textAlign: 'center' }}>
            <Ds.Avatar size="lg" name={adminUser?.full_name || 'AD'} variant="brand" ring />
            <div>
              <h4 style={{ fontSize: 'var(--text-lg)', fontWeight: 'var(--weight-bold)', color: 'var(--fg-primary)' }}>
                {adminUser?.full_name}
              </h4>
              <p style={{ color: 'var(--fg-secondary)', fontSize: 'var(--text-sm)', marginTop: 4 }}>
                {adminUser?.role} • {adminUser?.email}
              </p>
            </div>
          </div>
          <div style={{ display: 'flex', flexDirection: 'column', gap: 'var(--space-2)', marginTop: 'var(--space-4)' }}>
            <Ds.Button
              variant="primary"
              block
              leftIcon={<IconLock size={14} />}
              onClick={onShowChangePassword}
            >
              Change account password
            </Ds.Button>
            <Ds.Button
              variant="secondary"
              block
              leftIcon={<IconMail size={14} />}
            >
              Update contact email
            </Ds.Button>
          </div>
        </Ds.Section>

        <Ds.Section
          title="Notifications"
          subtitle="Choose what you'd like to be notified about"
        >
          <div style={{ display: 'flex', flexDirection: 'column', gap: 'var(--space-2)' }}>
            {notifRows.map(row => (
              <div
                key={row.key}
                className="ds-checkbox-row"
                onClick={() => toggleNotif(row.key)}
              >
                <div className="ds-checkbox-row__meta">
                  <div className="ds-checkbox-row__title">{row.title}</div>
                  <div className="ds-checkbox-row__desc">{row.desc}</div>
                </div>
                <input
                  type="checkbox"
                  className="ds-checkbox"
                  checked={notifPreferences[row.key]}
                  onChange={() => toggleNotif(row.key)}
                  onClick={e => e.stopPropagation()}
                />
              </div>
            ))}
          </div>
        </Ds.Section>

        {/* Mailbox Settings – SUPER_ADMIN only */}
        {adminUser?.role === 'SUPER_ADMIN' && (
          <MailboxSettingsSection showToast={showToast} />
        )}
      </div>
    </section>
  );
}


// ── Mailbox Viewer Page ───────────────────────────────────────────────────
// ── Mailbox helpers ───────────────────────────────────────────────────────
const MAILBOX_AVATAR_COLORS = [
  '#2563EB', '#7C3AED', '#DB2777', '#EA580C',
  '#059669', '#0891B2', '#4F46E5', '#CA8A04',
];

// Split a raw "From" header into a display name and bare email address.
function parseSender(raw = '') {
  const match = raw.match(/^\s*"?([^"<]*?)"?\s*<([^>]+)>\s*$/);
  if (match) {
    const email = match[2].trim();
    return { name: match[1].trim() || email, email };
  }
  const trimmed = raw.trim();
  return { name: trimmed || '(Unknown sender)', email: trimmed.includes('@') ? trimmed : '' };
}

function senderInitials(value = '') {
  const parts = value.replace(/[<>"@.]/g, ' ').trim().split(/\s+/).filter(Boolean);
  if (parts.length === 0) return '?';
  if (parts.length === 1) return parts[0].slice(0, 2).toUpperCase();
  return (parts[0][0] + parts[parts.length - 1][0]).toUpperCase();
}

function avatarColor(key = '') {
  let hash = 0;
  for (let i = 0; i < key.length; i++) hash = (hash * 31 + key.charCodeAt(i)) >>> 0;
  return MAILBOX_AVATAR_COLORS[hash % MAILBOX_AVATAR_COLORS.length];
}

// Human-friendly relative timestamp ("3m ago", "2h ago", "Yesterday", "Mar 4").
function formatMailDate(dateStr) {
  if (!dateStr) return '';
  const d = new Date(dateStr);
  if (isNaN(d.getTime())) return '';
  const now = new Date();
  const diffMin = Math.floor((now - d) / 60000);
  if (diffMin < 1) return 'Just now';
  if (diffMin < 60) return `${diffMin}m ago`;
  if (d.toDateString() === now.toDateString()) return `${Math.floor(diffMin / 60)}h ago`;
  const yesterday = new Date(now);
  yesterday.setDate(now.getDate() - 1);
  if (d.toDateString() === yesterday.toDateString()) return 'Yesterday';
  const sameYear = d.getFullYear() === now.getFullYear();
  return d.toLocaleDateString(undefined, sameYear
    ? { month: 'short', day: 'numeric' }
    : { month: 'short', day: 'numeric', year: 'numeric' });
}

import { md5 } from './lib/md5.js';

function MailAvatar({ name, email, size = 40 }) {
  const cleanEmail = (email || '').trim().toLowerCase();
  
  let actualEmail = cleanEmail;
  const match = cleanEmail.match(/<([^>]+)>/);
  if (match) {
    actualEmail = match[1].trim();
  }

  const hash = actualEmail ? md5(actualEmail) : '';
  const gravatarUrl = hash ? `https://www.gravatar.com/avatar/${hash}?d=blank&s=${size * 2}` : '';

  return (
    <div style={{
      width: size, height: size, minWidth: size, borderRadius: '50%',
      background: avatarColor(actualEmail || name || ''), color: '#fff',
      display: 'flex', alignItems: 'center', justifyContent: 'center',
      fontWeight: 'var(--weight-bold)', letterSpacing: '0.5px',
      fontSize: size <= 36 ? 'var(--text-xs)' : 'var(--text-sm)',
      boxShadow: 'inset 0 0 0 1px rgba(255,255,255,0.15)',
      position: 'relative',
      overflow: 'hidden'
    }}>
      {senderInitials(name || actualEmail)}
      {gravatarUrl && (
        <img
          src={gravatarUrl}
          alt={name || actualEmail}
          style={{
            position: 'absolute', top: 0, left: 0,
            width: '100%', height: '100%',
            objectFit: 'cover',
          }}
        />
      )}
    </div>
  );
}

// Clean up Outlook mailto: links from body text
function cleanMailBody(text) {
  if (!text) return '';
  // Remove mailto: links like <mailto:email@address.com> that follow email addresses
  let cleaned = text.replace(/<mailto:[^>]+>/gi, '');
  return cleaned;
}

// Parses raw plain text email threads into separate message objects
function parseEmailThread(body, topSender, topDate) {
  if (!body) return [];

  const lines = body.split(/\r?\n/);
  const messages = [];
  let currentBodyLines = [];

  // Initialize with the top-level message details
  const newestMessage = {
    from: topSender || '',
    date: topDate || '',
    to: '',
    subject: '',
    body: '',
    caution: '',
    isCollapsed: false,
    isFirst: true,
  };
  messages.push(newestMessage);

  let i = 0;
  while (i < lines.length) {
    const line = lines[i];

    // Check if this line starts a header block of an older reply.
    // Standard header blocks start with "From: " (sometimes with "Original Message" prefix)
    const fromMatch = line.match(/^(?:-----Original Message-----|----- Original Message -----)?\s*From:\s*(.+)$/i);
    let isHeaderBlock = false;
    let headersTemp = {};

    if (fromMatch) {
      // Look ahead up to 6 lines to parse the accompanying header fields
      const lookAheadLimit = Math.min(lines.length, i + 6);
      let foundDateOrSent = false;
      let foundTo = false;
      const tempFields = { from: fromMatch[1].trim() };

      for (let j = i + 1; j < lookAheadLimit; j++) {
        const nextLine = lines[j];
        const dateMatch = nextLine.match(/^(?:Sent|Date):\s*(.+)$/i);
        const toMatch = nextLine.match(/^To:\s*(.+)$/i);
        const subjectMatch = nextLine.match(/^Subject:\s*(.+)$/i);
        const ccMatch = nextLine.match(/^Cc:\s*(.+)$/i);

        if (dateMatch) {
          foundDateOrSent = true;
          tempFields.date = dateMatch[1].trim();
        } else if (toMatch) {
          foundTo = true;
          tempFields.to = toMatch[1].trim();
        } else if (subjectMatch) {
          tempFields.subject = subjectMatch[1].trim();
        } else if (ccMatch) {
          tempFields.cc = ccMatch[1].trim();
        }
      }

      if (foundDateOrSent || foundTo) {
        isHeaderBlock = true;
        headersTemp = tempFields;
        
        // Count how many header lines to skip
        let linesToSkip = 1;
        for (let j = i + 1; j < lookAheadLimit; j++) {
          const nextLine = lines[j];
          if (/^(?:Sent|Date|To|Subject|Cc):\s*/i.test(nextLine)) {
            linesToSkip = j - i + 1;
          } else if (nextLine.trim() === '') {
            continue;
          } else {
            break;
          }
        }
        i += linesToSkip - 1;
      }
    }

    if (isHeaderBlock) {
      // Commit the text parsed so far to the previous message
      if (messages.length > 0) {
        messages[messages.length - 1].body = currentBodyLines.join('\n').trim();
      }
      currentBodyLines = [];

      messages.push({
        from: headersTemp.from || '',
        date: headersTemp.date || '',
        to: headersTemp.to || '',
        subject: headersTemp.subject || '',
        cc: headersTemp.cc || '',
        body: '',
        caution: '',
        isCollapsed: true,
        isFirst: false,
      });
    } else {
      currentBodyLines.push(line);
    }
    i++;
  }

  // Commit any remaining lines to the last message
  if (messages.length > 0) {
    messages[messages.length - 1].body = currentBodyLines.join('\n').trim();
  }

  // Clean caution warning block out of each message body
  const cautionRegex = /\[CAUTION:[\s\S]+?\]/i;
  messages.forEach(msg => {
    const cautionMatch = msg.body.match(cautionRegex);
    if (cautionMatch) {
      msg.caution = cautionMatch[0].replace(/^\[|\]$/g, '').trim();
      msg.body = msg.body.replace(cautionRegex, '').trim();
    }
    msg.body = cleanMailBody(msg.body);
  });

  return messages;
}

function MailboxPage({ showToast }) {
  const [currentFolder, setCurrentFolder] = useState('INBOX');
  const [emails, setEmails] = useState([]);
  const [loading, setLoading] = useState(false);
  const [error, setError] = useState('');
  const [selectedUid, setSelectedUid] = useState(null);
  const [emailDetail, setEmailDetail] = useState(null);
  const [detailLoading, setDetailLoading] = useState(false);
  const [search, setSearch] = useState('');
  const [readUids, setReadUids] = useState(() => new Set());

  const [compose, setCompose] = useState(null); // null | { to, subject, body }
  const [expandedIndices, setExpandedIndices] = useState({});

  const fetchEmails = useCallback(async (folder = currentFolder) => {
    setLoading(true);
    setError('');
    setSelectedUid(null);
    try {
      const data = await api.listMailbox(folder);
      setEmails(data || []);
      if (data) {
        const readSet = new Set();
        data.forEach(e => {
          if (e.read) {
            readSet.add(e.uid);
          }
        });
        setReadUids(readSet);
      }
    } catch (err) {
      console.error(err);
      setError(err.message || 'Failed to fetch emails');
    } finally {
      setLoading(false);
    }
  }, [currentFolder]);

  const fetchEmailDetail = useCallback(async (uid) => {
    setDetailLoading(true);
    try {
      const data = await api.getMailboxEmail(uid, currentFolder);
      setEmailDetail(data);
    } catch (err) {
      console.error(err);
      showToast(err.message || 'Failed to fetch email body', 'error');
    } finally {
      setDetailLoading(false);
    }
  }, [showToast, currentFolder]);

  useEffect(() => {
    fetchEmails();
  }, [fetchEmails, currentFolder]);

  useEffect(() => {
    setExpandedIndices({});
    if (selectedUid) {
      fetchEmailDetail(selectedUid);
    } else {
      setEmailDetail(null);
    }
  }, [selectedUid, fetchEmailDetail]);

  const selectEmail = useCallback((uid) => {
    setSelectedUid(uid);
    setReadUids(prev => {
      if (prev.has(uid)) return prev;
      const next = new Set(prev);
      next.add(uid);
      return next;
    });
  }, []);

  const filteredEmails = useMemo(() => {
    if (!search) return emails;
    const s = search.toLowerCase();
    return emails.filter(e =>
      (e.subject || '').toLowerCase().includes(s) ||
      (e.from || '').toLowerCase().includes(s) ||
      (e.to || '').toLowerCase().includes(s) ||
      (e.snippet || '').toLowerCase().includes(s)
    );
  }, [emails, search]);

  const unreadCount = useMemo(
    () => emails.reduce((n, e) => (readUids.has(e.uid) ? n : n + 1), 0),
    [emails, readUids]
  );

  const threadMessages = useMemo(() => {
    if (!emailDetail) return [];
    return parseEmailThread(emailDetail.body, emailDetail.from, emailDetail.date);
  }, [emailDetail]);

  const toggleIndex = useCallback((index) => {
    setExpandedIndices(prev => ({
      ...prev,
      [index]: !prev[index]
    }));
  }, []);

  const expandAll = useCallback(() => {
    const all = {};
    threadMessages.forEach((_, idx) => {
      all[idx] = true;
    });
    setExpandedIndices(all);
  }, [threadMessages]);

  const collapseAll = useCallback(() => {
    setExpandedIndices({});
  }, []);

  const handleReply = useCallback(() => {
    if (!emailDetail) return;
    const { email } = parseSender(emailDetail.from);
    const subject = emailDetail.subject || '';
    setCompose({
      to: email,
      subject: /^re:/i.test(subject) ? subject : `Re: ${subject}`,
      body: '',
    });
  }, [emailDetail]);

  const emailSuggestions = useMemo(() => {
    const suggestions = new Set();
    
    // Extract from all emails in the inbox list
    emails.forEach(e => {
      if (e.from) {
        const { email } = parseSender(e.from);
        if (email) suggestions.add(email);
      }
    });

    // Extract from local storage (sent emails)
    try {
      const sent = JSON.parse(localStorage.getItem('sent_emails') || '[]');
      sent.forEach(email => {
        if (email && email.includes('@')) {
          suggestions.add(email.trim());
        }
      });
    } catch (err) {
      console.error('Error reading sent_emails from localStorage:', err);
    }

    return Array.from(suggestions);
  }, [emails]);

  return (
    <section className="ds-page" style={{ height: 'calc(100vh - 120px)', display: 'flex', flexDirection: 'column' }}>
      <Ds.PageHeader
        title="Admin Mailbox"
        description="Manage the info@primebusiness.network inbox — read incoming emails and compose new messages."
        actions={
          <div style={{ display: 'flex', gap: 'var(--space-2)' }}>
            <Ds.Button
              variant="secondary"
              leftIcon={<IconRefresh size={14} />}
              onClick={fetchEmails}
              loading={loading}
            >
              Refresh
            </Ds.Button>
            <Ds.Button
              variant="primary"
              leftIcon={<IconPlus size={14} />}
              onClick={() => setCompose({ to: '', subject: '', body: '' })}
            >
              Compose
            </Ds.Button>
          </div>
        }
      />

      <div className="mailbox-grid" style={{ display: 'grid', gridTemplateColumns: '380px 1fr', gap: 'var(--space-4)', flex: 1, minHeight: 0, marginTop: 'var(--space-4)' }}>
        {/* Email List Sidebar */}
        <div style={{ background: 'var(--bg-card)', borderRadius: 'var(--radius-lg)', border: '1px solid var(--border-subtle)', display: 'flex', flexDirection: 'column', overflow: 'hidden', minHeight: 0 }}>
          {/* Folder tabs */}
          <div style={{ display: 'flex', borderBottom: '1px solid var(--border-subtle)', background: 'var(--bg-surface)' }}>
            <button
              onClick={() => setCurrentFolder('INBOX')}
              style={{
                flex: 1, padding: 'var(--space-3)', background: 'none', border: 'none',
                borderBottom: currentFolder === 'INBOX' ? '2px solid var(--brand-blue)' : '2px solid transparent',
                color: currentFolder === 'INBOX' ? 'var(--brand-blue)' : 'var(--fg-muted)',
                fontWeight: currentFolder === 'INBOX' ? 'var(--weight-bold)' : 'var(--weight-medium)',
                cursor: 'pointer', fontSize: 'var(--text-sm)', transition: 'all 0.2s'
              }}
            >
              Inbox
            </button>
            <button
              onClick={() => setCurrentFolder('INBOX.Sent')}
              style={{
                flex: 1, padding: 'var(--space-3)', background: 'none', border: 'none',
                borderBottom: currentFolder === 'INBOX.Sent' ? '2px solid var(--brand-blue)' : '2px solid transparent',
                color: currentFolder === 'INBOX.Sent' ? 'var(--brand-blue)' : 'var(--fg-muted)',
                fontWeight: currentFolder === 'INBOX.Sent' ? 'var(--weight-bold)' : 'var(--weight-medium)',
                cursor: 'pointer', fontSize: 'var(--text-sm)', transition: 'all 0.2s'
              }}
            >
              Sent
            </button>
          </div>

          {/* Inbox summary header */}
          <div style={{ padding: 'var(--space-3) var(--space-4)', borderBottom: '1px solid var(--border-subtle)', display: 'flex', alignItems: 'center', justifyContent: 'space-between', gap: 'var(--space-2)' }}>
            <div style={{ display: 'flex', alignItems: 'center', gap: 'var(--space-2)' }}>
              {currentFolder === 'INBOX' ? <IconInbox size={18} stroke={1.75} style={{ color: 'var(--brand-blue)' }} /> : <IconSend size={18} stroke={1.75} style={{ color: 'var(--brand-blue)' }} />}
              <span style={{ fontWeight: 'var(--weight-bold)', color: 'var(--brand-navy)', fontSize: 'var(--text-sm)' }}>
                {currentFolder === 'INBOX' ? 'Inbox' : 'Sent Box'}
              </span>
              <span style={{ fontSize: 'var(--text-xxs)', color: 'var(--fg-muted)' }}>
                {emails.length} {emails.length === 1 ? 'message' : 'messages'}
              </span>
            </div>
            {currentFolder === 'INBOX' && unreadCount > 0 && (
              <span className="mailbox-unread-badge">{unreadCount} unread</span>
            )}
          </div>

          <div style={{ padding: 'var(--space-3)', borderBottom: '1px solid var(--border-subtle)' }}>
            <div className="login-input-wrap" style={{ margin: 0 }}>
              <IconSearch size={16} className="login-input-icon" />
              <input
                type="text"
                placeholder="Search mailbox..."
                value={search}
                onChange={e => setSearch(e.target.value)}
                style={{ paddingLeft: '2.5rem', height: '36px', fontSize: 'var(--text-sm)' }}
              />
            </div>
          </div>

          <div style={{ flex: 1, overflowY: 'auto', padding: 'var(--space-2)' }}>
            {loading ? (
              <div style={{ display: 'flex', justifyContent: 'center', alignItems: 'center', height: '150px', color: 'var(--fg-muted)' }}>
                <Ds.Spinner size="md" />
                <span style={{ marginLeft: 'var(--space-2)', fontSize: 'var(--text-sm)' }}>Loading emails...</span>
              </div>
            ) : error ? (
              <div style={{ padding: 'var(--space-4)', color: 'var(--danger)', fontSize: 'var(--text-sm)', textAlign: 'center' }}>
                {error}
              </div>
            ) : filteredEmails.length === 0 ? (
              <div style={{ display: 'flex', flexDirection: 'column', alignItems: 'center', padding: 'var(--space-6)', color: 'var(--fg-muted)', fontSize: 'var(--text-sm)', textAlign: 'center', gap: 'var(--space-2)' }}>
                {currentFolder === 'INBOX' ? <IconInbox size={32} stroke={1.5} style={{ opacity: 0.4 }} /> : <IconSend size={32} stroke={1.5} style={{ opacity: 0.4 }} />}
                {search ? 'No emails match your search.' : `Your ${currentFolder === 'INBOX' ? 'inbox' : 'sent box'} is empty.`}
              </div>
            ) : (
              <div style={{ display: 'flex', flexDirection: 'column', gap: 'var(--space-1)' }}>
                {filteredEmails.map(e => {
                  const isSelected = selectedUid === e.uid;
                  const isUnread = !readUids.has(e.uid);
                  const { name } = parseSender(e.from);
                  return (
                    <div
                      key={e.uid}
                      onClick={() => selectEmail(e.uid)}
                      className={`mailbox-item ${isSelected ? 'selected' : ''} ${isUnread ? 'unread' : ''}`}
                    >
                      <MailAvatar name={name} email={e.from} size={38} />
                      <div style={{ minWidth: 0, flex: 1, display: 'flex', flexDirection: 'column', gap: '2px' }}>
                        <div style={{ display: 'flex', justifyContent: 'space-between', alignItems: 'center', gap: 'var(--space-2)' }}>
                          <span style={{ fontWeight: isUnread ? 'var(--weight-bold)' : 'var(--weight-semibold)', color: isSelected ? 'var(--brand-blue-900)' : 'var(--fg-primary)', fontSize: 'var(--text-sm)', overflow: 'hidden', textOverflow: 'ellipsis', whiteSpace: 'nowrap' }}>
                            {name}
                          </span>
                          <span style={{ fontSize: 'var(--text-xxs)', color: 'var(--fg-muted)', whiteSpace: 'nowrap', flexShrink: 0, display: 'flex', alignItems: 'center', gap: '4px' }}>
                            {isUnread && <IconPointFilled size={10} style={{ color: 'var(--brand-blue)' }} />}
                            {formatMailDate(e.date)}
                          </span>
                        </div>
                        <div style={{ fontWeight: isUnread ? 'var(--weight-semibold)' : 'var(--weight-medium)', color: 'var(--fg-primary)', fontSize: 'var(--text-xs)', overflow: 'hidden', textOverflow: 'ellipsis', whiteSpace: 'nowrap' }}>
                          {e.subject || '(No Subject)'}
                        </div>
                        <div style={{ color: 'var(--fg-muted)', fontSize: 'var(--text-xxs)', display: '-webkit-box', WebkitLineClamp: 2, WebkitBoxOrient: 'vertical', overflow: 'hidden', lineHeight: 1.4 }}>
                          {e.snippet}
                        </div>
                      </div>
                    </div>
                  );
                })}
              </div>
            )}
          </div>
        </div>

        {/* Email Reading Pane */}
        <div style={{ background: 'var(--bg-card)', borderRadius: 'var(--radius-lg)', border: '1px solid var(--border-subtle)', display: 'flex', flexDirection: 'column', overflow: 'hidden', minHeight: 0 }}>
          {selectedUid ? (
            detailLoading ? (
              <div style={{ display: 'flex', justifyContent: 'center', alignItems: 'center', flex: 1, color: 'var(--fg-muted)' }}>
                <Ds.Spinner size="lg" />
                <span style={{ marginLeft: 'var(--space-3)' }}>Opening email...</span>
              </div>
            ) : emailDetail ? (
              <div style={{ display: 'flex', flexDirection: 'column', flex: 1, overflow: 'hidden' }}>
                {/* Header / Thread Controls */}
                <div style={{ padding: 'var(--space-4) var(--space-5)', borderBottom: '1px solid var(--border-subtle)', display: 'flex', alignItems: 'center', justifyContent: 'space-between', gap: 'var(--space-3)', background: 'var(--bg-surface)' }}>
                  <div style={{ minWidth: 0, flex: 1 }}>
                    <h2 style={{ fontSize: 'var(--text-md)', fontWeight: 'var(--weight-bold)', color: 'var(--brand-navy)', overflow: 'hidden', textOverflow: 'ellipsis', whiteSpace: 'nowrap', margin: 0 }}>
                      {emailDetail.subject || '(No Subject)'}
                    </h2>
                  </div>
                  {threadMessages.length > 1 && (
                    <div style={{ display: 'flex', gap: 'var(--space-2)', flexShrink: 0 }}>
                      <Ds.Button
                        variant="secondary"
                        size="xs"
                        onClick={expandAll}
                        style={{ padding: '4px 8px', fontSize: 'var(--text-xs)' }}
                      >
                        Expand all
                      </Ds.Button>
                      <Ds.Button
                        variant="secondary"
                        size="xs"
                        onClick={collapseAll}
                        style={{ padding: '4px 8px', fontSize: 'var(--text-xs)' }}
                      >
                        Collapse all
                      </Ds.Button>
                    </div>
                  )}
                </div>

                {/* Email Body Thread */}
                <div style={{ flex: 1, padding: 'var(--space-4)', overflowY: 'auto', background: 'var(--bg-subtle)', display: 'flex', flexDirection: 'column', gap: 'var(--space-3)' }}>
                  {threadMessages.map((msg, idx) => {
                    const isExpanded = idx === 0 ? (expandedIndices[0] !== false) : !!expandedIndices[idx];
                    const sender = parseSender(msg.from);

                    if (!isExpanded) {
                      // Render Collapsed Message Card
                      return (
                        <div
                          key={idx}
                          onClick={() => toggleIndex(idx)}
                          style={{
                            background: 'var(--bg-surface)',
                            border: '1px solid var(--border-subtle)',
                            borderRadius: 'var(--radius-md)',
                            padding: 'var(--space-3) var(--space-4)',
                            display: 'flex',
                            alignItems: 'center',
                            justifyContent: 'space-between',
                            cursor: 'pointer',
                            transition: 'background var(--duration-fast) var(--ease-out)',
                            boxShadow: 'var(--shadow-sm)',
                            flexShrink: 0
                          }}
                          onMouseEnter={(e) => e.currentTarget.style.background = 'var(--bg-subtle)'}
                          onMouseLeave={(e) => e.currentTarget.style.background = 'var(--bg-surface)'}
                        >
                          <div style={{ display: 'flex', alignItems: 'center', gap: 'var(--space-3)', minWidth: 0, flex: 1 }}>
                            <MailAvatar name={sender.name} email={sender.email || msg.from} size={28} />
                            <span style={{ fontWeight: 'var(--weight-semibold)', color: 'var(--fg-primary)', fontSize: 'var(--text-sm)', whiteSpace: 'nowrap', overflow: 'hidden', textOverflow: 'ellipsis', width: '150px' }}>
                              {sender.name}
                            </span>
                            <span style={{ color: 'var(--fg-muted)', fontSize: 'var(--text-xs)', overflow: 'hidden', textOverflow: 'ellipsis', whiteSpace: 'nowrap', flex: 1 }}>
                              {msg.body.slice(0, 100) || '(No message content)'}
                            </span>
                          </div>
                          <div style={{ display: 'flex', alignItems: 'center', gap: 'var(--space-3)', flexShrink: 0 }}>
                            <span style={{ fontSize: 'var(--text-xs)', color: 'var(--fg-muted)' }}>
                              {msg.date || ''}
                            </span>
                            <IconChevronRight size={16} style={{ color: 'var(--fg-muted)' }} />
                          </div>
                        </div>
                      );
                    }

                    // Render Expanded Message Card
                    return (
                      <div
                        key={idx}
                        style={{
                          background: '#ffffff',
                          border: '1px solid var(--border-subtle)',
                          borderRadius: 'var(--radius-md)',
                          boxShadow: 'var(--shadow-sm)',
                          display: 'flex',
                          flexDirection: 'column',
                          overflow: 'hidden',
                          flexShrink: 0
                        }}
                      >
                        {/* Message Header */}
                        <div
                          style={{
                            padding: 'var(--space-4) var(--space-5)',
                            borderBottom: '1px solid var(--border-subtle)',
                            background: 'var(--bg-surface)',
                            display: 'flex',
                            alignItems: 'center',
                            justifyContent: 'space-between',
                            cursor: 'pointer'
                          }}
                          onClick={() => toggleIndex(idx)}
                        >
                          <div style={{ display: 'flex', alignItems: 'center', gap: 'var(--space-3)', minWidth: 0 }}>
                            <MailAvatar name={sender.name} email={sender.email || msg.from} size={36} />
                            <div style={{ minWidth: 0 }}>
                              <div style={{ display: 'flex', alignItems: 'baseline', gap: 'var(--space-2)' }}>
                                <span style={{ fontWeight: 'var(--weight-bold)', color: 'var(--fg-primary)', fontSize: 'var(--text-sm)' }}>
                                  {sender.name}
                                </span>
                                {sender.email && (
                                  <span style={{ color: 'var(--fg-muted)', fontSize: 'var(--text-xs)', overflow: 'hidden', textOverflow: 'ellipsis', whiteSpace: 'nowrap' }}>
                                    &lt;{sender.email}&gt;
                                  </span>
                                )}
                              </div>
                              <div style={{ color: 'var(--fg-muted)', fontSize: 'var(--text-xs)', display: 'flex', gap: 'var(--space-2)', marginTop: '2px' }}>
                                <span>to {msg.to || 'me'}</span>
                                {msg.cc && <span>cc: {msg.cc}</span>}
                              </div>
                            </div>
                          </div>
                          <div style={{ display: 'flex', alignItems: 'center', gap: 'var(--space-3)', flexShrink: 0 }}>
                            <span style={{ fontSize: 'var(--text-xs)', color: 'var(--fg-muted)' }}>
                              {msg.date || ''}
                            </span>
                            <IconChevronDown size={16} style={{ color: 'var(--fg-muted)' }} />
                          </div>
                        </div>

                        {/* Caution Warning Box */}
                        {msg.caution && (
                          <div style={{
                            margin: 'var(--space-3) var(--space-5) 0 var(--space-5)',
                            padding: 'var(--space-3) var(--space-4)',
                            background: '#FFFBEB',
                            border: '1px solid #FDE68A',
                            borderRadius: 'var(--radius-md)',
                            color: '#78350F',
                            fontSize: 'var(--text-xs)',
                            display: 'flex',
                            alignItems: 'flex-start',
                            gap: 'var(--space-2)',
                            lineHeight: 1.4
                          }}>
                            <IconAlertCircle size={16} style={{ color: '#D97706', flexShrink: 0, marginTop: '2px' }} />
                            <span>{msg.caution}</span>
                          </div>
                        )}

                        {/* Message Content */}
                        <div style={{ padding: 'var(--space-5) var(--space-5) var(--space-4) var(--space-5)' }}>
                          <pre style={{
                            whiteSpace: 'pre-wrap',
                            wordBreak: 'break-word',
                            fontFamily: 'var(--font-sans)',
                            fontSize: 'var(--text-sm)',
                            color: 'var(--fg-primary)',
                            lineHeight: '1.6',
                            margin: 0
                          }}>
                            {msg.body}
                          </pre>
                        </div>

                        {/* Message Card Footer Action */}
                        <div style={{
                          padding: '0 var(--space-5) var(--space-4) var(--space-5)',
                          display: 'flex',
                          justifyContent: 'flex-start'
                        }}>
                          <Ds.Button
                            variant="secondary"
                            size="sm"
                            leftIcon={<IconArrowBackUp size={12} />}
                            onClick={(e) => {
                              e.stopPropagation();
                              const replyTo = sender.email || msg.from;
                              const replySub = msg.subject || emailDetail.subject || '';
                              setCompose({
                                to: replyTo,
                                subject: /^re:/i.test(replySub) ? replySub : `Re: ${replySub}`,
                                body: ''
                              });
                            }}
                            style={{ padding: '6px 12px', fontSize: 'var(--text-xs)' }}
                          >
                            Reply
                          </Ds.Button>
                        </div>
                      </div>
                    );
                  })}
                </div>
              </div>
            ) : (
              <div style={{ display: 'flex', justifyContent: 'center', alignItems: 'center', flex: 1, color: 'var(--fg-muted)' }}>
                Failed to load email details.
              </div>
            )
          ) : (
            <div style={{ display: 'flex', flexDirection: 'column', justifyContent: 'center', alignItems: 'center', flex: 1, color: 'var(--fg-muted)', padding: 'var(--space-6)', textAlign: 'center' }}>
              <div style={{ width: 72, height: 72, borderRadius: '50%', background: 'var(--bg-subtle)', display: 'flex', alignItems: 'center', justifyContent: 'center', marginBottom: 'var(--space-4)' }}>
                <IconMail size={36} stroke={1.5} style={{ opacity: 0.5 }} />
              </div>
              <h3 style={{ fontSize: 'var(--text-md)', fontWeight: 'var(--weight-semibold)', color: 'var(--fg-primary)' }}>No email selected</h3>
              <p style={{ fontSize: 'var(--text-sm)', marginTop: '4px', maxWidth: '320px' }}>
                Select an email from the list to read its contents and retrieve verification codes.
              </p>
            </div>
          )}
        </div>
      </div>

      {compose && (
        <ComposeEmailModal
          initialTo={compose.to}
          initialSubject={compose.subject}
          initialBody={compose.body}
          onClose={() => setCompose(null)}
          onSuccess={() => {
            fetchEmails();
          }}
          showToast={showToast}
          emailSuggestions={emailSuggestions}
        />
      )}
    </section>
  );
}

function ComposeEmailModal({ onClose, onSuccess, showToast, initialTo = '', initialSubject = '', initialBody = '', emailSuggestions = [] }) {
  const [to, setTo] = useState(initialTo);
  const [subject, setSubject] = useState(initialSubject);
  const [body, setBody] = useState(initialBody);
  const [attachments, setAttachments] = useState([]);
  const [loading, setLoading] = useState(false);
  const [error, setError] = useState('');
  const isReply = !!initialTo;

  const handleFileChange = (e) => {
    if (e.target.files) {
      setAttachments(Array.from(e.target.files));
    }
  };

  const handleSubmit = async (e) => {
    e.preventDefault();
    setLoading(true);
    setError('');
    try {
      const attachmentData = await Promise.all(attachments.map(file => {
        return new Promise((resolve, reject) => {
          const reader = new FileReader();
          reader.readAsDataURL(file);
          reader.onload = () => {
            const base64Str = reader.result.split(',')[1];
            resolve({
              filename: file.name,
              content: base64Str,
              content_type: file.type || 'application/octet-stream'
            });
          };
          reader.onerror = error => reject(error);
        });
      }));

      await api.sendMailboxEmail({ to_email: to, subject, body, attachments: attachmentData });
      
      // Save recipient to sent_emails in localStorage
      try {
        const sent = JSON.parse(localStorage.getItem('sent_emails') || '[]');
        const cleanedTo = to.trim();
        if (cleanedTo && !sent.includes(cleanedTo)) {
          sent.push(cleanedTo);
          localStorage.setItem('sent_emails', JSON.stringify(sent));
        }
      } catch (err) {
        console.error('Failed to save sent email to local storage:', err);
      }

      showToast('Email sent successfully!');
      if (onSuccess) onSuccess();
      onClose();
    } catch (err) {
      console.error(err);
      setError(err.message || 'Failed to send email');
    } finally {
      setLoading(false);
    }
  };

  return (
    <div className="ds-modal-overlay" onClick={(e) => e.target === e.currentTarget && onClose()}>
      <div className="ds-modal ds-modal--lg" onClick={e => e.stopPropagation()}>
        <div className="ds-modal__header">
          <div>
            <h2 className="ds-modal__title" style={{ display: 'flex', alignItems: 'center', gap: 'var(--space-2)' }}>
              {isReply ? <IconArrowBackUp size={20} style={{ color: 'var(--brand-blue)' }} /> : <IconSend size={20} style={{ color: 'var(--brand-blue)' }} />}
              {isReply ? 'Reply to Message' : 'Compose Email'}
            </h2>
            <div className="ds-modal__subtitle">
              {isReply ? 'Send a reply from info@primebusiness.network' : 'Compose and send an email from info@primebusiness.network'}
            </div>
          </div>
          <button type="button" className="modal-close-btn" onClick={onClose} style={{ border: 'none', background: 'none', cursor: 'pointer', padding: '4px', display: 'flex', alignItems: 'center', justifyContent: 'center' }}>
            <IconX size={20} />
          </button>
        </div>
        <form onSubmit={handleSubmit} style={{ display: 'flex', flexDirection: 'column', flex: 1, overflow: 'hidden' }}>
          <div className="ds-modal__body" style={{ display: 'flex', flexDirection: 'column', gap: 'var(--space-4)' }}>
            {error && <div className="login-error" style={{ marginBottom: 0 }}>{error}</div>}
            
            <div style={{ display: 'flex', flexDirection: 'column', gap: 'var(--space-1)' }}>
              <label style={{ fontSize: 'var(--text-xs)', fontWeight: 'var(--weight-bold)', color: 'var(--fg-secondary)', textTransform: 'uppercase', letterSpacing: '0.05em' }}>To</label>
              <input 
                type="email" 
                value={to} 
                onChange={e => setTo(e.target.value)} 
                list="email-suggestions"
                style={{
                  width: '100%',
                  padding: 'var(--space-2) var(--space-3)',
                  border: '1px solid var(--border-default)',
                  borderRadius: 'var(--radius-md)',
                  fontFamily: 'var(--font-body)',
                  fontSize: 'var(--text-base)',
                  color: 'var(--fg-primary)',
                  background: 'var(--bg-surface)',
                  outline: 'none',
                  boxShadow: 'none',
                  transition: 'border-color var(--duration-fast) var(--ease-out), box-shadow var(--duration-fast) var(--ease-out)'
                }}
                onFocus={(e) => {
                  e.target.style.borderColor = 'var(--border-focus)';
                  e.target.style.boxShadow = 'var(--ring-focus)';
                }}
                onBlur={(e) => {
                  e.target.style.borderColor = 'var(--border-default)';
                  e.target.style.boxShadow = 'none';
                }}
                placeholder="recipient@example.com" 
                required 
              />
              <datalist id="email-suggestions">
                {emailSuggestions.map(email => (
                  <option key={email} value={email} />
                ))}
              </datalist>
            </div>

            <div style={{ display: 'flex', flexDirection: 'column', gap: 'var(--space-1)' }}>
              <label style={{ fontSize: 'var(--text-xs)', fontWeight: 'var(--weight-bold)', color: 'var(--fg-secondary)', textTransform: 'uppercase', letterSpacing: '0.05em' }}>Subject</label>
              <input 
                type="text" 
                value={subject} 
                onChange={e => setSubject(e.target.value)} 
                style={{
                  width: '100%',
                  padding: 'var(--space-2) var(--space-3)',
                  border: '1px solid var(--border-default)',
                  borderRadius: 'var(--radius-md)',
                  fontFamily: 'var(--font-body)',
                  fontSize: 'var(--text-base)',
                  color: 'var(--fg-primary)',
                  background: 'var(--bg-surface)',
                  outline: 'none',
                  boxShadow: 'none',
                  transition: 'border-color var(--duration-fast) var(--ease-out), box-shadow var(--duration-fast) var(--ease-out)'
                }}
                onFocus={(e) => {
                  e.target.style.borderColor = 'var(--border-focus)';
                  e.target.style.boxShadow = 'var(--ring-focus)';
                }}
                onBlur={(e) => {
                  e.target.style.borderColor = 'var(--border-default)';
                  e.target.style.boxShadow = 'none';
                }}
                placeholder="Subject" 
                required 
              />
            </div>

            <div style={{ display: 'flex', flexDirection: 'column', gap: 'var(--space-1)', flex: 1, minHeight: 0 }}>
              <label style={{ fontSize: 'var(--text-xs)', fontWeight: 'var(--weight-bold)', color: 'var(--fg-secondary)', textTransform: 'uppercase', letterSpacing: '0.05em' }}>Message</label>
              <textarea 
                value={body} 
                onChange={e => setBody(e.target.value)} 
                placeholder="Write your email here..." 
                style={{
                  width: '100%',
                  flex: 1,
                  minHeight: '200px',
                  padding: 'var(--space-3)',
                  border: '1px solid var(--border-default)',
                  borderRadius: 'var(--radius-md)',
                  fontFamily: 'var(--font-body)',
                  fontSize: 'var(--text-base)',
                  color: 'var(--fg-primary)',
                  background: 'var(--bg-surface)',
                  outline: 'none',
                  resize: 'vertical',
                  boxShadow: 'none',
                  lineHeight: '1.6',
                  transition: 'border-color var(--duration-fast) var(--ease-out), box-shadow var(--duration-fast) var(--ease-out)'
                }}
                onFocus={(e) => {
                  e.target.style.borderColor = 'var(--border-focus)';
                  e.target.style.boxShadow = 'var(--ring-focus)';
                }}
                onBlur={(e) => {
                  e.target.style.borderColor = 'var(--border-default)';
                  e.target.style.boxShadow = 'none';
                }}
                required 
              />
            </div>
            
            <div style={{ display: 'flex', flexDirection: 'column', gap: 'var(--space-1)' }}>
              <label style={{ fontSize: 'var(--text-xs)', fontWeight: 'var(--weight-bold)', color: 'var(--fg-secondary)', textTransform: 'uppercase', letterSpacing: '0.05em' }}>Attachments</label>
              <input 
                type="file" 
                multiple 
                onChange={handleFileChange}
                style={{
                  fontFamily: 'var(--font-body)',
                  fontSize: 'var(--text-sm)',
                  color: 'var(--fg-primary)'
                }}
              />
              {attachments.length > 0 && (
                <div style={{ fontSize: 'var(--text-xs)', color: 'var(--fg-muted)', marginTop: '4px' }}>
                  {attachments.length} file(s) selected
                </div>
              )}
            </div>
          </div>

          <div className="ds-modal__footer">
            <Ds.Button 
              type="button" 
              variant="secondary" 
              onClick={onClose}
              style={{ minWidth: '100px' }}
            >
              Cancel
            </Ds.Button>
            <Ds.Button
              type="submit"
              variant="primary"
              loading={loading}
              leftIcon={<IconSend size={14} />}
              style={{ minWidth: '120px' }}
            >
              {isReply ? 'Send Reply' : 'Send Email'}
            </Ds.Button>
          </div>
        </form>
      </div>
    </div>
  );
}

// ── Security Logs (Audit Trail) Page ─────────────────────────────────────

// Map machine-derived action names to human labels. Falls back to title-casing.
const ACTION_LABELS = {
  create: 'Create',
  update: 'Update',
  delete: 'Delete',
  create_chapters: 'Create chapter',
  delete_chapters: 'Delete chapter',
  update_chapters: 'Update chapter',
  create_clubs: 'Create club',
  update_clubs: 'Update club',
  delete_clubs: 'Delete club',
  create_staff: 'Create admin user',
  delete_staff: 'Delete admin user',
  update_change_password: 'Change password',
  update_2fa: 'Toggle 2FA',
  update_me: 'Update profile',
  create_me: 'Update profile',
  admin_update: 'Admin update',
  deactivate: 'Deactivate user',
  reactivate: 'Reactivate user',
  remove_from_chapter: 'Remove from chapter',
  status_update: 'Change status',
  manual_record: 'Record payment',
  webhook_processed: 'Webhook processed',
  approve: 'Approve',
  reject: 'Reject',
  feature: 'Feature listing',
};

const humanizeAction = (a) => {
  if (!a) return '—';
  if (ACTION_LABELS[a]) return ACTION_LABELS[a];
  return a.replace(/_/g, ' ').replace(/\b\w/g, c => c.toUpperCase());
};

// Specific, contextual label for an audit row based on method + path + body.
// Falls back to humanizeAction(log.action) when no rule matches.
function describeAuditAction(log) {
  if (!log) return '—';
  const path = (log.path || '').replace(/^\/api\/v[0-9]+/, ''); // strip /api/v1
  const m = (log.method || '').toUpperCase();
  const body = log.new_value || {};
  const status = body.status;

  // Applications
  if (/^\/applications\/[^/]+\/status$/.test(path)) {
    if (status === 'approved') return 'Application approved';
    if (status === 'rejected') return 'Application rejected';
    if (status === 'waitlisted') return 'Application waitlisted';
    if (status === 'fit_call_scheduled') return 'Application moved to fit call';
    if (status) return `Application status → ${status.replace(/_/g, ' ')}`;
    return 'Application status updated';
  }
  if (/^\/admin\/applications\/[^/]+\/payment-status$/.test(path)) return 'Application payment status updated';
  if (/^\/applications$/.test(path) && m === 'POST') return 'Application submitted';
  if (/^\/applications\/[^/]+$/.test(path) && m === 'DELETE') return 'Application deleted';

  // Auth / self profile
  if (path === '/auth/change-password') return 'Password changed';
  if (path === '/auth/me/photo') return 'Profile photo updated';
  if (path === '/auth/me' && m === 'PUT') return 'Profile updated';
  if (path === '/auth/2fa' && m === 'PUT') return 'Two-factor authentication toggled';

  // Staff (admin-panel users)
  if (path === '/admin/staff' && m === 'POST') return 'Admin user created';
  if (/^\/admin\/staff\/[^/]+$/.test(path) && m === 'DELETE') return 'Admin user deleted';

  // Member / user management
  if (/^\/admin\/users\/[^/]+\/deactivate$/.test(path)) return 'User deactivated';
  if (/^\/admin\/users\/[^/]+\/reactivate$/.test(path)) return 'User reactivated';
  if (/^\/admin\/users\/[^/]+\/chapter$/.test(path) && m === 'DELETE') return 'User removed from chapter';
  if (/^\/admin\/users\/[^/]+$/.test(path) && m === 'PATCH') {
    if (body.is_active === false) return 'User deactivated';
    if (body.is_active === true) return 'User reactivated';
    if (body.role) return `User role changed → ${body.role}`;
    if (body.membership_type) return `Membership type changed → ${body.membership_type}`;
    return 'User updated';
  }

  // Chapters
  if (path === '/chapters' && m === 'POST') return 'Chapter created';
  if (/^\/chapters\/[^/]+$/.test(path) && m === 'PATCH') return 'Chapter updated';
  if (/^\/chapters\/[^/]+$/.test(path) && m === 'DELETE') return 'Chapter deleted';

  // Horizontal clubs
  if (path === '/admin/clubs' && m === 'POST') return 'Horizontal club created';
  if (/^\/admin\/clubs\/[^/]+$/.test(path) && m === 'PATCH') return 'Horizontal club updated';
  if (/^\/admin\/clubs\/[^/]+$/.test(path) && m === 'DELETE') return 'Horizontal club deleted';

  // Events
  if (path === '/events' && m === 'POST') return 'Event created';
  if (/^\/events\/[^/]+$/.test(path) && m === 'PATCH') return 'Event updated';
  if (/^\/events\/[^/]+\/approve$/.test(path)) return 'Event RSVP approved';
  if (/^\/events\/[^/]+\/attendance$/.test(path)) return 'Event attendance marked';
  if (path === '/events/upload-image') return 'Event image uploaded';

  // Marketplace moderation
  if (/^\/admin\/marketplace\/listings\/[^/]+\/approve$/.test(path)) return 'Marketplace listing approved';
  if (/^\/admin\/marketplace\/listings\/[^/]+\/reject$/.test(path)) return 'Marketplace listing rejected';
  if (path === '/marketplace/listings' && m === 'POST') return 'Marketplace listing created';
  if (/^\/marketplace\/listings\/[^/]+$/.test(path) && m === 'PATCH') return 'Marketplace listing updated';
  if (/^\/marketplace\/listings\/[^/]+$/.test(path) && m === 'DELETE') return 'Marketplace listing deleted';

  // Rewards / privilege cards
  if (path === '/admin/cards/issue') return 'Privilege card issued';
  if (/^\/admin\/cards\/[^/]+\/suspend$/.test(path)) return 'Privilege card suspended';
  if (/^\/admin\/cards\/[^/]+\/replace$/.test(path)) return 'Privilege card replaced';
  if (/^\/admin\/cards\/[^/]+$/.test(path) && m === 'PATCH') return 'Privilege card updated';

  // Partners & offers
  if (path === '/rewards/partners' && m === 'POST') return 'Partner created';
  if (/^\/rewards\/partners\/[^/]+$/.test(path) && m === 'PATCH') return 'Partner updated';
  if (/^\/rewards\/partners\/[^/]+\/offers$/.test(path) && m === 'POST') return 'Reward offer created';
  if (path === '/rewards/partners/upload-logo') return 'Partner logo uploaded';

  // Payments
  if (path === '/admin/payments' && m === 'POST') return 'Payment recorded';
  if (/^\/admin\/payments\/[^/]+$/.test(path) && m === 'PATCH') return 'Payment updated';

  // Fees
  if (/^\/admin\/fees\/[^/]+$/.test(path) && m === 'PATCH') return 'Fee schedule updated';

  // Community moderation
  if (/^\/community\/posts\/[^/]+\/pin$/.test(path)) return 'Community post pinned/unpinned';
  if (/^\/community\/posts\/[^/]+\/status$/.test(path)) return 'Community post status updated';
  if (/^\/community\/posts\/[^/]+$/.test(path) && m === 'DELETE') return 'Community post deleted';
  if (/^\/community\/comments\/[^/]+$/.test(path) && m === 'DELETE') return 'Community comment deleted';

  return humanizeAction(log.action);
}

const ENTITY_LABELS = {
  user: 'User',
  users: 'User',
  staff: 'Staff',
  chapters: 'Chapter',
  chapter_membership: 'Membership',
  membership: 'Membership',
  application: 'Application',
  applications: 'Application',
  payment: 'Payment',
  payments: 'Payment',
  marketplace: 'Marketplace',
  events: 'Event',
  clubs: 'Club',
  rewards: 'Reward',
  cards: 'Privilege card',
  auth: 'Auth',
  fees: 'Fee schedule',
};

const humanizeEntity = (e) => {
  if (!e) return '—';
  if (ENTITY_LABELS[e]) return ENTITY_LABELS[e];
  return e.replace(/_/g, ' ').replace(/\b\w/g, c => c.toUpperCase());
};

function SecurityLogsPage({ adminUser }) {
  const isSuperAdmin = adminUser?.role === 'SUPER_ADMIN';

  const [logs, setLogs] = useState([]);
  const [total, setTotal] = useState(0);
  const [loading, setLoading] = useState(true);
  const [page, setPage] = useState(1);
  const [pageSize] = useState(25);
  const [search, setSearch] = useState('');
  const [entityType, setEntityType] = useState('');
  const [action, setAction] = useState('');
  const [method, setMethod] = useState('');
  const [dateFrom, setDateFrom] = useState(null);
  const [dateTo, setDateTo] = useState(null);
  const [facets, setFacets] = useState({ entity_types: [], actions: [], methods: [] });
  const [selected, setSelected] = useState(null);
  const [error, setError] = useState(null);

  const fetchLogs = useCallback(async () => {
    if (!isSuperAdmin) return;
    setLoading(true);
    setError(null);
    try {
      const params = { page, page_size: pageSize };
      if (search) params.search = search;
      if (entityType) params.entity_type = entityType;
      if (action) params.action = action;
      if (method) params.method = method;
      if (dateFrom) params.date_from = dateFrom.toISOString();
      if (dateTo) params.date_to = dateTo.toISOString();
      const data = await api.listAuditLogs(params);
      setLogs(data.logs || []);
      setTotal(data.total || 0);
    } catch (err) {
      console.error('Failed to load audit logs:', err);
      setError(err.message || 'Failed to load audit logs');
    } finally {
      setLoading(false);
    }
  }, [isSuperAdmin, page, pageSize, search, entityType, action, method, dateFrom, dateTo]);

  useEffect(() => { fetchLogs(); }, [fetchLogs]);

  useEffect(() => {
    if (!isSuperAdmin) return;
    api.getAuditLogFacets()
      .then(setFacets)
      .catch(err => console.error('Failed to load facets:', err));
  }, [isSuperAdmin]);

  useEffect(() => { setPage(1); }, [search, entityType, action, method, dateFrom, dateTo]);

  const clearFilters = () => {
    setSearch(''); setEntityType(''); setAction(''); setMethod('');
    setDateFrom(null); setDateTo(null);
  };
  const hasFilters = !!(search || entityType || action || method || dateFrom || dateTo);

  if (!isSuperAdmin) {
    return (
      <section className="ds-page">
        <Ds.PageHeader
          title="Audit Log"
          description="Timeline of administrative actions across the platform."
        />
        <Ds.Section>
          <Ds.EmptyState
            icon={IconLock}
            title="Restricted area"
            description="Only Super Admins can view the audit trail."
          />
        </Ds.Section>
      </section>
    );
  }

  const methodVariant = (m) => {
    if (m === 'POST') return 'success';
    if (m === 'PATCH' || m === 'PUT') return 'brand';
    if (m === 'DELETE') return 'danger';
    return 'neutral';
  };
  const statusVariant = (code) => {
    if (!code) return 'neutral';
    if (code >= 500) return 'danger';
    if (code >= 400) return 'warning';
    if (code >= 300) return 'brand';
    return 'success';
  };

  // Compact two-line date for the When column
  const formatWhen = (iso) => {
    if (!iso) return { date: '—', time: '' };
    const d = new Date(iso);
    return {
      date: d.toLocaleDateString(undefined, { month: 'short', day: '2-digit', year: 'numeric' }),
      time: d.toLocaleTimeString(undefined, { hour: '2-digit', minute: '2-digit', second: '2-digit', hour12: false }),
    };
  };

  // Stat strip — computed from the current visible page (cheap, helpful at-a-glance)
  const stats = {
    total,
    failures: logs.filter(l => l.status_code && l.status_code >= 400).length,
    today: logs.filter(l => {
      if (!l.created_at) return false;
      const d = new Date(l.created_at);
      const now = new Date();
      return d.toDateString() === now.toDateString();
    }).length,
    actors: new Set(logs.filter(l => l.actor?.id).map(l => l.actor.id)).size,
  };

  const totalPages = Math.max(1, Math.ceil(total / pageSize));

  const methodChips = [
    { value: '', label: 'All' },
    { value: 'POST', label: 'POST' },
    { value: 'PATCH', label: 'PATCH' },
    { value: 'PUT', label: 'PUT' },
    { value: 'DELETE', label: 'DELETE' },
  ];

  return (
    <section className="ds-page">
      <Ds.PageHeader
        title="Audit Log"
        description="Every admin operation is recorded — who, what, when, and from where."
        actions={
          <Ds.Button
            variant="secondary"
            leftIcon={<IconRefresh size={14} />}
            onClick={fetchLogs}
          >
            Refresh
          </Ds.Button>
        }
      />

      <div className="ds-stat-grid">
        <Ds.StatCard
          label="Total events"
          value={total.toLocaleString()}
          icon={IconListDetails}
          iconColor="var(--brand-blue)"
          iconBg="var(--brand-blue-50)"
        />
        <Ds.StatCard
          label="On this page"
          value={logs.length}
          icon={IconClipboardList}
          iconColor="var(--fg-secondary)"
          iconBg="var(--bg-subtle)"
        />
        <Ds.StatCard
          label="Failures on page"
          value={stats.failures}
          icon={IconAlertCircle}
          iconColor="var(--warning)"
          iconBg="var(--warning-bg)"
        />
        <Ds.StatCard
          label="Distinct actors"
          value={stats.actors}
          icon={IconUserCheck}
          iconColor="var(--success)"
          iconBg="var(--success-bg)"
        />
      </div>

      <Ds.Section
        title="Activity trail"
        subtitle="Click any row to inspect the request body, response status and diff."
        flush
        actions={
          <Ds.ChipGroup
            value={method}
            onChange={setMethod}
            options={methodChips}
          />
        }
      >
        <div style={{
          display: 'grid',
          gridTemplateColumns: 'minmax(260px, 1.4fr) minmax(160px, 1fr) minmax(160px, 1fr) auto auto',
          gap: 'var(--space-3)',
          alignItems: 'center',
          padding: 'var(--space-4) var(--space-6)',
          borderBottom: '1px solid var(--border-subtle)',
        }}>
          <Ds.Input
            placeholder="Search by actor, action or path…"
            value={search}
            onChange={e => setSearch(e.target.value)}
            leftIcon={<IconSearch size={14} />}
          />
          <Ds.Select
            placeholder="All entities"
            value={entityType}
            options={facets.entity_types.map(t => ({ id: t, name: humanizeEntity(t) }))}
            allowClear
            onChange={setEntityType}
          />
          <Ds.Select
            placeholder="All actions"
            value={action}
            options={facets.actions.map(a => ({ id: a, name: humanizeAction(a) }))}
            allowClear
            onChange={setAction}
          />
          <div className="audit-daterange">
            <DatePicker
              selected={dateFrom}
              onChange={setDateFrom}
              selectsStart
              startDate={dateFrom}
              endDate={dateTo}
              dateFormat="MMM d, yyyy"
              placeholderText="From date"
              className="modern-datepicker-input"
              isClearable
            />
            <span style={{ color: 'var(--fg-muted)', padding: '0 6px' }}>—</span>
            <DatePicker
              selected={dateTo}
              onChange={setDateTo}
              selectsEnd
              startDate={dateFrom}
              endDate={dateTo}
              minDate={dateFrom}
              dateFormat="MMM d, yyyy"
              placeholderText="To date"
              className="modern-datepicker-input"
              isClearable
            />
          </div>
          {hasFilters ? (
            <Ds.Button variant="ghost" onClick={clearFilters} leftIcon={<IconX size={14} />}>
              Clear
            </Ds.Button>
          ) : <span />}
        </div>

        {error && (
          <div style={{ padding: 'var(--space-4) var(--space-6)', color: 'var(--danger)' }}>
            {error}
          </div>
        )}

        <Ds.Table>
          <thead>
            <tr>
              <th style={{ width: 140 }}>When</th>
              <th style={{ width: 220 }}>Actor</th>
              <th>Action</th>
              <th style={{ width: 140 }}>Target</th>
              <th style={{ width: 90 }}>Method</th>
              <th style={{ width: 90 }}>Status</th>
              <th style={{ width: 130 }}>Source</th>
              <th className="ds-table__actions" />
            </tr>
          </thead>
          <tbody>
            {loading ? (
              <Ds.Table.LoadingRow colSpan={8} label="Loading audit trail…" />
            ) : logs.length === 0 ? (
              <Ds.Table.EmptyRow
                colSpan={8}
                icon={IconLock}
                title="No audit events"
                description={hasFilters ? "No events match the current filters." : "Activity will appear here as soon as admins start operating."}
              />
            ) : logs.map(log => {
              const when = formatWhen(log.created_at);
              return (
                <tr key={log.id} className="is-clickable" onClick={() => setSelected(log)}>
                  <td style={{ fontVariantNumeric: 'tabular-nums' }}>
                    <div className="ds-table__primary" style={{ fontSize: 'var(--text-sm)' }}>{when.date}</div>
                    <div className="ds-table__muted" style={{ fontSize: 'var(--text-xs)' }}>{when.time}</div>
                  </td>
                  <td>
                    {log.actor?.full_name ? (
                      <div style={{ display: 'flex', alignItems: 'center', gap: 'var(--space-2)', minWidth: 0 }}>
                        <Ds.Avatar size="sm" name={log.actor.full_name} />
                        <div style={{ minWidth: 0 }}>
                          <div className="ds-table__primary" style={{ overflow: 'hidden', textOverflow: 'ellipsis', whiteSpace: 'nowrap' }}>
                            {log.actor.full_name}
                          </div>
                          <div className="ds-table__muted" style={{ fontSize: 'var(--text-xs)' }}>
                            {log.actor.role || '—'}
                          </div>
                        </div>
                      </div>
                    ) : (
                      <span className="ds-table__muted">System</span>
                    )}
                  </td>
                  <td>
                    <div className="ds-table__primary">{describeAuditAction(log)}</div>
                  </td>
                  <td className="ds-table__muted">{humanizeEntity(log.entity_type)}</td>
                  <td>
                    {log.method ? <Ds.Badge variant={methodVariant(log.method)}>{log.method}</Ds.Badge> : <span className="ds-table__muted">—</span>}
                  </td>
                  <td>
                    {log.status_code ? (
                      <Ds.Badge variant={statusVariant(log.status_code)}>{log.status_code}</Ds.Badge>
                    ) : <span className="ds-table__muted">—</span>}
                  </td>
                  <td className="ds-table__muted" style={{ fontVariantNumeric: 'tabular-nums', fontSize: 'var(--text-xs)' }}>
                    {log.ip_address || '—'}
                  </td>
                  <td className="ds-table__actions" onClick={e => e.stopPropagation()}>
                    <Ds.IconButton aria-label="View details" onClick={() => setSelected(log)}>
                      <IconEye size={16} />
                    </Ds.IconButton>
                  </td>
                </tr>
              );
            })}
          </tbody>
        </Ds.Table>

        <Ds.Pagination
          page={page}
          totalPages={totalPages}
          total={total}
          pageLabel="events"
          onPageChange={p => setPage(Math.max(1, p))}
        />
      </Ds.Section>

      {selected && (
        <AuditLogDetailModal log={selected} onClose={() => setSelected(null)} />
      )}
    </section>
  );
}

// Fetcher: given an audit log row, try to load the related entity.
// Returns { kind, data, loading, error }. Currently supports applications.
function useAuditContext(log) {
  const [state, setState] = useState({ kind: null, data: null, loading: false, error: null });

  useEffect(() => {
    if (!log) return;
    const path = (log.path || '').replace(/^\/api\/v[0-9]+/, '');
    const m = (log.method || '').toUpperCase();

    // Try to derive an application id from the path or entity fields.
    const appMatch = path.match(/^\/applications\/([0-9a-f-]{36})/i)
      || path.match(/^\/admin\/applications\/([0-9a-f-]{36})/i);

    if (appMatch && (log.entity_type === 'application' || log.entity_type === 'applications' || appMatch)) {
      const appId = appMatch[1];
      // Don't try to fetch if the application was just deleted in this very event
      if (m === 'DELETE' && path.endsWith(appId)) {
        setState({ kind: 'application', data: null, loading: false, error: 'Application was deleted in this event' });
        return;
      }
      setState({ kind: 'application', data: null, loading: true, error: null });
      api.getApplication(appId)
        .then(d => setState({ kind: 'application', data: d, loading: false, error: null }))
        .catch(err => setState({ kind: 'application', data: null, loading: false, error: err.message || 'Failed to load application' }));
      return;
    }
    // Future: add chapter / privilege card / etc. here as their getById endpoints land.
  }, [log]);

  return state;
}

function ApplicationContextCard({ data }) {
  if (!data) return null;
  return (
    <div style={{
      border: '1px solid var(--border-subtle)',
      borderRadius: 'var(--radius-lg, 12px)',
      background: 'var(--bg-elevated, #fff)',
      padding: 'var(--space-4)',
    }}>
      <div style={{ display: 'flex', alignItems: 'center', gap: 'var(--space-3)', marginBottom: 'var(--space-3)' }}>
        <Ds.Avatar size="md" name={data.full_name || '?'} />
        <div style={{ flex: 1, minWidth: 0 }}>
          <div style={{ fontWeight: 'var(--weight-bold)', fontSize: 'var(--text-base)' }}>
            {data.full_name || '—'}
          </div>
          <div style={{ color: 'var(--fg-secondary)', fontSize: 'var(--text-sm)' }}>
            {data.business_name || '—'} · {data.industry_name || '—'}
          </div>
        </div>
        <Ds.Badge variant={
          data.status === 'approved' ? 'success'
          : data.status === 'rejected' ? 'danger'
          : data.status === 'fit_call_scheduled' ? 'brand'
          : 'warning'
        }>
          {data.status?.replace(/_/g, ' ')}
        </Ds.Badge>
      </div>
      <div style={{ display: 'grid', gridTemplateColumns: 'repeat(2, minmax(0, 1fr))', gap: 'var(--space-3) var(--space-4)' }}>
        <ContextRow label="Email" value={data.email} />
        <ContextRow label="Phone" value={data.contact_number} />
        <ContextRow label="District" value={data.district} />
        <ContextRow label="Chapter" value={data.chapter_name} />
        <ContextRow label="Industry" value={data.industry_name} />
        <ContextRow label="Submitted" value={data.created_at ? new Date(data.created_at).toLocaleString() : null} />
        {data.fit_call_date && <ContextRow label="Fit call" value={new Date(data.fit_call_date).toLocaleString()} />}
        {data.notes && <ContextRow label="Notes" value={data.notes} full />}
      </div>

      {data.history && data.history.length > 0 && (
        <div style={{ marginTop: 'var(--space-4)' }}>
          <div style={{ fontSize: 'var(--text-xs)', color: 'var(--fg-secondary)', textTransform: 'uppercase', letterSpacing: '.04em', marginBottom: 8 }}>
            Status history
          </div>
          <div style={{ display: 'flex', flexDirection: 'column', gap: 'var(--space-2)' }}>
            {data.history.slice().reverse().map(h => (
              <div key={h.id} style={{
                display: 'flex', alignItems: 'center', gap: 'var(--space-3)',
                padding: 'var(--space-2) var(--space-3)',
                background: 'var(--bg-subtle)', borderRadius: 'var(--radius-md, 8px)',
              }}>
                <span className="ds-table__muted" style={{ fontSize: 'var(--text-xs)', minWidth: 140 }}>
                  {h.created_at ? new Date(h.created_at).toLocaleString() : '—'}
                </span>
                <span style={{ fontSize: 'var(--text-sm)' }}>
                  {h.old_status ? `${h.old_status.replace(/_/g, ' ')} → ` : ''}
                  <strong>{h.new_status?.replace(/_/g, ' ')}</strong>
                </span>
                {h.notes && <span className="ds-table__muted" style={{ fontSize: 'var(--text-xs)', marginLeft: 'auto' }}>{h.notes}</span>}
              </div>
            ))}
          </div>
        </div>
      )}
    </div>
  );
}

function ContextRow({ label, value, full = false }) {
  return (
    <div style={full ? { gridColumn: '1 / -1' } : undefined}>
      <div style={{ fontSize: 'var(--text-xs)', color: 'var(--fg-secondary)', textTransform: 'uppercase', letterSpacing: '.04em', marginBottom: 2 }}>
        {label}
      </div>
      <div style={{ fontSize: 'var(--text-sm)', wordBreak: 'break-word' }}>
        {value || '—'}
      </div>
    </div>
  );
}

function AuditLogDetailModal({ log, onClose }) {
  const ctx = useAuditContext(log);
  const headline = describeAuditAction(log);

  return (
    <Ds.Modal open onClose={onClose} size="lg">
      <Ds.Modal.Header
        title={headline}
        subtitle={`${log.actor?.full_name || 'System'} · ${new Date(log.created_at).toLocaleString()}`}
        onClose={onClose}
      />
      <Ds.Modal.Body>
        {/* Event summary */}
        <div style={{
          display: 'grid',
          gridTemplateColumns: 'repeat(auto-fit, minmax(180px, 1fr))',
          gap: 'var(--space-3) var(--space-4)',
          padding: 'var(--space-4)',
          background: 'var(--bg-subtle)',
          borderRadius: 'var(--radius-lg, 12px)',
          marginBottom: 'var(--space-5)',
        }}>
          <ContextRow label="Actor" value={log.actor?.full_name || 'System'} />
          <ContextRow label="Role" value={log.actor?.role} />
          <ContextRow label="Target" value={humanizeEntity(log.entity_type)} />
          <ContextRow label="Result" value={log.status_code ? `HTTP ${log.status_code}` : '—'} />
          <ContextRow label="IP address" value={log.ip_address} />
          <ContextRow label="Duration" value={log.duration_ms != null ? `${log.duration_ms} ms` : null} />
          {log.actor?.email && <ContextRow label="Actor email" value={log.actor.email} />}
          {log.user_agent && <ContextRow label="User agent" value={log.user_agent} full />}
        </div>

        {/* Related entity context */}
        {ctx.kind && (
          <div style={{ marginBottom: 'var(--space-5)' }}>
            <div style={{ fontSize: 'var(--text-xs)', color: 'var(--fg-secondary)', textTransform: 'uppercase', letterSpacing: '.04em', marginBottom: 8 }}>
              Related {ctx.kind}
            </div>
            {ctx.loading && (
              <div style={{ padding: 'var(--space-4)', color: 'var(--fg-secondary)' }}>Loading…</div>
            )}
            {ctx.error && (
              <div style={{ padding: 'var(--space-3)', color: 'var(--fg-secondary)', fontSize: 'var(--text-sm)', fontStyle: 'italic' }}>
                {ctx.error}
              </div>
            )}
            {ctx.kind === 'application' && ctx.data && <ApplicationContextCard data={ctx.data} />}
          </div>
        )}

        {/* Diff / raw payload (advanced) */}
        {(log.old_value || log.new_value) && (
          <details>
            <summary style={{
              cursor: 'pointer', userSelect: 'none',
              fontSize: 'var(--text-xs)', color: 'var(--fg-secondary)',
              textTransform: 'uppercase', letterSpacing: '.04em',
              padding: 'var(--space-2) 0',
            }}>
              Request payload & diff
            </summary>
            <div style={{ display: 'grid', gridTemplateColumns: 'repeat(auto-fit, minmax(280px, 1fr))', gap: 'var(--space-4)', marginTop: 'var(--space-3)' }}>
              {log.old_value && (
                <div>
                  <div style={{ fontSize: 'var(--text-xs)', color: 'var(--fg-secondary)', marginBottom: 6 }}>Before</div>
                  <pre style={{
                    background: '#0f172a', color: '#f1f5f9',
                    padding: 'var(--space-3)', borderRadius: 'var(--radius-md, 8px)',
                    maxHeight: 280, overflow: 'auto', fontSize: 'var(--text-xs)', margin: 0,
                  }}>
                    {JSON.stringify(log.old_value, null, 2)}
                  </pre>
                </div>
              )}
              {log.new_value && (
                <div>
                  <div style={{ fontSize: 'var(--text-xs)', color: 'var(--fg-secondary)', marginBottom: 6 }}>After / payload</div>
                  <pre style={{
                    background: '#0f172a', color: '#f1f5f9',
                    padding: 'var(--space-3)', borderRadius: 'var(--radius-md, 8px)',
                    maxHeight: 280, overflow: 'auto', fontSize: 'var(--text-xs)', margin: 0,
                  }}>
                    {JSON.stringify(log.new_value, null, 2)}
                  </pre>
                </div>
              )}
            </div>
          </details>
        )}
      </Ds.Modal.Body>
      <Ds.Modal.Footer>
        <Ds.Button variant="secondary" onClick={onClose}>Close</Ds.Button>
      </Ds.Modal.Footer>
    </Ds.Modal>
  );
}



// ── Events Management ────────────────────────────────────────────────────────

function AddEventModal({ onClose, onCreated, chapters = [] }) {
  const [formData, setFormData] = useState({
    chapter_id: '',
    title: '',
    description: '',
    event_type: 'flagship',
    location: '',
    meeting_link: '',
    start_at: new Date(),
    end_at: new Date(Date.now() + 3600000), // +1 hour
    fee: 0,
    max_attendees: '',
    is_published: true,
    image_url: ''
  });
  const [loading, setLoading] = useState(false);
  const [uploading, setUploading] = useState(false);
  const [error, setError] = useState('');

  const handleFileUpload = async (e) => {
    const file = e.target.files[0];
    if (!file) return;
    setUploading(true);
    setError('');
    try {
      const result = await api.uploadEventImage(file);
      setFormData(prev => ({ ...prev, image_url: result.image_url }));
    } catch (err) {
      setError('Image upload failed: ' + err.message);
    } finally {
      setUploading(false);
    }
  };

  const handleSubmit = async (e) => {
    e.preventDefault();
    if (!formData.chapter_id) return setError('Please select a chapter');
    if (!formData.start_at || !formData.end_at) return setError('Please set event dates');
    
    setLoading(true);
    setError('');
    try {
      await api.createEvent({
        ...formData,
        fee: parseFloat(formData.fee),
        max_attendees: formData.max_attendees ? parseInt(formData.max_attendees) : null,
        start_at: formData.start_at.toISOString(),
        end_at: formData.end_at.toISOString(),
      });
      onCreated();
      onClose();
    } catch (err) {
      setError(err.message || 'Failed to create event');
    } finally {
      setLoading(false);
    }
  };

  return (
    <div className="modal-overlay" onClick={(e) => e.target === e.currentTarget && onClose()}>
      <div className="modal-content" onClick={e => e.stopPropagation()} style={{ maxWidth: 600, maxHeight: '90vh', overflowY: 'auto' }}>
        <div className="modal-header">
          <div>
            <h2 style={{ fontSize: '1.25rem', fontWeight: 800 }}>Create New Event</h2>
            <p style={{ color: 'var(--text-secondary)', fontSize: '0.85rem' }}>Schedule a new chapter meeting or meetup</p>
          </div>
          <button type="button" className="modal-close-btn" onClick={onClose}>
            <IconX size={20} />
          </button>
        </div>

        <form onSubmit={handleSubmit} style={{ padding: '1.5rem 1.5rem 8rem' }}>
          {error && <div className="login-error" style={{ marginBottom: '1.25rem' }}>{error}</div>}

          <div style={{ display: 'grid', gridTemplateColumns: '1fr 1fr', gap: '1rem', marginBottom: '1.25rem' }}>
             <div>
              <label style={{ fontSize: '0.75rem', fontWeight: 700, color: 'var(--text-secondary)', textTransform: 'uppercase', marginBottom: '0.5rem', display: 'block' }}>Target Chapter *</label>
              <CustomSelect
                label="Choose a chapter..."
                value={formData.chapter_id}
                options={chapters}
                onChange={val => setFormData({ ...formData, chapter_id: val })}
              />
            </div>
            <div>
              <label style={{ fontSize: '0.75rem', fontWeight: 700, color: 'var(--text-secondary)', textTransform: 'uppercase', marginBottom: '0.5rem', display: 'block' }}>Event Type *</label>
              <CustomSelect
                label="Event Type..."
                value={formData.event_type}
                options={[
                  { id: 'flagship', name: 'Physical (Flagship)' },
                  { id: 'virtual', name: 'Online (Virtual)' },
                  { id: 'micro_meetup', name: 'Micro Meetup' }
                ]}
                onChange={val => setFormData({ ...formData, event_type: val })}
              />
            </div>
          </div>

          <div className="login-field">
            <label>Event Title *</label>
            <input
              type="text"
              className="filter-input v2"
              placeholder="e.g. Monthly Chapter Meeting"
              required
              value={formData.title}
              onChange={e => setFormData({ ...formData, title: e.target.value })}
            />
          </div>

          <div className="login-field">
            <label>Event Cover Image</label>
            <div style={{ display: 'flex', gap: '1rem', alignItems: 'center', marginBottom: '0.5rem' }}>
              <div style={{ width: 100, height: 60, borderRadius: '8px', background: '#f8fafc', overflow: 'hidden', display: 'flex', alignItems: 'center', justifyContent: 'center', border: '1px solid #e2e8f0' }}>
                {formData.image_url ? (
                  <img src={formData.image_url.startsWith('http') ? formData.image_url : `${STATIC_BASE_URL}${formData.image_url}`} style={{ width: '100%', height: '100%', objectFit: 'cover' }} />
                ) : (
                  <IconCalendarEvent size={24} color="#94a3b8" />
                )}
              </div>
              <div style={{ flex: 1 }}>
                <input
                  type="file"
                  id="event-image-upload"
                  accept="image/*"
                  style={{ display: 'none' }}
                  onChange={handleFileUpload}
                />
                <label 
                  htmlFor="event-image-upload" 
                  className="btn-secondary" 
                  style={{ display: 'inline-flex', alignItems: 'center', gap: '0.5rem', cursor: 'pointer', fontSize: '0.85rem', padding: '0.5rem 0.75rem' }}
                >
                  <IconPlus size={16} /> {uploading ? 'Uploading...' : formData.image_url ? 'Change Image' : 'Upload Cover'}
                </label>
                {formData.image_url && (
                  <button 
                    type="button" 
                    style={{ marginLeft: '0.5rem', fontSize: '0.75rem', color: '#ef4444', border: 'none', background: 'none', cursor: 'pointer', fontWeight: 600 }}
                    onClick={() => setFormData({ ...formData, image_url: '' })}
                  >
                    Remove
                  </button>
                )}
              </div>
            </div>
          </div>

          <div className="login-field">
            <label>Description</label>
            <textarea
              className="action-textarea"
              placeholder="What is this event about?"
              style={{ minHeight: 80 }}
              value={formData.description}
              onChange={e => setFormData({ ...formData, description: e.target.value })}
            />
          </div>

          <div style={{ display: 'grid', gridTemplateColumns: '1fr 1fr', gap: '1rem', marginBottom: '1.25rem' }}>
            <div className="login-field" style={{ marginBottom: 0 }}>
              <label>Location (Physical)</label>
              <input
                type="text"
                className="filter-input v2"
                placeholder="Hotel, Cafe, or Hall"
                value={formData.location}
                onChange={e => setFormData({ ...formData, location: e.target.value })}
              />
            </div>
            <div className="login-field" style={{ marginBottom: 0 }}>
              <label>Meeting Link (Virtual)</label>
              <input
                type="url"
                className="filter-input v2"
                placeholder="Zoom/Google Meet URL"
                value={formData.meeting_link}
                onChange={e => setFormData({ ...formData, meeting_link: e.target.value })}
              />
            </div>
          </div>

          <div style={{ display: 'grid', gridTemplateColumns: '1fr 1fr', gap: '1rem', marginBottom: '1.25rem' }}>
            <div className="login-field" style={{ marginBottom: 0 }}>
              <label>Start Time *</label>
              <DatePicker
                selected={formData.start_at}
                onChange={date => setFormData({ ...formData, start_at: date })}
                showTimeSelect
                timeFormat="HH:mm"
                dateFormat="MMMM d, yyyy h:mm aa"
                className="modern-datepicker-input"
                required
              />
            </div>
            <div className="login-field" style={{ marginBottom: 0 }}>
              <label>End Time *</label>
              <DatePicker
                selected={formData.end_at}
                onChange={date => setFormData({ ...formData, end_at: date })}
                showTimeSelect
                timeFormat="HH:mm"
                dateFormat="MMMM d, yyyy h:mm aa"
                className="modern-datepicker-input"
                required
                minDate={formData.start_at}
              />
            </div>
          </div>

          <div style={{ display: 'grid', gridTemplateColumns: '1fr 1fr', gap: '1rem', marginBottom: '1.5rem' }}>
            <div className="login-field" style={{ marginBottom: 0 }}>
              <label>Event Fee (LKR)</label>
              <input
                type="number"
                className="filter-input v2"
                value={formData.fee}
                onChange={e => setFormData({ ...formData, fee: e.target.value })}
              />
            </div>
            <div className="login-field" style={{ marginBottom: 0 }}>
              <label>Max Attendees</label>
              <input
                type="number"
                className="filter-input v2"
                placeholder="Unlimited"
                value={formData.max_attendees}
                onChange={e => setFormData({ ...formData, max_attendees: e.target.value })}
              />
            </div>
          </div>

          <div style={{ display: 'flex', gap: '1rem', marginTop: '1rem' }}>
            <button type="submit" className="login-btn" disabled={loading} style={{ flex: 2 }}>
              {loading ? 'Creating...' : 'Create & Publish Event'}
            </button>
            <button type="button" className="login-btn" onClick={onClose} style={{ flex: 1, background: '#94a3b8' }}>
              Cancel
            </button>
          </div>
        </form>
      </div>
    </div>
  );
}

function EditEventModal({ event, onClose, onUpdated, chapters = [] }) {
  const [formData, setFormData] = useState({
    chapter_id: event.chapter_id || '',
    title: event.title || '',
    description: event.description || '',
    event_type: event.event_type || 'flagship',
    location: event.location || '',
    meeting_link: event.meeting_link || '',
    start_at: new Date(event.start_at),
    end_at: new Date(event.end_at),
    fee: event.fee || 0,
    max_attendees: event.max_attendees || '',
    is_published: event.is_published ?? true,
    image_url: event.image_url || ''
  });
  const [loading, setLoading] = useState(false);
  const [uploading, setUploading] = useState(false);
  const [error, setError] = useState('');

  const handleFileUpload = async (e) => {
    const file = e.target.files[0];
    if (!file) return;
    setUploading(true);
    setError('');
    try {
      const result = await api.uploadEventImage(file);
      setFormData(prev => ({ ...prev, image_url: result.image_url }));
    } catch (err) {
      setError('Image upload failed: ' + err.message);
    } finally {
      setUploading(false);
    }
  };

  const handleSubmit = async (e) => {
    e.preventDefault();
    setLoading(true);
    setError('');
    try {
      await api.updateEvent(event.id, {
        ...formData,
        fee: parseFloat(formData.fee),
        max_attendees: formData.max_attendees ? parseInt(formData.max_attendees) : null,
        start_at: formData.start_at.toISOString(),
        end_at: formData.end_at.toISOString(),
      });
      onUpdated();
      onClose();
    } catch (err) {
      setError(err.message || 'Failed to update event');
    } finally {
      setLoading(false);
    }
  };

  return (
    <div className="modal-overlay" onClick={(e) => e.target === e.currentTarget && onClose()}>
      <div className="modal-content" onClick={e => e.stopPropagation()} style={{ maxWidth: 600, maxHeight: '90vh', overflowY: 'auto' }}>
        <div className="modal-header">
          <div>
            <h2 style={{ fontSize: '1.25rem', fontWeight: 800 }}>Edit Event</h2>
            <p style={{ color: 'var(--text-secondary)', fontSize: '0.85rem' }}>Update details for this meeting</p>
          </div>
          <button type="button" className="modal-close-btn" onClick={onClose}>
            <IconX size={20} />
          </button>
        </div>

        <form onSubmit={handleSubmit} style={{ padding: '1.5rem 1.5rem 8rem' }}>
          {error && <div className="login-error" style={{ marginBottom: '1.25rem' }}>{error}</div>}

          <div style={{ display: 'grid', gridTemplateColumns: '1fr 1fr', gap: '1rem', marginBottom: '1.25rem' }}>
             <div>
              <label style={{ fontSize: '0.75rem', fontWeight: 700, color: 'var(--text-secondary)', textTransform: 'uppercase', marginBottom: '0.5rem', display: 'block' }}>Target Chapter *</label>
              <CustomSelect
                label="Choose a chapter..."
                value={formData.chapter_id}
                options={chapters}
                onChange={val => setFormData({ ...formData, chapter_id: val })}
              />
            </div>
            <div>
              <label style={{ fontSize: '0.75rem', fontWeight: 700, color: 'var(--text-secondary)', textTransform: 'uppercase', marginBottom: '0.5rem', display: 'block' }}>Event Type *</label>
              <CustomSelect
                label="Event Type..."
                value={formData.event_type}
                options={[
                  { id: 'flagship', name: 'Physical (Flagship)' },
                  { id: 'virtual', name: 'Online (Virtual)' },
                  { id: 'micro_meetup', name: 'Micro Meetup' }
                ]}
                onChange={val => setFormData({ ...formData, event_type: val })}
              />
            </div>
          </div>

          <div className="login-field">
            <label>Event Title *</label>
            <input
              type="text"
              className="filter-input v2"
              required
              value={formData.title}
              onChange={e => setFormData({ ...formData, title: e.target.value })}
            />
          </div>

          <div className="login-field">
            <label>Event Cover Image</label>
            <div style={{ display: 'flex', gap: '1rem', alignItems: 'center', marginBottom: '0.5rem' }}>
              <div style={{ width: 100, height: 60, borderRadius: '8px', background: '#f8fafc', overflow: 'hidden', display: 'flex', alignItems: 'center', justifyContent: 'center', border: '1px solid #e2e8f0' }}>
                {formData.image_url ? (
                  <img src={formData.image_url.startsWith('http') ? formData.image_url : `${STATIC_BASE_URL}${formData.image_url}`} style={{ width: '100%', height: '100%', objectFit: 'cover' }} />
                ) : (
                  <IconCalendarEvent size={24} color="#94a3b8" />
                )}
              </div>
              <div style={{ flex: 1 }}>
                <input
                  type="file"
                  id="event-edit-image-upload"
                  accept="image/*"
                  style={{ display: 'none' }}
                  onChange={handleFileUpload}
                />
                <label 
                  htmlFor="event-edit-image-upload" 
                  className="btn-secondary" 
                  style={{ display: 'inline-flex', alignItems: 'center', gap: '0.5rem', cursor: 'pointer', fontSize: '0.85rem', padding: '0.5rem 0.75rem' }}
                >
                  <IconPlus size={16} /> {uploading ? 'Uploading...' : formData.image_url ? 'Change Image' : 'Upload Cover'}
                </label>
                {formData.image_url && (
                  <button 
                    type="button" 
                    style={{ marginLeft: '0.5rem', fontSize: '0.75rem', color: '#ef4444', border: 'none', background: 'none', cursor: 'pointer', fontWeight: 600 }}
                    onClick={() => setFormData({ ...formData, image_url: '' })}
                  >
                    Remove
                  </button>
                )}
              </div>
            </div>
          </div>

          <div className="login-field">
            <label>Description</label>
            <textarea
              className="action-textarea"
              style={{ minHeight: 80 }}
              value={formData.description}
              onChange={e => setFormData({ ...formData, description: e.target.value })}
            />
          </div>

          <div style={{ display: 'grid', gridTemplateColumns: '1fr 1fr', gap: '1rem', marginBottom: '1.25rem' }}>
            <div className="login-field" style={{ marginBottom: 0 }}>
              <label>Location (Physical)</label>
              <input
                type="text"
                className="filter-input v2"
                value={formData.location}
                onChange={e => setFormData({ ...formData, location: e.target.value })}
              />
            </div>
            <div className="login-field" style={{ marginBottom: 0 }}>
              <label>Meeting Link (Virtual)</label>
              <input
                type="url"
                className="filter-input v2"
                value={formData.meeting_link}
                onChange={e => setFormData({ ...formData, meeting_link: e.target.value })}
              />
            </div>
          </div>

          <div style={{ display: 'grid', gridTemplateColumns: '1fr 1fr', gap: '1rem', marginBottom: '1.25rem' }}>
            <div className="login-field" style={{ marginBottom: 0 }}>
              <label>Start Time *</label>
              <DatePicker
                selected={formData.start_at}
                onChange={date => setFormData({ ...formData, start_at: date })}
                showTimeSelect
                timeFormat="HH:mm"
                dateFormat="MMMM d, yyyy h:mm aa"
                className="modern-datepicker-input"
                required
              />
            </div>
            <div className="login-field" style={{ marginBottom: 0 }}>
              <label>End Time *</label>
              <DatePicker
                selected={formData.end_at}
                onChange={date => setFormData({ ...formData, end_at: date })}
                showTimeSelect
                timeFormat="HH:mm"
                dateFormat="MMMM d, yyyy h:mm aa"
                className="modern-datepicker-input"
                required
                minDate={formData.start_at}
              />
            </div>
          </div>

          <div style={{ display: 'grid', gridTemplateColumns: '1fr 1fr', gap: '1rem', marginBottom: '1.5rem' }}>
            <div className="login-field" style={{ marginBottom: 0 }}>
              <label>Event Fee (LKR)</label>
              <input
                type="number"
                className="filter-input v2"
                value={formData.fee}
                onChange={e => setFormData({ ...formData, fee: e.target.value })}
              />
            </div>
            <div className="login-field" style={{ marginBottom: 0 }}>
              <label>Max Attendees</label>
              <input
                type="number"
                className="filter-input v2"
                value={formData.max_attendees}
                onChange={e => setFormData({ ...formData, max_attendees: e.target.value })}
              />
            </div>
          </div>

          <div style={{ display: 'flex', gap: '1rem', marginTop: '1rem' }}>
            <button type="submit" className="login-btn" disabled={loading} style={{ flex: 2 }}>
              {loading ? 'Saving...' : 'Save Changes'}
            </button>
            <button type="button" className="login-btn" onClick={onClose} style={{ flex: 1, background: '#94a3b8' }}>
              Cancel
            </button>
          </div>
        </form>
      </div>
    </div>
  );
}

function ManageRsvpsModal({ event, onClose, onUpdated }) {
  const [loading, setLoading] = useState(false);
  const requestedRsvps = event.rsvps?.filter(r => r.status === 'requested') || [];
  const goingRsvps = event.rsvps?.filter(r => r.status === 'going') || [];

  const handleApprove = async (userId) => {
    try {
      setLoading(true);
      await api.approveRsvp(event.id, { user_id: userId, status: 'going' });
      onUpdated();
    } catch (e) {
      alert("Error: " + e.message);
    } finally {
      setLoading(false);
    }
  };

  const handleReject = async (userId) => {
    if (!window.confirm("Are you sure you want to reject this request?")) return;
    try {
      setLoading(true);
      await api.approveRsvp(event.id, { user_id: userId, status: 'not_going' });
      onUpdated();
    } catch (e) {
      alert("Error: " + e.message);
    } finally {
      setLoading(false);
    }
  };

  const getInitials = (name) => {
    if (!name) return 'U';
    return name.split(' ').map(n => n[0]).join('').substring(0, 2).toUpperCase();
  };

  return (
    <div className="modal-overlay">
      <div className="modal-content" style={{ width: '650px', maxHeight: '90vh', overflowY: 'auto', padding: 0 }}>
        
        {/* Header Section */}
        <div style={{ position: 'sticky', top: 0, padding: '1.5rem', background: 'white', borderBottom: '1px solid #e2e8f0', zIndex: 10, display: 'flex', justifyContent: 'space-between', alignItems: 'center' }}>
          <div>
            <h2 style={{ fontSize: '1.25rem', fontWeight: 800, color: '#0f172a' }}>Manage RSVPs</h2>
            <div style={{ fontSize: '0.85rem', color: '#64748b', marginTop: '0.2rem' }}>{event.title} • {event.rsvps?.length || 0} Total Responses</div>
          </div>
          <button onClick={onClose} style={{ background: '#f1f5f9', border: 'none', cursor: 'pointer', borderRadius: '50%', width: 36, height: 36, display: 'flex', alignItems: 'center', justifyContent: 'center' }}>
            <IconX size={20} color="#64748b" />
          </button>
        </div>
        
        <div style={{ padding: '1.5rem' }}>
          {/* Pending Section */}
          <div style={{ marginBottom: '2.5rem' }}>
            <div style={{ display: 'flex', alignItems: 'center', gap: '0.5rem', marginBottom: '1.2rem' }}>
              <h3 style={{ fontSize: '1rem', fontWeight: 800, color: '#b45309' }}>Pending Requests</h3>
              <span style={{ background: '#fef3c7', color: '#b45309', padding: '0.2rem 0.6rem', borderRadius: '999px', fontSize: '0.75rem', fontWeight: 700 }}>{requestedRsvps.length}</span>
            </div>
            
            {requestedRsvps.length === 0 ? (
              <div style={{ background: '#f8fafc', border: '1px dashed #cbd5e1', borderRadius: '12px', padding: '2rem', textAlign: 'center' }}>
                <IconClock size={32} color="#94a3b8" style={{ marginBottom: '0.5rem' }} />
                <div style={{ color: '#64748b', fontSize: '0.9rem', fontWeight: 500 }}>No pending requests at the moment.</div>
              </div>
            ) : (
              <div style={{ display: 'flex', flexDirection: 'column', gap: '0.8rem' }}>
                {requestedRsvps.map(r => (
                  <div key={r.user.id} style={{ display: 'flex', justifyContent: 'space-between', alignItems: 'center', border: '1px solid #e2e8f0', borderRadius: '12px', padding: '1rem', background: '#fff', boxShadow: '0 1px 3px rgba(0,0,0,0.02)' }}>
                     <div style={{ display: 'flex', alignItems: 'center', gap: '1rem' }}>
                       <div style={{ width: 40, height: 40, borderRadius: '50%', background: '#fef3c7', color: '#b45309', display: 'flex', alignItems: 'center', justifyContent: 'center', fontWeight: 'bold' }}>
                         {getInitials(r.user.full_name)}
                       </div>
                       <div>
                         <div style={{ fontWeight: 700, color: '#1e293b' }}>{r.user.full_name || 'Unknown User'}</div>
                         <div style={{ fontSize: '0.8rem', color: '#64748b', marginTop: '2px', display: 'flex', alignItems: 'center', gap: '0.25rem' }}>
                           <IconUser size={14} /> {r.user.phone_number}
                         </div>
                       </div>
                     </div>
                     <div style={{ display: 'flex', gap: '0.5rem' }}>
                       <button 
                         style={{ background: '#10b981', color: 'white', border: 'none', padding: '0.5rem 1rem', fontSize: '0.85rem', fontWeight: 600, borderRadius: '6px', cursor: 'pointer', display: 'flex', alignItems: 'center', gap: '4px' }} 
                         onClick={() => handleApprove(r.user.id)} disabled={loading}>
                           <IconCheck size={16} /> Approve
                       </button>
                       <button 
                         style={{ background: 'white', color: '#ef4444', border: '1px solid #fca5a5', padding: '0.5rem 1rem', fontSize: '0.85rem', fontWeight: 600, borderRadius: '6px', cursor: 'pointer' }} 
                         onClick={() => handleReject(r.user.id)} disabled={loading}>
                           Reject
                       </button>
                     </div>
                  </div>
                ))}
              </div>
            )}
          </div>
          
          {/* Confirmed Section */}
          <div>
            <div style={{ display: 'flex', alignItems: 'center', gap: '0.5rem', marginBottom: '1.2rem' }}>
              <h3 style={{ fontSize: '1rem', fontWeight: 800, color: '#15803d' }}>Confirmed Attendees</h3>
              <span style={{ background: '#dcfce7', color: '#15803d', padding: '0.2rem 0.6rem', borderRadius: '999px', fontSize: '0.75rem', fontWeight: 700 }}>{goingRsvps.length}</span>
            </div>

            {goingRsvps.length === 0 ? (
              <div style={{ background: '#f8fafc', border: '1px dashed #cbd5e1', borderRadius: '12px', padding: '2rem', textAlign: 'center' }}>
                <IconUserCheck size={32} color="#94a3b8" style={{ marginBottom: '0.5rem' }} />
                <div style={{ color: '#64748b', fontSize: '0.9rem', fontWeight: 500 }}>No attendees have been confirmed yet.</div>
              </div>
            ) : (
              <div style={{ display: 'flex', flexDirection: 'column', gap: '0.8rem' }}>
                 {goingRsvps.map(r => (
                   <div key={r.user.id} style={{ display: 'flex', justifyContent: 'space-between', alignItems: 'center', border: '1px solid #e2e8f0', borderRadius: '12px', padding: '1rem', background: '#f8fafc' }}>
                      <div style={{ display: 'flex', alignItems: 'center', gap: '1rem' }}>
                       <div style={{ width: 40, height: 40, borderRadius: '50%', background: '#e2e8f0', color: '#475569', display: 'flex', alignItems: 'center', justifyContent: 'center', fontWeight: 'bold' }}>
                         {getInitials(r.user.full_name)}
                       </div>
                       <div>
                         <div style={{ fontWeight: 600, color: '#1e293b' }}>{r.user.full_name || 'Unknown User'}</div>
                         <div style={{ fontSize: '0.8rem', color: '#64748b', marginTop: '2px', display: 'flex', alignItems: 'center', gap: '0.25rem' }}>
                           <IconUser size={14} /> {r.user.phone_number}
                         </div>
                       </div>
                     </div>
                     <span style={{ background: '#dcfce7', color: '#15803d', padding: '0.3rem 0.8rem', borderRadius: '999px', fontSize: '0.75rem', fontWeight: 700, display: 'flex', alignItems: 'center', gap: '4px' }}><IconCheck size={14} /> Attending</span>
                   </div>
                 ))}
              </div>
            )}
          </div>
        </div>
      </div>
    </div>
  );
}

function EventActionMenu({ event, onManageRsvps, onEdit }) {
  const [isOpen, setIsOpen] = useState(false);
  const menuRef = useRef(null);

  useEffect(() => {
    const handleClickOutside = (e) => {
      if (menuRef.current && !menuRef.current.contains(e.target)) setIsOpen(false);
    };
    document.addEventListener('mousedown', handleClickOutside);
    return () => document.removeEventListener('mousedown', handleClickOutside);
  }, []);

  return (
    <div className="action-menu-container" ref={menuRef}>
      <button className="view-detail-btn" title="Actions" onClick={() => setIsOpen(!isOpen)}>
        <IconSettings size={20} />
      </button>
      
      {isOpen && (
        <div className="action-dropdown" style={{ right: 0, left: 'auto' }}>
          <button className="action-item" onClick={() => { onManageRsvps(); setIsOpen(false); }}>
            <IconUserCheck size={16} /> Manage RSVPs
          </button>
          <button className="action-item" onClick={() => { onEdit(); setIsOpen(false); }}>
            <IconPencil size={16} /> Edit Event
          </button>
        </div>
      )}
    </div>
  );
}

function EventsPage() {
  const [events, setEvents] = useState([]);
  const [loading, setLoading] = useState(true);
  const [showAddModal, setShowAddModal] = useState(false);
  const [editingEvent, setEditingEvent] = useState(null);
  const [managingRsvpsEvent, setManagingRsvpsEvent] = useState(null);
  const [chapters, setChapters] = useState([]);
  const [chapterFilter, setChapterFilter] = useState('');
  const [timeFilter, setTimeFilter] = useState('upcoming');


  const fetchEvents = useCallback(async () => {
    setLoading(true);
    try {
      const params = {};
      if (chapterFilter) params.chapter_id = chapterFilter;
      params.published_only = false;
      const data = await api.listEvents(params);
      setEvents(data || []);
    } catch (err) {
      console.error('Failed to load events:', err);
    } finally {
      setLoading(false);
    }
  }, [chapterFilter]);

  useEffect(() => {
    fetchEvents();
    api.listChapters().then(data => setChapters(data || []));
  }, [fetchEvents]);

  const filteredEvents = events.filter(ev => {
    const isPast = new Date(ev.end_at) < new Date();
    if (timeFilter === 'upcoming') return !isPast;
    if (timeFilter === 'finished') return isPast;
    return true;
  });

  return (
    <section className="ds-page">
      <Ds.PageHeader
        title="Event Management"
        description="Schedule and manage chapter meetings, micro-meetups, and virtual sessions."
        actions={
          <>
            <Ds.Button
              variant="secondary"
              leftIcon={<IconRefresh size={14} />}
              onClick={fetchEvents}
            >
              Refresh
            </Ds.Button>
            <Ds.Button
              variant="primary"
              leftIcon={<IconPlus size={14} />}
              onClick={() => setShowAddModal(true)}
            >
              New event
            </Ds.Button>
          </>
        }
      />

      <Ds.Section
        title="Event Calendar"
        subtitle={`${filteredEvents.length} event${filteredEvents.length === 1 ? '' : 's'}`}
        flush
        actions={
          <>
            <Ds.Select
              placeholder="All chapters"
              value={chapterFilter}
              options={chapters}
              allowClear
              onChange={setChapterFilter}
              style={{ width: 200 }}
              size="sm"
            />
            <Ds.ChipGroup
              value={timeFilter}
              onChange={setTimeFilter}
              options={[
                { value: 'upcoming', label: 'Upcoming' },
                { value: 'finished', label: 'Past' },
                { value: 'all', label: 'All' },
              ]}
            />
          </>
        }
      >
        <Ds.Table>
          <thead>
            <tr>
              <th>Event</th>
              <th>Type</th>
              <th>Date</th>
              <th>Location</th>
              <th>Fee</th>
              <th>RSVPs</th>
              <th className="ds-table__actions" />
            </tr>
          </thead>
          <tbody>
            {loading ? (
              <Ds.Table.LoadingRow colSpan={7} label="Loading events…" />
            ) : filteredEvents.length === 0 ? (
              <Ds.Table.EmptyRow
                colSpan={7}
                icon={IconCalendarEvent}
                title={`No ${timeFilter !== 'all' ? timeFilter : ''} events`}
                description="Create one to get started."
              />
            ) : filteredEvents.map(ev => {
              const isPast = new Date(ev.end_at) < new Date();
              return (
                <tr key={ev.id} style={{ opacity: isPast ? 0.7 : 1 }}>
                  <td>
                    <div style={{ display: 'flex', alignItems: 'center', gap: 'var(--space-3)' }}>
                      <div style={{
                        width: 40, height: 40,
                        borderRadius: 'var(--radius-md)',
                        background: 'var(--bg-subtle)',
                        overflow: 'hidden',
                        border: '1px solid var(--border-subtle)',
                        flexShrink: 0,
                        display: 'flex', alignItems: 'center', justifyContent: 'center',
                      }}>
                        {ev.image_url ? (
                          <img
                            src={ev.image_url.startsWith('http') ? ev.image_url : `${STATIC_BASE_URL}${ev.image_url}`}
                            alt=""
                            style={{ width: '100%', height: '100%', objectFit: 'cover' }}
                          />
                        ) : (
                          <IconCalendarEvent size={16} color="var(--fg-muted)" />
                        )}
                      </div>
                      <div style={{ minWidth: 0 }}>
                        <div style={{ display: 'flex', alignItems: 'center', gap: 6 }}>
                          <span className="ds-table__primary">{ev.title}</span>
                          <Ds.Badge dot variant={isPast ? 'neutral' : 'success'}>
                            {isPast ? 'Past' : 'Live'}
                          </Ds.Badge>
                        </div>
                        <div style={{ fontSize: 'var(--text-xs)', color: 'var(--fg-muted)', fontWeight: 'var(--weight-medium)' }}>
                          ID: {ev.id.slice(0, 8)}
                        </div>
                      </div>
                    </div>
                  </td>
                  <td>
                    <Ds.Badge variant={ev.event_type === 'flagship' ? 'accent' : 'neutral'}>
                      {ev.event_type}
                    </Ds.Badge>
                  </td>
                  <td>
                    <div className="ds-table__primary">{new Date(ev.start_at).toLocaleDateString()}</div>
                    <div style={{ fontSize: 'var(--text-xs)', color: 'var(--fg-muted)' }}>
                      {new Date(ev.start_at).toLocaleTimeString([], { hour: '2-digit', minute: '2-digit' })}
                    </div>
                  </td>
                  <td className="ds-table__muted" style={{ maxWidth: 220, overflow: 'hidden', textOverflow: 'ellipsis' }}>
                    {ev.location || ev.meeting_link || '—'}
                  </td>
                  <td className="ds-table__primary" style={{ fontWeight: 'var(--weight-bold)' }}>
                    {ev.fee > 0 ? formatCurrency(ev.fee) : 'Free'}
                  </td>
                  <td>
                    <div style={{ display: 'flex', alignItems: 'baseline', gap: 4 }}>
                      <span style={{ fontWeight: 'var(--weight-bold)', fontSize: 'var(--text-base)' }}>
                        {ev.rsvps?.filter(r => r.status === 'going').length || 0}
                      </span>
                      <span style={{ fontSize: 'var(--text-xs)', color: 'var(--fg-muted)' }}>going</span>
                    </div>
                  </td>
                  <td className="ds-table__actions">
                    <EventActionMenu
                      event={ev}
                      onManageRsvps={() => setManagingRsvpsEvent(ev)}
                      onEdit={() => setEditingEvent(ev)}
                    />
                  </td>
                </tr>
              );
            })}
          </tbody>
        </Ds.Table>
      </Ds.Section>

      {showAddModal && (
        <AddEventModal
          chapters={chapters}
          onClose={() => setShowAddModal(false)}
          onCreated={() => {
            setShowAddModal(false);
            fetchEvents();
          }}
        />
      )}

      {editingEvent && (
        <EditEventModal
          event={editingEvent}
          chapters={chapters}
          onClose={() => setEditingEvent(null)}
          onUpdated={fetchEvents}
        />
      )}

      {managingRsvpsEvent && (
        <ManageRsvpsModal
          event={events.find(e => e.id === managingRsvpsEvent.id) || managingRsvpsEvent}
          onClose={() => setManagingRsvpsEvent(null)}
          onUpdated={fetchEvents}
        />
      )}

    </section>
  );
}



function AddClubModal({ onClose, onCreated, club }) {
  const [formData, setFormData] = useState({
    name: club?.name || '',
    description: club?.description || '',
    industry_ids: club?.industry_ids || [], // Note: backend needs to return IDs for easy editing
    min_members: club?.min_members || 10
  });
  const [industries, setIndustries] = useState([]);
  const [loading, setLoading] = useState(false);
  const [loadingInitial, setLoadingInitial] = useState(true);

  useEffect(() => {
    api.listIndustryCategories().then(data => {
      setIndustries(data || []);
      // If we are editing, we might need to fetch the current club's industry IDs 
      // if they aren't already in the 'club' prop.
      // But for now let's assume they are passed or we fetch them.
      setLoadingInitial(false);
    });
  }, []);

  // Ensure industry_ids are populated if editing
  useEffect(() => {
    if (club && industries.length > 0) {
      // If the backend list_clubs didn't include IDs, we might need to map names back to IDs
      // or ensure the backend list_clubs includes them. 
      // I updated the backend service to return 'industries' as names, 
      // I should probably update it to return IDs too.
    }
  }, [club, industries]);

  const handleSubmit = async (e) => {
    e.preventDefault();
    if (formData.industry_ids.length === 0) {
      alert("Please select at least one industry category.");
      return;
    }
    setLoading(true);
    try {
      if (club) {
        await api.updateClub(club.id, formData);
      } else {
        await api.createClub(formData);
      }
      onCreated();
    } catch (err) {
      alert(err.message);
    } finally {
      setLoading(false);
    }
  };

  const toggleIndustry = (id) => {
    setFormData(prev => {
      const ids = prev.industry_ids.includes(id)
        ? prev.industry_ids.filter(i => i !== id)
        : [...prev.industry_ids, id];
      return { ...prev, industry_ids: ids };
    });
  };

  return (
    <div className="modal-overlay" onClick={(e) => e.target === e.currentTarget && onClose()}>
      <div className="modal-content" onClick={e => e.stopPropagation()} style={{ maxWidth: 550, maxHeight: '90vh', display: 'flex', flexDirection: 'column' }}>
        <div className="modal-header">
          <div>
            <h2 style={{ fontSize: '1.25rem', fontWeight: 800 }}>{club ? 'Edit Horizontal Club' : 'New Horizontal Club'}</h2>
            <p style={{ color: 'var(--text-secondary)', fontSize: '0.85rem' }}>
              {club ? `Modifying settings for ${club.name}` : 'Establish a new national industry vertical'}
            </p>
          </div>
          <button type="button" className="modal-close-btn" onClick={onClose}>
            <IconX size={20} />
          </button>
        </div>

        <form onSubmit={handleSubmit} style={{ padding: '1.5rem', overflowY: 'auto', flex: 1 }}>
          <div className="login-field">
            <label>Club Name *</label>
            <input
              type="text"
              className="filter-input v2"
              placeholder="e.g., Real Estate Investment Club"
              required
              value={formData.name}
              onChange={e => setFormData({ ...formData, name: e.target.value })}
            />
          </div>

          <div className="login-field">
            <label>Eligibility: Industry Categories *</label>
            <p style={{ fontSize: '0.75rem', color: '#64748b', marginBottom: '0.8rem' }}>
              Select which member industries are allowed to join this club.
            </p>
            {loadingInitial ? (
              <div style={{ padding: '1rem', textAlign: 'center', color: '#94a3b8' }}>Loading industries...</div>
            ) : (
              <div style={{ 
                display: 'grid', 
                gridTemplateColumns: '1fr 1fr', 
                gap: '0.5rem', 
                maxHeight: '200px', 
                overflowY: 'auto', 
                padding: '1rem', 
                background: '#f8fafc', 
                borderRadius: '12px',
                border: '1px solid #e2e8f0'
              }}>
                {industries.map(ind => (
                  <label key={ind.id} style={{ 
                    display: 'flex', 
                    alignItems: 'center', 
                    gap: '0.6rem', 
                    fontSize: '0.85rem', 
                    padding: '0.4rem', 
                    borderRadius: '6px',
                    cursor: 'pointer',
                    transition: 'all 0.2s',
                    background: formData.industry_ids.includes(ind.id) ? '#dbeafe' : 'transparent',
                    border: formData.industry_ids.includes(ind.id) ? '1px solid #3b82f6' : '1px solid transparent'
                  }}>
                    <input 
                      type="checkbox" 
                      checked={formData.industry_ids.includes(ind.id)}
                      onChange={() => toggleIndustry(ind.id)}
                      style={{ width: '16px', height: '16px' }}
                    />
                    <span style={{ fontWeight: 500, color: formData.industry_ids.includes(ind.id) ? '#1e40af' : 'var(--text-primary)' }}>{ind.name}</span>
                  </label>
                ))}
              </div>
            )}
          </div>

          <div className="login-field">
            <label>Description</label>
            <textarea
              className="action-textarea"
              placeholder="Brief overview of the club goals..."
              value={formData.description}
              onChange={e => setFormData({ ...formData, description: e.target.value })}
              style={{ minHeight: 80 }}
            />
          </div>

          <div className="login-field">
            <label>Minimum Members for Activation</label>
            <input
              type="number"
              className="filter-input v2"
              value={formData.min_members}
              onChange={e => setFormData({ ...formData, min_members: parseInt(e.target.value) || 10 })}
            />
          </div>

          <div style={{ display: 'flex', gap: '1rem', marginTop: '1rem' }}>
            <button type="submit" className="login-btn" disabled={loading} style={{ flex: 2 }}>
              {loading ? 'Processing...' : (club ? 'Update Settings' : 'Establish Club')}
            </button>
            <button type="button" className="login-btn" onClick={onClose} style={{ flex: 1, background: '#94a3b8' }}>
              Cancel
            </button>
          </div>
        </form>
      </div>
    </div>
  );
}

function ClubActionMenu({ club, onEdit, onDelete }) {
  const [isOpen, setIsOpen] = useState(false);
  const menuRef = useRef(null);

  useEffect(() => {
    const handleClickOutside = (e) => {
      if (menuRef.current && !menuRef.current.contains(e.target)) setIsOpen(false);
    };
    document.addEventListener('mousedown', handleClickOutside);
    return () => document.removeEventListener('mousedown', handleClickOutside);
  }, []);

  return (
    <div className="action-menu-container" ref={menuRef}>
      <button className="view-detail-btn" title="Actions" onClick={() => setIsOpen(!isOpen)}>
        <IconSettings size={20} />
      </button>
      
      {isOpen && (
        <div className="action-dropdown" style={{ right: 0, left: 'auto' }}>
          <button className="action-item" onClick={() => { onEdit(); setIsOpen(false); }}>
            <IconPencil size={16} /> Edit Club
          </button>
          <div className="action-divider" />
          <button className="action-item danger" onClick={() => { onDelete(); setIsOpen(false); }}>
            <IconTrash size={16} /> Delete Club
          </button>
        </div>
      )}
    </div>
  );
}

function ClubsPage() {
  const [clubs, setClubs] = useState([]);
  const [loading, setLoading] = useState(true);
  const [showAddModal, setShowAddModal] = useState(false);
  const [editingClub, setEditingClub] = useState(null);

  const fetchClubs = useCallback(async () => {
    setLoading(true);
    try {
      const data = await api.listClubs();
      setClubs(data || []);
    } catch (err) {
      console.error('Failed to load clubs:', err);
    } finally {
      setLoading(false);
    }
  }, []);

  useEffect(() => { fetchClubs(); }, [fetchClubs]);

  return (
    <section className="ds-page">
      <Ds.PageHeader
        title="Horizontal Clubs"
        description="Cross-chapter industry verticals for targeted business collaboration."
        actions={
          <>
            <Ds.Button
              variant="secondary"
              leftIcon={<IconRefresh size={14} />}
              onClick={fetchClubs}
            >
              Refresh
            </Ds.Button>
            <Ds.Button
              variant="primary"
              leftIcon={<IconPlus size={14} />}
              onClick={() => setShowAddModal(true)}
            >
              New club
            </Ds.Button>
          </>
        }
      />

      <Ds.Section title="Active Verticals" flush>
        <Ds.Table>
          <thead>
            <tr>
              <th>Club</th>
              <th>Industry verticals</th>
              <th>Requirement</th>
              <th>Status</th>
              <th>Description</th>
              <th className="ds-table__actions" />
            </tr>
          </thead>
          <tbody>
            {loading ? (
              <Ds.Table.LoadingRow colSpan={6} label="Loading clubs…" />
            ) : clubs.length === 0 ? (
              <Ds.Table.EmptyRow
                colSpan={6}
                icon={IconHierarchy2}
                title="No clubs established"
                description="Create the first horizontal club to enable cross-chapter collaboration."
              />
            ) : clubs.map(club => (
              <tr key={club.id}>
                <td style={{ fontWeight: 'var(--weight-bold)', color: 'var(--brand-navy)' }}>
                  {club.name}
                </td>
                <td>
                  <div style={{ display: 'flex', flexWrap: 'wrap', gap: 4 }}>
                    {club.industries?.length
                      ? club.industries.map(ind => (
                          <Ds.Badge key={ind} variant="neutral">{ind}</Ds.Badge>
                        ))
                      : '—'}
                  </div>
                </td>
                <td className="ds-table__primary">{club.min_members}+ members</td>
                <td>
                  <Ds.Badge dot variant={club.is_active ? 'success' : 'danger'}>
                    {club.is_active ? 'Active' : 'Inactive'}
                  </Ds.Badge>
                </td>
                <td className="ds-table__muted" style={{ maxWidth: 280, overflow: 'hidden', textOverflow: 'ellipsis' }}>
                  {club.description || '—'}
                </td>
                <td className="ds-table__actions">
                  <ClubActionMenu
                    club={club}
                    onEdit={() => { setEditingClub(club); setShowAddModal(true); }}
                    onDelete={async () => {
                      if (confirm(`Are you sure you want to delete "${club.name}"?`)) {
                        await api.deleteClub(club.id);
                        fetchClubs();
                      }
                    }}
                  />
                </td>
              </tr>
            ))}
          </tbody>
        </Ds.Table>
      </Ds.Section>

      {showAddModal && (
        <AddClubModal
          club={editingClub}
          onClose={() => {
            setShowAddModal(false);
            setEditingClub(null);
          }}
          onCreated={() => {
            setShowAddModal(false);
            setEditingClub(null);
            fetchClubs();
          }}
        />
      )}
    </section>
  );
}

// ── Main App ────────────────────────────────────────────────────────────────

function ListingActionMenu({ listing, onViewInterests, onPreview, onApprove, onReject, onToggleStatus, onDelete }) {
  const [isOpen, setIsOpen] = useState(false);
  const menuRef = useRef(null);

  useEffect(() => {
    const handleClickOutside = (e) => {
      if (menuRef.current && !menuRef.current.contains(e.target)) setIsOpen(false);
    };
    document.addEventListener('mousedown', handleClickOutside);
    return () => document.removeEventListener('mousedown', handleClickOutside);
  }, []);

  return (
    <div className="action-menu-container" ref={menuRef}>
      <button className="view-detail-btn" title="Actions" onClick={() => setIsOpen(!isOpen)}>
        <IconSettings size={20} />
      </button>
      
      {isOpen && (
        <div className="action-dropdown" style={{ right: 0, left: 'auto' }}>
          <button className="action-item" onClick={() => { onPreview(); setIsOpen(false); }}>
            <IconEye size={16} /> View Details
          </button>
          <button className="action-item" onClick={() => { onViewInterests(); setIsOpen(false); }}>
            <IconClipboardList size={16} /> Interests
          </button>
          
          <div className="action-divider" />
          
          {!listing.is_approved ? (
            <button className="action-item" style={{ color: '#059669' }} onClick={() => { onApprove(); setIsOpen(false); }}>
              <IconCheck size={16} /> Approve
            </button>
          ) : (
            <button className="action-item" style={{ color: '#ef4444' }} onClick={() => { onReject(); setIsOpen(false); }}>
              <IconX size={16} /> Reject
            </button>
          )}

          <button className="action-item" onClick={() => { onToggleStatus(); setIsOpen(false); }}>
            {listing.status === 'active' ? (
              <><IconLock size={16} /> Pause Listing</>
            ) : (
              <><IconRefresh size={16} /> Activate Listing</>
            )}
          </button>

          <div className="action-divider" />
          <button className="action-item danger" onClick={() => { onDelete(); setIsOpen(false); }}>
            <IconTrash size={16} /> Delete Listing
          </button>
        </div>
      )}
    </div>
  );
}

function MarketplacePage() {
  const [listings, setListings] = useState([]);
  const [loading, setLoading] = useState(true);
  const [statusFilter, setStatusFilter] = useState('');
  const [selectedListing, setSelectedListing] = useState(null);
  const [showInterestsModal, setShowInterestsModal] = useState(false);
  const [interests, setInterests] = useState([]);
  const [loadingInterests, setLoadingInterests] = useState(false);
  const [approvalFilter, setApprovalFilter] = useState('pending');
  const [showRejectModal, setShowRejectModal] = useState(false);
  const [rejectionReason, setRejectionReason] = useState('');

  const fetchListings = useCallback(async () => {
    setLoading(true);
    try {
      const params = {};
      if (statusFilter) params.status = statusFilter;
      if (approvalFilter === 'pending') params.is_approved = false;
      else if (approvalFilter === 'approved') params.is_approved = true;
      
      const data = await api.adminListMarketplaceListings(params);
      setListings(data.listings || []);
    } catch (err) {
      console.error('Failed to load listings:', err);
    } finally {
      setLoading(false);
    }
  }, [statusFilter, approvalFilter]);

  useEffect(() => { fetchListings(); }, [fetchListings]);

  const toggleFeatured = async (id, current) => {
    try {
      await api.featureMarketplaceListing(id, !current);
      setListings(prev => prev.map(l => l.id === id ? { ...l, is_featured: !current } : l));
    } catch (err) {
      alert(err.message);
    }
  };

  const updateStatus = async (id, status) => {
    try {
      await api.updateMarketplaceListing(id, { status });
      setListings(prev => prev.map(l => l.id === id ? { ...l, status } : l));
    } catch (err) {
      alert(err.message);
    }
  };

  const deleteListing = async (id) => {
    if (!confirm('Are you sure you want to delete this listing permanently?')) return;
    try {
      await api.deleteMarketplaceListing(id);
      setListings(prev => prev.filter(l => l.id !== id));
    } catch (err) {
      alert(err.message);
    }
  };

  const viewInterests = async (listing) => {
    setSelectedListing(listing);
    setShowInterestsModal(true);
    setLoadingInterests(true);
    try {
      const data = await api.listMarketplaceInterests(listing.id);
      setInterests(data || []);
    } catch (err) {
      console.error('Failed to load interests:', err);
    } finally {
      setLoadingInterests(false);
    }
  };

  const handleApprove = async (id) => {
    try {
      await api.approveMarketplaceListing(id);
      setListings(prev => prev.map(l => l.id === id ? { ...l, is_approved: true, rejection_reason: null } : l));
    } catch (err) {
      alert(err.message);
    }
  };

  const handleReject = async () => {
    if (!rejectionReason || rejectionReason.length < 5) return alert('Please provide a valid reason');
    try {
      await api.rejectMarketplaceListing(selectedListing.id, rejectionReason);
      setListings(prev => prev.map(l => l.id === selectedListing.id ? { ...l, is_approved: false, rejection_reason: rejectionReason } : l));
      setShowRejectModal(false);
      setRejectionReason('');
    } catch (err) {
      alert(err.message);
    }
  };

  return (
    <section className="ds-page">
      <Ds.PageHeader
        title="Marketplace"
        description="Manage member listings, feature premium deals, and monitor marketplace activity."
        actions={
          <Ds.Button
            variant="secondary"
            leftIcon={<IconRefresh size={14} />}
            onClick={fetchListings}
          >
            Refresh
          </Ds.Button>
        }
      />

      <Ds.Section
        title="Global Listings"
        subtitle={`${listings.length} ${listings.length === 1 ? 'listing' : 'listings'}`}
        flush
        actions={
          <>
            <Ds.Select
              placeholder="All status"
              value={statusFilter}
              options={[
                { id: 'active', name: 'Active' },
                { id: 'paused', name: 'Paused' },
                { id: 'sold', name: 'Sold' },
              ]}
              allowClear
              onChange={setStatusFilter}
              style={{ width: 160 }}
              size="sm"
            />
            <Ds.ChipGroup
              value={approvalFilter}
              onChange={setApprovalFilter}
              options={[
                { value: 'pending', label: 'Pending' },
                { value: 'approved', label: 'Approved' },
                { value: '', label: 'All' },
              ]}
            />
          </>
        }
      >
        <Ds.Table>
          <thead>
            <tr>
              <th style={{ width: 40 }} />
              <th>Listing</th>
              <th>Seller</th>
              <th>Category</th>
              <th>Approval</th>
              <th>Price</th>
              <th>Status</th>
              <th className="ds-table__actions" />
            </tr>
          </thead>
          <tbody>
            {loading ? (
              <Ds.Table.LoadingRow colSpan={8} label="Loading marketplace…" />
            ) : listings.length === 0 ? (
              <Ds.Table.EmptyRow
                colSpan={8}
                icon={IconBuildingStore}
                title="No listings found"
                description="Adjust filters to see more listings."
              />
            ) : listings.map(l => (
              <tr key={l.id}>
                <td>
                  <Ds.IconButton
                    aria-label={l.is_featured ? 'Unfeature' : 'Feature'}
                    onClick={() => toggleFeatured(l.id, l.is_featured)}
                    style={{ color: l.is_featured ? 'var(--brand-amber)' : 'var(--neutral-300)' }}
                  >
                    {l.is_featured ? <IconStarFilled size={18} /> : <IconStar size={18} />}
                  </Ds.IconButton>
                </td>
                <td>
                  <div style={{ display: 'flex', alignItems: 'center', gap: 'var(--space-3)' }}>
                    <div style={{
                      width: 44, height: 44,
                      borderRadius: 'var(--radius-md)',
                      background: 'var(--bg-subtle)',
                      overflow: 'hidden',
                      border: '1px solid var(--border-subtle)',
                      flexShrink: 0,
                      display: 'flex', alignItems: 'center', justifyContent: 'center',
                    }}>
                      {l.image_urls && l.image_urls.length > 0 ? (
                        <img
                          src={l.image_urls[0].startsWith('http') ? l.image_urls[0] : `${STATIC_BASE_URL}${l.image_urls[0]}`}
                          alt=""
                          style={{ width: '100%', height: '100%', objectFit: 'cover' }}
                        />
                      ) : (
                        <IconBuildingStore size={18} color="var(--fg-muted)" />
                      )}
                    </div>
                    <div style={{ minWidth: 0 }}>
                      <div className="ds-table__primary">{l.title}</div>
                      <div style={{ fontSize: 'var(--text-xs)', color: 'var(--fg-muted)', fontWeight: 'var(--weight-medium)' }}>
                        ID: {String(l.id).slice(0, 8)}
                      </div>
                    </div>
                  </div>
                </td>
                <td>
                  <div className="ds-table__primary">{l.seller?.full_name || 'Unknown'}</div>
                  <div style={{ fontSize: 'var(--text-xs)', color: 'var(--fg-muted)' }}>
                    {l.seller?.business_name || '—'}
                  </div>
                </td>
                <td>
                  <Ds.Badge variant="neutral">{l.category || 'General'}</Ds.Badge>
                </td>
                <td>
                  <Ds.Badge dot variant={l.is_approved ? 'success' : 'warning'}>
                    {l.is_approved ? 'Verified' : 'Pending'}
                  </Ds.Badge>
                  {l.rejection_reason && (
                    <div style={{ fontSize: 'var(--text-xs)', color: 'var(--danger)', marginTop: 4, maxWidth: 140 }}>
                      Reason: {l.rejection_reason}
                    </div>
                  )}
                </td>
                <td className="ds-table__primary" style={{ fontWeight: 'var(--weight-bold)' }}>
                  {formatCurrency(l.price)}
                </td>
                <td>
                  <Ds.Badge dot variant={l.status === 'active' ? 'success' : l.status === 'paused' ? 'warning' : 'danger'}>
                    {l.status}
                  </Ds.Badge>
                </td>
                <td className="ds-table__actions">
                  <ListingActionMenu
                    listing={l}
                    onViewInterests={() => viewInterests(l)}
                    onPreview={() => setSelectedListing(l)}
                    onApprove={() => handleApprove(l.id)}
                    onReject={() => { setSelectedListing(l); setShowRejectModal(true); }}
                    onToggleStatus={() => updateStatus(l.id, l.status === 'active' ? 'paused' : 'active')}
                    onDelete={() => deleteListing(l.id)}
                  />
                </td>
              </tr>
            ))}
          </tbody>
        </Ds.Table>
      </Ds.Section>

      {selectedListing && !showInterestsModal && !showRejectModal && (
        <Ds.Modal open size="lg" onClose={() => setSelectedListing(null)}>
          <Ds.Modal.Header
            title="Listing Preview"
            subtitle="Review all details before approval"
            onClose={() => setSelectedListing(null)}
          />
          <Ds.Modal.Body>
            <div style={{ display: 'grid', gridTemplateColumns: '1fr 1fr', gap: 'var(--space-6)' }}>
              <div>
                <div style={{
                  width: '100%', aspectRatio: '1/1',
                  borderRadius: 'var(--radius-lg)',
                  overflow: 'hidden',
                  background: 'var(--bg-subtle)',
                  border: '1px solid var(--border-subtle)',
                  display: 'flex', alignItems: 'center', justifyContent: 'center',
                }}>
                  {selectedListing.image_urls && selectedListing.image_urls.length > 0 ? (
                    <img
                      src={selectedListing.image_urls[0].startsWith('http') ? selectedListing.image_urls[0] : `${STATIC_BASE_URL}${selectedListing.image_urls[0]}`}
                      alt=""
                      style={{ width: '100%', height: '100%', objectFit: 'cover' }}
                    />
                  ) : (
                    <IconBuildingStore size={40} color="var(--neutral-300)" />
                  )}
                </div>
                {selectedListing.image_urls?.length > 1 && (
                  <div style={{ display: 'flex', gap: 'var(--space-2)', marginTop: 'var(--space-3)', overflowX: 'auto' }}>
                    {selectedListing.image_urls.map((url, i) => (
                      <div key={i} style={{
                        width: 56, height: 56,
                        borderRadius: 'var(--radius-sm)',
                        overflow: 'hidden',
                        border: '1px solid var(--border-subtle)',
                        flexShrink: 0,
                      }}>
                        <img
                          src={url.startsWith('http') ? url : `${STATIC_BASE_URL}${url}`}
                          alt=""
                          style={{ width: '100%', height: '100%', objectFit: 'cover' }}
                        />
                      </div>
                    ))}
                  </div>
                )}
              </div>

              <div>
                <Ds.Badge variant="neutral">{selectedListing.category}</Ds.Badge>
                <h3 style={{ fontSize: 'var(--text-2xl)', fontWeight: 'var(--weight-bold)', marginTop: 'var(--space-2)', letterSpacing: 'var(--tracking-tight)' }}>
                  {selectedListing.title}
                </h3>
                <p style={{ fontSize: 'var(--text-base)', color: 'var(--fg-secondary)', marginTop: 'var(--space-2)', lineHeight: 'var(--leading-relaxed)' }}>
                  {selectedListing.description}
                </p>

                <div style={{ display: 'grid', gridTemplateColumns: '1fr 1fr', gap: 'var(--space-3)', marginTop: 'var(--space-5)' }}>
                  <div style={{ padding: 'var(--space-3) var(--space-4)', background: 'var(--bg-subtle)', borderRadius: 'var(--radius-md)' }}>
                    <p style={{ fontSize: 'var(--text-xs)', color: 'var(--fg-muted)', fontWeight: 'var(--weight-semibold)', textTransform: 'uppercase', letterSpacing: 'var(--tracking-wide)' }}>
                      Regular price
                    </p>
                    <p style={{ fontSize: 'var(--text-lg)', fontWeight: 'var(--weight-bold)', color: 'var(--fg-primary)', marginTop: 4 }}>
                      {formatCurrency(selectedListing.price)}
                    </p>
                  </div>
                  <div style={{ padding: 'var(--space-3) var(--space-4)', background: 'var(--success-bg)', borderRadius: 'var(--radius-md)' }}>
                    <p style={{ fontSize: 'var(--text-xs)', color: 'var(--success)', fontWeight: 'var(--weight-semibold)', textTransform: 'uppercase', letterSpacing: 'var(--tracking-wide)' }}>
                      Member price
                    </p>
                    <p style={{ fontSize: 'var(--text-lg)', fontWeight: 'var(--weight-bold)', color: 'var(--success)', marginTop: 4 }}>
                      {selectedListing.member_price ? formatCurrency(selectedListing.member_price) : 'N/A'}
                    </p>
                  </div>
                </div>

                <div style={{ padding: 'var(--space-4)', background: 'var(--bg-subtle)', borderRadius: 'var(--radius-md)', marginTop: 'var(--space-4)' }}>
                  <p style={{ fontSize: 'var(--text-xs)', color: 'var(--fg-muted)', fontWeight: 'var(--weight-semibold)', textTransform: 'uppercase', letterSpacing: 'var(--tracking-wide)', marginBottom: 'var(--space-1)' }}>
                    Seller
                  </p>
                  <p className="ds-table__primary">{selectedListing.seller?.full_name}</p>
                  <p style={{ fontSize: 'var(--text-sm)', color: 'var(--fg-secondary)' }}>{selectedListing.seller?.business_name}</p>
                </div>
              </div>
            </div>
          </Ds.Modal.Body>
          <Ds.Modal.Footer>
            <Ds.Button variant="ghost" onClick={() => setSelectedListing(null)}>Close</Ds.Button>
            {!selectedListing.is_approved ? (
              <Ds.Button
                variant="success"
                leftIcon={<IconCheck size={14} />}
                onClick={() => { handleApprove(selectedListing.id); setSelectedListing(null); }}
              >
                Approve listing
              </Ds.Button>
            ) : (
              <Ds.Button
                variant="danger-outline"
                leftIcon={<IconX size={14} />}
                onClick={() => setShowRejectModal(true)}
              >
                Reject listing
              </Ds.Button>
            )}
          </Ds.Modal.Footer>
        </Ds.Modal>
      )}

      {showInterestsModal && (
        <Ds.Modal open size="lg" onClose={() => setShowInterestsModal(false)}>
          <Ds.Modal.Header
            title="Lead Activity"
            subtitle={`Members interested in: ${selectedListing?.title}`}
            onClose={() => setShowInterestsModal(false)}
          />
          <Ds.Modal.Body>
            {loadingInterests ? (
              <Ds.LoadingRow label="Loading interests…" />
            ) : interests.length === 0 ? (
              <Ds.EmptyState icon={IconUsers} title="No interest yet" description="Members will appear here when they react to this listing." />
            ) : (
              <Ds.Table>
                <thead>
                  <tr>
                    <th>Member</th>
                    <th>Chapter</th>
                    <th>Method</th>
                    <th>Date</th>
                  </tr>
                </thead>
                <tbody>
                  {interests.map(i => (
                    <tr key={i.id}>
                      <td className="ds-table__primary">{i.user?.full_name}</td>
                      <td className="ds-table__muted">{i.user?.chapter?.name || '—'}</td>
                      <td style={{ textTransform: 'capitalize' }} className="ds-table__muted">{i.contact_method}</td>
                      <td className="ds-table__muted">{new Date(i.created_at).toLocaleDateString()}</td>
                    </tr>
                  ))}
                </tbody>
              </Ds.Table>
            )}
          </Ds.Modal.Body>
        </Ds.Modal>
      )}

      {showRejectModal && (
        <Ds.Modal open size="sm" onClose={() => setShowRejectModal(false)}>
          <Ds.Modal.Header title="Reject listing" onClose={() => setShowRejectModal(false)} />
          <Ds.Modal.Body>
            <Ds.Field label="Reason for rejection" required>
              <Ds.Textarea
                placeholder="e.g. Image is not clear, title is too short…"
                value={rejectionReason}
                onChange={e => setRejectionReason(e.target.value)}
                rows={5}
              />
            </Ds.Field>
          </Ds.Modal.Body>
          <Ds.Modal.Footer>
            <Ds.Button variant="ghost" onClick={() => setShowRejectModal(false)}>Cancel</Ds.Button>
            <Ds.Button variant="danger" onClick={handleReject}>Confirm reject</Ds.Button>
          </Ds.Modal.Footer>
        </Ds.Modal>
      )}
    </section>
  );
}

function ChapterActionMenu({ chapter, onEdit, onDelete }) {
  const [isOpen, setIsOpen] = useState(false);
  const menuRef = useRef(null);

  useEffect(() => {
    const handleClickOutside = (e) => {
      if (menuRef.current && !menuRef.current.contains(e.target)) setIsOpen(false);
    };
    document.addEventListener('mousedown', handleClickOutside);
    return () => document.removeEventListener('mousedown', handleClickOutside);
  }, []);

  return (
    <div className="action-menu-container" ref={menuRef}>
      <button className="view-detail-btn" title="Actions" onClick={() => setIsOpen(!isOpen)}>
        <IconSettings size={20} />
      </button>
      
      {isOpen && (
        <div className="action-dropdown" style={{ right: 0, left: 'auto' }}>
          <button className="action-item" onClick={() => { onEdit(); setIsOpen(false); }}>
            <IconPencil size={16} /> Edit Chapter
          </button>
          <div className="action-divider" />
          <button className="action-item danger" onClick={() => { onDelete(); setIsOpen(false); }}>
            <IconTrash size={16} /> Delete Chapter
          </button>
        </div>
      )}
    </div>
  );
}

function ChaptersPage() {
  const [chapters, setChapters] = useState([]);
  const [loading, setLoading] = useState(true);
  const [showModal, setShowModal] = useState(false);
  const [editingChapter, setEditingChapter] = useState(null);

  // Filters state
  const [search, setSearch] = useState('');
  const [districtFilter, setDistrictFilter] = useState('');
  const [statusFilter, setStatusFilter] = useState('');
  
  const fetchChapters = async () => {
    setLoading(true);
    try {
      const data = await api.listChapters();
      setChapters(data || []);
    } catch (err) {
      console.error(err);
    } finally {
      setLoading(false);
    }
  };

  useEffect(() => { fetchChapters(); }, []);

  const handleSave = async (formData) => {
    try {
      if (editingChapter) {
        await api.updateChapter(editingChapter.id, formData);
      } else {
        await api.createChapter(formData);
      }
      setShowModal(false);
      fetchChapters();
    } catch (err) {
      alert(err.message);
    }
  };

  const handleDelete = async (id) => {
    if (!window.confirm('Are you sure you want to delete this chapter?')) return;
    try {
      await api.deleteChapter(id);
      fetchChapters();
    } catch (err) {
      alert(err.message);
    }
  };

  // Filtered chapters list
  const filteredChapters = chapters.filter(c => {
    if (search) {
      const q = search.toLowerCase();
      const nameMatch = c.name?.toLowerCase().includes(q);
      const districtMatch = c.district?.toLowerCase().includes(q);
      const scheduleMatch = c.meeting_schedule?.toLowerCase().includes(q);
      if (!nameMatch && !districtMatch && !scheduleMatch) return false;
    }
    if (districtFilter && c.district !== districtFilter) {
      return false;
    }
    if (statusFilter !== '') {
      const isActiveFilter = statusFilter === 'active';
      if (c.is_active !== isActiveFilter) {
        return false;
      }
    }
    return true;
  });

  const districtOptions = SRI_LANKA_DISTRICTS.map(d => ({ id: d, name: d }));
  const statusOptions = [
    { id: 'active', name: 'Active' },
    { id: 'inactive', name: 'Inactive' }
  ];

  return (
    <section className="ds-page">
      <Ds.PageHeader
        title="Global Chapters"
        description="Manage geographical chapters and their regional operations."
        actions={
          <Ds.Button
            variant="primary"
            leftIcon={<IconPlus size={14} />}
            onClick={() => { setEditingChapter(null); setShowModal(true); }}
          >
            New chapter
          </Ds.Button>
        }
      />

      <Ds.Section
        title="Chapters"
        subtitle={`${filteredChapters.length} of ${chapters.length} chapters`}
        flush
      >
        <div style={{ display: 'flex', gap: 'var(--space-3)', flexWrap: 'wrap', padding: 'var(--space-5) var(--space-6)', borderBottom: '1px solid var(--border-subtle)' }}>
          <Ds.Input
            placeholder="Search by name, district or schedule…"
            value={search}
            onChange={e => setSearch(e.target.value)}
            leftIcon={<IconSearch size={14} />}
            wrapClassName=""
            style={{ flex: 1, minWidth: 240 }}
          />
          <Ds.Select
            placeholder="All Districts"
            value={districtFilter}
            options={districtOptions}
            allowClear
            onChange={setDistrictFilter}
            style={{ width: 200 }}
          />
          <Ds.Select
            placeholder="All Status"
            value={statusFilter}
            options={statusOptions}
            allowClear
            onChange={setStatusFilter}
            style={{ width: 150 }}
          />
        </div>

        <Ds.Table>
          <thead>
            <tr>
              <th>Chapter</th>
              <th>District</th>
              <th>Meeting schedule</th>
              <th>Status</th>
              <th className="ds-table__actions" />
            </tr>
          </thead>
          <tbody>
            {loading ? (
              <Ds.Table.LoadingRow colSpan={5} label="Loading chapters…" />
            ) : filteredChapters.length === 0 ? (
              <Ds.Table.EmptyRow
                colSpan={5}
                icon={IconBuildingCommunity}
                title="No chapters found"
                description={chapters.length === 0 ? "Add the first chapter to get started." : "Try adjusting your filters or search."}
              />
            ) : filteredChapters.map(c => (
              <tr key={c.id}>
                <td className="ds-table__primary">{c.name}</td>
                <td>
                  <span style={{ display: 'inline-flex', alignItems: 'center', gap: 6, color: 'var(--fg-secondary)', fontSize: 'var(--text-sm)' }}>
                    <IconMapPin size={14} color="var(--brand-blue)" />
                    {c.district}
                  </span>
                </td>
                <td className="ds-table__muted">{c.meeting_schedule || '—'}</td>
                <td>
                  <Ds.Badge dot variant={c.is_active ? 'success' : 'danger'}>
                    {c.is_active ? 'Active' : 'Inactive'}
                  </Ds.Badge>
                </td>
                <td className="ds-table__actions">
                  <ChapterActionMenu
                    chapter={c}
                    onEdit={() => { setEditingChapter(c); setShowModal(true); }}
                    onDelete={() => handleDelete(c.id)}
                  />
                </td>
              </tr>
            ))}
          </tbody>
        </Ds.Table>
      </Ds.Section>

      {showModal && (
        <ChapterFormModal
          chapter={editingChapter}
          districts={SRI_LANKA_DISTRICTS}
          onClose={() => setShowModal(false)}
          onSave={handleSave}
        />
      )}
    </section>
  );
}

function ChapterFormModal({ chapter, districts, onClose, onSave }) {
  const [formData, setFormData] = useState({
    name: chapter?.name || '',
    district: chapter?.district || '',
    description: chapter?.description || '',
    meeting_schedule: chapter?.meeting_schedule || '',
    poster_url: chapter?.poster_url || '',
    is_active: chapter?.is_active ?? true
  });
  const [uploadingPoster, setUploadingPoster] = useState(false);

  const handlePosterUpload = async (e) => {
    const file = e.target.files?.[0];
    if (!file || !chapter) return;
    setUploadingPoster(true);
    try {
      const res = await api.uploadChapterPoster(chapter.id, file);
      setFormData(prev => ({ ...prev, poster_url: res.poster_url }));
    } catch (err) {
      alert('Poster upload failed: ' + (err.message || ''));
    } finally {
      setUploadingPoster(false);
    }
  };

  const handleSubmit = (e) => {
    e.preventDefault();
    if (!formData.name || !formData.district) return alert('Name and District are required');
    onSave(formData);
  };

  return (
    <div className="modal-overlay" onClick={(e) => e.target === e.currentTarget && onClose()}>
      <div className="modal-content" onClick={e => e.stopPropagation()} style={{ maxWidth: 500 }}>
        <div className="modal-header">
          <h2 style={{ fontSize: '1.25rem', fontWeight: 800 }}>{chapter ? 'Edit Chapter' : 'Add New Chapter'}</h2>
          <button type="button" className="modal-close-btn" onClick={onClose}>
            <IconX size={20} />
          </button>
        </div>
        <form onSubmit={handleSubmit} style={{ padding: '1.5rem 1.5rem 6rem' }}>
          <div className="login-field">
            <label>Chapter Name *</label>
            <input 
              type="text" 
              className="filter-input v2" 
              value={formData.name} 
              onChange={e => setFormData({ ...formData, name: e.target.value })} 
              required 
            />
          </div>
          
          <div style={{ marginBottom: '1.25rem' }}>
            <label style={{ fontSize: '0.75rem', fontWeight: 700, color: 'var(--text-secondary)', textTransform: 'uppercase', letterSpacing: '0.05em', display: 'block', marginBottom: '0.5rem' }}>District *</label>
            <CustomSelect
              label="Select District..."
              value={formData.district}
              options={districts.map(d => ({ id: d, name: d }))}
              onChange={val => setFormData({ ...formData, district: val })}
            />
          </div>

          <div className="login-field">
            <label>Meeting Schedule</label>
            <input 
              type="text" 
              className="filter-input v2" 
              placeholder="e.g. Every Tuesday 7:00 AM"
              value={formData.meeting_schedule} 
              onChange={e => setFormData({ ...formData, meeting_schedule: e.target.value })} 
            />
          </div>

          <div className="login-field">
            <label>Description</label>
            <textarea
              className="action-textarea"
              value={formData.description}
              onChange={e => setFormData({ ...formData, description: e.target.value })}
              style={{ minHeight: 80 }}
            />
          </div>

          {chapter ? (
            <div className="login-field">
              <label>Chapter Poster</label>
              <div style={{ display: 'flex', gap: '1rem', alignItems: 'center', marginTop: '0.25rem' }}>
                <div style={{ width: 120, height: 68, borderRadius: 8, background: '#f8fafc', overflow: 'hidden', border: '1px solid #e2e8f0', display: 'flex', alignItems: 'center', justifyContent: 'center', flexShrink: 0 }}>
                  {formData.poster_url
                    ? <img src={formData.poster_url.startsWith('http') ? formData.poster_url : `${STATIC_BASE_URL}${formData.poster_url}`} alt="" style={{ width: '100%', height: '100%', objectFit: 'cover' }} />
                    : <span style={{ fontSize: '0.7rem', color: '#94a3b8' }}>No poster</span>}
                </div>
                <div>
                  <input id="chapter-poster-upload" type="file" accept="image/*" style={{ display: 'none' }} onChange={handlePosterUpload} />
                  <label htmlFor="chapter-poster-upload" className="btn-secondary" style={{ display: 'inline-flex', alignItems: 'center', gap: '0.5rem', cursor: 'pointer', fontSize: '0.85rem', padding: '0.5rem 0.75rem' }}>
                    <IconPlus size={16} /> {uploadingPoster ? 'Uploading…' : formData.poster_url ? 'Change poster' : 'Upload poster'}
                  </label>
                  {formData.poster_url && (
                    <button type="button" style={{ marginLeft: '0.5rem', fontSize: '0.75rem', color: '#ef4444', border: 'none', background: 'none', cursor: 'pointer', fontWeight: 600 }} onClick={() => setFormData({ ...formData, poster_url: '' })}>
                      Remove
                    </button>
                  )}
                </div>
              </div>
            </div>
          ) : (
            <div className="login-field">
              <label>Chapter Poster</label>
              <p style={{ fontSize: '0.8rem', color: '#94a3b8', margin: 0 }}>Save the chapter first, then edit it to upload a poster image.</p>
            </div>
          )}

          {chapter && (
            <div style={{ display: 'flex', alignItems: 'center', gap: '0.75rem', marginBottom: '1.5rem' }}>
              <input 
                type="checkbox" 
                checked={formData.is_active} 
                onChange={e => setFormData({ ...formData, is_active: e.target.checked })} 
                id="chapter-active"
              />
              <label htmlFor="chapter-active" style={{ fontSize: '0.9rem', fontWeight: 600 }}>Active Status</label>
            </div>
          )}

          <button type="submit" className="login-btn">
            {chapter ? 'Update Chapter' : 'Create Chapter'}
          </button>
        </form>
      </div>
    </div>
  );
}


// ── Community & Leads ───────────────────────────────────────────────────────

const LEAD_STATUS_META = {
  open: { label: 'Open', variant: 'info' },
  in_progress: { label: 'In Progress', variant: 'warning' },
  closed_won: { label: 'Closed Won', variant: 'success' },
  closed_lost: { label: 'Closed Lost', variant: 'danger' },
};

const LEAD_STATUS_OPTIONS = [
  { id: 'open', name: 'Open' },
  { id: 'in_progress', name: 'In Progress' },
  { id: 'closed_won', name: 'Closed Won' },
  { id: 'closed_lost', name: 'Closed Lost' },
];

function fmtLKR(value) {
  const n = Number(value || 0);
  return `LKR ${n.toLocaleString('en-LK', { maximumFractionDigits: 0 })}`;
}

function LeadStatusBadge({ status }) {
  if (!status) return <Ds.Badge variant="neutral">—</Ds.Badge>;
  const meta = LEAD_STATUS_META[status] || { label: status, variant: 'neutral' };
  return <Ds.Badge variant={meta.variant}>{meta.label}</Ds.Badge>;
}

function PostTypeBadge({ type }) {
  const map = {
    lead: { label: 'Lead', variant: 'brand' },
    rfp: { label: 'RFP', variant: 'info' },
    general: { label: 'General', variant: 'neutral' },
  };
  const meta = map[type] || { label: type || 'General', variant: 'neutral' };
  return <Ds.Badge variant={meta.variant}>{meta.label}</Ds.Badge>;
}

function CommunityPage({ showToast }) {
  const notify = showToast || ((m) => alert(m));
  const [view, setView] = useState('overview'); // overview | leads | moderation

  // Overview
  const [stats, setStats] = useState(null);
  const [statsLoading, setStatsLoading] = useState(true);
  const [days, setDays] = useState('30');

  // Leads pipeline
  const [leads, setLeads] = useState([]);
  const [leadsLoading, setLeadsLoading] = useState(false);
  const [leadsTotal, setLeadsTotal] = useState(0);
  const [leadsPage, setLeadsPage] = useState(1);
  const [leadStatus, setLeadStatus] = useState('');
  const [leadType, setLeadType] = useState('');
  const [leadSearch, setLeadSearch] = useState('');

  // Moderation feed
  const [posts, setPosts] = useState([]);
  const [postsLoading, setPostsLoading] = useState(false);
  const [postsTotal, setPostsTotal] = useState(0);
  const [postsPage, setPostsPage] = useState(1);
  const [postType, setPostType] = useState('');
  const [postSearch, setPostSearch] = useState('');

  // Detail modal
  const [detail, setDetail] = useState(null);
  const [detailLoading, setDetailLoading] = useState(false);
  const [tyfbValue, setTyfbValue] = useState('');

  const PAGE_SIZE = 20;

  const fetchStats = useCallback(async () => {
    setStatsLoading(true);
    try {
      setStats(await api.getCommunityStats(days));
    } catch (err) {
      console.error('Failed to load community stats:', err);
      notify(err.message || 'Failed to load stats', 'error');
    } finally {
      setStatsLoading(false);
    }
  }, [days]);

  const fetchLeads = useCallback(async () => {
    setLeadsLoading(true);
    try {
      const data = await api.listCommunityLeads({
        status: leadStatus, post_type: leadType, search: leadSearch,
        page: leadsPage, page_size: PAGE_SIZE,
      });
      setLeads(data.leads || []);
      setLeadsTotal(data.total || 0);
    } catch (err) {
      console.error('Failed to load leads:', err);
    } finally {
      setLeadsLoading(false);
    }
  }, [leadStatus, leadType, leadSearch, leadsPage]);

  const fetchPosts = useCallback(async () => {
    setPostsLoading(true);
    try {
      const data = await api.listCommunityPosts({
        post_type: postType, search: postSearch,
        page: postsPage, page_size: PAGE_SIZE,
      });
      setPosts(data.posts || []);
      setPostsTotal(data.total || 0);
    } catch (err) {
      console.error('Failed to load posts:', err);
    } finally {
      setPostsLoading(false);
    }
  }, [postType, postSearch, postsPage]);

  useEffect(() => { fetchStats(); }, [fetchStats]);
  useEffect(() => { if (view === 'leads') fetchLeads(); }, [view, fetchLeads]);
  useEffect(() => { if (view === 'moderation') fetchPosts(); }, [view, fetchPosts]);

  const openDetail = async (postId) => {
    setDetail({ id: postId });
    setDetailLoading(true);
    setTyfbValue('');
    try {
      setDetail(await api.getCommunityPost(postId));
    } catch (err) {
      notify(err.message || 'Failed to load post', 'error');
      setDetail(null);
    } finally {
      setDetailLoading(false);
    }
  };

  const refreshAfterMutation = () => {
    fetchStats();
    if (view === 'leads') fetchLeads();
    if (view === 'moderation') fetchPosts();
  };

  const handleStatusChange = async (postId, status) => {
    try {
      await api.updateCommunityLeadStatus(postId, status);
      notify('Lead status updated');
      setDetail((d) => (d && d.id === postId ? { ...d, lead_status: status } : d));
      refreshAfterMutation();
    } catch (err) {
      notify(err.message || 'Failed to update status', 'error');
    }
  };

  const handleRecordTyfb = async (postId) => {
    const value = parseFloat(tyfbValue);
    if (!value || value <= 0) return notify('Enter a valid business value', 'error');
    try {
      await api.recordCommunityTyfb(postId, value);
      notify('TYFB recorded — lead closed as won');
      setDetail((d) => (d && d.id === postId ? { ...d, business_value: value, lead_status: 'closed_won' } : d));
      setTyfbValue('');
      refreshAfterMutation();
    } catch (err) {
      notify(err.message || 'Failed to record TYFB', 'error');
    }
  };

  const handleDeletePost = async (postId) => {
    if (!confirm('Delete this post permanently? This also removes its likes and comments.')) return;
    try {
      await api.deleteCommunityPost(postId);
      notify('Post deleted');
      setDetail(null);
      refreshAfterMutation();
    } catch (err) {
      notify(err.message || 'Failed to delete post', 'error');
    }
  };

  const handleDeleteComment = async (commentId) => {
    if (!confirm('Delete this comment?')) return;
    try {
      await api.deleteCommunityComment(commentId);
      setDetail((d) => (d ? { ...d, comments: (d.comments || []).filter((c) => c.id !== commentId) } : d));
      notify('Comment deleted');
    } catch (err) {
      notify(err.message || 'Failed to delete comment', 'error');
    }
  };

  const leadsPages = Math.max(1, Math.ceil(leadsTotal / PAGE_SIZE));
  const postsPages = Math.max(1, Math.ceil(postsTotal / PAGE_SIZE));

  return (
    <section className="ds-page">
      <Ds.PageHeader
        title="Community & Leads"
        description="Monitor network engagement, track the lead pipeline, and moderate the community feed."
        actions={
          <Ds.Button variant="secondary" leftIcon={<IconRefresh size={14} />} onClick={refreshAfterMutation}>
            Refresh
          </Ds.Button>
        }
      />

      <div style={{ marginBottom: 'var(--space-4)' }}>
        <Ds.ChipGroup
          value={view}
          onChange={setView}
          options={[
            { value: 'overview', label: 'Overview' },
            { value: 'leads', label: 'Leads Pipeline' },
            { value: 'moderation', label: 'Moderation' },
          ]}
        />
      </div>

      {/* ── Overview ── */}
      {view === 'overview' && (
        <>
          <Ds.Section
            title="Engagement & Business Value"
            subtitle={`Last ${days} days`}
            flush
            actions={
              <Ds.ChipGroup
                value={days}
                onChange={setDays}
                options={[
                  { value: '7', label: '7d' },
                  { value: '30', label: '30d' },
                  { value: '90', label: '90d' },
                ]}
              />
            }
          >
            <div style={{ display: 'grid', gridTemplateColumns: 'repeat(auto-fit, minmax(180px, 1fr))', gap: 'var(--space-3)' }}>
              <Ds.StatCard label="Total TYFB Value" value={statsLoading ? '—' : fmtLKR(stats?.total_tyfb_value)} icon={IconCoin} iconColor="#059669" iconBg="#ecfdf5" />
              <Ds.StatCard label="Open Leads" value={statsLoading ? '—' : (stats?.open_leads ?? 0)} icon={IconHierarchy2} iconColor="#2563eb" iconBg="#eff6ff" />
              <Ds.StatCard label="Win Rate" value={statsLoading ? '—' : `${stats?.win_rate ?? 0}%`} icon={IconChartBar} iconColor="#8b5cf6" iconBg="#f5f3ff" />
              <Ds.StatCard label="Avg Deal Size" value={statsLoading ? '—' : fmtLKR(stats?.avg_deal_size)} icon={IconArrowUpRight} iconColor="#0891b2" iconBg="#ecfeff" />
              <Ds.StatCard label="Posts" value={statsLoading ? '—' : (stats?.total_posts ?? 0)} icon={IconMessages} iconColor="#64748b" iconBg="#f8fafc" />
              <Ds.StatCard label="Leads / RFPs" value={statsLoading ? '—' : `${stats?.total_leads ?? 0} / ${stats?.total_rfps ?? 0}`} icon={IconClipboardList} iconColor="#d97706" iconBg="#fffbeb" />
              <Ds.StatCard label="Likes" value={statsLoading ? '—' : (stats?.total_likes ?? 0)} icon={IconStar} iconColor="#f59e0b" iconBg="#fffbeb" />
              <Ds.StatCard label="Comments" value={statsLoading ? '—' : (stats?.total_comments ?? 0)} icon={IconMessages} iconColor="#0ea5e9" iconBg="#f0f9ff" />
            </div>
          </Ds.Section>

          <Ds.Section title="TYFB Value Over Time" subtitle={`Daily business value recorded (last ${days} days)`}>
            {statsLoading ? (
              <div style={{ padding: 'var(--space-6)', color: 'var(--fg-muted)' }}>Loading…</div>
            ) : (stats?.tyfb_timeseries?.length ? (
              <Ds.Sparkline
                points={stats.tyfb_timeseries.map((p) => p.value)}
                color="var(--brand-blue, #2563eb)"
                height={120}
                ariaLabel="TYFB value over time"
              />
            ) : (
              <Ds.EmptyState icon={IconChartBar} title="No business value recorded yet" description="Closed-won deals with a recorded TYFB value will appear here." />
            ))}
          </Ds.Section>
        </>
      )}

      {/* ── Leads Pipeline ── */}
      {view === 'leads' && (
        <Ds.Section
          title="Leads Pipeline"
          subtitle={`${leadsTotal} ${leadsTotal === 1 ? 'opportunity' : 'opportunities'}`}
          flush
          actions={
            <>
              <Ds.Input
                placeholder="Search content or author…"
                value={leadSearch}
                onChange={(e) => { setLeadSearch(e.target.value); setLeadsPage(1); }}
                leftIcon={<IconSearch size={14} />}
                size="sm"
                style={{ width: 220 }}
              />
              <Ds.Select placeholder="All types" value={leadType} allowClear size="sm" style={{ width: 130 }}
                options={[{ id: 'lead', name: 'Lead' }, { id: 'rfp', name: 'RFP' }]}
                onChange={(v) => { setLeadType(v); setLeadsPage(1); }} />
              <Ds.Select placeholder="All status" value={leadStatus} allowClear size="sm" style={{ width: 150 }}
                options={LEAD_STATUS_OPTIONS}
                onChange={(v) => { setLeadStatus(v); setLeadsPage(1); }} />
            </>
          }
        >
          <Ds.Table>
            <thead>
              <tr>
                <th>Opportunity</th>
                <th>Author</th>
                <th>Chapter</th>
                <th>Type</th>
                <th>Status</th>
                <th>Budget</th>
                <th>Value</th>
                <th className="ds-table__actions" />
              </tr>
            </thead>
            <tbody>
              {leadsLoading ? (
                <Ds.Table.LoadingRow colSpan={8} label="Loading leads…" />
              ) : leads.length === 0 ? (
                <Ds.Table.EmptyRow colSpan={8} icon={IconHierarchy2} title="No leads found" description="Adjust filters to see more opportunities." />
              ) : leads.map((l) => (
                <tr key={l.id} style={{ cursor: 'pointer' }} onClick={() => openDetail(l.id)}>
                  <td><div className="ds-table__primary" style={{ maxWidth: 280, overflow: 'hidden', textOverflow: 'ellipsis', whiteSpace: 'nowrap' }}>{l.content}</div></td>
                  <td>{l.author?.full_name || '—'}</td>
                  <td>{l.chapter_name || '—'}</td>
                  <td><PostTypeBadge type={l.post_type} /></td>
                  <td><LeadStatusBadge status={l.lead_status} /></td>
                  <td>{l.budget_range || '—'}</td>
                  <td>{l.business_value ? fmtLKR(l.business_value) : '—'}</td>
                  <td className="ds-table__actions" onClick={(e) => e.stopPropagation()}>
                    <Ds.IconButton aria-label="View" onClick={() => openDetail(l.id)}><IconEye size={18} /></Ds.IconButton>
                  </td>
                </tr>
              ))}
            </tbody>
          </Ds.Table>
          <Ds.Pagination page={leadsPage} totalPages={leadsPages} total={leadsTotal} pageLabel="leads" onPageChange={setLeadsPage} />
        </Ds.Section>
      )}

      {/* ── Moderation ── */}
      {view === 'moderation' && (
        <Ds.Section
          title="Community Feed"
          subtitle={`${postsTotal} ${postsTotal === 1 ? 'post' : 'posts'}`}
          flush
          actions={
            <>
              <Ds.Input
                placeholder="Search content or author…"
                value={postSearch}
                onChange={(e) => { setPostSearch(e.target.value); setPostsPage(1); }}
                leftIcon={<IconSearch size={14} />}
                size="sm"
                style={{ width: 220 }}
              />
              <Ds.Select placeholder="All types" value={postType} allowClear size="sm" style={{ width: 140 }}
                options={[{ id: 'general', name: 'General' }, { id: 'lead', name: 'Lead' }, { id: 'rfp', name: 'RFP' }]}
                onChange={(v) => { setPostType(v); setPostsPage(1); }} />
            </>
          }
        >
          <Ds.Table>
            <thead>
              <tr>
                <th>Post</th>
                <th>Author</th>
                <th>Chapter</th>
                <th>Type</th>
                <th>Posted</th>
                <th className="ds-table__actions" />
              </tr>
            </thead>
            <tbody>
              {postsLoading ? (
                <Ds.Table.LoadingRow colSpan={6} label="Loading posts…" />
              ) : posts.length === 0 ? (
                <Ds.Table.EmptyRow colSpan={6} icon={IconMessages} title="No posts found" description="Adjust filters to see more posts." />
              ) : posts.map((p) => (
                <tr key={p.id} style={{ cursor: 'pointer' }} onClick={() => openDetail(p.id)}>
                  <td><div className="ds-table__primary" style={{ maxWidth: 320, overflow: 'hidden', textOverflow: 'ellipsis', whiteSpace: 'nowrap' }}>{p.content}</div></td>
                  <td>{p.author?.full_name || '—'}</td>
                  <td>{p.chapter_name || '—'}</td>
                  <td><PostTypeBadge type={p.post_type} /></td>
                  <td>{p.created_at ? new Date(p.created_at).toLocaleDateString() : '—'}</td>
                  <td className="ds-table__actions" onClick={(e) => e.stopPropagation()}>
                    <Ds.IconButton aria-label="View" onClick={() => openDetail(p.id)}><IconEye size={18} /></Ds.IconButton>
                    <Ds.IconButton aria-label="Delete" onClick={() => handleDeletePost(p.id)} style={{ color: '#dc2626' }}><IconTrash size={18} /></Ds.IconButton>
                  </td>
                </tr>
              ))}
            </tbody>
          </Ds.Table>
          <Ds.Pagination page={postsPage} totalPages={postsPages} total={postsTotal} pageLabel="posts" onPageChange={setPostsPage} />
        </Ds.Section>
      )}

      {/* ── Detail modal ── */}
      {detail && (
        <Ds.Modal open onClose={() => setDetail(null)} size="lg">
          <Ds.Modal.Header
            title="Post Detail"
            subtitle={detail.chapter_name ? `${detail.chapter_name}` : undefined}
            onClose={() => setDetail(null)}
          />
          <Ds.Modal.Body>
            {detailLoading || !detail.content ? (
              <div style={{ padding: 'var(--space-6)', color: 'var(--fg-muted)' }}>Loading…</div>
            ) : (
              <div style={{ display: 'flex', flexDirection: 'column', gap: 'var(--space-4)' }}>
                <div style={{ display: 'flex', gap: 'var(--space-2)', flexWrap: 'wrap', alignItems: 'center' }}>
                  <PostTypeBadge type={detail.post_type} />
                  {detail.lead_status && <LeadStatusBadge status={detail.lead_status} />}
                  {detail.business_value ? <Ds.Badge variant="success">{fmtLKR(detail.business_value)}</Ds.Badge> : null}
                </div>

                <div>
                  <div style={{ fontWeight: 'var(--weight-semibold)' }}>{detail.author?.full_name || 'Unknown'}</div>
                  <div style={{ fontSize: 'var(--text-xs)', color: 'var(--fg-muted)' }}>
                    {detail.created_at ? new Date(detail.created_at).toLocaleString() : ''}
                  </div>
                </div>

                <div style={{ whiteSpace: 'pre-wrap', lineHeight: 1.6 }}>{detail.content}</div>
                {detail.image_url && (
                  <img
                    src={detail.image_url.startsWith('http') ? detail.image_url : `${STATIC_BASE_URL}${detail.image_url}`}
                    alt=""
                    style={{ maxWidth: '100%', borderRadius: 'var(--radius-md)', border: '1px solid var(--border-subtle)' }}
                  />
                )}

                {(detail.budget_range || detail.deadline || detail.target_industry_name || detail.target_club_name) && (
                  <div style={{ display: 'grid', gridTemplateColumns: 'repeat(auto-fit, minmax(160px, 1fr))', gap: 'var(--space-2)', fontSize: 'var(--text-sm)' }}>
                    {detail.budget_range && <div><span style={{ color: 'var(--fg-muted)' }}>Budget: </span>{detail.budget_range}</div>}
                    {detail.deadline && <div><span style={{ color: 'var(--fg-muted)' }}>Deadline: </span>{new Date(detail.deadline).toLocaleDateString()}</div>}
                    {detail.target_industry_name && <div><span style={{ color: 'var(--fg-muted)' }}>Industry: </span>{detail.target_industry_name}</div>}
                    {detail.target_club_name && <div><span style={{ color: 'var(--fg-muted)' }}>Club: </span>{detail.target_club_name}</div>}
                  </div>
                )}

                {/* Lead actions (only for lead/rfp) */}
                {detail.post_type !== 'general' && (
                  <div style={{ borderTop: '1px solid var(--border-subtle)', paddingTop: 'var(--space-3)', display: 'flex', flexWrap: 'wrap', gap: 'var(--space-3)', alignItems: 'flex-end' }}>
                    <div style={{ width: 180 }}>
                      <Ds.Field label="Update status">
                        <Ds.Select
                          value={detail.lead_status || ''}
                          options={LEAD_STATUS_OPTIONS}
                          onChange={(v) => handleStatusChange(detail.id, v)}
                          size="sm"
                        />
                      </Ds.Field>
                    </div>
                    <div style={{ width: 200 }}>
                      <Ds.Field label="Record TYFB (LKR)">
                        <Ds.Input
                          type="number"
                          placeholder="e.g. 150000"
                          value={tyfbValue}
                          onChange={(e) => setTyfbValue(e.target.value)}
                          size="sm"
                        />
                      </Ds.Field>
                    </div>
                    <Ds.Button variant="primary" size="sm" leftIcon={<IconCoin size={14} />} onClick={() => handleRecordTyfb(detail.id)}>
                      Record
                    </Ds.Button>
                  </div>
                )}

                {/* Comments */}
                <div style={{ borderTop: '1px solid var(--border-subtle)', paddingTop: 'var(--space-3)' }}>
                  <div style={{ fontWeight: 'var(--weight-semibold)', marginBottom: 'var(--space-2)' }}>
                    Comments ({detail.comments?.length || 0})
                  </div>
                  {(detail.comments || []).length === 0 ? (
                    <div style={{ color: 'var(--fg-muted)', fontSize: 'var(--text-sm)' }}>No comments.</div>
                  ) : (
                    <div style={{ display: 'flex', flexDirection: 'column', gap: 'var(--space-2)' }}>
                      {detail.comments.map((c) => (
                        <div key={c.id} style={{ display: 'flex', justifyContent: 'space-between', gap: 'var(--space-2)', padding: 'var(--space-2)', background: 'var(--bg-subtle)', borderRadius: 'var(--radius-md)' }}>
                          <div style={{ minWidth: 0 }}>
                            <div style={{ fontSize: 'var(--text-xs)', fontWeight: 'var(--weight-medium)' }}>{c.author?.full_name || 'Unknown'}</div>
                            <div style={{ fontSize: 'var(--text-sm)' }}>{c.content}</div>
                          </div>
                          <Ds.IconButton aria-label="Delete comment" onClick={() => handleDeleteComment(c.id)} style={{ color: '#dc2626', flexShrink: 0 }}>
                            <IconTrash size={16} />
                          </Ds.IconButton>
                        </div>
                      ))}
                    </div>
                  )}
                </div>
              </div>
            )}
          </Ds.Modal.Body>
          <Ds.Modal.Footer>
            <Ds.Button variant="ghost" leftIcon={<IconTrash size={14} />} onClick={() => handleDeletePost(detail.id)} style={{ color: '#dc2626' }}>
              Delete Post
            </Ds.Button>
            <Ds.Button variant="secondary" onClick={() => setDetail(null)}>Close</Ds.Button>
          </Ds.Modal.Footer>
        </Ds.Modal>
      )}
    </section>
  );
}

// ── Analytics Hub (Overview landing page) ───────────────────────────────────

function AnalyticsHubPage({ overview, overviewLoading, overviewError, onChangeTab, showToast }) {
  const [events, setEvents] = useState([]);
  const [chapters, setChapters] = useState([]);
  const [pendingAppsCount, setPendingAppsCount] = useState(0);
  const [pendingListingsCount, setPendingListingsCount] = useState(0);
  const [activity, setActivity] = useState([]);
  const [loading, setLoading] = useState(true);

  // Growth chart state
  const [chartMetric, setChartMetric] = useState('members');
  const [chartData, setChartData] = useState({ metric: 'members', days: 30, buckets: [] });
  const [chartLoading, setChartLoading] = useState(true);

  useEffect(() => {
    let cancelled = false;
    setChartLoading(true);
    api.getAdminTimeseries({ metric: chartMetric, days: 30 })
      .then(data => {
        if (cancelled) return;
        setChartData(data || { metric: chartMetric, days: 30, buckets: [] });
      })
      .catch(() => {
        if (cancelled) return;
        setChartData({ metric: chartMetric, days: 30, buckets: [] });
      })
      .finally(() => { if (!cancelled) setChartLoading(false); });
    return () => { cancelled = true; };
  }, [chartMetric]);

  useEffect(() => {
    let cancelled = false;
    setLoading(true);

    Promise.allSettled([
      api.listEvents({ published_only: false }),
      api.listChapters(),
      api.listApplications({ status: 'pending', page: 1, limit: 8 }),
      api.adminListMarketplaceListings({ is_approved: false }),
      api.listPayments({ limit: 5 }),
      api.listAllReferrals({ page: 1, limit: 5 }),
    ]).then(results => {
      if (cancelled) return;

      const [evRes, chRes, appsRes, listingsRes, paysRes, refsRes] = results;

      const evList = evRes.status === 'fulfilled' ? (evRes.value || []) : [];
      const chList = chRes.status === 'fulfilled' ? (chRes.value || []) : [];
      const appsPayload = appsRes.status === 'fulfilled' ? (appsRes.value || {}) : {};
      const appsData = appsPayload.data || [];
      const appsTotal = appsPayload.total ?? appsData.length;
      const listingsPayload = listingsRes.status === 'fulfilled' ? (listingsRes.value || {}) : {};
      const listingsArr = listingsPayload.listings || [];
      const paysPayload = paysRes.status === 'fulfilled' ? paysRes.value : null;
      const paysArr = Array.isArray(paysPayload) ? paysPayload : (paysPayload?.data || []);
      const refsPayload = refsRes.status === 'fulfilled' ? refsRes.value : null;
      const refsArr = Array.isArray(refsPayload) ? refsPayload : (refsPayload?.referrals || []);

      const acts = [];
      appsData.slice(0, 5).forEach(a => acts.push({
        type: 'application',
        title: `${a.full_name || 'Someone'} applied to join`,
        subtitle: a.business_name || a.chapter_name || '—',
        time: a.created_at,
        tab: 'applications',
      }));
      paysArr.slice(0, 5).forEach(p => acts.push({
        type: 'payment',
        title: `Payment received from ${p.user_name || 'a member'}`,
        subtitle: `${formatCurrency(p.amount)} · ${p.payment_type || 'payment'}`,
        time: p.created_at,
        tab: 'payments',
      }));
      refsArr.slice(0, 5).forEach(r => acts.push({
        type: 'referral',
        title: `${r.from_user?.full_name || 'A member'} sent a referral`,
        subtitle: r.lead_name || r.target_user?.full_name || '—',
        time: r.created_at,
        tab: 'referrals',
      }));
      acts.sort((a, b) => new Date(b.time || 0) - new Date(a.time || 0));

      setEvents(evList);
      setChapters(chList);
      setPendingAppsCount(appsTotal);
      setPendingListingsCount(listingsArr.length);
      setActivity(acts.slice(0, 8));
      setLoading(false);
    });

    return () => { cancelled = true; };
  }, []);

  const handleExportReports = async () => {
    try {
      const data = await api.exportData();
      if (data instanceof Blob) {
        const url = window.URL.createObjectURL(data);
        const link = document.createElement('a');
        link.href = url;
        link.setAttribute('download', `PBN_Report_${new Date().toISOString().split('T')[0]}.csv`);
        document.body.appendChild(link);
        link.click();
        link.remove();
        showToast('Data report downloaded');
      } else {
        const csvContent =
          'data:text/csv;charset=utf-8,' +
          Object.keys(data).join(',') + '\n' +
          Object.values(data).join(',');
        const link = document.createElement('a');
        link.setAttribute('href', encodeURI(csvContent));
        link.setAttribute('download', 'platform_summary.csv');
        document.body.appendChild(link);
        link.click();
        link.remove();
        showToast('Platform summary downloaded');
      }
    } catch (e) {
      showToast('Export failed: ' + e.message, 'error');
    }
  };

  const now = Date.now();
  const nextEvent = events
    .filter(e => e.end_at && new Date(e.end_at).getTime() >= now)
    .sort((a, b) => new Date(a.start_at) - new Date(b.start_at))[0];

  const topChapters = [...chapters]
    .sort((a, b) => (b.member_count || 0) - (a.member_count || 0))
    .slice(0, 5);

  const openTasksTotal = pendingAppsCount + pendingListingsCount;

  // Compute trend chip text for a KPI given current and previous values.
  // `period_days` from the overview tells us the lookback window (default 30).
  const pctTrend = (current, previous) => {
    if (current == null || previous == null) return null;
    if (previous === 0) {
      return current === 0 ? null : { text: 'New', direction: 'up' };
    }
    const pct = ((current - previous) / previous) * 100;
    if (Math.abs(pct) < 0.5) return null;
    return {
      text: `${pct >= 0 ? '+' : ''}${pct.toFixed(1)}%`,
      direction: pct >= 0 ? 'up' : 'down',
    };
  };

  const trendRevenue = pctTrend(overview?.total_value, overview?.previous_total_value);
  const trendMembers = pctTrend(overview?.total_members, overview?.previous_total_members);
  const trendLeads = pctTrend(overview?.total_leads, overview?.previous_total_leads);

  // Sparkline derived values
  const chartPoints = (chartData.buckets || []).map(b => Number(b.value) || 0);
  const chartTotal = chartPoints.reduce((s, v) => s + v, 0);
  const chartTotalLabel = chartMetric === 'revenue'
    ? formatCurrency(chartTotal)
    : chartTotal.toLocaleString();
  const chartColor = chartMetric === 'revenue'
    ? 'var(--success)'
    : chartMetric === 'leads'
      ? 'var(--brand-amber-600)'
      : 'var(--brand-blue)';

  const activityVisuals = {
    application: { icon: IconClipboardList, color: 'var(--brand-blue)',       bg: 'var(--brand-blue-50)' },
    payment:     { icon: IconCoin,          color: 'var(--success)',          bg: 'var(--success-bg)' },
    referral:    { icon: IconHierarchy2,    color: 'var(--brand-amber-600)',  bg: 'var(--brand-amber-50)' },
  };

  return (
    <section className="ds-page">
      <Ds.PageHeader
        title="Analytics Hub"
        description="Network growth, recent activity, and what needs your attention today."
        actions={
          <Ds.Button
            variant="primary"
            leftIcon={<IconFileExport size={14} />}
            onClick={handleExportReports}
          >
            Export
          </Ds.Button>
        }
      />

      {/* KPI cards */}
      {overviewError ? (
        <Ds.Card padded>
          <Ds.EmptyState
            icon={IconAlertCircle}
            title="Failed to load analytics"
            description="Check the backend connection and try again."
          />
        </Ds.Card>
      ) : (
        <div className="ds-stat-grid">
          <Ds.StatCard
            label="Total Revenue (ROI)"
            value={overviewLoading ? '—' : formatCurrency(overview?.total_value)}
            icon={IconCoin}
            iconColor="var(--success)"
            iconBg="var(--success-bg)"
            trend={trendRevenue?.text}
            trendDirection={trendRevenue?.direction}
          />
          <Ds.StatCard
            label="Active Members"
            value={overview?.total_members?.toLocaleString() ?? '—'}
            icon={IconUsers}
            iconColor="var(--brand-blue)"
            iconBg="var(--brand-blue-50)"
            trend={trendMembers?.text}
            trendDirection={trendMembers?.direction}
          />
          <Ds.StatCard
            label="Total Leads"
            value={overview?.total_leads?.toLocaleString() ?? '—'}
            icon={IconStackPop}
            iconColor="var(--brand-amber-600)"
            iconBg="var(--brand-amber-50)"
            trend={trendLeads?.text}
            trendDirection={trendLeads?.direction}
          />
          <Ds.StatCard
            label="Open Tasks"
            value={loading ? '—' : openTasksTotal.toLocaleString()}
            icon={IconBell}
            iconColor="var(--brand-navy)"
            iconBg="rgba(10, 37, 64, 0.08)"
          />
        </div>
      )}

      {/* Two-column dashboard */}
      <div className="ds-dashboard-grid">
        {/* LEFT column */}
        <div className="ds-dashboard-grid__col">
          <Ds.Section
            title="Network Growth"
            subtitle={`Last ${chartData.days || 30} days`}
            actions={
              <Ds.ChipGroup
                value={chartMetric}
                onChange={setChartMetric}
                options={[
                  { value: 'members', label: 'Members' },
                  { value: 'revenue', label: 'Revenue' },
                  { value: 'leads', label: 'Leads' },
                ]}
              />
            }
          >
            {chartLoading ? (
              <Ds.LoadingRow label="Loading chart…" />
            ) : chartPoints.length === 0 || chartPoints.every(v => v === 0) ? (
              <Ds.EmptyState
                icon={IconChartBar}
                title="No data in this window"
                description={`No new ${chartMetric} recorded in the last ${chartData.days || 30} days.`}
              />
            ) : (
              <>
                <div style={{ display: 'flex', alignItems: 'baseline', gap: 'var(--space-2)', marginBottom: 'var(--space-4)' }}>
                  <span style={{
                    fontSize: 'var(--text-3xl)',
                    fontWeight: 'var(--weight-bold)',
                    color: 'var(--fg-primary)',
                    letterSpacing: 'var(--tracking-tight)',
                    lineHeight: 1,
                  }}>
                    {chartTotalLabel}
                  </span>
                  <span style={{
                    fontSize: 'var(--text-sm)',
                    color: 'var(--fg-muted)',
                    fontWeight: 'var(--weight-medium)',
                  }}>
                    new {chartMetric} in the last {chartData.days || 30} days
                  </span>
                </div>
                <Ds.Sparkline
                  points={chartPoints}
                  color={chartColor}
                  height={120}
                  ariaLabel={`${chartMetric} new per ${chartData.bucket || 'day'}`}
                />
                <div style={{
                  display: 'flex',
                  justifyContent: 'space-between',
                  marginTop: 'var(--space-2)',
                  fontSize: 'var(--text-xs)',
                  color: 'var(--fg-muted)',
                  fontWeight: 'var(--weight-medium)',
                }}>
                  <span>
                    {chartData.buckets?.[0]?.date
                      ? new Date(chartData.buckets[0].date).toLocaleDateString(undefined, { month: 'short', day: 'numeric' })
                      : ''}
                  </span>
                  <span>
                    {chartData.buckets?.[chartData.buckets.length - 1]?.date
                      ? new Date(chartData.buckets[chartData.buckets.length - 1].date).toLocaleDateString(undefined, { month: 'short', day: 'numeric' })
                      : ''}
                  </span>
                </div>
              </>
            )}
          </Ds.Section>

          <Ds.Section
            title="Recent Activity"
            subtitle="Latest applications, payments, and referrals"
            flush
          >
            {loading ? (
              <Ds.LoadingRow label="Loading activity…" />
            ) : activity.length === 0 ? (
              <Ds.EmptyState
                icon={IconBell}
                title="No recent activity"
                description="As members apply, pay, or send referrals, you'll see them here."
              />
            ) : (
              <div className="ds-activity-list" style={{ padding: '0 var(--space-4)' }}>
                {activity.map((act, i) => {
                  const v = activityVisuals[act.type];
                  const Icon = v.icon;
                  return (
                    <button
                      key={i}
                      type="button"
                      className="ds-activity-item"
                      onClick={() => onChangeTab(act.tab)}
                    >
                      <span className="ds-activity-item__icon" style={{ background: v.bg, color: v.color }}>
                        <Icon size={16} />
                      </span>
                      <div className="ds-activity-item__body">
                        <div className="ds-activity-item__title">{act.title}</div>
                        <div className="ds-activity-item__subtitle">{act.subtitle}</div>
                      </div>
                      <span className="ds-activity-item__time">{formatRelativeTime(act.time)}</span>
                    </button>
                  );
                })}
              </div>
            )}
          </Ds.Section>
        </div>

        {/* RIGHT column */}
        <div className="ds-dashboard-grid__col">
          <Ds.Section
            title="Upcoming Event"
            actions={
              <Ds.Button
                variant="ghost"
                size="sm"
                onClick={() => onChangeTab('events')}
                rightIcon={<IconChevronRight size={14} />}
              >
                View all
              </Ds.Button>
            }
          >
            {loading ? (
              <Ds.LoadingRow label="Loading…" />
            ) : !nextEvent ? (
              <Ds.EmptyState
                icon={IconCalendarEvent}
                title="No upcoming events"
                description="Schedule a chapter meeting to see it here."
              />
            ) : (
              <div className="ds-event-card">
                <div className="ds-event-card__date">
                  <span className="ds-event-card__month">
                    {new Date(nextEvent.start_at).toLocaleString(undefined, { month: 'short' })}
                  </span>
                  <span className="ds-event-card__day">
                    {new Date(nextEvent.start_at).getDate()}
                  </span>
                </div>
                <div className="ds-event-card__body">
                  <div className="ds-event-card__title">{nextEvent.title}</div>
                  <div className="ds-event-card__meta">
                    <span>
                      {new Date(nextEvent.start_at).toLocaleTimeString([], { hour: '2-digit', minute: '2-digit' })}
                      {nextEvent.location ? ` · ${nextEvent.location}` : ''}
                    </span>
                    <span>
                      {(nextEvent.rsvps?.filter(r => r.status === 'going').length || 0)} going
                    </span>
                  </div>
                </div>
              </div>
            )}
          </Ds.Section>

          <Ds.Section
            title="Top Chapters"
            subtitle="Ranked by member count"
            actions={
              <Ds.Button
                variant="ghost"
                size="sm"
                onClick={() => onChangeTab('chapters')}
                rightIcon={<IconChevronRight size={14} />}
              >
                View all
              </Ds.Button>
            }
          >
            {loading ? (
              <Ds.LoadingRow label="Loading…" />
            ) : topChapters.length === 0 ? (
              <Ds.EmptyState
                icon={IconBuildingCommunity}
                title="No chapters yet"
              />
            ) : (
              <div className="ds-rank-list">
                {topChapters.map((c, i) => (
                  <div
                    key={c.id}
                    className={Ds.cx('ds-rank-list__item', i === 0 && 'ds-rank-list__item--top')}
                  >
                    <span className="ds-rank-list__rank">{i + 1}</span>
                    <div className="ds-rank-list__body">
                      <div className="ds-rank-list__title">{c.name}</div>
                      <div className="ds-rank-list__sub">{c.district || '—'}</div>
                    </div>
                    <span className="ds-rank-list__value">
                      {(c.member_count ?? 0).toLocaleString()}
                    </span>
                  </div>
                ))}
              </div>
            )}
          </Ds.Section>

          <Ds.Section title="Open Tasks" subtitle="Items that need your attention">
            <div className="ds-task-list">
              <button
                type="button"
                className="ds-task-item"
                onClick={() => onChangeTab('applications')}
              >
                <span
                  className="ds-task-item__icon"
                  style={{ background: 'var(--brand-blue-50)', color: 'var(--brand-blue)' }}
                >
                  <IconClipboardList size={16} />
                </span>
                <div className="ds-task-item__body">
                  <div className="ds-task-item__title">Pending applications</div>
                  <div className="ds-task-item__desc">Review and approve membership requests</div>
                </div>
                <span
                  className={Ds.cx('ds-task-item__count', !pendingAppsCount && 'ds-task-item__count--zero')}
                >
                  {pendingAppsCount}
                </span>
                <IconChevronRight size={16} className="ds-task-item__chevron" />
              </button>

              <button
                type="button"
                className="ds-task-item"
                onClick={() => onChangeTab('marketplace')}
              >
                <span
                  className="ds-task-item__icon"
                  style={{ background: 'var(--brand-amber-50)', color: 'var(--brand-amber-600)' }}
                >
                  <IconBuildingStore size={16} />
                </span>
                <div className="ds-task-item__body">
                  <div className="ds-task-item__title">Marketplace approvals</div>
                  <div className="ds-task-item__desc">Listings awaiting moderation</div>
                </div>
                <span
                  className={Ds.cx('ds-task-item__count', !pendingListingsCount && 'ds-task-item__count--zero')}
                >
                  {pendingListingsCount}
                </span>
                <IconChevronRight size={16} className="ds-task-item__chevron" />
              </button>

              <button
                type="button"
                className="ds-task-item"
                onClick={() => onChangeTab('rewards')}
              >
                <span
                  className="ds-task-item__icon"
                  style={{ background: 'var(--success-bg)', color: 'var(--success)' }}
                >
                  <IconGift size={16} />
                </span>
                <div className="ds-task-item__body">
                  <div className="ds-task-item__title">Privilege cards</div>
                  <div className="ds-task-item__desc">Manage member rewards and benefits</div>
                </div>
                <IconChevronRight size={16} className="ds-task-item__chevron" />
              </button>
            </div>
          </Ds.Section>
        </div>
      </div>
    </section>
  );
}


export default function App() {
  // Public onboarding wizard — token-authenticated, bypasses the admin login.
  if (typeof window !== 'undefined' && window.location.pathname.startsWith('/onboard')) {
    return <OnboardingPage />;
  }

  const [isAuthenticated, setIsAuthenticated] = useState(() => !!localStorage.getItem('access_token'));
  const [adminUser, setAdminUser] = useState(null);
  const [activeTab, setActiveTab] = useState(() => {
    return localStorage.getItem('active_tab') || 'overview';
  });

  useEffect(() => {
    localStorage.setItem('active_tab', activeTab);
  }, [activeTab]);

  const [showChangePassword, setShowChangePassword] = useState(false);
  const { toasts, showToast } = useToast();
  
  // Notification State
  const [notifications, setNotifications] = useState([]);
  const [unreadCount, setUnreadCount] = useState(0);

  const fetchNotifications = useCallback(async () => {
    if (!isAuthenticated) return;
    try {
      const data = await api.listNotifications();
      // data is { notifications: [], total_unread: number } from backend
      setNotifications(data.notifications || []);
      setUnreadCount(data.total_unread || 0);
    } catch (err) {
      console.error('Failed to fetch notifications:', err);
    }
  }, [isAuthenticated]);

  useEffect(() => {
    fetchNotifications();
    // Poll for new notifications every 60 seconds
    const interval = setInterval(fetchNotifications, 60000);
    return () => clearInterval(interval);
  }, [fetchNotifications]);

  useEffect(() => {
    // If we have a token but no user data, try to fetch current user
    if (isAuthenticated && !adminUser) {
      api.getCurrentUser().then(data => setAdminUser(data)).catch(() => handleLogout());
    }
  }, [isAuthenticated, adminUser]);

  const { data: overview, loading: overviewLoading, error: overviewError } = useApi(
    isAuthenticated ? api.getAdminOverview : () => Promise.resolve(null),
    [isAuthenticated]
  );

  const handleLogin = (user) => {
    setAdminUser(user);
    setIsAuthenticated(true);
    showToast(`Welcome back, ${user.full_name || 'Admin'}!`);
  };

  const handleLogout = () => {
    localStorage.removeItem('access_token');
    localStorage.removeItem('refresh_token');
    localStorage.removeItem('active_tab');
    setIsAuthenticated(false);
    setAdminUser(null);
    setActiveTab('overview');
  };

  const dismissNotification = async (id) => {
    try {
      await api.markNotificationRead(id);
      // Optimistic update
      setNotifications(prev => prev.map(n => n.id === id ? { ...n, is_read: true } : n));
      setUnreadCount(prev => Math.max(0, prev - 1));
    } catch (err) {
      console.error('Failed to mark notification read:', err);
    }
  };

  const markAllRead = async () => {
    try {
      await api.markAllNotificationsRead();
      setNotifications(prev => prev.map(n => ({ ...n, is_read: true })));
      setUnreadCount(0);
      showToast('All notifications marked as read');
    } catch (err) {
      console.error('Failed to mark all notifications read:', err);
    }
  };

  // Maps a backend notification `data.route` to an admin-panel tab.
  // Routes that only exist in the mobile app (e.g. /my-applications) fall back
  // to the closest admin tab so the click always lands somewhere sensible.
  const NOTIF_ROUTE_TO_TAB = {
    '/applications': 'applications',
    '/my-applications': 'applications',
    '/members': 'members',
    '/payments': 'payments',
    '/community': 'community',
    '/referrals': 'referrals',
    '/my-referrals': 'referrals',
    '/events': 'events',
    '/marketplace': 'marketplace',
    '/clubs': 'clubs',
  };

  const openNotification = async (n) => {
    // Mark read (optimistic) — reuse the single-read flow.
    if (n && !n.is_read) dismissNotification(n.id);

    const route = n?.data?.route || '';
    const tab = NOTIF_ROUTE_TO_TAB[route] || route.replace(/^\//, '');
    if (tab) {
      setActiveTab(tab);
    } else {
      showToast('Opened notification');
    }
  };

  if (!isAuthenticated) {
    return <LoginPage onLogin={handleLogin} />;
  }


  const renderContent = () => {
    const commonProps = { adminUser, showToast, onShowChangePassword: () => setShowChangePassword(true) };
    if (activeTab === 'applications') return <ApplicationsPage />;
    if (activeTab === 'members') return <MembersPage />;
    if (activeTab === 'user-management') {
      if (adminUser?.role !== 'SUPER_ADMIN') return <MembersPage />;
      return <UserManagementPage adminUser={adminUser} />;
    }
    if (activeTab === 'chapters') return <ChaptersPage />;
    if (activeTab === 'marketplace') return <MarketplacePage />;
    if (activeTab === 'payments') return <PaymentsPage />;
    if (activeTab === 'rewards') return <RewardsHubPage />;
    if (activeTab === 'referrals') return <ReferralsPage />;
    if (activeTab === 'community') return <CommunityPage showToast={showToast} />;
    if (activeTab === 'events') return <EventsPage />;
    if (activeTab === 'home-slides') return <HomeSlidesPage />;
    if (activeTab === 'clubs') return <ClubsPage />;
    if (activeTab === 'complements') return <ComplementsPage />;
    if (activeTab === 'revenue') return <RevenuePage onNavigateToGovernance={() => setActiveTab('governance')} />;
    if (activeTab === 'governance') return <GovernancePage onBack={() => setActiveTab('revenue')} />;
    if (activeTab === 'settings') return <SettingsPage {...commonProps} />;
    if (activeTab === 'mailbox') {
      if (adminUser?.role !== 'SUPER_ADMIN' && adminUser?.role !== 'ADMIN') return <MembersPage />;
      return <MailboxPage showToast={showToast} />;
    }
    if (activeTab === 'notifications') return <SecurityLogsPage adminUser={adminUser} />;

    // Default: Analytics Hub
    return (
      <AnalyticsHubPage
        overview={overview}
        overviewLoading={overviewLoading}
        overviewError={overviewError}
        onChangeTab={setActiveTab}
        showToast={showToast}
      />
    );
  };

  return (
    <>
      <ToastContainer toasts={toasts} />
      {showChangePassword && (
        <ChangePasswordModal
          onClose={() => setShowChangePassword(false)}
          showToast={showToast}
        />
      )}
      <AppShell
        activeTab={activeTab}
        onChangeTab={setActiveTab}
        adminUser={adminUser}
        notifications={notifications}
        unreadCount={unreadCount}
        onDismissNotification={dismissNotification}
        onOpenNotification={openNotification}
        onMarkAllRead={markAllRead}
        onChangePassword={() => setShowChangePassword(true)}
        onLogout={handleLogout}
      >
        {renderContent()}
      </AppShell>
    </>
  );
}
