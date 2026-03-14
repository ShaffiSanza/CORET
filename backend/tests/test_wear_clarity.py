"""
Tests for wear logging and clarity history endpoints.
"""

import pytest
import services.garment_store as garment_store
import services.wear_log_store as wear_store
import services.clarity_tracker as clarity_tracker


@pytest.fixture(autouse=True)
def clean_stores(tmp_path):
    garment_store.STORE_PATH = tmp_path / "garments.json"
    garment_store.STORE_PATH.write_text("[]")
    wear_store.STORE_PATH = tmp_path / "wear_logs.json"
    wear_store.STORE_PATH.write_text("[]")
    clarity_tracker.STORE_PATH = tmp_path / "clarity_history.json"
    clarity_tracker.STORE_PATH.write_text("[]")
    yield


# ═══ WEAR LOGGING ═══

@pytest.mark.asyncio
async def test_log_wear(client):
    r = await client.post("/api/garments", json={"name": "Tee", "category": "upper", "base_group": "tee"})
    gid = r.json()["id"]

    r = await client.post(f"/api/garments/{gid}/wear")
    assert r.status_code == 201
    assert r.json()["garment_id"] == gid


@pytest.mark.asyncio
async def test_log_wear_with_date(client):
    r = await client.post("/api/garments", json={"name": "Tee", "category": "upper", "base_group": "tee"})
    gid = r.json()["id"]

    r = await client.post(f"/api/garments/{gid}/wear", json={"date": "2026-03-01T10:00:00Z"})
    assert r.status_code == 201
    assert "2026-03-01" in r.json()["date"]


@pytest.mark.asyncio
async def test_log_wear_not_found(client):
    r = await client.post("/api/garments/nope/wear")
    assert r.status_code == 404


@pytest.mark.asyncio
async def test_get_garment_wears(client):
    r = await client.post("/api/garments", json={"name": "Tee", "category": "upper", "base_group": "tee"})
    gid = r.json()["id"]

    await client.post(f"/api/garments/{gid}/wear")
    await client.post(f"/api/garments/{gid}/wear")
    await client.post(f"/api/garments/{gid}/wear")

    r = await client.get(f"/api/garments/{gid}/wears")
    assert r.status_code == 200
    assert r.json()["total_wears"] == 3
    assert r.json()["count"] == 3


@pytest.mark.asyncio
async def test_get_wears_not_found(client):
    r = await client.get("/api/garments/nope/wears")
    assert r.status_code == 404


@pytest.mark.asyncio
async def test_get_wears_empty(client):
    r = await client.post("/api/garments", json={"name": "Tee", "category": "upper", "base_group": "tee"})
    gid = r.json()["id"]

    r = await client.get(f"/api/garments/{gid}/wears")
    assert r.json()["total_wears"] == 0


# ═══ CLARITY HISTORY ═══

@pytest.mark.asyncio
async def test_clarity_snapshot(client):
    r = await client.post("/api/clarity/snapshot")
    assert r.status_code == 201
    data = r.json()
    assert "score" in data
    assert "created_at" in data


@pytest.mark.asyncio
async def test_clarity_history_empty(client):
    r = await client.get("/api/clarity/history")
    assert r.status_code == 200
    data = r.json()
    assert data["snapshots"] == []
    assert data["trend"] == "stable"


@pytest.mark.asyncio
async def test_clarity_history_with_snapshots(client):
    await client.post("/api/clarity/snapshot")

    # Add garments to change score
    await client.post("/api/garments", json={"name": "Tee", "category": "upper", "base_group": "tee"})
    await client.post("/api/garments", json={"name": "Jeans", "category": "lower", "base_group": "jeans"})
    await client.post("/api/garments", json={"name": "Sneakers", "category": "shoes", "base_group": "sneakers"})

    await client.post("/api/clarity/snapshot")

    r = await client.get("/api/clarity/history")
    data = r.json()
    assert len(data["snapshots"]) == 2
    assert data["current_score"] >= 0


@pytest.mark.asyncio
async def test_clarity_trend_improving(client):
    # First snapshot: empty wardrobe = 0
    await client.post("/api/clarity/snapshot")

    # Add garments
    await client.post("/api/garments", json={"name": "Tee", "category": "upper", "base_group": "tee"})
    await client.post("/api/garments", json={"name": "Jeans", "category": "lower", "base_group": "jeans"})
    await client.post("/api/garments", json={"name": "Sneakers", "category": "shoes", "base_group": "sneakers"})

    # Second snapshot: should be higher
    await client.post("/api/clarity/snapshot")

    r = await client.get("/api/clarity/history")
    data = r.json()
    assert data["trend"] == "improving"
