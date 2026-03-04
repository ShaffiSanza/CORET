"""
CORET Backend — Helsesjekk-tester

Disse testene verifiserer at:
  1. Backend-en starter opp riktig
  2. /api/health returnerer forventet data
  3. Grunnleggende HTTP-infrastruktur fungerer

Å kjore:
  cd /home/Command/projects/CORET
  python -m pytest backend/tests/test_health.py -v
"""

import pytest


@pytest.mark.asyncio
async def test_health_returns_ok(client):
    """Helsesjekk skal returnere HTTP 200 med status 'ok'."""
    response = await client.get("/api/health")

    # Sjekk at HTTP-statuskoden er 200 (OK)
    assert response.status_code == 200

    # Sjekk at JSON-bodyen inneholder riktig status
    data = response.json()
    assert data["status"] == "ok"


@pytest.mark.asyncio
async def test_health_includes_version(client):
    """Helsesjekk skal inkludere versjonsnummer."""
    response = await client.get("/api/health")
    data = response.json()

    # Sjekk at versjon-feltet finnes og ikke er tomt
    assert "version" in data
    assert len(data["version"]) > 0


@pytest.mark.asyncio
async def test_stubs_return_success_false(client):
    """Alle stub-endpoints (som ikke er implementert ennå) skal returnere success=false.
    Dette bekrefter at routeren er riktig koblet opp."""

    # Test product-search stub
    response = await client.post(
        "/api/product-search",
        json={"query": "test"}
    )
    assert response.status_code == 200
    assert response.json()["success"] is False

    # Test barcode-lookup stub
    response = await client.post(
        "/api/barcode-lookup",
        json={"barcode": "12345678"}
    )
    assert response.status_code == 200
    assert response.json()["success"] is False

    # Test product-metadata stub
    response = await client.post(
        "/api/product-metadata",
        json={"product_title": "Test Product"}
    )
    assert response.status_code == 200
    assert response.json()["success"] is False
