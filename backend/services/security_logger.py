"""
CORET Backend — Security Event Logger

Logs security-relevant events: failed auth, invalid webhooks, etc.
NEVER logs token values or secrets.
"""

import logging
from datetime import datetime, timezone

logger = logging.getLogger("coret.security")
logger.setLevel(logging.WARNING)

# Console handler if not already configured
if not logger.handlers:
    handler = logging.StreamHandler()
    handler.setFormatter(logging.Formatter(
        "%(asctime)s [SECURITY] %(levelname)s %(message)s"
    ))
    logger.addHandler(handler)


def log_invalid_api_key(ip: str, path: str):
    """Log invalid or missing API key attempt."""
    logger.warning(
        "Invalid API key from %s on %s at %s",
        ip, path, datetime.now(timezone.utc).isoformat()
    )


def log_failed_webhook_hmac(ip: str):
    """Log failed webhook HMAC validation."""
    logger.warning(
        "Failed webhook HMAC from %s at %s",
        ip, datetime.now(timezone.utc).isoformat()
    )


def log_missing_webhook_topic(ip: str):
    """Log webhook request without X-Shopify-Topic header."""
    logger.warning(
        "Missing X-Shopify-Topic from %s at %s",
        ip, datetime.now(timezone.utc).isoformat()
    )
