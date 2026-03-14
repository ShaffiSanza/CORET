"""
CORET Backend — Clarity History Models

Mirrors engine ClaritySnapshot for tracking score over time.
"""

from pydantic import BaseModel, Field


class ClaritySnapshotResponse(BaseModel):
    """A single clarity score snapshot."""
    id: str
    score: int  # 0-100
    total_garments: int
    total_combinations: int
    gap_count: int
    created_at: str  # ISO 8601


class ClarityHistoryResponse(BaseModel):
    """Full clarity history for Evolution screen."""
    snapshots: list[ClaritySnapshotResponse]
    current_score: int
    trend: str  # "improving", "stable", "declining"
    change_30d: int  # score change in last 30 days
