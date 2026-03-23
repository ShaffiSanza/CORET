"""
CORET Backend — User Profile Models

Minimal user profile for style preferences.
Not exposed as "gender" in UI — purely backend filtering.
"""

from pydantic import BaseModel, Field, field_validator


class UserProfile(BaseModel):
    """User style profile. Stored locally as JSON."""
    style_context: str = Field("unisex", max_length=20)
    archetype: str = Field("smartCasual", max_length=50)


class UserProfileUpdate(BaseModel):
    """Partial update for user profile."""
    style_context: str | None = Field(None, max_length=20)
    archetype: str | None = Field(None, max_length=50)

    @field_validator("style_context", "archetype", mode="before")
    @classmethod
    def strip_strings(cls, v):
        return v.strip() if isinstance(v, str) else v
