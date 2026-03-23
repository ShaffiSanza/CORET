"""
CORET Backend — User Profile Service

JSON-basert profil-lagring. Samme mønster som bookmarks/actions.
Lagrer style_context + archetype for ghost-plagg filtrering.
"""

import json
from pathlib import Path

DATA_DIR = Path(__file__).parent.parent / "data"
PROFILE_FILE = DATA_DIR / "user_profile.json"

DEFAULT_PROFILE = {
    "style_context": "unisex",
    "archetype": "smartCasual",
}


def get_profile() -> dict:
    """Get user profile. Returns default if not set."""
    if PROFILE_FILE.exists():
        return json.loads(PROFILE_FILE.read_text())
    return dict(DEFAULT_PROFILE)


def update_profile(updates: dict) -> dict:
    """Update user profile fields. Only overwrites provided fields."""
    profile = get_profile()
    for key, val in updates.items():
        if val is not None and key in DEFAULT_PROFILE:
            profile[key] = val
    PROFILE_FILE.write_text(json.dumps(profile, indent=2))
    return profile
