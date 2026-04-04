import React, { useState } from 'react';
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
  IconFileExport
} from '@tabler/icons-react';
import { api } from './lib/api';
import { useApi } from './hooks/useApi';

const MENU_GROUPS = [
  {
    label: 'Main Dashboard',
    links: [
      { id: 'overview', icon: IconChartBar, label: 'Analytics Hub' },
      { id: 'members', icon: IconUsers, label: 'Member Directory' },
    ]
  },
  {
    label: 'Asset Management',
    links: [
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

export default function App() {
  const [activeTab, setActiveTab] = useState('overview');
  const { data: overview, loading: overviewLoading, error: overviewError } = useApi(api.getAdminOverview);
  const { data: referrals, loading: referralsLoading } = useApi(api.listReferrals);

  if (overviewLoading) {
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

        <div className="sidebar-footer" style={{ marginTop: 'auto', padding: '1rem', background: 'rgba(255,255,255,0.03)', borderRadius: '16px', display: 'flex', alignItems: 'center', justifyContent: 'space-between' }}>
          <div style={{ display: 'flex', alignItems: 'center', gap: '0.75rem' }}>
             <IconUser size={18} stroke={1.5} color="rgba(255,255,255,0.5)" />
             <span style={{ fontSize: '0.8rem', fontWeight: 600, color: 'rgba(255,255,255,0.8)' }}>Support Hub</span>
          </div>
          <IconLogout size={18} stroke={1.5} color="rgba(255,255,255,0.3)" style={{ cursor: 'pointer' }} />
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
      </main>
    </div>
  );
}
