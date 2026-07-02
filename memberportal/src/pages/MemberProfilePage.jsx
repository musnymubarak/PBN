import React, { useState, useEffect } from 'react';
import { useParams, useNavigate } from 'react-router-dom';
import { 
  IconMail, 
  IconSend, 
  IconArrowLeft, 
  IconBriefcase, 
  IconMapPin, 
  IconBuildingSkyscraper, 
  IconPhone, 
  IconBrandWhatsapp, 
  IconCircleCheckFilled, 
  IconAlertTriangle,
  IconWorld,
  IconFileDownload,
  IconBrandLinkedin,
  IconBrandFacebook,
  IconBrandInstagram,
  IconCalendar,
  IconFileText
} from '@tabler/icons-react';
import * as Ds from '../components/ui';
import api from '../lib/api';

export default function MemberProfilePage() {
  const { id } = useParams();
  const navigate = useNavigate();
  
  const [member, setMember] = useState(null);
  const [loading, setLoading] = useState(true);
  
  const [showEmailModal, setShowEmailModal] = useState(false);
  const [emailSubject, setEmailSubject] = useState('Connection request via PBN Portal');
  const [emailContent, setEmailContent] = useState('');
  const [isSending, setIsSending] = useState(false);

  const [successBanner, setSuccessBanner] = useState('');
  const [errorBanner, setErrorBanner] = useState('');

  useEffect(() => {
    const fetchMember = async () => {
      try {
        const res = await api.get('/chapters/members/all');
        if (res.data?.data) {
          const found = res.data.data.find(m => m.user_id.toString() === id);
          if (found) {
            setMember(found);
            setEmailContent(`Hi ${found.full_name},\n\nI'd like to connect regarding...`);
          }
        }
      } catch (err) {
        console.error('Failed to fetch member details', err);
      } finally {
        setLoading(false);
      }
    };
    fetchMember();
  }, [id]);

  const handleSendEmail = async (e) => {
    e.preventDefault();
    setIsSending(true);
    setErrorBanner('');
    setSuccessBanner('');

    try {
      await api.post(`/members/${member.user_id}/send-email`, {
        subject: emailSubject,
        content: emailContent
      });
      setShowEmailModal(false);
      setSuccessBanner('Email sent successfully using your personal SMTP settings!');
      setTimeout(() => setSuccessBanner(''), 6000);
    } catch (err) {
      setErrorBanner(err.response?.data?.error?.message || 'Failed to send email. Please check your SMTP settings.');
      setTimeout(() => setErrorBanner(''), 6000);
    } finally {
      setIsSending(false);
    }
  };

  const formatWhatsAppNumber = (num) => {
    if (!num) return '';
    return num.replace(/\D/g, ''); // strip non-digits
  };

  if (loading) {
    return (
      <div className="dashboard-body">
        <Ds.EmptyState icon={Ds.Spinner} title="Loading Profile..." />
      </div>
    );
  }

  if (!member) {
    return (
      <div className="dashboard-body">
        <Ds.EmptyState title="Member Not Found" description="The requested member profile could not be found." />
        <div style={{ textAlign: 'center', marginTop: '1rem' }}>
          <Ds.Button variant="ghost" onClick={() => navigate('/members')}>Back to Directory</Ds.Button>
        </div>
      </div>
    );
  }

  const sectionHeader = (title) => (
    <div style={{ display: 'flex', alignItems: 'center', gap: '0.5rem', marginBottom: '1rem' }}>
      <div style={{ width: '3px', height: '18px', background: 'linear-gradient(to bottom, #d4af37, #aa842c)', borderRadius: '2px' }} />
      <h2 style={{ fontSize: '1.1rem', fontWeight: 800, color: 'var(--fg-primary)', margin: 0, textTransform: 'uppercase' }}>
        {title}
      </h2>
    </div>
  );

  const vLevel = member.verification_level && member.verification_level !== 'none' ? member.verification_level : 'Member';

  return (
    <div className="dashboard-body">
      <Ds.PageHeader
        title="Member Profile"
        description="View details and connect with this member."
        actions={
          <Ds.Button variant="ghost" leftIcon={<IconArrowLeft size={16} />} onClick={() => navigate('/members')}>
            Back to Directory
          </Ds.Button>
        }
      />

      {successBanner && (
        <div style={{
          marginBottom: '1.5rem',
          padding: '1rem',
          background: 'var(--brand-green-50)',
          color: 'var(--brand-green-700)',
          border: '1px solid var(--brand-green-100)',
          borderRadius: 'var(--radius-lg)',
          fontSize: 'var(--text-sm)',
          fontWeight: 600,
          boxShadow: '0 2px 8px rgba(16,185,129,0.05)',
          display: 'flex',
          alignItems: 'center',
          gap: '0.5rem'
        }}>
          <IconCircleCheckFilled size={18} style={{ color: '#10b981', flexShrink: 0 }} />
          <span>{successBanner}</span>
        </div>
      )}

      {errorBanner && (
        <div style={{
          marginBottom: '1.5rem',
          padding: '1rem',
          background: 'var(--brand-red-50)',
          color: 'var(--brand-red-600)',
          border: '1px solid var(--brand-red-100)',
          borderRadius: 'var(--radius-lg)',
          fontSize: 'var(--text-sm)',
          fontWeight: 600,
          boxShadow: '0 2px 8px rgba(239,68,68,0.05)',
          display: 'flex',
          alignItems: 'center',
          gap: '0.5rem'
        }}>
          <IconAlertTriangle size={18} style={{ color: '#ef4444', flexShrink: 0 }} />
          <span>{errorBanner}</span>
        </div>
      )}

      <div style={{
        display: 'grid',
        gridTemplateColumns: 'repeat(auto-fit, minmax(360px, 1fr))',
        gap: '2rem',
        alignItems: 'start'
      }}>
        {/* Left Column: Personal Profile */}
        <div>
          {sectionHeader('Personal Profile')}
          <Ds.Card padded style={{ display: 'flex', flexDirection: 'column', alignItems: 'center', textAlign: 'center' }}>
            <Ds.Avatar name={member.full_name} src={member.profile_photo} size="lg" variant="brand" style={{ marginBottom: '1rem', width: 80, height: 80, fontSize: '2rem' }} />
            <h1 style={{ fontSize: 'var(--text-3xl)', fontWeight: 700, color: 'var(--fg-primary)', marginBottom: '0.5rem', display: 'flex', alignItems: 'center', gap: '0.5rem' }}>
              {member.full_name}
            </h1>
            {vLevel !== 'Member' && (
              <div style={{ marginBottom: '1.5rem' }}>
                <Ds.Badge variant={vLevel === 'Gold' ? 'warning' : 'info'} style={{ display: 'inline-flex', alignItems: 'center', gap: '0.375rem', padding: '0.25rem 0.75rem', fontSize: '0.75rem', textTransform: 'uppercase' }}>
                  <svg xmlns="http://www.w3.org/2000/svg" width="14" height="14" viewBox="0 0 24 24" fill="currentColor" stroke="none"><path d="M12.01 2.011a3.2 3.2 0 0 1 2.113 .797l.154 .145l.698 .698a1.2 1.2 0 0 0 .71 .341l.135 .008h1a3.2 3.2 0 0 1 3.195 3.018l.005 .182v1c0 .27 .092 .533 .258 .743l.09 .1l.697 .698a3.2 3.2 0 0 1 .147 4.382l-.145 .154l-.698 .698a1.2 1.2 0 0 0 -.341 .71l-.008 .135v1a3.2 3.2 0 0 1 -3.018 3.195l-.182 .005h-1a1.2 1.2 0 0 0 -.71 .341l-.135 .008l-.698 .698a3.2 3.2 0 0 1 -4.382 .147l-.154 -.145l-.698 -.698a1.2 1.2 0 0 0 -.71 -.341l-.135 -.008h-1a3.2 3.2 0 0 1 -3.195 -3.018l-.005 -.182v-1a1.2 1.2 0 0 0 -.341 -.71l-.008 -.135l-.698 -.698a3.2 3.2 0 0 1 -.147 -4.382l.145 -.154l.698 -.698a1.2 1.2 0 0 0 .341 -.71l.008 -.135v-1a3.2 3.2 0 0 1 3.018 -3.195l.182 -.005h1a1.2 1.2 0 0 0 .71 -.341l.135 -.008l.698 -.698a3.2 3.2 0 0 1 2.269 -.944zm3.697 7.282a1 1 0 0 0 -1.414 0l-3.293 3.292l-1.293 -1.292l-.094 -.083a1 1 0 0 0 -1.32 1.497l2 2l.094 .083a1 1 0 0 0 1.32 -.083l4 -4l.083 -.094a1 1 0 0 0 -.083 -1.32z" /></svg>
                  {vLevel}
                </Ds.Badge>
              </div>
            )}
            
            <div style={{ display: 'flex', gap: '1rem', flexWrap: 'wrap', justifyContent: 'center', marginBottom: '2rem' }}>
              <div style={{ display: 'flex', alignItems: 'center', gap: '0.5rem', color: 'var(--fg-secondary)', fontSize: 'var(--text-sm)' }}>
                <IconMapPin size={16} />
                <span>{member.chapter_name || 'No Chapter'}</span>
              </div>
              <div style={{ display: 'flex', alignItems: 'center', gap: '0.5rem', color: 'var(--fg-secondary)', fontSize: 'var(--text-sm)' }}>
                <IconBriefcase size={16} />
                <span>{member.company || member.business_name || 'Independent'}</span>
              </div>
              <div style={{ display: 'flex', alignItems: 'center', gap: '0.5rem', color: 'var(--fg-secondary)', fontSize: 'var(--text-sm)' }}>
                <IconBuildingSkyscraper size={16} />
                <span>{member.industry || member.industry_category?.name || 'N/A'}</span>
              </div>
            </div>

            {(member.phone_number || member.email) && (
              <div style={{ display: 'flex', gap: '1.5rem', flexWrap: 'wrap', justifyContent: 'center', marginBottom: '2rem', padding: '1rem', background: 'var(--bg-subtle)', borderRadius: 'var(--radius-md)' }}>
                {member.phone_number && (
                  <div style={{ display: 'flex', alignItems: 'center', gap: '0.5rem', color: 'var(--fg-primary)', fontSize: 'var(--text-md)' }}>
                    <IconPhone size={18} style={{ color: 'var(--brand-primary)' }} />
                    <span>{member.phone_number}</span>
                  </div>
                )}
                {member.email && (
                  <div style={{ display: 'flex', alignItems: 'center', gap: '0.5rem', color: 'var(--fg-primary)', fontSize: 'var(--text-md)' }}>
                    <IconMail size={18} style={{ color: 'var(--brand-primary)' }} />
                    <a href={`mailto:${member.email}`} style={{ color: 'inherit', textDecoration: 'none' }}>{member.email}</a>
                  </div>
                )}
              </div>
            )}

            <div style={{ display: 'flex', gap: '1rem', flexWrap: 'wrap', justifyContent: 'center' }}>
              <Ds.Button
                variant="primary"
                leftIcon={<IconMail size={16} />}
                onClick={() => setShowEmailModal(true)}
                style={{ minWidth: 200 }}
              >
                Send Direct Email
              </Ds.Button>
              
              {member.phone_number && (
                <Ds.Button
                  variant="outline"
                  leftIcon={<IconBrandWhatsapp size={16} />}
                  onClick={() => window.open(`https://wa.me/${formatWhatsAppNumber(member.phone_number)}`, '_blank')}
                  style={{ 
                    minWidth: 200, 
                    borderColor: '#25D366', 
                    color: '#25D366',
                    backgroundColor: 'rgba(37, 211, 102, 0.05)'
                  }}
                >
                  WhatsApp Message
                </Ds.Button>
              )}
            </div>
          </Ds.Card>
        </div>

        {/* Right Column: Business Portfolio */}
        <div>
          {sectionHeader('Business Portfolio')}
          <Ds.Card padded style={{ display: 'flex', flexDirection: 'column', gap: '1.5rem', textAlign: 'left' }}>
            {member.business ? (
              <div style={{ display: 'flex', flexDirection: 'column', gap: '1.5rem' }}>
                
                {/* Business Header with logo */}
                <div style={{ display: 'flex', alignItems: 'center', gap: '1rem' }}>
                  {member.business.logo_url ? (
                    <img
                      src={member.business.logo_url}
                      alt={member.business.name}
                      style={{
                        width: '64px',
                        height: '64px',
                        borderRadius: '12px',
                        objectFit: 'cover',
                        border: '1px solid var(--border-subtle)'
                      }}
                    />
                  ) : (
                    <div style={{
                      width: '64px',
                      height: '64px',
                      borderRadius: '12px',
                      background: 'var(--bg-subtle)',
                      display: 'flex',
                      alignItems: 'center',
                      justifyContent: 'center',
                      color: 'var(--fg-muted)',
                      border: '1px solid var(--border-subtle)'
                    }}>
                      <IconBriefcase size={28} />
                    </div>
                  )}
                  <div>
                    <h3 style={{ fontSize: '1.15rem', fontWeight: 700, color: 'var(--fg-primary)', margin: 0 }}>
                      {member.business.name || member.company}
                    </h3>
                    <p style={{ fontSize: '0.85rem', color: 'var(--fg-secondary)', margin: '4px 0 0 0', fontWeight: 600 }}>
                      {member.industry || member.industry_category?.name}
                    </p>
                  </div>
                </div>

                {/* About description */}
                {member.business.description && (
                  <div>
                    <h4 style={{ fontSize: '0.875rem', fontWeight: 700, color: 'var(--fg-secondary)', margin: '0 0 0.5rem 0', textTransform: 'uppercase', letterSpacing: '0.05em' }}>
                      About The Business
                    </h4>
                    <p style={{ fontSize: '0.9rem', color: 'var(--fg-secondary)', lineHeight: 1.5, margin: 0 }}>
                      {member.business.description}
                    </p>
                  </div>
                )}

                {/* Details grid */}
                <div>
                  <h4 style={{ fontSize: '0.875rem', fontWeight: 700, color: 'var(--fg-secondary)', margin: '0 0 0.75rem 0', textTransform: 'uppercase', letterSpacing: '0.05em' }}>
                    Specifications
                  </h4>
                  <div style={{ display: 'grid', gridTemplateColumns: '1fr 1fr', gap: '1rem' }}>
                    
                    {member.business.district && (
                      <div style={{ display: 'flex', alignItems: 'start', gap: '8px' }}>
                        <IconMapPin size={16} style={{ color: 'var(--fg-muted)', marginTop: '2px' }} />
                        <div>
                          <div style={{ fontSize: '0.75rem', color: 'var(--fg-muted)', fontWeight: 600 }}>DISTRICT</div>
                          <div style={{ fontSize: '0.85rem', color: 'var(--fg-primary)', fontWeight: 700 }}>{member.business.district}</div>
                        </div>
                      </div>
                    )}

                    {member.business.established_year && (
                      <div style={{ display: 'flex', alignItems: 'start', gap: '8px' }}>
                        <IconCalendar size={16} style={{ color: 'var(--fg-muted)', marginTop: '2px' }} />
                        <div>
                          <div style={{ fontSize: '0.75rem', color: 'var(--fg-muted)', fontWeight: 600 }}>ESTABLISHED</div>
                          <div style={{ fontSize: '0.85rem', color: 'var(--fg-primary)', fontWeight: 700 }}>{member.business.established_year}</div>
                        </div>
                      </div>
                    )}

                    {member.business.br_number && (
                      <div style={{ display: 'flex', alignItems: 'start', gap: '8px', gridColumn: 'span 2' }}>
                        <IconFileText size={16} style={{ color: 'var(--fg-muted)', marginTop: '2px' }} />
                        <div>
                          <div style={{ fontSize: '0.75rem', color: 'var(--fg-muted)', fontWeight: 600 }}>BUSINESS REGISTRATION (BR)</div>
                          <div style={{ fontSize: '0.85rem', color: 'var(--fg-primary)', fontWeight: 700 }}>{member.business.br_number}</div>
                        </div>
                      </div>
                    )}

                    {member.business.address && (
                      <div style={{ display: 'flex', alignItems: 'start', gap: '8px', gridColumn: 'span 2' }}>
                        <IconMapPin size={16} style={{ color: 'var(--fg-muted)', marginTop: '2px' }} />
                        <div>
                          <div style={{ fontSize: '0.75rem', color: 'var(--fg-muted)', fontWeight: 600 }}>ADDRESS</div>
                          <div style={{ fontSize: '0.85rem', color: 'var(--fg-primary)', fontWeight: 500, lineHeight: 1.4 }}>{member.business.address}</div>
                        </div>
                      </div>
                    )}

                  </div>
                </div>

                {/* Action buttons (Website, Brochure, Maps) */}
                {(member.business.website || member.business.brochure_url || member.business.google_maps_url) && (
                  <div style={{ display: 'flex', gap: '8px', flexWrap: 'wrap', borderTop: '1px solid var(--border-subtle)', paddingTop: '1.25rem' }}>
                    {member.business.website && (
                      <Ds.Button
                        variant="outline"
                        size="sm"
                        leftIcon={<IconWorld size={14} />}
                        onClick={() => window.open(member.business.website, '_blank')}
                      >
                        Visit Website
                      </Ds.Button>
                    )}
                    {member.business.brochure_url && (
                      <Ds.Button
                        variant="outline"
                        size="sm"
                        leftIcon={<IconFileDownload size={14} />}
                        onClick={() => window.open(member.business.brochure_url, '_blank')}
                      >
                        View Brochure
                      </Ds.Button>
                    )}
                    {member.business.google_maps_url && (
                      <Ds.Button
                        variant="outline"
                        size="sm"
                        leftIcon={<IconMapPin size={14} />}
                        onClick={() => window.open(member.business.google_maps_url, '_blank')}
                      >
                        Google Maps
                      </Ds.Button>
                    )}
                  </div>
                )}

                {/* Social links */}
                {(member.business.linkedin_url || member.business.facebook_url || member.business.instagram_url) && (
                  <div style={{ display: 'flex', gap: '12px', alignItems: 'center', borderTop: '1px solid var(--border-subtle)', paddingTop: '1rem' }}>
                    <span style={{ fontSize: '0.75rem', color: 'var(--fg-muted)', fontWeight: 700, textTransform: 'uppercase', letterSpacing: '0.05em' }}>
                      Social Links:
                    </span>
                    <div style={{ display: 'flex', gap: '8px' }}>
                      {member.business.linkedin_url && (
                        <button
                          onClick={() => window.open(member.business.linkedin_url, '_blank')}
                          style={{
                            display: 'flex', alignItems: 'center', justifyContent: 'center',
                            width: '32px', height: '32px', borderRadius: '50%',
                            background: 'var(--bg-subtle)', border: '1px solid var(--border-subtle)',
                            cursor: 'pointer', color: 'var(--fg-primary)'
                          }}
                        >
                          <IconBrandLinkedin size={16} />
                        </button>
                      )}
                      {member.business.facebook_url && (
                        <button
                          onClick={() => window.open(member.business.facebook_url, '_blank')}
                          style={{
                            display: 'flex', alignItems: 'center', justifyContent: 'center',
                            width: '32px', height: '32px', borderRadius: '50%',
                            background: 'var(--bg-subtle)', border: '1px solid var(--border-subtle)',
                            cursor: 'pointer', color: 'var(--fg-primary)'
                          }}
                        >
                          <IconBrandFacebook size={16} />
                        </button>
                      )}
                      {member.business.instagram_url && (
                        <button
                          onClick={() => window.open(member.business.instagram_url, '_blank')}
                          style={{
                            display: 'flex', alignItems: 'center', justifyContent: 'center',
                            width: '32px', height: '32px', borderRadius: '50%',
                            background: 'var(--bg-subtle)', border: '1px solid var(--border-subtle)',
                            cursor: 'pointer', color: 'var(--fg-primary)'
                          }}
                        >
                          <IconBrandInstagram size={16} />
                        </button>
                      )}
                    </div>
                  </div>
                )}

              </div>
            ) : (
              <div style={{ display: 'flex', flexDirection: 'column', alignItems: 'center', justifyContent: 'center', padding: '3rem 1.5rem', color: 'var(--fg-muted)', textAlign: 'center', gap: '12px' }}>
                <IconBriefcase size={40} style={{ color: 'var(--border-default)' }} />
                <div>
                  <div style={{ fontWeight: 700, color: 'var(--fg-secondary)', fontSize: '0.95rem' }}>No Business Registered</div>
                  <div style={{ fontSize: '0.8rem', marginTop: '4px' }}>This member has not yet added their business details to their profile.</div>
                </div>
              </div>
            )}
          </Ds.Card>
        </div>
      </div>

      {showEmailModal && (
        <Ds.Modal
          isOpen={true}
          onClose={() => setShowEmailModal(false)}
        >
          <Ds.Modal.Header title={`Email ${member.full_name}`} onClose={() => setShowEmailModal(false)} />
          
          <form onSubmit={handleSendEmail}>
            <Ds.Modal.Body>
              <p style={{ fontSize: 'var(--text-sm)', color: 'var(--fg-secondary)', marginBottom: '1.5rem' }}>
                This email will be sent directly from your configured personal SMTP server.
              </p>
              <Ds.Field label="Subject">
                <Ds.Input
                  value={emailSubject}
                  onChange={e => setEmailSubject(e.target.value)}
                  required
                />
              </Ds.Field>
              <Ds.Field label="Message" style={{ marginTop: '1rem' }}>
                <Ds.Textarea
                  value={emailContent}
                  onChange={e => setEmailContent(e.target.value)}
                  rows={6}
                  required
                />
              </Ds.Field>
            </Ds.Modal.Body>

            <Ds.Modal.Footer>
              <Ds.Button variant="ghost" onClick={() => setShowEmailModal(false)}>Cancel</Ds.Button>
              <Ds.Button variant="primary" type="submit" loading={isSending} leftIcon={<IconSend size={16} />}>
                Send Message
              </Ds.Button>
            </Ds.Modal.Footer>
          </form>
        </Ds.Modal>
      )}
    </div>
  );
}
