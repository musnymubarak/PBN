import React, { useCallback, useEffect, useState } from 'react';
import {
  IconPlus, IconRefresh, IconArrowUp, IconArrowDown, IconTrash, IconEdit,
  IconPhoto, IconLayoutDashboard,
} from '@tabler/icons-react';
import { api, STATIC_BASE_URL } from '../lib/api';
import * as Ds from '../components/ui';

// ── Constants ────────────────────────────────────────────────────────────────

const SLIDE_TYPES = [
  { id: 'custom', name: 'Custom (fully authored)' },
  { id: 'next_virtual_event', name: 'Auto: next virtual event' },
  { id: 'next_physical_event', name: 'Auto: next physical event' },
];

const SLIDE_TYPE_META = {
  custom: { label: 'Custom', variant: 'brand' },
  next_virtual_event: { label: 'Auto · Virtual', variant: 'accent' },
  next_physical_event: { label: 'Auto · Physical', variant: 'info' },
};

const CTA_ACTION_TYPES = [
  { id: 'none', name: 'No button' },
  { id: 'route', name: 'Open in-app screen (route)' },
  { id: 'url', name: 'Open URL / link' },
  { id: 'event', name: 'Open event' },
  { id: 'maps', name: 'Open maps' },
];

// Hint shown under the CTA value field per action type.
const CTA_VALUE_HINT = {
  none: '',
  route: 'Route name the app understands, e.g. create_referral, events, marketplace',
  url: 'Full URL, e.g. https://zoom.us/j/123 (also used for Zoom links)',
  event: 'Event id to open the event detail screen',
  maps: 'Location / address query to open in maps',
};

// Member-facing roles for audience targeting. Empty selection = everyone.
const TARGETABLE_ROLES = ['PROSPECT', 'MEMBER', 'CHAPTER_ADMIN', 'PARTNER_ADMIN'];

// ── Helpers ──────────────────────────────────────────────────────────────────

function imgSrc(url) {
  if (!url) return '';
  return url.startsWith('http') ? url : `${STATIC_BASE_URL}${url}`;
}

// ISO (UTC) -> value for <input type="datetime-local"> in local time.
function isoToLocalInput(iso) {
  if (!iso) return '';
  const d = new Date(iso);
  const local = new Date(d.getTime() - d.getTimezoneOffset() * 60000);
  return local.toISOString().slice(0, 16);
}

// datetime-local value (local time) -> ISO (UTC) for the API.
function localInputToIso(value) {
  if (!value) return null;
  return new Date(value).toISOString();
}

function fmtSchedule(slide) {
  const s = slide.starts_at ? new Date(slide.starts_at).toLocaleDateString() : null;
  const e = slide.ends_at ? new Date(slide.ends_at).toLocaleDateString() : null;
  if (!s && !e) return 'Always';
  return `${s || '…'} → ${e || '…'}`;
}

function fmtAudience(slide) {
  const roles = slide.audience_roles?.length ? slide.audience_roles.length : 0;
  const chaps = slide.audience_chapter_ids?.length ? slide.audience_chapter_ids.length : 0;
  if (!roles && !chaps) return 'Everyone';
  const parts = [];
  if (roles) parts.push(`${roles} role${roles === 1 ? '' : 's'}`);
  if (chaps) parts.push(`${chaps} chapter${chaps === 1 ? '' : 's'}`);
  return parts.join(' · ');
}

// ── Page ─────────────────────────────────────────────────────────────────────

export default function HomeSlidesPage() {
  const [slides, setSlides] = useState([]);
  const [chapters, setChapters] = useState([]);
  const [loading, setLoading] = useState(true);
  const [reordering, setReordering] = useState(false);
  const [editing, setEditing] = useState(null); // slide object or {} for new
  const [error, setError] = useState('');

  const fetchSlides = useCallback(async () => {
    setLoading(true);
    setError('');
    try {
      const data = await api.listHomeSlides();
      setSlides(data || []);
    } catch (err) {
      setError(err.message || 'Failed to load slides.');
    } finally {
      setLoading(false);
    }
  }, []);

  useEffect(() => {
    fetchSlides();
    api.listChapters({ active_only: false }).then(d => setChapters(d || [])).catch(() => {});
  }, [fetchSlides]);

  const persistOrder = async (next) => {
    setSlides(next); // optimistic
    setReordering(true);
    try {
      await api.reorderHomeSlides(next.map(s => s.id));
    } catch (err) {
      setError(err.message || 'Reorder failed.');
      fetchSlides(); // revert to server truth
    } finally {
      setReordering(false);
    }
  };

  const move = (index, dir) => {
    const target = index + dir;
    if (target < 0 || target >= slides.length) return;
    const next = [...slides];
    [next[index], next[target]] = [next[target], next[index]];
    persistOrder(next);
  };

  const handleDelete = async (slide) => {
    if (!window.confirm('Delete this slide? This cannot be undone.')) return;
    try {
      await api.deleteHomeSlide(slide.id);
      fetchSlides();
    } catch (err) {
      setError(err.message || 'Delete failed.');
    }
  };

  return (
    <section className="ds-page">
      <Ds.PageHeader
        title="Home Slides"
        description="Control the home-screen carousel — content, order, schedule and audience — without an app update."
        actions={
          <>
            <Ds.Button variant="secondary" leftIcon={<IconRefresh size={14} />} onClick={fetchSlides}>
              Refresh
            </Ds.Button>
            <Ds.Button variant="primary" leftIcon={<IconPlus size={14} />} onClick={() => setEditing({})}>
              New slide
            </Ds.Button>
          </>
        }
      />

      {error && (
        <div className="login-error" style={{ marginBottom: '1rem' }}>{error}</div>
      )}

      <Ds.Section
        title="Carousel"
        subtitle={`${slides.length} slide${slides.length === 1 ? '' : 's'}${reordering ? ' · saving order…' : ''}`}
        flush
      >
        <Ds.Table>
          <thead>
            <tr>
              <th style={{ width: 90 }}>Order</th>
              <th>Slide</th>
              <th>Type</th>
              <th>Button</th>
              <th>Schedule</th>
              <th>Audience</th>
              <th>Status</th>
              <th className="ds-table__actions" />
            </tr>
          </thead>
          <tbody>
            {loading ? (
              <Ds.Table.LoadingRow colSpan={8} label="Loading slides…" />
            ) : slides.length === 0 ? (
              <Ds.Table.EmptyRow
                colSpan={8}
                icon={IconLayoutDashboard}
                title="No slides yet"
                description="Create one to populate the home carousel."
              />
            ) : slides.map((s, i) => {
              const meta = SLIDE_TYPE_META[s.slide_type] || { label: s.slide_type, variant: 'neutral' };
              return (
                <tr key={s.id} style={{ opacity: s.is_active ? 1 : 0.6 }}>
                  <td>
                    <div style={{ display: 'flex', alignItems: 'center', gap: 4 }}>
                      <Ds.IconButton aria-label="Move up" disabled={i === 0 || reordering} onClick={() => move(i, -1)}>
                        <IconArrowUp size={15} />
                      </Ds.IconButton>
                      <Ds.IconButton aria-label="Move down" disabled={i === slides.length - 1 || reordering} onClick={() => move(i, 1)}>
                        <IconArrowDown size={15} />
                      </Ds.IconButton>
                    </div>
                  </td>
                  <td>
                    <div style={{ display: 'flex', alignItems: 'center', gap: 'var(--space-3)' }}>
                      <div style={{
                        width: 56, height: 36, borderRadius: 'var(--radius-md)',
                        background: 'var(--bg-subtle)', overflow: 'hidden',
                        border: '1px solid var(--border-subtle)', flexShrink: 0,
                        display: 'flex', alignItems: 'center', justifyContent: 'center',
                      }}>
                        {s.image_url
                          ? <img src={imgSrc(s.image_url)} alt="" style={{ width: '100%', height: '100%', objectFit: 'cover' }} />
                          : <IconPhoto size={16} color="var(--fg-muted)" />}
                      </div>
                      <div style={{ minWidth: 0 }}>
                        {s.badge_label && (
                          <div style={{ fontSize: 'var(--text-xs)', fontWeight: 700, letterSpacing: '0.04em', color: 'var(--fg-muted)', textTransform: 'uppercase' }}>
                            {s.badge_label}
                          </div>
                        )}
                        <div style={{ fontWeight: 600, overflow: 'hidden', textOverflow: 'ellipsis', whiteSpace: 'nowrap', maxWidth: 240 }}>
                          {s.title || <span style={{ color: 'var(--fg-muted)' }}>{s.slide_type === 'custom' ? '(no title)' : 'Auto from next event'}</span>}
                        </div>
                      </div>
                    </div>
                  </td>
                  <td><Ds.Badge variant={meta.variant}>{meta.label}</Ds.Badge></td>
                  <td className="ds-table__muted">
                    {s.cta_action_type && s.cta_action_type !== 'none'
                      ? (s.cta_label || s.cta_action_type)
                      : '—'}
                  </td>
                  <td className="ds-table__muted">{fmtSchedule(s)}</td>
                  <td className="ds-table__muted">{fmtAudience(s)}</td>
                  <td>
                    <Ds.Badge dot variant={s.is_active ? 'success' : 'danger'}>
                      {s.is_active ? 'Active' : 'Hidden'}
                    </Ds.Badge>
                  </td>
                  <td className="ds-table__actions">
                    <div style={{ display: 'flex', gap: 4 }}>
                      <Ds.IconButton aria-label="Edit" onClick={() => setEditing(s)}><IconEdit size={16} /></Ds.IconButton>
                      <Ds.IconButton aria-label="Delete" onClick={() => handleDelete(s)}><IconTrash size={16} /></Ds.IconButton>
                    </div>
                  </td>
                </tr>
              );
            })}
          </tbody>
        </Ds.Table>
      </Ds.Section>

      {editing && (
        <SlideEditModal
          slide={editing.id ? editing : null}
          chapters={chapters}
          onClose={() => setEditing(null)}
          onSaved={() => { setEditing(null); fetchSlides(); }}
        />
      )}
    </section>
  );
}

// ── Edit / Create Modal ──────────────────────────────────────────────────────

function SlideEditModal({ slide, chapters, onClose, onSaved }) {
  const isEdit = !!slide;
  const [form, setForm] = useState({
    slide_type: slide?.slide_type || 'custom',
    badge_label: slide?.badge_label || '',
    title: slide?.title || '',
    subtitle: slide?.subtitle || '',
    image_url: slide?.image_url || '',
    cta_label: slide?.cta_label || '',
    cta_action_type: slide?.cta_action_type || 'none',
    cta_action_value: slide?.cta_action_value || '',
    is_active: slide?.is_active ?? true,
    starts_at: isoToLocalInput(slide?.starts_at),
    ends_at: isoToLocalInput(slide?.ends_at),
    audience_roles: slide?.audience_roles || [],
    audience_chapter_ids: slide?.audience_chapter_ids || [],
  });
  const [uploading, setUploading] = useState(false);
  const [saving, setSaving] = useState(false);
  const [error, setError] = useState('');

  const set = (patch) => setForm(prev => ({ ...prev, ...patch }));
  const isDynamic = form.slide_type !== 'custom';

  const toggleRole = (role) => set({
    audience_roles: form.audience_roles.includes(role)
      ? form.audience_roles.filter(r => r !== role)
      : [...form.audience_roles, role],
  });
  const toggleChapter = (id) => set({
    audience_chapter_ids: form.audience_chapter_ids.includes(id)
      ? form.audience_chapter_ids.filter(c => c !== id)
      : [...form.audience_chapter_ids, id],
  });

  const handleUpload = async (e) => {
    const file = e.target.files?.[0];
    if (!file) return;
    setUploading(true);
    setError('');
    try {
      const res = await api.uploadHomeSlideImage(file);
      set({ image_url: res.image_url });
    } catch (err) {
      setError('Image upload failed: ' + (err.message || ''));
    } finally {
      setUploading(false);
    }
  };

  const handleSave = async () => {
    setSaving(true);
    setError('');
    try {
      const payload = {
        slide_type: form.slide_type,
        badge_label: form.badge_label || null,
        title: form.title || null,
        subtitle: form.subtitle || null,
        image_url: form.image_url || null,
        cta_label: form.cta_label || null,
        cta_action_type: form.cta_action_type,
        cta_action_value: form.cta_action_value || null,
        is_active: form.is_active,
        starts_at: localInputToIso(form.starts_at),
        ends_at: localInputToIso(form.ends_at),
        audience_roles: form.audience_roles.length ? form.audience_roles : null,
        audience_chapter_ids: form.audience_chapter_ids.length ? form.audience_chapter_ids : null,
      };
      if (isEdit) {
        await api.updateHomeSlide(slide.id, payload);
      } else {
        await api.createHomeSlide(payload);
      }
      onSaved();
    } catch (err) {
      setError(err.message || 'Failed to save slide.');
    } finally {
      setSaving(false);
    }
  };

  return (
    <Ds.Modal open onClose={onClose} size="lg">
      <Ds.Modal.Header
        title={isEdit ? 'Edit slide' : 'New slide'}
        subtitle="Changes go live on next app refresh — no store update needed."
        onClose={onClose}
      />
      <Ds.Modal.Body>
        {error && <div className="login-error" style={{ marginBottom: '1rem' }}>{error}</div>}

        <Ds.Field label="Slide type">
          <Ds.Select
            value={form.slide_type}
            options={SLIDE_TYPES}
            onChange={(v) => set({ slide_type: v })}
          />
        </Ds.Field>
        {isDynamic && (
          <p className="ds-help" style={{ marginTop: -8, marginBottom: 12 }}>
            Title, image and the button auto-fill from the next event. Fields below act as optional overrides.
          </p>
        )}

        <div style={{ display: 'grid', gridTemplateColumns: '1fr 1fr', gap: 'var(--space-4)' }}>
          <Ds.Field label="Badge label">
            <Ds.Input
              placeholder="e.g. NETWORK GROWTH"
              value={form.badge_label}
              onChange={(e) => set({ badge_label: e.target.value })}
            />
          </Ds.Field>
          <Ds.Field label={isDynamic ? 'Title (override)' : 'Title'}>
            <Ds.Input
              placeholder="Headline"
              value={form.title}
              onChange={(e) => set({ title: e.target.value })}
            />
          </Ds.Field>
        </div>

        <Ds.Field label="Subtitle">
          <Ds.Textarea
            rows={2}
            placeholder="Supporting copy (optional)"
            value={form.subtitle}
            onChange={(e) => set({ subtitle: e.target.value })}
          />
        </Ds.Field>

        {/* Image upload */}
        <Ds.Field label={isDynamic ? 'Image (override)' : 'Image'}>
          <div style={{ display: 'flex', gap: '1rem', alignItems: 'center' }}>
            <div style={{
              width: 120, height: 76, borderRadius: 'var(--radius-md)', background: 'var(--bg-subtle)',
              overflow: 'hidden', border: '1px solid var(--border-subtle)', flexShrink: 0,
              display: 'flex', alignItems: 'center', justifyContent: 'center',
            }}>
              {form.image_url
                ? <img src={imgSrc(form.image_url)} alt="" style={{ width: '100%', height: '100%', objectFit: 'cover' }} />
                : <IconPhoto size={22} color="var(--fg-muted)" />}
            </div>
            <div>
              <input id="slide-image-upload" type="file" accept="image/*" style={{ display: 'none' }} onChange={handleUpload} />
              <label htmlFor="slide-image-upload" className="btn-secondary" style={{ display: 'inline-flex', alignItems: 'center', gap: '0.5rem', cursor: 'pointer', fontSize: '0.85rem', padding: '0.5rem 0.75rem' }}>
                <IconPlus size={16} /> {uploading ? 'Uploading…' : form.image_url ? 'Change image' : 'Upload image'}
              </label>
              {form.image_url && (
                <button type="button" style={{ marginLeft: '0.5rem', fontSize: '0.75rem', color: '#ef4444', border: 'none', background: 'none', cursor: 'pointer', fontWeight: 600 }} onClick={() => set({ image_url: '' })}>
                  Remove
                </button>
              )}
            </div>
          </div>
        </Ds.Field>

        {/* Call to action */}
        <div style={{ display: 'grid', gridTemplateColumns: '1fr 1fr', gap: 'var(--space-4)' }}>
          <Ds.Field label="Button label">
            <Ds.Input
              placeholder="e.g. SUBMIT OPPORTUNITY"
              value={form.cta_label}
              onChange={(e) => set({ cta_label: e.target.value })}
            />
          </Ds.Field>
          <Ds.Field label="Button action">
            <Ds.Select
              value={form.cta_action_type}
              options={CTA_ACTION_TYPES}
              onChange={(v) => set({ cta_action_type: v })}
            />
          </Ds.Field>
        </div>
        {form.cta_action_type !== 'none' && (
          <Ds.Field label="Action value" hint={CTA_VALUE_HINT[form.cta_action_type]}>
            <Ds.Input
              placeholder={CTA_VALUE_HINT[form.cta_action_type]}
              value={form.cta_action_value}
              onChange={(e) => set({ cta_action_value: e.target.value })}
            />
          </Ds.Field>
        )}

        {/* Scheduling */}
        <div style={{ display: 'grid', gridTemplateColumns: '1fr 1fr', gap: 'var(--space-4)' }}>
          <Ds.Field label="Show from" hint="Leave empty for always">
            <input className="ds-input" type="datetime-local" value={form.starts_at} onChange={(e) => set({ starts_at: e.target.value })} />
          </Ds.Field>
          <Ds.Field label="Show until" hint="Leave empty for no end">
            <input className="ds-input" type="datetime-local" value={form.ends_at} onChange={(e) => set({ ends_at: e.target.value })} />
          </Ds.Field>
        </div>

        {/* Audience targeting */}
        <Ds.Field label="Audience — roles" hint="None selected = visible to everyone">
          <div style={{ display: 'flex', flexWrap: 'wrap', gap: '0.5rem' }}>
            {TARGETABLE_ROLES.map(role => (
              <button
                key={role}
                type="button"
                className={`ds-chip${form.audience_roles.includes(role) ? ' is-active' : ''}`}
                onClick={() => toggleRole(role)}
              >
                {role}
              </button>
            ))}
          </div>
        </Ds.Field>

        <Ds.Field label="Audience — chapters" hint="None selected = all chapters">
          <div style={{ maxHeight: 140, overflowY: 'auto', border: '1px solid var(--border-subtle)', borderRadius: 'var(--radius-md)', padding: '0.5rem' }}>
            {chapters.length === 0 ? (
              <span className="ds-help">No chapters loaded.</span>
            ) : chapters.map(c => (
              <label key={c.id} style={{ display: 'flex', alignItems: 'center', gap: '0.5rem', padding: '0.25rem 0', fontSize: '0.85rem', cursor: 'pointer' }}>
                <input
                  type="checkbox"
                  checked={form.audience_chapter_ids.includes(c.id)}
                  onChange={() => toggleChapter(c.id)}
                />
                {c.name} <span style={{ color: 'var(--fg-muted)' }}>· {c.district}</span>
              </label>
            ))}
          </div>
        </Ds.Field>

        <label style={{ display: 'flex', alignItems: 'center', gap: '0.6rem', marginTop: '0.5rem', fontWeight: 600 }}>
          <input type="checkbox" checked={form.is_active} onChange={(e) => set({ is_active: e.target.checked })} />
          Active (visible in the app)
        </label>
      </Ds.Modal.Body>
      <Ds.Modal.Footer>
        <Ds.Button variant="secondary" onClick={onClose}>Cancel</Ds.Button>
        <Ds.Button variant="primary" loading={saving} onClick={handleSave}>
          {isEdit ? 'Save changes' : 'Create slide'}
        </Ds.Button>
      </Ds.Modal.Footer>
    </Ds.Modal>
  );
}
