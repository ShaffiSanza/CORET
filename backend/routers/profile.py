"""
CORET Backend — User Profile Router

GET  /api/profile     — Get current profile
PUT  /api/profile     — Update profile (style_context, archetype)
"""

from fastapi import APIRouter

from models.profile import UserProfile, UserProfileUpdate
from services.user_profile import get_profile, update_profile

router = APIRouter(tags=["profile"])


@router.get("/profile", response_model=UserProfile)
async def get_user_profile():
    """Get user style profile."""
    return get_profile()


@router.put("/profile", response_model=UserProfile)
async def put_user_profile(req: UserProfileUpdate):
    """Update user style profile. Only provided fields are changed."""
    updates = req.model_dump(exclude_none=True)
    return update_profile(updates)
