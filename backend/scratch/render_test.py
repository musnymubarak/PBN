import os
import sys

# Ensure backend directory is in the import path
sys.path.append(os.path.dirname(os.path.dirname(os.path.abspath(__file__))))

from app.core.email_service import render_template

def test_render():
    os.makedirs("scratch/output", exist_ok=True)
    
    # Common test context data
    base_contexts = {
        "application_received.html": {
            "full_name": "John Doe",
            "business_name": "Acme Corp"
        },
        "application_approved.html": {
            "full_name": "Jane Smith",
            "business_name": "Globex Corporation",
            "has_missing_fields": True,
            "onboarding_url": "https://primebusiness.network/onboard?token=testtoken",
            "email": "jane@globex.com",
            "password": "temporary_password_123",
            "play_store_url": "https://play.google.com/store/apps/details?id=network.primebusiness.app",
            "app_store_url": "https://apps.apple.com/us/app/prime-business-network/id6772060160"
        },
        "application_rejected.html": {
            "full_name": "Bob Johnson",
            "business_name": "Initech Inc.",
            "reason": "Business model does not align with our current focus area."
        },
        "fit_call_scheduled.html": {
            "full_name": "Alice Williams",
            "business_name": "Umbrella Corp",
            "fit_call_date": "Monday, June 1st at 10:00 AM UTC"
        },
        "otp_email.html": {
            "otp": "489210"
        },
        "2fa_otp_email.html": {
            "otp": "123456"
        }
    }
    
    # Render with defaults
    print("Rendering with default signature...")
    for template_name, context in base_contexts.items():
        try:
            rendered = render_template(template_name, context)
            output_path = f"scratch/output/default_{template_name}"
            with open(output_path, "w", encoding="utf-8") as f:
                f.write(rendered)
            print(f"  Saved {template_name} to {output_path}")
        except Exception as e:
            print(f"  Error rendering {template_name} (default): {e}")

    # Render with custom sender context (e.g. Ilham Safeek)
    print("\nRendering with custom signature (Ilham Safeek)...")
    custom_signature_context = {
        "sender_name": "Ilham Safeek",
        "sender_title": "Managing Director, VP of Strategy",
        "sender_email": "ilham@primebusiness.network",
        "sender_phone": "+94 777 140 803"
    }
    
    for template_name, context in base_contexts.items():
        # Merge context
        merged_context = {**context, **custom_signature_context}
        try:
            rendered = render_template(template_name, merged_context)
            output_path = f"scratch/output/custom_{template_name}"
            with open(output_path, "w", encoding="utf-8") as f:
                f.write(rendered)
            print(f"  Saved {template_name} to {output_path}")
        except Exception as e:
            print(f"  Error rendering {template_name} (custom): {e}")

if __name__ == "__main__":
    test_render()
