"""
Tests for Discover feed endpoints.
"""

import pytest
import services.garment_store as garment_store
import services.wear_log_store as wear_log_store
import services.discover_feed as discover_feed
import services.ghost_catalog as ghost_catalog


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
    yield


async def _seed_wardrobe(client):
    """Create a minimal wardrobe: 2 uppers, 2 lowers, 2 shoes."""
    items = [
        ("Hvit Tee", "upper", "tee", "neutral"),
        ("Navy Skjorte", "upper", "shirt", "cool"),
        ("Morke Jeans", "lower", "jeans", "cool"),
        ("Beige Chinos", "lower", "chinos", "warm"),
        ("Svarte Sneakers", "shoes", "sneakers", "neutral"),
        ("Brune Boots", "shoes", "boots", "warm"),
    ]
    ids = []
    for name, cat, bg, ct in items:
        r = await client.post("/api/garments", json={
            "name": name, "category": cat, "base_group": bg,
            "color_temperature": ct,
        })
        ids.append(r.json()["id"])
    return ids


# ═══ FEED ENDPOINT ═══

@pytest.mark.asyncio
async def test_feed_empty_wardrobe(client):
    """Empty wardrobe returns empty feed."""
    r = await client.get("/api/discover/feed")
    assert r.status_code == 200
    data = r.json()
    assert data["total_cards"] == 0
    assert data["mode"] == "7030"
    assert data["clarity_estimate"] == 0


@pytest.mark.asyncio
async def test_feed_7030_with_garments(client):
    """7030 feed with garments returns cards."""
    await _seed_wardrobe(client)
    r = await client.get("/api/discover/feed?mode=7030")
    assert r.status_code == 200
    data = r.json()
    assert data["total_cards"] > 0
    assert data["total_cards"] <= 20
    assert data["mode"] == "7030"
    # Should have owned cards
    types = {c["feed_type"] for c in data["cards"]}
    assert "owned" in types


@pytest.mark.asyncio
async def test_feed_full_mode(client):
    """Full mode returns ghost cards."""
    await _seed_wardrobe(client)
    r = await client.get("/api/discover/feed?mode=full")
    assert r.status_code == 200
    data = r.json()
    assert data["mode"] == "full"
    # All cards should be ghost type
    for card in data["cards"]:
        assert card["feed_type"] == "ghost"
        assert card["ghost_count"] >= 1


@pytest.mark.asyncio
async def test_feed_invalid_mode(client):
    """Invalid mode rejected."""
    r = await client.get("/api/discover/feed?mode=invalid")
    assert r.status_code == 422


@pytest.mark.asyncio
async def test_feed_card_structure(client):
    """Verify card has all expected fields."""
    await _seed_wardrobe(client)
    r = await client.get("/api/discover/feed")
    data = r.json()
    assert data["total_cards"] > 0
    card = data["cards"][0]
    assert "card_id" in card
    assert "garments" in card
    assert "outfit_name" in card
    assert "brands" in card
    assert "strength" in card
    assert "color_harmony" in card
    assert "archetype_coherence" in card
    assert "feed_type" in card
    assert "owned_count" in card
    assert "ghost_count" in card
    assert "filter_tags" in card
    assert isinstance(card["filter_tags"], list)
    # Each garment should have expected fields
    g = card["garments"][0]
    assert "id" in g
    assert "name" in g
    assert "category" in g
    assert "is_ghost" in g
    assert "available" in g


@pytest.mark.asyncio
async def test_feed_owned_count(client):
    """Owned cards should have owned_count == len(garments)."""
    await _seed_wardrobe(client)
    r = await client.get("/api/discover/feed?mode=7030")
    data = r.json()
    owned_cards = [c for c in data["cards"] if c["feed_type"] == "owned"]
    assert len(owned_cards) > 0
    for card in owned_cards:
        assert card["owned_count"] == len(card["garments"])
        assert card["ghost_count"] == 0


@pytest.mark.asyncio
async def test_feed_max_20_cards(client):
    """Feed never exceeds 20 cards."""
    await _seed_wardrobe(client)
    r = await client.get("/api/discover/feed")
    assert r.json()["total_cards"] <= 20


@pytest.mark.asyncio
async def test_feed_strength_range(client):
    """All card strengths should be 0-1."""
    await _seed_wardrobe(client)
    r = await client.get("/api/discover/feed")
    for card in r.json()["cards"]:
        assert 0 <= card["strength"] <= 1


@pytest.mark.asyncio
async def test_feed_with_season_filter(client):
    """Season filter doesn't crash (garments have no seasons set)."""
    await _seed_wardrobe(client)
    r = await client.get("/api/discover/feed?season=winter")
    assert r.status_code == 200


# ═══ BOOKMARKS ═══

@pytest.mark.asyncio
async def test_bookmark_card(client):
    """Bookmark a card."""
    r = await client.post("/api/discover/bookmark", json={
        "card_id": "test-card-1",
        "garment_ids": ["a", "b", "c"],
        "strength": 0.75,
    })
    assert r.status_code == 200
    assert r.json()["status"] == "bookmarked"


@pytest.mark.asyncio
async def test_bookmark_duplicate(client):
    """Duplicate bookmark returns already_bookmarked."""
    payload = {"card_id": "dup-1", "garment_ids": ["a"], "strength": 0.5}
    await client.post("/api/discover/bookmark", json=payload)
    r = await client.post("/api/discover/bookmark", json=payload)
    assert r.json()["status"] == "already_bookmarked"


@pytest.mark.asyncio
async def test_list_bookmarks(client):
    """List bookmarks returns saved cards."""
    await client.post("/api/discover/bookmark", json={
        "card_id": "bm-1", "garment_ids": ["a"], "strength": 0.5,
    })
    await client.post("/api/discover/bookmark", json={
        "card_id": "bm-2", "garment_ids": ["b"], "strength": 0.8,
    })
    r = await client.get("/api/discover/bookmarks")
    assert r.status_code == 200
    assert r.json()["count"] == 2


@pytest.mark.asyncio
async def test_delete_bookmark(client):
    """Delete a bookmark."""
    await client.post("/api/discover/bookmark", json={
        "card_id": "del-1", "garment_ids": ["a"], "strength": 0.5,
    })
    r = await client.delete("/api/discover/bookmark/del-1")
    assert r.status_code == 200
    assert r.json()["status"] == "removed"
    # Verify gone
    r = await client.get("/api/discover/bookmarks")
    assert r.json()["count"] == 0


@pytest.mark.asyncio
async def test_delete_nonexistent_bookmark(client):
    """Deleting nonexistent bookmark returns 404."""
    r = await client.delete("/api/discover/bookmark/nope")
    assert r.status_code == 404


@pytest.mark.asyncio
async def test_feed_clarity_estimate(client):
    """Feed includes clarity estimate."""
    await _seed_wardrobe(client)
    r = await client.get("/api/discover/feed")
    data = r.json()
    assert 0 <= data["clarity_estimate"] <= 100
    assert "gaps_detected" in data


# ═══ TAG FILTERING ═══

@pytest.mark.asyncio
async def test_feed_tag_filter_returns_matching(client):
    """Tag filter returns only cards with matching tags."""
    await _seed_wardrobe(client)
    # First get unfiltered to see what tags exist
    r = await client.get("/api/discover/feed")
    all_cards = r.json()["cards"]
    assert len(all_cards) > 0
    # Pick a tag from the first card
    first_tags = all_cards[0].get("filter_tags", [])
    if first_tags:
        tag = first_tags[0]
        r = await client.get(f"/api/discover/feed?tags={tag}")
        data = r.json()
        for card in data["cards"]:
            assert tag.lower() in [t.lower() for t in card["filter_tags"]]


@pytest.mark.asyncio
async def test_feed_tag_filter_no_match(client):
    """Tag filter with nonexistent tag returns empty."""
    await _seed_wardrobe(client)
    r = await client.get("/api/discover/feed?tags=nonexistent_tag_xyz")
    assert r.status_code == 200
    assert r.json()["total_cards"] == 0


@pytest.mark.asyncio
async def test_feed_no_tags_returns_all(client):
    """No tags param returns all cards (backwards compatible)."""
    await _seed_wardrobe(client)
    r = await client.get("/api/discover/feed")
    assert r.json()["total_cards"] > 0


@pytest.mark.asyncio
async def test_feed_multiple_tags(client):
    """Multiple comma-separated tags use OR matching."""
    await _seed_wardrobe(client)
    r = await client.get("/api/discover/feed?tags=cool,warm,neutral")
    assert r.status_code == 200
    # Should return cards matching any of the tags
    data = r.json()
    for card in data["cards"]:
        card_tags = {t.lower() for t in card["filter_tags"]}
        assert card_tags & {"cool", "warm", "neutral"}


# ═══ ACTION LOGGING ═══

@pytest.mark.asyncio
async def test_log_like_action(client):
    """Log a like action."""
    r = await client.post("/api/discover/action", json={
        "card_id": "card-1", "action": "like",
    })
    assert r.status_code == 200
    assert r.json()["success"] is True
    assert r.json()["action"] == "like"


@pytest.mark.asyncio
async def test_log_pass_action(client):
    """Log a pass action."""
    r = await client.post("/api/discover/action", json={
        "card_id": "card-2", "action": "pass",
    })
    assert r.status_code == 200
    assert r.json()["action"] == "pass"


@pytest.mark.asyncio
async def test_log_hook_action(client):
    """Log a hook action."""
    r = await client.post("/api/discover/action", json={
        "card_id": "card-3", "action": "hook",
    })
    assert r.status_code == 200
    assert r.json()["action"] == "hook"


@pytest.mark.asyncio
async def test_log_invalid_action(client):
    """Invalid action returns 422."""
    r = await client.post("/api/discover/action", json={
        "card_id": "card-4", "action": "superlike",
    })
    assert r.status_code == 422


@pytest.mark.asyncio
async def test_log_action_with_timestamp(client):
    """Custom timestamp is accepted."""
    r = await client.post("/api/discover/action", json={
        "card_id": "card-5", "action": "like",
        "timestamp": "2026-03-22T12:00:00+00:00",
    })
    assert r.status_code == 200


@pytest.mark.asyncio
async def test_action_stats(client):
    """Stats endpoint returns counts."""
    await client.post("/api/discover/action", json={"card_id": "a", "action": "like"})
    await client.post("/api/discover/action", json={"card_id": "b", "action": "like"})
    await client.post("/api/discover/action", json={"card_id": "c", "action": "pass"})
    await client.post("/api/discover/action", json={"card_id": "d", "action": "hook"})
    r = await client.get("/api/discover/stats")
    assert r.status_code == 200
    data = r.json()
    assert data["total"] == 4
    assert data["like"] == 2
    assert data["pass"] == 1
    assert data["hook"] == 1


@pytest.mark.asyncio
async def test_hook_auto_bookmarks(client):
    """Hook action with garment_ids auto-creates a bookmark."""
    r = await client.post("/api/discover/action", json={
        "card_id": "auto-bm-1", "action": "hook",
        "garment_ids": ["a", "b", "c"], "strength": 0.85,
    })
    assert r.status_code == 200
    assert r.json()["bookmarked"] is True
    # Verify bookmark exists
    r = await client.get("/api/discover/bookmarks")
    assert any(b["card_id"] == "auto-bm-1" for b in r.json()["bookmarks"])


@pytest.mark.asyncio
async def test_seen_cards_not_repeated(client):
    """Second feed request should not repeat same combos."""
    await _seed_wardrobe(client)
    r1 = await client.get("/api/discover/feed")
    cards1 = r1.json()["cards"]
    owned1 = [c for c in cards1 if c["feed_type"] == "owned"]

    r2 = await client.get("/api/discover/feed")
    cards2 = r2.json()["cards"]
    owned2 = [c for c in cards2 if c["feed_type"] == "owned"]

    # Seen combos should be filtered out — second request has fewer or different owned cards
    if owned1:
        ids1 = {tuple(sorted(g["id"] for g in c["garments"])) for c in owned1}
        ids2 = {tuple(sorted(g["id"] for g in c["garments"])) for c in owned2}
        assert ids1 != ids2 or len(owned2) < len(owned1) or len(owned2) == 0


# ═══ BRAND GRID ═══

@pytest.mark.asyncio
async def test_brands_grid_empty(client):
    """No brands returns empty grid."""
    r = await client.get("/api/discover/brands")
    assert r.status_code == 200
    assert r.json()["count"] == 0
    assert r.json()["brands"] == []


@pytest.mark.asyncio
async def test_brands_grid_with_brands(client):
    """Registered brands appear in grid with cover image."""
    # Register brand with cover image
    await client.post("/api/brands/register", json={
        "name": "Nilah", "shopify_domain": "nilah.myshopify.com",
        "access_token": "t1", "cover_image_url": "https://nilah.no/cover.jpg",
    })
    await client.post("/api/brands/register", json={
        "name": "COS", "shopify_domain": "cos.myshopify.com",
        "access_token": "t2",
    })
    r = await client.get("/api/discover/brands")
    assert r.status_code == 200
    data = r.json()
    assert data["count"] == 2
    nilah = next(b for b in data["brands"] if b["name"] == "Nilah")
    assert nilah["cover_image"] == "https://nilah.no/cover.jpg"


@pytest.mark.asyncio
async def test_brands_grid_cover_fallback(client):
    """Without cover_image_url, falls back to first product image."""
    r = await client.post("/api/brands/register", json={
        "name": "COS", "shopify_domain": "cos.myshopify.com", "access_token": "t1",
    })
    brand_id = r.json()["id"]
    # Manually cache a product with an image
    ghost_catalog._save_cached_products(brand_id, [
        {"shopify_id": 1, "title": "Tee", "category": "upper", "base_group": "tee",
         "image_url": "https://cos.com/tee.jpg", "tags": ["basics", "cotton"],
         "vendor": "COS", "style_context": "unisex"},
    ])
    # Update product count
    brands = ghost_catalog._load_brands()
    for b in brands:
        if b["id"] == brand_id:
            b["product_count"] = 1
    ghost_catalog._save_brands(brands)

    r = await client.get("/api/discover/brands")
    cos = r.json()["brands"][0]
    assert cos["cover_image"] == "https://cos.com/tee.jpg"
    assert "basics" in cos["style_tags"]


@pytest.mark.asyncio
async def test_feed_full_with_brand_id(client):
    """Full mode with brand_id filters to that brand only."""
    await _seed_wardrobe(client)
    r = await client.post("/api/brands/register", json={
        "name": "COS", "shopify_domain": "cos.myshopify.com", "access_token": "t1",
    })
    brand_id = r.json()["id"]
    ghost_catalog._save_cached_products(brand_id, [
        {"shopify_id": 1, "title": "COS Sneakers", "category": "shoes", "base_group": "sneakers",
         "color_temperature": "neutral", "vendor": "COS", "style_context": "unisex",
         "price": 999, "available": True, "image_url": None, "tags": []},
    ])
    r = await client.get(f"/api/discover/feed?mode=full&brand_id={brand_id}")
    assert r.status_code == 200
    assert r.json()["mode"] == "full"


@pytest.mark.asyncio
async def test_feed_full_without_brand_id(client):
    """Full mode without brand_id works as before (all brands)."""
    await _seed_wardrobe(client)
    r = await client.get("/api/discover/feed?mode=full")
    assert r.status_code == 200
    assert r.json()["mode"] == "full"


# ═══ MISSING PIECE ═══

@pytest.mark.asyncio
async def test_ghost_card_has_missing_piece(client):
    """Ghost outfit with 1 ghost should have missing_piece."""
    await _seed_wardrobe(client)
    # Register a brand with a product
    r = await client.post("/api/brands/register", json={
        "name": "TestBrand", "shopify_domain": "test.myshopify.com",
        "access_token": "shpat_test",
    })
    brand_id = r.json()["id"]
    ghost_catalog._save_cached_products(brand_id, [
        {"shopify_id": 99, "title": "Test Sneakers", "category": "shoes", "base_group": "sneakers",
         "color_temperature": "neutral", "vendor": "TestBrand", "style_context": "unisex",
         "price": 999, "available": True, "image_url": "https://test.com/shoe.jpg",
         "shop_url": "https://test.com/products/sneakers", "tags": []},
    ])
    r = await client.get(f"/api/discover/feed?mode=full&brand_id={brand_id}")
    data = r.json()
    ghost_cards = [c for c in data["cards"] if c["feed_type"] == "ghost"]
    if ghost_cards:
        card = ghost_cards[0]
        if card.get("ghost_count") == 1 and card.get("owned_count") >= 2:
            assert card["missing_piece"] is not None
            assert "name" in card["missing_piece"]
            assert "base_group" in card["missing_piece"]
            assert "gap_type" in card["missing_piece"]


@pytest.mark.asyncio
async def test_owned_card_missing_piece_is_null(client):
    """Owned outfit should have missing_piece = null."""
    await _seed_wardrobe(client)
    r = await client.get("/api/discover/feed?mode=7030")
    data = r.json()
    owned_cards = [c for c in data["cards"] if c["feed_type"] == "owned"]
    for card in owned_cards:
        assert card.get("missing_piece") is None


@pytest.mark.asyncio
async def test_missing_piece_has_required_fields(client):
    """Missing piece must have name, brand, base_group, gap_type."""
    await _seed_wardrobe(client)
    r = await client.get("/api/discover/feed?mode=7030")
    data = r.json()
    for card in data["cards"]:
        mp = card.get("missing_piece")
        if mp is not None:
            assert "name" in mp
            assert "brand" in mp
            assert "base_group" in mp
            assert "gap_type" in mp
