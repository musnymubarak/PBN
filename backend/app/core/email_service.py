import smtplib
import ssl
import logging
import asyncio
from email.mime.text import MIMEText
from email.mime.multipart import MIMEMultipart
from email.mime.base import MIMEBase
from email import encoders
import typing
from email.utils import formatdate, make_msgid
from jinja2 import Environment, FileSystemLoader, select_autoescape
from app.core.config import get_settings

settings = get_settings()
logger = logging.getLogger(__name__)

# Setup Jinja2 environment for HTML templates
templates_dir = "templates"
jinja_env = Environment(
    loader=FileSystemLoader(templates_dir),
    autoescape=select_autoescape(['html', 'xml'])
)

def render_template(template_name: str, context: dict) -> str:
    """Renders an HTML template with the given context."""
    template = jinja_env.get_template(template_name)
    return template.render(context)

async def send_email(to_email: str, subject: str, html_content: str, attachments: typing.Optional[list[dict]] = None, append_to_sent: bool = False, custom_smtp: typing.Optional[dict] = None):
    """Sends an email asynchronously using SMTP."""
    if not custom_smtp and (not settings.SMTP_USER or not settings.SMTP_PASSWORD):
        logger.warning(f"SMTP credentials not fully configured. Skipping email to {to_email}")
        return

    # Run the blocking SMTP operations in a thread to keep it async-friendly
    await asyncio.to_thread(_send_smtp, to_email, subject, html_content, attachments, append_to_sent, custom_smtp)

def _send_smtp(to_email: str, subject: str, html_content: str, attachments: typing.Optional[list[dict]] = None, append_to_sent: bool = False, custom_smtp: typing.Optional[dict] = None):
    """Internal blocking function for sending SMTP email."""
    smtp_host = custom_smtp.get('host') if custom_smtp else settings.SMTP_HOST
    smtp_port = custom_smtp.get('port') if custom_smtp else settings.SMTP_PORT
    smtp_user = custom_smtp.get('user') if custom_smtp else settings.SMTP_USER
    smtp_password = custom_smtp.get('password') if custom_smtp else settings.SMTP_PASSWORD
    from_email = custom_smtp.get('from_email') if custom_smtp else settings.SMTP_FROM_EMAIL
    from_name = custom_smtp.get('from_name') if custom_smtp else settings.SMTP_FROM_NAME

    msg = MIMEMultipart("mixed")
    msg["Subject"] = subject
    msg["From"] = f"{from_name} <{from_email}>"
    msg["To"] = to_email
    msg["Date"] = formatdate(localtime=True)
    msg["Message-ID"] = make_msgid(domain="primebusiness.network")

    # Add plain text fallback to prevent "MIME HTML Only" spam penalty
    plain_text = "To view this message, please use an HTML compatible email client."
    part1 = MIMEText(plain_text, "plain")
    part2 = MIMEText(html_content, "html")
    
    alt_part = MIMEMultipart("alternative")
    alt_part.attach(part1)
    alt_part.attach(part2)
    msg.attach(alt_part)
    
    if attachments:
        for att in attachments:
            ctype = att.get('content_type', 'application/octet-stream')
            maintype, _, subtype = ctype.partition('/')
            part = MIMEBase(maintype, subtype or 'octet-stream')
            part.set_payload(att['content'])
            encoders.encode_base64(part)
            part.add_header("Content-Disposition", f"attachment; filename=\"{att['filename']}\"")
            msg.attach(part)

    try:
        context = ssl.create_default_context()
        
        # Use SMTP_SSL for port 465 (common in cPanel)
        if smtp_port == 465:
            with smtplib.SMTP_SSL(smtp_host, smtp_port, context=context) as server:
                server.login(smtp_user, smtp_password)
                server.sendmail(from_email, to_email, msg.as_string())
        else:
            # For port 587 or others using STARTTLS
            with smtplib.SMTP(smtp_host, smtp_port) as server:
                server.starttls(context=context)
                server.login(smtp_user, smtp_password)
                server.sendmail(from_email, to_email, msg.as_string())
        
        logger.info(f"Successfully sent email to {to_email} with subject: {subject}")
        
        if append_to_sent:
            try:
                import imaplib
                import time
                mail = imaplib.IMAP4_SSL(smtp_host, 993, timeout=10)
                mail.login(smtp_user, smtp_password)
                mail.append('INBOX.Sent', '\\Seen', imaplib.Time2Internaldate(time.time()), msg.as_bytes())
                mail.logout()
            except Exception as e:
                logger.error(f"Failed to append to Sent folder: {e}")
                
    except Exception as e:
        logger.error(f"Failed to send email to {to_email}: {str(e)}")
