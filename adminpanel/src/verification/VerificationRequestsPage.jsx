import React, { useCallback, useEffect, useState } from 'react';
import {
  IconUserShield, IconRefresh, IconSearch, IconCheck, IconX,
  IconClock, IconFileText, IconWorld, IconMapPin, IconBrandLinkedin,
  IconBrandFacebook, IconBrandInstagram, IconAlertCircle,
  IconMail, IconPhone, IconBuildingStore,
} from '@tabler/icons-react';
import { api, STATIC_BASE_URL } from '../lib/api';
import * as Ds from '../components/ui';

const STATUS_META = {
  pending:  { label: 'Pending Review', variant: 'warning', icon: IconClock },
  approved: { label: 'Approved',       variant: 'success', icon: IconCheck },
  rejected: { label: 'Rejected',       variant: 'danger',  icon: IconX },
};

function StatusPill({ status }) {
  const meta = STATUS_META[status] || { label: status, variant: 'brand' };
  return <Ds.Badge dot variant={meta.variant}>{meta.label}</Ds.Badge>;
}

function asAbsolute(url) {
  if (!url) return null;
  if (/^https?:\/\//i.test(url)) return url;
  return `${STATIC_BASE_URL}${url.startsWith('/') ? '' : '/'}${url}`;
}

function ReviewModal({ request, onClose, onUpdated, showToast }) {
  const [rejecting, setRejecting] = useState(false);
  const [reason, setReason] = useState('');
  const [actioning, setActioning] = useState(false);
  const [error, setError] = useState('');

  const handleApprove = async () => {
    if (!window.confirm('Are you sure you want to approve this verification request?')) return;
    setError('');
    setActioning(true);
    try {
      await api.approveVerificationRequest(request.id);
      if (showToast) showToast('Verification request approved successfully', 'success');
      onUpdated();
      onClose();
    } catch (err) {
      setError(err.message || 'Failed to approve request');
    } finally {
      setActioning(false);
    }
  };

  const handleReject = async () => {
    if (!reason.trim()) {
      setError('Please provide a rejection reason');
      return;
    }
    setError('');
    setActioning(true);
    try {
      await api.rejectVerificationRequest(request.id, reason.trim());
      if (showToast) showToast('Verification request rejected successfully', 'success');
      onUpdated();
      onClose();
    } catch (err) {
      setError(err.message || 'Failed to reject request');
    } finally {
      setActioning(false);
    }
  };

  const biz = request.business || {};
  const hasSocials = biz.linkedin_url || biz.facebook_url || biz.instagram_url;
  const isPending = request.status === 'pending';

  return (
    <div className="modal-overlay" onClick={(e) => e.target === e.currentTarget && onClose()}>
      <div className="modal-content" onClick={e => e.stopPropagation()} style={{ maxWidth: 640 }}>
        <div className="modal-header">
          <h2 style={{ fontSize: '1.25rem', fontWeight: 800 }}>Review Verification Request</h2>
          <button type="button" className="modal-close-btn" onClick={onClose}><IconX size={20} /></button>
        </div>
        <div style={{ padding: '1.5rem', maxHeight: 'calc(100vh - 200px)', overflowY: 'auto' }}>
          {error && (
            <div className="login-error" style={{ marginBottom: '1rem' }}>{error}</div>
          )}

          {/* Applicant Info Section */}
          <div style={{ display: 'grid', gridTemplateColumns: 'repeat(auto-fit, minmax(260px, 1fr))', gap: 16, marginBottom: 24 }}>
            <div style={{ background: '#f8fafc', padding: '1.25rem', borderRadius: 14, border: '1px solid var(--border-subtle)' }}>
              <div style={{ fontSize: 11, fontWeight: 700, color: '#94a3b8', textTransform: 'uppercase', letterSpacing: 0.8, marginBottom: 6 }}>Member Details</div>
              <div style={{ fontSize: 16, fontWeight: 800, color: 'var(--fg-primary)' }}>{request.user_name}</div>
              <div style={{ display: 'flex', alignItems: 'center', gap: 6, fontSize: 13, color: 'var(--fg-secondary)', marginTop: 8 }}>
                <IconMail size={14} color="#94a3b8" />
                <span>{request.user_email || 'No email'}</span>
              </div>
              <div style={{ display: 'flex', alignItems: 'center', gap: 6, fontSize: 13, color: 'var(--fg-secondary)', marginTop: 4 }}>
                <IconPhone size={14} color="#94a3b8" />
                <span>{request.user_phone || 'No phone'}</span>
              </div>
            </div>

            <div style={{ background: '#f8fafc', padding: '1.25rem', borderRadius: 14, border: '1px solid var(--border-subtle)' }}>
              <div style={{ fontSize: 11, fontWeight: 700, color: '#94a3b8', textTransform: 'uppercase', letterSpacing: 0.8, marginBottom: 6 }}>Verification Context</div>
              <div style={{ fontSize: 14, color: 'var(--fg-secondary)' }}>
                Business Value Generated:
              </div>
              <div style={{ fontSize: 20, fontWeight: 800, color: '#0f172a', marginTop: 2 }}>
                LKR {request.business_value.toLocaleString()}
              </div>
              <div style={{ display: 'flex', alignItems: 'center', gap: 6, marginTop: 10 }}>
                <span style={{ fontSize: 12, color: 'var(--fg-muted)' }}>Status:</span>
                <StatusPill status={request.status} />
              </div>
            </div>
          </div>

          {/* Business Info Section */}
          <div style={{ border: '1px solid var(--border-subtle)', borderRadius: 16, padding: '1.25rem', marginBottom: 24 }}>
            <div style={{ display: 'flex', justifyContent: 'space-between', alignItems: 'flex-start', gap: 12, marginBottom: 14 }}>
              <div>
                <div style={{ fontSize: 11, fontWeight: 700, color: '#94a3b8', textTransform: 'uppercase', letterSpacing: 0.8, marginBottom: 4 }}>Business Profile</div>
                <h3 style={{ fontSize: 16, fontWeight: 800, color: '#1e3a8a', margin: 0 }}>{request.business_name}</h3>
              </div>
              {biz.logo_url && (
                <img
                  src={asAbsolute(biz.logo_url)}
                  alt="Logo"
                  style={{ maxHeight: 48, maxWidth: 120, borderRadius: 6, border: '1px solid #e2e8f0', padding: 2, background: '#fff' }}
                />
              )}
            </div>

            {biz.description && (
              <p style={{ fontSize: 13, color: 'var(--fg-secondary)', lineHeight: 1.5, margin: '0 0 16px 0', whiteSpace: 'pre-line' }}>
                {biz.description}
              </p>
            )}

            <div style={{ display: 'flex', flexDirection: 'column', gap: 8 }}>
              {biz.established_year && (
                <div style={{ display: 'grid', gridTemplateColumns: '180px 1fr', fontSize: 13, padding: '4px 0', borderBottom: '1px dashed #f1f5f9' }}>
                  <span style={{ fontWeight: 600, color: '#64748b' }}>Established Year</span>
                  <span style={{ color: 'var(--fg-primary)' }}>{biz.established_year}</span>
                </div>
              )}
              {biz.br_number && (
                <div style={{ display: 'grid', gridTemplateColumns: '180px 1fr', fontSize: 13, padding: '4px 0', borderBottom: '1px dashed #f1f5f9' }}>
                  <span style={{ fontWeight: 600, color: '#64748b' }}>BR Number</span>
                  <span style={{ color: 'var(--fg-primary)', fontFamily: 'monospace' }}>{biz.br_number}</span>
                </div>
              )}
              {biz.address && (
                <div style={{ display: 'grid', gridTemplateColumns: '180px 1fr', fontSize: 13, padding: '4px 0', borderBottom: '1px dashed #f1f5f9' }}>
                  <span style={{ fontWeight: 600, color: '#64748b' }}>Address</span>
                  <span style={{ color: 'var(--fg-primary)' }}>{biz.address}</span>
                </div>
              )}
              {biz.website && (
                <div style={{ display: 'grid', gridTemplateColumns: '180px 1fr', fontSize: 13, padding: '4px 0', borderBottom: '1px dashed #f1f5f9' }}>
                  <span style={{ fontWeight: 600, color: '#64748b' }}>Website</span>
                  <span>
                    <a href={biz.website} target="_blank" rel="noreferrer" style={{ color: '#1e3a8a', display: 'flex', alignItems: 'center', gap: 4 }}>
                      <IconWorld size={14} />
                      {biz.website}
                    </a>
                  </span>
                </div>
              )}
              {biz.google_maps_url && (
                <div style={{ display: 'grid', gridTemplateColumns: '180px 1fr', fontSize: 13, padding: '4px 0', borderBottom: '1px dashed #f1f5f9' }}>
                  <span style={{ fontWeight: 600, color: '#64748b' }}>Google Maps Link</span>
                  <span>
                    <a href={biz.google_maps_url} target="_blank" rel="noreferrer" style={{ color: '#ef4444', display: 'flex', alignItems: 'center', gap: 4 }}>
                      <IconMapPin size={14} />
                      Open Location Maps
                    </a>
                  </span>
                </div>
              )}
              {biz.brochure_url && (
                <div style={{ display: 'grid', gridTemplateColumns: '180px 1fr', fontSize: 13, padding: '4px 0', borderBottom: '1px dashed #f1f5f9' }}>
                  <span style={{ fontWeight: 600, color: '#64748b' }}>PDF Brochure</span>
                  <span>
                    <a href={asAbsolute(biz.brochure_url)} target="_blank" rel="noreferrer" style={{ color: '#2563eb', display: 'flex', alignItems: 'center', gap: 4, fontWeight: 700 }}>
                      <IconFileText size={14} />
                      Download Company Brochure PDF
                    </a>
                  </span>
                </div>
              )}
            </div>

            {hasSocials && (
              <div style={{ display: 'flex', gap: 12, marginTop: 16, borderTop: '1px solid #f1f5f9', paddingTop: 14 }}>
                {biz.linkedin_url && (
                  <a href={biz.linkedin_url} target="_blank" rel="noreferrer" style={{ display: 'flex', alignItems: 'center', gap: 4, fontSize: 13, color: '#0077B5', textDecoration: 'none', fontWeight: 600 }}>
                    <IconBrandLinkedin size={16} /> LinkedIn
                  </a>
                )}
                {biz.facebook_url && (
                  <a href={biz.facebook_url} target="_blank" rel="noreferrer" style={{ display: 'flex', alignItems: 'center', gap: 4, fontSize: 13, color: '#1877F2', textDecoration: 'none', fontWeight: 600 }}>
                    <IconBrandFacebook size={16} /> Facebook
                  </a>
                )}
                {biz.instagram_url && (
                  <a href={biz.instagram_url} target="_blank" rel="noreferrer" style={{ display: 'flex', alignItems: 'center', gap: 4, fontSize: 13, color: '#E1306C', textDecoration: 'none', fontWeight: 600 }}>
                    <IconBrandInstagram size={16} /> Instagram
                  </a>
                )}
              </div>
            )}
          </div>

          {/* History Details */}
          {request.status === 'rejected' && request.rejection_reason && (
            <div style={{ background: 'rgba(239, 68, 68, 0.08)', border: '1px solid rgba(239, 68, 68, 0.2)', padding: '1rem', borderRadius: 12, marginBottom: 24 }}>
              <div style={{ display: 'flex', alignItems: 'center', gap: 6, fontSize: 12, fontWeight: 800, color: '#dc2626', textTransform: 'uppercase', letterSpacing: 0.5, marginBottom: 4 }}>
                <IconAlertCircle size={15} />
                Rejection Reason
              </div>
              <p style={{ fontSize: 13.5, color: '#b91c1c', margin: 0, fontWeight: 600 }}>{request.rejection_reason}</p>
            </div>
          )}

          {/* Action flow */}
          {isPending && (
            <div style={{ borderTop: '1px solid var(--border-subtle)', paddingTop: 20 }}>
              {!rejecting ? (
                <div style={{ display: 'flex', gap: 12 }}>
                  <button
                    type="button"
                    onClick={handleApprove}
                    disabled={actioning}
                    style={{
                      flex: 1,
                      background: 'linear-gradient(135deg, #10b981 0%, #059669 100%)',
                      color: '#fff',
                      padding: '12px',
                      borderRadius: 10,
                      fontWeight: 700,
                      cursor: 'pointer',
                      border: 'none',
                      display: 'flex',
                      alignItems: 'center',
                      justifyContent: 'center',
                      gap: 8,
                      boxShadow: '0 4px 10px rgba(16, 185, 129, 0.2)',
                    }}
                  >
                    {actioning ? 'Processing…' : 'Approve & Verify Member'}
                  </button>
                  <button
                    type="button"
                    onClick={() => setRejecting(true)}
                    disabled={actioning}
                    style={{
                      flex: 1,
                      background: '#ef4444',
                      color: '#fff',
                      padding: '12px',
                      borderRadius: 10,
                      fontWeight: 700,
                      cursor: 'pointer',
                      border: 'none',
                      display: 'flex',
                      alignItems: 'center',
                      justifyContent: 'center',
                      gap: 8,
                    }}
                  >
                    Reject Request
                  </button>
                </div>
              ) : (
                <div>
                  <label style={{ fontSize: 12, fontWeight: 700, color: 'var(--fg-secondary)', textTransform: 'uppercase', letterSpacing: 0.5, display: 'block', marginBottom: 6 }}>
                    Rejection Reason
                  </label>
                  <textarea
                    value={reason}
                    onChange={(e) => setReason(e.target.value)}
                    rows={3}
                    placeholder="Specify why the verification is rejected (e.g. Please provide a clear BR document or logo image)…"
                    style={{
                      width: '100%',
                      padding: '10px 12px',
                      border: '1.5px solid var(--border-subtle)',
                      borderRadius: 10,
                      fontSize: 14,
                      fontFamily: 'inherit',
                      boxSizing: 'border-box',
                      resize: 'vertical',
                    }}
                  />
                  <div style={{ display: 'flex', gap: 12, marginTop: 14 }}>
                    <button
                      type="button"
                      onClick={handleReject}
                      disabled={actioning}
                      style={{
                        flex: 2,
                        background: '#dc2626',
                        color: '#fff',
                        padding: '10px 16px',
                        borderRadius: 10,
                        fontWeight: 700,
                        cursor: 'pointer',
                        border: 'none',
                      }}
                    >
                      {actioning ? 'Processing…' : 'Confirm Rejection'}
                    </button>
                    <button
                      type="button"
                      onClick={() => { setRejecting(false); setReason(''); }}
                      disabled={actioning}
                      style={{
                        flex: 1,
                        background: '#e2e8f0',
                        color: '#0f172a',
                        padding: '10px 16px',
                        borderRadius: 10,
                        fontWeight: 700,
                        cursor: 'pointer',
                        border: 'none',
                      }}
                    >
                      Cancel
                    </button>
                  </div>
                </div>
              )}
            </div>
          )}

          {!isPending && (
            <div style={{ display: 'flex', justifyContent: 'flex-end', marginTop: 20 }}>
              <button
                type="button"
                className="login-btn"
                onClick={onClose}
                style={{ background: '#e2e8f0', color: '#0f172a', padding: '10px 24px', width: 'auto' }}
              >
                Close
              </button>
            </div>
          )}
        </div>
      </div>
    </div>
  );
}

export default function VerificationRequestsPage({ showToast }) {
  const [requests, setRequests] = useState([]);
  const [total, setTotal] = useState(0);
  const [page, setPage] = useState(1);
  const [pageSize] = useState(20);
  const [loading, setLoading] = useState(true);

  const [search, setSearch] = useState('');
  const [statusFilter, setStatusFilter] = useState('pending');
  const [reviewing, setReviewing] = useState(null);

  const fetchData = useCallback(async () => {
    setLoading(true);
    try {
      const params = { page, limit: pageSize };
      if (statusFilter) params.status = statusFilter;
      const data = await api.listVerificationRequests(params);
      setRequests(data.requests || []);
      setTotal(data.total || 0);
    } catch (err) {
      console.error('Failed to load verification requests:', err);
      if (showToast) showToast('Failed to load verification requests', 'danger');
    } finally {
      setLoading(false);
    }
  }, [page, pageSize, statusFilter, showToast]);

  useEffect(() => {
    fetchData();
  }, [fetchData]);

  const filteredRequests = requests.filter(r => {
    if (!search.trim()) return true;
    const query = search.toLowerCase();
    return (
      r.user_name?.toLowerCase().includes(query) ||
      r.business_name?.toLowerCase().includes(query) ||
      r.user_email?.toLowerCase().includes(query)
    );
  });

  const pages = Math.max(1, Math.ceil(total / pageSize));

  return (
    <section className="ds-page">
      <Ds.PageHeader
        title="Verification Requests"
        description="Review background checks and manual verification requests for members."
        actions={
          <Ds.Button variant="secondary" leftIcon={<IconRefresh size={14} />} onClick={() => { setPage(1); fetchData(); }}>
            Refresh
          </Ds.Button>
        }
      />

      <Ds.Section
        title="Pending & Historic Requests"
        subtitle={total > 0 ? `${total.toLocaleString()} request${total === 1 ? '' : 's'}` : undefined}
        flush
      >
        <div style={{ display: 'flex', gap: 'var(--space-3)', flexWrap: 'wrap', padding: 'var(--space-5) var(--space-6)', borderBottom: '1px solid var(--border-subtle)' }}>
          <Ds.Input
            placeholder="Filter by applicant name or business..."
            value={search}
            onChange={e => setSearch(e.target.value)}
            leftIcon={<IconSearch size={14} />}
            style={{ flex: 1, minWidth: 240 }}
          />
          <Ds.Select
            placeholder="Status Filter"
            value={statusFilter}
            options={[
              { id: '', name: 'All status requests' },
              { id: 'pending', name: 'Pending Review' },
              { id: 'approved', name: 'Approved' },
              { id: 'rejected', name: 'Rejected' }
            ]}
            onChange={val => { setStatusFilter(val); setPage(1); }}
            style={{ width: 220 }}
          />
        </div>

        <Ds.Table>
          <thead>
            <tr>
              <th>Applicant</th>
              <th>Business Name</th>
              <th>Value Generated</th>
              <th>Status</th>
              <th>Requested Date</th>
              <th className="ds-table__actions" />
            </tr>
          </thead>
          <tbody>
            {loading ? (
              <Ds.Table.LoadingRow colSpan={6} label="Loading verification requests…" />
            ) : filteredRequests.length === 0 ? (
              <Ds.Table.EmptyRow
                colSpan={6}
                icon={IconUserShield}
                title="No verification requests"
                description={statusFilter ? `There are no requests matching the "${statusFilter}" status.` : 'No requests found.'}
              />
            ) : filteredRequests.map(row => (
              <tr key={row.id} className="is-clickable" onClick={() => setReviewing(row)}>
                <td>
                  <div className="ds-table__primary">{row.user_name || '—'}</div>
                  <div style={{ fontSize: 'var(--text-xs)', color: 'var(--fg-muted)' }}>{row.user_email}</div>
                </td>
                <td style={{ fontWeight: 600, color: 'var(--fg-primary)' }}>{row.business_name || '—'}</td>
                <td style={{ fontWeight: 700 }}>LKR {row.business_value?.toLocaleString() ?? 0}</td>
                <td><StatusPill status={row.status} /></td>
                <td className="ds-table__muted">{row.created_at ? new Date(row.created_at).toLocaleDateString() : '—'}</td>
                <td className="ds-table__actions" onClick={e => e.stopPropagation()}>
                  <button className="view-detail-btn" title="Review Request" onClick={() => setReviewing(row)} style={{ display: 'flex', alignItems: 'center', gap: 4 }}>
                    Review
                  </button>
                </td>
              </tr>
            ))}
          </tbody>
        </Ds.Table>

        <Ds.Pagination
          page={page}
          totalPages={pages}
          total={total}
          pageLabel="requests"
          onPageChange={setPage}
        />
      </Ds.Section>

      {reviewing && (
        <ReviewModal
          request={reviewing}
          onClose={() => setReviewing(null)}
          onUpdated={fetchData}
          showToast={showToast}
        />
      )}
    </section>
  );
}
