import React, { useState, useEffect } from 'react';
import { useNavigate } from 'react-router-dom';
import { 
  IconSearch, 
  IconChevronRight, 
  IconMapPin, 
  IconBuildingCommunity, 
  IconCalendarEvent, 
  IconWorld, 
  IconUsers, 
  IconCircleCheck, 
  IconX,
  IconBuilding
} from '@tabler/icons-react';
import * as Ds from '../components/ui';
import api from '../lib/api';

export default function ChaptersPage() {
  const navigate = useNavigate();
  const [chapters, setChapters] = useState([]);
  const [memberships, setMemberships] = useState([]);
  const [loading, setLoading] = useState(true);
  const [search, setSearch] = useState('');
  const [selectedDistrict, setSelectedDistrict] = useState(null);
  const [selectedChapter, setSelectedChapter] = useState(null);

  useEffect(() => {
    const fetchChaptersAndMemberships = async () => {
      try {
        const [chaptersRes, membershipsRes] = await Promise.all([
          api.get('/chapters'),
          api.get('/chapters/my-memberships')
        ]);
        
        if (chaptersRes.data?.data) {
          setChapters(chaptersRes.data.data);
        }
        if (membershipsRes.data?.data) {
          setMemberships(membershipsRes.data.data);
        }
      } catch (err) {
        console.error('Failed to load chapters and memberships', err);
      } finally {
        setLoading(false);
      }
    };
    fetchChaptersAndMemberships();
  }, []);

  // Stats calculation
  const totalChapters = chapters.length;
  const representedDistricts = Array.from(new Set(chapters.map(c => c.district)));
  const activeChaptersCount = chapters.filter(c => c.is_active).length;

  // Identify home chapter
  const activeMemberships = memberships.filter(m => m.is_active);
  const homeChapterId = activeMemberships.length > 0 ? activeMemberships[0].chapter.id : null;
  const homeChapter = chapters.find(c => c.id === homeChapterId);

  // Filtering
  const filteredChapters = chapters.filter(c => {
    const matchesDistrict = !selectedDistrict || c.district === selectedDistrict;
    const matchesSearch = !search || c.name.toLowerCase().includes(search.toLowerCase());
    return matchesDistrict && matchesSearch;
  });

  // Exclude home chapter from explore list
  const exploreChapters = filteredChapters.filter(c => c.id !== homeChapterId);

  const handleViewMembers = (chapterName) => {
    navigate('/members', { state: { search: chapterName } });
  };

  if (loading) {
    return (
      <div className="dashboard-body">
        <Ds.PageHeader
          title="Chapters"
          description="Explore PBN chapters across different regions."
        />
        <Ds.EmptyState
          icon={Ds.Spinner}
          title="Loading chapters..."
          description="Fetching the latest directory from the PBN network."
        />
      </div>
    );
  }

  return (
    <div className="dashboard-body" style={{ position: 'relative' }}>
      <Ds.PageHeader
        title="Global Presence"
        description="Explore PBN chapters across different regions."
        actions={
          <Ds.Input
            type="text"
            value={search}
            onChange={e => setSearch(e.target.value)}
            placeholder="Search by chapter name..."
            leftIcon={<IconSearch size={16} />}
            style={{ width: 280 }}
          />
        }
      />

      {/* Network Overview Stats */}
      <div className="chapter-stats-v3">
        <div className="chapter-stat-item-v3">
          <div className="chapter-stat-num-v3">{totalChapters}</div>
          <div className="chapter-stat-label-v3">Chapters</div>
        </div>
        <div className="chapter-stat-divider-v3" />
        <div className="chapter-stat-item-v3">
          <div className="chapter-stat-num-v3">{representedDistricts.length}</div>
          <div className="chapter-stat-label-v3">Districts</div>
        </div>
        <div className="chapter-stat-divider-v3" />
        <div className="chapter-stat-item-v3">
          <div className="chapter-stat-num-v3">{activeChaptersCount}</div>
          <div className="chapter-stat-label-v3">Active</div>
        </div>
      </div>

      {/* Your Home Chapter */}
      {homeChapter && (
        <div style={{ marginBottom: '2.5rem' }}>
          <h3 style={{ fontSize: '1.1rem', fontWeight: 800, color: 'var(--fg-primary)', marginBottom: '0.875rem', display: 'flex', alignItems: 'center', gap: '0.5rem' }}>
            <span style={{ width: '4px', height: '16px', background: 'var(--brand-amber)', borderRadius: '2px', display: 'inline-block' }}></span>
            Your Home Chapter
            <span style={{ fontSize: '0.65rem', padding: '2px 8px', background: 'var(--brand-amber)', color: 'white', borderRadius: '4px', marginLeft: '6px', fontWeight: 900 }}>YOU</span>
          </h3>

          <div className="chapter-card-home-v3" onClick={() => setSelectedChapter(homeChapter)} style={{ cursor: 'pointer' }}>
            <div style={{ display: 'flex', alignItems: 'flex-start', justifyContent: 'space-between', flexWrap: 'wrap', gap: '1rem' }}>
              <div style={{ display: 'flex', alignItems: 'center', gap: '1.25rem' }}>
                <div style={{ 
                  background: 'rgba(255,255,255,0.1)', 
                  border: '1px solid rgba(255,255,255,0.2)', 
                  borderRadius: '12px',
                  padding: '10px',
                  display: 'flex',
                  alignItems: 'center',
                  justifyContent: 'center'
                }}>
                  <IconBuildingCommunity size={28} style={{ color: 'var(--brand-amber)' }} />
                </div>
                <div>
                  <h4 style={{ fontSize: '1.35rem', fontWeight: 800, margin: 0, color: 'white', letterSpacing: '-0.02em' }}>
                    {homeChapter.name}
                  </h4>
                  <div style={{ display: 'flex', alignItems: 'center', gap: '4px', marginTop: '6px', color: 'var(--brand-amber)', fontSize: '0.85rem', fontWeight: 800 }}>
                    <IconMapPin size={14} />
                    {homeChapter.district}
                  </div>
                </div>
              </div>

              <button 
                onClick={(e) => {
                  e.stopPropagation();
                  handleViewMembers(homeChapter.name);
                }}
                style={{
                  background: 'var(--brand-amber)',
                  color: 'white',
                  border: 'none',
                  borderRadius: '10px',
                  padding: '0.75rem 1.25rem',
                  fontSize: '0.875rem',
                  fontWeight: 800,
                  cursor: 'pointer',
                  display: 'flex',
                  alignItems: 'center',
                  gap: '6px',
                  boxShadow: '0 4px 10px rgba(198, 165, 76, 0.2)'
                }}
              >
                <IconUsers size={16} />
                View Members
              </button>
            </div>

            {homeChapter.description && (
              <p style={{ color: 'rgba(255,255,255,0.8)', fontSize: '0.9rem', lineHeight: 1.5, margin: '1.25rem 0 0 0' }}>
                {homeChapter.description}
              </p>
            )}

            <div style={{ display: 'flex', gap: '0.75rem', flexWrap: 'wrap', marginTop: '1.25rem' }}>
              {homeChapter.meeting_schedule && (
                <div style={{ background: 'rgba(255,255,255,0.1)', color: 'white', border: '1px solid rgba(255,255,255,0.15)', borderRadius: '6px', padding: '4px 10px', fontSize: '0.75rem', fontWeight: 800, display: 'flex', alignItems: 'center', gap: '4px' }}>
                  <IconCalendarEvent size={12} />
                  {homeChapter.meeting_schedule.toUpperCase()}
                </div>
              )}
              <div style={{ background: 'rgba(52, 211, 153, 0.2)', color: '#34d399', border: '1px solid rgba(52, 211, 153, 0.3)', borderRadius: '6px', padding: '4px 10px', fontSize: '0.75rem', fontWeight: 800, display: 'flex', alignItems: 'center', gap: '4px' }}>
                ACTIVE
              </div>
            </div>
          </div>
        </div>
      )}

      {/* Explore Grid & District Chips */}
      <div>
        <h3 style={{ fontSize: '1.1rem', fontWeight: 800, color: 'var(--fg-primary)', marginBottom: '0.875rem', display: 'flex', alignItems: 'center', gap: '0.5rem' }}>
          <span style={{ width: '4px', height: '16px', background: 'var(--brand-blue)', borderRadius: '2px', display: 'inline-block' }}></span>
          {homeChapter ? 'Explore the Network' : 'Discover Chapters'}
          {chapters.length > 0 && (
            <span style={{ fontSize: '0.65rem', padding: '2px 8px', background: 'var(--brand-blue-50)', color: 'var(--brand-blue)', border: '1px solid var(--brand-blue-100)', borderRadius: '4px', marginLeft: '6px', fontWeight: 900 }}>
              {exploreChapters.length} CHAPTERS
            </span>
          )}
        </h3>

        {/* District Filter Chips */}
        <div className="district-chips-v3">
          <button 
            className={`district-chip-v3 ${!selectedDistrict ? 'is-active' : ''}`}
            onClick={() => setSelectedDistrict(null)}
          >
            All <span className="chip-count-v3">{chapters.length}</span>
          </button>
          {representedDistricts.map(district => {
            const count = chapters.filter(c => c.district === district).length;
            return (
              <button 
                key={district}
                className={`district-chip-v3 ${selectedDistrict === district ? 'is-active' : ''}`}
                onClick={() => setSelectedDistrict(district)}
              >
                {district} <span className="chip-count-v3">{count}</span>
              </button>
            );
          })}
        </div>

        {/* Explore Chapters List Grid */}
        {exploreChapters.length > 0 ? (
          <div className="chapters-grid-v3">
            {exploreChapters.map(chapter => (
              <div 
                key={chapter.id} 
                className="chapter-card-v3"
                onClick={() => setSelectedChapter(chapter)}
              >
                <div>
                  <div style={{ display: 'flex', alignItems: 'flex-start', gap: '1rem', justifyContent: 'space-between' }}>
                    <div style={{ 
                      background: 'var(--brand-blue-50)', 
                      borderRadius: '10px',
                      padding: '8px',
                      display: 'flex',
                      alignItems: 'center',
                      justifyContent: 'center',
                      border: '1px solid var(--brand-blue-100)'
                    }}>
                      <IconBuildingCommunity size={20} style={{ color: 'var(--brand-blue)' }} />
                    </div>

                    {!chapter.is_active && (
                      <span style={{ fontSize: '0.65rem', padding: '2px 6px', background: 'var(--neutral-100)', color: 'var(--fg-muted)', borderRadius: '4px', fontWeight: 900 }}>
                        INACTIVE
                      </span>
                    )}
                  </div>

                  <h4 style={{ fontSize: '1.05rem', fontWeight: 800, color: 'var(--fg-primary)', margin: '0.75rem 0 0.25rem 0', letterSpacing: '-0.01em' }}>
                    {chapter.name}
                  </h4>

                  <div style={{ display: 'flex', alignItems: 'center', gap: '4px', color: 'var(--brand-blue)', fontSize: '0.8rem', fontWeight: 800, marginBottom: '0.75rem' }}>
                    <IconMapPin size={12} />
                    {chapter.district}
                  </div>

                  {chapter.description && (
                    <p style={{ color: 'var(--fg-secondary)', fontSize: '0.825rem', lineHeight: 1.4, margin: '0 0 1rem 0' }}>
                      {chapter.description.length > 100 ? `${chapter.description.substring(0, 100)}...` : chapter.description}
                    </p>
                  )}
                </div>

                <div style={{ display: 'flex', alignItems: 'center', justifyContent: 'space-between', marginTop: 'auto' }}>
                  {chapter.meeting_schedule ? (
                    <div style={{ background: 'var(--brand-blue-50)', color: 'var(--brand-blue)', borderRadius: '6px', padding: '3px 8px', fontSize: '0.7rem', fontWeight: 800, display: 'flex', alignItems: 'center', gap: '3px' }}>
                      <IconCalendarEvent size={10} />
                      {chapter.meeting_schedule.toUpperCase()}
                    </div>
                  ) : (
                    <div></div>
                  )}

                  <button 
                    onClick={(e) => {
                      e.stopPropagation();
                      handleViewMembers(chapter.name);
                    }}
                    style={{
                      background: 'none',
                      border: 'none',
                      color: 'var(--fg-muted)',
                      cursor: 'pointer',
                      display: 'flex',
                      alignItems: 'center',
                      padding: '4px'
                    }}
                  >
                    <IconChevronRight size={18} />
                  </button>
                </div>
              </div>
            ))}
          </div>
        ) : (
          <div style={{ marginTop: '1rem' }}>
            <Ds.EmptyState 
              icon={IconBuilding}
              title={search ? 'No matching chapters' : 'No chapters in this district'}
              description={search ? 'Try a different search keyword.' : 'Try selecting another district to see more chapters.'}
            />
          </div>
        )}
      </div>

      {/* Facts & Detail Modal */}
      {selectedChapter && (
        <div style={{
          position: 'fixed',
          inset: 0,
          background: 'rgba(10, 37, 64, 0.4)',
          backdropFilter: 'blur(4px)',
          display: 'flex',
          alignItems: 'center',
          justifyContent: 'center',
          zIndex: 1000
        }} onClick={() => setSelectedChapter(null)}>
          <div style={{
            background: 'var(--bg-surface)',
            borderRadius: 'var(--radius-xl)',
            border: '1px solid var(--border-subtle)',
            width: '100%',
            maxWidth: '520px',
            padding: '2rem',
            position: 'relative',
            boxShadow: 'var(--elev-4)'
          }} onClick={e => e.stopPropagation()}>
            
            {/* Close Button */}
            <button 
              onClick={() => setSelectedChapter(null)}
              style={{
                position: 'absolute',
                top: '1.5rem',
                right: '1.5rem',
                background: 'none',
                border: 'none',
                color: 'var(--fg-muted)',
                cursor: 'pointer',
                padding: '4px'
              }}
            >
              <IconX size={20} />
            </button>

            {/* Header Details */}
            <div style={{ 
              background: 'linear-gradient(135deg, #0A2540 0%, #102E55 100%)', 
              borderRadius: '16px',
              padding: '1.25rem',
              color: 'white',
              display: 'flex',
              alignItems: 'center',
              gap: '1rem',
              marginBottom: '1.5rem',
              boxShadow: '0 4px 12px rgba(10, 37, 64, 0.15)'
            }}>
              <div style={{ 
                background: 'rgba(255,255,255,0.1)', 
                border: '1px solid rgba(255,255,255,0.2)', 
                borderRadius: '10px',
                padding: '8px',
                display: 'flex',
                alignItems: 'center',
                justifyContent: 'center'
              }}>
                <IconBuildingCommunity size={24} style={{ color: 'var(--brand-amber)' }} />
              </div>
              <div>
                <h4 style={{ fontSize: '1.15rem', fontWeight: 800, margin: 0, color: 'white', letterSpacing: '-0.02em' }}>
                  {selectedChapter.name}
                </h4>
                <div style={{ display: 'flex', alignItems: 'center', gap: '4px', marginTop: '4px', color: 'var(--brand-amber)', fontSize: '0.8rem', fontWeight: 800 }}>
                  <IconMapPin size={12} />
                  {selectedChapter.district}
                </div>
              </div>
            </div>

            {/* Description */}
            {selectedChapter.description && (
              <div style={{ marginBottom: '1.5rem' }}>
                <div style={{ fontSize: '0.65rem', fontWeight: 900, color: 'var(--fg-muted)', letterSpacing: '0.1em', textTransform: 'uppercase', marginBottom: '0.5rem' }}>About</div>
                <p style={{ color: 'var(--fg-secondary)', fontSize: '0.875rem', lineHeight: 1.5, margin: 0 }}>
                  {selectedChapter.description}
                </p>
              </div>
            )}

            {/* Facts Grid */}
            <div style={{ marginBottom: '2rem' }}>
              <div style={{ fontSize: '0.65rem', fontWeight: 900, color: 'var(--fg-muted)', letterSpacing: '0.1em', textTransform: 'uppercase', marginBottom: '0.75rem' }}>Quick Facts</div>
              
              <div style={{ display: 'flex', flexDirection: 'column', gap: '0.75rem' }}>
                {selectedChapter.meeting_schedule && (
                  <div style={{ display: 'flex', alignItems: 'center', justifyContent: 'space-between', padding: '0.75rem 1rem', background: 'var(--bg-canvas)', borderRadius: '10px', border: '1px solid var(--border-subtle)' }}>
                    <div style={{ display: 'flex', alignItems: 'center', gap: '10px', color: 'var(--fg-secondary)', fontSize: '0.85rem', fontWeight: 600 }}>
                      <IconCalendarEvent size={16} style={{ color: 'var(--brand-blue)' }} />
                      Meeting Schedule
                    </div>
                    <span style={{ fontSize: '0.875rem', fontWeight: 800, color: 'var(--fg-primary)' }}>
                      {selectedChapter.meeting_schedule}
                    </span>
                  </div>
                )}

                <div style={{ display: 'flex', alignItems: 'center', justifyContent: 'space-between', padding: '0.75rem 1rem', background: 'var(--bg-canvas)', borderRadius: '10px', border: '1px solid var(--border-subtle)' }}>
                  <div style={{ display: 'flex', alignItems: 'center', gap: '10px', color: 'var(--fg-secondary)', fontSize: '0.85rem', fontWeight: 600 }}>
                    <IconMapPin size={16} style={{ color: 'var(--brand-amber)' }} />
                    District
                  </div>
                  <span style={{ fontSize: '0.875rem', fontWeight: 800, color: 'var(--fg-primary)' }}>
                    {selectedChapter.district}
                  </span>
                </div>

                <div style={{ display: 'flex', alignItems: 'center', justifyContent: 'space-between', padding: '0.75rem 1rem', background: 'var(--bg-canvas)', borderRadius: '10px', border: '1px solid var(--border-subtle)' }}>
                  <div style={{ display: 'flex', alignItems: 'center', gap: '10px', color: 'var(--fg-secondary)', fontSize: '0.85rem', fontWeight: 600 }}>
                    <IconCircleCheck size={16} style={{ color: selectedChapter.is_active ? '#34d399' : 'var(--fg-muted)' }} />
                    Status
                  </div>
                  <span style={{ fontSize: '0.875rem', fontWeight: 800, color: selectedChapter.is_active ? '#34d399' : 'var(--fg-muted)' }}>
                    {selectedChapter.is_active ? 'Active' : 'Inactive'}
                  </span>
                </div>
              </div>
            </div>

            {/* CTA action buttons */}
            <div style={{ display: 'flex', gap: '0.75rem', justifyContent: 'flex-end' }}>
              <button 
                onClick={() => setSelectedChapter(null)}
                style={{
                  background: 'none',
                  border: '1px solid var(--border-default)',
                  borderRadius: '10px',
                  padding: '0.75rem 1.25rem',
                  fontSize: '0.875rem',
                  fontWeight: 700,
                  color: 'var(--fg-primary)',
                  cursor: 'pointer'
                }}
              >
                Close
              </button>
              <button 
                onClick={() => {
                  setSelectedChapter(null);
                  handleViewMembers(selectedChapter.name);
                }}
                style={{
                  background: 'var(--brand-blue)',
                  color: 'white',
                  border: 'none',
                  borderRadius: '10px',
                  padding: '0.75rem 1.25rem',
                  fontSize: '0.875rem',
                  fontWeight: 800,
                  cursor: 'pointer',
                  display: 'flex',
                  alignItems: 'center',
                  gap: '6px',
                  boxShadow: '0 4px 10px rgba(37, 99, 235, 0.2)'
                }}
              >
                <IconUsers size={16} />
                View Members
              </button>
            </div>

          </div>
        </div>
      )}

    </div>
  );
}
