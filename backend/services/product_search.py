"""
CORET Backend - Product Search Service

Soker etter produktbilder via SerpAPI (Google Shopping).
Tar inn en soketekst (f.eks "Nike Air Force 1") og returnerer
det beste studiobildet den finner.

Bruker: httpx for HTTP-kall, SerpAPI for sok.
Bildepipeline: Last ned thumbnail -> fjern bakgrunn -> normaliser -> lagre.
"""

import logging
import uuid

import httpx
from config import settings

logger = logging.getLogger(__name__)

# SerpAPI-endepunktet vi kaller
SERPAPI_URL = "https://serpapi.com/search"


async def search_product(query: str) -> dict:
    """
    Sok etter et produkt og returner beste studiobilde.

    Parametere:
        query: Soketekst, f.eks "Nike Air Force 1 white"

    Returnerer:
        {
            "image_url": "https://...",
            "product_title": "Nike Air Force 1 '07",
            "brand": "Nike",
            "source_url": "https://...",
            "success": True
        }
    """
    # Sjekk at vi har API-nokkel
    if not settings.serpapi_key:
        return {
            "image_url": None,
            "product_title": None,
            "brand": None,
            "source_url": None,
            "success": False,
        }

    # Bygg parameterne til SerpAPI
    params = {
        "engine": "google_shopping",
        "q": query,
        "api_key": settings.serpapi_key,
        "num": 3,
    }

    # Send forsporselen til SerpAPI
    async with httpx.AsyncClient() as client:
        response = await client.get(SERPAPI_URL, params=params, timeout=10.0)

        # Sjekk at SerpAPI svarte OK
        if response.status_code != 200:
            return {
                "image_url": None,
                "product_title": None,
                "brand": None,
                "source_url": None,
                "success": False,
            }

        # Parse JSON-svaret
        data = response.json()
        results = data.get("shopping_results", [])

        # Ingen treff?
        if not results:
            return {
                "image_url": None,
                "product_title": None,
                "brand": None,
                "source_url": None,
                "success": False,
            }

        # Plukk forste (beste) resultat
        best = results[0]
        thumbnail_url = best.get("thumbnail")

        # Prosesser bildet gjennom pipeline (bg-fjerning + normalisering)
        processed_url = None
        if thumbnail_url:
            processed_url = await _process_search_image(thumbnail_url)

        return {
            "image_url": processed_url or thumbnail_url,
            "product_title": best.get("title"),
            "brand": best.get("source"),
            "source_url": best.get("link"),
            "success": True,
        }


async def _process_search_image(thumbnail_url: str) -> str | None:
    """Last ned, fjern bakgrunn, normaliser og lagre et sok-bilde.

    Returnerer full URL til prosessert bilde, eller None ved feil.
    """
    try:
        from services.image_polish import polish_image
        from services.image_normalize import normalize_image
        from services.image_storage import save_garment_images, get_image_path

        # Deterministisk UUID fra URL (same URL = same ID, unngaar duplikater)
        image_id = str(uuid.uuid5(uuid.NAMESPACE_URL, thumbnail_url))

        # Sjekk om allerede prosessert
        if get_image_path(image_id, "display"):
            base = settings.public_url.rstrip("/")
            return f"{base}/api/images/{image_id}/display.png"

        # Last ned thumbnail
        async with httpx.AsyncClient() as client:
            resp = await client.get(thumbnail_url, timeout=10.0, follow_redirects=True)
            if resp.status_code != 200:
                return None
            image_bytes = resp.content

        # Fjern bakgrunn via Photoroom
        polish_result = await polish_image(image_bytes)
        source_bytes = polish_result["image_bytes"] if polish_result["success"] else image_bytes

        # Normaliser (sentrer paa transparent canvas, generer varianter)
        norm_result = normalize_image(source_bytes)
        if not norm_result["success"]:
            return None

        # Lagre til disk
        storage_result = save_garment_images(image_id, norm_result)
        if not storage_result["success"]:
            return None

        base = settings.public_url.rstrip("/")
        return f"{base}/api/images/{image_id}/display.png"

    except Exception as e:
        logger.warning(f"Search image processing failed: {e}")
        return None
