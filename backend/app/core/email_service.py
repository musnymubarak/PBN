import smtplib
import ssl
import logging
import asyncio
from email.mime.text import MIMEText
from email.mime.multipart import MIMEMultipart
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

async def send_email(to_email: str, subject: str, html_content: str):
    """Sends an email asynchronously using SMTP."""
    if not settings.SMTP_USER or not settings.SMTP_PASSWORD:
        logger.warning(f"SMTP credentials not fully configured. Skipping email to {to_email}")
        return

    # Run the blocking SMTP operations in a thread to keep it async-friendly
    await asyncio.to_thread(_send_smtp, to_email, subject, html_content)

def _send_smtp(to_email: str, subject: str, html_content: str):
    """Internal blocking function for sending SMTP email."""
    msg = MIMEMultipart("alternative")
    msg["Subject"] = subject
    msg["From"] = f"{settings.SMTP_FROM_NAME} <{settings.SMTP_FROM_EMAIL}>"
    msg["To"] = to_email
    msg["Date"] = formatdate(localtime=True)
    msg["Message-ID"] = make_msgid(domain="primebusiness.network")

    # Add plain text fallback to prevent "MIME HTML Only" spam penalty
    plain_text = "To view this message, please use an HTML compatible email client."
    part1 = MIMEText(plain_text, "plain")
    part2 = MIMEText(html_content, "html")
    
    msg.attach(part1)
    msg.attach(part2)

    try:
        context = ssl.create_default_context()
        
        # Use SMTP_SSL for port 465 (common in cPanel)
        if settings.SMTP_PORT == 465:
            with smtplib.SMTP_SSL(settings.SMTP_HOST, settings.SMTP_PORT, context=context) as server:
                server.login(settings.SMTP_USER, settings.SMTP_PASSWORD)
                server.sendmail(settings.SMTP_FROM_EMAIL, to_email, msg.as_string())
        else:
            # For port 587 or others using STARTTLS
            with smtplib.SMTP(settings.SMTP_HOST, settings.SMTP_PORT) as server:
                server.starttls(context=context)
                server.login(settings.SMTP_USER, settings.SMTP_PASSWORD)
                server.sendmail(settings.SMTP_FROM_EMAIL, to_email, msg.as_string())
        
        logger.info(f"Successfully sent email to {to_email} with subject: {subject}")
    except Exception as e:
        logger.error(f"Failed to send email to {to_email}: {str(e)}")
