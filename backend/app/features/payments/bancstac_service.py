"""
Prime Business Network – Bancstac (Paycenter) API Service.
"""

from __future__ import annotations

import hmac
import hashlib
import uuid
from datetime import datetime, timezone
import logging
from typing import Any, Dict, Optional
import httpx

from app.core.config import get_settings

logger = logging.getLogger(__name__)

def generate_hmac_signature(payload: str, secret: str) -> str:
    """Generate HMAC-SHA256 signature of request payload in hexadecimal.
    
    Bancstac requires requests to be signed using the HMAC-SHA256 algorithm
    with the merchant's HMAC Secret key.
    """
    return hmac.new(
        secret.encode("utf-8"),
        payload.encode("utf-8"),
        hashlib.sha256
    ).hexdigest()

class BancstacService:
    def __init__(self):
        self.settings = get_settings()
        self.client_id = self.settings.BANCSTAC_CLIENT_ID
        self.auth_token = self.settings.BANCSTAC_AUTH_TOKEN
        self.hmac_secret = self.settings.BANCSTAC_HMAC_SECRET
        self.api_url = self.settings.BANCSTAC_API_URL

    def _get_headers(self, payload_str: str) -> Dict[str, str]:
        """Build headers required by Bancstac API, including Bearer token and HMAC signature."""
        sig = generate_hmac_signature(payload_str, self.hmac_secret)
        return {
            "Content-Type": "application/json",
            "authtoken": self.auth_token,
            "hmac": sig,
            "Cache-Control": "no-cache",
        }

    async def initiate_payment(
        self,
        amount: int,  # Amount in cents/cents-equivalent (LKR cents or LKR units based on environment)
        payment_id: str,
        payment_type: str,
        return_url: Optional[str] = None,
        cancel_url: Optional[str] = None,
    ) -> Dict[str, Any]:
        """Call Bancstac's PAYMENT_INIT operation to get a payment page URL."""
        # Clean URLs or use defaults
        ret_url = return_url or self.settings.BANCSTAC_RETURN_URL
        can_url = cancel_url or self.settings.BANCSTAC_CANCEL_URL

        # Prepare request structure according to Paycenter Technical Guideline (Page 11-12)
        request_date = datetime.now(timezone.utc).strftime("%Y-%m-%dT%H:%M:%S.000+0000")
        msg_id = str(uuid.uuid4()).upper()

        payload = {
            "version": "1.5",
            "msgId": msg_id,
            "operation": "PAYMENT_INIT",
            "requestDate": request_date,
            "validateOnly": False,
            "requestData": {
                "clientId": self.client_id,
                "clientIdHash": "",
                "transactionType": "PURCHASE",
                "transactionAmount": {
                    "totalAmount": amount,  # Min 200 in test environment
                    "paymentAmount": 0,
                    "serviceFeeAmount": 0,
                    "currency": "LKR"
                },
                "redirect": {
                    "returnUrl": ret_url,
                    "cancelUrl": can_url,
                    "returnMethod": "GET"
                },
                "clientRef": f"PBN-{payment_id}",
                "comment": f"PBN {payment_type.upper()} Payment",
                "tokenize": False,
                "useReliability": True,
                "extraData": {
                    "payment_id": payment_id,
                    "payment_type": payment_type
                }
            }
        }

        # Convert to compact JSON string for HMAC signature and transmission
        import json
        payload_str = json.dumps(payload, separators=(',', ':'))
        headers = self._get_headers(payload_str)

        logger.info(f"Bancstac PAYMENT_INIT request: msgId={msg_id}, clientRef=PBN-{payment_id}, amount={amount}")

        async with httpx.AsyncClient(timeout=15.0) as client:
            try:
                resp = await client.post(self.api_url, content=payload_str, headers=headers)
                resp.raise_for_status()
                res_data = resp.json()
                
                # Check for errors in the response body
                if "error" in res_data or ("responseData" not in res_data and "message" in res_data):
                    error_msg = res_data.get("message") or res_data.get("error", "Unknown error")
                    logger.error(f"Bancstac PAYMENT_INIT API error: {error_msg}")
                    raise Exception(f"Bancstac Error: {error_msg}")
                
                response_data = res_data.get("responseData", {})
                req_id = response_data.get("reqid")
                payment_page_url = response_data.get("paymentPageUrl")

                if not req_id or not payment_page_url:
                    logger.error(f"Bancstac PAYMENT_INIT returned empty reqid or paymentPageUrl. Response: {res_data}")
                    raise Exception("Bancstac initialization response incomplete")

                return {
                    "req_id": req_id,
                    "payment_page_url": payment_page_url,
                }

            except httpx.HTTPError as e:
                logger.error(f"HTTP request to Bancstac failed: {e}")
                raise Exception(f"Failed to connect to payment gateway: {e}")

    async def complete_payment(self, req_id: str) -> Dict[str, Any]:
        """Call Bancstac's PAYMENT_COMPLETE operation to finalize transaction and retrieve status."""
        request_date = datetime.now(timezone.utc).strftime("%Y-%m-%dT%H:%M:%S.000+0000")
        msg_id = str(uuid.uuid4()).upper()

        payload = {
            "version": "1.5",
            "msgId": msg_id,
            "operation": "PAYMENT_COMPLETE",
            "requestDate": request_date,
            "validateOnly": False,
            "requestData": {
                "clientId": self.client_id,
                "reqid": req_id
            }
        }

        import json
        payload_str = json.dumps(payload, separators=(',', ':'))
        headers = self._get_headers(payload_str)

        logger.info(f"Bancstac PAYMENT_COMPLETE request: msgId={msg_id}, reqid={req_id}")

        async with httpx.AsyncClient(timeout=15.0) as client:
            try:
                resp = await client.post(self.api_url, content=payload_str, headers=headers)
                resp.raise_for_status()
                res_data = resp.json()
                
                if "error" in res_data or ("responseData" not in res_data and "message" in res_data):
                    error_msg = res_data.get("message") or res_data.get("error", "Unknown error")
                    logger.error(f"Bancstac PAYMENT_COMPLETE API error: {error_msg}")
                    raise Exception(f"Bancstac Complete Error: {error_msg}")
                
                response_data = res_data.get("responseData", {})
                return response_data

            except httpx.HTTPError as e:
                logger.error(f"HTTP request to Bancstac failed: {e}")
                raise Exception(f"Failed to verify payment status: {e}")
