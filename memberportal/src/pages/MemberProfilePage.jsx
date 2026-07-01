import React, { useState, useEffect } from 'react';
import { useParams, useNavigate } from 'react-router-dom';
import { IconMail, IconSend, IconArrowLeft, IconBriefcase, IconMapPin, IconBuildingSkyscraper, IconPhone, IconBrandWhatsapp } from '@tabler/icons-react';
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

    try {
      await api.post(`/community/members/${member.user_id}/send-email`, {
        subject: emailSubject,
        body: emailContent
      });
      alert('Email sent successfully using your personal SMTP settings!');
      setShowEmailModal(false);
    } catch (err) {
      alert(err.response?.data?.error?.message || 'Failed to send email. Please check your SMTP settings.');
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

  const vLevel = member.verification_level && member.verification_level !== 'none' ? member.verification_level : 'Member';

  return (
    <div className="dashboard-body">
      <div style={{ marginBottom: '2rem' }}>
        <Ds.Button variant="ghost" leftIcon={<IconArrowLeft size={16} />} onClick={() => navigate('/members')}>
          Back to Directory
        </Ds.Button>
      </div>

      <div style={{ display: 'grid', gridTemplateColumns: '1fr', gap: '2rem' }}>
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

      {showEmailModal && (
        <Ds.Modal
          isOpen={true}
          onClose={() => setShowEmailModal(false)}
          title={`Email ${member.full_name}`}
        >
          <form onSubmit={handleSendEmail}>
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
            <Ds.Field label="Message">
              <Ds.Textarea
                value={emailContent}
                onChange={e => setEmailContent(e.target.value)}
                rows={6}
                required
              />
            </Ds.Field>
            <div style={{ display: 'flex', justifyContent: 'flex-end', gap: '0.75rem', marginTop: '2rem' }}>
              <Ds.Button variant="ghost" onClick={() => setShowEmailModal(false)}>Cancel</Ds.Button>
              <Ds.Button variant="primary" type="submit" loading={isSending} leftIcon={<IconSend size={16} />}>
                Send Message
              </Ds.Button>
            </div>
          </form>
        </Ds.Modal>
      )}
    </div>
  );
}
