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

VALID_STYLE_CONTEXTS = {"menswear", "womenswear", "unisex", "fluid"}
VALID_ARCHETYPES = {"smartCasual", "street", "tailored"}


def get_profile() -> dict:
    """Get user profile. Returns default if not set."""
    if PROFILE_FILE.exists():
        return json.loads(PROFILE_FILE.read_text())
    return dict(DEFAULT_PROFILE)


def update_profile(updates: dict) -> dict:
    """Update user profile fields. Only overwrites provided fields.
    Returns error dict if values are invalid."""
    # Filter to known keys
    filtered = {k: v for k, v in updates.items() if v is not None and k in DEFAULT_PROFILE}

    # Value validation
    if "style_context" in filtered and filtered["style_context"] not in VALID_STYLE_CONTEXTS:
        return {"error": f"Invalid style_context. Must be one of: {sorted(VALID_STYLE_CONTEXTS)}"}
    if "archetype" in filtered and filtered["archetype"] not in VALID_ARCHETYPES:
        return {"error": f"Invalid archetype. Must be one of: {sorted(VALID_ARCHETYPES)}"}

    profile = get_profile()
    profile.update(filtered)
    PROFILE_FILE.write_text(json.dumps(profile, indent=2))
    return profile
