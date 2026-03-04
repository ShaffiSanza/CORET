"""
CORET Backend - Product Search Tester

Bruker respx til å mocke HTTP-kall til SerpAPI.
Ingen ekte API-kall blir sendt!
"""

import pytest
import respx
from httpx import Response

from backend.services.product_search import search_product
from backend.config import settings


@pytest.mark.asyncio
async def test_successful_search():
    """Test at vi får tilbake produktdata når SerpAPI svarer OK"""

    # Sett en fake API-nøkkel så funksjonen ikke returnerer tidlig
    settings.serpapi_key = "fake-test-key"

    # Fake SerpAPI-svar (det SerpAPI ville returnert)
    fake_serapi_response = {
        "shopping_results": [
            {
                "title": "Nike Air Force 1 '07",
                "source": "Nike",
                "link": "https://nike.com/air-force-1",
                "thumbnail": "https://images.nike.com/af1.jpg"
            }
        ]
    }

    # respx fanger opp GET-kallet til SerpAPI og returnerer fake data
    with respx.mock:
        respx.get("https://serpapi.com/search").mock(
            return_value=Response(200, json=fake_serapi_response)
        )

        result = await search_product("Nike Air Force 1")

    assert result["success"] is True
    assert result["product_title"] == "Nike Air Force 1 '07"
    assert result["brand"] == "Nike"
    assert result["image_url"] == "https://images.nike.com/af1.jpg"

@pytest.mark.asyncio
async def test_api_error():
    """Test at vi håndterer SerpAPI-feil (f.eks. 500 server error)"""
    settings.serpapi_key = "fake-test-key"

    with respx.mock:
        respx.get("https://serpapi.com/search").mock(
            return_value=Response(500)
        )
        result = await search_product("Nike Air Force 1")

        assert result["success"] is False
        assert result["image_url"] is None

@pytest.mark.asyncio
async def test_no_results():
    """Test at vi håndterer tomt søkeresultat"""
    settings.serpapi_key = "fake-test-key"

    with respx.mock:
        respx.get("https://serpapi.com/search").mock(
            return_value=Response(200, json={"shopping_results": []})
        )
        result = await search_product("xyznonexistent12345")

    assert result["success"] is False
    assert result["image_url"] is None
