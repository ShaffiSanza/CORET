"""
CORET Backend - Image Polish Tester

Bruker respx til å mocke HTTP-kall til Photoroom API.
Ingen ekte API-kall blir sendt!
"""
import pytest
import respx
from httpx import Response

from backend.services.image_polish import polish_image
from backend.config import settings


@pytest.mark.asyncio
async def test_successful_polish():
    """Test at vi får tilbake polert bilde når Photoroom svarer OK"""

    settings.photoroom_api_key = "fake-key"

    with respx.mock:
        respx.post("https://sdk.photoroom.com/v1/segment").mock(
            return_value=Response(200, content=b"fake-polished-image")
        )
        result = await polish_image(b"fake-original-image")

    assert result["success"] is True
    assert result["image_bytes"] == b"fake-polished-image"


@pytest.mark.asyncio
async def test_api_error():
    """Test at vi håndterer Photoroom-feil (f.eks. 500 server error)"""

    settings.photoroom_api_key = "fake-key"

    with respx.mock:
        respx.post("https://sdk.photoroom.com/v1/segment").mock(
            return_value=Response(500)
        )
        result = await polish_image(b"fake-original-image")

    assert result["success"] is False
    assert result["image_bytes"] is None


@pytest.mark.asyncio
async def test_no_api_key():
    """Test at vi håndterer manglende API-nøkkel"""

    settings.photoroom_api_key = ""

    result = await polish_image(b"fake-original-image")

    assert result["success"] is False
    assert result["error"] == "Photoroom API key not configured"
