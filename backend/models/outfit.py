"""
CORET Backend — Outfit Models

Mirrors ios/Persistence/SavedOutfitEntity.swift
"""

from pydantic import BaseModel, Field
from typing import Optional


class OutfitCreate(BaseModel):
    """Request body for saving an outfit."""
    garment_ids: list[str] = Field(..., min_length=1, max_length=10)
    label: str = ""
    score: Optional[float] = Field(None, ge=0.0, le=1.0)


class OutfitUpdate(BaseModel):
    """Request body for updating an outfit."""
    label: Optional[str] = None
    garment_ids: Optional[list[str]] = None
    score: Optional[float] = Field(None, ge=0.0, le=1.0)


class OutfitResponse(BaseModel):
    """Response model for a saved outfit."""
    id: str
    garment_ids: list[str]
    garment_names: list[str]
    label: str
    score: Optional[float]
    created_at: str


class OutfitListResponse(BaseModel):
    """Response model for outfit listing."""
    outfits: list[OutfitResponse]
    count: int
