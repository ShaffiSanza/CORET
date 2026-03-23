"""
Tests for Shopify OAuth onboarding flow.
All Shopify API calls are mocked — no real HTTP requests.
"""

import time
import pytest
from unittest.mock import AsyncMock, patch, MagicMock
import httpx

import services.ghost_catalog as ghost_catalog
import services.shopify_oauth as shopify_oauth
from config import settings
from services.shopify_oauth import (
    validate_shop,
    create_state,
    validate_state,
    check_shop_rate,
    generate_preview_token,
    validate_preview_token,
    SHOP_RATE_LIMIT,
)


@pytest.fixture(autouse=True)
def clean_stores(tmp_path):
    ghost_catalog.BRANDS_FILE = tmp_path / "brands.json"
    ghost_catalog.PRODUCT_CACHE_DIR = tmp_path / "shopify_cache"
    ghost_catalog.PRODUCT_CACHE_DIR.mkdir()
    ghost_catalog.BRAND_SECRETS_FILE = tmp_path / "brand_secrets.json"
    # Reset state store between tests
    shopify_oauth._state_store.clear()
    shopify_oauth._shop_rate.clear()
    yield


# ═══ SHOP VALIDATION ═══

def test_valid_shop_domain():
    assert validate_shop("nilah.myshopify.com") == "nilah.myshopify.com"

def test_shop_domain_stripped_lowercased():
    assert validate_shop("  Nilah.Myshopify.Com  ") == "nilah.myshopify.com"

def test_invalid_shop_domain_rejected():
    assert validate_shop("not-a-shopify-url.com") is None
    assert validate_shop("") is None
    assert validate_shop("evil.com/admin") is None
    assert validate_shop(".myshopify.com") is None

def test_shop_domain_regex():
    assert validate_shop("my-store-123.myshopify.com") == "my-store-123.myshopify.com"
    assert validate_shop("-invalid.myshopify.com") is None


# ═══ STATE MANAGEMENT ═══

def test_state_created_and_validated():
    state = create_state("test.myshopify.com")
    data = validate_state(state, "test.myshopify.com")
    assert data is not None
    assert data["shop"] == "test.myshopify.com"

def test_state_one_time_use():
    state = create_state("test.myshopify.com")
    validate_state(state, "test.myshopify.com")
    # Second use should fail
    assert validate_state(state, "test.myshopify.com") is None

def test_state_shop_mismatch_rejected():
    state = create_state("real.myshopify.com")
    assert validate_state(state, "fake.myshopify.com") is None

def test_expired_state_rejected():
    state = create_state("test.myshopify.com")
    # Manually expire
    shopify_oauth._state_store[state]["expires"] = time.time() - 1
    assert validate_state(state, "test.myshopify.com") is None

def test_invalid_state_returns_none():
    assert validate_state("nonexistent", "test.myshopify.com") is None


# ═══ RATE LIMITING PER SHOP ═══

def test_rate_limit_per_shop():
    shop = "nilah.myshopify.com"
    for _ in range(SHOP_RATE_LIMIT):
        assert check_shop_rate(shop) is True
    assert check_shop_rate(shop) is False  # exceeded


# ═══ PREVIEW TOKEN ═══

@pytest.fixture(autouse=False)
def with_api_secret(monkeypatch):
    """Set shopify_api_secret for preview token tests."""
    monkeypatch.setattr(settings, "shopify_api_secret", "test-secret-key")

def test_preview_token_valid(with_api_secret):
    token = generate_preview_token("brand-123")
    assert validate_preview_token(token, "brand-123") is True

def test_preview_token_wrong_brand_rejected(with_api_secret):
    token = generate_preview_token("brand-123")
    assert validate_preview_token(token, "brand-456") is False

def test_preview_token_expired(with_api_secret):
    # Create token, then manually test with expired time
    token = generate_preview_token("brand-123")
    parts = token.split(":")
    # Set expiry to past
    expired_token = f"{parts[0]}:{int(time.time()) - 1}:{parts[2]}"
    assert validate_preview_token(expired_token, "brand-123") is False

def test_preview_token_tampered(with_api_secret):
    token = generate_preview_token("brand-123")
    tampered = token[:-1] + ("a" if token[-1] != "a" else "b")
    assert validate_preview_token(tampered, "brand-123") is False

def test_preview_token_raises_without_secret():
    """generate_preview_token should raise when shopify_api_secret is empty."""
    with pytest.raises(ValueError, match="shopify_api_secret must be configured"):
        generate_preview_token("brand-123")


# ═══ OAUTH ENDPOINTS ═══

@pytest.mark.asyncio
async def test_oauth_invalid_shop_rejected(client):
    r = await client.get("/api/auth/shopify?shop=not-valid.com")
    assert r.status_code == 422

@pytest.mark.asyncio
async def test_oauth_redirect_contains_state(client):
    r = await client.get("/api/auth/shopify?shop=nilah.myshopify.com", follow_redirects=False)
    assert r.status_code == 307  # redirect
    location = r.headers.get("location", "")
    assert "state=" in location
    assert "nilah.myshopify.com" in location

@pytest.mark.asyncio
async def test_callback_rejects_invalid_state(client):
    r = await client.get("/api/auth/shopify/callback?code=test&shop=nilah.myshopify.com&state=invalid")
    assert r.status_code == 400
    assert "avbrutt" in r.json()["detail"].lower()

@pytest.mark.asyncio
async def test_callback_returns_generic_error_on_exchange_fail(client):
    """OAuth errors should never expose internals."""
    state = create_state("nilah.myshopify.com")

    with patch("routers.auth.exchange_code_for_token", new_callable=AsyncMock, side_effect=shopify_oauth.OAuthError("secret error")):
        r = await client.get(f"/api/auth/shopify/callback?code=test&shop=nilah.myshopify.com&state={state}")
        assert r.status_code == 400
        data = r.json()
        assert "secret" not in data.get("detail", "").lower()
        assert "prov" in data.get("detail", "").lower() or "prøv" in data.get("detail", "").lower()

@pytest.mark.asyncio
async def test_preview_requires_token(client):
    """Preview without token should be rejected."""
    r = await client.get("/api/brands/nonexistent/preview")
    assert r.status_code == 422  # missing required param

@pytest.mark.asyncio
async def test_preview_rejects_wrong_brand_token(client, with_api_secret):
    """Preview token scoped to wrong brand should be rejected."""
    token = generate_preview_token("other-brand-id")
    r = await client.get(f"/api/brands/real-brand-id/preview?preview_token={token}")
    assert r.status_code == 403

@pytest.mark.asyncio
async def test_token_not_in_api_response(client):
    """Brand registration should never expose token."""
    r = await client.post("/api/brands/register", json={
        "name": "Test", "shopify_domain": "test.myshopify.com",
        "access_token": "shpat_secret",
    })
    data = r.json()
    assert "access_token" not in data
    assert "shpat_secret" not in str(data)
