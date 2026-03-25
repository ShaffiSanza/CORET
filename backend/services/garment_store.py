"""
CORET Backend — Garment Store

Lightweight JSON-file storage for garments.
This is a V1 store for testing and demos. In production,
SwiftData on iOS is the source of truth — this backend store
serves as a companion for API testing and web clients.
"""

import json
import threading
from contextlib import contextmanager
from pathlib import Path
from uuid import uuid4

try:
    import fcntl
    _FCNTL_AVAILABLE = True
except ImportError:
    _FCNTL_AVAILABLE = False

from models.garment import GarmentCreate, GarmentUpdate, GarmentResponse

STORE_PATH = Path(__file__).parent.parent / "data" / "garments.json"

# Per-path threading locks ensure safety across concurrent requests
# within the same process regardless of whether fcntl is available.
_thread_locks: dict[str, threading.Lock] = {}
_thread_locks_mutex = threading.Lock()


def _get_thread_lock(path: Path) -> threading.Lock:
    key = str(path)
    with _thread_locks_mutex:
        if key not in _thread_locks:
            _thread_locks[key] = threading.Lock()
        return _thread_locks[key]


@contextmanager
def _file_lock(path: Path):
    """Acquire an exclusive lock for read-modify-write operations.

    Uses fcntl.flock on Unix/Linux for cross-process safety, with a
    threading.Lock always held first to guarantee intra-process safety.
    Falls back to the threading lock alone when fcntl is unavailable.
    """
    thread_lock = _get_thread_lock(path)
    with thread_lock:
        if _FCNTL_AVAILABLE:
            lock_path = path.with_suffix(".lock")
            lock_file = open(lock_path, "w")
            try:
                fcntl.flock(lock_file.fileno(), fcntl.LOCK_EX)
                yield
            finally:
                fcntl.flock(lock_file.fileno(), fcntl.LOCK_UN)
                lock_file.close()
        else:
            # threading.Lock (held above) is sufficient for single-process use.
            yield


def _ensure_store() -> None:
    """Create data directory and file if they don't exist."""
    STORE_PATH.parent.mkdir(parents=True, exist_ok=True)
    if not STORE_PATH.exists():
        STORE_PATH.write_text("[]", encoding="utf-8")


def _read_all() -> list[dict]:
    _ensure_store()
    return json.loads(STORE_PATH.read_text(encoding="utf-8"))


def _write_all(garments: list[dict]) -> None:
    _ensure_store()
    tmp = STORE_PATH.with_suffix(".tmp")
    tmp.write_text(json.dumps(garments, indent=2, default=str))
    tmp.rename(STORE_PATH)


def list_garments() -> list[GarmentResponse]:
    """Return all garments."""
    return [GarmentResponse(**g) for g in _read_all()]


def get_garment(garment_id: str) -> GarmentResponse | None:
    """Return a single garment by ID, or None."""
    for g in _read_all():
        if g["id"] == garment_id:
            return GarmentResponse(**g)
    return None


def create_garment(data: GarmentCreate) -> GarmentResponse:
    """Create and store a new garment. Returns the created garment."""
    with _file_lock(STORE_PATH):
        garments = _read_all()
        new = {
            "id": str(uuid4()),
            **data.model_dump(),
            "image_url": None,
        }
        garments.append(new)
        _write_all(garments)
    return GarmentResponse(**new)


def update_garment(garment_id: str, data: GarmentUpdate) -> GarmentResponse | None:
    """Update an existing garment. Returns updated garment or None."""
    with _file_lock(STORE_PATH):
        garments = _read_all()
        for i, g in enumerate(garments):
            if g["id"] == garment_id:
                updates = data.model_dump(exclude_unset=True)
                garments[i] = {**g, **updates}
                _write_all(garments)
                return GarmentResponse(**garments[i])
    return None


def set_garment_image(garment_id: str, image_url: str) -> GarmentResponse | None:
    """Set the image URL for a garment. Returns updated garment or None."""
    with _file_lock(STORE_PATH):
        garments = _read_all()
        for i, g in enumerate(garments):
            if g["id"] == garment_id:
                garments[i]["image_url"] = image_url
                _write_all(garments)
                return GarmentResponse(**garments[i])
    return None


def delete_garment(garment_id: str) -> bool:
    """Delete a garment by ID. Returns True if found and deleted."""
    with _file_lock(STORE_PATH):
        garments = _read_all()
        filtered = [g for g in garments if g["id"] != garment_id]
        if len(filtered) == len(garments):
            return False
        _write_all(filtered)
    return True
