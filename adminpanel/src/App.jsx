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
} from '@tabler/icons-react';
import { api, STATIC_BASE_URL } from './lib/api';
import { useApi } from './hooks/useApi';
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

const MENU_GROUPS = [
  {
    label: 'Main Dashboard',
    links: [
      { id: 'overview', icon: IconChartBar, label: 'Analytics Hub' },
      { id: 'members', icon: IconUsers, label: 'Member Directory' },
    ]
  },
  {
    label: 'Operations',
    links: [
      { id: 'applications', icon: IconClipboardList, label: 'Applications' },
      { id: 'referrals', icon: IconHierarchy2, label: 'Referral Pipeline' },
      { id: 'events', icon: IconCalendarEvent, label: 'Event Management' },
      { id: 'payments', icon: IconCoin, label: 'Payments' },
      { id: 'revenue', icon: IconChartBar, label: 'Revenue & ROI' },
    ]
  },
  {
    label: 'Expansion',
    links: [
      { id: 'rewards', icon: IconBuildingStore, label: 'Rewards Hub' },
      { id: 'clubs', icon: IconHierarchy2, label: 'Horizontal Clubs' },
    ]
  },
  {
    label: 'System & Security',
    links: [
      { id: 'settings', icon: IconSettings, label: 'Global Settings' },
      { id: 'notifications', icon: IconBell, label: 'Security Logs' },
    ]
  }
];

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

// ── Status Helpers ──────────────────────────────────────────────────────────

const STATUS_CONFIG = {
  pending: { label: 'Pending', class: 'pill-pending', color: '#f59e0b', bg: '#fffbeb' },
  fit_call_scheduled: { label: 'Fit Call Scheduled', class: 'pill-scheduled', color: '#8b5cf6', bg: '#f5f3ff' },
  approved: { label: 'Approved', class: 'pill-approved', color: '#059669', bg: '#ecfdf5' },
  rejected: { label: 'Rejected', class: 'pill-rejected', color: '#dc2626', bg: '#fef2f2' },
  waitlisted: { label: 'Waitlisted', class: 'pill-waitlisted', color: '#6b7280', bg: '#f9fafb' },
};

const getStatusConfig = (status) => STATUS_CONFIG[status] || { label: status, class: '', color: '#6b7280', bg: '#f9fafb' };

const StatusPill = ({ status }) => {
  const cfg = getStatusConfig(status);
  return (
    <span className="pill" style={{ background: cfg.bg, color: cfg.color }}>
      {cfg.label}
    </span>
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
      api.listChapters().catch(() => ({ data: [] })),
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
    <div className="modal-overlay" onClick={onClose}>
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
    <div className="modal-overlay" onClick={onClose}>
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
          api.listChapters()
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
    <div className="modal-overlay" onClick={onClose}>
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

        <form onSubmit={handleSubmit} style={{ padding: '1.5rem 1.5rem 8rem' }}>
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

          <div style={{ display: 'grid', gridTemplateColumns: '1fr 1fr', gap: '1rem', marginBottom: '1.5rem' }}>
            <div>
              <label style={{ fontSize: '0.75rem', fontWeight: 700, color: 'var(--text-secondary)', textTransform: 'uppercase', letterSpacing: '0.05em', display: 'block', marginBottom: '0.5rem' }}>Target Chapter *</label>
              <CustomSelect
                label={loadingInitial ? "Loading..." : "Select Chapter..."}
                value={formData.chapter_id}
                options={chapters}
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
    <section className="dashboard-body">
      <div className="page-title-wrap">
        <h1 className="page-title">Member Applications</h1>
        <p style={{ color: 'var(--text-secondary)', marginTop: '0.4rem', fontWeight: 500 }}>
          Review, approve, and manage membership applications across the network.
        </p>
      </div>

      {/* Stats Row */}
      <div className="stat-grid" style={{ marginBottom: '2rem' }}>
        <StatCard title="TOTAL APPLICATIONS" value={total} icon={IconClipboardList} color="#2563eb" />
        <StatCard title="PENDING REVIEW" value={apps.filter(a => a.status === 'pending').length} icon={IconClock} color="#f59e0b" />
        <StatCard title="APPROVED" value={apps.filter(a => a.status === 'approved').length} icon={IconCheck} color="#059669" />
        <StatCard title="REJECTED" value={apps.filter(a => a.status === 'rejected').length} icon={IconX} color="#dc2626" />
      </div>

      {/* Table */}
      <div className="data-section">
        <div className="section-head">
          <div>
            <h3 style={{ fontSize: '1.25rem', fontWeight: 800 }}>Application Queue</h3>
            <p style={{ fontSize: '0.85rem', color: 'var(--text-secondary)', marginTop: '0.2rem' }}>
              Click on any application to view details and take action.
            </p>
          </div>
          <div style={{ display: 'flex', gap: '0.75rem', alignItems: 'center' }}>
            {/* Status Filter Chips */}
            <div className="filter-chips">
              {statusFilters.map(f => (
                <button
                  key={f.value}
                  className={`filter-chip ${statusFilter === f.value ? 'active' : ''}`}
                  onClick={() => { setStatusFilter(f.value); setPage(1); }}
                >
                  {f.label}
                </button>
              ))}
            </div>
            <button
              className="btn-primary"
              style={{ display: 'flex', alignItems: 'center', gap: '0.5rem', padding: '0.6rem 1.25rem', background: '#10b981' }}
              onClick={() => setShowCreateModal(true)}
            >
              <IconPlus size={16} />
              Add Application
            </button>
            <button
              className="btn-primary"
              style={{ display: 'flex', alignItems: 'center', gap: '0.5rem', padding: '0.6rem 1.25rem' }}
              onClick={fetchApps}
            >
              <IconRefresh size={16} />
              Refresh
            </button>
          </div>
        </div>

        <table className="modern-table">
          <thead>
            <tr>
              <th>Applicant</th>
              <th>Business</th>
              <th>Contact</th>
              <th>Targetted Chapter</th>
              <th>Status</th>
              <th>Applied On</th>
              <th>Actions</th>
            </tr>
          </thead>
          <tbody>
            {loading ? (
              <tr><td colSpan={7} style={{ textAlign: 'center', padding: '3rem', color: '#94a3b8' }}>
                <div style={{ display: 'flex', flexDirection: 'column', alignItems: 'center', gap: '0.75rem' }}>
                  <div style={{ width: 28, height: 28, border: '3px solid #e2e8f0', borderTopColor: 'var(--primary)', borderRadius: '50%', animation: 'spin 1s linear infinite' }} />
                  Loading applications...
                </div>
              </td></tr>
            ) : apps.length === 0 ? (
              <tr><td colSpan={7} style={{ textAlign: 'center', padding: '3rem', color: '#94a3b8' }}>
                <IconClipboardList size={40} stroke={1.2} color="#cbd5e1" style={{ marginBottom: '0.75rem' }} />
                <p style={{ fontWeight: 600 }}>No applications found</p>
                <p style={{ fontSize: '0.8rem', marginTop: '0.25rem' }}>Try changing the status filter above.</p>
              </td></tr>
            ) : apps.map((app, idx) => (
              <tr key={app.id || idx} className="table-row-clickable" onClick={() => setSelectedAppId(app.id)}>
                <td>
                  <div style={{ display: 'flex', alignItems: 'center', gap: '0.75rem' }}>
                    <div className="avatar-sm" style={{ background: `hsl(${(app.full_name || '').charCodeAt(0) * 7 % 360}, 60%, 92%)`, color: `hsl(${(app.full_name || '').charCodeAt(0) * 7 % 360}, 60%, 35%)` }}>
                      {(app.full_name || '?')[0]}
                    </div>
                    <span style={{ fontWeight: 700 }}>{app.full_name}</span>
                  </div>
                </td>
                <td style={{ fontWeight: 500 }}>{app.business_name}</td>
                <td style={{ color: 'var(--text-secondary)' }}>{app.contact_number}</td>
                <td style={{ color: 'var(--text-secondary)' }}>{app.chapter_name || '—'}</td>
                <td><StatusPill status={app.status} /></td>
                <td style={{ color: 'var(--text-secondary)', fontSize: '0.875rem' }}>
                  {new Date(app.created_at).toLocaleDateString()}
                </td>
                <td>
                  <button className="view-detail-btn" onClick={e => { e.stopPropagation(); setSelectedAppId(app.id); }}>
                    <IconEye size={18} />
                  </button>
                </td>
              </tr>
            ))}
          </tbody>
        </table>

        {/* Pagination */}
        <div style={{ padding: '1.25rem 2.5rem', background: '#f8fafc', display: 'flex', justifyContent: 'space-between', alignItems: 'center' }}>
          <p style={{ fontSize: '0.8125rem', color: 'var(--text-secondary)', fontWeight: 600 }}>
            {total > 0 ? `Showing page ${page} of ${pages} · ${total} total applications` : 'No records found'}
          </p>
          {pages > 1 && (
            <div style={{ display: 'flex', gap: '0.5rem' }}>
              <button
                className="pagination-btn"
                disabled={page <= 1}
                onClick={() => setPage(p => Math.max(1, p - 1))}
              >
                <IconChevronLeft size={16} /> Prev
              </button>
              <button
                className="pagination-btn"
                disabled={page >= pages}
                onClick={() => setPage(p => p + 1)}
              >
                Next <IconChevronRight size={16} />
              </button>
            </div>
          )}
        </div>

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
      </div>
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
    <div className="modal-overlay" onClick={onClose}>
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

  return (
    <section className="dashboard-body">
      <div className="page-title-wrap">
        <h1 className="page-title">Member Directory</h1>
        <p style={{ color: 'var(--text-secondary)', marginTop: '0.4rem', fontWeight: 500 }}>
          Browse, filter, and search through all members and prospects in the network.
        </p>
      </div>

      <div className="data-section">
        <div className="section-head" style={{ flexDirection: 'column', alignItems: 'stretch', gap: '1.5rem' }}>
          <div style={{ display: 'flex', justifyContent: 'space-between', alignItems: 'center' }}>
            <h3 style={{ fontSize: '1.25rem', fontWeight: 800 }}>Network Registry</h3>
            <button className="btn-primary" onClick={() => { setPage(1); fetchMembers(); }} style={{ display: 'flex', alignItems: 'center', gap: '0.5rem' }}>
              <IconRefresh size={18} /> Refresh
            </button>
          </div>

          <div className="directory-filters" style={{ display: 'flex', gap: '1rem', flexWrap: 'wrap' }}>
            <div style={{ flex: 1, minWidth: '250px', position: 'relative' }}>
              <IconSearch size={18} style={{ position: 'absolute', left: '12px', top: '50%', transform: 'translateY(-50%)', color: '#94a3b8' }} />
              <input
                type="text"
                placeholder="Search by name, phone or chapter..."
                className="filter-input v2"
                style={{ paddingLeft: '40px', width: '100%', height: '48px' }}
                value={search}
                onChange={e => { setSearch(e.target.value); setPage(1); }}
              />
            </div>
            <CustomSelect
              label="All Chapters"
              value={chapterFilter}
              options={chapters}
              onChange={(val) => { setChapterFilter(val); setPage(1); }}
              style={{ width: '220px' }}
            />

            <CustomSelect
              label="All Industries (Network)"
              value={industryFilter}
              options={industries}
              onChange={(val) => { setIndustryFilter(val); setPage(1); }}
              style={{ width: '240px' }}
            />

            <CustomSelect
              label="All Roles"
              value={roleFilter}
              options={[
                { id: 'MEMBER', name: 'Members' },
                { id: 'PROSPECT', name: 'Prospects' },
                { id: 'CHAPTER_ADMIN', name: 'Chapter Admins' },
                { id: 'PARTNER_ADMIN', name: 'Partner Admins' }
              ]}
              onChange={(val) => { setRoleFilter(val); setPage(1); }}
              style={{ width: '200px' }}
            />
          </div>
        </div>

        <table className="modern-table">
          <thead>
            <tr>
              <th>Member Name</th>
              <th>Chapter</th>
              <th>Network (Industry)</th>
              <th>Role</th>
              <th>Status</th>
              <th>Joined Date</th>
            </tr>
          </thead>
          <tbody>
            {loading ? (
              <tr><td colSpan={6} style={{ textAlign: 'center', padding: '3rem' }}>
                <div style={{ display: 'flex', flexDirection: 'column', alignItems: 'center', gap: '0.75rem' }}>
                  <div style={{ width: 28, height: 28, border: '3px solid #e2e8f0', borderTopColor: 'var(--primary)', borderRadius: '50%', animation: 'spin 1s linear infinite' }} />
                  Loading directory...
                </div>
              </td></tr>
            ) : users.length === 0 ? (
              <tr><td colSpan={6} style={{ textAlign: 'center', padding: '3rem', color: '#94a3b8' }}>No members found matching your criteria.</td></tr>
            ) : users.map(user => (
              <tr key={user.id} className="table-row-clickable" onClick={() => setSelectedUser(user)}>
                <td>
                  <div style={{ display: 'flex', alignItems: 'center', gap: '0.75rem' }}>
                    <div className="avatar-sm" style={{ background: '#f1f5f9', color: 'var(--primary)' }}>
                      {user.full_name ? user.full_name[0] : '?'}
                    </div>
                    <div>
                      <div style={{ fontWeight: 700 }}>{user.full_name || 'Unnamed User'}</div>
                      <div style={{ fontSize: '0.75rem', color: 'var(--text-secondary)' }}>{user.phone_number}</div>
                    </div>
                  </div>
                </td>
                <td>
                  {user.chapter_name ? (
                    <span className="id-badge" style={{ background: '#e0f2fe', color: '#0369a1' }}>{user.chapter_name}</span>
                  ) : <span style={{ color: '#94a3b8', fontSize: '0.85rem' }}>No Chapter</span>}
                </td>
                <td>{user.industry_name || '—'}</td>
                <td>
                  <span style={{ fontSize: '0.85rem', fontWeight: 600, color: user.role === 'PROSPECT' ? '#f59e0b' : '#64748b' }}>
                    {user.role}
                    {user.membership_type && user.membership_type !== 'standard' && (
                      <span style={{ marginLeft: '6px', fontSize: '0.7rem', background: '#fef3c7', color: '#92400e', padding: '2px 6px', borderRadius: '4px' }}>
                        {user.membership_type.replace('_', ' ').toUpperCase()}
                      </span>
                    )}
                  </span>
                </td>
                <td>
                  <span className={`pill ${user.is_active
                      ? 'pill-approved'
                      : user.role === 'PROSPECT'
                        ? 'pill-awaiting-payment'
                        : 'pill-rejected'
                    }`}>
                    {user.is_active ? 'Active' : user.role === 'PROSPECT' ? 'Awaiting Payment' : 'Inactive'}
                  </span>
                </td>
                <td style={{ fontSize: '0.85rem', color: 'var(--text-secondary)' }}>
                  {user.created_at ? new Date(user.created_at).toLocaleDateString() : '—'}
                </td>
              </tr>
            ))}
          </tbody>
        </table>

        {/* Pagination */}
        <div style={{ padding: '1.25rem 2.5rem', background: '#f8fafc', display: 'flex', justifyContent: 'space-between', alignItems: 'center' }}>
          <p style={{ fontSize: '0.8125rem', color: 'var(--text-secondary)', fontWeight: 600 }}>
            {total > 0 ? `Showing page ${page} of ${pages} · ${total} users` : 'No members found'}
          </p>
          {pages > 1 && (
            <div style={{ display: 'flex', gap: '0.5rem' }}>
              <button className="pagination-btn" disabled={page <= 1} onClick={() => setPage(p => p - 1)}><IconChevronLeft size={16} /> Prev</button>
              <button className="pagination-btn" disabled={page >= pages} onClick={() => setPage(p => p + 1)}>Next <IconChevronRight size={16} /></button>
            </div>
          )}
        </div>
      </div>

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
    <div className="modal-overlay" onClick={onClose}>
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
    <div className="modal-overlay" onClick={onClose}>
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

  return (
    <section className="dashboard-body">
      <div className="page-title-wrap" style={{ display: 'flex', justifyContent: 'space-between', alignItems: 'center' }}>
        <div>
          <h1 className="page-title">Payment Management</h1>
          <p style={{ color: 'var(--text-secondary)', marginTop: '0.4rem', fontWeight: 500 }}>
            Track and record all network transactions and membership fees.
          </p>
        </div>
        <button className="btn-primary" onClick={() => setShowRecordModal(true)} style={{ display: 'flex', alignItems: 'center', gap: '0.6rem' }}>
          <IconCoin size={20} /> Record Direct Payment
        </button>
      </div>

      <div className="data-section">
        <div className="section-head">
          <h3 style={{ fontSize: '1.25rem', fontWeight: 800 }}>Transaction History</h3>
          <button className="view-detail-btn" onClick={fetchPayments}><IconRefresh size={18} /></button>
        </div>

        <table className="modern-table">
          <thead>
            <tr>
              <th>Date</th>
              <th>User</th>
              <th>Reason</th>
              <th>Type</th>
              <th>Amount</th>
              <th>Status</th>
              <th>Actions</th>
            </tr>
          </thead>
          <tbody>
            {loading ? (
              <tr><td colSpan={7} style={{ textAlign: 'center', padding: '3rem' }}>Loading payments...</td></tr>
            ) : payments.length === 0 ? (
              <tr><td colSpan={7} style={{ textAlign: 'center', padding: '3rem' }}>No payments found.</td></tr>
            ) : payments.map(p => (
              <tr key={p.id}>
                <td style={{ fontSize: '0.85rem', color: 'var(--text-secondary)' }}>
                  {new Date(p.created_at).toLocaleDateString()}
                </td>
                <td>
                  <div style={{ fontWeight: 600 }}>{p.user_name || 'Unknown'}</div>
                  <div style={{ fontSize: '0.75rem', color: 'var(--text-secondary)' }}>{p.user_phone}</div>
                </td>
                <td style={{ maxWidth: 200, overflow: 'hidden', textOverflow: 'ellipsis', whiteSpace: 'nowrap' }}>
                  {p.reason || '—'}
                </td>
                <td><span className="id-badge">{p.payment_type}</span></td>
                <td style={{ fontWeight: 700 }}>{formatCurrency(p.amount)}</td>
                <td>
                  <span className={`pill ${p.status === 'completed' ? 'pill-approved' : 'pill-pending'}`}>
                    {p.status}
                  </span>
                </td>
                <td>
                  <button className="view-detail-btn" onClick={() => setEditingPayment(p)}>
                    <IconSettings size={18} />
                  </button>
                </td>
              </tr>
            ))}
          </tbody>
        </table>
      </div>

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
    <div className="modal-overlay" onClick={onClose}>
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
    <div className="modal-overlay" onClick={onClose}>
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
    <div className="modal-overlay" onClick={onClose}>
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

function PartnersPage() {
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
    <section className="dashboard-body">
      <div className="page-title-wrap">
        <h1 className="page-title">Rewards & Network Partners</h1>
        <p style={{ color: 'var(--text-secondary)', marginTop: '0.4rem', fontWeight: 500 }}>
          Manage business alliances and member exclusive privileges.
        </p>
      </div>

      <div className="stat-grid" style={{ marginBottom: '2rem' }}>
        <StatCard title="TOTAL PARTNERS" value={partners.length} icon={IconBuildingStore} color="#2563eb" />
        <StatCard title="ACTIVE OFFERS" value={partners.reduce((acc, p) => acc + (p.offers?.length || 0), 0)} icon={IconGift} color="#059669" />
        <StatCard title="PARTNER REVENUE" value="LKR 4.2M" icon={IconCoin} color="#f59e0b" />
      </div>

      <div className="data-section">
        <div className="section-head">
          <h3 style={{ fontSize: '1.25rem', fontWeight: 800 }}>Partner Directory</h3>
          <button className="btn-primary" onClick={() => setShowAddPartner(true)} style={{ display: 'flex', alignItems: 'center', gap: '0.5rem' }}>
            <IconPlus size={18} /> Add Partner
          </button>
        </div>

        {loading ? (
          <div style={{ padding: '4rem', textAlign: 'center' }}>Loading partners...</div>
        ) : (
          <div className="partners-list" style={{ padding: '0 1.5rem 1.5rem' }}>
            {partners.length === 0 ? (
              <div style={{ padding: '3rem', textAlign: 'center', color: '#94a3b8' }}>No partners registered yet.</div>
            ) : partners.map(partner => (
              <div key={partner.id} className="partner-card-row" style={{ display: 'flex', alignItems: 'center', gap: '1.5rem', padding: '1.5rem', border: '1px solid #e2e8f0', borderRadius: '12px', marginBottom: '1rem', background: 'white' }}>
                <div style={{ width: 64, height: 64, borderRadius: '12px', background: 'white', overflow: 'hidden', display: 'flex', alignItems: 'center', justifyContent: 'center', border: '1px solid #e2e8f0' }}>
                  {partner.logo_url ? <img src={partner.logo_url.startsWith('http') ? partner.logo_url : `${STATIC_BASE_URL}${partner.logo_url}`} style={{ width: '100%', height: '100%', objectFit: 'contain' }} /> : <IconBuildingStore size={24} color="#94a3b8" />}
                </div>
                <div style={{ flex: 1 }}>
                  <h4 style={{ fontSize: '1.1rem', fontWeight: 700 }}>{partner.name}</h4>
                  <p style={{ fontSize: '0.85rem', color: 'var(--text-secondary)', marginTop: '0.2rem' }}>{partner.offers?.length || 0} active rewards</p>
                  {partner.website && <a href={partner.website} target="_blank" rel="noreferrer" style={{ fontSize: '0.8rem', color: 'var(--secondary)', textDecoration: 'none', marginTop: '0.25rem', display: 'inline-block' }}>{partner.website}</a>}
                </div>
                <div style={{ display: 'flex', gap: '0.75rem' }}>
                  <button
                    className="view-detail-btn"
                    title="Add New Reward"
                    style={{ background: '#f0fdf4', color: '#059669', borderColor: '#bbf7d0' }}
                    onClick={() => setAddingOfferTo(partner)}
                  >
                    <IconPlus size={20} />
                  </button>
                  <button
                    className="view-detail-btn"
                    title="Edit Partner"
                    onClick={() => setEditingPartner(partner)}
                  >
                    <IconSettings size={20} />
                  </button>
                </div>
              </div>
            ))}
          </div>
        )}
      </div>

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
    </section>
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
  
  return (
    <section className="dashboard-body">
      <div className="page-title-wrap">
        <h1 className="page-title">Referral Pipeline</h1>
        <p style={{ color: 'var(--text-secondary)', marginTop: '0.4rem', fontWeight: 500 }}>
          Monitoring business exchanges and conversion velocity across the network.
        </p>
      </div>

      <div className="data-section">
        <div className="section-head" style={{ flexDirection: 'column', alignItems: 'stretch', gap: '1.5rem' }}>
          <div style={{ display: 'flex', justifyContent: 'space-between', alignItems: 'center' }}>
            <h3 style={{ fontSize: '1.25rem', fontWeight: 800 }}>Global Referral Stream</h3>
            <button className="btn-primary" onClick={() => { setPage(1); fetchReferrals(); }} style={{ display: 'flex', alignItems: 'center', gap: '0.5rem' }}>
              <IconRefresh size={18} /> Refresh
            </button>
          </div>

          <div className="directory-filters" style={{ display: 'flex', gap: '1rem', flexWrap: 'wrap' }}>
            <div style={{ flex: 1, minWidth: '300px', position: 'relative' }}>
              <IconSearch size={18} style={{ position: 'absolute', left: '12px', top: '50%', transform: 'translateY(-50%)', color: '#94a3b8' }} />
              <input
                type="text"
                placeholder="Search lead name, description or member..."
                className="filter-input v2"
                style={{ paddingLeft: '40px', width: '100%', height: '48px' }}
                value={search}
                onChange={e => { setSearch(e.target.value); setPage(1); }}
              />
            </div>

            <CustomSelect
              label="All Statuses"
              value={statusFilter}
              options={[
                { id: 'submitted', name: 'Submitted' },
                { id: 'contacted', name: 'Contacted' },
                { id: 'negotiation', name: 'Negotiation' },
                { id: 'in_progress', name: 'In Progress' },
                { id: 'success', name: 'Closed Won' },
                { id: 'closed_lost', name: 'Closed Lost' }
              ]}
              onChange={(val) => { setStatusFilter(val); setPage(1); }}
              style={{ width: '220px' }}
            />
          </div>
        </div>

        <table className="modern-table">
          <thead>
            <tr>
              <th>ID</th>
              <th>From</th>
              <th>To</th>
              <th>Lead Name</th>
              <th>Value</th>
              <th>Status</th>
              <th>Date</th>
            </tr>
          </thead>
          <tbody>
            {loading ? (
              <tr><td colSpan={7} style={{ textAlign: 'center', padding: '3rem' }}>Loading referrals...</td></tr>
            ) : !referrals || referrals.length === 0 ? (
              <tr><td colSpan={7} style={{ textAlign: 'center', padding: '3rem' }}>No referrals found.</td></tr>
            ) : referrals.map((ref, idx) => (
              <tr key={ref.id || idx}>
                <td><span className="id-badge">REF-{String(ref.id || idx).slice(0, 4)}</span></td>
                <td style={{ fontWeight: 600 }}>{ref.from_user?.full_name || '—'}</td>
                <td>{ref.target_user?.full_name || '—'}</td>
                <td style={{ fontWeight: 600 }}>{ref.lead_name || '—'}</td>
                <td style={{ fontWeight: 700 }}>{ref.actual_value ? `LKR ${ref.actual_value.toLocaleString()}` : '—'}</td>
                <td>
                  <span className={`pill ${ref.status === 'success' ? 'pill-approved' : ref.status === 'closed_lost' ? 'pill-rejected' : 'pill-pending'}`}>
                    {ref.status || 'pending'}
                  </span>
                </td>
                <td style={{ color: 'var(--text-secondary)' }}>{new Date(ref.created_at).toLocaleDateString()}</td>
              </tr>
            ))}
          </tbody>
        </table>

        {/* Pagination */}
        <div style={{ padding: '1.25rem 2.5rem', background: '#f8fafc', display: 'flex', justifyContent: 'space-between', alignItems: 'center' }}>
          <p style={{ fontSize: '0.8125rem', color: 'var(--text-secondary)', fontWeight: 600 }}>
            {total > 0 ? `Showing page ${page} of ${pages} · ${total} referrals` : 'No results matching criteria'}
          </p>
          {pages > 1 && (
            <div style={{ display: 'flex', gap: '0.5rem' }}>
              <button className="pagination-btn" disabled={page <= 1} onClick={() => setPage(p => p - 1)}>
                <IconChevronLeft size={16} /> Prev
              </button>
              <button className="pagination-btn" disabled={page >= pages} onClick={() => setPage(p => p + 1)}>
                Next <IconChevronRight size={16} />
              </button>
            </div>
          )}
        </div>
      </div>
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
    <div className="modal-overlay" onClick={onClose}>
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

  return (
    <section className="dashboard-body">
      <div className="page-title-wrap">
        <h1 className="page-title">Revenue & ROI Analysis</h1>
        <p style={{ color: 'var(--text-secondary)', marginTop: '0.4rem', fontWeight: 500 }}>
          Financial health and network growth metrics.
        </p>
      </div>

      <div style={{ marginBottom: '2rem', padding: '1.5rem', background: '#f8fafc', borderRadius: '16px', border: '1px solid #e2e8f0', display: 'flex', justifyContent: 'space-between', alignItems: 'center' }}>
        <div>
          <h3 style={{ fontWeight: 800, fontSize: '1rem' }}>Network Governance & Fees</h3>
          <p style={{ color: 'var(--text-secondary)', fontSize: '0.8rem', marginTop: '0.2rem' }}>Configure master rates for all membership tiers.</p>
        </div>
        <button className="btn-primary" onClick={onNavigateToGovernance} style={{ display: 'flex', alignItems: 'center', gap: '0.5rem', padding: '0.6rem 1.25rem', fontSize: '0.875rem' }}>
          <IconSettings size={18} /> Manage Fee Schedules
        </button>
      </div>

      <div className="stat-grid" style={{ marginBottom: '2rem' }}>
        <StatCard title="TOTAL REVENUE" value={formatCurrency(overview?.total_value)} icon={IconCoin} color="#059669" />
        <StatCard title="PENDING PAYMENTS" value={payments?.filter(p => p.status === 'pending').length || 0} icon={IconClock} color="#f59e0b" />
        <StatCard title="AVG CONVERSION" value={overview?.conversion_rate ? `${overview.conversion_rate}%` : '—'} icon={IconChartBar} color="#2563eb" />
      </div>

      <div className="data-section">
        <div className="section-head">
          <h3 style={{ fontSize: '1.25rem', fontWeight: 800 }}>Recent Financial Activity</h3>
        </div>
        <table className="modern-table">
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
              <tr><td colSpan={5} style={{ textAlign: 'center', padding: '2rem' }}>Loading payments...</td></tr>
            ) : (Array.isArray(payments) ? payments : payments?.data || []).slice(0, 10).map(p => (
              <tr key={p.id}>
                <td>{new Date(p.created_at).toLocaleDateString()}</td>
                <td style={{ fontWeight: 600 }}>{p.user_name}</td>
                <td>{p.payment_type}</td>
                <td style={{ fontWeight: 700 }}>{formatCurrency(p.amount)}</td>
                <td><span className={`pill ${p.status === 'completed' ? 'pill-approved' : 'pill-pending'}`}>{p.status}</span></td>
              </tr>
            ))}
          </tbody>
        </table>
      </div>
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
    <section className="dashboard-body">
      <div className="page-title-wrap" style={{ display: 'flex', justifyContent: 'space-between', alignItems: 'flex-start' }}>
        <div>
          <button 
            onClick={onBack}
            style={{ border: 'none', background: 'none', display: 'flex', alignItems: 'center', gap: '0.5rem', color: 'var(--text-secondary)', fontWeight: 700, marginBottom: '0.75rem', cursor: 'pointer', padding: 0 }}
          >
            <IconChevronLeft size={18} /> Back to Revenue
          </button>
          <h1 className="page-title">Fee Governance</h1>
          <p style={{ color: 'var(--text-secondary)', marginTop: '0.4rem', fontWeight: 500 }}>
            Official master rates as per Bylaws Article 8.
          </p>
        </div>
      </div>

      <div className="data-section">
        <div className="section-head">
          <h3 style={{ fontSize: '1.25rem', fontWeight: 800 }}>Master Rate Schedules</h3>
        </div>
        
        {loading ? (
          <div style={{ padding: '4rem', textAlign: 'center' }}>Loading governance data...</div>
        ) : (
          <div style={{ padding: '0 1.5rem 1.5rem' }}>
            <div style={{ display: 'grid', gridTemplateColumns: 'repeat(auto-fill, minmax(320px, 1fr))', gap: '1.5rem' }}>
              {fees.map(f => (
                <div key={f.membership_type} className="fee-card" style={{ padding: '1.5rem', border: '1px solid #e2e8f0', borderRadius: '20px', background: 'white', boxShadow: '0 4px 6px -1px rgb(0 0 0 / 0.1)' }}>
                  <div style={{ display: 'flex', justifyContent: 'space-between', alignItems: 'flex-start', marginBottom: '1.5rem' }}>
                    <span className="id-badge" style={{ background: 'var(--primary)', color: 'white', fontWeight: 800, fontSize: '0.75rem', padding: '4px 10px' }}>
                      {f.membership_type.toUpperCase()}
                    </span>
                    <button onClick={() => setEditingFee(f)} className="view-detail-btn" style={{ borderRadius: '50%', width: 36, height: 36, padding: 0, display: 'flex', alignItems: 'center', justifyContent: 'center' }}>
                      <IconPencil size={18} />
                    </button>
                  </div>
                  <div style={{ display: 'flex', flexDirection: 'column', gap: '1.25rem' }}>
                    <div style={{ background: '#f8fafc', padding: '1rem', borderRadius: '12px' }}>
                      <span style={{ fontSize: '0.7rem', color: 'var(--text-secondary)', fontWeight: 800, textTransform: 'uppercase', letterSpacing: '0.05em' }}>Annual Membership</span>
                      <span style={{ fontSize: '1.5rem', fontWeight: 900, color: 'var(--primary)', display: 'block', marginTop: '0.25rem' }}>{formatCurrency(f.annual_fee)}</span>
                    </div>
                    <div style={{ background: '#f8fafc', padding: '1rem', borderRadius: '12px' }}>
                      <span style={{ fontSize: '0.7rem', color: 'var(--text-secondary)', fontWeight: 800, textTransform: 'uppercase', letterSpacing: '0.05em' }}>Per Forum Meeting</span>
                      <span style={{ fontSize: '1.25rem', fontWeight: 800, display: 'block', marginTop: '0.25rem' }}>{formatCurrency(f.per_forum_fee)}</span>
                    </div>
                  </div>
                </div>
              ))}
            </div>
          </div>
        )}
      </div>

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
    <div className="modal-overlay" onClick={onClose}>
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

  return (
    <section className="dashboard-body">
      <div className="page-title-wrap">
        <h1 className="page-title">Global Settings</h1>
        <p style={{ color: 'var(--text-secondary)', marginTop: '0.4rem', fontWeight: 500 }}>
          Manage your administrative profile and platform preferences.
        </p>
      </div>

      <div className="settings-grid">
        <div className="settings-section" style={{ flex: 1 }}>
          <div className="settings-header">
            <h3 style={{ fontSize: '1.1rem', fontWeight: 800, display: 'flex', alignItems: 'center', gap: '0.75rem' }}>
              <IconUser size={22} color="var(--secondary)" /> My Profile
            </h3>
          </div>
          <div style={{ textAlign: 'center', marginBottom: '2rem' }}>
             <div style={{ width: 80, height: 80, borderRadius: 20, background: 'linear-gradient(135deg, var(--primary), #3b82f6)', display: 'flex', alignItems: 'center', justifyContent: 'center', color: 'white', fontWeight: 800, fontSize: '1.5rem', margin: '0 auto 1rem', border: '4px solid white', boxShadow: 'var(--shadow)' }}>
                {adminUser?.full_name ? adminUser.full_name.split(' ').map(n => n[0]).join('').toUpperCase() : 'AD'}
              </div>
              <h4 style={{ fontSize: '1.25rem', fontWeight: 800 }}>{adminUser?.full_name}</h4>
              <p style={{ color: 'var(--text-secondary)', fontSize: '0.875rem' }}>{adminUser?.role} • {adminUser?.email}</p>
          </div>
          <div style={{ display: 'flex', flexDirection: 'column', gap: '0.75rem' }}>
             <button className="btn-primary" onClick={onShowChangePassword} style={{ display: 'flex', alignItems: 'center', justifyContent: 'center', gap: '0.5rem' }}>
                <IconLock size={18} /> Change Account Password
             </button>
             <button className="btn-primary" style={{ background: '#f1f5f9', color: 'var(--text-primary)', border: '1px solid var(--border)', display: 'flex', alignItems: 'center', justifyContent: 'center', gap: '0.5rem' }}>
                <IconMail size={18} /> Update Contact Email
             </button>
          </div>
        </div>

        <div className="settings-section" style={{ flex: 1 }}>
          <div className="settings-header">
            <h3 style={{ fontSize: '1.1rem', fontWeight: 800, display: 'flex', alignItems: 'center', gap: '0.75rem' }}>
              <IconBell size={22} color="var(--accent)" /> Notification Preferences
            </h3>
          </div>
          <div className="settings-row">
            <div>
              <div style={{ fontWeight: 700, fontSize: '0.9rem' }}>New Applications</div>
              <div style={{ fontSize: '0.75rem', color: 'var(--text-secondary)' }}>Notify when a potential member submits application</div>
            </div>
            <label className="toggle-switch">
              <input type="checkbox" checked={notifPreferences.applications} onChange={() => toggleNotif('applications')} />
              <span className="slider"></span>
            </label>
          </div>
          <div className="settings-row">
            <div>
              <div style={{ fontWeight: 700, fontSize: '0.9rem' }}>Payment Alerts</div>
              <div style={{ fontSize: '0.75rem', color: 'var(--text-secondary)' }}>Real-time updates on membership and renewal fees</div>
            </div>
            <label className="toggle-switch">
              <input type="checkbox" checked={notifPreferences.payments} onChange={() => toggleNotif('payments')} />
              <span className="slider"></span>
            </label>
          </div>
          <div className="settings-row">
            <div>
              <div style={{ fontWeight: 700, fontSize: '0.9rem' }}>Meeting Reminders</div>
              <div style={{ fontSize: '0.75rem', color: 'var(--text-secondary)' }}>Automated nudges for upcoming chapter fit-calls</div>
            </div>
            <label className="toggle-switch">
              <input type="checkbox" checked={notifPreferences.reminders} onChange={() => toggleNotif('reminders')} />
              <span className="slider"></span>
            </label>
          </div>
        </div>
      </div>
    </section>
  );
}

// ── Security Logs Page ────────────────────────────────────────────────────
function SecurityLogsPage() {
  return (
    <section className="dashboard-body">
      <div className="page-title-wrap">
        <h1 className="page-title">Security & Audit Logs</h1>
        <p style={{ color: 'var(--text-secondary)', marginTop: '0.4rem', fontWeight: 500 }}>
          Timeline of critical administrative actions and system events.
        </p>
      </div>
      <div className="data-section">
        <div style={{ padding: '4rem', textAlign: 'center' }}>
          <IconLock size={48} color="#cbd5e1" style={{ marginBottom: '1rem' }} />
          <h3 style={{ color: 'var(--text-secondary)' }}>Audit Logging Module</h3>
          <p style={{ color: '#94a3b8', marginTop: '0.5rem' }}>Real-time audit logs are currently being initialized for the network.</p>
        </div>
      </div>
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
    <div className="modal-overlay" onClick={onClose}>
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
    <div className="modal-overlay" onClick={onClose}>
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

  return (
    <section className="dashboard-body">
      <div className="page-title-wrap" style={{ display: 'flex', justifyContent: 'space-between', alignItems: 'center' }}>
        <div>
          <h1 className="page-title">Event Management</h1>
          <p style={{ color: 'var(--text-secondary)', marginTop: '0.4rem', fontWeight: 500 }}>
            Schedule and manage chapter meetings, micro-meetups, and virtual sessions.
          </p>
        </div>
        <button className="btn-primary" onClick={() => setShowAddModal(true)} style={{ display: 'flex', alignItems: 'center', gap: '0.6rem' }}>
          <IconPlus size={20} /> Create New Event
        </button>
      </div>

      <div className="data-section">
        <div className="section-head">
          <h3 style={{ fontSize: '1.25rem', fontWeight: 800 }}>Event Calendar</h3>
          <div style={{ display: 'flex', gap: '1rem' }}>
            <CustomSelect
              label="Filter by Chapter"
              value={chapterFilter}
              options={chapters}
              onChange={setChapterFilter}
              style={{ width: '220px' }}
            />
            <CustomSelect
              label="All Events"
              value={timeFilter}
              options={[
                { id: 'all', name: 'All Events' },
                { id: 'upcoming', name: 'Upcoming Only' },
                { id: 'finished', name: 'Finished / Past' }
              ]}
              onChange={setTimeFilter}
              style={{ width: '180px' }}
            />
            <button className="view-detail-btn" onClick={fetchEvents}><IconRefresh size={18} /></button>
          </div>
        </div>

        <table className="modern-table">
          <thead>
            <tr>
              <th>Event Title</th>
              <th>Type</th>
              <th>Date & Time</th>
              <th>Location / Link</th>
              <th>Fee</th>
              <th>RSVPs</th>
              <th>Actions</th>
            </tr>
          </thead>
          <tbody>
            {loading ? (
              <tr><td colSpan={7} style={{ textAlign: 'center', padding: '3rem' }}>Loading events...</td></tr>
            ) : (() => {
              const filtered = events.filter(ev => {
                const isPast = new Date(ev.end_at) < new Date();
                if (timeFilter === 'upcoming') return !isPast;
                if (timeFilter === 'finished') return isPast;
                return true;
              });
              
              if (filtered.length === 0) {
                return <tr><td colSpan={7} style={{ textAlign: 'center', padding: '3rem', color: '#94a3b8' }}>No {timeFilter !== 'all' ? timeFilter : ''} events found.</td></tr>;
              }

              return filtered.map(ev => {
                const isPast = new Date(ev.end_at) < new Date();
                return (
                  <tr key={ev.id} style={{ background: isPast ? '#f8fafc' : 'white', opacity: isPast ? 0.8 : 1 }}>
                    <td>
                      <div style={{ display: 'flex', alignItems: 'center', gap: '1rem' }}>
                        <div style={{ width: 44, height: 44, borderRadius: '8px', background: '#f8fafc', overflow: 'hidden', border: '1px solid #e2e8f0', flexShrink: 0, position: 'relative' }}>
                           {ev.image_url ? (
                             <img src={ev.image_url.startsWith('http') ? ev.image_url : `${STATIC_BASE_URL}${ev.image_url}`} style={{ width: '100%', height: '100%', objectFit: 'cover' }} />
                           ) : (
                             <div style={{ width: '100%', height: '100%', display: 'flex', alignItems: 'center', justifyContent: 'center' }}>
                                <IconCalendarEvent size={18} color="#94a3b8" />
                             </div>
                           )}
                           {isPast && <div style={{ position: 'absolute', inset: 0, background: 'rgba(255,255,255,0.4)', display: 'flex', alignItems: 'center', justifyContent: 'center', fontSize: '0.5rem', fontWeight: 900, color: '#475569' }}>PAST</div>}
                        </div>
                        <div>
                          <div style={{ display: 'flex', alignItems: 'center', gap: '0.5rem' }}>
                            <div style={{ fontWeight: 700 }}>{ev.title}</div>
                            {isPast ? (
                              <span style={{ fontSize: '0.6rem', background: '#e2e8f0', color: '#64748b', padding: '2px 4px', borderRadius: '3px', fontWeight: 800 }}>PAST</span>
                            ) : (
                              <span style={{ fontSize: '0.6rem', background: '#dcfce7', color: '#15803d', padding: '2px 4px', borderRadius: '3px', fontWeight: 800 }}>LIVE</span>
                            )}
                          </div>
                          <div style={{ fontSize: '0.75rem', color: 'var(--text-secondary)' }}>ID: {ev.id.slice(0, 8)}</div>
                        </div>
                      </div>
                    </td>
                    <td>
                      <span className={`pill ${ev.event_type === 'flagship' ? 'pill-approved' : 'pill-waitlisted'}`} style={{ textTransform: 'uppercase', fontSize: '0.7rem' }}>
                        {ev.event_type}
                      </span>
                    </td>
                    <td style={{ fontSize: '0.85rem' }}>
                      <div style={{ fontWeight: 600 }}>{new Date(ev.start_at).toLocaleDateString()}</div>
                      <div style={{ color: 'var(--text-secondary)' }}>{new Date(ev.start_at).toLocaleTimeString([], { hour: '2-digit', minute: '2-digit' })}</div>
                    </td>
                    <td style={{ fontSize: '0.85rem', maxWidth: '200px', overflow: 'hidden', textOverflow: 'ellipsis' }}>
                      {ev.location || ev.meeting_link || '—'}
                    </td>
                    <td style={{ fontWeight: 700 }}>{ev.fee > 0 ? formatCurrency(ev.fee) : 'Free'}</td>
                    <td style={{ textAlign: 'center' }}>
                      <div style={{ fontWeight: 700 }}>{ev.rsvps?.filter(r => r.status === 'going').length || 0}</div>
                      <div style={{ fontSize: '0.7rem', color: 'var(--text-secondary)' }}>Going</div>
                    </td>
                    <td style={{ display: 'flex', gap: '0.5rem' }}>
                      <button className="view-detail-btn" onClick={() => setManagingRsvpsEvent(ev)} title="Manage RSVPs">
                        <IconUserCheck size={18} />
                      </button>
                      <button className="view-detail-btn" onClick={() => setEditingEvent(ev)} title="Edit Event">
                        <IconSettings size={18} />
                      </button>
                    </td>
                  </tr>
                );
              })
            })()}
          </tbody>
        </table>
      </div>

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
    <div className="modal-overlay" onClick={onClose}>
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
    <section className="dashboard-body">
      <div className="page-title-wrap" style={{ display: 'flex', justifyContent: 'space-between', alignItems: 'center' }}>
        <div>
          <h1 className="page-title">Horizontal Clubs</h1>
          <p style={{ color: 'var(--text-secondary)', marginTop: '0.4rem', fontWeight: 500 }}>
            Cross-chapter industry verticals for targeted business collaboration.
          </p>
        </div>
        <button className="btn-primary" onClick={() => setShowAddModal(true)} style={{ display: 'flex', alignItems: 'center', gap: '0.6rem' }}>
          <IconPlus size={20} /> Establish New Club
        </button>
      </div>

      <div className="data-section">
        <div className="section-head">
          <h3 style={{ fontSize: '1.25rem', fontWeight: 800 }}>Active Verticals</h3>
          <button className="view-detail-btn" onClick={fetchClubs}><IconRefresh size={18} /></button>
        </div>

        <table className="modern-table">
          <thead>
            <tr>
              <th>Club Name</th>
              <th>Industry Vertical</th>
              <th>Requirement</th>
              <th>Status</th>
              <th>Description</th>
            </tr>
          </thead>
          <tbody>
            {loading ? (
              <tr><td colSpan={5} style={{ textAlign: 'center', padding: '3rem' }}>Loading clubs...</td></tr>
            ) : clubs.length === 0 ? (
              <tr><td colSpan={5} style={{ textAlign: 'center', padding: '3rem' }}>No clubs established.</td></tr>
            ) : clubs.map(club => (
              <tr key={club.id}>
                <td style={{ fontWeight: 700, color: 'var(--primary)' }}>{club.name}</td>
                <td>
                  <div style={{ display: 'flex', flexWrap: 'wrap', gap: '0.3rem' }}>
                    {club.industries?.map(ind => (
                      <span key={ind} className="pill" style={{ background: '#f1f5f9', color: '#475569', fontWeight: 700, fontSize: '0.65rem', padding: '0.2rem 0.5rem' }}>
                        {ind}
                      </span>
                    )) || '—'}
                  </div>
                </td>
                <td style={{ fontWeight: 600 }}>{club.min_members}+ Members</td>
                <td>
                  <StatusPill status={club.is_active ? 'approved' : 'rejected'} />
                </td>
                <td style={{ fontSize: '0.85rem', color: 'var(--text-secondary)', maxWidth: '300px' }}>
                  {club.description || '—'}
                </td>
                <td style={{ textAlign: 'right' }}>
                  <div style={{ display: 'flex', gap: '0.5rem', justifyContent: 'flex-end' }}>
                    <button className="view-detail-btn" title="Edit Club" onClick={() => {
                      setEditingClub(club);
                      setShowAddModal(true);
                    }}>
                      <IconPencil size={18} />
                    </button>
                    <button className="view-detail-btn" title="Delete Club" style={{ color: '#ef4444' }} onClick={async () => {
                      if (confirm(`Are you sure you want to delete "${club.name}"?`)) {
                        await api.deleteClub(club.id);
                        fetchClubs();
                      }
                    }}>
                      <IconTrash size={18} />
                    </button>
                  </div>
                </td>
              </tr>
            ))}
          </tbody>
        </table>
      </div>

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

export default function App() {
  const [isAuthenticated, setIsAuthenticated] = useState(() => !!localStorage.getItem('access_token'));
  const [adminUser, setAdminUser] = useState(null);
  const [activeTab, setActiveTab] = useState('overview');
  const [showNotifications, setShowNotifications] = useState(false);
  const [showProfileMenu, setShowProfileMenu] = useState(false);
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
  
  const { data: referrals, loading: referralsLoading } = useApi(
    isAuthenticated ? api.listAllReferrals : () => Promise.resolve(null),
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
    if (activeTab === 'payments') return <PaymentsPage />;
    if (activeTab === 'rewards') return <PartnersPage />;
    if (activeTab === 'referrals') return <ReferralsPage />;
    if (activeTab === 'events') return <EventsPage />;
    if (activeTab === 'clubs') return <ClubsPage />;
    if (activeTab === 'revenue') return <RevenuePage onNavigateToGovernance={() => setActiveTab('governance')} />;
    if (activeTab === 'governance') return <GovernancePage onBack={() => setActiveTab('revenue')} />;
    if (activeTab === 'settings') return <SettingsPage {...commonProps} />;
    if (activeTab === 'notifications') return <SecurityLogsPage />;

    // Default: Overview dashboard
    return (
      <section className="dashboard-body">
        <div className="page-title-wrap">
          <h1 className="page-title">Performance Overview</h1>
          <p style={{ color: 'var(--text-secondary)', marginTop: '0.4rem', fontWeight: 500 }}>
            Tracking business movement across the Prime Business Network in real-time.
          </p>
        </div>

        {overviewError ? (
          <div style={{ padding: '2rem', textAlign: 'center', color: '#ef4444', fontWeight: 600 }}>
            Failed to load analytics. Check backend connection.
          </div>
        ) : (
          <div className="stat-grid" style={{ gridTemplateColumns: 'repeat(auto-fill, minmax(280px, 1fr))' }}>
            <StatCard 
              title="TOTAL REVENUE (ROI)" 
              value={formatCurrency(overview?.total_value)} 
              icon={IconCoin} 
              color="#059669" 
              trend={null}
            />
            <StatCard title="ACTIVE MEMBER BASE" value={overview?.total_members?.toLocaleString() ?? '—'} icon={IconUsers} color="#2563eb" />
            <StatCard title="TOTAL LEADS (ECONOMY)" value={overview?.total_leads?.toLocaleString() ?? '—'} icon={IconStackPop} color="#f59e0b" />
            <StatCard title="TOTAL RFPs" value={overview?.total_rfps?.toLocaleString() ?? '—'} icon={IconClipboardList} color="#7c3aed" />
          </div>
        )}

        <div className="data-section">
          <div className="section-head">
            <div>
              <h3 style={{ fontSize: '1.25rem', fontWeight: 800 }}>Referral Interaction Pipeline</h3>
              <p style={{ fontSize: '0.85rem', color: 'var(--text-secondary)', marginTop: '0.2rem' }}>Insights into the latest cross-chapter business exchanges.</p>
            </div>
            <div style={{ display: 'flex', gap: '1rem' }}>
              <button 
                className="btn-primary" 
                style={{ background: 'white', color: 'var(--text-primary)', border: '1px solid var(--border)', display: 'flex', alignItems: 'center', gap: '0.5rem' }}
                onClick={() => alert('Search filters are available in the dedicated Referrals and Directory pages.')}
              >
                <IconFilter size={18} />
                Advanced Filtering
              </button>
              <button 
                className="btn-primary" 
                style={{ display: 'flex', alignItems: 'center', gap: '0.6rem' }}
                onClick={async () => {
                  try {
                    await api.exportData();
                    showToast('Data report export started');
                  } catch (e) {
                    showToast('Export failed: ' + e.message, 'error');
                  }
                }}
              >
                <IconFileExport size={18} />
                Export Data Reports
              </button>
            </div>
          </div>

          <table className="modern-table">
            <thead>
              <tr>
                <th>Referral ID</th>
                <th>Primary Source</th>
                <th>Network Target</th>
                <th>Market Value</th>
                <th>Live Status</th>
                <th>Time Elapsed</th>
                <th>Options</th>
              </tr>
            </thead>
            <tbody>
              {referralsLoading ? (
                <tr><td colSpan={7} style={{ textAlign: 'center', padding: '2rem', color: '#94a3b8' }}>Loading referrals...</td></tr>
              ) : (!referrals || (Array.isArray(referrals) ? referrals.length === 0 : !referrals.referrals || referrals.referrals.length === 0)) ? (
                <tr><td colSpan={7} style={{ textAlign: 'center', padding: '2rem', color: '#94a3b8' }}>No referral data available</td></tr>
              ) : (Array.isArray(referrals) ? referrals : referrals.referrals).slice(0, 8).map((ref, idx) => (
                <tr key={ref.id || idx}>
                  <td><span className="id-badge">{ref.id ? `REF-${String(ref.id).slice(0, 4)}` : `REF-${idx}`}</span></td>
                  <td style={{ fontWeight: 600 }}>{ref.from_user?.full_name || '—'}</td>
                  <td>{ref.target_user?.full_name || '—'}</td>
                  <td style={{ fontWeight: 700 }}>{ref.actual_value ? formatCurrency(ref.actual_value) : '—'}</td>
                  <td>
                    <span className={`pill ${ref.status === 'closed_won' ? 'pill-completed' : 'pill-pending'}`}>
                      {ref.status || 'Unknown'}
                    </span>
                  </td>
                  <td>{ref.created_at ? new Date(ref.created_at).toLocaleDateString() : '—'}</td>
                  <td><IconDotsVertical size={20} color="#94a3b8" style={{ cursor: 'pointer' }} /></td>
                </tr>
              ))}
            </tbody>
          </table>

          <div style={{ padding: '1.5rem 2.5rem', background: '#f8fafc', display: 'flex', justifyContent: 'space-between', alignItems: 'center' }}>
            <p style={{ fontSize: '0.8125rem', color: 'var(--text-secondary)', fontWeight: 600 }}>
              {(Array.isArray(referrals) ? referrals?.length : referrals?.referrals?.length) > 0 ? `Showing latest entries` : 'No records available'}
            </p>
            <button
              onClick={() => setActiveTab('referrals')}
              style={{ display: 'flex', gap: '0.5rem', alignItems: 'center', cursor: 'pointer', color: 'var(--secondary)', fontWeight: 700, fontSize: '0.875rem', background: 'none', border: 'none', fontFamily: 'inherit' }}
            >
              See Full Global Timeline <IconChevronRight size={18} />
            </button>
          </div>
        </div>
      </section>
    );
  };

  return (
    <div className="app-wrapper" onClick={() => { setShowNotifications(false); setShowProfileMenu(false); }}>
      <ToastContainer toasts={toasts} />
      {showChangePassword && <ChangePasswordModal onClose={() => setShowChangePassword(false)} showToast={showToast} />}

      {/* Premium Sidebar */}
      <aside className="sidebar">
        <div className="logo-section">
          <span className="logo-text">Prime <span style={{ color: 'var(--accent)', WebkitTextFillColor: 'var(--accent)' }}>Business</span> Network</span>
        </div>

        <nav className="nav-container">
          {MENU_GROUPS.map((group, i) => (
            <div key={i} className="nav-group">
              <ul className="nav-list">
                {group.links.map(link => (
                  <li
                    key={link.id}
                    data-label={link.label}
                    className={`nav-item ${activeTab === link.id ? 'active' : ''}`}
                    onClick={() => setActiveTab(link.id)}
                  >
                    <link.icon className="nav-icon" />
                    <span>{link.label}</span>
                  </li>
                ))}
              </ul>
            </div>
          ))}
        </nav>

        <div className="sidebar-footer" style={{ marginTop: 'auto', padding: '0.5rem' }}>
          <button
            onClick={handleLogout}
            style={{
              width: '100%',
              display: 'flex',
              alignItems: 'center',
              gap: '0.75rem',
              padding: '0.875rem 1rem',
              background: 'rgba(239, 68, 68, 0.1)',
              color: '#f87171',
              border: '1px solid rgba(239, 68, 68, 0.2)',
              borderRadius: '12px',
              cursor: 'pointer',
              fontSize: '0.875rem',
              fontWeight: 700,
              transition: 'all 0.2s'
            }}
          >
            <IconLogout size={18} stroke={2} />
            <span>Sign Out</span>
          </button>
        </div>
      </aside>

      {/* Main Experience */}
      <main className="main-content">
        <header className="top-header">
          <div className="search-nav">
            <IconSearch size={20} color="#94a3b8" />
            <input type="text" placeholder="Quick search members, referrals or chapters..." />
          </div>

          <div className="header-actions">
            <div className="profile-dropdown-container">
              <div 
                className="action-btn" 
                onClick={(e) => { e.stopPropagation(); setShowNotifications(!showNotifications); setShowProfileMenu(false); }}
                style={{ position: 'relative' }}
              >
                <IconBell size={20} />
                {unreadCount > 0 && <span className="notification-badge">{unreadCount}</span>}
              </div>
              {showNotifications && (
                <NotificationPanel 
                  notifications={notifications} 
                  onDismiss={dismissNotification}
                  onMarkAllRead={markAllRead}
                  onClose={() => setShowNotifications(false)}
                />
              )}
            </div>

            <div className="action-btn" onClick={() => setActiveTab('settings')}><IconSettings size={20} /></div>
            
            <div style={{ width: '1px', height: '24px', background: '#e2e8f0', margin: '0 0.5rem' }}></div>
            
            <div className="profile-dropdown-container">
              <div 
                className="header-profile" 
                onClick={(e) => { e.stopPropagation(); setShowProfileMenu(!showProfileMenu); setShowNotifications(false); }}
                style={{ display: 'flex', alignItems: 'center', gap: '0.75rem', cursor: 'pointer' }}
              >
                <div style={{ textAlign: 'right' }}>
                  <p style={{ fontSize: '0.9rem', fontWeight: 700, color: 'var(--text-primary)' }}>{adminUser?.full_name || 'Admin User'}</p>
                  <p style={{ fontSize: '0.75rem', fontWeight: 600, color: 'var(--text-secondary)' }}>{adminUser?.role || 'Administrator'}</p>
                </div>
                <div style={{ width: 42, height: 42, borderRadius: 12, background: 'linear-gradient(135deg, var(--primary), #3b82f6)', display: 'flex', alignItems: 'center', justifyContent: 'center', color: 'white', fontWeight: 800, fontSize: '0.9rem', border: '2px solid white', boxShadow: 'var(--shadow)' }}>
                  {adminUser?.full_name ? adminUser.full_name.split(' ').map(n => n[0]).join('').toUpperCase() : 'AD'}
                </div>
              </div>

              {showProfileMenu && (
                <div className="profile-menu" onClick={e => e.stopPropagation()}>
                  <div className="profile-menu-item" onClick={() => { setActiveTab('settings'); setShowProfileMenu(false); }}>
                    <IconUser size={18} /> My Profile
                  </div>
                  <div className="profile-menu-item" onClick={() => { setShowChangePassword(true); setShowProfileMenu(false); }}>
                    <IconLock size={18} /> Change Password
                  </div>
                  <div style={{ height: '1px', background: 'var(--border)', margin: '0.5rem 0' }}></div>
                  <div className="profile-menu-item danger" onClick={handleLogout}>
                    <IconLogout size={18} /> Sign Out
                  </div>
                </div>
              )}
            </div>
          </div>
        </header>

        {renderContent()}
      </main>
    </div>
  );
}
