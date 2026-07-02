import React, { useState } from 'react';
import * as Ds from '../components/ui';
import { 
  IconHelp, 
  IconMail, 
  IconClock, 
  IconActivity, 
  IconCheck, 
  IconChevronDown, 
  IconChevronUp 
} from '@tabler/icons-react';

export default function SupportPage() {
  const [formData, setFormData] = useState({
    subject: '',
    category: 'membership',
    message: ''
  });
  
  const [submitting, setSubmitting] = useState(false);
  const [success, setSuccess] = useState(false);
  const [activeFaq, setActiveFaq] = useState(null);

  const handleSubmit = (e) => {
    e.preventDefault();
    setSubmitting(true);
    setTimeout(() => {
      setSubmitting(false);
      setSuccess(true);
      setFormData({ subject: '', category: 'membership', message: '' });
      setTimeout(() => setSuccess(false), 5000);
    }, 800);
  };

  const faqs = [
    {
      q: "How do I earn reward points?",
      a: "Points are earned automatically by attending chapter meetings, posting B2B listings on the marketplace, submitting verified referrals, and completing your business portfolio information."
    },
    {
      q: "Can I redeem my partner discounts on the web portal?",
      a: "No. To protect physical merchants and verify transactions, rewards can only be redeemed using the QR camera scanner inside the PBN Mobile App in person at the merchant's checkout counter."
    },
    {
      q: "How do I join horizontal specialist clubs?",
      a: "Navigate to the Clubs tab and click 'Join'. Note that Horizontal Clubs have vertical alignments; your registered business industry category must match the allowed verticals for that club to join."
    },
    {
      q: "How does the referral matchmaking system work?",
      a: "Our matchmaking engine automatically matches B2B opportunities (Leads and RFPs) shared on the Community feed with members whose business portfolio details align with the requested industry verticals."
    }
  ];

  return (
    <div className="dashboard-body" style={{ position: 'relative', paddingBottom: '4rem' }}>
      <Ds.PageHeader
        title="Support Center"
        description="Submit tickets, get help, or view portal documentation."
      />

      {/* Hero Banner (styled like Event Hero) */}
      <div className="event-hero-v3">
        <div style={{ display: 'flex', flexDirection: 'column', gap: '0.5rem', maxWidth: '80%' }}>
          <div style={{ display: 'flex', alignItems: 'center', gap: '8px' }}>
            <IconHelp size={20} style={{ color: 'var(--brand-amber)' }} />
            <span style={{ fontSize: '0.7rem', fontWeight: 900, color: 'var(--brand-amber)', letterSpacing: '0.15em' }}>PBN HELP DESK</span>
          </div>
          <h3 style={{ fontSize: '1.6rem', fontWeight: 900, color: 'white', letterSpacing: '-0.02em', margin: '4px 0 0 0' }}>
            How can we help you?
          </h3>
          <p style={{ color: 'rgba(255,255,255,0.85)', fontSize: '0.9rem', margin: '4px 0 10px 0', fontWeight: 600 }}>
            Read through our quick guides or submit a support ticket directly to our network administrators.
          </p>
        </div>
      </div>

      {/* Stats Counter / Support channels strip */}
      <div className="event-stats-v3">
        <div className="event-stat-card-v3">
          <div className="event-stat-icon-v3" style={{ background: 'var(--brand-blue-50)', color: 'var(--brand-blue)' }}>
            <IconMail size={18} />
          </div>
          <div className="event-stat-info-v3">
            <span className="event-stat-val-v3" style={{ fontSize: '0.82rem', fontWeight: 800 }}>support@pbn.com</span>
            <span className="event-stat-lbl-v3">Direct Help Desk Email</span>
          </div>
        </div>
        
        <div className="event-stat-card-v3">
          <div className="event-stat-icon-v3" style={{ background: 'rgba(52, 211, 153, 0.1)', color: '#34d399' }}>
            <IconClock size={18} />
          </div>
          <div className="event-stat-info-v3">
            <span className="event-stat-val-v3">&lt; 24 Hours</span>
            <span className="event-stat-lbl-v3">Average Response Time</span>
          </div>
        </div>

        <div className="event-stat-card-v3">
          <div className="event-stat-icon-v3" style={{ background: 'rgba(52, 211, 153, 0.1)', color: '#34d399' }}>
            <IconActivity size={18} />
          </div>
          <div className="event-stat-info-v3">
            <span className="event-stat-val-v3">Operational</span>
            <span className="event-stat-lbl-v3">All Systems Running</span>
          </div>
        </div>
      </div>

      {/* Two Column Layout (Form vs FAQ) */}
      <div style={{ display: 'grid', gridTemplateColumns: 'repeat(auto-fit, minmax(360px, 1fr))', gap: '2rem', marginTop: '2rem' }}>
        
        {/* Contact Form Column */}
        <div>
          <h4 style={{ fontSize: '1.1rem', fontWeight: 900, color: 'var(--fg-primary)', marginBottom: '1.25rem' }}>
            Submit a Ticket
          </h4>
          
          <Ds.Card padded style={{ border: '1px solid var(--border-subtle)' }}>
            {success && (
              <div style={{
                background: 'rgba(52, 211, 153, 0.12)', border: '1px solid rgba(52, 211, 153, 0.25)',
                borderRadius: '12px', color: '#34d399', padding: '1rem', marginBottom: '1.5rem',
                fontSize: '0.82rem', fontWeight: 600, display: 'flex', alignItems: 'center', gap: '8px'
              }}>
                <IconCheck size={18} />
                Support request logged successfully. Our agents will respond to your email.
              </div>
            )}

            <form onSubmit={handleSubmit} style={{ display: 'flex', flexDirection: 'column', gap: '1.25rem' }}>
              <Ds.Field label="Inquiry Category">
                <Ds.Select
                  value={formData.category}
                  onChange={(val) => setFormData({ ...formData, category: val })}
                  options={[
                    { id: 'membership', name: 'Membership Alignment' },
                    { id: 'tech', name: 'Technology & Portal Bug' },
                    { id: 'billing', name: 'Billing & Payments' },
                    { id: 'clubs', name: 'Clubs & Vertical Exceptions' },
                    { id: 'feedback', name: 'General Feedback' }
                  ]}
                  placeholder="Select category…"
                />
              </Ds.Field>

              <Ds.Field label="Subject" hint="Brief title of your request">
                <Ds.Input 
                  type="text" 
                  value={formData.subject}
                  onChange={(e) => setFormData({ ...formData, subject: e.target.value })}
                  placeholder="e.g. Cannot join Horizontal Club"
                  required
                />
              </Ds.Field>

              <Ds.Field label="Describe Your Issue" hint="Please give as much details as possible">
                <Ds.Textarea
                  value={formData.message}
                  onChange={(e) => setFormData({ ...formData, message: e.target.value })}
                  placeholder="Type your message details here..."
                  rows={5}
                  required
                />
              </Ds.Field>

              <Ds.Button
                type="submit"
                variant="primary"
                loading={submitting}
                leftIcon={<IconCheck size={16} />}
              >
                Send Request
              </Ds.Button>
            </form>
          </Ds.Card>
        </div>

        {/* Documentation / FAQ Column */}
        <div>
          <h4 style={{ fontSize: '1.1rem', fontWeight: 900, color: 'var(--fg-primary)', marginBottom: '1.25rem' }}>
            Frequently Asked Questions
          </h4>

          <div style={{ display: 'flex', flexDirection: 'column', gap: '1rem' }}>
            {faqs.map((faq, i) => {
              const isOpen = activeFaq === i;
              return (
                <div 
                  key={i} 
                  style={{
                    background: 'var(--bg-surface)',
                    border: '1px solid var(--border-subtle)',
                    borderRadius: '16px',
                    overflow: 'hidden'
                  }}
                >
                  <button
                    onClick={() => setActiveFaq(isOpen ? null : i)}
                    style={{
                      width: '100%', padding: '1.25rem', background: 'none', border: 'none',
                      display: 'flex', justifyContent: 'space-between', alignItems: 'center',
                      cursor: 'pointer', textAlign: 'left'
                    }}
                  >
                    <span style={{ fontSize: 'var(--text-sm)', fontWeight: 800, color: 'var(--fg-primary)' }}>
                      {faq.q}
                    </span>
                    {isOpen ? <IconChevronUp size={16} color="var(--fg-muted)" /> : <IconChevronDown size={16} color="var(--fg-muted)" />}
                  </button>
                  {isOpen && (
                    <div style={{
                      padding: '0 1.25rem 1.25rem 1.25rem',
                      fontSize: '0.82rem',
                      lineHeight: 1.5,
                      color: 'var(--fg-secondary)',
                      borderTop: '1px solid var(--border-subtle)',
                      paddingTop: '1rem',
                      background: 'var(--bg-canvas)'
                    }}>
                      {faq.a}
                    </div>
                  )}
                </div>
              );
            })}
          </div>
        </div>

      </div>
    </div>
  );
}
