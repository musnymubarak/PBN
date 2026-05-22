import React, { useCallback, useEffect, useState } from 'react';
import {
  IconShirt, IconRefresh, IconSearch, IconCheck, IconTruckDelivery,
  IconClock, IconX, IconPackage, IconMessage,
} from '@tabler/icons-react';
import { api } from '../lib/api';
import * as Ds from '../components/ui';

const STATUS_META = {
  pending:     { label: 'Pending',     variant: 'warning', icon: IconClock },
  in_progress: { label: 'In progress', variant: 'brand',   icon: IconPackage },
  shipped:     { label: 'Shipped',     variant: 'accent',  icon: IconTruckDelivery },
  delivered:   { label: 'Delivered',   variant: 'success', icon: IconCheck },
  cancelled:   { label: 'Cancelled',   variant: 'danger',  icon: IconX },
};

const STATUS_OPTIONS = [
  { id: '', name: 'All statuses' },
  ...Object.entries(STATUS_META).map(([id, m]) => ({ id, name: m.label })),
];

function StatusPill({ status }) {
  const meta = STATUS_META[status] || { label: status, variant: 'brand' };
  return <Ds.Badge dot variant={meta.variant}>{meta.label}</Ds.Badge>;
}

function StatusUpdateDrawer({ record, onClose, onUpdated }) {
  const [status, setStatus] = useState(record.fulfilment_status);
  const [notes, setNotes] = useState(record.notes || '');
  const [saving, setSaving] = useState(false);
  const [error, setError] = useState('');

  const save = async () => {
    setError('');
    setSaving(true);
    try {
      await api.updateComplementStatus(record.id, { status, notes: notes || null });
      onUpdated();
      onClose();
    } catch (err) {
      setError(err.message || 'Failed to update.');
    } finally {
      setSaving(false);
    }
  };

  return (
    <div className="modal-overlay" onClick={(e) => e.target === e.currentTarget && onClose()}>
      <div className="modal-content" onClick={e => e.stopPropagation()} style={{ maxWidth: 480 }}>
        <div className="modal-header">
          <h2 style={{ fontSize: '1.25rem', fontWeight: 800 }}>Update fulfilment</h2>
          <button type="button" className="modal-close-btn" onClick={onClose}><IconX size={20} /></button>
        </div>
        <div style={{ padding: '1.5rem' }}>
          {error && (
            <div className="login-error" style={{ marginBottom: '1rem' }}>{error}</div>
          )}

          <div style={{ background: '#f8fafc', padding: '1rem', borderRadius: 12, marginBottom: '1.25rem' }}>
            <div style={{ fontSize: 13, color: 'var(--fg-secondary)', marginBottom: 4 }}>{record.complement_type_name}</div>
            <div style={{ fontSize: 16, fontWeight: 700 }}>{record.user_full_name}</div>
            <div style={{ fontSize: 13, color: 'var(--fg-muted)' }}>
              {record.chapter_name ? `${record.chapter_name} · ` : ''}
              {record.user_phone_number}
            </div>
            {record.variant && (
              <div style={{ marginTop: 8, fontSize: 13 }}>
                Variant: <strong>{record.variant}</strong>
              </div>
            )}
          </div>

          <label style={{ fontSize: 11, fontWeight: 700, color: 'var(--fg-secondary)', textTransform: 'uppercase', letterSpacing: 1, display: 'block', marginBottom: 6 }}>
            Fulfilment status
          </label>
          <div style={{ display: 'grid', gridTemplateColumns: 'repeat(auto-fit, minmax(140px, 1fr))', gap: 8, marginBottom: '1.25rem' }}>
            {Object.entries(STATUS_META).map(([key, meta]) => {
              const active = status === key;
              const Icon = meta.icon;
              return (
                <button
                  key={key}
                  type="button"
                  onClick={() => setStatus(key)}
                  style={{
                    padding: '10px 12px',
                    border: active ? '2px solid #1e3a8a' : '1px solid var(--border-subtle)',
                    background: active ? 'rgba(30, 58, 138, 0.05)' : '#fff',
                    borderRadius: 10,
                    cursor: 'pointer',
                    display: 'flex',
                    alignItems: 'center',
                    gap: 8,
                    fontWeight: active ? 700 : 500,
                    fontSize: 13,
                    color: active ? '#1e3a8a' : 'var(--fg-primary)',
                  }}
                >
                  <Icon size={14} />
                  {meta.label}
                </button>
              );
            })}
          </div>

          <label style={{ fontSize: 11, fontWeight: 700, color: 'var(--fg-secondary)', textTransform: 'uppercase', letterSpacing: 1, display: 'block', marginBottom: 6 }}>
            Notes / tracking
          </label>
          <textarea
            value={notes}
            onChange={(e) => setNotes(e.target.value)}
            rows={3}
            placeholder="Courier name, tracking number, internal comments…"
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

          <div style={{ display: 'flex', gap: '0.75rem', marginTop: '1.25rem' }}>
            <button
              type="button"
              className="login-btn"
              disabled={saving}
              onClick={save}
              style={{ flex: 2 }}
            >
              {saving ? 'Saving…' : 'Save changes'}
            </button>
            <button type="button" className="login-btn" onClick={onClose} disabled={saving} style={{ flex: 1, background: '#e2e8f0', color: '#0f172a' }}>
              Cancel
            </button>
          </div>
        </div>
      </div>
    </div>
  );
}

export default function ComplementsPage() {
  const [items, setItems] = useState([]);
  const [total, setTotal] = useState(0);
  const [page, setPage] = useState(1);
  const [pageSize] = useState(25);
  const [loading, setLoading] = useState(true);

  const [search, setSearch] = useState('');
  const [statusFilter, setStatusFilter] = useState('');
  const [typeFilter, setTypeFilter] = useState('');
  const [chapterFilter, setChapterFilter] = useState('');

  const [types, setTypes] = useState([]);
  const [chapters, setChapters] = useState([]);
  const [editing, setEditing] = useState(null);

  const fetchData = useCallback(async () => {
    setLoading(true);
    try {
      const params = { page, page_size: pageSize };
      if (search) params.search = search;
      if (statusFilter) params.status = statusFilter;
      if (typeFilter) params.type = typeFilter;
      if (chapterFilter) params.chapter_id = chapterFilter;
      const data = await api.listComplements(params);
      setItems(data.items || []);
      setTotal(data.total || 0);
    } catch (err) {
      console.error('Failed to load complements:', err);
    } finally {
      setLoading(false);
    }
  }, [page, pageSize, search, statusFilter, typeFilter, chapterFilter]);

  useEffect(() => { fetchData(); }, [fetchData]);
  useEffect(() => {
    api.listComplementTypes(true).then(setTypes).catch(() => setTypes([]));
    api.listChapters().then(setChapters).catch(() => setChapters([]));
  }, []);

  const pages = Math.max(1, Math.ceil(total / pageSize));

  return (
    <section className="ds-page">
      <Ds.PageHeader
        title="Complements"
        description="Track founding-member T-shirts and future perk fulfilment across the network."
        actions={
          <Ds.Button variant="secondary" leftIcon={<IconRefresh size={14} />} onClick={() => { setPage(1); fetchData(); }}>
            Refresh
          </Ds.Button>
        }
      />

      <Ds.Section
        title="Fulfilment ledger"
        subtitle={total > 0 ? `${total.toLocaleString()} record${total === 1 ? '' : 's'}` : undefined}
        flush
      >
        <div style={{ display: 'flex', gap: 'var(--space-3)', flexWrap: 'wrap', padding: 'var(--space-5) var(--space-6)', borderBottom: '1px solid var(--border-subtle)' }}>
          <Ds.Input
            placeholder="Search member, phone or notes…"
            value={search}
            onChange={e => { setSearch(e.target.value); setPage(1); }}
            leftIcon={<IconSearch size={14} />}
            style={{ flex: 1, minWidth: 240 }}
          />
          <Ds.Select
            placeholder="All types"
            value={typeFilter}
            options={[{ id: '', name: 'All types' }, ...types.map(t => ({ id: t.code, name: t.name }))]}
            allowClear
            onChange={val => { setTypeFilter(val); setPage(1); }}
            style={{ width: 200 }}
          />
          <Ds.Select
            placeholder="All statuses"
            value={statusFilter}
            options={STATUS_OPTIONS}
            allowClear
            onChange={val => { setStatusFilter(val); setPage(1); }}
            style={{ width: 180 }}
          />
          <Ds.Select
            placeholder="All chapters"
            value={chapterFilter}
            options={chapters}
            allowClear
            onChange={val => { setChapterFilter(val); setPage(1); }}
            style={{ width: 200 }}
          />
        </div>

        <Ds.Table>
          <thead>
            <tr>
              <th>Member</th>
              <th>Chapter</th>
              <th>Complement</th>
              <th>Variant</th>
              <th>Status</th>
              <th>Updated</th>
              <th className="ds-table__actions" />
            </tr>
          </thead>
          <tbody>
            {loading ? (
              <Ds.Table.LoadingRow colSpan={7} label="Loading ledger…" />
            ) : items.length === 0 ? (
              <Ds.Table.EmptyRow
                colSpan={7}
                icon={IconShirt}
                title="No complement records"
                description="Approved members get a T-shirt record automatically after onboarding."
              />
            ) : items.map(row => (
              <tr key={row.id} className="is-clickable" onClick={() => setEditing(row)}>
                <td>
                  <div className="ds-table__primary">{row.user_full_name || '—'}</div>
                  <div style={{ fontSize: 'var(--text-xs)', color: 'var(--fg-muted)' }}>{row.user_phone_number}</div>
                </td>
                <td>{row.chapter_name ? <Ds.Badge variant="brand">{row.chapter_name}</Ds.Badge> : <span style={{ color: 'var(--fg-muted)' }}>—</span>}</td>
                <td>
                  <div style={{ display: 'flex', alignItems: 'center', gap: 6 }}>
                    <IconShirt size={14} color="#94a3b8" />
                    {row.complement_type_name}
                  </div>
                </td>
                <td style={{ fontWeight: 700 }}>{row.variant || '—'}</td>
                <td><StatusPill status={row.fulfilment_status} /></td>
                <td className="ds-table__muted">{row.updated_at ? new Date(row.updated_at).toLocaleDateString() : '—'}</td>
                <td className="ds-table__actions" onClick={e => e.stopPropagation()}>
                  <button className="view-detail-btn" title="Update status" onClick={() => setEditing(row)}>
                    <IconMessage size={18} />
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
          pageLabel="records"
          onPageChange={setPage}
        />
      </Ds.Section>

      {editing && (
        <StatusUpdateDrawer
          record={editing}
          onClose={() => setEditing(null)}
          onUpdated={fetchData}
        />
      )}
    </section>
  );
}
