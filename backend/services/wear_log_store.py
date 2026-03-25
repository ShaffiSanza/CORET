"""
CORET Backend — Wear Log Store

JSON-file storage for garment wear history.
Used by BehaviouralEngine for drift detection, rotation analysis,
and "predict next wear" features.
"""

import json
import threading
from contextlib import contextmanager
from datetime import datetime, timezone
from pathlib import Path
from uuid import uuid4

try:
    import fcntl
    _FCNTL_AVAILABLE = True
except ImportError:
    _FCNTL_AVAILABLE = False

from models.wear_log import WearLogResponse

STORE_PATH = Path(__file__).parent.parent / "data" / "wear_logs.json"

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
    STORE_PATH.parent.mkdir(parents=True, exist_ok=True)
    if not STORE_PATH.exists():
        STORE_PATH.write_text("[]", encoding="utf-8")


def _read_all() -> list[dict]:
    _ensure_store()
    return json.loads(STORE_PATH.read_text(encoding="utf-8"))


def _write_all(logs: list[dict]) -> None:
    _ensure_store()
    tmp = STORE_PATH.with_suffix(".tmp")
    tmp.write_text(json.dumps(logs, indent=2, default=str))
    tmp.rename(STORE_PATH)


def log_wear(garment_id: str, date: str | None = None) -> WearLogResponse:
    """Record a wear event."""
    with _file_lock(STORE_PATH):
        logs = _read_all()
        wear_date = date or datetime.now(timezone.utc).isoformat()
        entry = {
            "id": str(uuid4()),
            "garment_id": garment_id,
            "date": wear_date,
        }
        logs.append(entry)
        _write_all(logs)
    return WearLogResponse(**entry)


def get_garment_wears(garment_id: str) -> list[WearLogResponse]:
    """Get all wear logs for a specific garment, sorted by date descending."""
    logs = [WearLogResponse(**l) for l in _read_all() if l["garment_id"] == garment_id]
    logs.sort(key=lambda l: l.date, reverse=True)
    return logs


def get_all_wears() -> list[WearLogResponse]:
    """Get all wear logs, sorted by date descending."""
    logs = [WearLogResponse(**l) for l in _read_all()]
    logs.sort(key=lambda l: l.date, reverse=True)
    return logs


def get_wear_count(garment_id: str) -> int:
    """Get total wear count for a garment."""
    return sum(1 for l in _read_all() if l["garment_id"] == garment_id)


def delete_garment_wears(garment_id: str) -> int:
    """Delete all wear logs for a garment. Returns count deleted."""
    with _file_lock(STORE_PATH):
        logs = _read_all()
        filtered = [l for l in logs if l["garment_id"] != garment_id]
        deleted = len(logs) - len(filtered)
        _write_all(filtered)
    return deleted
