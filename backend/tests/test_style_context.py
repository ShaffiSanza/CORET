"""
Tests for style_context — profile, filtering, inference.
"""

import pytest
import services.garment_store as garment_store
import services.wear_log_store as wear_log_store
import services.discover_feed as discover_feed
import services.ghost_catalog as ghost_catalog
import services.user_profile as user_profile
from services.shopify_client import _infer_style_context
from services.ghost_catalog import _filter_by_style


@pytest.fixture(autouse=True)
def clean_stores(tmp_path):
    garment_store.STORE_PATH = tmp_path / "garments.json"
    garment_store.STORE_PATH.write_text("[]")
    wear_log_store.STORE_PATH = tmp_path / "wear_logs.json"
    wear_log_store.STORE_PATH.write_text("[]")
    discover_feed.BOOKMARKS_FILE = tmp_path / "discover_bookmarks.json"
    discover_feed.ACTIONS_FILE = tmp_path / "discover_actions.json"
    discover_feed.SEEN_FILE = tmp_path / "discover_seen.json"
    ghost_catalog.BRANDS_FILE = tmp_path / "brands.json"
    ghost_catalog.PRODUCT_CACHE_DIR = tmp_path / "shopify_cache"
    ghost_catalog.PRODUCT_CACHE_DIR.mkdir()
    user_profile.PROFILE_FILE = tmp_path / "user_profile.json"
    yield


# ═══ STYLE CONTEXT INFERENCE ═══

def test_infer_menswear_from_tags():
    assert _infer_style_context(["men", "winter"], "Navy Blazer") == "menswear"

def test_infer_womenswear_from_tags():
    assert _infer_style_context(["women", "summer"], "Silk Blouse") == "womenswear"

def test_infer_unisex_default():
    assert _infer_style_context(["winter"], "Cotton Tee") == "unisex"

def test_infer_unisex_explicit():
    assert _infer_style_context(["unisex", "basics"], "Tee") == "unisex"

def test_infer_both_tags_equals_unisex():
    assert _infer_style_context(["men", "women"], "Shared Jacket") == "unisex"

def test_infer_norwegian_herre():
    assert _infer_style_context(["herre", "klassisk"], "Dress") == "menswear"

def test_infer_norwegian_dame():
    assert _infer_style_context(["dame"], "Kjole") == "womenswear"

def test_infer_from_title():
    assert _infer_style_context([], "Men's Oxford Shirt") == "menswear"

def test_infer_womens_from_title():
    assert _infer_style_context([], "Women's Silk Top") == "womenswear"


# ═══ PRODUCT FILTERING ═══

def test_filter_menswear_sees_menswear_and_unisex():
    products = [
        {"shopify_id": 1, "style_context": "menswear"},
        {"shopify_id": 2, "style_context": "womenswear"},
        {"shopify_id": 3, "style_context": "unisex"},
    ]
    result = _filter_by_style(products, "menswear")
    ids = {p["shopify_id"] for p in result}
    assert ids == {1, 3}


def test_filter_womenswear_sees_womenswear_and_unisex():
    products = [
        {"shopify_id": 1, "style_context": "menswear"},
        {"shopify_id": 2, "style_context": "womenswear"},
        {"shopify_id": 3, "style_context": "unisex"},
    ]
    result = _filter_by_style(products, "womenswear")
    ids = {p["shopify_id"] for p in result}
    assert ids == {2, 3}


def test_filter_unisex_sees_all():
    products = [
        {"shopify_id": 1, "style_context": "menswear"},
        {"shopify_id": 2, "style_context": "womenswear"},
        {"shopify_id": 3, "style_context": "unisex"},
    ]
    result = _filter_by_style(products, "unisex")
    assert len(result) == 3


def test_filter_fluid_sees_all():
    products = [
        {"shopify_id": 1, "style_context": "menswear"},
        {"shopify_id": 2, "style_context": "womenswear"},
    ]
    result = _filter_by_style(products, "fluid")
    assert len(result) == 2


# ═══ PROFILE ENDPOINTS ═══

@pytest.mark.asyncio
async def test_get_default_profile(client):
    r = await client.get("/api/profile")
    assert r.status_code == 200
    data = r.json()
    assert data["style_context"] == "unisex"
    assert data["archetype"] == "smartCasual"


@pytest.mark.asyncio
async def test_update_profile_style_context(client):
    r = await client.put("/api/profile", json={"style_context": "menswear"})
    assert r.status_code == 200
    assert r.json()["style_context"] == "menswear"
    # Verify persisted
    r = await client.get("/api/profile")
    assert r.json()["style_context"] == "menswear"


@pytest.mark.asyncio
async def test_update_profile_partial(client):
    """Partial update only changes provided fields."""
    await client.put("/api/profile", json={"style_context": "womenswear"})
    r = await client.put("/api/profile", json={"archetype": "tailored"})
    data = r.json()
    assert data["style_context"] == "womenswear"  # unchanged
    assert data["archetype"] == "tailored"


# ═══ FEED WITH STYLE_CONTEXT ═══

async def _seed(client):
    for name, cat, bg in [("Tee", "upper", "tee"), ("Jeans", "lower", "jeans"), ("Sneakers", "shoes", "sneakers")]:
        await client.post("/api/garments", json={"name": name, "category": cat, "base_group": bg})


@pytest.mark.asyncio
async def test_feed_accepts_style_context_param(client):
    await _seed(client)
    r = await client.get("/api/discover/feed?style_context=menswear")
    assert r.status_code == 200


@pytest.mark.asyncio
async def test_feed_uses_profile_style_context(client):
    """Feed defaults to profile style_context when no param given."""
    await _seed(client)
    await client.put("/api/profile", json={"style_context": "womenswear"})
    r = await client.get("/api/discover/feed")
    assert r.status_code == 200


@pytest.mark.asyncio
async def test_feed_param_overrides_profile(client):
    """Explicit param overrides profile setting."""
    await _seed(client)
    await client.put("/api/profile", json={"style_context": "womenswear"})
    r = await client.get("/api/discover/feed?style_context=menswear")
    assert r.status_code == 200


# ═══ GHOST FILTERING WITH CACHED PRODUCTS ═══

def test_ghost_garments_filtered_by_style():
    """Menswear user should not see womenswear ghost products."""
    brand = ghost_catalog.register_brand("TestBrand", "test.myshopify.com", "t1")
    ghost_catalog._save_cached_products(brand["id"], [
        {"shopify_id": 1, "title": "Men's Boots", "category": "shoes", "base_group": "boots",
         "style_context": "menswear", "vendor": "Test"},
        {"shopify_id": 2, "title": "Women's Heels", "category": "shoes", "base_group": "loafers",
         "style_context": "womenswear", "vendor": "Test"},
        {"shopify_id": 3, "title": "Unisex Sneakers", "category": "shoes", "base_group": "sneakers",
         "style_context": "unisex", "vendor": "Test"},
    ])

    gaps = [{"type": "category", "description": "Ingen sko", "suggestion": "Legg til sko", "priority": "high", "projected_combo_gain": 0}]

    # Menswear: should see boots + sneakers, not heels
    ghosts = ghost_catalog.get_ghost_garments(gaps, style_context="menswear")
    names = {g["name"] for g in ghosts}
    assert "Men's Boots" in names
    assert "Unisex Sneakers" in names
    assert "Women's Heels" not in names

    # Womenswear: should see heels + sneakers, not boots
    ghosts = ghost_catalog.get_ghost_garments(gaps, style_context="womenswear")
    names = {g["name"] for g in ghosts}
    assert "Women's Heels" in names
    assert "Unisex Sneakers" in names
    assert "Men's Boots" not in names

    # Fluid: should see all
    ghosts = ghost_catalog.get_ghost_garments(gaps, style_context="fluid")
    assert len(ghosts) == 3
