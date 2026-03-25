"""
CORET Backend - Product Search Tester

Bruker respx til aa mocke HTTP-kall til SerpAPI.
Ingen ekte API-kall blir sendt!
"""

import pytest
import respx
from httpx import Response

from services.product_search import search_products
from config import settings


@pytest.mark.asyncio
async def test_successful_search():
    """Test at vi faar tilbake flere filtrerte resultater"""

    settings.serpapi_key = "fake-test-key"

    fake_serpapi_response = {
        "shopping_results": [
            {
                "title": "Nike Air Force 1 '07 Shoes",
                "source": "Nike",
                "link": "https://nike.com/air-force-1",
                "thumbnail": "https://images.nike.com/af1.jpg"
            },
            {
                "title": "Samsung Galaxy S24 Phone",
                "source": "Samsung",
                "link": "https://samsung.com/s24",
                "thumbnail": "https://images.samsung.com/s24.jpg"
            },
            {
                "title": "Levi's 501 Original Jeans",
                "source": "Levi's",
                "link": "https://levis.com/501",
                "thumbnail": "https://images.levis.com/501.jpg"
            }
        ]
    }

    with respx.mock:
        respx.get("https://serpapi.com/search").mock(
            return_value=Response(200, json=fake_serpapi_response)
        )

        result = await search_products("Nike Air Force 1")

    assert result["success"] is True
    # Samsung phone should be filtered out (not clothing)
    assert len(result["results"]) == 2
    assert result["results"][0]["product_title"] == "Nike Air Force 1 '07 Shoes"
    assert result["results"][1]["product_title"] == "Levi's 501 Original Jeans"


@pytest.mark.asyncio
async def test_api_error():
    """Test at vi haandterer SerpAPI-feil"""
    settings.serpapi_key = "fake-test-key"

    with respx.mock:
        respx.get("https://serpapi.com/search").mock(
            return_value=Response(500)
        )
        result = await search_products("Nike Air Force 1")

    assert result["success"] is False
    assert result["results"] == []


@pytest.mark.asyncio
async def test_no_results():
    """Test at vi haandterer tomt soekeresultat"""
    settings.serpapi_key = "fake-test-key"

    with respx.mock:
        respx.get("https://serpapi.com/search").mock(
            return_value=Response(200, json={"shopping_results": []})
        )
        result = await search_products("xyznonexistent12345")

    assert result["success"] is False
    assert result["results"] == []


@pytest.mark.asyncio
async def test_filters_non_clothing():
    """Test at ikke-klaer filtreres bort"""
    settings.serpapi_key = "fake-test-key"

    fake_response = {
        "shopping_results": [
            {"title": "iPhone 16 Pro Max", "source": "Apple", "link": "", "thumbnail": ""},
            {"title": "MacBook Pro 14", "source": "Apple", "link": "", "thumbnail": ""},
            {"title": "AirPods Pro", "source": "Apple", "link": "", "thumbnail": ""},
        ]
    }

    with respx.mock:
        respx.get("https://serpapi.com/search").mock(
            return_value=Response(200, json=fake_response)
        )
        result = await search_products("iPhone")

    assert result["success"] is False
    assert result["results"] == []
