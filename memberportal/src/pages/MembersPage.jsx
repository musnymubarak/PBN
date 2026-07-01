import React, { useState, useEffect } from 'react';
import { IconSearch, IconChevronRight, IconCircleCheckFilled, IconUsers, IconBuildingCommunity, IconBriefcase, IconFilter } from '@tabler/icons-react';
import { useNavigate, useLocation } from 'react-router-dom';
import * as Ds from '../components/ui';
import api from '../lib/api';

export default function MembersPage() {
  const navigate = useNavigate();
  const location = useLocation();
  const [members, setMembers] = useState([]);
  const [myChapterIds, setMyChapterIds] = useState(new Set());
  const [loading, setLoading] = useState(true);
  const [search, setSearch] = useState(location.state?.search || '');
  
  // New Filter States
  const [scope, setScope] = useState('all'); // 'all' or 'my_chapter'
  const [selectedChapter, setSelectedChapter] = useState('all');
  const [selectedDistrict, setSelectedDistrict] = useState('all');

  useEffect(() => {
    const fetchMembersAndMyChapters = async () => {
      try {
        const [membersRes, membershipsRes] = await Promise.all([
          api.get('/chapters/members/all'),
          api.get('/chapters/my-memberships')
        ]);
        
        if (membersRes.data?.data) {
          setMembers(membersRes.data.data);
        }
        if (membershipsRes.data?.data) {
          const activeIds = new Set(
            membershipsRes.data.data
              .filter(m => m.is_active)
              .map(m => m.chapter.id)
          );
          setMyChapterIds(activeIds);
        }
      } catch (err) {
        console.error('Failed to fetch members or chapter memberships', err);
      } finally {
        setLoading(false);
      }
    };
    fetchMembersAndMyChapters();
  }, []);

  // Dynamically compute list of unique chapters and districts for select boxes
  const uniqueChaptersList = Array.from(
    new Set(
      members
        .map(m => m.chapter_name)
        .filter(Boolean)
    )
  ).sort();

  const uniqueDistrictsList = Array.from(
    new Set(
      members
        .map(m => m.district_name || m.district) // Fallback support
        .filter(Boolean)
    )
  ).sort();

  const searchLower = search.toLowerCase();
  const filteredMembers = members.filter(m => {
    // 1. Scope Filter (My Chapter)
    if (scope === 'my_chapter' && !myChapterIds.has(m.chapter_id)) {
      return false;
    }

    // 2. District Filter
    if (selectedDistrict !== 'all') {
      const dist = (m.district_name || m.district || '').toLowerCase();
      if (dist !== selectedDistrict.toLowerCase()) return false;
    }

    // 3. Chapter Filter
    if (selectedChapter !== 'all') {
      if ((m.chapter_name || '').toLowerCase() !== selectedChapter.toLowerCase()) return false;
    }

    // 4. Search Filter
    const name = m.full_name || '';
    const chapter = m.chapter_name || '';
    const business = m.business_name || '';
    
    return name.toLowerCase().includes(searchLower) || 
           chapter.toLowerCase().includes(searchLower) ||
           business.toLowerCase().includes(searchLower);
  });

  // Pagination state
  const [currentPage, setCurrentPage] = useState(1);
  const itemsPerPage = 12;

  // Reset pagination on filter/search change
  useEffect(() => {
    setCurrentPage(1);
  }, [search, scope, selectedChapter, selectedDistrict]);

  // Calculate quick stats
  const totalMembers = members.length;
  const verifiedMembers = members.filter(m => m.verification_level && m.verification_level !== 'none').length;
  const uniqueChapters = Array.from(new Set(members.map(m => m.chapter_name).filter(Boolean))).length;

  // Pagination calculations
  const totalItems = filteredMembers.length;
  const totalPages = Math.ceil(totalItems / itemsPerPage) || 1;
  const indexOfLastItem = currentPage * itemsPerPage;
  const indexOfFirstItem = indexOfLastItem - itemsPerPage;
  const currentMembers = filteredMembers.slice(indexOfFirstItem, indexOfLastItem);

  return (
    <div className="dashboard-body" style={{ position: 'relative' }}>
      
      {/* Title Header */}
      <div style={{ display: 'flex', justifyContent: 'space-between', alignItems: 'flex-start', marginBottom: '1.5rem' }}>
        <Ds.PageHeader
          title="Member Directory"
          description="Connect and build relationships with verified business leaders across all chapters."
        />
      </div>

      {/* Hero Banner Card */}
      <div className="event-hero-v3" style={{ marginBottom: '1.5rem' }}>
        <div style={{ display: 'flex', flexDirection: 'column', gap: '0.5rem', maxWidth: '80%' }}>
          <div style={{ display: 'flex', alignItems: 'center', gap: '8px' }}>
            <IconUsers size={20} style={{ color: 'var(--brand-amber)' }} />
            <span style={{ fontSize: '0.7rem', fontWeight: 900, color: 'var(--brand-amber)', letterSpacing: '0.15em' }}>GLOBAL DIRECTORY</span>
          </div>
          <h3 style={{ fontSize: '1.6rem', fontWeight: 900, color: 'white', letterSpacing: '-0.02em', margin: '4px 0 0 0' }}>
            PBN Trusted Connections
          </h3>
          <p style={{ color: 'rgba(255,255,255,0.85)', fontSize: '0.9rem', margin: '4px 0 0 0', fontWeight: 600 }}>
            Collaborate and partner with {totalMembers} business leaders across {uniqueChapters} chapters
          </p>
        </div>
      </div>

      {/* Stats Counter Row */}
      <div style={{
        display: 'grid',
        gridTemplateColumns: 'repeat(auto-fit, minmax(220px, 1fr))',
        gap: '1rem',
        marginBottom: '2rem'
      }}>
        <div style={{
          background: 'var(--bg-surface)',
          border: '1px solid var(--border-subtle)',
          borderRadius: '16px',
          padding: '1.25rem 1.5rem',
          display: 'flex',
          alignItems: 'center',
          gap: '1rem',
          boxShadow: '0 1px 3px rgba(0,0,0,0.05)'
        }}>
          <div style={{
            width: '40px',
            height: '40px',
            borderRadius: '12px',
            background: 'rgba(10,37,64,0.05)',
            display: 'flex',
            alignItems: 'center',
            justifyContent: 'center',
            color: 'var(--brand-navy)'
          }}>
            <IconUsers size={20} />
          </div>
          <div>
            <div style={{ fontSize: '1.5rem', fontWeight: 800, color: 'var(--fg-primary)', lineHeight: 1.1 }}>{totalMembers}</div>
            <div style={{ fontSize: '0.75rem', fontWeight: 600, color: 'var(--fg-muted)', textTransform: 'uppercase', marginTop: '4px' }}>Total Directory</div>
          </div>
        </div>

        <div style={{
          background: 'var(--bg-surface)',
          border: '1px solid var(--border-subtle)',
          borderRadius: '16px',
          padding: '1.25rem 1.5rem',
          display: 'flex',
          alignItems: 'center',
          gap: '1rem',
          boxShadow: '0 1px 3px rgba(0,0,0,0.05)'
        }}>
          <div style={{
            width: '40px',
            height: '40px',
            borderRadius: '12px',
            background: 'rgba(37,99,235,0.05)',
            display: 'flex',
            alignItems: 'center',
            justifyContent: 'center',
            color: '#2563EB'
          }}>
            <IconCircleCheckFilled size={20} />
          </div>
          <div>
            <div style={{ fontSize: '1.5rem', fontWeight: 800, color: 'var(--fg-primary)', lineHeight: 1.1 }}>{verifiedMembers}</div>
            <div style={{ fontSize: '0.75rem', fontWeight: 600, color: 'var(--fg-muted)', textTransform: 'uppercase', marginTop: '4px' }}>Verified Tiers</div>
          </div>
        </div>

        <div style={{
          background: 'var(--bg-surface)',
          border: '1px solid var(--border-subtle)',
          borderRadius: '16px',
          padding: '1.25rem 1.5rem',
          display: 'flex',
          alignItems: 'center',
          gap: '1rem',
          boxShadow: '0 1px 3px rgba(0,0,0,0.05)'
        }}>
          <div style={{
            width: '40px',
            height: '40px',
            borderRadius: '12px',
            background: 'rgba(217,119,6,0.05)',
            display: 'flex',
            alignItems: 'center',
            justifyContent: 'center',
            color: '#D97706'
          }}>
            <IconBuildingCommunity size={20} />
          </div>
          <div>
            <div style={{ fontSize: '1.5rem', fontWeight: 800, color: 'var(--fg-primary)', lineHeight: 1.1 }}>{uniqueChapters}</div>
            <div style={{ fontSize: '0.75rem', fontWeight: 600, color: 'var(--fg-muted)', textTransform: 'uppercase', marginTop: '4px' }}>Active Chapters</div>
          </div>
        </div>
      </div>

      {/* Chapter Scope Navigation Tabs */}
      <div style={{ display: 'flex', gap: '1rem', borderBottom: '1px solid var(--border-subtle)', marginBottom: '1.5rem', paddingBottom: '0.25rem' }}>
        <button
          onClick={() => { setScope('all'); setSelectedChapter('all'); }}
          style={{
            background: 'none',
            border: 'none',
            padding: '0.75rem 1rem',
            fontSize: 'var(--text-sm)',
            fontWeight: scope === 'all' ? 700 : 500,
            color: scope === 'all' ? 'var(--brand-primary)' : 'var(--fg-muted)',
            borderBottom: scope === 'all' ? '2px solid var(--brand-primary)' : '2px solid transparent',
            cursor: 'pointer',
            transition: 'all 0.2s ease',
            display: 'flex',
            alignItems: 'center',
            gap: '0.5rem'
          }}
        >
          <IconUsers size={16} />
          All Chapters
        </button>
        <button
          onClick={() => { setScope('my_chapter'); setSelectedChapter('all'); }}
          style={{
            background: 'none',
            border: 'none',
            padding: '0.75rem 1rem',
            fontSize: 'var(--text-sm)',
            fontWeight: scope === 'my_chapter' ? 700 : 500,
            color: scope === 'my_chapter' ? 'var(--brand-primary)' : 'var(--fg-muted)',
            borderBottom: scope === 'my_chapter' ? '2px solid var(--brand-primary)' : '2px solid transparent',
            cursor: 'pointer',
            transition: 'all 0.2s ease',
            display: 'flex',
            alignItems: 'center',
            gap: '0.5rem'
          }}
        >
          <IconBuildingCommunity size={16} />
          My Chapter
        </button>
      </div>

      {/* Filter Controls & Search Bar Container */}
      <div style={{
        background: 'var(--bg-surface)',
        border: '1px solid var(--border-subtle)',
        borderRadius: '16px',
        padding: '1.25rem',
        marginBottom: '1.5rem',
        display: 'flex',
        flexDirection: 'column',
        gap: '1rem',
        boxShadow: '0 1px 2px rgba(0,0,0,0.02)'
      }}>
        
        {/* Top Header and Match Counter Row */}
        <div style={{ display: 'flex', alignItems: 'center', justifyContent: 'space-between', flexWrap: 'wrap', gap: '0.5rem' }}>
          <div style={{ display: 'flex', alignItems: 'center', gap: '0.5rem' }}>
            <IconFilter size={16} style={{ color: 'var(--fg-muted)' }} />
            <span style={{ fontSize: '0.75rem', fontWeight: 700, color: 'var(--fg-muted)', textTransform: 'uppercase', letterSpacing: '0.05em' }}>
              Filter Directory
            </span>
          </div>
          <span style={{
            background: 'var(--bg-subtle)',
            color: 'var(--fg-secondary)',
            fontSize: '0.75rem',
            fontWeight: 700,
            padding: '3px 10px',
            borderRadius: '20px'
          }}>
            {filteredMembers.length} {filteredMembers.length === 1 ? 'member' : 'members'} found
          </span>
        </div>

        {/* Inputs and Selects Row */}
        <div style={{
          display: 'grid',
          gridTemplateColumns: 'repeat(auto-fit, minmax(200px, 1fr))',
          gap: '0.75rem'
        }}>
          {/* Text Search Input */}
          <Ds.Input
            type="text"
            value={search}
            onChange={e => setSearch(e.target.value)}
            placeholder="Search name or business..."
            leftIcon={<IconSearch size={16} />}
          />

          {/* District Selector */}
          <div style={{ position: 'relative' }}>
            <select
              value={selectedDistrict}
              onChange={e => setSelectedDistrict(e.target.value)}
              style={{
                width: '100%',
                padding: '0.625rem 1rem',
                fontSize: 'var(--text-sm)',
                borderRadius: 'var(--radius-md)',
                border: '1px solid var(--border-subtle)',
                background: 'var(--bg-surface)',
                color: 'var(--fg-primary)',
                outline: 'none',
                cursor: 'pointer'
              }}
            >
              <option value="all">All Districts</option>
              {uniqueDistrictsList.map(dist => (
                <option key={dist} value={dist}>{dist}</option>
              ))}
            </select>
          </div>

          {/* Chapter Selector (Only shows if scope is not limited to my_chapter) */}
          {scope !== 'my_chapter' && (
            <div style={{ position: 'relative' }}>
              <select
                value={selectedChapter}
                onChange={e => setSelectedChapter(e.target.value)}
                style={{
                  width: '100%',
                  padding: '0.625rem 1rem',
                  fontSize: 'var(--text-sm)',
                  borderRadius: 'var(--radius-md)',
                  border: '1px solid var(--border-subtle)',
                  background: 'var(--bg-surface)',
                  color: 'var(--fg-primary)',
                  outline: 'none',
                  cursor: 'pointer'
                }}
              >
                <option value="all">All Chapters</option>
                {uniqueChaptersList.map(ch => (
                  <option key={ch} value={ch}>{ch}</option>
                ))}
              </select>
            </div>
          )}
        </div>
      </div>

      {/* Main List Rendering */}
      {loading ? (
        <Ds.EmptyState
          icon={Ds.Spinner}
          title="Loading directory..."
          description="Fetching the latest member list."
        />
      ) : (
        <>
          <div style={{ display: 'flex', flexDirection: 'column', gap: '0.75rem' }}>
            {currentMembers.map(member => {
              const vLevel = member.verification_level && member.verification_level !== 'none' ? member.verification_level.toLowerCase() : 'none';
              const hasTier = vLevel !== 'none';
              const tierColor =
                vLevel === 'gold'     ? '#D97706' :
                vLevel === 'silver'   ? '#9CA3AF' :
                vLevel === 'platinum' ? '#E5E7EB' :
                                        '#2563EB';
              const tierLabel =
                vLevel === 'gold'     ? 'Gold Member' :
                vLevel === 'silver'   ? 'Silver Member' :
                vLevel === 'platinum' ? 'Platinum Member' :
                                        'Verified';

              return (
                <div 
                  key={member.user_id} 
                  onClick={() => navigate(`/members/${member.user_id}`)}
                  style={{ 
                    display: 'flex', 
                    alignItems: 'center', 
                    justifyContent: 'space-between',
                    padding: '1.25rem 1.5rem', 
                    background: 'var(--bg-surface)', 
                    border: '1px solid var(--border-subtle)',
                    borderRadius: '16px',
                    cursor: 'pointer',
                    transition: 'all 0.2s cubic-bezier(0.16, 1, 0.3, 1)',
                    boxShadow: '0 1px 2px rgba(0,0,0,0.02)'
                  }}
                  onMouseEnter={e => {
                    e.currentTarget.style.borderColor = 'var(--border-default)';
                    e.currentTarget.style.transform = 'translateY(-2px)';
                    e.currentTarget.style.boxShadow = '0 6px 20px rgba(10,37,64,0.05)';
                  }}
                  onMouseLeave={e => {
                    e.currentTarget.style.borderColor = 'var(--border-subtle)';
                    e.currentTarget.style.transform = 'none';
                    e.currentTarget.style.boxShadow = '0 1px 2px rgba(0,0,0,0.02)';
                  }}
                >
                  <div style={{ display: 'flex', alignItems: 'center', gap: '1.25rem', minWidth: 0, flex: 1 }}>
                    
                    {/* Positioned Avatar with Verification Overlays */}
                    <div style={{ position: 'relative', display: 'inline-flex', flexShrink: 0 }}>
                      <Ds.Avatar name={member.full_name} src={member.profile_photo} size="md" variant="brand" />
                      {hasTier && (
                        <span
                          title={tierLabel}
                          style={{
                            position: 'absolute',
                            bottom: '-2px',
                            right: '-2px',
                            width: '15px',
                            height: '15px',
                            borderRadius: '50%',
                            background: 'white',
                            display: 'flex',
                            alignItems: 'center',
                            justifyContent: 'center',
                            boxShadow: '0 0 0 1.5px white, 0 1px 3px rgba(0,0,0,0.15)',
                            lineHeight: 1,
                          }}
                        >
                          <IconCircleCheckFilled size={15} style={{ color: tierColor }} />
                        </span>
                      )}
                    </div>

                    {/* Text Details Section */}
                    <div style={{ minWidth: 0, flex: 1 }}>
                      <div style={{ fontWeight: 700, color: 'var(--fg-primary)', fontSize: '1.05rem', marginBottom: '0.375rem', display: 'flex', alignItems: 'center', gap: '0.625rem', flexWrap: 'wrap' }}>
                        {member.full_name}
                        {hasTier && (
                          <Ds.Badge 
                            variant="info" 
                            style={{ 
                              background: `color-mix(in srgb, ${tierColor} 12%, transparent)`,
                              color: tierColor,
                              borderColor: `color-mix(in srgb, ${tierColor} 20%, transparent)`,
                              display: 'inline-flex', 
                              alignItems: 'center', 
                              gap: '0.25rem', 
                              padding: '0.125rem 0.5rem', 
                              fontSize: '0.65rem', 
                              textTransform: 'uppercase',
                              fontWeight: 800,
                              letterSpacing: '0.05em'
                            }}
                          >
                            {vLevel}
                          </Ds.Badge>
                        )}
                      </div>

                      <div style={{ display: 'flex', alignItems: 'center', gap: '1.25rem', flexWrap: 'wrap' }}>
                        <div style={{ display: 'flex', alignItems: 'center', gap: '0.375rem', color: 'var(--fg-secondary)', fontSize: '0.825rem' }}>
                          <IconBuildingCommunity size={14} style={{ color: 'var(--fg-muted)' }} />
                          <span>{member.chapter_name || 'No Chapter'}</span>
                        </div>
                        
                        {(member.business_name || member.company) && (
                          <div style={{ display: 'flex', alignItems: 'center', gap: '0.375rem', color: 'var(--fg-secondary)', fontSize: '0.825rem' }}>
                            <IconBriefcase size={14} style={{ color: 'var(--fg-muted)' }} />
                            <span style={{ fontWeight: 500 }}>{member.business_name || member.company}</span>
                          </div>
                        )}
                      </div>
                    </div>
                  </div>
                  
                  {/* Arrow Right Indicator */}
                  <div style={{ color: 'var(--fg-muted)', display: 'flex', alignItems: 'center', paddingLeft: '1rem' }}>
                    <IconChevronRight size={20} />
                  </div>
                </div>
              );
            })}

            {filteredMembers.length === 0 && (
              <Ds.EmptyState title="No members found" description="Try a different search query." />
            )}
          </div>

          {/* Pagination Controls */}
          {totalPages > 1 && (
            <div style={{
              display: 'flex',
              justifyContent: 'center',
              alignItems: 'center',
              gap: '0.5rem',
              marginTop: '2rem'
            }}>
              <Ds.Button
                variant="outline"
                disabled={currentPage === 1}
                onClick={() => setCurrentPage(prev => Math.max(prev - 1, 1))}
              >
                Previous
              </Ds.Button>
              
              <span style={{
                fontSize: '0.875rem',
                fontWeight: 600,
                color: 'var(--fg-secondary)',
                margin: '0 1rem'
              }}>
                Page {currentPage} of {totalPages}
              </span>

              <Ds.Button
                variant="outline"
                disabled={currentPage === totalPages}
                onClick={() => setCurrentPage(prev => Math.min(prev + 1, totalPages))}
              >
                Next
              </Ds.Button>
            </div>
          )}
        </>
      )}
    </div>
  );
}
