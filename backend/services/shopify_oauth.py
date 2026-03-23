"""
CORET Backend — Shopify OAuth Service

Handles OAuth flow: state/nonce management, shop validation,
token exchange, scope verification, and token binding.

Security: CSRF via state+nonce, one-time use, TTL 300s,
idempotent callbacks, standardized error responses.
"""

import hashlib
import hmac
import re
import threading
import time
import uuid

import httpx

from config import settings
from services.security_logger import logger

# ═══ CONSTANTS ═══

SHOP_REGEX = re.compile(r"^[a-zA-Z0-9][a-zA-Z0-9\-]*\.myshopify\.com$")
STATE_TTL = 300  # 5 minutes
TOKEN_EXCHANGE_TIMEOUT = 5.0  # seconds
REQUIRED_SCOPES = {"read_products", "read_product_listings"}

# ═══ STATE STORE ═══
# In-memory, reset on restart. Sufficient for OAuth flows (<60s).

_state_store: dict[str, dict] = {}
_state_lock = threading.Lock()
_shop_rate: dict[str, list[float]] = {}  # shop → [timestamps]
SHOP_RATE_LIMIT = 5  # per hour


def _cleanup_expired():
    """Remove expired states."""
    now = time.time()
    expired = [k for k, v in _state_store.items() if v["expires"] < now]
    for k in expired:
        del _state_store[k]


# ═══ SHOP VALIDATION ═══

def validate_shop(shop: str) -> str | None:
    """Validate and normalize shop domain. Returns cleaned shop or None."""
    if not shop:
        return None
    cleaned = shop.strip().lower()
    if SHOP_REGEX.match(cleaned):
        return cleaned
    return None


# ═══ RATE LIMITING PER SHOP ═══

def check_shop_rate(shop: str) -> bool:
    """Check if shop is within rate limit. Returns True if allowed."""
    now = time.time()
    hour_ago = now - 3600
    timestamps = _shop_rate.get(shop, [])
    timestamps = [t for t in timestamps if t > hour_ago]
    _shop_rate[shop] = timestamps
    if len(timestamps) >= SHOP_RATE_LIMIT:
        return False
    _shop_rate[shop].append(now)
    return True


# ═══ STATE GENERATION ═══

def create_state(shop: str) -> str:
    """Create a state token with nonce for CSRF protection."""
    with _state_lock:
        _cleanup_expired()
        state = uuid.uuid4().hex
        _state_store[state] = {
            "shop": shop,
            "nonce": uuid.uuid4().hex,
            "expires": time.time() + STATE_TTL,
        }
        return state


def build_authorize_url(shop: str, state: str) -> str:
    """Build Shopify OAuth authorize URL."""
    redirect_uri = settings.shopify_redirect_uri
    # HTTPS enforcement in production
    if settings.environment == "production" and not redirect_uri.startswith("https://"):
        raise ValueError("redirect_uri must be HTTPS in production")

    return (
        f"https://{shop}/admin/oauth/authorize"
        f"?client_id={settings.shopify_api_key}"
        f"&scope={settings.shopify_scopes}"
        f"&redirect_uri={redirect_uri}"
        f"&state={state}"
    )


# ═══ STATE VALIDATION ═══

def validate_state(state: str, shop: str) -> dict | None:
    """Validate state token. Returns state data or None.
    One-time use — state is consumed on validation."""
    with _state_lock:
        _cleanup_expired()
        data = _state_store.pop(state, None)  # one-time use
        if not data:
            return None
        if data["shop"] != shop:
            logger.warning("State shop mismatch: expected %s, got %s", data["shop"], shop)
            return None
        return data


# ═══ TOKEN EXCHANGE ═══

class OAuthError(Exception):
    """Internal OAuth error — never exposed to client."""
    pass


async def exchange_code_for_token(shop: str, code: str) -> str:
    """Exchange authorization code for access token.
    Raises OAuthError on failure — caller returns generic message."""
    url = f"https://{shop}/admin/oauth/access_token"
    payload = {
        "client_id": settings.shopify_api_key,
        "client_secret": settings.shopify_api_secret,
        "code": code,
    }

    try:
        async with httpx.AsyncClient() as client:
            response = await client.post(url, json=payload, timeout=TOKEN_EXCHANGE_TIMEOUT)
    except httpx.TimeoutException:
        logger.warning("Token exchange timeout for shop %s", shop)
        raise OAuthError("Token exchange timeout")
    except httpx.RequestError as e:
        logger.warning("Token exchange request error for shop %s: %s", shop, type(e).__name__)
        raise OAuthError("Token exchange failed")

    if response.status_code != 200:
        logger.warning("Token exchange HTTP %d for shop %s", response.status_code, shop)
        raise OAuthError(f"Token exchange returned {response.status_code}")

    data = response.json()
    token = data.get("access_token")
    if not token:
        logger.warning("Token exchange missing access_token for shop %s", shop)
        raise OAuthError("No access_token in response")

    return token


# ═══ SCOPE VERIFICATION ═══

async def verify_scopes(shop: str, token: str) -> bool:
    """Verify granted scopes match required scopes."""
    url = f"https://{shop}/admin/oauth/access_scopes.json"
    headers = {"X-Shopify-Access-Token": token}

    try:
        async with httpx.AsyncClient() as client:
            response = await client.get(url, headers=headers, timeout=5.0)
    except (httpx.TimeoutException, httpx.RequestError):
        return False

    if response.status_code != 200:
        return False

    scopes = {s["handle"] for s in response.json().get("access_scopes", [])}
    return REQUIRED_SCOPES.issubset(scopes)


# ═══ TOKEN BINDING ═══

async def verify_shop_binding(shop: str, token: str) -> bool:
    """Verify token actually belongs to the expected shop."""
    url = f"https://{shop}/admin/api/2024-01/shop.json"
    headers = {"X-Shopify-Access-Token": token}

    try:
        async with httpx.AsyncClient() as client:
            response = await client.get(url, headers=headers, timeout=5.0)
    except (httpx.TimeoutException, httpx.RequestError):
        return False

    if response.status_code != 200:
        return False

    shop_data = response.json().get("shop", {})
    return shop_data.get("myshopify_domain") == shop


# ═══ PREVIEW TOKEN ═══

def generate_preview_token(brand_id: str) -> str:
    """Generate a signed preview token (HMAC, 24h TTL).
    Simple HMAC-based — no JWT dependency needed."""
    expires = int(time.time()) + 86400  # 24 hours
    payload = f"{brand_id}:{expires}"
    secret = settings.shopify_api_secret or "coret-preview-secret"
    signature = hmac.new(secret.encode(), payload.encode(), hashlib.sha256).hexdigest()[:32]
    return f"{payload}:{signature}"


def validate_preview_token(token: str, brand_id: str) -> bool:
    """Validate preview token: correct brand_id + not expired."""
    try:
        parts = token.split(":")
        if len(parts) != 3:
            return False
        token_brand_id, expires_str, signature = parts
        if token_brand_id != brand_id:
            return False
        expires = int(expires_str)
        if time.time() > expires:
            return False
        # Verify signature
        payload = f"{token_brand_id}:{expires_str}"
        secret = settings.shopify_api_secret or "coret-preview-secret"
        expected = hmac.new(secret.encode(), payload.encode(), hashlib.sha256).hexdigest()[:32]
        return hmac.compare_digest(signature, expected)
    except (ValueError, IndexError):
        return False
