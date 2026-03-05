"""
CORET Backend — Test-konfigurasjon

conftest.py er en spesiell pytest-fil som kjores FOR alle tester.
Fixtures definert her er tilgjengelige i ALLE testfiler automatisk.

Hva er en fixture?
  En fixture er en "forberedelse" som tester kan bruke.
  I stedet for å skrive setup-kode i hver test, definerer du den
  én gang her og pytest injiserer den automatisk.

Hva er en TestClient?
  En TestClient lar deg sende HTTP-requests til FastAPI-appen
  UTEN å starte en ekte server. Alt kjorer i minnet = raskt.
"""

import pytest
from httpx import AsyncClient, ASGITransport

from main import app


@pytest.fixture
def client():
    """Opprett en test-HTTP-klient som snakker med appen vår.

    Bruk:
        async def test_noe(client):
            response = await client.get("/api/health")
            assert response.status_code == 200

    ASGITransport betyr at vi kobler httpx direkte til FastAPI
    uten å gå via nettverk — alt skjer i minnet.
    """
    transport = ASGITransport(app=app)
    return AsyncClient(transport=transport, base_url="http://test")
