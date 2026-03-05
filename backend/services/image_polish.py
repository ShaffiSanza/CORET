"""
CORET Backend - Image Polish Service

Fjerner bakgrunn fra produktbilder via Photoroom API.
Tar inn rå bilde-bytes og returnerer polert bilde som PNG-bytes.

Bruker: httpx for HTTP-kall, Photoroom API for bildeforbedring.
"""

import httpx
from config import settings

# Photoroom API-endepunktet
PHOTOROOM_URL = "https://sdk.photoroom.com/v1/segment"


async def polish_image(image_bytes: bytes) -> dict:
    """
    Fjern bakgrunn fra et bilde via Photoroom API.

    Parameter:
        image_bytes: Rå bilde-data (PNG/JPG) som bytes

    Returnerer:
        {
            "image_bytes": b"...",
            "success": True
        }
    """
    # Sjekk at vi har API-nøkkel
    if not settings.photoroom_api_key:
        return {
            "image_bytes": None,
            "success": False,
            "error": "Photoroom API key not configured",
        }

    # Send bildet til Photoroom som multipart/form-data
    async with httpx.AsyncClient() as client:
        response = await client.post(
            PHOTOROOM_URL,
            headers={"x-api-key": settings.photoroom_api_key},
            files={"image_file": ("image.png", image_bytes, "image/png")},
            timeout=30.0,
        )

        # Sjekk at Photoroom svarte OK
        if response.status_code != 200:
            return {
                "image_bytes": None,
                "success": False,
                "error": f"Photoroom returned {response.status_code}",
            }

        # Returner det polerte bildet som bytes
        return {
            "image_bytes": response.content,
            "success": True,
            "error": None,
        }
