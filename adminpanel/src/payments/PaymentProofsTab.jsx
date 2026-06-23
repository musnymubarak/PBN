import React, { useState, useEffect, useCallback } from 'react';
import { api, STATIC_BASE_URL } from '../lib/api';
import * as Ds from '../components/ui';
import { IconFileCheck, IconEye, IconCheck, IconX, IconExternalLink } from '@tabler/icons-react';

export default function PaymentProofsTab() {
  const [proofs, setProofs] = useState([]);
  const [loading, setLoading] = useState(true);
  const [statusFilter, setStatusFilter] = useState('');
  
  const [selectedProof, setSelectedProof] = useState(null);
  const [actionNotes, setActionNotes] = useState('');
  const [actionLoading, setActionLoading] = useState(false);

  const fetchProofs = useCallback(async () => {
    setLoading(true);
    try {
      const data = await api.listPaymentProofs(statusFilter);
      setProofs(data || []);
    } catch (err) {
      console.error(err);
    } finally {
      setLoading(false);
    }
  }, [statusFilter]);

  useEffect(() => {
    fetchProofs();
  }, [fetchProofs]);

  const handleAction = async (status) => {
    if (!selectedProof) return;
    setActionLoading(true);
    try {
      if (status === 'APPROVED') {
        await api.approvePaymentProof(selectedProof.id, actionNotes);
      } else {
        await api.rejectPaymentProof(selectedProof.id, actionNotes);
      }
      setSelectedProof(null);
      setActionNotes('');
      fetchProofs();
    } catch (err) {
      alert(err.message || 'Action failed');
    } finally {
      setActionLoading(false);
    }
  };

  const pendingCount = proofs.filter(p => p.status?.toUpperCase() === 'PENDING_REVIEW').length;

  return (
    <div style={{ marginTop: '2rem' }}>
      <div style={{ display: 'flex', justifyContent: 'space-between', alignItems: 'center', marginBottom: '1.5rem' }}>
        <h3 style={{ fontSize: '1.25rem', fontWeight: 600 }}>Payment Proofs {pendingCount > 0 && <Ds.Badge variant="warning">{pendingCount} Pending</Ds.Badge>}</h3>
        <Ds.Select
          value={statusFilter}
          onChange={setStatusFilter}
          options={[
            { id: '', name: 'All Statuses' },
            { id: 'pending_review', name: 'Pending Review' },
            { id: 'approved', name: 'Approved' },
            { id: 'rejected', name: 'Rejected' },
          ]}
          style={{ width: '200px' }}
        />
      </div>

      <Ds.Section flush>
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
              <Ds.Table.LoadingRow colSpan={7} label="Loading payment proofs…" />
            ) : proofs.length === 0 ? (
              <Ds.Table.EmptyRow
                colSpan={7}
                icon={IconFileCheck}
                title="No payment proofs found"
                description="Uploaded proofs will appear here."
              />
            ) : proofs.map(p => (
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
                  {p.payment_reason || '—'}
                </td>
                <td>
                  <Ds.Badge variant="neutral">{p.proof_type?.replace('_', ' ')}</Ds.Badge>
                </td>
                <td className="ds-table__primary" style={{ fontWeight: 'var(--weight-bold)' }}>
                  LKR {p.payment_amount?.toLocaleString() || '0'}
                </td>
                <td>
                  <Ds.Badge dot variant={p.status?.toUpperCase() === 'APPROVED' ? 'success' : p.status?.toUpperCase() === 'REJECTED' ? 'danger' : 'warning'}>
                    {p.status}
                  </Ds.Badge>
                </td>
                <td className="ds-table__actions">
                  <Ds.Button variant="outline" size="sm" leftIcon={<IconEye size={14}/>} onClick={() => { setSelectedProof(p); setActionNotes(p.admin_notes || ''); }}>
                    Review
                  </Ds.Button>
                </td>
              </tr>
            ))}
          </tbody>
        </Ds.Table>
      </Ds.Section>

      {selectedProof && (
        <div className="modal-overlay" onClick={() => !actionLoading && setSelectedProof(null)}>
          <div className="modal-content" onClick={e => e.stopPropagation()} style={{ maxWidth: '600px' }}>
            <div className="modal-header">
              <h2>Review Payment Proof</h2>
              <button className="modal-close-btn" onClick={() => !actionLoading && setSelectedProof(null)}><IconX size={20}/></button>
            </div>
            <div className="modal-body">
              <div style={{ display: 'grid', gridTemplateColumns: '1fr 1fr', gap: '1rem', marginBottom: '1.5rem', background: '#f8fafc', padding: '1rem', borderRadius: '8px' }}>
                <div><label style={{ fontSize: '0.75rem', fontWeight: 700, color: '#64748b', textTransform: 'uppercase' }}>Member</label><div style={{ fontWeight: 600 }}>{selectedProof.user_name}</div></div>
                <div><label style={{ fontSize: '0.75rem', fontWeight: 700, color: '#64748b', textTransform: 'uppercase' }}>Amount</label><div style={{ fontWeight: 600, color: '#0f172a' }}>LKR {selectedProof.payment_amount?.toLocaleString()}</div></div>
                <div style={{ gridColumn: 'span 2' }}><label style={{ fontSize: '0.75rem', fontWeight: 700, color: '#64748b', textTransform: 'uppercase' }}>Reason</label><div>{selectedProof.payment_reason}</div></div>
              </div>

              {selectedProof.proof_type === 'REFERENCE_NUMBER' ? (
                <div style={{ marginBottom: '1.5rem', padding: '1.5rem', background: '#f1f5f9', borderRadius: '8px', textAlign: 'center' }}>
                  <label style={{ fontSize: '0.75rem', fontWeight: 700, color: '#64748b', textTransform: 'uppercase' }}>Bank Reference Number</label>
                  <div style={{ fontSize: '1.5rem', fontWeight: 700, marginTop: '0.5rem', color: '#0f172a', letterSpacing: '1px' }}>{selectedProof.reference_number}</div>
                </div>
              ) : (
                <div style={{ marginBottom: '1.5rem' }}>
                  <label style={{ fontSize: '0.75rem', fontWeight: 700, color: '#64748b', textTransform: 'uppercase', marginBottom: '0.5rem', display: 'block' }}>Document</label>
                  {selectedProof.file_path ? (
                    <div style={{ border: '1px solid #e2e8f0', borderRadius: '8px', padding: '1rem', textAlign: 'center', background: '#f8fafc' }}>
                      {selectedProof.file_path.toLowerCase().endsWith('.pdf') ? (
                        <embed src={selectedProof.file_path.replace('/uploads/', '/static/')} width="100%" height="400px" type="application/pdf" style={{ borderRadius: '4px' }} />
                      ) : (
                        <img src={selectedProof.file_path.replace('/uploads/', '/static/')} alt="Payment Proof" style={{ maxWidth: '100%', maxHeight: '400px', objectFit: 'contain', borderRadius: '4px' }} />
                      )}
                      <div style={{ marginTop: '1rem' }}>
                        <a href={selectedProof.file_path.replace('/uploads/', '/static/')} download target="_blank" rel="noreferrer" style={{ display: 'inline-flex', alignItems: 'center', gap: '0.5rem', color: '#2563eb', fontWeight: 600, textDecoration: 'none' }}>
                          <IconExternalLink size={16} /> Download File
                        </a>
                      </div>
                    </div>
                  ) : (
                    <div style={{ color: '#ef4444' }}>No file attached</div>
                  )}
                  {selectedProof.reference_number && (
                    <div style={{ marginTop: '1rem' }}>
                      <label style={{ fontSize: '0.75rem', fontWeight: 700, color: '#64748b', textTransform: 'uppercase' }}>Reference Number Provided</label>
                      <div style={{ fontWeight: 600 }}>{selectedProof.reference_number}</div>
                    </div>
                  )}
                </div>
              )}

              <div style={{ marginBottom: '1.5rem' }}>
                <label style={{ fontSize: '0.75rem', fontWeight: 700, color: '#64748b', textTransform: 'uppercase', marginBottom: '0.5rem', display: 'block' }}>Admin Notes (Optional)</label>
                <textarea 
                  className="modern-input" 
                  style={{ width: '100%', minHeight: '80px', padding: '0.75rem' }} 
                  placeholder="Enter any notes here..."
                  value={actionNotes}
                  onChange={e => setActionNotes(e.target.value)}
                  disabled={selectedProof.status?.toUpperCase() !== 'PENDING_REVIEW'}
                />
              </div>

              {selectedProof.status?.toUpperCase() === 'PENDING_REVIEW' ? (
                <div style={{ display: 'flex', gap: '1rem' }}>
                  <Ds.Button variant="primary" style={{ flex: 1, background: '#10b981', borderColor: '#10b981' }} leftIcon={<IconCheck size={18}/>} onClick={() => handleAction('APPROVED')} loading={actionLoading}>
                    Approve Payment
                  </Ds.Button>
                  <Ds.Button variant="danger" style={{ flex: 1 }} leftIcon={<IconX size={18}/>} onClick={() => handleAction('REJECTED')} loading={actionLoading}>
                    Reject Proof
                  </Ds.Button>
                </div>
              ) : (
                <div style={{ textAlign: 'center', padding: '1rem', background: selectedProof.status?.toUpperCase() === 'APPROVED' ? '#d1fae5' : '#fee2e2', color: selectedProof.status?.toUpperCase() === 'APPROVED' ? '#065f46' : '#991b1b', borderRadius: '8px', fontWeight: 600 }}>
                  This proof has been {selectedProof.status}
                </div>
              )}
            </div>
          </div>
        </div>
      )}
    </div>
  );
}
