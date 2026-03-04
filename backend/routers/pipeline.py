"""
CORET Backend — Pipeline Router

Denne filen kobler HTTP-endepunkter til services.
Tenk på det som en "resepsjonist" — den tar imot foresporselen,
sender den videre til riktig service, og returnerer svaret.

Routeren skal IKKE inneholde forretningslogikk.
All logikk bor i services/-mappen.

FastAPI APIRouter:
  - Samler relaterte endpoints i en gruppe
  - Mountes i main.py med et prefix (f.eks. /api)
"""

from fastapi import APIRouter, UploadFile, File
from fastapi.responses import Response

from backend.services.color_extraction import extract_colors_from_image
from backend.services.metadata_extractor import extract_metadata
from backend.models.schemas import (
    ProductSearchRequest, ProductSearchResponse,
    BarcodeLookupRequest, BarcodeLookupResponse,
    ColorExtractionResponse,
    ProductMetadataRequest, ProductMetadataResponse,
    ImagePolishResponse,
)

# Opprett routeren — alle endpoints her får /api-prefix fra main.py
router = APIRouter()


# ============================================================
# POST /api/product-search
# Sok etter plagg med tekst (merke + modell) → studiobilde
# ============================================================
@router.post("/product-search", response_model=ProductSearchResponse)
async def product_search(request: ProductSearchRequest):
    """Sok etter et plagg og få tilbake et studiobilde.
    Eksempel: {"query": "Nike Air Force 1 white"}"""

    # TODO: Koble til services/product_search.py
    # DU skal implementere denne! Folg monsteret fra color_extraction.
    return ProductSearchResponse(
        image_url=None,
        product_title=None,
        brand=None,
        source_url=None,
        success=False,
    )


# ============================================================
# POST /api/barcode-lookup
# Slå opp plagg via strekkode → produktinfo + bilde
# ============================================================
@router.post("/barcode-lookup", response_model=BarcodeLookupResponse)
async def barcode_lookup(request: BarcodeLookupRequest):
    """Slå opp et produkt via strekkode (UPC/EAN).
    Eksempel: {"barcode": "0194501087902"}"""

    # TODO: Koble til services/barcode_lookup.py
    # DU skal implementere denne!
    return BarcodeLookupResponse(
        image_url=None,
        product_title=None,
        brand=None,
        category=None,
        description=None,
        success=False,
    )


# ============================================================
# POST /api/extract-colors
# Last opp bilde → få ut dominerende farge + temperatur
# ============================================================
@router.post("/extract-colors", response_model=ColorExtractionResponse)
async def extract_colors(image: UploadFile = File(...)):
    """Last opp et bilde og få tilbake dominerende farge og fargetemperatur.
    Bruker multipart/form-data (fileopplasting, ikke JSON)."""

    # Les bildet som bytes fra opplastingen
    image_bytes = await image.read()

    # Send bytes til color_extraction-servicen
    result = extract_colors_from_image(image_bytes)

    # Returner resultatet som ColorExtractionResponse
    return ColorExtractionResponse(
        dominant_color=result["dominant_color"],
        color_temperature=result["color_temperature"],
        palette=result["palette"],
    )


# ============================================================
# POST /api/product-metadata
# Gi produkttittel → få foreslått kategori, plaggtype, farge
# ============================================================
@router.post("/product-metadata", response_model=ProductMetadataResponse)
async def product_metadata(request: ProductMetadataRequest):
    """Auto-utfylling: gi en produkttittel, få tilbake foreslåtte CORET-verdier.
    Eksempel: {"product_title": "Nike Air Force 1 Sneakers", "brand": "Nike"}"""

    # TODO: Koble til services/metadata_extractor.py
    # DU skal implementere denne!
    result = extract_metadata(request.product_title, request.brand, request.description)

    return ProductMetadataResponse(
        suggested_base_group=result["suggested_base_group"],
        suggested_category=result["suggested_category"],
        confidence=result["confidence"],
        success=result["success"],
    )


# ============================================================
# POST /api/image-polish
# Last opp bilde → få tilbake polert versjon (Pro-funksjon)
# ============================================================
@router.post("/image-polish")
async def image_polish(image: UploadFile = File(...)):
    """Forbedre et bilde via Photoroom API (Pro-funksjon).
    Returnerer polert bilde som PNG ved suksess, eller JSON ved feil."""

    # TODO: Koble til services/image_polish.py
    # DU skal implementere denne!
    return ImagePolishResponse(success=False, error="Not implemented yet")


