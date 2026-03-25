"""
CORET Backend - Product Search Service

Soker etter produktbilder via SerpAPI (Google Shopping).
Returnerer flere resultater filtrert til kun klaer/sko/tilbehor.

Bruker: httpx for HTTP-kall, SerpAPI for sok.
Bildepipeline: Kjoeres kun for valgt produkt, ikke alle sokeresultater.
"""

import logging
import uuid

import httpx
from config import settings
from services.metadata_extractor import extract_metadata

logger = logging.getLogger(__name__)

SERPAPI_URL = "https://serpapi.com/search"


async def search_products(query: str) -> dict:
    """
    Sok etter produkter og returner filtrerte resultater (kun klaer).

    Returnerer:
        {
            "results": [
                {"image_url": "...", "product_title": "...", "brand": "...", "source_url": "..."},
                ...
            ],
            "success": True
        }
    """
    if not settings.serpapi_key:
        return {"results": [], "success": False}

    # "product" biaser mot produktbilder uten modell
    enhanced_query = f"{query} product" if "product" not in query.lower() else query
    params = {
        "engine": "google_shopping",
        "q": enhanced_query,
        "api_key": settings.serpapi_key,
        "num": 20,
    }

    async with httpx.AsyncClient() as client:
        response = await client.get(SERPAPI_URL, params=params, timeout=10.0)

        if response.status_code != 200:
            return {"results": [], "success": False}

        data = response.json()
        raw_results = data.get("shopping_results", [])

        if not raw_results:
            return {"results": [], "success": False}

        # Filtrer til kun klaer/sko/tilbehor via metadata extractor
        filtered = []
        for item in raw_results:
            title = item.get("title", "")
            meta = extract_metadata(title)
            if meta["success"]:
                filtered.append({
                    "image_url": item.get("thumbnail"),
                    "product_title": title,
                    "brand": item.get("source"),
                    "source_url": item.get("link"),
                })

            if len(filtered) >= 8:
                break

        return {
            "results": filtered,
            "success": len(filtered) > 0,
        }


async def _find_clean_image(query: str) -> str | None:
    """Soek Google Images for et rent produktbilde uten modell.

    Bruker 'isolated white background' for aa finne studio-shots.
    Returnerer bilde-URL eller None.
    """
    if not settings.serpapi_key:
        return None

    try:
        params = {
            "engine": "google_images",
            "q": f"{query} isolated white background product",
            "api_key": settings.serpapi_key,
            "num": 5,
        }
        async with httpx.AsyncClient() as client:
            resp = await client.get(SERPAPI_URL, params=params, timeout=10.0)
            if resp.status_code != 200:
                return None
            data = resp.json()
            images = data.get("images_results", [])
            if images:
                return images[0].get("thumbnail") or images[0].get("original")
    except Exception as e:
        logger.warning(f"Google Images search failed: {e}")

    return None


async def process_selected_image(thumbnail_url: str) -> str | None:
    """Prosesser valgt bilde: last ned, isoler plagg, normaliser, lagre.

    Proever foerst aa finne et bedre kildebilde via Google Images.
    Deretter kjorer gjennom Photoroom/rembg + prettifier.
    """
    try:
        from services.image_isolate import isolate_garment_with_fallback
        from services.image_normalize import normalize_image
        from services.image_storage import save_garment_images, get_image_path

        image_id = str(uuid.uuid5(uuid.NAMESPACE_URL, thumbnail_url))

        # Allerede prosessert?
        if get_image_path(image_id, "display"):
            base = settings.public_url.rstrip("/")
            return f"{base}/api/images/{image_id}/display.png"

        # Last ned kildebilde
        async with httpx.AsyncClient() as client:
            resp = await client.get(thumbnail_url, timeout=10.0, follow_redirects=True)
            if resp.status_code != 200:
                return None
            image_bytes = resp.content

        # Isoler plagget (fjern bakgrunn + modell)
        isolation_result = await isolate_garment_with_fallback(image_bytes)
        source_bytes = isolation_result["image_bytes"] if isolation_result["success"] else image_bytes

        # Normaliser (studio bg + skygge)
        norm_result = normalize_image(source_bytes)
        if not norm_result["success"]:
            return None

        # Lagre
        storage_result = save_garment_images(image_id, norm_result)
        if not storage_result["success"]:
            return None

        base = settings.public_url.rstrip("/")
        return f"{base}/api/images/{image_id}/display.png"

    except Exception as e:
        logger.warning(f"Image processing failed: {e}")
        return None
