import React, { useState, useEffect, useCallback } from 'react';
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
} from '@tabler/icons-react';
import { api } from './lib/api';
import { useApi } from './hooks/useApi';


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
            <div className="login-logo-wrap">
              <img src="/logo.png" alt="PBN" style={{ width: 48, height: 48, objectFit: 'contain' }} />
            </div>
            <h1 className="login-brand-title">Prime Business<br />Network</h1>
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
      { id: 'revenue', icon: IconCoin, label: 'Revenue & ROI' },
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
  pending:            { label: 'Pending',          class: 'pill-pending',     color: '#f59e0b', bg: '#fffbeb' },
  fit_call_scheduled: { label: 'Fit Call Scheduled', class: 'pill-scheduled', color: '#8b5cf6', bg: '#f5f3ff' },
  approved:           { label: 'Approved',         class: 'pill-approved',    color: '#059669', bg: '#ecfdf5' },
  rejected:           { label: 'Rejected',         class: 'pill-rejected',    color: '#dc2626', bg: '#fef2f2' },
  waitlisted:         { label: 'Waitlisted',       class: 'pill-waitlisted',  color: '#6b7280', bg: '#f9fafb' },
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
  const [errorMessage, setErrorMessage] = useState('');

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
    // Business Rule: PENDING -> Decision (Approve/Reject/Waitlist) is not allowed directly.
    if (detail.status === 'pending' && ['approved', 'rejected', 'waitlisted'].includes(newStatus)) {
      setErrorMessage('A Fit Call must be scheduled and completed before making a final decision on this application.');
      return;
    }

    if (newStatus === 'approved' && !selectedChapterId && !modalStatus) {
      setModalStatus('approved');
      return;
    }

    setUpdating(true);
    try {
      await api.updateApplicationStatus(appId, {
        status: newStatus,
        notes: actionNotes || undefined,
        chapter_id: selectedChapterId || undefined,
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
          <button className="modal-close-btn" onClick={onClose}>
            <IconX size={20} />
          </button>
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
              <label>District</label>
              <p>{detail.district || '—'}</p>
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
                  Please select the chapter to which this member will be assigned.
                </p>
                <div className="login-field" style={{ marginBottom: '1.25rem' }}>
                  <label style={{ color: '#166534' }}>Target Chapter</label>
                  <select 
                    value={selectedChapterId} 
                    onChange={e => setSelectedChapterId(e.target.value)}
                    style={{ width: '100%', padding: '0.75rem', borderRadius: '10px', border: '1.5px solid #86efac', outline: 'none' }}
                  >
                    <option value="">Select a chapter...</option>
                    {chapters.map(c => (
                      <option key={c.id} value={c.id}>{c.name}</option>
                    ))}
                  </select>
                </div>
                <div style={{ display: 'flex', gap: '0.75rem' }}>
                  <button 
                    className="login-btn" 
                    style={{ flex: 1, background: '#10b981', padding: '0.75rem' }}
                    onClick={() => handleStatusUpdate('approved')}
                    disabled={updating || !selectedChapterId}
                  >
                    Confirm Approval
                  </button>
                  <button 
                    className="login-btn" 
                    style={{ flex: 1, background: '#94a3b8', padding: '0.75rem' }}
                    onClick={() => setModalStatus(null)}
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
                  {availableActions.map(action => (
                    <button
                      key={action.status}
                      className="action-btn-main"
                      style={{ '--btn-color': action.color }}
                      disabled={updating}
                      onClick={() => handleStatusUpdate(action.status)}
                    >
                      <action.icon size={18} />
                      {updating ? 'Updating...' : action.label}
                    </button>
                  ))}
                </div>
              </>
            )}
          </div>
        </div>
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
              <th>District</th>
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
                <td style={{ color: 'var(--text-secondary)' }}>{app.district || '—'}</td>
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
      </div>

      {/* Detail Modal */}
      {selectedAppId && (
        <ApplicationDetailModal
          appId={selectedAppId}
          onClose={() => setSelectedAppId(null)}
          onStatusUpdated={fetchApps}
        />
      )}
    </section>
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
      api.listChapters().catch(() => ({ data: [] })),
      api.listIndustries().catch(() => ({ data: [] }))
    ]).then(([cData, iData]) => {
      const c = cData?.data || (Array.isArray(cData) ? cData : []);
      const i = iData?.data || (Array.isArray(iData) ? iData : []);
      setChapters(c);
      setIndustries(i);
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
                className="filter-input"
                style={{ paddingLeft: '40px', width: '100%', height: '48px' }}
                value={search}
                onChange={e => { setSearch(e.target.value); setPage(1); }}
              />
            </div>
            
            <select className="filter-input" style={{ width: '200px', height: '48px' }} value={chapterFilter} onChange={e => { setChapterFilter(e.target.value); setPage(1); }}>
              <option value="">All Chapters</option>
              {chapters.map(c => <option key={c.id} value={c.id}>{c.name}</option>)}
            </select>

            <select className="filter-input" style={{ width: '220px', height: '48px' }} value={industryFilter} onChange={e => { setIndustryFilter(e.target.value); setPage(1); }}>
              <option value="">All Industries (Network)</option>
              {industries.map(i => <option key={i.id} value={i.id}>{i.name}</option>)}
            </select>

            <select className="filter-input" style={{ width: '180px', height: '48px' }} value={roleFilter} onChange={e => { setRoleFilter(e.target.value); setPage(1); }}>
              <option value="">All Roles</option>
              <option value="MEMBER">Members</option>
              <option value="PROSPECT">Prospects</option>
              <option value="CHAPTER_ADMIN">Chapter Admins</option>
              <option value="PARTNER_ADMIN">Partner Admins</option>
            </select>
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
              <tr key={user.id}>
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
                  </span>
                </td>
                <td>
                  <span className={`pill ${user.is_active ? 'pill-approved' : 'pill-rejected'}`}>
                    {user.is_active ? 'Active' : 'Inactive'}
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
    </section>
  );
}



// ── Main App ────────────────────────────────────────────────────────────────

export default function App() {
  const [isAuthenticated, setIsAuthenticated] = useState(() => !!localStorage.getItem('access_token'));
  const [adminUser, setAdminUser] = useState(null);
  const [activeTab, setActiveTab] = useState('overview');
  const { data: overview, loading: overviewLoading, error: overviewError } = useApi(
    isAuthenticated ? api.getAdminOverview : () => Promise.resolve(null),
    [isAuthenticated]
  );
  const { data: referrals, loading: referralsLoading } = useApi(
    isAuthenticated ? api.listReferrals : () => Promise.resolve(null),
    [isAuthenticated]
  );

  const handleLogin = (user) => {
    setAdminUser(user);
    setIsAuthenticated(true);
  };

  const handleLogout = () => {
    localStorage.removeItem('access_token');
    localStorage.removeItem('refresh_token');
    setIsAuthenticated(false);
    setAdminUser(null);
  };

  if (!isAuthenticated) {
    return <LoginPage onLogin={handleLogin} />;
  }

  if (overviewLoading && activeTab === 'overview') {
    return (
      <div className="loading-state" style={{ display: 'flex', alignItems: 'center', justifyContent: 'center', height: '100vh', fontSize: '1.1rem', fontWeight: 600, color: '#64748b', background: '#f8fafc' }}>
        <div style={{ textAlign: 'center' }}>
          <div style={{ width: 40, height: 40, border: '3px solid #e2e8f0', borderTopColor: 'var(--primary)', borderRadius: '50%', animation: 'spin 1s linear infinite', margin: '0 auto 1rem' }}></div>
          Loading dashboard...
        </div>
      </div>
    );
  }

  const displayReferrals = referrals || [];

  const renderContent = () => {
    if (activeTab === 'applications') {
      return <ApplicationsPage />;
    }
    if (activeTab === 'members') {
      return <MembersPage />;
    }

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
          <div className="stat-grid">
            <StatCard title="TOTAL REVENUE (ROI)" value={formatCurrency(overview?.total_value)} icon={IconCoin} trend={12.4} color="#059669" />
            <StatCard title="ACTIVE MEMBER BASE" value={overview?.total_members?.toLocaleString() ?? '—'} icon={IconUsers} trend={5.2} color="#2563eb" />
            <StatCard title="REFERRAL VELOCITY" value={overview?.conversion_rate != null ? `${overview.conversion_rate}%` : '—'} icon={IconHierarchy2} color="#f59e0b" />
            <StatCard title="TOTAL REFERRALS" value={overview?.total_referrals?.toLocaleString() ?? '—'} icon={IconClock} color="#7c3aed" />
          </div>
        )}

        <div className="data-section">
          <div className="section-head">
            <div>
              <h3 style={{ fontSize: '1.25rem', fontWeight: 800 }}>Referral Interaction Pipeline</h3>
              <p style={{ fontSize: '0.85rem', color: 'var(--text-secondary)', marginTop: '0.2rem' }}>Insights into the latest cross-chapter business exchanges.</p>
            </div>
            <div style={{ display: 'flex', gap: '1rem' }}>
              <button className="btn-primary" style={{ background: 'white', color: 'var(--text-primary)', border: '1px solid var(--border)', display: 'flex', alignItems: 'center', gap: '0.5rem' }}>
                <IconFilter size={18} />
                Advanced Filtering
              </button>
              <button className="btn-primary" style={{ display: 'flex', alignItems: 'center', gap: '0.6rem' }}>
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
              ) : displayReferrals.length === 0 ? (
                <tr><td colSpan={7} style={{ textAlign: 'center', padding: '2rem', color: '#94a3b8' }}>No referral data available</td></tr>
              ) : displayReferrals.map((ref, idx) => (
                <tr key={ref.id || idx}>
                  <td><span className="id-badge">{ref.id ? `REF-${String(ref.id).slice(0, 4)}` : `REF-${idx}`}</span></td>
                  <td style={{ fontWeight: 600 }}>{ref.from_member_name || '—'}</td>
                  <td>{ref.to_member_name || '—'}</td>
                  <td style={{ fontWeight: 700 }}>{ref.estimated_value ? formatCurrency(ref.estimated_value) : '—'}</td>
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
               {displayReferrals.length > 0 ? `Showing ${displayReferrals.length} entries` : 'No records available'}
             </p>
             <div style={{ display: 'flex', gap: '0.5rem', alignItems: 'center', cursor: 'pointer', color: 'var(--secondary)', fontWeight: 700, fontSize: '0.875rem' }}>
               See Full Global Timeline <IconChevronRight size={18} />
             </div>
          </div>
        </div>
      </section>
    );
  };

  return (
    <div className="app-wrapper">
      {/* Premium Sidebar */}
      <aside className="sidebar">
        <div className="logo-section">
          <div className="logo-icon-wrap" style={{ background: 'transparent' }}>
            <img src="/logo.png" alt="PBN Logo" style={{ width: '40px', height: '40px', objectFit: 'contain' }} />
          </div>
          <span className="logo-text">Prime Business Network</span>
        </div>

        <nav className="nav-container">
          {MENU_GROUPS.map((group, i) => (
            <div key={i} className="nav-group">
              <p className="nav-label">{group.label}</p>
              <ul className="nav-list">
                {group.links.map(link => (
                  <li 
                    key={link.id} 
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

        <div className="sidebar-footer" style={{ marginTop: 'auto', padding: '1.25rem' }}>
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
            onMouseOver={e => e.currentTarget.style.background = 'rgba(239, 68, 68, 0.2)'}
            onMouseOut={e => e.currentTarget.style.background = 'rgba(239, 68, 68, 0.1)'}
          >
            <IconLogout size={18} stroke={2} />
            Sign Out
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
            <div className="action-btn"><IconBell size={20} /></div>
            <div className="action-btn"><IconSettings size={20} /></div>
            <div style={{ width: '1px', height: '24px', background: '#e2e8f0', margin: '0 0.5rem' }}></div>
            <div className="header-profile" style={{ display: 'flex', alignItems: 'center', gap: '0.75rem', cursor: 'pointer' }}>
               <div style={{ textAlign: 'right' }}>
                 <p style={{ fontSize: '0.9rem', fontWeight: 700, color: 'var(--text-primary)' }}>Deepthi Perera</p>
                 <p style={{ fontSize: '0.75rem', fontWeight: 600, color: 'var(--text-secondary)' }}>Account Manager</p>
               </div>
               <div style={{ width: 42, height: 42, borderRadius: 12, background: 'linear-gradient(135deg, var(--primary), #3b82f6)', display: 'flex', alignItems: 'center', justifyContent: 'center', color: 'white', fontWeight: 800, fontSize: '0.9rem', border: '2px solid white', boxShadow: 'var(--shadow)' }}>DP</div>
            </div>
          </div>
        </header>

        {renderContent()}
      </main>
    </div>
  );
}
