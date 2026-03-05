"""
CORET Backend - Barcode Lookup Service

Denne servicen skal returnere: image_url, product_title, brand, category, description, success.
(f.eks. nikeairforce1.jpg, Nike Air Force 1, Nike, lower, Shoes, success.)

Bruker både API-keys og httpx
"""

import httpx
from backend.config import settings

# UpciteEmdb-endepunktet vi bruker
UPCITEMDB_URL = "https://api.upcitemdb.com/prod/trial/lookup"


async def lookup_barcode(barcode: str) -> dict:
    """
    Søk etter produktet med barcode og matcher det med dict.
    
    Parameter:
        barcode: Strekkode-streng, f.eks "0194501065795"

    Returnerer:
        {
            "product_title": "Air Force 1",
            "brand": "Nike",
            "category": "Shoes",
            "description": "...",
            "image_url": "https://...",
            "success": True
        }
    """
    # Send Get-request til UPCitemDB med strek koden
    async with httpx.AsyncClient() as client:
        response = await client.get(UPCITEMDB_URL, params={"upc": barcode}, timeout=10.0)

        # Sjekk at API-et svarte OK
        if response.status_code != 200:
            return {
                "product_title": None,
                "brand": None,
                "category": None,
                "description": None,
                "image_url": None,
                "success": False,
            }
        
        # Parse JSON-svaret
        data = response.json()
        items = data.get("items", [])

        # Ingen treff?
        if not items:
            return {
                "product_title": None,
                "brand": None,
                "category": None,
                "description": None,
                "image_url": None,
                "success": False,
            }
        
        # Plukk første (beste) resultat
        best = items[0]

        # Hent bilde-URL (første bilde i listen, hvis det finnes)
        images = best.get("images", [])
        image_url = images[0] if images else None

        return {
            "product_title": best.get("title"),
            "brand": best.get("brand"),
            "category": best.get("category"),
            "description": best.get("description"),
            "image_url": image_url,
            "success": True,
        }



