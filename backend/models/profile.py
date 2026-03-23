"""
CORET Backend — User Profile Models

Minimal user profile for style preferences.
Not exposed as "gender" in UI — purely backend filtering.
"""

from typing import Literal

from pydantic import BaseModel, Field, field_validator

from .enums import StyleContext

Archetype = Literal["smartCasual", "street", "tailored"]


class UserProfile(BaseModel):
    """User style profile. Stored locally as JSON."""
    style_context: StyleContext = StyleContext.unisex
    archetype: Archetype = "smartCasual"


class UserProfileUpdate(BaseModel):
    """Partial update for user profile."""
    style_context: StyleContext | None = None
    archetype: Archetype | None = None

    @field_validator("style_context", "archetype", mode="before")
    @classmethod
    def strip_strings(cls, v):
        return v.strip() if isinstance(v, str) else v
