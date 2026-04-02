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

export default function App() {
  const [activeTab, setActiveTab] = useState('overview');

  const referrals = [
    { id: 'REF-7821', from: 'John Silva', to: 'Aashiq Amin', value: 'LKR 450,000', status: 'Completed', date: '2 hours ago' },
    { id: 'REF-7822', from: 'Bhathiya W.', to: 'Chatura Fernando', value: 'LKR 125,000', status: 'Pending', date: '5 hours ago' },
    { id: 'REF-7823', from: 'Janaka P.', to: 'Damika Perera', value: 'LKR 950,000', status: 'Completed', date: 'Yesterday' },
    { id: 'REF-7824', from: 'Hirunika S.', to: 'Erandi K.', value: 'LKR 80,000', status: 'Pending', date: 'Oct 23, 2023' },
    { id: 'REF-7825', from: 'Mahesh S.', to: 'Farhan M.', value: 'LKR 2,500,000', status: 'Completed', date: 'Oct 22, 2023' },
  ];

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

          <div className="stat-grid">
            <StatCard title="TOTAL REVENUE (ROI)" value="LKR 12.8M" icon={IconCoin} trend={12.4} color="#059669" />
            <StatCard title="ACTIVE MEMBER BASE" value="2,481" icon={IconUsers} trend={5.2} color="#2563eb" />
            <StatCard title="REFERRAL VELOCITY" value="82.1%" icon={IconHierarchy2} color="#f59e0b" />
            <StatCard title="AVG. LEAD VALUE" value="LKR 51.6K" icon={IconClock} color="#7c3aed" />
          </div>

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
                {referrals.map(ref => (
                  <tr key={ref.id}>
                    <td><span className="id-badge">{ref.id}</span></td>
                    <td style={{ fontWeight: 600 }}>{ref.from}</td>
                    <td>{ref.to}</td>
                    <td style={{ fontWeight: 700 }}>{ref.value}</td>
                    <td>
                      <span className={`pill ${ref.status === 'Completed' ? 'pill-completed' : 'pill-pending'}`}>
                        {ref.status}
                      </span>
                    </td>
                    <td>{ref.date}</td>
                    <td><IconDotsVertical size={20} color="#94a3b8" style={{ cursor: 'pointer' }} /></td>
                  </tr>
                ))}
              </tbody>
            </table>
            
            <div style={{ padding: '1.5rem 2.5rem', background: '#f8fafc', display: 'flex', justifyContent: 'space-between', alignItems: 'center' }}>
               <p style={{ fontSize: '0.8125rem', color: 'var(--text-secondary)', fontWeight: 600 }}>Showing 5 entries out of 124 available records</p>
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
