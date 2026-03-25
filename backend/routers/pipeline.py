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

from fastapi import APIRouter, UploadFile, File, HTTPException
from fastapi.responses import Response

from services.color_extraction import extract_colors_from_image
from services.metadata_extractor import extract_metadata
from services.product_search import search_product
from services.barcode_lookup import lookup_barcode as lookup_barcode_service
from services.image_polish import polish_image
from models.schemas import (
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

    result = await search_product(request.query)
    return ProductSearchResponse(
        image_url=result["image_url"],
        product_title=result["product_title"],
        brand=result["brand"],
        source_url=result["source_url"],
        success=result["success"],
    )
    
    


# ============================================================
# POST /api/barcode-lookup
# Slå opp plagg via strekkode → produktinfo + bilde
# ============================================================
@router.post("/barcode-lookup", response_model=BarcodeLookupResponse)
async def barcode_lookup(request: BarcodeLookupRequest):
    """Slå opp et produkt via strekkode (UPC/EAN).
    Eksempel: {"barcode": "0194501087902"}"""

    result = await lookup_barcode_service(request.barcode)
    return BarcodeLookupResponse(
        image_url=result["image_url"],
        product_title=result["product_title"],
        brand=result["brand"],
        category=result["category"],
        description=result["description"],
        success=result["success"],
    )


# ============================================================
# POST /api/extract-colors
# Last opp bilde → få ut dominerende farge + temperatur
# ============================================================
@router.post("/extract-colors", response_model=ColorExtractionResponse)
async def extract_colors(image: UploadFile = File(...)):
    """Last opp et bilde og få tilbake dominerende farge og fargetemperatur.
    Bruker multipart/form-data (fileopplasting, ikke JSON)."""

    # Validate content type
    ALLOWED_TYPES = {"image/png", "image/jpeg", "image/webp"}
    if image.content_type not in ALLOWED_TYPES:
        raise HTTPException(status_code=400, detail=f"Invalid image type: {image.content_type}. Allowed: png, jpeg, webp")

    # Read in chunks to enforce size limit before consuming memory
    MAX_SIZE = 5 * 1024 * 1024
    chunks = []
    total = 0
    while True:
        chunk = await image.read(64 * 1024)
        if not chunk:
            break
        total += len(chunk)
        if total > MAX_SIZE:
            raise HTTPException(status_code=413, detail="Bildet er for stort. Maks 5 MB.")
        chunks.append(chunk)
    image_bytes = b"".join(chunks)

    # Validate magic bytes
    MAGIC_BYTES = {
        b"\x89PNG": "image/png",
        b"\xff\xd8\xff": "image/jpeg",
        b"RIFF": "image/webp",
    }
    valid_magic = any(image_bytes.startswith(magic) for magic in MAGIC_BYTES)
    if not valid_magic:
        raise HTTPException(status_code=400, detail="File content does not match a valid image format")

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

    #
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

    # Validate content type
    ALLOWED_TYPES = {"image/png", "image/jpeg", "image/webp"}
    if image.content_type not in ALLOWED_TYPES:
        raise HTTPException(status_code=400, detail=f"Invalid image type: {image.content_type}. Allowed: png, jpeg, webp")

    MAX_SIZE = 10 * 1024 * 1024
    chunks = []
    total = 0
    while True:
        chunk = await image.read(64 * 1024)
        if not chunk:
            break
        total += len(chunk)
        if total > MAX_SIZE:
            raise HTTPException(status_code=413, detail="Bildet er for stort. Maks 10 MB.")
        chunks.append(chunk)
    image_bytes = b"".join(chunks)

    # Validate magic bytes
    MAGIC_BYTES = {
        b"\x89PNG": "image/png",
        b"\xff\xd8\xff": "image/jpeg",
        b"RIFF": "image/webp",
    }
    valid_magic = any(image_bytes.startswith(magic) for magic in MAGIC_BYTES)
    if not valid_magic:
        raise HTTPException(status_code=400, detail="File content does not match a valid image format")

    result = await polish_image(image_bytes)

    if not result["success"]:
        return ImagePolishResponse(success=False, error=result["error"])

    return Response(content=result["image_bytes"], media_type="image/png")









