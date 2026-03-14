"""
CORET Backend — Wardrobe Map Models

Response models for wardrobe analysis endpoints.
"""

from pydantic import BaseModel


class GarmentStats(BaseModel):
    """Per-garment connection statistics."""
    id: str
    name: str
    category: str
    combo_count: int
    role: str  # "anchor" (≥20%), "support", "weak" (≤2)
    works_with: list[str]  # garment IDs this garment appears with
    combo_percentage: float  # 0-100


class OutfitResult(BaseModel):
    """A single outfit combination."""
    garment_ids: list[str]
    garment_names: list[str]
    strength: float  # 0-1
    color_harmony: float
    archetype_coherence: float


class GapResult(BaseModel):
    """A detected structural gap."""
    type: str  # "category", "layer", "proportion"
    priority: str  # "high", "medium", "low"
    description: str
    suggestion: str
    projected_combo_gain: int


class WardrobeAnalysis(BaseModel):
    """Full wardrobe network analysis."""
    total_garments: int
    total_combinations: int
    strong_combinations: int  # strength ≥ 0.65
    clarity_estimate: int  # 0-100
    gap_count: int
    key_garments: list[GarmentStats]
    weak_garments: list[GarmentStats]
    gaps: list[GapResult]
    all_garments: list[GarmentStats]
