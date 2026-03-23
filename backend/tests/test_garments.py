"""
Tests for garment CRUD endpoints.
"""

import json
import pytest
from pathlib import Path

# Override store path before importing anything that uses it
import services.garment_store as store


@pytest.fixture(autouse=True)
def clean_store(tmp_path):
    """Use a temporary store file for each test."""
    test_store = tmp_path / "garments.json"
    test_store.write_text("[]", encoding="utf-8")
    store.STORE_PATH = test_store
    yield
    # Cleanup happens automatically with tmp_path


SAMPLE_GARMENT = {
    "name": "Navy Skjorte",
    "category": "upper",
    "base_group": "shirt",
    "color_temperature": "cool",
    "dominant_color": "#2C3E50",
    "silhouette": "fitted",
    "import_source": "manual",
}


@pytest.mark.asyncio
async def test_create_garment(client):
    response = await client.post("/api/garments", json=SAMPLE_GARMENT)
    assert response.status_code == 201
    data = response.json()
    assert data["name"] == "Navy Skjorte"
    assert data["category"] == "upper"
    assert data["base_group"] == "shirt"
    assert data["id"]  # UUID assigned


@pytest.mark.asyncio
async def test_list_garments_empty(client):
    response = await client.get("/api/garments")
    assert response.status_code == 200
    data = response.json()
    assert data["count"] == 0
    assert data["garments"] == []


@pytest.mark.asyncio
async def test_list_garments_with_items(client):
    await client.post("/api/garments", json=SAMPLE_GARMENT)
    await client.post("/api/garments", json={
        **SAMPLE_GARMENT, "name": "Hvit T-shirt", "base_group": "tee"
    })
    response = await client.get("/api/garments")
    data = response.json()
    assert data["count"] == 2


@pytest.mark.asyncio
async def test_get_garment(client):
    create = await client.post("/api/garments", json=SAMPLE_GARMENT)
    gid = create.json()["id"]

    response = await client.get(f"/api/garments/{gid}")
    assert response.status_code == 200
    assert response.json()["name"] == "Navy Skjorte"


@pytest.mark.asyncio
async def test_get_garment_not_found(client):
    response = await client.get("/api/garments/00000000-0000-0000-0000-000000000000")
    assert response.status_code == 404


@pytest.mark.asyncio
async def test_update_garment(client):
    create = await client.post("/api/garments", json=SAMPLE_GARMENT)
    gid = create.json()["id"]

    response = await client.put(f"/api/garments/{gid}", json={"name": "Dark Navy Skjorte"})
    assert response.status_code == 200
    assert response.json()["name"] == "Dark Navy Skjorte"
    assert response.json()["category"] == "upper"  # unchanged


@pytest.mark.asyncio
async def test_update_garment_not_found(client):
    response = await client.put("/api/garments/00000000-0000-0000-0000-000000000000", json={"name": "X"})
    assert response.status_code == 404


@pytest.mark.asyncio
async def test_delete_garment(client):
    create = await client.post("/api/garments", json=SAMPLE_GARMENT)
    gid = create.json()["id"]

    response = await client.delete(f"/api/garments/{gid}")
    assert response.status_code == 200
    assert response.json()["deleted"] is True

    # Verify it's gone
    response = await client.get(f"/api/garments/{gid}")
    assert response.status_code == 404


@pytest.mark.asyncio
async def test_delete_garment_not_found(client):
    response = await client.delete("/api/garments/00000000-0000-0000-0000-000000000000")
    assert response.status_code == 404


@pytest.mark.asyncio
async def test_create_garment_validation(client):
    # Missing required fields
    response = await client.post("/api/garments", json={"name": "X"})
    assert response.status_code == 422

    # Invalid category
    response = await client.post("/api/garments", json={
        **SAMPLE_GARMENT, "category": "invalid"
    })
    assert response.status_code == 422

    # Invalid color format
    response = await client.post("/api/garments", json={
        **SAMPLE_GARMENT, "dominant_color": "not-a-hex"
    })
    assert response.status_code == 422


@pytest.mark.asyncio
async def test_create_garment_minimal(client):
    """Only required fields."""
    response = await client.post("/api/garments", json={
        "name": "Test",
        "category": "shoes",
        "base_group": "sneakers",
    })
    assert response.status_code == 201
    data = response.json()
    assert data["import_source"] == "manual"
    assert data["color_temperature"] is None
    assert data["image_url"] is None
