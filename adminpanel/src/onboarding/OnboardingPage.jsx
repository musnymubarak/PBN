import React, { useEffect, useMemo, useState } from 'react';
import { api } from '../lib/api';
import TshirtPicker3D from './TshirtPicker3D';

const FIELD_LABELS = {
  designation: 'Your Role / Designation',
  decision_authority: 'Decision Authority',
  years_in_operation: 'Years in Operation',
  business_legal_type: 'Business Legal Type',
  website_url: 'Website URL',
  linkedin_url: 'LinkedIn Profile URL',
  what_you_offer: 'What you offer the network',
  what_you_seek: 'What you seek from the network',
};

const SELECT_OPTIONS = {
  designation: ['Founder', 'CEO', 'Managing Director', 'Director', 'Partner', 'Manager', 'Other'],
  decision_authority: [
    { value: 'sole', label: 'Sole decision-maker' },
    { value: 'shared', label: 'Shared / committee decision' },
    { value: 'influencer', label: 'Influencer / not the decider' },
  ],
  years_in_operation: [
    { value: '<1', label: 'Less than 1 year' },
    { value: '1-3', label: '1–3 years' },
    { value: '3-7', label: '3–7 years' },
    { value: '7+', label: '7+ years' },
  ],
  business_legal_type: [
    { value: 'sole_proprietorship', label: 'Sole Proprietorship' },
    { value: 'partnership', label: 'Partnership' },
    { value: 'pvt_ltd', label: 'Private Limited (Pvt) Ltd' },
    { value: 'plc', label: 'Public Limited (PLC)' },
    { value: 'ngo', label: 'NGO / Non-profit' },
    { value: 'other', label: 'Other' },
  ],
};

const TEXTAREA_FIELDS = new Set(['what_you_offer', 'what_you_seek']);
const URL_FIELDS = new Set(['website_url', 'linkedin_url']);

// ── Shared layout ────────────────────────────────────────────────────────────

function PageShell({ children }) {
  return (
    <div
      style={{
        minHeight: '100vh',
        background: 'linear-gradient(135deg, #0f172a 0%, #1e293b 60%, #0f172a 100%)',
        padding: '40px 20px',
        fontFamily: '"DM Sans", "Helvetica Neue", Arial, sans-serif',
      }}
    >
      <div style={{ maxWidth: 720, margin: '0 auto' }}>
        <div style={{ textAlign: 'center', marginBottom: 28 }}>
          <div
            style={{
              display: 'inline-block',
              padding: '6px 16px',
              background: 'rgba(245, 158, 11, 0.1)',
              color: '#fbbf24',
              border: '1px solid rgba(245, 158, 11, 0.3)',
              borderRadius: 999,
              fontSize: 11,
              letterSpacing: 2,
              textTransform: 'uppercase',
              fontWeight: 700,
            }}
          >
            Prime Business Network
          </div>
          <h1 style={{ color: '#fff', fontSize: 28, margin: '14px 0 6px', fontWeight: 800 }}>
            Welcome aboard
          </h1>
        </div>
        {children}
      </div>
    </div>
  );
}

function Card({ children }) {
  return (
    <div
      style={{
        background: '#fff',
        borderRadius: 24,
        padding: 32,
        boxShadow: '0 25px 60px rgba(0,0,0,0.25)',
      }}
    >
      {children}
    </div>
  );
}

function MessageCard({ icon, title, body, accent = '#dc2626' }) {
  return (
    <PageShell>
      <Card>
        <div style={{ textAlign: 'center' }}>
          <div style={{ fontSize: 48, marginBottom: 12 }}>{icon}</div>
          <h2 style={{ fontSize: 22, margin: '0 0 12px', color: accent, fontWeight: 800 }}>{title}</h2>
          <p style={{ color: '#475569', fontSize: 15, lineHeight: 1.6 }}>{body}</p>
        </div>
      </Card>
    </PageShell>
  );
}

// ── Missing-fields form ──────────────────────────────────────────────────────

function MissingFieldsStep({ status, onSubmitted }) {
  const fields = status.missing_fields || [];
  const [values, setValues] = useState(() =>
    Object.fromEntries(fields.map((f) => [f, status[f] || '']))
  );
  const [error, setError] = useState('');
  const [saving, setSaving] = useState(false);

  const handleChange = (field, value) => setValues((v) => ({ ...v, [field]: value }));

  const normalizeUrl = (v) => {
    const trimmed = (v || '').trim();
    if (!trimmed) return trimmed;
    return /^https?:\/\//i.test(trimmed) ? trimmed : `https://${trimmed}`;
  };

  const handleSubmit = async (e) => {
    e.preventDefault();
    setError('');

    const cleaned = {};
    for (const field of fields) {
      let v = (values[field] || '').trim();
      if (URL_FIELDS.has(field)) v = normalizeUrl(v);
      if (!v) {
        setError(`${FIELD_LABELS[field] || field} is required.`);
        return;
      }
      if (URL_FIELDS.has(field)) {
        try { new URL(v); } catch {
          setError(`${FIELD_LABELS[field]} doesn't look like a valid URL.`);
          return;
        }
      }
      cleaned[field] = v;
    }

    setSaving(true);
    try {
      const refreshed = await api.patchOnboardingDetails(status.token, cleaned);
      onSubmitted(refreshed);
    } catch (err) {
      setError(err.message || 'Failed to save. Please try again.');
    } finally {
      setSaving(false);
    }
  };

  return (
    <Card>
      <div style={{ marginBottom: 24 }}>
        <div style={{ fontSize: 11, color: '#f59e0b', letterSpacing: 2, fontWeight: 700, textTransform: 'uppercase' }}>
          Step 1 of 2
        </div>
        <h2 style={{ fontSize: 22, margin: '8px 0 6px', color: '#0f172a', fontWeight: 800 }}>
          Complete your profile
        </h2>
        <p style={{ color: '#64748b', fontSize: 14, margin: 0 }}>
          Hi {status.full_name?.split(' ')[0] || 'there'} — a few quick details about {status.business_name} so the team can finalise your seat.
        </p>
      </div>

      {error && (
        <div
          style={{
            background: '#fef2f2',
            color: '#b91c1c',
            border: '1px solid #fecaca',
            borderRadius: 10,
            padding: '10px 14px',
            marginBottom: 16,
            fontSize: 13,
          }}
        >
          {error}
        </div>
      )}

      <form onSubmit={handleSubmit}>
        {fields.map((field) => (
          <div key={field} style={{ marginBottom: 18 }}>
            <label
              style={{
                fontSize: 11,
                color: '#64748b',
                fontWeight: 700,
                letterSpacing: 1,
                textTransform: 'uppercase',
                display: 'block',
                marginBottom: 6,
              }}
            >
              {FIELD_LABELS[field] || field} <span style={{ color: '#dc2626' }}>*</span>
            </label>
            {SELECT_OPTIONS[field] ? (
              <select
                value={values[field]}
                onChange={(e) => handleChange(field, e.target.value)}
                required
                style={fieldStyle()}
              >
                <option value="" disabled>Select…</option>
                {SELECT_OPTIONS[field].map((opt) =>
                  typeof opt === 'string' ? (
                    <option key={opt} value={opt}>{opt}</option>
                  ) : (
                    <option key={opt.value} value={opt.value}>{opt.label}</option>
                  )
                )}
              </select>
            ) : TEXTAREA_FIELDS.has(field) ? (
              <textarea
                rows={2}
                maxLength={280}
                value={values[field]}
                onChange={(e) => handleChange(field, e.target.value)}
                required
                placeholder={
                  field === 'what_you_offer'
                    ? 'One sentence on what you bring to PBN members.'
                    : 'One sentence on what you’re looking for.'
                }
                style={{ ...fieldStyle(), resize: 'vertical', minHeight: 64 }}
              />
            ) : (
              <input
                type="text"
                inputMode={URL_FIELDS.has(field) ? 'url' : 'text'}
                value={values[field]}
                onChange={(e) => handleChange(field, e.target.value)}
                required
                placeholder={
                  URL_FIELDS.has(field)
                    ? (field === 'website_url' ? 'your-business.lk' : 'linkedin.com/in/yourname')
                    : ''
                }
                style={fieldStyle()}
              />
            )}
          </div>
        ))}

        <button
          type="submit"
          disabled={saving}
          style={{
            width: '100%',
            background: saving ? '#94a3b8' : 'linear-gradient(135deg, #0f172a 0%, #1e3a8a 100%)',
            color: '#fff',
            padding: '14px 20px',
            border: 'none',
            borderRadius: 12,
            fontWeight: 800,
            fontSize: 15,
            letterSpacing: 0.5,
            cursor: saving ? 'wait' : 'pointer',
            marginTop: 8,
          }}
        >
          {saving ? 'Saving…' : 'Continue to T-shirt sizing →'}
        </button>
      </form>
    </Card>
  );
}

function fieldStyle() {
  return {
    width: '100%',
    padding: '12px 14px',
    background: '#f8fafc',
    border: '1.5px solid #e2e8f0',
    borderRadius: 10,
    fontSize: 14,
    color: '#0f172a',
    fontFamily: 'inherit',
    outline: 'none',
    boxSizing: 'border-box',
  };
}

// ── T-shirt step ─────────────────────────────────────────────────────────────

function TshirtStep({ status, onCompleted, hasPreviousStep }) {
  const [size, setSize] = useState(status.tshirt_size || '');
  const [submitting, setSubmitting] = useState(false);
  const [error, setError] = useState('');

  const submit = async () => {
    if (!size) {
      setError('Please pick a size to finish.');
      return;
    }
    setError('');
    setSubmitting(true);
    try {
      await api.submitOnboardingTshirt(status.token, size);
      onCompleted();
    } catch (err) {
      setError(err.message || 'Submission failed.');
      setSubmitting(false);
    }
  };

  return (
    <Card>
      <div style={{ marginBottom: 24 }}>
        <div style={{ fontSize: 11, color: '#f59e0b', letterSpacing: 2, fontWeight: 700, textTransform: 'uppercase' }}>
          {hasPreviousStep ? 'Step 2 of 2' : 'Final step'}
        </div>
        <h2 style={{ fontSize: 22, margin: '8px 0 6px', color: '#0f172a', fontWeight: 800 }}>
          Pick your founding-member tee
        </h2>
        <p style={{ color: '#64748b', fontSize: 14, margin: 0 }}>
          Drag the shirt to inspect front and back. Pick the size that fits best — we ship it to your chapter pickup.
        </p>
      </div>

      <TshirtPicker3D value={size} onChange={setSize} disabled={submitting} />

      {error && (
        <div
          style={{
            background: '#fef2f2',
            color: '#b91c1c',
            border: '1px solid #fecaca',
            borderRadius: 10,
            padding: '10px 14px',
            marginTop: 16,
            fontSize: 13,
          }}
        >
          {error}
        </div>
      )}

      <button
        type="button"
        onClick={submit}
        disabled={submitting || !size}
        style={{
          width: '100%',
          background: !size ? '#cbd5e1' : (submitting ? '#94a3b8' : 'linear-gradient(135deg, #f59e0b 0%, #d97706 100%)'),
          color: !size ? '#64748b' : '#0f172a',
          padding: '14px 20px',
          border: 'none',
          borderRadius: 12,
          fontWeight: 800,
          fontSize: 15,
          letterSpacing: 0.5,
          cursor: submitting || !size ? 'not-allowed' : 'pointer',
          marginTop: 22,
        }}
      >
        {submitting ? 'Confirming…' : size ? `Confirm size ${size} & finish` : 'Pick a size to continue'}
      </button>
    </Card>
  );
}

// ── Success screen ───────────────────────────────────────────────────────────

function CompletedScreen({ status }) {
  return (
    <Card>
      <div style={{ textAlign: 'center', padding: '12px 8px' }}>
        <div
          style={{
            width: 72,
            height: 72,
            margin: '0 auto 18px',
            borderRadius: '50%',
            background: 'linear-gradient(135deg, #10b981 0%, #059669 100%)',
            display: 'flex',
            alignItems: 'center',
            justifyContent: 'center',
            color: '#fff',
            fontSize: 38,
            boxShadow: '0 12px 30px rgba(16,185,129,0.35)',
          }}
        >
          ✓
        </div>
        <h2 style={{ fontSize: 22, margin: '0 0 8px', color: '#0f172a', fontWeight: 800 }}>
          You’re all set, {status.full_name?.split(' ')[0]}!
        </h2>
        <p style={{ color: '#64748b', fontSize: 14, margin: '0 0 18px', lineHeight: 1.6 }}>
          {status.tshirt_size ? (
            <>Size <strong>{status.tshirt_size}</strong> noted. </>
          ) : null}
          We’ll be in touch with chapter details. You can now log in to the PBN mobile app or admin panel with the credentials in your welcome email.
        </p>
        <a
          href="/"
          style={{
            display: 'inline-block',
            background: 'linear-gradient(135deg, #0f172a 0%, #1e3a8a 100%)',
            color: '#fff',
            padding: '12px 28px',
            borderRadius: 10,
            textDecoration: 'none',
            fontWeight: 700,
            fontSize: 14,
          }}
        >
          Back to primebusiness.network
        </a>
      </div>
    </Card>
  );
}

// ── Wizard ───────────────────────────────────────────────────────────────────

export default function OnboardingPage() {
  const token = useMemo(() => {
    const params = new URLSearchParams(window.location.search);
    return params.get('token') || '';
  }, []);

  const [status, setStatus] = useState(null);
  const [loadError, setLoadError] = useState('');
  const [loading, setLoading] = useState(true);
  const [completed, setCompleted] = useState(false);
  const [hadMissingFieldsOnLoad, setHadMissingFieldsOnLoad] = useState(false);

  useEffect(() => {
    if (!token) {
      setLoadError('This onboarding link is invalid. Please use the link from your welcome email.');
      setLoading(false);
      return;
    }
    api.getOnboardingStatus(token)
      .then((data) => {
        const enriched = { ...data, token };
        setStatus(enriched);
        setHadMissingFieldsOnLoad((data.missing_fields || []).length > 0);
        if (data.completed) setCompleted(true);
      })
      .catch((err) => {
        setLoadError(err.message || 'Could not load your onboarding link.');
      })
      .finally(() => setLoading(false));
  }, [token]);

  if (loading) {
    return (
      <PageShell>
        <Card>
          <p style={{ textAlign: 'center', color: '#64748b' }}>Loading your onboarding link…</p>
        </Card>
      </PageShell>
    );
  }

  if (loadError) {
    return (
      <MessageCard
        icon="🔒"
        title="Link unavailable"
        body={loadError}
      />
    );
  }

  if (completed || status?.completed) {
    return <PageShell><CompletedScreen status={status} /></PageShell>;
  }

  const showMissingStep = (status.missing_fields || []).length > 0;

  if (showMissingStep) {
    return (
      <PageShell>
        <MissingFieldsStep
          status={status}
          onSubmitted={(refreshed) => setStatus({ ...refreshed, token })}
        />
      </PageShell>
    );
  }

  return (
    <PageShell>
      <TshirtStep
        status={status}
        hasPreviousStep={hadMissingFieldsOnLoad}
        onCompleted={() => setCompleted(true)}
      />
    </PageShell>
  );
}
