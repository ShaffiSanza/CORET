"""
CORET Backend - Product Search Service

Søker etter produktbilder via SerpAPI (Google Shopping).
Tar inn en søketekst (f.eks "Nike Air Force 1") og returnerer
det beste studiobildet den finner.

Bruker: httpx for HTTP-kall, SerpAPI for søk.
"""

import httpx
from backend.config import settings

# SerpAPI-endepunktet vi kaller
SERPAPI_URL = "https://serpapi.com/search"


async def search_product(query: str) -> dict:
    """
    Søk etter et produkt og returner beste studiobilde.

    Parametere:
        query: Søketekst, f.eks "Nike Air Force 1 white"

    Returnerer:
        {
            "image_url": "https://...",
            "product_title": "Nike Air Force 1 '07",
            "brand": "Nike",
            "source_url": "https://...",
            "success": True
        }
    """
    # Sjekk at vi har API-nøkkel
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

    # Send forespørselen til SerpAPI
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

        # Plukk første (beste) resultat
        best = results[0]

        return {
            "image_url": best.get("thumbnail"),
            "product_title": best.get("title"),
            "brand": best.get("source"),
            "source_url": best.get("link"),
            "success": True,
        }
