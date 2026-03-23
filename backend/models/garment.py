"""
CORET Backend — Garment Models

Pydantic models for garment CRUD operations.
These mirror the Swift engine's Garment type for API compatibility.
"""

from pydantic import BaseModel, Field, field_validator
from typing import Optional
from uuid import uuid4

from .enums import Category, BaseGroup, ColorTemp, ImportSource, Season


class GarmentCreate(BaseModel):
    """Request body for creating a new garment."""
    name: str = Field(..., min_length=1, max_length=100)

    @field_validator("name")
    @classmethod
    def strip_name(cls, v: str) -> str:
        return v.strip()
    category: Category
    base_group: BaseGroup
    color_temperature: Optional[ColorTemp] = None
    dominant_color: Optional[str] = Field(
        None, pattern=r"^#[0-9A-Fa-f]{6}$",
        description="Hex color code, e.g. '#2C3E50'"
    )
    silhouette: Optional[str] = None
    seasons: Optional[list[str]] = None
    import_source: ImportSource = ImportSource.manual


class GarmentUpdate(BaseModel):
    """Request body for updating a garment. All fields optional."""
    name: Optional[str] = Field(None, min_length=1, max_length=100)
    category: Optional[Category] = None
    base_group: Optional[BaseGroup] = None
    color_temperature: Optional[ColorTemp] = None
    dominant_color: Optional[str] = Field(
        None, pattern=r"^#[0-9A-Fa-f]{6}$"
    )
    silhouette: Optional[str] = None
    seasons: Optional[list[str]] = None


class GarmentResponse(BaseModel):
    """Response model for a single garment."""
    id: str
    name: str
    category: Category
    base_group: BaseGroup
    color_temperature: Optional[ColorTemp] = None
    dominant_color: Optional[str] = None
    silhouette: Optional[str] = None
    seasons: Optional[list[str]] = None
    import_source: ImportSource
    image_url: Optional[str] = None


class WardrobeResponse(BaseModel):
    """Response model for the full wardrobe listing."""
    garments: list[GarmentResponse]
    count: int
