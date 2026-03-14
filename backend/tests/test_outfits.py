"""
Tests for outfit CRUD endpoints.
"""

import pytest
import services.garment_store as garment_store
import services.outfit_store as outfit_store


@pytest.fixture(autouse=True)
def clean_stores(tmp_path):
    garment_store.STORE_PATH = tmp_path / "garments.json"
    garment_store.STORE_PATH.write_text("[]")
    outfit_store.STORE_PATH = tmp_path / "outfits.json"
    outfit_store.STORE_PATH.write_text("[]")
    yield


async def _create_garments(client):
    """Helper: create 3 garments, return IDs."""
    ids = []
    for name, cat, bg in [("Tee", "upper", "tee"), ("Jeans", "lower", "jeans"), ("Sneakers", "shoes", "sneakers")]:
        r = await client.post("/api/garments", json={"name": name, "category": cat, "base_group": bg})
        ids.append(r.json()["id"])
    return ids


@pytest.mark.asyncio
async def test_create_outfit(client):
    ids = await _create_garments(client)
    r = await client.post("/api/outfits", json={"garment_ids": ids, "label": "Casual"})
    assert r.status_code == 201
    data = r.json()
    assert data["label"] == "Casual"
    assert len(data["garment_ids"]) == 3
    assert data["garment_names"] == ["Tee", "Jeans", "Sneakers"]


@pytest.mark.asyncio
async def test_list_outfits(client):
    ids = await _create_garments(client)
    await client.post("/api/outfits", json={"garment_ids": ids, "label": "A"})
    await client.post("/api/outfits", json={"garment_ids": ids[:2], "label": "B"})

    r = await client.get("/api/outfits")
    assert r.status_code == 200
    assert r.json()["count"] == 2


@pytest.mark.asyncio
async def test_get_outfit(client):
    ids = await _create_garments(client)
    create = await client.post("/api/outfits", json={"garment_ids": ids})
    oid = create.json()["id"]

    r = await client.get(f"/api/outfits/{oid}")
    assert r.status_code == 200
    assert len(r.json()["garment_ids"]) == 3


@pytest.mark.asyncio
async def test_update_outfit(client):
    ids = await _create_garments(client)
    create = await client.post("/api/outfits", json={"garment_ids": ids, "label": ""})
    oid = create.json()["id"]

    r = await client.put(f"/api/outfits/{oid}", json={"label": "Vinterstruktur"})
    assert r.status_code == 200
    assert r.json()["label"] == "Vinterstruktur"


@pytest.mark.asyncio
async def test_delete_outfit(client):
    ids = await _create_garments(client)
    create = await client.post("/api/outfits", json={"garment_ids": ids})
    oid = create.json()["id"]

    r = await client.delete(f"/api/outfits/{oid}")
    assert r.status_code == 200
    assert (await client.get(f"/api/outfits/{oid}")).status_code == 404


@pytest.mark.asyncio
async def test_outfit_not_found(client):
    assert (await client.get("/api/outfits/nope")).status_code == 404
    assert (await client.put("/api/outfits/nope", json={"label": "x"})).status_code == 404
    assert (await client.delete("/api/outfits/nope")).status_code == 404


@pytest.mark.asyncio
async def test_outfit_with_score(client):
    ids = await _create_garments(client)
    r = await client.post("/api/outfits", json={"garment_ids": ids, "score": 0.84})
    assert r.json()["score"] == 0.84
