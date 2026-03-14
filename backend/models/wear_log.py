"""
CORET Backend — Wear Log Models

Mirrors engine/Sources/COREEngine/Models/Garment.swift WearLog struct.
"""

from pydantic import BaseModel, Field
from typing import Optional


class WearLogCreate(BaseModel):
    """Log a wear event for a garment."""
    date: Optional[str] = None  # ISO 8601, defaults to now


class WearLogResponse(BaseModel):
    """A single wear log entry."""
    id: str
    garment_id: str
    date: str  # ISO 8601


class WearLogListResponse(BaseModel):
    """Response for wear history."""
    logs: list[WearLogResponse]
    count: int
    total_wears: int
