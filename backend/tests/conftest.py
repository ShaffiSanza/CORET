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

import os

import pytest
from httpx import AsyncClient, ASGITransport

# Disable API key auth and raise rate limit for tests
os.environ["CORET_API_KEY"] = ""
os.environ["RATE_LIMIT_PER_MINUTE"] = "9999"

# Force reload config
import config  # noqa: E402
config.settings = config.Settings()

from main import app  # noqa: E402


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
