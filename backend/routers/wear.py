"""
CORET Backend — Wear Logging + Clarity History Router

Endpoints:
  POST /api/garments/{id}/wear   — Log a wear event
  GET  /api/garments/{id}/wears  — Get wear history for garment
  GET  /api/clarity/history      — Get clarity score history
  POST /api/clarity/snapshot     — Force record a clarity snapshot
"""

from fastapi import APIRouter, HTTPException

from models.wear_log import WearLogCreate, WearLogResponse, WearLogListResponse
from models.clarity_history import ClaritySnapshotResponse, ClarityHistoryResponse
from services.garment_store import get_garment
from services.wear_log_store import log_wear, get_garment_wears, get_wear_count
from services.clarity_tracker import record_snapshot, maybe_record_snapshot, get_history

router = APIRouter(tags=["wear-tracking"])


# ═══ WEAR LOGGING ═══

@router.post("/garments/{garment_id}/wear", response_model=WearLogResponse, status_code=201)
async def record_wear(garment_id: str, data: WearLogCreate = WearLogCreate()):
    """Log that a garment was worn. Auto-records clarity snapshot if score changed."""
    garment = get_garment(garment_id)
    if not garment:
        raise HTTPException(status_code=404, detail="Garment not found")

    wear = log_wear(garment_id, data.date)

    # Auto-snapshot clarity if score changed significantly
    maybe_record_snapshot()

    return wear


@router.get("/garments/{garment_id}/wears", response_model=WearLogListResponse)
async def garment_wears(garment_id: str):
    """Get wear history for a specific garment."""
    garment = get_garment(garment_id)
    if not garment:
        raise HTTPException(status_code=404, detail="Garment not found")

    logs = get_garment_wears(garment_id)
    return WearLogListResponse(
        logs=logs,
        count=len(logs),
        total_wears=get_wear_count(garment_id),
    )


# ═══ CLARITY HISTORY ═══

@router.get("/clarity/history", response_model=ClarityHistoryResponse)
async def clarity_history():
    """Get clarity score history for Evolution screen."""
    return get_history()


@router.post("/clarity/snapshot", response_model=ClaritySnapshotResponse, status_code=201)
async def force_snapshot():
    """Force record a clarity snapshot (regardless of delta threshold)."""
    return record_snapshot()
