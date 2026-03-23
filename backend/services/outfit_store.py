"""
CORET Backend — Outfit Store

JSON-file storage for saved outfits.
"""

import fcntl
import json
from contextlib import contextmanager
from datetime import datetime, timezone
from pathlib import Path
from uuid import uuid4

from models.outfit import OutfitCreate, OutfitUpdate, OutfitResponse
from services.garment_store import get_garment

STORE_PATH = Path(__file__).parent.parent / "data" / "outfits.json"


@contextmanager
def _file_lock(path: Path):
    """Acquire an exclusive file lock for read-modify-write operations."""
    lock_path = path.with_suffix(".lock")
    lock_file = open(lock_path, "w")
    try:
        fcntl.flock(lock_file.fileno(), fcntl.LOCK_EX)
        yield
    finally:
        fcntl.flock(lock_file.fileno(), fcntl.LOCK_UN)
        lock_file.close()


def _ensure_store() -> None:
    STORE_PATH.parent.mkdir(parents=True, exist_ok=True)
    if not STORE_PATH.exists():
        STORE_PATH.write_text("[]", encoding="utf-8")


def _read_all() -> list[dict]:
    _ensure_store()
    return json.loads(STORE_PATH.read_text(encoding="utf-8"))


def _write_all(outfits: list[dict]) -> None:
    _ensure_store()
    tmp = STORE_PATH.with_suffix(".tmp")
    tmp.write_text(json.dumps(outfits, indent=2, default=str))
    tmp.rename(STORE_PATH)


def _resolve_names(garment_ids: list[str]) -> list[str]:
    """Resolve garment IDs to names."""
    names = []
    for gid in garment_ids:
        g = get_garment(gid)
        names.append(g.name if g else "Unknown")
    return names


def list_outfits() -> list[OutfitResponse]:
    return [OutfitResponse(**o) for o in _read_all()]


def get_outfit(outfit_id: str) -> OutfitResponse | None:
    for o in _read_all():
        if o["id"] == outfit_id:
            return OutfitResponse(**o)
    return None


def create_outfit(data: OutfitCreate) -> OutfitResponse:
    with _file_lock(STORE_PATH):
        outfits = _read_all()
        new = {
            "id": str(uuid4()),
            "garment_ids": data.garment_ids,
            "garment_names": _resolve_names(data.garment_ids),
            "label": data.label,
            "score": data.score,
            "created_at": datetime.now(timezone.utc).isoformat(),
        }
        outfits.append(new)
        _write_all(outfits)
    return OutfitResponse(**new)


def update_outfit(outfit_id: str, data: OutfitUpdate) -> OutfitResponse | None:
    with _file_lock(STORE_PATH):
        outfits = _read_all()
        for i, o in enumerate(outfits):
            if o["id"] == outfit_id:
                updates = data.model_dump(exclude_unset=True)
                if "garment_ids" in updates:
                    updates["garment_names"] = _resolve_names(updates["garment_ids"])
                outfits[i] = {**o, **updates}
                _write_all(outfits)
                return OutfitResponse(**outfits[i])
    return None


def delete_outfit(outfit_id: str) -> bool:
    with _file_lock(STORE_PATH):
        outfits = _read_all()
        filtered = [o for o in outfits if o["id"] != outfit_id]
        if len(filtered) == len(outfits):
            return False
        _write_all(filtered)
    return True
