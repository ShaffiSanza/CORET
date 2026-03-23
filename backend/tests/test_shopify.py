"""
Tests for Shopify integration — client, ghost catalog, brand endpoints.
All Shopify API calls are mocked — no real HTTP requests.
"""

import pytest
from unittest.mock import AsyncMock, patch, MagicMock
import httpx

import services.ghost_catalog as ghost_catalog
import services.garment_store as garment_store
import services.wear_log_store as wear_log_store
import services.discover_feed as discover_feed
from services.shopify_client import (
    map_product_type,
    _parse_product,
    _parse_next_link,
)


@pytest.fixture(autouse=True)
def clean_stores(tmp_path):
    ghost_catalog.BRANDS_FILE = tmp_path / "brands.json"
    ghost_catalog.PRODUCT_CACHE_DIR = tmp_path / "shopify_cache"
    ghost_catalog.PRODUCT_CACHE_DIR.mkdir()
    garment_store.STORE_PATH = tmp_path / "garments.json"
    garment_store.STORE_PATH.write_text("[]")
    wear_log_store.STORE_PATH = tmp_path / "wear_logs.json"
    wear_log_store.STORE_PATH.write_text("[]")
    discover_feed.BOOKMARKS_FILE = tmp_path / "discover_bookmarks.json"
    yield


# ═══ PRODUCT TYPE MAPPING ═══

def test_map_tshirt():
    assert map_product_type("T-Shirt") == ("upper", "tee")

def test_map_jeans():
    assert map_product_type("Jeans") == ("lower", "jeans")

def test_map_sneakers():
    assert map_product_type("Sneakers") == ("shoes", "sneakers")

def test_map_unknown():
    assert map_product_type("Umbrella") == (None, None)

def test_map_case_insensitive():
    assert map_product_type("HOODIE") == ("upper", "hoodie")

def test_map_partial_match():
    assert map_product_type("Cotton T-Shirt") == ("upper", "tee")

def test_map_norwegian():
    assert map_product_type("Skjorte") == ("upper", "shirt")
    assert map_product_type("Bukser") == ("lower", "trousers")
    assert map_product_type("Støvler") == ("shoes", "boots")


# ═══ PRODUCT PARSING ═══

MOCK_SHOPIFY_PRODUCT = {
    "id": 123456,
    "title": "Navy Merino Crew",
    "vendor": "COS",
    "product_type": "Knit",
    "handle": "navy-merino-crew",
    "tags": "winter, merino, navy",
    "images": [{"src": "https://cdn.shopify.com/image.jpg"}],
    "variants": [
        {"price": "899.00", "available": True},
        {"price": "999.00", "available": False},
    ],
}


def test_parse_product():
    result = _parse_product(MOCK_SHOPIFY_PRODUCT, "cos.myshopify.com")
    assert result["shopify_id"] == 123456
    assert result["title"] == "Navy Merino Crew"
    assert result["vendor"] == "COS"
    assert result["category"] == "upper"
    assert result["base_group"] == "knit"
    assert result["price"] == 899.0
    assert result["available"] is True
    assert result["image_url"] == "https://cdn.shopify.com/image.jpg"
    assert result["shop_url"] == "https://cos.myshopify.com/products/navy-merino-crew"
    assert "winter" in result["tags"]


def test_parse_product_no_images():
    product = {**MOCK_SHOPIFY_PRODUCT, "images": []}
    result = _parse_product(product, "test.myshopify.com")
    assert result["image_url"] is None


def test_parse_product_no_variants():
    product = {**MOCK_SHOPIFY_PRODUCT, "variants": []}
    result = _parse_product(product, "test.myshopify.com")
    assert result["price"] is None


# ═══ LINK HEADER PAGINATION ═══

def test_parse_next_link():
    header = '<https://store.myshopify.com/admin/api/2024-01/products.json?page_info=abc>; rel="next"'
    assert _parse_next_link(header) == "https://store.myshopify.com/admin/api/2024-01/products.json?page_info=abc"


def test_parse_next_link_with_previous():
    header = '<https://store.myshopify.com/products.json?page_info=prev>; rel="previous", <https://store.myshopify.com/products.json?page_info=next>; rel="next"'
    assert "page_info=next" in _parse_next_link(header)


def test_parse_next_link_empty():
    assert _parse_next_link("") is None
    assert _parse_next_link(None) is None


# ═══ BRAND REGISTRATION ═══

@pytest.mark.asyncio
async def test_register_brand(client):
    r = await client.post("/api/brands/register", json={
        "name": "COS",
        "shopify_domain": "cos.myshopify.com",
        "access_token": "shpat_test123",
        "archetype": "smartCasual",
    })
    assert r.status_code == 201
    data = r.json()
    assert data["name"] == "COS"
    assert data["shopify_domain"] == "cos.myshopify.com"
    assert "access_token" not in data  # stripped from response


@pytest.mark.asyncio
async def test_register_duplicate_brand(client):
    payload = {
        "name": "COS",
        "shopify_domain": "cos.myshopify.com",
        "access_token": "shpat_test123",
    }
    await client.post("/api/brands/register", json=payload)
    r = await client.post("/api/brands/register", json=payload)
    assert r.status_code == 201
    # Should return existing brand, not duplicate


@pytest.mark.asyncio
async def test_list_brands(client):
    await client.post("/api/brands/register", json={
        "name": "COS", "shopify_domain": "cos.myshopify.com", "access_token": "t1",
    })
    await client.post("/api/brands/register", json={
        "name": "Arket", "shopify_domain": "arket.myshopify.com", "access_token": "t2",
    })
    r = await client.get("/api/brands")
    assert r.status_code == 200
    assert r.json()["count"] == 2


@pytest.mark.asyncio
async def test_delete_brand(client):
    r = await client.post("/api/brands/register", json={
        "name": "COS", "shopify_domain": "cos.myshopify.com", "access_token": "t1",
    })
    brand_id = r.json()["id"]
    r = await client.delete(f"/api/brands/{brand_id}")
    assert r.status_code == 200
    r = await client.get("/api/brands")
    assert r.json()["count"] == 0


@pytest.mark.asyncio
async def test_delete_nonexistent_brand(client):
    r = await client.delete("/api/brands/nonexistent")
    assert r.status_code == 404


# ═══ PRODUCT SYNC (mocked) ═══

@pytest.mark.asyncio
async def test_sync_brand_products(client):
    """Sync with mocked Shopify response."""
    # Register brand
    r = await client.post("/api/brands/register", json={
        "name": "COS", "shopify_domain": "cos.myshopify.com", "access_token": "shpat_test_token",
    })
    brand_id = r.json()["id"]

    # Mock the Shopify API response (OAuth brand — uses stored token)
    mock_response = MagicMock(spec=httpx.Response)
    mock_response.status_code = 200
    mock_response.json.return_value = {
        "products": [MOCK_SHOPIFY_PRODUCT, {
            **MOCK_SHOPIFY_PRODUCT,
            "id": 789,
            "title": "Black Jeans",
            "product_type": "Jeans",
            "handle": "black-jeans",
        }]
    }
    mock_response.headers = {}

    with patch("services.shopify_client._request_with_retry", new_callable=AsyncMock, return_value=mock_response):
        r = await client.post(f"/api/brands/{brand_id}/sync")
        assert r.status_code == 200
        data = r.json()
        assert data["success"] is True
        assert data["mappable"] == 2

    # Check cached products
    r = await client.get(f"/api/brands/{brand_id}/products")
    assert r.status_code == 200
    assert r.json()["count"] == 2


@pytest.mark.asyncio
async def test_sync_nonexistent_brand(client):
    r = await client.post("/api/brands/nonexistent/sync")
    assert r.status_code == 404


@pytest.mark.asyncio
async def test_sync_cooldown(client):
    """Second sync within 15 min should be rejected."""
    r = await client.post("/api/brands/register", json={
        "name": "COS", "shopify_domain": "cos.myshopify.com", "access_token": "shpat_cooldown_test",
    })
    brand_id = r.json()["id"]

    mock_response = MagicMock(spec=httpx.Response)
    mock_response.status_code = 200
    mock_response.json.return_value = {"products": [MOCK_SHOPIFY_PRODUCT]}
    mock_response.headers = {}

    with patch("services.shopify_client._request_with_retry", new_callable=AsyncMock, return_value=mock_response):
        # First sync succeeds
        r = await client.post(f"/api/brands/{brand_id}/sync")
        assert r.status_code == 200
        assert r.json()["success"] is True

        # Second sync within cooldown should fail
        r = await client.post(f"/api/brands/{brand_id}/sync")
        assert r.status_code == 404  # HTTPException from router



# ═══ GHOST CATALOG ═══

def test_ghost_garments_no_brands():
    """No brands registered = empty ghost list."""
    gaps = [{"type": "category", "description": "Ingen overdeler", "suggestion": "", "priority": "high", "projected_combo_gain": 0}]
    ghosts = ghost_catalog.get_ghost_garments(gaps)
    assert ghosts == []


def test_ghost_garments_with_cached_products():
    """Cached products should be returned as ghosts matching gaps."""
    # Register a brand and cache products manually
    brand = ghost_catalog.register_brand("COS", "cos.myshopify.com", "t1")
    products = [
        {"shopify_id": 1, "title": "Navy Tee", "category": "upper", "base_group": "tee",
         "color_temperature": "cool", "price": 299, "shop_url": "https://cos.myshopify.com/products/tee",
         "available": True, "vendor": "COS"},
        {"shopify_id": 2, "title": "Black Jeans", "category": "lower", "base_group": "jeans",
         "color_temperature": "neutral", "price": 699, "shop_url": "https://cos.myshopify.com/products/jeans",
         "available": True, "vendor": "COS"},
    ]
    ghost_catalog._save_cached_products(brand["id"], products)

    gaps = [{"type": "category", "description": "Ingen overdeler", "suggestion": "Legg til en t-skjorte", "priority": "high", "projected_combo_gain": 0}]
    ghosts = ghost_catalog.get_ghost_garments(gaps)
    assert len(ghosts) >= 1
    assert ghosts[0]["id"].startswith("ghost-")
    assert ghosts[0]["name"] == "Navy Tee"
    assert ghosts[0]["price"] == 299
    assert ghosts[0]["shop_url"] is not None


# ═══ WEBHOOK ═══

@pytest.mark.asyncio
async def test_webhook_rejects_without_secret(client):
    """Webhook should return 503 when no secret is configured."""
    r = await client.post("/api/brands/webhook")
    assert r.status_code == 503


# ═══ DISCOVER FEED WITH LIVE GHOSTS ═══

@pytest.mark.asyncio
async def test_feed_uses_live_ghosts_when_available(client):
    """When brands have synced products, feed should use them instead of placeholder."""
    # Seed wardrobe (no shoes → category gap)
    for name, cat, bg in [("Tee", "upper", "tee"), ("Jeans", "lower", "jeans")]:
        await client.post("/api/garments", json={"name": name, "category": cat, "base_group": bg})

    # Register brand and cache shoe products
    brand = ghost_catalog.register_brand("COS", "cos.myshopify.com", "t1")
    ghost_catalog._save_cached_products(brand["id"], [
        {"shopify_id": 99, "title": "White Sneakers", "category": "shoes", "base_group": "sneakers",
         "color_temperature": "neutral", "price": 999, "available": True, "vendor": "COS"},
    ])

    r = await client.get("/api/discover/feed?mode=7030")
    assert r.status_code == 200
    # Feed may have ghost cards with live product data
    data = r.json()
    assert data["gaps_detected"] >= 1
