import React, { useState, useEffect } from 'react';
import { IconCash, IconPlus, IconUpload, IconCreditCard, IconReceipt, IconRefresh } from '@tabler/icons-react';
import * as Ds from '../components/ui';
import api from '../lib/api';

export default function PaymentsPage() {
  const [payments, setPayments] = useState([]);
  const [loading, setLoading] = useState(true);
  
  // Proof Modal State
  const [showProofModal, setShowProofModal] = useState(false);
  const [selectedPayment, setSelectedPayment] = useState(null);
  const [proofType, setProofType] = useState('IMAGE');
  const [refNumber, setRefNumber] = useState('');
  const [file, setFile] = useState(null);
  const [fileName, setFileName] = useState('');
  const [isSubmitting, setIsSubmitting] = useState(false);
  const [isInitiating, setIsInitiating] = useState(null); // stores paymentId when initiating

  const fetchPayments = async () => {
    setLoading(true);
    try {
      const res = await api.get('/payments/my');
      if (res.data?.data) {
        setPayments(res.data.data);
      }
    } catch (err) {
      console.error('Failed to fetch payments', err);
    } finally {
      setLoading(false);
    }
  };

  useEffect(() => {
    fetchPayments();
  }, []);

  const handlePayOnline = async (p) => {
    setIsInitiating(p.id);
    try {
      const res = await api.post('/payments/initiate', {
        payment_type: p.payment_type.toUpperCase(),
        amount: parseFloat(p.amount),
        event_id: p.reference_id || null,
      });

      if (res.data?.data?.payment_url) {
        // Append source parameter so it redirects back to the portal
        const initUrl = res.data.data.payment_url;
        const separator = initUrl.includes('?') ? '&' : '?';
        
        // Redirect user to the Bancstac hosted page
        window.location.href = `${initUrl}${separator}source=portal`;
      } else {
        alert('Failed to initiate online payment.');
      }
    } catch (err) {
      console.error(err);
      alert(err.response?.data?.error?.message || 'Payment gateway initiation failed. Please try again.');
    } finally {
      setIsInitiating(null);
    }
  };

  const handleUploadProofClick = (p) => {
    setSelectedPayment(p);
    setProofType('IMAGE');
    setRefNumber('');
    setFile(null);
    setFileName('');
    setShowProofModal(true);
  };

  const handleFileChange = (e) => {
    if (e.target.files && e.target.files[0]) {
      setFile(e.target.files[0]);
      setFileName(e.target.files[0].name);
    }
  };

  const handleSendProof = async (e) => {
    e.preventDefault();
    if (proofType !== 'REFERENCE_NUMBER' && !file) {
      alert('Please select a file to upload.');
      return;
    }
    
    setIsSubmitting(true);
    const formData = new FormData();
    formData.append('proof_type', proofType);
    if (refNumber) {
      formData.append('reference_number', refNumber);
    }
    if (proofType !== 'REFERENCE_NUMBER' && file) {
      formData.append('file', file);
    }

    try {
      await api.post(`/payments/${selectedPayment.id}/proof`, formData, {
        headers: {
          'Content-Type': 'multipart/form-data',
        },
      });
      alert('Payment proof uploaded successfully. Admin will review it shortly!');
      setShowProofModal(false);
      fetchPayments();
    } catch (err) {
      console.error(err);
      alert(err.response?.data?.error?.message || 'Failed to upload proof. Please try again.');
    } finally {
      setIsSubmitting(false);
    }
  };

  // Stat calculations
  const totalPaid = payments
    .filter((p) => p.status === 'completed')
    .reduce((sum, p) => sum + parseFloat(p.amount), 0);

  const totalPending = payments
    .filter((p) => p.status === 'pending')
    .reduce((sum, p) => sum + parseFloat(p.amount), 0);

  const formatLKR = (val) => {
    return new Intl.NumberFormat('en-US', {
      style: 'currency',
      currency: 'LKR',
      minimumFractionDigits: 0,
    }).format(val);
  };

  return (
    <div className="dashboard-body">
      <Ds.PageHeader
        title="Payments"
        description="Manage your memberships, event meeting fees, and gateway transactions."
        actions={
          <Ds.Button
            variant="ghost"
            leftIcon={<IconRefresh size={16} />}
            onClick={fetchPayments}
            loading={loading}
          >
            Refresh
          </Ds.Button>
        }
      />

      {/* Stats row */}
      <div style={{ display: 'grid', gridTemplateColumns: 'repeat(auto-fit, minmax(200px, 1fr))', gap: '1rem', marginBottom: '2rem' }}>
        <Ds.StatCard
          title="Total Paid"
          value={formatLKR(totalPaid)}
          description="Confirmed online & manual transactions"
        />
        <Ds.StatCard
          title="Pending Payments"
          value={formatLKR(totalPending)}
          description="Outstanding balances requiring action"
        />
      </div>

      {loading ? (
        <Ds.EmptyState icon={Ds.Spinner} title="Loading Payments..." description="Syncing your transactions ledger." />
      ) : payments.length === 0 ? (
        <Ds.EmptyState
          icon={IconCash}
          title="No payments found"
          description="Any memberships or fee demands will be listed here."
        />
      ) : (
        <Ds.Card padded>
          <h3 style={{ fontSize: '1.1rem', fontWeight: 700, color: 'var(--fg-primary)', marginBottom: '1.25rem' }}>
            Payment Log
          </h3>
          <div style={{ overflowX: 'auto' }}>
            <Ds.Table>
              <thead>
                <tr>
                  <th>Reason</th>
                  <th>Type</th>
                  <th>Amount</th>
                  <th>Status</th>
                  <th>Gateway Ref</th>
                  <th>Action</th>
                </tr>
              </thead>
              <tbody>
                {payments.map((p) => {
                  const isPending = p.status === 'pending';
                  const hasProof = p.proof_status !== null;
                  
                  let statusBadgeType = 'info';
                  let statusLabel = p.status;
                  if (p.status === 'completed') {
                    statusBadgeType = 'success';
                    statusLabel = 'Completed';
                  } else if (p.status === 'failed') {
                    statusBadgeType = 'danger';
                    statusLabel = 'Failed';
                  } else if (p.status === 'pending') {
                    if (p.proof_status === 'pending_review') {
                      statusBadgeType = 'warning';
                      statusLabel = 'Proof Pending';
                    } else if (p.proof_status === 'rejected') {
                      statusBadgeType = 'danger';
                      statusLabel = 'Proof Rejected';
                    } else {
                      statusBadgeType = 'warning';
                      statusLabel = 'Pending';
                    }
                  }

                  return (
                    <tr key={p.id}>
                      <td style={{ fontWeight: 600, color: 'var(--fg-primary)' }}>
                        {p.reason}
                        {p.created_at && (
                          <div style={{ fontSize: '0.75rem', color: 'var(--fg-muted)', fontWeight: 400, marginTop: '0.25rem' }}>
                            {new Date(p.created_at).toLocaleDateString()}
                          </div>
                        )}
                      </td>
                      <td>
                        <Ds.Badge variant="ghost">
                          {p.payment_type.toUpperCase()}
                        </Ds.Badge>
                      </td>
                      <td style={{ fontWeight: 700, color: 'var(--fg-primary)' }}>
                        {formatLKR(p.amount)}
                      </td>
                      <td>
                        <Ds.Badge variant={statusBadgeType}>
                          {statusLabel}
                        </Ds.Badge>
                      </td>
                      <td style={{ fontFamily: 'monospace', fontSize: '0.8rem', color: 'var(--fg-secondary)' }}>
                        {p.gateway_reference || '—'}
                      </td>
                      <td>
                        {isPending && (
                          <div style={{ display: 'flex', gap: '0.5rem' }}>
                            {p.proof_status !== 'pending_review' && (
                              <Ds.Button
                                variant="primary"
                                size="sm"
                                leftIcon={<IconCreditCard size={14} />}
                                onClick={() => handlePayOnline(p)}
                                loading={isInitiating === p.id}
                              >
                                Pay Online
                              </Ds.Button>
                            )}
                            <Ds.Button
                              variant="outline"
                              size="sm"
                              leftIcon={<IconUpload size={14} />}
                              onClick={() => handleUploadProofClick(p)}
                            >
                              {p.proof_status === 'rejected' ? 'Re-upload' : 'Upload Proof'}
                            </Ds.Button>
                          </div>
                        )}
                      </td>
                    </tr>
                  );
                })}
              </tbody>
            </Ds.Table>
          </div>
        </Ds.Card>
      )}

      {/* Proof Modal */}
      {showProofModal && selectedPayment && (
        <Ds.Modal
          isOpen={true}
          onClose={() => setShowProofModal(false)}
          title="Submit Payment Proof"
        >
          <form onSubmit={handleSendProof}>
            <div style={{ background: 'var(--bg-subtle)', padding: '1rem', borderRadius: 'var(--radius-md)', marginBottom: '1.5rem', display: 'flex', justifyContent: 'space-between' }}>
              <div>
                <div style={{ fontSize: 'var(--text-xs)', color: 'var(--fg-muted)', textTransform: 'uppercase', letterSpacing: '0.5px' }}>Total Amount</div>
                <div style={{ fontSize: '1.25rem', fontWeight: 800, color: 'var(--fg-primary)' }}>{formatLKR(selectedPayment.amount)}</div>
              </div>
              <div style={{ textAlign: 'right' }}>
                <div style={{ fontSize: 'var(--text-xs)', color: 'var(--fg-muted)', textTransform: 'uppercase', letterSpacing: '0.5px' }}>Reason</div>
                <div style={{ fontWeight: 600, color: 'var(--fg-primary)' }}>{selectedPayment.reason}</div>
              </div>
            </div>

            <Ds.Field label="Proof Type">
              <Ds.Select
                value={proofType}
                onChange={(e) => setProofType(e.target.value)}
              >
                <option value="IMAGE">Image / Screenshot</option>
                <option value="PDF">PDF Document</option>
                <option value="REFERENCE_NUMBER">Reference Number Only</option>
              </Ds.Select>
            </Ds.Field>

            {proofType !== 'REFERENCE_NUMBER' && (
              <Ds.Field label="Select Receipt File">
                <div style={{ display: 'flex', alignItems: 'center', gap: '1rem' }}>
                  <Ds.Button
                    variant="outline"
                    type="button"
                    leftIcon={<IconReceipt size={16} />}
                    onClick={() => document.getElementById('receipt-file').click()}
                  >
                    Choose File
                  </Ds.Button>
                  <span style={{ fontSize: 'var(--text-sm)', color: 'var(--fg-secondary)', overflow: 'hidden', textOverflow: 'ellipsis', whiteSpace: 'nowrap', maxWidth: '240px' }}>
                    {fileName || 'No file selected'}
                  </span>
                  <input
                    id="receipt-file"
                    type="file"
                    accept={proofType === 'IMAGE' ? 'image/*' : '.pdf'}
                    style={{ display: 'none' }}
                    onChange={handleFileChange}
                  />
                </div>
              </Ds.Field>
            )}

            <Ds.Field label="Bank Reference Number (Optional)">
              <Ds.Input
                type="text"
                placeholder="e.g. REF123456789"
                value={refNumber}
                onChange={(e) => setRefNumber(e.target.value)}
              />
            </Ds.Field>

            <div style={{ display: 'flex', justifyContent: 'flex-end', gap: '0.75rem', marginTop: '2rem' }}>
              <Ds.Button variant="ghost" type="button" onClick={() => setShowProofModal(false)}>Cancel</Ds.Button>
              <Ds.Button variant="primary" type="submit" loading={isSubmitting} leftIcon={<IconUpload size={16} />}>
                Submit Proof
              </Ds.Button>
            </div>
          </form>
        </Ds.Modal>
      )}
    </div>
  );
}
