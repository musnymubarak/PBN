import React, { useState, useEffect } from 'react';
import * as Ds from '../components/ui';
import { 
  IconMessageCircle, 
  IconStar, 
  IconUserCheck, 
  IconSearch, 
  IconPlus, 
  IconX, 
  IconChevronRight, 
  IconAlertTriangle, 
  IconUsers,
  IconApps,
  IconHeart,
  IconHeartFilled,
  IconPin,
  IconTrash,
  IconClock,
  IconCoin,
  IconVolume
} from '@tabler/icons-react';
import api from '../lib/api';
import { useAuth } from '../context/AuthContext';
import CreatePostModal from '../components/community/CreatePostModal';

export default function CommunityPage() {
  const { user } = useAuth();
  const [selectedTab, setSelectedTab] = useState('chapter'); // 'chapter' or 'network'
  const [posts, setPosts] = useState([]);
  const [loading, setLoading] = useState(true);
  const [loadError, setLoadError] = useState(false);

  const [activeFilter, setActiveFilter] = useState('all'); // 'all', 'pinned', 'my_posts', 'opportunities'
  const [searchQuery, setSearchQuery] = useState('');
  
  const [isCreateOpen, setIsCreateOpen] = useState(false);

  // Comments state
  const [expandedPostId, setExpandedPostId] = useState(null);
  const [commentsMap, setCommentsMap] = useState({}); // postId -> array of comments
  const [loadingCommentsPostId, setLoadingCommentsPostId] = useState(null);
  const [newCommentText, setNewCommentText] = useState('');

  // Status / ROI updates state
  const [updatingPostId, setUpdatingPostId] = useState(null);
  const [roiFormPostId, setRoiFormPostId] = useState(null);
  const [roiValue, setRoiValue] = useState('');

  const loadData = async () => {
    setLoading(true);
    setLoadError(false);
    try {
      const isNetworkWide = selectedTab === 'network';
      // filter keys match backend service: "all", "pinned", "my_posts", "leads"
      let filterParam = activeFilter;
      if (activeFilter === 'opportunities') filterParam = 'leads'; // backend maps opportunities to 'leads' filter

      const params = {
        network_wide: isNetworkWide,
        filter: filterParam,
        limit: 30
      };
      if (searchQuery.trim()) {
        params.search = searchQuery.trim();
      }

      const res = await api.get('/community/posts', { params });
      setPosts(res.data?.data || res.data || []);
    } catch (err) {
      console.error('Failed to load community feed', err);
      setLoadError(true);
    } finally {
      setLoading(false);
    }
  };

  useEffect(() => {
    loadData();
  }, [selectedTab, activeFilter, searchQuery]);

  const handleLike = async (postId) => {
    try {
      const res = await api.post(`/community/posts/${postId}/like`);
      const { likes_count, is_liked } = res.data?.data || res.data;
      
      setPosts(prev => prev.map(p => {
        if (p.id === postId) {
          return { ...p, likes_count, is_liked_by_me: is_liked };
        }
        return p;
      }));
    } catch (err) {
      console.error('Failed to toggle like', err);
    }
  };

  const handlePin = async (postId) => {
    try {
      const res = await api.post(`/community/posts/${postId}/pin`);
      const { is_pinned } = res.data?.data || res.data || {};
      
      setPosts(prev => prev.map(p => {
        if (p.id === postId) {
          return { ...p, is_pinned };
        }
        return p;
      }));
    } catch (err) {
      console.error('Failed to toggle pin', err);
    }
  };

  const handleDeletePost = async (postId) => {
    if (!window.confirm('Are you sure you want to delete this post permanently?')) return;
    try {
      await api.delete(`/community/posts/${postId}`);
      setPosts(prev => prev.filter(p => p.id !== postId));
    } catch (err) {
      alert('Failed to delete post.');
    }
  };

  const toggleComments = async (postId) => {
    if (expandedPostId === postId) {
      setExpandedPostId(null);
      return;
    }

    setExpandedPostId(postId);
    setLoadingCommentsPostId(postId);
    try {
      const res = await api.get(`/community/posts/${postId}/comments`);
      setCommentsMap(prev => ({
        ...prev,
        [postId]: res.data?.data || res.data || []
      }));
    } catch (err) {
      console.error('Failed to load comments', err);
    } finally {
      setLoadingCommentsPostId(null);
    }
  };

  const handleAddComment = async (e, postId) => {
    e.preventDefault();
    if (!newCommentText.trim()) return;

    try {
      const res = await api.post(`/community/posts/${postId}/comments`, {
        content: newCommentText.trim()
      });
      const newComment = res.data?.data || res.data;
      
      setCommentsMap(prev => ({
        ...prev,
        [postId]: [...(prev[postId] || []), newComment]
      }));
      
      setPosts(prev => prev.map(p => {
        if (p.id === postId) {
          return { ...p, comments_count: (p.comments_count || 0) + 1 };
        }
        return p;
      }));
      setNewCommentText('');
    } catch (err) {
      alert('Failed to submit comment.');
    }
  };

  const handleDeleteComment = async (postId, commentId) => {
    if (!window.confirm('Delete this comment?')) return;
    try {
      await api.delete(`/community/comments/${commentId}`);
      setCommentsMap(prev => ({
        ...prev,
        [postId]: prev[postId].filter(c => c.id !== commentId)
      }));
      setPosts(prev => prev.map(p => {
        if (p.id === postId) {
          return { ...p, comments_count: Math.max(0, (p.comments_count || 1) - 1) };
        }
        return p;
      }));
    } catch (err) {
      alert('Failed to delete comment.');
    }
  };

  const handleUpdateStatus = async (postId, status) => {
    setUpdatingPostId(postId);
    try {
      await api.patch(`/community/posts/${postId}/status`, { status });
      setPosts(prev => prev.map(p => {
        if (p.id === postId) {
          return { ...p, lead_status: status };
        }
        return p;
      }));
    } catch (err) {
      alert('Failed to update status.');
    } finally {
      setUpdatingPostId(null);
    }
  };

  const handleConfirmTYFB = async (postId) => {
    if (!roiValue) return;
    setUpdatingPostId(postId);
    try {
      await api.patch(`/community/posts/${postId}/tyfb`, { business_value: parseFloat(roiValue) });
      setRoiFormPostId(null);
      setRoiValue('');
      loadData();
    } catch (err) {
      alert('Failed to record business value.');
    } finally {
      setUpdatingPostId(null);
    }
  };

  // Stats calculation
  const totalPostsCount = posts.length;
  const oppsCount = posts.filter(p => p.post_type === 'lead' || p.post_type === 'rfp').length;
  const pinnedCount = posts.filter(p => p.is_pinned).length;

  return (
    <div className="dashboard-body" style={{ position: 'relative', paddingBottom: '4rem' }}>
      
      {/* Title Header */}
      <div style={{ display: 'flex', justifyContent: 'space-between', alignItems: 'flex-start', marginBottom: '1.5rem' }}>
        <Ds.PageHeader
          title="Community"
          description="Engage with PBN chapters, post leads, and follow business requests."
        />
        <Ds.Button 
          variant="primary" 
          leftIcon={<IconPlus size={16} />} 
          onClick={() => setIsCreateOpen(true)}
        >
          Create a Post
        </Ds.Button>
      </div>

      {/* Load Error Alert */}
      {loadError && (
        <div style={{ 
          padding: '1rem', background: 'rgba(239,68,68,0.1)', border: '1px solid rgba(239,68,68,0.2)',
          borderRadius: '16px', color: '#ef4444', marginBottom: '1.5rem',
          display: 'flex', alignItems: 'center', justifyContent: 'space-between', gap: '1rem'
        }}>
          <div style={{ display: 'flex', alignItems: 'center', gap: '10px', fontSize: '0.85rem', fontWeight: 600 }}>
            <IconAlertTriangle size={18} />
            An error occurred while fetching updates.
          </div>
          <button 
            onClick={loadData}
            style={{
              background: 'none', border: '1px solid rgba(239,68,68,0.3)',
              color: '#ef4444', borderRadius: '8px', padding: '6px 12px',
              fontSize: '0.75rem', fontWeight: 800, cursor: 'pointer'
            }}
          >
            RETRY
          </button>
        </div>
      )}

      {/* Hero Banner (styled like Event Hero) */}
      <div className="event-hero-v3">
        <div style={{ display: 'flex', flexDirection: 'column', gap: '0.5rem', maxWidth: '80%' }}>
          <div style={{ display: 'flex', alignItems: 'center', gap: '8px' }}>
            <IconVolume size={20} style={{ color: 'var(--brand-amber)' }} />
            <span style={{ fontSize: '0.7rem', fontWeight: 900, color: 'var(--brand-amber)', letterSpacing: '0.15em' }}>CHAPTER DISCUSSIONS</span>
          </div>
          <h3 style={{ fontSize: '1.6rem', fontWeight: 900, color: 'white', letterSpacing: '-0.02em', margin: '4px 0 0 0' }}>
            Community Feed
          </h3>
          <p style={{ color: 'rgba(255,255,255,0.85)', fontSize: '0.9rem', margin: '4px 0 10px 0', fontWeight: 600 }}>
            Broadcast business updates, ask for referrals, or upload project RFPs.
          </p>
          
          <div style={{
            background: 'var(--brand-amber)',
            color: 'white',
            alignSelf: 'flex-start',
            borderRadius: '8px',
            padding: '4px 10px',
            fontSize: '0.7rem',
            fontWeight: 900,
            display: 'flex',
            alignItems: 'center',
            gap: '4px',
            boxShadow: '0 4px 10px rgba(198, 165, 76, 0.3)'
          }}>
            <IconUserCheck size={12} />
            Active Networking in Chapter
          </div>
        </div>
      </div>

      {/* Stats Counter Row (styled like Event stats) */}
      <div className="event-stats-v3">
        <div className="event-stat-card-v3">
          <div className="event-stat-icon-v3" style={{ background: 'var(--brand-blue-50)', color: 'var(--brand-blue)' }}>
            <IconUsers size={18} />
          </div>
          <div className="event-stat-info-v3">
            <span className="event-stat-val-v3">{totalPostsCount}</span>
            <span className="event-stat-lbl-v3">Feed Posts</span>
          </div>
        </div>
        
        <div className="event-stat-card-v3">
          <div className="event-stat-icon-v3" style={{ background: 'rgba(52, 211, 153, 0.1)', color: '#34d399' }}>
            <IconCoin size={18} />
          </div>
          <div className="event-stat-info-v3">
            <span className="event-stat-val-v3">{oppsCount}</span>
            <span className="event-stat-lbl-v3">Opportunities</span>
          </div>
        </div>

        <div className="event-stat-card-v3">
          <div className="event-stat-icon-v3" style={{ background: 'var(--brand-amber-50)', color: 'var(--brand-amber)' }}>
            <IconPin size={18} />
          </div>
          <div className="event-stat-info-v3">
            <span className="event-stat-val-v3">{pinnedCount}</span>
            <span className="event-stat-lbl-v3">Pinned Updates</span>
          </div>
        </div>
      </div>

      {/* Tab Controller Bar (styled like Event tabs) */}
      <div className="events-tabs-v3" style={{ marginBottom: '1.5rem' }}>
        <button 
          className={`event-tab-btn-v3 ${selectedTab === 'chapter' ? 'is-active' : ''}`}
          onClick={() => setSelectedTab('chapter')}
        >
          My Chapter Feed
        </button>
        <button 
          className={`event-tab-btn-v3 ${selectedTab === 'network' ? 'is-active' : ''}`}
          onClick={() => setSelectedTab('network')}
        >
          Network-Wide Feed
        </button>
      </div>

      {/* Filters Search & Category Chips */}
      <div style={{ display: 'flex', flexDirection: 'column', gap: '1rem', marginBottom: '2rem' }}>
        {/* Search Input bar */}
        <div style={{ position: 'relative', width: '100%' }}>
          <div style={{ position: 'absolute', left: '1rem', top: '50%', transform: 'translateY(-50%)', color: 'var(--fg-muted)' }}>
            <IconSearch size={18} />
          </div>
          <input 
            type="text" 
            placeholder="Search feed messages, authors, or target industries..."
            value={searchQuery}
            onChange={(e) => setSearchQuery(e.target.value)}
            style={{
              width: '100%',
              padding: '0.85rem 1rem 0.85rem 2.75rem',
              borderRadius: '16px',
              border: '1px solid var(--border-subtle)',
              background: 'var(--bg-surface)',
              color: 'var(--fg-primary)',
              fontWeight: 600,
              fontSize: '0.9rem',
              boxShadow: 'var(--shadow-sm)'
            }}
          />
          {searchQuery && (
            <button 
              onClick={() => setSearchQuery('')}
              style={{ position: 'absolute', right: '1rem', top: '50%', transform: 'translateY(-50%)', background: 'none', border: 'none', color: 'var(--fg-muted)', cursor: 'pointer' }}
            >
              <IconX size={16} />
            </button>
          )}
        </div>

        {/* Filters chips list */}
        <div style={{ display: 'flex', gap: '0.5rem', overflowX: 'auto', paddingBottom: '4px' }}>
          {[
            { id: 'all', label: 'All Updates', icon: <IconApps size={14} /> },
            { id: 'pinned', label: 'Pinned Only', icon: <IconPin size={14} /> },
            { id: 'my_posts', label: 'My Posts', icon: <IconUserCheck size={14} /> },
            { id: 'opportunities', label: 'Leads & RFPs', icon: <IconCoin size={14} /> }
          ].map(chip => (
            <button
              key={chip.id}
              onClick={() => setActiveFilter(chip.id)}
              style={{
                background: activeFilter === chip.id ? 'var(--brand-amber)' : 'var(--bg-surface)',
                border: `1.5px solid ${activeFilter === chip.id ? 'var(--brand-amber)' : 'var(--border-subtle)'}`,
                color: activeFilter === chip.id ? 'white' : 'var(--fg-secondary)',
                borderRadius: '12px', padding: '0.5rem 1rem', fontSize: '0.8rem', fontWeight: 800,
                cursor: 'pointer', display: 'flex', alignItems: 'center', gap: '6px', transition: 'all 0.15s'
              }}
            >
              {chip.icon}
              {chip.label}
            </button>
          ))}
        </div>
      </div>

      {/* Feed list display */}
      {loading ? (
        <div style={{ padding: '6rem', textAlign: 'center', color: 'var(--fg-secondary)', fontWeight: 600 }}>
          Loading community feed...
        </div>
      ) : posts.length === 0 ? (
        <div style={{ marginTop: '1rem' }}>
          <Ds.EmptyState 
            icon={IconMessageCircle}
            title="Feed is empty" 
            description="Be the first to share an update, lead, or RFP in this feed."
          />
        </div>
      ) : (
        <div style={{ display: 'flex', flexDirection: 'column', gap: '1.5rem' }}>
          {posts.map(post => {
            const isAuthor = user && post.author?.id === user.id;
            const isAdmin = user && ['super_admin', 'admin', 'chapter_admin'].includes(user.role);
            
            return (
              <div 
                key={post.id}
                style={{
                  background: 'var(--bg-surface)',
                  border: '1px solid var(--border-subtle)',
                  borderRadius: '24px',
                  boxShadow: 'var(--shadow-md)',
                  padding: '1.5rem',
                  display: 'flex',
                  flexDirection: 'column',
                  gap: '1rem',
                  position: 'relative'
                }}
              >
                {/* Author Header */}
                <div style={{ display: 'flex', justify: 'space-between', alignItems: 'center', justifyContent: 'space-between' }}>
                  <div style={{ display: 'flex', alignItems: 'center', gap: '0.75rem' }}>
                    <Ds.Avatar name={post.author?.full_name} src={post.author?.profile_photo} size="md" />
                    <div>
                      <div style={{ fontSize: '0.9rem', fontWeight: 800, color: 'var(--fg-primary)' }}>
                        {post.author?.full_name}
                      </div>
                      <div style={{ fontSize: '0.72rem', color: 'var(--fg-muted)', display: 'flex', alignItems: 'center', gap: '4px', marginTop: '2px', fontWeight: 700 }}>
                        <IconClock size={12} />
                        {new Date(post.created_at).toLocaleString('en-US', { month: 'short', day: 'numeric', hour: '2-digit', minute: '2-digit' })}
                        &middot;
                        <span style={{ textTransform: 'uppercase' }}>{post.visibility}</span>
                      </div>
                    </div>
                  </div>

                  {/* Badges/Pins */}
                  <div style={{ display: 'flex', alignItems: 'center', gap: '6px' }}>
                    {post.is_pinned && (
                      <span style={{
                        background: 'rgba(245, 158, 11, 0.12)', color: 'var(--brand-amber)', border: '1px solid rgba(245,158,11,0.25)',
                        fontSize: '9px', fontWeight: 900, padding: '2px 8px', borderRadius: '6px', display: 'flex', alignItems: 'center', gap: '3px'
                      }}>
                        <IconPin size={10} /> PINNED
                      </span>
                    )}

                    {post.post_type !== 'general' && (
                      <span style={{
                        background: post.post_type === 'rfp' ? 'rgba(var(--brand-blue-rgb), 0.12)' : 'rgba(52, 211, 153, 0.12)',
                        color: post.post_type === 'rfp' ? 'var(--brand-blue)' : '#34d399',
                        fontSize: '9px', fontWeight: 950, padding: '2px 8px', borderRadius: '6px', textTransform: 'uppercase'
                      }}>
                        {post.post_type}
                      </span>
                    )}
                  </div>
                </div>

                {/* Core content text */}
                <p style={{ color: 'var(--fg-secondary)', fontSize: 'var(--text-sm)', lineHeight: 1.5, margin: 0, whiteSpace: 'pre-wrap' }}>
                  {post.content}
                </p>

                {/* Image attachment */}
                {post.image_url && (
                  <div style={{ width: '100%', maxHeight: '350px', borderRadius: '16px', overflow: 'hidden', border: '1px solid var(--border-subtle)', marginTop: '0.25rem' }}>
                    <img src={post.image_url} alt="Attachment" style={{ width: '100%', height: '100%', objectFit: 'cover' }} />
                  </div>
                )}

                {/* Opportunity Box (Leads & RFPs metadata) */}
                {post.post_type !== 'general' && (
                  <div style={{
                    background: 'var(--bg-canvas)', borderRadius: '16px', border: '1px solid var(--border-subtle)',
                    padding: '1rem', display: 'grid', gridTemplateColumns: 'repeat(auto-fit, minmax(180px, 1fr))', gap: '1rem'
                  }}>
                    {post.target_industry_name && (
                      <div>
                        <div style={{ fontSize: '0.65rem', fontWeight: 800, color: 'var(--fg-muted)', letterSpacing: '0.5px' }}>TARGET INDUSTRY</div>
                        <div style={{ fontSize: '0.85rem', fontWeight: 800, color: 'var(--fg-primary)', marginTop: '2px' }}>{post.target_industry_name}</div>
                      </div>
                    )}

                    {post.budget_range && (
                      <div>
                        <div style={{ fontSize: '0.65rem', fontWeight: 800, color: 'var(--fg-muted)', letterSpacing: '0.5px' }}>BUDGET RANGE</div>
                        <div style={{ fontSize: '0.85rem', fontWeight: 800, color: 'var(--fg-primary)', marginTop: '2px' }}>{post.budget_range}</div>
                      </div>
                    )}

                    {post.deadline && (
                      <div>
                        <div style={{ fontSize: '0.65rem', fontWeight: 800, color: 'var(--fg-muted)', letterSpacing: '0.5px' }}>DEADLINE</div>
                        <div style={{ fontSize: '0.85rem', fontWeight: 800, color: 'var(--fg-primary)', marginTop: '2px' }}>
                          {new Date(post.deadline).toLocaleDateString()}
                        </div>
                      </div>
                    )}

                    <div>
                      <div style={{ fontSize: '0.65rem', fontWeight: 800, color: 'var(--fg-muted)', letterSpacing: '0.5px' }}>OPPORTUNITY STATUS</div>
                      <div style={{ display: 'flex', alignItems: 'center', gap: '6px', marginTop: '2px' }}>
                        <span style={{
                          fontSize: '10px', fontWeight: 900, padding: '2px 8px', borderRadius: '6px', textTransform: 'uppercase',
                          background: post.lead_status === 'closed_won' ? 'rgba(52, 211, 153, 0.12)' : post.lead_status === 'closed_lost' ? 'var(--border-subtle)' : 'rgba(245, 158, 11, 0.12)',
                          color: post.lead_status === 'closed_won' ? '#34d399' : post.lead_status === 'closed_lost' ? 'var(--fg-secondary)' : 'var(--brand-amber)'
                        }}>
                          {post.lead_status?.replace('_', ' ') || 'OPEN'}
                        </span>
                        
                        {post.lead_status === 'closed_won' && post.business_value && (
                          <span style={{ fontSize: '0.78rem', fontWeight: 800, color: '#34d399' }}>
                            (LKR {Number(post.business_value).toLocaleString()} TYFB)
                          </span>
                        )}
                      </div>
                    </div>
                  </div>
                )}

                {/* Economic / Status transition manager (For authors & Admins) */}
                {post.post_type !== 'general' && (isAuthor || isAdmin) && (
                  <div style={{ 
                    borderTop: '1px solid var(--border-subtle)', 
                    paddingTop: '0.75rem', 
                    display: 'flex', 
                    flexWrap: 'wrap', 
                    alignItems: 'center', 
                    gap: '0.75rem' 
                  }}>
                    <span style={{ fontSize: '0.75rem', color: 'var(--fg-muted)', fontWeight: 800 }}>MANAGE OPPORTUNITY:</span>
                    
                    {post.lead_status !== 'closed_won' && post.lead_status !== 'closed_lost' ? (
                      <div style={{ display: 'flex', gap: '0.5rem' }}>
                        {post.lead_status === 'open' && (
                          <button
                            onClick={() => handleUpdateStatus(post.id, 'in_progress')}
                            disabled={updatingPostId === post.id}
                            style={{ background: 'var(--brand-blue)', color: 'white', border: 'none', borderRadius: '6px', padding: '4px 10px', fontSize: '0.7rem', fontWeight: 900, cursor: 'pointer' }}
                          >
                            Mark In Progress
                          </button>
                        )}
                        <button
                          onClick={() => setRoiFormPostId(post.id)}
                          style={{ background: '#34d399', color: '#0A2540', border: 'none', borderRadius: '6px', padding: '4px 10px', fontSize: '0.7rem', fontWeight: 900, cursor: 'pointer' }}
                        >
                          Mark Closed Won (Log TYFB)
                        </button>
                        <button
                          onClick={() => handleUpdateStatus(post.id, 'closed_lost')}
                          style={{ background: 'transparent', border: '1px solid var(--border-subtle)', color: 'var(--fg-muted)', borderRadius: '6px', padding: '4px 10px', fontSize: '0.7rem', fontWeight: 800, cursor: 'pointer' }}
                        >
                          Mark Lost
                        </button>
                      </div>
                    ) : (
                      <span style={{ fontSize: '0.75rem', color: 'var(--fg-muted)', fontStyle: 'italic' }}>Opportunity is finalized</span>
                    )}

                    {roiFormPostId === post.id && (
                      <div style={{
                        width: '100%', marginTop: '0.5rem', padding: '0.75rem', background: 'var(--bg-canvas)',
                        border: '1px solid var(--border-subtle)', borderRadius: '12px', display: 'flex', flexDirection: 'column', gap: '0.5rem'
                      }}>
                        <div style={{ fontSize: '0.7rem', fontWeight: 800, color: 'var(--fg-muted)' }}>ENTER GENERATED BUSINESS VALUE (LKR)</div>
                        <div style={{ display: 'flex', gap: '0.5rem' }}>
                          <input
                            type="number"
                            value={roiValue}
                            onChange={(e) => setRoiValue(e.target.value)}
                            placeholder="e.g. 150000"
                            style={{
                              flex: 1, padding: '4px 8px', borderRadius: '6px', border: '1px solid var(--border-subtle)',
                              background: 'var(--bg-surface)', color: 'var(--fg-primary)', fontSize: '0.8rem', fontWeight: 700
                            }}
                          />
                          <button
                            onClick={() => handleConfirmTYFB(post.id)}
                            disabled={updatingPostId === post.id}
                            className="ds-btn ds-btn--primary"
                            style={{
                              borderRadius: '6px', padding: '4px 12px', fontSize: '0.75rem', fontWeight: 900, cursor: 'pointer'
                            }}
                          >
                            Submit TYFB
                          </button>
                        </div>
                      </div>
                    )}
                  </div>
                )}

                {/* Interaction Footer (Likes & Comments counts) */}
                <div style={{
                  display: 'flex',
                  alignItems: 'center',
                  gap: '1.5rem',
                  borderTop: '1px solid var(--border-subtle)',
                  paddingTop: '0.75rem',
                  marginTop: '0.25rem'
                }}>
                  {/* Like Button */}
                  <button
                    onClick={() => handleLike(post.id)}
                    style={{
                      background: 'none', border: 'none', cursor: 'pointer',
                      display: 'flex', alignItems: 'center', gap: '6px',
                      color: post.is_liked_by_me ? '#ef4444' : 'var(--fg-secondary)',
                      fontSize: '0.8rem', fontWeight: 800, padding: 0
                    }}
                  >
                    {post.is_liked_by_me ? <IconHeartFilled size={18} /> : <IconHeart size={18} />}
                    {post.likes_count || 0} Likes
                  </button>

                  {/* Comment Trigger */}
                  <button
                    onClick={() => toggleComments(post.id)}
                    style={{
                      background: 'none', border: 'none', cursor: 'pointer',
                      display: 'flex', alignItems: 'center', gap: '6px',
                      color: expandedPostId === post.id ? 'var(--brand-blue)' : 'var(--fg-secondary)',
                      fontSize: '0.8rem', fontWeight: 800, padding: 0
                    }}
                  >
                    <IconMessageCircle size={18} />
                    {post.comments_count || 0} Comments
                  </button>

                  {/* Pin and Delete Controls (Admins/Authors) */}
                  <div style={{ marginLeft: 'auto', display: 'flex', gap: '0.5rem' }}>
                    {(isAdmin || isAuthor) && (
                      <button
                        onClick={() => handlePin(post.id)}
                        title="Toggle Pin"
                        style={{
                          background: 'none', border: 'none', cursor: 'pointer',
                          color: post.is_pinned ? 'var(--brand-amber)' : 'var(--fg-muted)',
                          padding: '4px'
                        }}
                      >
                        <IconPin size={16} />
                      </button>
                    )}

                    {(isAdmin || isAuthor) && (
                      <button
                        onClick={() => handleDeletePost(post.id)}
                        title="Delete Post"
                        style={{
                          background: 'none', border: 'none', cursor: 'pointer',
                          color: '#ef4444', padding: '4px'
                        }}
                      >
                        <IconTrash size={16} />
                      </button>
                    )}
                  </div>
                </div>

                {/* Collapsible Comments Section */}
                {expandedPostId === post.id && (
                  <div style={{
                    borderTop: '1px solid var(--border-subtle)',
                    paddingTop: '1rem',
                    display: 'flex',
                    flexDirection: 'column',
                    gap: '1rem'
                  }}>
                    {/* Add Comment form */}
                    <form onSubmit={(e) => handleAddComment(e, post.id)} style={{ display: 'flex', gap: '0.5rem' }}>
                      <input
                        type="text"
                        placeholder="Write a comment..."
                        value={newCommentText}
                        onChange={(e) => setNewCommentText(e.target.value)}
                        required
                        style={{
                          flex: 1, padding: '0.5rem 1rem', background: 'var(--bg-canvas)',
                          border: '1px solid var(--border-subtle)', borderRadius: '12px',
                          color: 'var(--fg-primary)', fontSize: '0.82rem', fontWeight: 600
                        }}
                      />
                      <button
                        type="submit"
                        className="ds-btn ds-btn--primary"
                        style={{
                          borderRadius: '12px',
                          padding: '0.5rem 1.25rem', fontSize: '0.75rem', fontWeight: 900, cursor: 'pointer'
                        }}
                      >
                        Comment
                      </button>
                    </form>

                    {/* Comments list */}
                    {loadingCommentsPostId === post.id ? (
                      <div style={{ fontSize: '0.75rem', color: 'var(--fg-muted)', padding: '0.5rem', textAlign: 'center' }}>Loading comments...</div>
                    ) : !commentsMap[post.id] || commentsMap[post.id].length === 0 ? (
                      <div style={{ fontSize: '0.75rem', color: 'var(--fg-muted)', fontStyle: 'italic', padding: '0.5rem', textAlign: 'center' }}>No comments yet.</div>
                    ) : (
                      <div style={{ display: 'flex', flexDirection: 'column', gap: '0.75rem' }}>
                        {commentsMap[post.id].map(comment => {
                          const isCommentAuthor = user && comment.author?.id === user.id;
                          return (
                            <div key={comment.id} style={{
                              background: 'var(--bg-canvas)', padding: '0.75rem 1rem', borderRadius: '14px',
                              border: '1px solid var(--border-subtle)', display: 'flex', gap: '0.75rem', alignItems: 'flex-start'
                            }}>
                              <Ds.Avatar name={comment.author?.full_name} src={comment.author?.profile_photo} size="sm" />
                              <div style={{ flex: 1 }}>
                                <div style={{ display: 'flex', justify: 'space-between', alignItems: 'center', justifyContent: 'space-between' }}>
                                  <div style={{ fontSize: '0.8rem', fontWeight: 800, color: 'var(--fg-primary)' }}>{comment.author?.full_name}</div>
                                  <div style={{ display: 'flex', alignItems: 'center', gap: '6px' }}>
                                    <span style={{ fontSize: '0.65rem', color: 'var(--fg-muted)' }}>
                                      {new Date(comment.created_at).toLocaleDateString()}
                                    </span>
                                    {(isCommentAuthor || isAdmin) && (
                                      <button
                                        onClick={() => handleDeleteComment(post.id, comment.id)}
                                        style={{ background: 'none', border: 'none', color: '#ef4444', cursor: 'pointer', padding: 0 }}
                                      >
                                        <IconTrash size={12} />
                                      </button>
                                    )}
                                  </div>
                                </div>
                                <p style={{ color: 'var(--fg-secondary)', fontSize: '0.78rem', margin: '4px 0 0 0', lineHeight: 1.4, fontWeight: 500 }}>
                                  {comment.content}
                                </p>
                              </div>
                            </div>
                          );
                        })}
                      </div>
                    )}
                  </div>
                )}

              </div>
            );
          })}
        </div>
      )}

      <CreatePostModal 
        isOpen={isCreateOpen}
        onClose={() => setIsCreateOpen(false)}
        onSuccess={loadData}
      />

    </div>
  );
}
