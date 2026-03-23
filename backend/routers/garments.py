"""
CORET Backend — Garment CRUD + Image Processing Router

Endpoints:
  POST   /api/garments              — Create garment
  GET    /api/garments              — List all garments
  GET    /api/garments/{id}         — Get single garment
  PUT    /api/garments/{id}         — Update garment
  DELETE /api/garments/{id}         — Delete garment
  POST   /api/garments/{id}/image   — Upload + process garment image
  GET    /api/images/{id}/{variant} — Serve stored garment image
"""

import re

from fastapi import APIRouter, HTTPException, UploadFile, File
from fastapi.responses import JSONResponse, FileResponse

_UUID_RE = re.compile(r"^[0-9a-f]{8}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{12}$")

from models.garment import (
    GarmentCreate,
    GarmentUpdate,
    GarmentResponse,
    WardrobeResponse,
)
from services.garment_store import (
    list_garments,
    get_garment,
    create_garment,
    update_garment,
    delete_garment,
    set_garment_image,
)
from services.image_polish import polish_image
from services.color_extraction import extract_colors_from_image
from services.image_normalize import normalize_image
from services.image_storage import save_garment_images, get_image_path, delete_garment_images

router = APIRouter(tags=["garments"])


# ═══ CRUD ═══

@router.post("/garments", response_model=GarmentResponse, status_code=201)
async def create(data: GarmentCreate):
    """Create a new garment in the wardrobe."""
    return create_garment(data)


@router.get("/garments", response_model=WardrobeResponse)
async def list_all():
    """List all garments in the wardrobe."""
    garments = list_garments()
    return WardrobeResponse(garments=garments, count=len(garments))


@router.get("/garments/{garment_id}", response_model=GarmentResponse)
async def get_one(garment_id: str):
    """Get a single garment by ID."""
    if not _UUID_RE.match(garment_id):
        raise HTTPException(status_code=400, detail="Invalid garment ID format")
    garment = get_garment(garment_id)
    if not garment:
        raise HTTPException(status_code=404, detail="Garment not found")
    return garment


@router.put("/garments/{garment_id}", response_model=GarmentResponse)
async def update(garment_id: str, data: GarmentUpdate):
    """Update an existing garment."""
    if not _UUID_RE.match(garment_id):
        raise HTTPException(status_code=400, detail="Invalid garment ID format")
    garment = update_garment(garment_id, data)
    if not garment:
        raise HTTPException(status_code=404, detail="Garment not found")
    return garment


@router.delete("/garments/{garment_id}")
async def delete(garment_id: str):
    """Delete a garment and its images."""
    if not _UUID_RE.match(garment_id):
        raise HTTPException(status_code=400, detail="Invalid garment ID format")
    if not delete_garment(garment_id):
        raise HTTPException(status_code=404, detail="Garment not found")
    delete_garment_images(garment_id)
    return {"deleted": True}


# ═══ IMAGE PIPELINE ═══

@router.post("/garments/{garment_id}/image")
async def upload_image(garment_id: str, image: UploadFile = File(...)):
    """Upload and process a garment image.

    Pipeline:
    1. Color extraction from original
    2. Background removal (Photoroom)
    3. Resize + center to 1024px transparent canvas
    4. Generate 512px + 256px variants
    5. Save all variants to disk
    6. Update garment with color data + image URLs
    """
    if not _UUID_RE.match(garment_id):
        raise HTTPException(status_code=400, detail="Invalid garment ID format")

    # Validate content type
    ALLOWED_TYPES = {"image/png", "image/jpeg", "image/webp"}
    if image.content_type not in ALLOWED_TYPES:
        raise HTTPException(status_code=400, detail=f"Invalid image type: {image.content_type}. Allowed: png, jpeg, webp")

    garment = get_garment(garment_id)
    if not garment:
        raise HTTPException(status_code=404, detail="Garment not found")

    image_bytes = await image.read()

    # Validate magic bytes
    MAGIC_BYTES = {
        b"\x89PNG": "image/png",
        b"\xff\xd8\xff": "image/jpeg",
        b"RIFF": "image/webp",  # WebP starts with RIFF
    }
    valid_magic = any(image_bytes.startswith(magic) for magic in MAGIC_BYTES)
    if not valid_magic:
        raise HTTPException(status_code=400, detail="File content does not match a valid image format")

    if len(image_bytes) > 10 * 1024 * 1024:
        raise HTTPException(status_code=413, detail="Image too large (max 10MB)")

    # Step 1: Extract colors from original
    color_result = extract_colors_from_image(image_bytes)

    # Step 2: Background removal
    polish_result = await polish_image(image_bytes)
    source_bytes = polish_result["image_bytes"] if polish_result["success"] else image_bytes

    # Step 3-4: Normalize + generate variants
    norm_result = normalize_image(source_bytes)

    # Step 5: Save to disk
    urls = {"full": None, "display": None, "preview": None}
    if norm_result["success"]:
        storage_result = save_garment_images(garment_id, norm_result)
        if storage_result["success"]:
            urls = {
                "full": storage_result["full"],
                "display": storage_result["display"],
                "preview": storage_result["preview"],
            }

    # Step 6: Update garment with color + image reference
    color_update = GarmentUpdate(
        dominant_color=color_result["dominant_color"],
        color_temperature=color_result["color_temperature"],
    )
    update_garment(garment_id, color_update)
    set_garment_image(garment_id, urls["display"])

    return JSONResponse(content={
        "garment_id": garment_id,
        "pipeline": {
            "bg_removed": polish_result["success"],
            "normalized": norm_result["success"],
            "stored": urls["full"] is not None,
        },
        "colors": {
            "dominant_color": color_result["dominant_color"],
            "color_temperature": color_result["color_temperature"].value,
            "palette": color_result["palette"],
        },
        "images": urls,
    })


# ═══ IMAGE SERVING ═══

@router.get("/images/{garment_id}/{variant}")
async def serve_image(garment_id: str, variant: str):
    """Serve a stored garment image.

    Variants:
    - full.png    — 1024px (storage/export)
    - display.png — 512px (app UI)
    - preview.png — 256px (thumbnails/lists)
    """
    if not _UUID_RE.match(garment_id):
        raise HTTPException(status_code=400, detail="Invalid garment ID format")
    # Strip .png extension if present
    variant_name = variant.replace(".png", "")
    if variant_name not in ("full", "display", "preview"):
        raise HTTPException(status_code=400, detail="Invalid variant. Use: full, display, or preview")

    path = get_image_path(garment_id, variant_name)
    if not path:
        raise HTTPException(status_code=404, detail="Image not found")

    return FileResponse(path, media_type="image/png")
