"""
Tests for outfit graph engine (V1.5 smart suggestions).
"""

import pytest
from services.outfit_graph import suggest_outfits
import services.garment_store as store


def _g(id, name, category, base_group, color_temp="neutral", silhouette=None, seasons=None):
    d = {
        "id": id, "name": name, "category": category,
        "base_group": base_group, "color_temperature": color_temp,
        "import_source": "manual", "image_url": None,
    }
    if silhouette:
        d["silhouette"] = silhouette
    if seasons:
        d["seasons"] = seasons
    return d


# ═══ Empty / Edge Cases ═══

def test_empty_wardrobe():
    assert suggest_outfits([]) == []


def test_missing_category():
    garments = [_g("u1", "Tee", "upper", "tee")]
    assert suggest_outfits(garments) == []


def test_single_combo():
    garments = [
        _g("u1", "Tee", "upper", "tee"),
        _g("l1", "Jeans", "lower", "jeans"),
        _g("s1", "Sneakers", "shoes", "sneakers"),
    ]
    results = suggest_outfits(garments, count=5)
    assert len(results) == 1
    assert results[0]["garment_ids"] == ["u1", "l1", "s1"]
    assert 0 <= results[0]["strength"] <= 1


# ═══ Count Limiting ═══

def test_count_limits():
    garments = [
        _g("u1", "Tee", "upper", "tee"),
        _g("u2", "Shirt", "upper", "shirt"),
        _g("u3", "Knit", "upper", "knit"),
        _g("l1", "Jeans", "lower", "jeans"),
        _g("l2", "Chinos", "lower", "chinos"),
        _g("s1", "Sneakers", "shoes", "sneakers"),
        _g("s2", "Boots", "shoes", "boots"),
    ]
    results = suggest_outfits(garments, count=3)
    assert len(results) == 3


# ═══ Ranking ═══

def test_sorted_by_strength():
    garments = [
        _g("u1", "Tee", "upper", "tee", "warm"),
        _g("u2", "Shirt", "upper", "shirt", "warm"),
        _g("l1", "Jeans", "lower", "jeans", "warm"),
        _g("l2", "Chinos", "lower", "chinos", "cool"),
        _g("s1", "Sneakers", "shoes", "sneakers", "warm"),
    ]
    results = suggest_outfits(garments, count=4)
    strengths = [r["strength"] for r in results]
    assert strengths == sorted(strengths, reverse=True)


# ═══ No Duplicates ═══

def test_no_duplicate_combos():
    garments = [
        _g("u1", "Tee", "upper", "tee"),
        _g("u2", "Shirt", "upper", "shirt"),
        _g("l1", "Jeans", "lower", "jeans"),
        _g("s1", "Sneakers", "shoes", "sneakers"),
    ]
    results = suggest_outfits(garments, count=5)
    id_sets = [tuple(sorted(r["garment_ids"])) for r in results]
    assert len(id_sets) == len(set(id_sets))


# ═══ API Integration ═══

@pytest.fixture(autouse=True)
def clean_store(tmp_path):
    test_store = tmp_path / "garments.json"
    test_store.write_text("[]", encoding="utf-8")
    store.STORE_PATH = test_store
    yield


@pytest.mark.asyncio
async def test_api_suggest_empty(client):
    response = await client.get("/api/wardrobe/suggest")
    assert response.status_code == 200
    data = response.json()
    assert data["suggestions"] == []
    assert data["count"] == 0


@pytest.mark.asyncio
async def test_api_suggest_with_garments(client):
    await client.post("/api/garments", json={"name": "Tee", "category": "upper", "base_group": "tee"})
    await client.post("/api/garments", json={"name": "Jeans", "category": "lower", "base_group": "jeans"})
    await client.post("/api/garments", json={"name": "Sneakers", "category": "shoes", "base_group": "sneakers"})

    response = await client.get("/api/wardrobe/suggest?count=3")
    assert response.status_code == 200
    data = response.json()
    assert data["count"] == 1
    assert len(data["suggestions"]) == 1
    assert 0 <= data["suggestions"][0]["strength"] <= 1
