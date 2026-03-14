"""
CORET Backend — Outfit CRUD Router

Endpoints:
  POST   /api/outfits        — Save an outfit from Studio
  GET    /api/outfits        — List saved outfits
  GET    /api/outfits/{id}   — Get single outfit
  PUT    /api/outfits/{id}   — Update outfit (label, garments)
  DELETE /api/outfits/{id}   — Delete outfit
"""

from fastapi import APIRouter, HTTPException

from models.outfit import OutfitCreate, OutfitUpdate, OutfitResponse, OutfitListResponse
from services.outfit_store import (
    list_outfits,
    get_outfit,
    create_outfit,
    update_outfit,
    delete_outfit,
)

router = APIRouter(tags=["outfits"])


@router.post("/outfits", response_model=OutfitResponse, status_code=201)
async def create(data: OutfitCreate):
    """Save an outfit built in Studio."""
    return create_outfit(data)


@router.get("/outfits", response_model=OutfitListResponse)
async def list_all():
    """List all saved outfits."""
    outfits = list_outfits()
    return OutfitListResponse(outfits=outfits, count=len(outfits))


@router.get("/outfits/{outfit_id}", response_model=OutfitResponse)
async def get_one(outfit_id: str):
    """Get a single saved outfit."""
    outfit = get_outfit(outfit_id)
    if not outfit:
        raise HTTPException(status_code=404, detail="Outfit not found")
    return outfit


@router.put("/outfits/{outfit_id}", response_model=OutfitResponse)
async def update(outfit_id: str, data: OutfitUpdate):
    """Update a saved outfit."""
    outfit = update_outfit(outfit_id, data)
    if not outfit:
        raise HTTPException(status_code=404, detail="Outfit not found")
    return outfit


@router.delete("/outfits/{outfit_id}")
async def delete(outfit_id: str):
    """Delete a saved outfit."""
    if not delete_outfit(outfit_id):
        raise HTTPException(status_code=404, detail="Outfit not found")
    return {"deleted": True}
