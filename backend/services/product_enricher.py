"""
CORET Backend — Product Enrichment Layer

Three-layer enrichment applied at read time (never mutates raw cache):
  Layer 1: Category defaults
  Layer 2: Title keyword heuristics (color + silhouette)
  Layer 3: Manual overrides (data/product_overrides.json)

Priority: override > heuristic > category default > None
"""

import json
from pathlib import Path

DATA_DIR = Path(__file__).parent.parent / "data"
OVERRIDES_FILE = DATA_DIR / "product_overrides.json"


# ═══ LAYER 1: CATEGORY DEFAULTS ═══

CATEGORY_DEFAULTS = {
    "upper": {"silhouette": "regular"},
    "lower": {"silhouette": "regular"},
    "shoes": {"silhouette": "none"},
}


# ═══ LAYER 2: TITLE HEURISTICS ═══

_WARM_KEYWORDS = {"beige", "brown", "burgundy", "tan", "camel", "rust", "olive", "cream", "warm", "cognac", "khaki", "sand", "terracotta"}
_COOL_KEYWORDS = {"navy", "blue", "indigo", "slate", "ice", "cool", "charcoal", "grey", "gray", "steel", "silver", "dark"}
_NEUTRAL_KEYWORDS = {"black", "white", "ivory", "bone", "ecru"}

_SILHOUETTE_KEYWORDS = {
    "oversized": "oversized",
    "slim": "slim",
    "skinny": "slim",
    "relaxed": "relaxed",
    "tailored": "fitted",
    "fitted": "fitted",
    "leather": "fitted",
    "bomber": "relaxed",
    "parka": "relaxed",
    "wool coat": "relaxed",
    "overcoat": "relaxed",
    "chino": "tapered",
    "wide": "wide",
    "straight": "regular",
    "regular": "regular",
    "cropped": "tapered",
    "blazer": "fitted",
}


def _infer_color_temp(title: str) -> str | None:
    """Infer color temperature from product title keywords."""
    words = set(title.lower().split())
    # Check multi-word patterns first
    lower_title = title.lower()
    if any(kw in lower_title for kw in _NEUTRAL_KEYWORDS):
        return "neutral"
    if any(kw in lower_title for kw in _WARM_KEYWORDS):
        return "warm"
    if any(kw in lower_title for kw in _COOL_KEYWORDS):
        return "cool"
    return None


def _infer_silhouette(title: str, base_group: str | None) -> str | None:
    """Infer silhouette from product title and base_group."""
    lower_title = title.lower()
    # Check title keywords (most specific wins)
    for keyword, silhouette in _SILHOUETTE_KEYWORDS.items():
        if keyword in lower_title:
            return silhouette
    return None


# ═══ LAYER 3: MANUAL OVERRIDES ═══

def _load_overrides() -> dict[str, dict]:
    """Load product overrides from JSON file."""
    if OVERRIDES_FILE.exists():
        return json.loads(OVERRIDES_FILE.read_text())
    return {}


# ═══ PUBLIC API ═══

def enrich(products: list[dict]) -> list[dict]:
    """Enrich products with color_temperature and silhouette.
    Applied at read time — never mutates raw cache.
    Returns new list with enriched copies."""
    overrides = _load_overrides()
    enriched = []

    for p in products:
        # Work on a copy — never mutate original
        ep = dict(p)
        title = ep.get("title", "")
        category = ep.get("category", "")
        base_group = ep.get("base_group", "")
        override = overrides.get(title, {})

        # Color temperature: override > heuristic > existing > None
        if not ep.get("color_temperature"):
            ct = override.get("color_temperature") or _infer_color_temp(title)
            if ct:
                ep["color_temperature"] = ct

        # Silhouette: override > heuristic > category default > existing
        if not ep.get("silhouette") or ep["silhouette"] == "none" and category != "shoes":
            sil = (
                override.get("silhouette")
                or _infer_silhouette(title, base_group)
                or CATEGORY_DEFAULTS.get(category, {}).get("silhouette")
            )
            if sil:
                ep["silhouette"] = sil

        # Override can also force values even if already set
        if "color_temperature" in override:
            ep["color_temperature"] = override["color_temperature"]
        if "silhouette" in override:
            ep["silhouette"] = override["silhouette"]

        enriched.append(ep)

    return enriched
