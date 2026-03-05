"""
CORET Backend - Barcode Lookup Tester

Bruker respx til å mocke HTTP-kall til UPCitemDB.
Ingen ekte API-kall blir sendt!
"""
import pytest
import respx
from httpx import Response

from services.barcode_lookup import lookup_barcode


@pytest.mark.asyncio
async def test_successful_lookup():
    """Test at vi får tilbake produktdata når UPCitemDB svarer OK"""

    # Fake UPCitemDB-svar
    fake_response = {
        "items": [
            {
                "title": "Nike Air Force 1 '07",
                "brand": "Nike",
                "category": "Shoes",
                "description": "Classic sneaker",
                "images": ["https://images.nike.com/af1.jpg"]
            }
        ]
    }

    with respx.mock:
        respx.get("https://api.upcitemdb.com/prod/trial/lookup").mock(
            return_value=Response(200, json=fake_response)
        )
        result = await lookup_barcode("0194501065795")

    assert result["success"] is True
    assert result["product_title"] == "Nike Air Force 1 '07"
    assert result["brand"] == "Nike"
    assert result["image_url"] == "https://images.nike.com/af1.jpg"


@pytest.mark.asyncio
async def test_api_error():
    """Test at vi håndterer API-feil (f.eks 500 server error)"""

    with respx.mock:
        respx.get("https://api.upcitemdb.com/prod/trial/lookup").mock(
            return_value=Response(500)
        )
        result = await lookup_barcode("0194501065795")

    assert result["success"] is False
    assert result["image_url"] is None


@pytest.mark.asyncio
async def test_no_items():
    """Test at vi håndterer tomt resultat"""

    with respx.mock:
        respx.get("https://api.upcitemdb.com/prod/trial/lookup").mock(
            return_value=Response(200, json={"items": []})
        )
        result = await lookup_barcode("0000000000000")

    assert result["success"] is False
    assert result["image_url"] is None
