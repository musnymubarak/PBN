import React, { useState, useEffect } from 'react';
import { useAuth } from '../context/AuthContext';
import { useNavigate } from 'react-router-dom';
import * as Ds from '../components/ui';
import api from '../lib/api';
import {
  IconArrowRight,
  IconBriefcase,
  IconMail,
  IconPhone,
  IconLock,
  IconLogout,
  IconDiscountCheckFilled,
  IconSettings
} from '@tabler/icons-react';

export default function MyProfilePage() {
  const { user, logout } = useAuth();
  const navigate = useNavigate();
  const [loading, setLoading] = useState(true);
  const [stats, setStats] = useState({ valueGenerated: 0, referralsGiven: 0, referralsReceived: 0 });

  useEffect(() => {
    // We would fetch actual stats here if the API provides it.
    // For now, we will simulate loading and set basic stats from user if available.
    setLoading(true);
    setTimeout(() => {
      setStats({
        valueGenerated: user?.cumulative_value_generated || 0,
        referralsGiven: 0,
        referralsReceived: 0
      });
      setLoading(false);
    }, 500);
  }, [user]);

  if (loading) {
    return (
      <div className="dashboard-body">
        <Ds.EmptyState icon={Ds.Spinner} title="Loading Profile..." />
      </div>
    );
  }

  const vLevel = user?.verification_level && user.verification_level !== 'none' ? user.verification_level : 'Member';
  const hasTier = vLevel !== 'Member';

  const sectionHeader = (title) => (
    <div style={{ display: 'flex', alignItems: 'center', gap: '0.5rem', marginBottom: '1rem' }}>
      <div style={{ width: '3px', height: '18px', background: 'linear-gradient(to bottom, #d4af37, #aa842c)', borderRadius: '2px' }} />
      <h2 style={{ fontSize: '1.1rem', fontWeight: 800, color: 'var(--fg-primary)', margin: 0, textTransform: 'uppercase' }}>
        {title}
      </h2>
    </div>
  );

  return (
    <div className="dashboard-body" style={{ position: 'relative', paddingBottom: '3rem' }}>
      <Ds.PageHeader title="My Profile" />

      {/* Hero Card */}
      <Ds.Card padded style={{ background: 'linear-gradient(135deg, #080D24, #162050)', color: 'white', border: 'none', marginBottom: '2rem', borderRadius: '1.5rem' }}>
        <div style={{ display: 'flex', gap: '1.5rem', alignItems: 'center' }}>
          <div style={{ 
            padding: '4px', 
            background: 'linear-gradient(135deg, #E8C97A, #C9A84C, #8A6A20)', 
            borderRadius: '50%',
            boxShadow: '0 4px 12px rgba(0,0,0,0.15)'
          }}>
            <Ds.Avatar name={user?.full_name} src={user?.profile_photo} size="lg" style={{ width: 80, height: 80, fontSize: '2rem', border: '2px solid #080D24', borderRadius: '50%' }} />
          </div>
          <div style={{ flex: 1 }}>
            <h1 style={{ fontSize: '1.5rem', fontWeight: 900, marginBottom: '0.5rem', color: 'white' }}>
              {user?.full_name}
            </h1>
            <div style={{ display: 'flex', gap: '0.5rem', flexWrap: 'wrap' }}>
              <span style={{ 
                background: 'rgba(255,255,255,0.15)', 
                border: '1px solid rgba(255,255,255,0.2)', 
                padding: '0.125rem 0.5rem', 
                borderRadius: '4px', 
                fontSize: '0.65rem', 
                fontWeight: 800, 
                textTransform: 'uppercase' 
              }}>
                {user?.role?.replace('_', ' ') || 'MEMBER'}
              </span>
              {hasTier && (
                <span style={{ 
                  background: 'rgba(13,148,136,0.2)', 
                  border: '1px solid rgba(13,148,136,0.5)', 
                  padding: '0.125rem 0.5rem', 
                  borderRadius: '4px', 
                  fontSize: '0.65rem', 
                  fontWeight: 800, 
                  textTransform: 'uppercase',
                  display: 'flex',
                  alignItems: 'center',
                  gap: '0.25rem',
                  color: '#2dd4bf'
                }}>
                  <IconDiscountCheckFilled size={12} />
                  {vLevel}
                </span>
              )}
            </div>
          </div>
          <div>
            <Ds.Button variant="secondary" style={{ background: 'rgba(255,255,255,0.1)', color: 'white', border: 'none' }} onClick={() => navigate('/portfolio')}>
              Edit Profile
            </Ds.Button>
          </div>
        </div>
      </Ds.Card>

      {/* Quick Stats */}
      <div style={{ display: 'grid', gridTemplateColumns: 'repeat(3, 1fr)', gap: '1rem', marginBottom: '2rem' }}>
        <Ds.Card padded style={{ textAlign: 'center' }}>
          <div style={{ fontSize: 'var(--text-xs)', color: 'var(--fg-secondary)', textTransform: 'uppercase', fontWeight: 700, marginBottom: '0.5rem' }}>Value Generated</div>
          <div style={{ fontSize: 'var(--text-xl)', fontWeight: 800, color: 'var(--brand-blue)' }}>LKR {stats.valueGenerated.toLocaleString()}</div>
        </Ds.Card>
        <Ds.Card padded style={{ textAlign: 'center' }}>
          <div style={{ fontSize: 'var(--text-xs)', color: 'var(--fg-secondary)', textTransform: 'uppercase', fontWeight: 700, marginBottom: '0.5rem' }}>Referrals Given</div>
          <div style={{ fontSize: 'var(--text-xl)', fontWeight: 800, color: 'var(--brand-blue)' }}>{stats.referralsGiven}</div>
        </Ds.Card>
        <Ds.Card padded style={{ textAlign: 'center' }}>
          <div style={{ fontSize: 'var(--text-xs)', color: 'var(--fg-secondary)', textTransform: 'uppercase', fontWeight: 700, marginBottom: '0.5rem' }}>Referrals Received</div>
          <div style={{ fontSize: 'var(--text-xl)', fontWeight: 800, color: 'var(--brand-blue)' }}>{stats.referralsReceived}</div>
        </Ds.Card>
      </div>

      {/* Two Column Layout for wider screens */}
      <div style={{ display: 'grid', gridTemplateColumns: 'repeat(auto-fit, minmax(400px, 1fr))', gap: '2rem', marginBottom: '2rem' }}>
        {/* Personal Info Column */}
        <div>
          {sectionHeader('Personal Information')}
          <Ds.Card style={{ height: 'calc(100% - 32px)' }}>
            <div style={{ display: 'flex', flexDirection: 'column' }}>
              <div style={{ display: 'flex', alignItems: 'center', justifyContent: 'space-between', padding: '1rem', borderBottom: '1px solid var(--border-color)' }}>
                <div style={{ display: 'flex', alignItems: 'center', gap: '1rem' }}>
                  <div style={{ width: 36, height: 36, borderRadius: '8px', background: 'var(--bg-subtle)', display: 'flex', alignItems: 'center', justifyContent: 'center', color: 'var(--brand-blue)' }}>
                    <IconMail size={18} />
                  </div>
                  <div>
                    <div style={{ fontSize: 'var(--text-sm)', fontWeight: 600, color: 'var(--fg-primary)' }}>Email Address</div>
                    <div style={{ fontSize: 'var(--text-sm)', color: 'var(--fg-secondary)' }}>{user?.email || 'Not provided'}</div>
                  </div>
                </div>
              </div>
              <div style={{ display: 'flex', alignItems: 'center', justifyContent: 'space-between', padding: '1rem' }}>
                <div style={{ display: 'flex', alignItems: 'center', gap: '1rem' }}>
                  <div style={{ width: 36, height: 36, borderRadius: '8px', background: 'var(--bg-subtle)', display: 'flex', alignItems: 'center', justifyContent: 'center', color: 'var(--brand-blue)' }}>
                    <IconPhone size={18} />
                  </div>
                  <div>
                    <div style={{ fontSize: 'var(--text-sm)', fontWeight: 600, color: 'var(--fg-primary)' }}>Phone Number</div>
                    <div style={{ fontSize: 'var(--text-sm)', color: 'var(--fg-secondary)' }}>{user?.phone_number || 'Not provided'}</div>
                  </div>
                </div>
              </div>
            </div>
          </Ds.Card>
        </div>

        {/* Account Column */}
        <div>
          {sectionHeader('Account')}
          <Ds.Card style={{ height: 'calc(100% - 32px)' }}>
            <div style={{ display: 'flex', flexDirection: 'column' }}>
              <button onClick={() => navigate('/portfolio')} style={{ display: 'flex', alignItems: 'center', justifyContent: 'space-between', padding: '1rem', borderBottom: '1px solid var(--border-color)', background: 'transparent', border: 'none', cursor: 'pointer', textAlign: 'left' }} className="ds-list-item-hover">
                <div style={{ display: 'flex', alignItems: 'center', gap: '1rem' }}>
                  <div style={{ width: 36, height: 36, borderRadius: '8px', background: 'var(--bg-subtle)', display: 'flex', alignItems: 'center', justifyContent: 'center', color: 'var(--fg-primary)' }}>
                    <IconBriefcase size={18} />
                  </div>
                  <div>
                    <div style={{ fontSize: 'var(--text-sm)', fontWeight: 600, color: 'var(--fg-primary)' }}>Business Portfolio</div>
                    <div style={{ fontSize: 'var(--text-xs)', color: 'var(--fg-secondary)' }}>Update your business details and profile</div>
                  </div>
                </div>
                <IconArrowRight size={16} color="var(--fg-muted)" />
              </button>
              
              <button onClick={() => navigate('/settings')} style={{ display: 'flex', alignItems: 'center', justifyContent: 'space-between', padding: '1rem', borderBottom: '1px solid var(--border-color)', background: 'transparent', border: 'none', cursor: 'pointer', textAlign: 'left' }} className="ds-list-item-hover">
                <div style={{ display: 'flex', alignItems: 'center', gap: '1rem' }}>
                  <div style={{ width: 36, height: 36, borderRadius: '8px', background: 'var(--bg-subtle)', display: 'flex', alignItems: 'center', justifyContent: 'center', color: 'var(--fg-primary)' }}>
                    <IconSettings size={18} />
                  </div>
                  <div>
                    <div style={{ fontSize: 'var(--text-sm)', fontWeight: 600, color: 'var(--fg-primary)' }}>Account Settings</div>
                    <div style={{ fontSize: 'var(--text-xs)', color: 'var(--fg-secondary)' }}>Update your app preferences and SMTP</div>
                  </div>
                </div>
                <IconArrowRight size={16} color="var(--fg-muted)" />
              </button>
              
              <button onClick={() => navigate('/change-password')} style={{ display: 'flex', alignItems: 'center', justifyContent: 'space-between', padding: '1rem', background: 'transparent', border: 'none', cursor: 'pointer', textAlign: 'left' }} className="ds-list-item-hover">
                <div style={{ display: 'flex', alignItems: 'center', gap: '1rem' }}>
                  <div style={{ width: 36, height: 36, borderRadius: '8px', background: 'var(--bg-subtle)', display: 'flex', alignItems: 'center', justifyContent: 'center', color: 'var(--fg-primary)' }}>
                    <IconLock size={18} />
                  </div>
                  <div>
                    <div style={{ fontSize: 'var(--text-sm)', fontWeight: 600, color: 'var(--fg-primary)' }}>Change Password</div>
                    <div style={{ fontSize: 'var(--text-xs)', color: 'var(--fg-secondary)' }}>Keep your account secure</div>
                  </div>
                </div>
                <IconArrowRight size={16} color="var(--fg-muted)" />
              </button>
            </div>
          </Ds.Card>
        </div>
      </div>

      <Ds.Button variant="ghost" className="btn-signout-hover" style={{ width: '100%', border: '1px solid var(--border-color)' }} onClick={logout} leftIcon={<IconLogout size={16} />}>
        Sign Out
      </Ds.Button>
    </div>
  );
}
