import React, { useState, useEffect, useCallback, useRef } from 'react';
import {
  IconChartBar,
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
} from '@tabler/icons-react';
import { api, STATIC_BASE_URL } from './lib/api';
import { useApi } from './hooks/useApi';
import { AppShell } from './components/layout/AppShell';
import * as Ds from './components/ui';
import DatePicker from 'react-datepicker';
import 'react-datepicker/dist/react-datepicker.css';


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

  useEffect(() => {
    setLoading(true);
    setErrorMessage('');
    Promise.all([
      api.getApplication(appId),
      api.listChapters({ active_only: true }).catch(() => []),
    ])
      .then(([appData, chaptersData]) => {
        setDetail(appData);
        setChapters(chaptersData || []);
        if (appData.chapter_id) setSelectedChapterId(appData.chapter_id);
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

    setUpdating(true);
    try {
      await api.updateApplicationStatus(appId, {
        status: newStatus,
        notes: actionNotes || undefined,
        chapter_id: selectedChapterId || undefined,
        payment_status: newStatus === 'approved' ? paymentStatus : undefined,
        fit_call_date: newStatus === 'fit_call_scheduled' ? fitCallDate.toISOString() : undefined,
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
            <h2 style={{ fontSize: '1.5rem', fontWeight: 800 }}>Application Details</h2>
            <p style={{ color: 'var(--text-secondary)', fontSize: '0.875rem', marginTop: '0.25rem' }}>
              Review and manage this membership application
            </p>
          </div>
          <div style={{ display: 'flex', gap: '0.75rem', alignItems: 'center' }}>
            <button 
              type="button" 
              className="view-detail-btn" 
              style={{ color: '#ef4444', borderColor: 'transparent', background: '#fef2f2' }} 
              onClick={handleDelete}
              title="Delete Application"
              disabled={updating}
            >
              <IconTrash size={20} />
            </button>
            <button type="button" className="modal-close-btn" onClick={onClose}>
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
          <div className="detail-grid">
            <div className="detail-item">
              <label>Full Name</label>
              <p>{detail.full_name}</p>
            </div>
            <div className="detail-item">
              <label>Business Name</label>
              <p>{detail.business_name}</p>
            </div>
            <div className="detail-item">
              <label>Contact Number</label>
              <p>{detail.contact_number}</p>
            </div>
            <div className="detail-item">
              <label>Email</label>
              <p>{detail.email || '—'}</p>
            </div>
            <div className="detail-item">
              <label>Targetted Chapter</label>
              <p>{detail.chapter_name || '—'}</p>
            </div>
            <div className="detail-item">
              <label>Fit Call Date</label>
              <p>{detail.fit_call_date ? new Date(detail.fit_call_date).toLocaleDateString() : '—'}</p>
            </div>
          </div>

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
                  Select the chapter and confirming the initial payment status if previously received.
                </p>
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
                style={isDisabled ? { color: '#94a3b8', cursor: 'not-allowed', background: '#f8fafc', pointerEvents: 'none' } : {}}
              >
                {opt.name || opt.label}
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
  const [chapterFilter, setChapterFilter] = useState('');
  const [industryFilter, setIndustryFilter] = useState('');
  const [roleFilter, setRoleFilter] = useState('');
  const [selectedUser, setSelectedUser] = useState(null);

  const [chapters, setChapters] = useState([]);
  const [industries, setIndustries] = useState([]);

  const fetchMembers = useCallback(async () => {
    setLoading(true);
    try {
      const params = { page, limit: 15 };
      if (search) params.search = search;
      if (chapterFilter) params.chapter_id = chapterFilter;
      if (industryFilter) params.industry_id = industryFilter;
      if (roleFilter) params.role = roleFilter;

      const result = await api.listUsers(params);
      setUsers(result.users || []);
      setTotal(result.total || 0);
      setPages(Math.ceil(result.total / (result.page_size || 15)) || 1);
    } catch (err) {
      console.error('Failed to load members:', err);
    } finally {
      setLoading(false);
    }
  }, [page, search, chapterFilter, industryFilter, roleFilter]);

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
            placeholder="All chapters"
            value={chapterFilter}
            options={chapters}
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
              <tr key={user.id} className="is-clickable" onClick={() => setSelectedUser(user)}>
                <td>
                  <div style={{ display: 'flex', alignItems: 'center', gap: 'var(--space-3)' }}>
                    <Ds.Avatar size="sm" name={user.full_name || '?'} />
                    <div style={{ minWidth: 0 }}>
                      <div className="ds-table__primary">{user.full_name || 'Unnamed User'}</div>
                      <div style={{ fontSize: 'var(--text-xs)', color: 'var(--fg-muted)', fontWeight: 'var(--weight-medium)' }}>
                        {user.phone_number}
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
      </div>
    </section>
  );
}

// ── Security Logs Page ────────────────────────────────────────────────────
function SecurityLogsPage() {
  return (
    <section className="ds-page">
      <Ds.PageHeader
        title="Security & Audit"
        description="Timeline of critical administrative actions and system events."
      />
      <Ds.Section>
        <Ds.EmptyState
          icon={IconLock}
          title="Audit logging module"
          description="Real-time audit logs are currently being initialized for the network."
        />
      </Ds.Section>
    </section>
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
        subtitle={`${chapters.length} active across the network`}
        flush
      >
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
            ) : chapters.length === 0 ? (
              <Ds.Table.EmptyRow
                colSpan={5}
                icon={IconBuildingCommunity}
                title="No chapters yet"
                description="Add the first chapter to get started."
              />
            ) : chapters.map(c => (
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
    is_active: chapter?.is_active ?? true
  });

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
  const [isAuthenticated, setIsAuthenticated] = useState(() => !!localStorage.getItem('access_token'));
  const [adminUser, setAdminUser] = useState(null);
  const [activeTab, setActiveTab] = useState('overview');
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
    setIsAuthenticated(false);
    setAdminUser(null);
    setShowProfileMenu(false);
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

  if (!isAuthenticated) {
    return <LoginPage onLogin={handleLogin} />;
  }


  const renderContent = () => {
    const commonProps = { adminUser, showToast, onShowChangePassword: () => setShowChangePassword(true) };
    if (activeTab === 'applications') return <ApplicationsPage />;
    if (activeTab === 'members') return <MembersPage />;
    if (activeTab === 'chapters') return <ChaptersPage />;
    if (activeTab === 'marketplace') return <MarketplacePage />;
    if (activeTab === 'payments') return <PaymentsPage />;
    if (activeTab === 'rewards') return <RewardsHubPage />;
    if (activeTab === 'referrals') return <ReferralsPage />;
    if (activeTab === 'events') return <EventsPage />;
    if (activeTab === 'clubs') return <ClubsPage />;
    if (activeTab === 'revenue') return <RevenuePage onNavigateToGovernance={() => setActiveTab('governance')} />;
    if (activeTab === 'governance') return <GovernancePage onBack={() => setActiveTab('revenue')} />;
    if (activeTab === 'settings') return <SettingsPage {...commonProps} />;
    if (activeTab === 'notifications') return <SecurityLogsPage />;

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
        onMarkAllRead={markAllRead}
        onChangePassword={() => setShowChangePassword(true)}
        onLogout={handleLogout}
      >
        {renderContent()}
      </AppShell>
    </>
  );
}
