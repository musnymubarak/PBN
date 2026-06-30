import React, { useState, useEffect } from 'react';
import { IconSearch, IconChevronRight } from '@tabler/icons-react';
import { useNavigate } from 'react-router-dom';
import * as Ds from '../components/ui';
import api from '../lib/api';

export default function MembersPage() {
  const navigate = useNavigate();
  const [members, setMembers] = useState([]);
  const [loading, setLoading] = useState(true);
  const [search, setSearch] = useState('');

  useEffect(() => {
    const fetchMembers = async () => {
      try {
        const res = await api.get('/chapters/members/all');
        if (res.data?.data) {
          setMembers(res.data.data);
        }
      } catch (err) {
        console.error('Failed to fetch members', err);
      } finally {
        setLoading(false);
      }
    };
    fetchMembers();
  }, []);

  const searchLower = search.toLowerCase();
  const filteredMembers = members.filter(m => {
    const name = m.full_name || '';
    const chapter = m.chapter_name || '';
    const business = m.business_name || '';
    
    return name.toLowerCase().includes(searchLower) || 
           chapter.toLowerCase().includes(searchLower) ||
           business.toLowerCase().includes(searchLower);
  });

  return (
    <div className="dashboard-body">
      <Ds.PageHeader
        title="Member Directory"
        description="Connect with verified members across all chapters."
        actions={
          <Ds.Input
            type="text"
            value={search}
            onChange={e => setSearch(e.target.value)}
            placeholder="Search members..."
            leftIcon={<IconSearch size={16} />}
            style={{ width: 280 }}
          />
        }
      />

      {loading ? (
        <Ds.EmptyState
          icon={Ds.Spinner}
          title="Loading directory..."
          description="Fetching the latest member list."
        />
      ) : (
        <div style={{ display: 'flex', flexDirection: 'column', gap: '0.5rem' }}>
          {filteredMembers.map(member => {
            const vLevel = member.verification_level && member.verification_level !== 'none' ? member.verification_level : 'Member';
            return (
              <div 
                key={member.user_id} 
                onClick={() => navigate(`/members/${member.user_id}`)}
                style={{ 
                  display: 'flex', 
                  alignItems: 'center', 
                  justifyContent: 'space-between',
                  padding: '1rem 1.5rem', 
                  background: 'var(--bg-surface)', 
                  border: '1px solid var(--border-subtle)',
                  borderRadius: 'var(--radius-lg)',
                  cursor: 'pointer',
                  transition: 'all 0.2s ease'
                }}
                onMouseEnter={e => {
                  e.currentTarget.style.borderColor = 'var(--border-default)';
                  e.currentTarget.style.transform = 'translateX(4px)';
                }}
                onMouseLeave={e => {
                  e.currentTarget.style.borderColor = 'var(--border-subtle)';
                  e.currentTarget.style.transform = 'none';
                }}
              >
                <div style={{ display: 'flex', alignItems: 'center', gap: '1.25rem' }}>
                  <Ds.Avatar name={member.full_name} src={member.profile_photo} size="md" variant="brand" />
                  <div>
                    <div style={{ fontWeight: 600, color: 'var(--fg-primary)', marginBottom: '0.25rem', display: 'flex', alignItems: 'center', gap: '0.5rem' }}>
                      {member.full_name}
                      {vLevel !== 'Member' && (
                        <Ds.Badge variant={vLevel === 'Gold' ? 'warning' : 'info'} style={{ display: 'flex', alignItems: 'center', gap: '0.25rem', padding: '0.125rem 0.5rem', fontSize: '0.65rem', textTransform: 'uppercase' }}>
                          <svg xmlns="http://www.w3.org/2000/svg" width="12" height="12" viewBox="0 0 24 24" fill="currentColor" stroke="none"><path d="M12.01 2.011a3.2 3.2 0 0 1 2.113 .797l.154 .145l.698 .698a1.2 1.2 0 0 0 .71 .341l.135 .008h1a3.2 3.2 0 0 1 3.195 3.018l.005 .182v1c0 .27 .092 .533 .258 .743l.09 .1l.697 .698a3.2 3.2 0 0 1 .147 4.382l-.145 .154l-.698 .698a1.2 1.2 0 0 0 -.341 .71l-.008 .135v1a3.2 3.2 0 0 1 -3.018 3.195l-.182 .005h-1a1.2 1.2 0 0 0 -.71 .341l-.135 .008l-.698 .698a3.2 3.2 0 0 1 -4.382 .147l-.154 -.145l-.698 -.698a1.2 1.2 0 0 0 -.71 -.341l-.135 -.008h-1a3.2 3.2 0 0 1 -3.195 -3.018l-.005 -.182v-1a1.2 1.2 0 0 0 -.341 -.71l-.008 -.135l-.698 -.698a3.2 3.2 0 0 1 -.147 -4.382l.145 -.154l.698 -.698a1.2 1.2 0 0 0 .341 -.71l.008 -.135v-1a3.2 3.2 0 0 1 3.018 -3.195l.182 -.005h1a1.2 1.2 0 0 0 .71 -.341l.135 -.008l.698 -.698a3.2 3.2 0 0 1 2.269 -.944zm3.697 7.282a1 1 0 0 0 -1.414 0l-3.293 3.292l-1.293 -1.292l-.094 -.083a1 1 0 0 0 -1.32 1.497l2 2l.094 .083a1 1 0 0 0 1.32 -.083l4 -4l.083 -.094a1 1 0 0 0 -.083 -1.32z" /></svg>
                          {vLevel}
                        </Ds.Badge>
                      )}
                    </div>
                    <div style={{ display: 'flex', alignItems: 'center', gap: '0.75rem' }}>
                      <span style={{ fontSize: 'var(--text-sm)', color: 'var(--fg-secondary)' }}>
                        {member.chapter_name || 'No Chapter'}
                      </span>
                    </div>
                  </div>
                </div>
                
                <div style={{ color: 'var(--fg-muted)' }}>
                  <IconChevronRight size={20} />
                </div>
              </div>
            );
          })}
          {filteredMembers.length === 0 && (
            <Ds.EmptyState title="No members found" description="Try a different search term." />
          )}
        </div>
      )}
    </div>
  );
}
