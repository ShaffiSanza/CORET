"""
Tests for security hardening.
"""

import pytest
import services.garment_store as garment_store
import services.ghost_catalog as ghost_catalog
import services.user_profile as user_profile
import services.discover_feed as discover_feed
import services.wear_log_store as wear_log_store


@pytest.fixture(autouse=True)
def clean_stores(tmp_path):
    garment_store.STORE_PATH = tmp_path / "garments.json"
    garment_store.STORE_PATH.write_text("[]")
    ghost_catalog.BRANDS_FILE = tmp_path / "brands.json"
    ghost_catalog.PRODUCT_CACHE_DIR = tmp_path / "shopify_cache"
    ghost_catalog.PRODUCT_CACHE_DIR.mkdir()
    ghost_catalog.BRAND_SECRETS_FILE = tmp_path / "brand_secrets.json"
    user_profile.PROFILE_FILE = tmp_path / "user_profile.json"
    wear_log_store.STORE_PATH = tmp_path / "wear_logs.json"
    wear_log_store.STORE_PATH.write_text("[]")
    discover_feed.BOOKMARKS_FILE = tmp_path / "discover_bookmarks.json"
    discover_feed.ACTIONS_FILE = tmp_path / "discover_actions.json"
    discover_feed.SEEN_FILE = tmp_path / "discover_seen.json"
    yield


# ═══ SECURITY HEADERS ═══

@pytest.mark.asyncio
async def test_security_headers_present(client):
    """All responses should have security headers."""
    r = await client.get("/api/health")
    assert r.headers.get("X-Content-Type-Options") == "nosniff"
    assert r.headers.get("X-Frame-Options") == "DENY"
    assert "max-age=31536000" in r.headers.get("Strict-Transport-Security", "")
    assert "preload" in r.headers.get("Strict-Transport-Security", "")
    assert r.headers.get("X-XSS-Protection") == "1; mode=block"
    assert "default-src" in r.headers.get("Content-Security-Policy", "")


# ═══ TOKEN NOT IN BRANDS.JSON ═══

@pytest.mark.asyncio
async def test_token_not_in_brands_json(client):
    """Shopify token should NOT be stored in brands.json."""
    r = await client.post("/api/brands/register", json={
        "name": "SecureTest", "shopify_domain": "secure.myshopify.com",
        "access_token": "shpat_secret123",
    })
    assert r.status_code == 201

    # Read brands.json directly — token should NOT be there
    import json
    brands = json.loads(ghost_catalog.BRANDS_FILE.read_text())
    for brand in brands:
        assert "access_token" not in brand, "Token must not be in brands.json"


@pytest.mark.asyncio
async def test_token_in_secrets_file(client):
    """Token should be in separate secrets file."""
    r = await client.post("/api/brands/register", json={
        "name": "SecureTest2", "shopify_domain": "secure2.myshopify.com",
        "access_token": "shpat_secret456",
    })
    brand_id = r.json()["id"]

    # Secrets file should have the token
    import json
    secrets = json.loads(ghost_catalog.BRAND_SECRETS_FILE.read_text())
    assert brand_id in secrets
    assert secrets[brand_id] == "shpat_secret456"


@pytest.mark.asyncio
async def test_token_not_in_api_response(client):
    """API response should never contain access_token."""
    r = await client.post("/api/brands/register", json={
        "name": "NoTokenResp", "shopify_domain": "notok.myshopify.com",
        "access_token": "shpat_hidden",
    })
    data = r.json()
    assert "access_token" not in data


@pytest.mark.asyncio
async def test_delete_brand_cleans_secrets(client):
    """Deleting brand should remove token from secrets."""
    r = await client.post("/api/brands/register", json={
        "name": "DeleteMe", "shopify_domain": "del.myshopify.com",
        "access_token": "shpat_todelete",
    })
    brand_id = r.json()["id"]
    await client.delete(f"/api/brands/{brand_id}")

    import json
    secrets = json.loads(ghost_catalog.BRAND_SECRETS_FILE.read_text())
    assert brand_id not in secrets


# ═══ INPUT VALIDATION ═══

@pytest.mark.asyncio
async def test_garment_name_too_long(client):
    """Garment name over 100 chars should be rejected."""
    r = await client.post("/api/garments", json={
        "name": "X" * 101, "category": "upper", "base_group": "tee",
    })
    assert r.status_code == 422


@pytest.mark.asyncio
async def test_garment_name_stripped(client):
    """Whitespace should be stripped from name."""
    r = await client.post("/api/garments", json={
        "name": "  Navy Tee  ", "category": "upper", "base_group": "tee",
    })
    assert r.status_code == 201
    assert r.json()["name"] == "Navy Tee"


@pytest.mark.asyncio
async def test_brand_name_too_long(client):
    """Brand name over 100 chars should be rejected."""
    r = await client.post("/api/brands/register", json={
        "name": "B" * 101, "shopify_domain": "long.myshopify.com",
        "access_token": "t1",
    })
    assert r.status_code == 422


# ═══ WEBHOOK HMAC ═══

@pytest.mark.asyncio
async def test_webhook_accepts_without_secret(client):
    """Without configured secret, webhook should still accept."""
    r = await client.post("/api/brands/webhook",
                          headers={"X-Shopify-Topic": "products/update"},
                          content=b'{}')
    assert r.status_code == 200


@pytest.mark.asyncio
async def test_webhook_logs_missing_topic(client):
    """Webhook without X-Shopify-Topic should still work (V1) but is logged."""
    r = await client.post("/api/brands/webhook", content=b'{}')
    assert r.status_code == 200
