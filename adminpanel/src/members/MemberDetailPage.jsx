import React, { useEffect, useState } from 'react';
import {
  IconArrowLeft, IconMail, IconPhone, IconMapPin, IconBuildingStore,
  IconLink, IconBrandLinkedin, IconAward, IconCoin, IconHierarchy2,
  IconClipboardList, IconShirt, IconRefresh, IconCalendarEvent,
} from '@tabler/icons-react';
import { api, STATIC_BASE_URL } from '../lib/api';
import * as Ds from '../components/ui';

const SECTION_GAP = 24;

function asAbsolute(url) {
  if (!url) return null;
  if (/^https?:\/\//i.test(url)) return url;
  return `${STATIC_BASE_URL}${url.startsWith('/') ? '' : '/'}${url}`;
}

function Section({ title, icon: Icon, right, children }) {
  return (
    <div
      style={{
        background: '#fff',
        borderRadius: 16,
        padding: 20,
        boxShadow: '0 1px 3px rgba(0,0,0,0.04)',
        border: '1px solid var(--border-subtle)',
      }}
    >
      <div style={{ display: 'flex', alignItems: 'center', justifyContent: 'space-between', marginBottom: 14 }}>
        <div style={{ display: 'flex', alignItems: 'center', gap: 8 }}>
          {Icon && <Icon size={16} color="#94a3b8" />}
          <h3 style={{ fontSize: 13, fontWeight: 700, color: 'var(--fg-secondary)', textTransform: 'uppercase', letterSpacing: 1, margin: 0 }}>
            {title}
          </h3>
        </div>
        {right}
      </div>
      {children}
    </div>
  );
}

function FieldRow({ label, value, href, mono }) {
  if (value === null || value === undefined || value === '') return null;
  return (
    <div style={{ display: 'grid', gridTemplateColumns: '160px 1fr', gap: 12, padding: '8px 0', borderBottom: '1px dashed #f1f5f9' }}>
      <div style={{ fontSize: 12, color: '#94a3b8', fontWeight: 600, textTransform: 'uppercase', letterSpacing: 0.5 }}>{label}</div>
      <div style={{ fontSize: 14, color: 'var(--fg-primary)', fontFamily: mono ? 'monospace' : 'inherit', wordBreak: 'break-word' }}>
        {href ? <a href={href} target="_blank" rel="noreferrer" style={{ color: '#1e3a8a' }}>{value}</a> : value}
      </div>
    </div>
  );
}

function StatTile({ icon: Icon, label, value, hint }) {
  return (
    <div style={{ background: '#fff', borderRadius: 12, padding: 16, border: '1px solid var(--border-subtle)' }}>
      <div style={{ display: 'flex', alignItems: 'center', gap: 8, marginBottom: 6 }}>
        {Icon && <Icon size={14} color="#94a3b8" />}
        <div style={{ fontSize: 11, color: '#94a3b8', fontWeight: 700, textTransform: 'uppercase', letterSpacing: 0.5 }}>{label}</div>
      </div>
      <div style={{ fontSize: 22, fontWeight: 800, color: 'var(--fg-primary)' }}>{value}</div>
      {hint && <div style={{ fontSize: 11, color: '#94a3b8', marginTop: 4 }}>{hint}</div>}
    </div>
  );
}

function prettify(value) {
  if (!value) return null;
  return value.toString().replace(/_/g, ' ').replace(/\b\w/g, (c) => c.toUpperCase());
}

export default function MemberDetailPage({ memberId, onBack }) {
  const [profile, setProfile] = useState(null);
  const [loading, setLoading] = useState(true);
  const [error, setError] = useState('');

  const load = () => {
    setLoading(true);
    setError('');
    api.getMemberProfile(memberId)
      .then(setProfile)
      .catch((e) => setError(e.message || 'Failed to load member.'))
      .finally(() => setLoading(false));
  };

  useEffect(() => { load(); }, [memberId]);

  if (loading) {
    return (
      <section className="ds-page">
        <p style={{ padding: 40, textAlign: 'center', color: '#94a3b8' }}>Loading member profile…</p>
      </section>
    );
  }

  if (error || !profile) {
    return (
      <section className="ds-page">
        <Ds.Button variant="secondary" leftIcon={<IconArrowLeft size={14} />} onClick={onBack}>Back to directory</Ds.Button>
        <div style={{ marginTop: 24, color: '#dc2626' }}>{error || 'Member not found.'}</div>
      </section>
    );
  }

  const { user, membership, business, application, activity, complements = [] } = profile;

  // T-shirt size now lives on the complements ledger. Fall back to the
  // legacy applications.tshirt_size column for historical records.
  const tshirtComplement = complements.find(c => c.type_code === 'founders_tshirt');
  const tshirtSize = tshirtComplement?.variant || application?.tshirt_size || null;
  const tshirtStatus = tshirtComplement?.fulfilment_status || null;
  const photoUrl = asAbsolute(user.profile_photo);
  const initial = (user.full_name || '?').trim()[0]?.toUpperCase() || '?';

  return (
    <section className="ds-page">
      {/* Top bar */}
      <div style={{ display: 'flex', alignItems: 'center', gap: 12, marginBottom: 20 }}>
        <Ds.Button variant="secondary" leftIcon={<IconArrowLeft size={14} />} onClick={onBack}>Back to directory</Ds.Button>
        <Ds.Button variant="secondary" leftIcon={<IconRefresh size={14} />} onClick={load}>Refresh</Ds.Button>
      </div>

      {/* Header card */}
      <div
        style={{
          background: 'linear-gradient(135deg, #0f172a 0%, #1e3a8a 100%)',
          borderRadius: 20,
          padding: 28,
          color: '#fff',
          display: 'flex',
          gap: 20,
          alignItems: 'center',
          flexWrap: 'wrap',
        }}
      >
        <div style={{ position: 'relative' }}>
          {photoUrl ? (
            <img
              src={photoUrl}
              alt={user.full_name}
              style={{ width: 96, height: 96, borderRadius: '50%', objectFit: 'cover', border: '3px solid rgba(245, 158, 11, 0.5)' }}
              onError={(e) => { e.currentTarget.style.display = 'none'; }}
            />
          ) : (
            <div
              style={{
                width: 96, height: 96, borderRadius: '50%',
                background: 'linear-gradient(135deg, #f59e0b 0%, #d97706 100%)',
                display: 'flex', alignItems: 'center', justifyContent: 'center',
                fontSize: 40, fontWeight: 800, color: '#0f172a',
                border: '3px solid rgba(255,255,255,0.15)',
              }}
            >
              {initial}
            </div>
          )}
        </div>
        <div style={{ flex: 1, minWidth: 220 }}>
          <div style={{ fontSize: 24, fontWeight: 800, marginBottom: 4 }}>{user.full_name || 'Unnamed member'}</div>
          <div style={{ fontSize: 14, color: '#cbd5e1' }}>
            {business?.business_name || application?.designation || '—'}
          </div>
          <div style={{ display: 'flex', gap: 8, marginTop: 12, flexWrap: 'wrap' }}>
            <Ds.Badge variant="accent">{user.role}</Ds.Badge>
            {membership?.chapter_name && <Ds.Badge variant="brand">{membership.chapter_name}</Ds.Badge>}
            {membership?.industry_name && <Ds.Badge>{membership.industry_name}</Ds.Badge>}
            <Ds.Badge dot variant={user.is_active ? 'success' : 'danger'}>{user.is_active ? 'Active' : 'Inactive'}</Ds.Badge>
            {user.verification_level && user.verification_level !== 'none' && (
              <Ds.Badge variant="accent">{user.verification_level.toUpperCase()}</Ds.Badge>
            )}
          </div>
        </div>
        <div style={{ textAlign: 'right' }}>
          <div style={{ fontSize: 11, color: '#94a3b8', textTransform: 'uppercase', letterSpacing: 1 }}>Joined</div>
          <div style={{ fontSize: 14, fontWeight: 600 }}>
            {user.created_at ? new Date(user.created_at).toLocaleDateString() : '—'}
          </div>
        </div>
      </div>

      {/* Stat tiles */}
      <div style={{ display: 'grid', gridTemplateColumns: 'repeat(auto-fit, minmax(180px, 1fr))', gap: 12, marginTop: SECTION_GAP }}>
        <StatTile icon={IconHierarchy2} label="Referrals given" value={activity?.referrals_given || 0} />
        <StatTile icon={IconHierarchy2} label="Referrals received" value={activity?.referrals_received || 0} />
        <StatTile icon={IconCoin} label="Payments" value={activity?.payments_count || 0} hint={`LKR ${(activity?.payments_total || 0).toLocaleString()}`} />
        <StatTile icon={IconBuildingStore} label="Marketplace listings" value={activity?.listings_count || 0} />
        <StatTile icon={IconCoin} label="Cumulative value" value={`LKR ${(user.cumulative_value_generated || 0).toLocaleString()}`} />
      </div>

      {/* Two-column body */}
      <div style={{ display: 'grid', gridTemplateColumns: 'minmax(0, 2fr) minmax(0, 1fr)', gap: SECTION_GAP, marginTop: SECTION_GAP }}>
        {/* Left column */}
        <div style={{ display: 'flex', flexDirection: 'column', gap: SECTION_GAP }}>
          <Section title="Contact" icon={IconMail}>
            <FieldRow label="Phone" value={user.phone_number} mono />
            <FieldRow label="Email" value={user.email} />
            <FieldRow label="District" value={business?.district || '—'} />
          </Section>

          {application && (
            <Section title="Founding-member profile" icon={IconClipboardList}>
              <FieldRow label="Designation" value={application.designation} />
              <FieldRow label="Decision authority" value={prettify(application.decision_authority)} />
              <FieldRow label="Years in operation" value={application.years_in_operation} />
              <FieldRow label="Legal type" value={prettify(application.business_legal_type)} />
              <FieldRow label="BR number" value={application.business_registration_number} mono />
              <FieldRow label="Website" value={application.website_url} href={application.website_url} />
              <FieldRow label="LinkedIn" value={application.linkedin_url} href={application.linkedin_url} />
              <FieldRow label="Referred by" value={application.referred_by_name} />
              <FieldRow label="What they offer" value={application.what_you_offer} />
              <FieldRow label="What they seek" value={application.what_you_seek} />
            </Section>
          )}

          {business && (
            <Section title="Business" icon={IconBuildingStore}>
              <FieldRow label="Business name" value={business.business_name} />
              <FieldRow label="Description" value={business.description} />
              <FieldRow label="Website" value={business.website} href={business.website} />
              <FieldRow label="Established year" value={business.established_year} />
              <FieldRow label="BR number" value={business.br_number} mono />
              <FieldRow label="Physical address" value={business.address} />
              <FieldRow label="Google maps link" value={business.google_maps_url} href={business.google_maps_url} />
              <FieldRow label="LinkedIn URL" value={business.linkedin_url} href={business.linkedin_url} />
              <FieldRow label="Facebook URL" value={business.facebook_url} href={business.facebook_url} />
              <FieldRow label="Instagram URL" value={business.instagram_url} href={business.instagram_url} />
              {business.brochure_url && (
                <FieldRow label="Brochure PDF" value="Download PDF Brochure" href={asAbsolute(business.brochure_url)} />
              )}
              {business.logo_url && (
                <div style={{ marginTop: 12 }}>
                  <div style={{ fontSize: 12, color: '#94a3b8', fontWeight: 600, textTransform: 'uppercase', letterSpacing: 0.5, marginBottom: 6 }}>Business logo</div>
                  <img
                    src={asAbsolute(business.logo_url)}
                    alt="Business Logo"
                    style={{ maxHeight: 80, maxWidth: 200, borderRadius: 8, border: '1px solid var(--border-subtle)', padding: 4, background: '#fff' }}
                  />
                </div>
              )}
            </Section>
          )}
        </div>

        {/* Right column */}
        <div style={{ display: 'flex', flexDirection: 'column', gap: SECTION_GAP }}>
          {membership && (
            <Section title="Membership" icon={IconAward}>
              <FieldRow label="Chapter" value={membership.chapter_name} />
              <FieldRow label="Industry" value={membership.industry_name} />
              <FieldRow label="Tier" value={prettify(membership.membership_type)} />
              <FieldRow label="Active" value={membership.is_active ? 'Yes' : 'No'} />
              <FieldRow label="Started" value={membership.start_date} />
              <FieldRow label="Renews" value={membership.end_date} />
            </Section>
          )}

          {application && (
            <Section title="Onboarding" icon={IconShirt}>
              <FieldRow label="Status" value={application.onboarding_completed_at ? 'Completed' : 'Pending'} />
              <FieldRow label="T-shirt size" value={tshirtSize} />
              {tshirtStatus && (
                <FieldRow label="T-shirt fulfilment" value={prettify(tshirtStatus)} />
              )}
              <FieldRow label="Completed at" value={application.onboarding_completed_at ? new Date(application.onboarding_completed_at).toLocaleString() : null} />
              <FieldRow label="Application submitted" value={application.submitted_at ? new Date(application.submitted_at).toLocaleString() : null} />
              <FieldRow label="Fit-call date" value={application.fit_call_date ? new Date(application.fit_call_date).toLocaleString() : null} />
            </Section>
          )}

          {activity?.privilege_card && (
            <Section title="Privilege card" icon={IconAward}>
              <FieldRow label="Card #" value={activity.privilege_card.card_number} mono />
              <FieldRow label="Issued" value={activity.privilege_card.issued_at ? new Date(activity.privilege_card.issued_at).toLocaleDateString() : null} />
              <FieldRow label="Expires" value={activity.privilege_card.expires_at ? new Date(activity.privilege_card.expires_at).toLocaleDateString() : null} />
            </Section>
          )}

          <Section title="Account flags" icon={IconAward}>
            <FieldRow label="Verification" value={prettify(user.verification_level)} />
            <FieldRow label="Must change password" value={user.must_change_password ? 'Yes' : 'No'} />
          </Section>
        </div>
      </div>
    </section>
  );
}
