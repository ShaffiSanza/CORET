"""
CORET Backend — Wardrobe Analysis Router (Wardrobe Map V1)

Endpoints:
  GET /api/wardrobe/analysis      — Full wardrobe network analysis
  GET /api/wardrobe/garment/{id}  — Per-garment connections + role
  GET /api/wardrobe/gaps          — Structural gaps + suggestions
  GET /api/wardrobe/key-garments  — Key/anchor garments
  GET /api/wardrobe/weak-garments — Weak/isolated garments
  GET /api/wardrobe/export        — Export full wardrobe JSON
  POST /api/wardrobe/import       — Import wardrobe from JSON
  GET /api/wardrobe/suggest       — Smart outfit suggestions
"""

from typing import Optional

from fastapi import APIRouter, HTTPException, Query

from services.garment_store import list_garments, get_garment, create_garment
from services.wardrobe_analysis import analyze_wardrobe
from services.outfit_graph import suggest_outfits
from services.outfit_store import list_outfits
from services.wear_log_store import get_all_wears
from services.wardrobe_io import validate_import
from models.garment import GarmentCreate
from models.wardrobe_map import WardrobeAnalysis, GarmentStats, GapResult

router = APIRouter(tags=["wardrobe-map"])


def _get_analysis(season: str | None = None) -> dict:
    """Run analysis on current wardrobe."""
    garments = [g.model_dump() for g in list_garments()]
    return analyze_wardrobe(garments, season=season)


@router.get("/wardrobe/analysis", response_model=WardrobeAnalysis)
async def full_analysis(season: Optional[str] = Query(None, description="Filter by season")):
    """Full wardrobe network analysis — combos, key/weak garments, gaps."""
    return _get_analysis(season=season)


@router.get("/wardrobe/garment/{garment_id}", response_model=GarmentStats)
async def garment_connections(garment_id: str):
    """Per-garment connection stats — combo count, role, works-with list."""
    garment = get_garment(garment_id)
    if not garment:
        raise HTTPException(status_code=404, detail="Garment not found")

    analysis = _get_analysis()
    for stat in analysis["all_garments"]:
        if stat["id"] == garment_id:
            return stat

    raise HTTPException(status_code=404, detail="Garment not found in analysis")


@router.get("/wardrobe/gaps", response_model=list[GapResult])
async def wardrobe_gaps():
    """Structural gaps with suggestions and projected impact."""
    return _get_analysis()["gaps"]


@router.get("/wardrobe/key-garments", response_model=list[GarmentStats])
async def key_garments():
    """Key/anchor garments — ≥20% combo participation."""
    return _get_analysis()["key_garments"]


@router.get("/wardrobe/weak-garments", response_model=list[GarmentStats])
async def weak_garments():
    """Weak/isolated garments — ≤2 combinations."""
    return _get_analysis()["weak_garments"]


@router.get("/wardrobe/export")
async def export_wardrobe():
    """Export full wardrobe as JSON backup."""
    garments = [g.model_dump() for g in list_garments()]
    outfits = [o.model_dump() for o in list_outfits()]
    wear_logs = [w.model_dump() for w in get_all_wears()]
    return {
        "garments": garments,
        "outfits": outfits,
        "wear_logs": wear_logs,
    }


@router.post("/wardrobe/import")
async def import_wardrobe(data: dict):
    """Import wardrobe from JSON. Validates then creates garments."""
    validation = validate_import(data)
    if not validation["valid"]:
        raise HTTPException(status_code=422, detail=validation["errors"])

    created = []
    for g in data.get("garments", []):
        garment_data = GarmentCreate(
            name=g.get("name", "Imported"),
            category=g["category"],
            base_group=g["baseGroup"],
            color_temperature=g.get("colorTemperature"),
            dominant_color=g.get("dominantColor"),
            silhouette=g.get("silhouette"),
            seasons=g.get("seasons"),
        )
        result = create_garment(garment_data)
        created.append(result.id)

    return {
        "imported": len(created),
        "garment_ids": created,
        "warnings": validation["warnings"],
    }


@router.get("/wardrobe/suggest")
async def suggest(count: int = Query(3, ge=1, le=10, description="Number of suggestions")):
    """Smart outfit suggestions using graph-walk from anchor garments."""
    garments = [g.model_dump() for g in list_garments()]
    suggestions = suggest_outfits(garments, count=count)
    return {"suggestions": suggestions, "count": len(suggestions)}
