"""
CORET Backend — Clarity Tracker

Records clarity score snapshots over time for Evolution screen.
Snapshots are created when:
- Score changes by ≥5 points
- Monthly boundary crossed
- Manually triggered via API

Mirrors engine MilestoneTracker's ClaritySnapshot concept.
"""

import fcntl
import json
from contextlib import contextmanager
from datetime import datetime, timezone
from pathlib import Path
from uuid import uuid4

from models.clarity_history import ClaritySnapshotResponse, ClarityHistoryResponse
from services.wardrobe_analysis import analyze_wardrobe
from services.garment_store import list_garments

STORE_PATH = Path(__file__).parent.parent / "data" / "clarity_history.json"
DELTA_THRESHOLD = 5  # minimum score change to auto-record


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


def _write_all(snapshots: list[dict]) -> None:
    _ensure_store()
    tmp = STORE_PATH.with_suffix(".tmp")
    tmp.write_text(json.dumps(snapshots, indent=2, default=str))
    tmp.rename(STORE_PATH)


def record_snapshot() -> ClaritySnapshotResponse:
    """Compute current clarity and record a snapshot."""
    garments = [g.model_dump() for g in list_garments()]
    analysis = analyze_wardrobe(garments)

    with _file_lock(STORE_PATH):
        snapshots = _read_all()
        entry = {
            "id": str(uuid4()),
            "score": analysis["clarity_estimate"],
            "total_garments": analysis["total_garments"],
            "total_combinations": analysis["total_combinations"],
            "gap_count": analysis["gap_count"],
            "created_at": datetime.now(timezone.utc).isoformat(),
        }
        snapshots.append(entry)
        _write_all(snapshots)
    return ClaritySnapshotResponse(**entry)


def maybe_record_snapshot() -> ClaritySnapshotResponse | None:
    """Record a snapshot only if score changed by ≥ DELTA_THRESHOLD since last."""
    garments = [g.model_dump() for g in list_garments()]
    analysis = analyze_wardrobe(garments)
    current_score = analysis["clarity_estimate"]

    with _file_lock(STORE_PATH):
        snapshots = _read_all()
        if snapshots:
            last_score = snapshots[-1]["score"]
            if abs(current_score - last_score) < DELTA_THRESHOLD:
                return None

        entry = {
            "id": str(uuid4()),
            "score": current_score,
            "total_garments": analysis["total_garments"],
            "total_combinations": analysis["total_combinations"],
            "gap_count": analysis["gap_count"],
            "created_at": datetime.now(timezone.utc).isoformat(),
        }
        snapshots.append(entry)
        _write_all(snapshots)
    return ClaritySnapshotResponse(**entry)


def get_history() -> ClarityHistoryResponse:
    """Get full clarity history with trend analysis."""
    snapshots = _read_all()
    responses = [ClaritySnapshotResponse(**s) for s in snapshots]

    # Current score
    if snapshots:
        current = snapshots[-1]["score"]
    else:
        garments = [g.model_dump() for g in list_garments()]
        analysis = analyze_wardrobe(garments)
        current = analysis["clarity_estimate"]

    # Trend: compare last 2 snapshots
    if len(snapshots) >= 2:
        recent = snapshots[-1]["score"]
        previous = snapshots[-2]["score"]
        if recent > previous + 2:
            trend = "improving"
        elif recent < previous - 2:
            trend = "declining"
        else:
            trend = "stable"
    else:
        trend = "stable"

    # 30-day change
    now = datetime.now(timezone.utc)
    change_30d = 0
    if len(snapshots) >= 2:
        for s in reversed(snapshots[:-1]):
            try:
                snap_date = datetime.fromisoformat(s["created_at"])
                if (now - snap_date).days >= 25:
                    change_30d = snapshots[-1]["score"] - s["score"]
                    break
            except (ValueError, KeyError):
                continue

    return ClarityHistoryResponse(
        snapshots=responses,
        current_score=current,
        trend=trend,
        change_30d=change_30d,
    )
