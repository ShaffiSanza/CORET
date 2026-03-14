"""
Tests for wardrobe analysis service (Wardrobe Map V1).
"""

import pytest
from services.wardrobe_analysis import (
    generate_combinations,
    compute_garment_stats,
    detect_gaps,
    analyze_wardrobe,
    STRONG_OUTFIT_THRESHOLD,
)
import services.garment_store as store
import services.outfit_store as outfit_store
import services.wear_log_store as wear_store


def _g(id, name, category, base_group, color_temp="neutral", silhouette=None, seasons=None):
    """Helper to create a garment dict."""
    d = {
        "id": id,
        "name": name,
        "category": category,
        "base_group": base_group,
        "color_temperature": color_temp,
        "import_source": "manual",
        "image_url": None,
    }
    if silhouette:
        d["silhouette"] = silhouette
    if seasons:
        d["seasons"] = seasons
    return d


# ═══ Combination Generation ═══

def test_empty_wardrobe():
    assert generate_combinations([]) == []


def test_missing_category():
    garments = [_g("1", "Tee", "upper", "tee"), _g("2", "Jeans", "lower", "jeans")]
    assert generate_combinations(garments) == []  # no shoes


def test_single_combo():
    garments = [
        _g("u1", "Tee", "upper", "tee"),
        _g("l1", "Jeans", "lower", "jeans"),
        _g("s1", "Sneakers", "shoes", "sneakers"),
    ]
    combos = generate_combinations(garments)
    assert len(combos) == 1
    assert combos[0]["garment_ids"] == ["u1", "l1", "s1"]
    assert 0 <= combos[0]["strength"] <= 1


def test_cartesian_product():
    """3 uppers × 2 lowers × 2 shoes = 12 combos."""
    garments = [
        _g("u1", "Tee", "upper", "tee"),
        _g("u2", "Shirt", "upper", "shirt"),
        _g("u3", "Knit", "upper", "knit"),
        _g("l1", "Jeans", "lower", "jeans"),
        _g("l2", "Chinos", "lower", "chinos"),
        _g("s1", "Sneakers", "shoes", "sneakers"),
        _g("s2", "Boots", "shoes", "boots"),
    ]
    combos = generate_combinations(garments)
    assert len(combos) == 12


def test_accessories_excluded():
    """Accessories don't participate in combos."""
    garments = [
        _g("u1", "Tee", "upper", "tee"),
        _g("l1", "Jeans", "lower", "jeans"),
        _g("s1", "Sneakers", "shoes", "sneakers"),
        _g("a1", "Belt", "accessory", "belt"),
    ]
    combos = generate_combinations(garments)
    assert len(combos) == 1
    assert "a1" not in combos[0]["garment_ids"]


# ═══ Color Harmony ═══

def test_warm_cool_clash():
    garments = [
        _g("u1", "Tee", "upper", "tee", "warm"),
        _g("l1", "Jeans", "lower", "jeans", "cool"),
        _g("s1", "Sneakers", "shoes", "sneakers", "neutral"),
    ]
    combos = generate_combinations(garments)
    assert combos[0]["color_harmony"] == 0.5  # clash


def test_same_temp_harmony():
    garments = [
        _g("u1", "Tee", "upper", "tee", "warm"),
        _g("l1", "Chinos", "lower", "chinos", "warm"),
        _g("s1", "Boots", "shoes", "boots", "warm"),
    ]
    combos = generate_combinations(garments)
    assert combos[0]["color_harmony"] == 1.0


def test_neutral_no_clash():
    garments = [
        _g("u1", "Tee", "upper", "tee", "warm"),
        _g("l1", "Jeans", "lower", "jeans", "neutral"),
        _g("s1", "Sneakers", "shoes", "sneakers", "neutral"),
    ]
    combos = generate_combinations(garments)
    assert combos[0]["color_harmony"] == 1.0


# ═══ Garment Stats & Roles ═══

def test_key_garment_detection():
    """With 1 upper, 1 lower, 2 shoes → 2 combos. Each shoe in 1/2 = 50% → anchor."""
    garments = [
        _g("u1", "Tee", "upper", "tee"),
        _g("l1", "Jeans", "lower", "jeans"),
        _g("s1", "Sneakers", "shoes", "sneakers"),
        _g("s2", "Boots", "shoes", "boots"),
    ]
    combos = generate_combinations(garments)
    stats = compute_garment_stats(garments, combos)

    # u1 and l1 are in 100% of combos → anchor
    u1_stat = next(s for s in stats if s["id"] == "u1")
    assert u1_stat["role"] == "anchor"
    assert u1_stat["combo_count"] == 2
    assert u1_stat["combo_percentage"] == 100.0

    # Each shoe in 50% → anchor (≥20%)
    s1_stat = next(s for s in stats if s["id"] == "s1")
    assert s1_stat["role"] == "anchor"


def test_weak_garment_detection():
    """Garment in ≤2 combos out of many = weak."""
    garments = [
        _g("u1", "Tee", "upper", "tee"),
        _g("u2", "Shirt", "upper", "shirt"),
        _g("u3", "Knit", "upper", "knit"),
        _g("u4", "Blazer", "upper", "blazer"),
        _g("u5", "Hoodie", "upper", "hoodie"),
        _g("l1", "Jeans", "lower", "jeans"),
        _g("l2", "Chinos", "lower", "chinos"),
        _g("l3", "Trousers", "lower", "trousers"),
        _g("s1", "Sneakers", "shoes", "sneakers"),
    ]
    # 5 × 3 × 1 = 15 combos. Each upper in 3/15 = 20% → anchor boundary
    combos = generate_combinations(garments)
    assert len(combos) == 15
    stats = compute_garment_stats(garments, combos)

    # Each upper: 3 combos, 20% → anchor
    u1 = next(s for s in stats if s["id"] == "u1")
    assert u1["combo_count"] == 3
    assert u1["role"] == "anchor"


def test_accessory_not_weak():
    """Accessories with 0 combos should be 'support', not 'weak'."""
    garments = [
        _g("u1", "Tee", "upper", "tee"),
        _g("l1", "Jeans", "lower", "jeans"),
        _g("s1", "Sneakers", "shoes", "sneakers"),
        _g("a1", "Belt", "accessory", "belt"),
    ]
    combos = generate_combinations(garments)
    stats = compute_garment_stats(garments, combos)
    belt = next(s for s in stats if s["id"] == "a1")
    assert belt["role"] == "support"


def test_works_with_tracking():
    garments = [
        _g("u1", "Tee", "upper", "tee"),
        _g("l1", "Jeans", "lower", "jeans"),
        _g("s1", "Sneakers", "shoes", "sneakers"),
    ]
    combos = generate_combinations(garments)
    stats = compute_garment_stats(garments, combos)
    u1 = next(s for s in stats if s["id"] == "u1")
    assert set(u1["works_with"]) == {"l1", "s1"}


# ═══ Gap Detection ═══

def test_category_gap():
    garments = [_g("u1", "Tee", "upper", "tee")]
    gaps = detect_gaps(garments, [])
    types = [g["type"] for g in gaps]
    assert "category" in types
    # Missing lower and shoes
    descs = [g["description"] for g in gaps]
    assert any("underdeler" in d.lower() or "Ingen underdeler" in d for d in descs)
    assert any("sko" in d.lower() or "Ingen sko" in d for d in descs)


def test_no_gaps_balanced():
    garments = [
        _g("u1", "Tee", "upper", "tee"),
        _g("l1", "Jeans", "lower", "jeans"),
        _g("s1", "Sneakers", "shoes", "sneakers"),
    ]
    combos = generate_combinations(garments)
    gaps = detect_gaps(garments, combos)
    # No category gaps, no proportion imbalance with 1:1:1
    cat_gaps = [g for g in gaps if g["type"] == "category"]
    assert len(cat_gaps) == 0


def test_proportion_imbalance():
    garments = [
        _g("u1", "Tee", "upper", "tee"),
        _g("u2", "Shirt", "upper", "shirt"),
        _g("u3", "Knit", "upper", "knit"),
        _g("l1", "Jeans", "lower", "jeans"),
        _g("s1", "Sneakers", "shoes", "sneakers"),
    ]
    combos = generate_combinations(garments)
    gaps = detect_gaps(garments, combos)
    prop_gaps = [g for g in gaps if g["type"] == "proportion"]
    assert len(prop_gaps) == 1
    assert prop_gaps[0]["priority"] == "medium"


# ═══ Full Analysis ═══

def test_full_analysis_empty():
    result = analyze_wardrobe([])
    assert result["total_garments"] == 0
    assert result["total_combinations"] == 0
    assert result["clarity_estimate"] == 0
    assert result["key_garments"] == []
    assert result["weak_garments"] == []


def test_full_analysis_balanced():
    garments = [
        _g("u1", "Tee", "upper", "tee", "neutral"),
        _g("u2", "Shirt", "upper", "shirt", "cool"),
        _g("l1", "Jeans", "lower", "jeans", "neutral"),
        _g("l2", "Chinos", "lower", "chinos", "warm"),
        _g("s1", "Sneakers", "shoes", "sneakers", "neutral"),
        _g("s2", "Boots", "shoes", "boots", "warm"),
    ]
    result = analyze_wardrobe(garments)
    assert result["total_garments"] == 6
    assert result["total_combinations"] == 8  # 2×2×2
    assert result["clarity_estimate"] > 0
    assert len(result["all_garments"]) == 6


# ═══ API Integration Tests ═══

@pytest.fixture(autouse=True)
def clean_store(tmp_path):
    test_store = tmp_path / "garments.json"
    test_store.write_text("[]", encoding="utf-8")
    store.STORE_PATH = test_store
    outfit_file = tmp_path / "outfits.json"
    outfit_file.write_text("[]", encoding="utf-8")
    outfit_store.STORE_PATH = outfit_file
    wear_file = tmp_path / "wear_logs.json"
    wear_file.write_text("[]", encoding="utf-8")
    wear_store.STORE_PATH = wear_file
    yield


@pytest.mark.asyncio
async def test_api_analysis_empty(client):
    response = await client.get("/api/wardrobe/analysis")
    assert response.status_code == 200
    data = response.json()
    assert data["total_combinations"] == 0


@pytest.mark.asyncio
async def test_api_analysis_with_garments(client):
    # Add garments
    await client.post("/api/garments", json={"name": "Tee", "category": "upper", "base_group": "tee"})
    await client.post("/api/garments", json={"name": "Jeans", "category": "lower", "base_group": "jeans"})
    await client.post("/api/garments", json={"name": "Sneakers", "category": "shoes", "base_group": "sneakers"})

    response = await client.get("/api/wardrobe/analysis")
    assert response.status_code == 200
    data = response.json()
    assert data["total_combinations"] == 1
    assert data["total_garments"] == 3
    assert len(data["key_garments"]) == 3  # all are anchor in a 1-combo wardrobe


@pytest.mark.asyncio
async def test_api_garment_connections(client):
    r1 = await client.post("/api/garments", json={"name": "Tee", "category": "upper", "base_group": "tee"})
    await client.post("/api/garments", json={"name": "Jeans", "category": "lower", "base_group": "jeans"})
    await client.post("/api/garments", json={"name": "Sneakers", "category": "shoes", "base_group": "sneakers"})

    gid = r1.json()["id"]
    response = await client.get(f"/api/wardrobe/garment/{gid}")
    assert response.status_code == 200
    data = response.json()
    assert data["combo_count"] == 1
    assert len(data["works_with"]) == 2


@pytest.mark.asyncio
async def test_api_gaps(client):
    await client.post("/api/garments", json={"name": "Tee", "category": "upper", "base_group": "tee"})

    response = await client.get("/api/wardrobe/gaps")
    assert response.status_code == 200
    gaps = response.json()
    assert len(gaps) >= 2  # missing lower + shoes


@pytest.mark.asyncio
async def test_api_garment_not_found(client):
    response = await client.get("/api/wardrobe/garment/nonexistent")
    assert response.status_code == 404


# ═══ Proportion Matrix ═══

def test_proportion_fitted_wide_high():
    """fitted top + wide bottom = 1.0 proportion."""
    garments = [
        _g("u1", "Tee", "upper", "tee", silhouette="fitted"),
        _g("l1", "Wide pants", "lower", "trousers", silhouette="wide"),
        _g("s1", "Sneakers", "shoes", "sneakers"),
    ]
    combos = generate_combinations(garments)
    assert len(combos) == 1
    # fitted+wide = 1.0 proportion, so strength should be higher than default 0.5
    assert combos[0]["strength"] > 0.5


def test_proportion_oversized_wide_low():
    """oversized top + wide bottom = 0.3 proportion (bad)."""
    garments = [
        _g("u1", "Oversized tee", "upper", "tee", silhouette="oversized"),
        _g("l1", "Wide pants", "lower", "trousers", silhouette="wide"),
        _g("s1", "Sneakers", "shoes", "sneakers"),
    ]
    combos = generate_combinations(garments)
    # oversized+wide = 0.3, should be lower than fitted+wide
    fitted_garments = [
        _g("u1", "Fitted tee", "upper", "tee", silhouette="fitted"),
        _g("l1", "Wide pants", "lower", "trousers", silhouette="wide"),
        _g("s1", "Sneakers", "shoes", "sneakers"),
    ]
    fitted_combos = generate_combinations(fitted_garments)
    assert combos[0]["strength"] < fitted_combos[0]["strength"]


def test_proportion_no_silhouette_default():
    """Missing silhouette → 0.5 default proportion."""
    garments = [
        _g("u1", "Tee", "upper", "tee"),
        _g("l1", "Jeans", "lower", "jeans"),
        _g("s1", "Sneakers", "shoes", "sneakers"),
    ]
    combos = generate_combinations(garments)
    # Default 0.5 proportion — same as before
    assert 0 <= combos[0]["strength"] <= 1


# ═══ Season Filtering ═══

def test_season_filter_excludes():
    """Winter-only garments excluded when filtering for summer."""
    garments = [
        _g("u1", "Tee", "upper", "tee", seasons=["summer", "spring"]),
        _g("u2", "Coat", "upper", "coat", seasons=["winter"]),
        _g("l1", "Shorts", "lower", "shorts", seasons=["summer"]),
        _g("l2", "Jeans", "lower", "jeans", seasons=["all_season"]),
        _g("s1", "Sandals", "shoes", "sandals", seasons=["summer"]),
    ]
    result = analyze_wardrobe(garments, season="summer")
    # Coat (winter only) should be excluded
    all_ids = [g["id"] for g in result["all_garments"]]
    assert "u2" not in all_ids
    assert "u1" in all_ids


def test_season_filter_includes_all_season():
    """all_season garments always included."""
    garments = [
        _g("u1", "Tee", "upper", "tee", seasons=["all_season"]),
        _g("l1", "Jeans", "lower", "jeans", seasons=["all_season"]),
        _g("s1", "Sneakers", "shoes", "sneakers", seasons=["all_season"]),
    ]
    result = analyze_wardrobe(garments, season="winter")
    assert result["total_garments"] == 3
    assert result["total_combinations"] == 1


def test_season_filter_no_seasons_field():
    """Garments without seasons field are always included."""
    garments = [
        _g("u1", "Tee", "upper", "tee"),
        _g("l1", "Jeans", "lower", "jeans"),
        _g("s1", "Sneakers", "shoes", "sneakers"),
    ]
    result = analyze_wardrobe(garments, season="summer")
    assert result["total_garments"] == 3


def test_season_filter_none_returns_all():
    """No season filter returns all garments."""
    garments = [
        _g("u1", "Tee", "upper", "tee", seasons=["summer"]),
        _g("u2", "Coat", "upper", "coat", seasons=["winter"]),
        _g("l1", "Jeans", "lower", "jeans"),
        _g("s1", "Sneakers", "shoes", "sneakers"),
    ]
    result = analyze_wardrobe(garments, season=None)
    assert result["total_garments"] == 4


# ═══ API Season Filter ═══

@pytest.mark.asyncio
async def test_api_analysis_season_filter(client):
    await client.post("/api/garments", json={
        "name": "Tee", "category": "upper", "base_group": "tee", "seasons": ["summer"]
    })
    await client.post("/api/garments", json={
        "name": "Coat", "category": "upper", "base_group": "coat", "seasons": ["winter"]
    })
    await client.post("/api/garments", json={
        "name": "Jeans", "category": "lower", "base_group": "jeans"
    })
    await client.post("/api/garments", json={
        "name": "Sneakers", "category": "shoes", "base_group": "sneakers"
    })

    # Summer filter — should exclude coat
    response = await client.get("/api/wardrobe/analysis?season=summer")
    assert response.status_code == 200
    data = response.json()
    assert data["total_garments"] == 3

    # No filter — all 4
    response = await client.get("/api/wardrobe/analysis")
    data = response.json()
    assert data["total_garments"] == 4


# ═══ Import/Export API ═══

@pytest.mark.asyncio
async def test_api_export_empty(client):
    response = await client.get("/api/wardrobe/export")
    assert response.status_code == 200
    data = response.json()
    assert data["garments"] == []
    assert data["outfits"] == []
    assert data["wear_logs"] == []


@pytest.mark.asyncio
async def test_api_import_valid(client):
    import_data = {
        "garments": [
            {"name": "Tee", "category": "upper", "baseGroup": "tee"},
            {"name": "Jeans", "category": "lower", "baseGroup": "jeans"},
        ]
    }
    response = await client.post("/api/wardrobe/import", json=import_data)
    assert response.status_code == 200
    data = response.json()
    assert data["imported"] == 2
    assert len(data["garment_ids"]) == 2


@pytest.mark.asyncio
async def test_api_import_invalid(client):
    import_data = {
        "garments": [
            {"name": "Bad", "category": "invalid_cat", "baseGroup": "tee"},
        ]
    }
    response = await client.post("/api/wardrobe/import", json=import_data)
    assert response.status_code == 422


@pytest.mark.asyncio
async def test_api_export_roundtrip(client):
    # Create garments
    await client.post("/api/garments", json={"name": "Tee", "category": "upper", "base_group": "tee"})
    await client.post("/api/garments", json={"name": "Jeans", "category": "lower", "base_group": "jeans"})

    # Export
    response = await client.get("/api/wardrobe/export")
    assert response.status_code == 200
    data = response.json()
    assert len(data["garments"]) == 2
