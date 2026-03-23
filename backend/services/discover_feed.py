"""
CORET Backend — Discover Feed Service

Generates the Discover outfit feed using existing wardrobe analysis engines.

Feed modes:
  7030 — 70% owned outfits, 20% rotation tips, 10% ghost outfits
  full — 100% curated looks (all ghost garments from partner catalog)

Feed rhythm (7030): owned-owned-owned-rotation, repeating.
Ghost cards injected at positions 4, 9, 14, 19.

Max 20 cards per session.
"""

import json
import random
import uuid
from datetime import datetime, timezone
from pathlib import Path

from services.garment_store import list_garments
from services.wear_log_store import get_all_wears, get_wear_count
from services.wardrobe_analysis import (
    generate_combinations,
    detect_gaps,
    analyze_wardrobe,
    _outfit_strength,
    STRONG_OUTFIT_THRESHOLD,
)
from services.ghost_catalog import get_ghost_garments

MAX_CARDS = 20
GHOST_POSITIONS = {4, 9, 14, 19}  # 0-indexed positions for ghost cards
ROTATION_DAYS = 14  # unused for N days = rotation candidate

DATA_DIR = Path(__file__).parent.parent / "data"
BOOKMARKS_FILE = DATA_DIR / "discover_bookmarks.json"
ACTIONS_FILE = DATA_DIR / "discover_actions.json"
SEEN_FILE = DATA_DIR / "discover_seen.json"


# ═══ GHOST GARMENT CATALOG ═══
# Placeholder catalog until Shopify integration.
# These represent garments the user doesn't own but could fill gaps.
GHOST_CATALOG = [
    {"id": "ghost-upper-tee-white", "name": "Hvit Basis Tee", "category": "upper",
     "base_group": "tee", "color_temperature": "neutral", "dominant_color": "#F0EDE8",
     "brand": "Uniqlo", "fills_gap": "category", "style_context": "unisex"},
    {"id": "ghost-upper-knit-navy", "name": "Navy Strikk", "category": "upper",
     "base_group": "knit", "color_temperature": "cool", "dominant_color": "#1E2A3A",
     "brand": "COS", "fills_gap": "category", "style_context": "unisex"},
    {"id": "ghost-upper-shirt-white", "name": "Hvit Oxford", "category": "upper",
     "base_group": "shirt", "color_temperature": "neutral", "dominant_color": "#F5F0EA",
     "brand": "Arket", "fills_gap": "category", "style_context": "unisex"},
    {"id": "ghost-lower-chinos-beige", "name": "Beige Chinos", "category": "lower",
     "base_group": "chinos", "color_temperature": "warm", "dominant_color": "#C4B89A",
     "brand": "Arket", "fills_gap": "proportion", "style_context": "unisex"},
    {"id": "ghost-lower-trousers-charcoal", "name": "Kull Dressbukser", "category": "lower",
     "base_group": "trousers", "color_temperature": "neutral", "dominant_color": "#3A3A3E",
     "brand": "COS", "fills_gap": "category", "style_context": "unisex"},
    {"id": "ghost-shoes-loafers-brown", "name": "Brune Loafers", "category": "shoes",
     "base_group": "loafers", "color_temperature": "warm", "dominant_color": "#5A3020",
     "brand": "Massimo Dutti", "fills_gap": "layer", "style_context": "unisex"},
    {"id": "ghost-shoes-boots-black", "name": "Svarte Chelsea Boots", "category": "shoes",
     "base_group": "boots", "color_temperature": "neutral", "dominant_color": "#1A1A1E",
     "brand": "Red Wing", "fills_gap": "category", "style_context": "unisex"},
    {"id": "ghost-upper-blazer-navy", "name": "Navy Blazer", "category": "upper",
     "base_group": "blazer", "color_temperature": "cool", "dominant_color": "#1E2A3A",
     "brand": "Massimo Dutti", "fills_gap": "layer", "style_context": "unisex"},
]


def _garment_to_dict(g) -> dict:
    """Convert GarmentResponse to dict for analysis functions."""
    return {
        "id": g.id,
        "name": g.name,
        "category": g.category,
        "base_group": g.base_group,
        "color_temperature": g.color_temperature,
        "dominant_color": g.dominant_color,
        "silhouette": g.silhouette,
        "seasons": g.seasons or [],
        "image_url": g.image_url,
    }


def _generate_reason(score: dict, feed_type: str, garments: list[dict] | None = None) -> str:
    """Generate a human-readable reason using Fashion Intelligence rule matching.
    Checks outfit properties against the same rules as the Swift engine."""
    if feed_type == "rotation":
        return "Ikke brukt nylig — tid for rotasjon"
    if feed_type == "ghost":
        return "Fyller et gap i garderoben din"

    # If we have garment data, use rule-based reasoning
    if garments:
        reason = _match_fashion_rules(garments, score)
        if reason:
            return reason

    # Fallback to score-based reasoning
    harmony = score.get("color_harmony", 0)
    archetype = score.get("archetype_coherence", 0)
    strength = score.get("strength", 0)

    if harmony >= 1.0 and archetype >= 0.8:
        return "Perfekt fargeharmoni og stilmatch"
    if harmony >= 1.0:
        return "Sterk fargeharmoni"
    if archetype >= 0.8:
        return "Passer stilen din godt"
    if strength >= 0.75:
        return "Solid kombinasjon"
    if strength >= 0.6:
        return "God hverdagskombo"
    return "Basert pa garderoben din"


def _match_fashion_rules(garments: list[dict], score: dict) -> str | None:
    """Match outfit against Fashion Intelligence rules. Returns best reason or None."""
    upper_sils = [g.get("silhouette") for g in garments if g.get("category") == "upper"]
    lower_sils = [g.get("silhouette") for g in garments if g.get("category") == "lower"]
    shoe_bgs = [g.get("base_group") for g in garments if g.get("category") == "shoes"]
    upper_bgs = [g.get("base_group") for g in garments if g.get("category") == "upper"]
    temps = [g.get("color_temperature") for g in garments if g.get("color_temperature")]
    has_coat = any(g.get("base_group") == "coat" for g in garments)
    has_blazer = any(g.get("base_group") == "blazer" for g in garments)
    has_shorts = any(g.get("base_group") == "shorts" for g in garments)

    # Negative rules (issues) — return first match
    if has_coat and has_shorts:
        return "Ytterjakke og shorts gir blandet sesong-signal"
    if "sneakers" in shoe_bgs and "blazer" in upper_bgs:
        return "Sneakers under blazer — et bevisst formalitetsgap"
    if "loafers" in shoe_bgs and "hoodie" in upper_bgs:
        return "Loafers og hoodie — en high-low miks"
    if any(s in ["oversized", "relaxed"] for s in upper_sils) and any(s in ["wide", "relaxed"] for s in lower_sils):
        return "Mye volum oppe og nede — outfiten trenger kontrast"
    if "warm" in temps and "cool" in temps:
        if "neutral" in temps:
            return "Varme og kalde toner brukt sammen — det noytrale binder det"
        return "Varme og kalde toner kjemper — et noeytralt plagg ville dempet"

    # Positive rules — return best match
    if any(s in ["oversized", "relaxed"] for s in upper_sils) and any(s in ["slim", "tapered", "fitted"] for s in lower_sils):
        return "Perfekt silhuett-kontrast — romslig oppe, smal nede"
    if (has_blazer or has_coat):
        simple = {"tee", "shirt", "jeans", "chinos", "trousers", "sneakers", "loafers", "boots"}
        others = [g for g in garments if g.get("base_group") not in ("coat", "blazer")]
        if all(g.get("base_group") in simple for g in others):
            return "Statement-plagg med enkel base — rent og kontrollert"
    if len(set(temps)) == 1 and temps:
        return "Helhetlig fargefoolelse — rolig og gjennomtenkt"
    if any(s in ["fitted", "slim"] for s in upper_sils) and any(s in ["slim", "fitted"] for s in lower_sils):
        return "Alt sitter tett — rent og ryddig uttrykk"

    return None


def _dedup_similar(cards: list[dict]) -> list[dict]:
    """Remove cards that share ≥2 of 3 garments with a stronger card already in the list.
    Cards are assumed to be in priority order (strongest first for full mode,
    rhythm order for 7030 mode)."""
    kept: list[dict] = []
    kept_id_sets: list[set] = []
    for card in cards:
        gids = {g["id"] for g in card.get("garments", [])}
        too_similar = False
        for existing_ids in kept_id_sets:
            if len(gids & existing_ids) >= 2:
                too_similar = True
                break
        if not too_similar:
            kept.append(card)
            kept_id_sets.append(gids)
    return kept


def _build_card(garment_dicts: list[dict], feed_type: str,
                ghost_ids: set | None = None, gap_type: str | None = None) -> dict:
    """Build a single DiscoverCard dict from garment dicts."""
    ghost_ids = ghost_ids or set()
    score = _outfit_strength(garment_dicts)

    brands = []
    seen_brands = set()
    for g in garment_dicts:
        b = g.get("brand", g.get("b", ""))
        if b and b not in seen_brands:
            brands.append(b)
            seen_brands.add(b)

    garments_out = []
    for g in garment_dicts:
        garments_out.append({
            "id": g["id"],
            "name": g["name"],
            "category": g.get("category", ""),
            "base_group": g.get("base_group", ""),
            "color_temperature": g.get("color_temperature"),
            "dominant_color": g.get("dominant_color"),
            "image_url": g.get("image_url"),
            "is_ghost": g["id"] in ghost_ids,
            "price": g.get("price"),
            "shop_url": g.get("shop_url"),
            "available": g.get("available", True),
        })

    ghost_count = sum(1 for g in garments_out if g["is_ghost"])
    owned_count = sum(1 for g in garments_out if not g["is_ghost"])
    names = [g["name"].split()[-1] for g in garment_dicts]

    # Build filter tags from garment properties
    filter_tags = []
    seasons = set()
    for g in garment_dicts:
        for s in g.get("seasons", []):
            seasons.add(s)
    filter_tags.extend(sorted(seasons))
    # Add color temperature tags
    temps = {g.get("color_temperature") for g in garment_dicts if g.get("color_temperature")}
    filter_tags.extend(sorted(temps))

    reason = _generate_reason(score, feed_type, garment_dicts)

    # Missing piece: exactly 1 ghost + user owns >= 2 items
    missing_piece = None
    ghost_garments = [g for g in garments_out if g.get("is_ghost")]
    if len(ghost_garments) == 1 and owned_count >= 2:
        g = ghost_garments[0]
        missing_piece = {
            "name": g["name"],
            "brand": brands[0] if brands else "",
            "price": g.get("price"),
            "shop_url": g.get("shop_url"),
            "image_url": g.get("image_url"),
            "base_group": g.get("base_group", ""),
            "gap_type": gap_type or "missing_layer",
        }

    return {
        "card_id": str(uuid.uuid4()),
        "garments": garments_out,
        "outfit_name": " + ".join(names),
        "brands": brands,
        "strength": score["strength"],
        "color_harmony": score["color_harmony"],
        "archetype_coherence": score["archetype_coherence"],
        "feed_type": feed_type,
        "owned_count": owned_count,
        "ghost_count": ghost_count,
        "gap_type": gap_type,
        "filter_tags": filter_tags,
        "reason": reason,
        "missing_piece": missing_piece,
    }


def _pick_rotation_outfits(garment_dicts: list[dict], combos: list[dict],
                           wear_counts: dict[str, int]) -> list[list[dict]]:
    """Find outfits containing underused garments (not worn in ROTATION_DAYS days).
    Returns list of garment-dict lists."""
    by_id = {g["id"]: g for g in garment_dicts}

    # Find garments with lowest wear counts
    underused = sorted(
        [g for g in garment_dicts if g.get("category") != "accessory"],
        key=lambda g: wear_counts.get(g["id"], 0)
    )

    # Get outfits that contain underused garments
    results = []
    seen = set()
    for g in underused[:5]:  # top 5 least worn
        for combo in combos:
            if g["id"] in combo["garment_ids"]:
                key = tuple(sorted(combo["garment_ids"]))
                if key not in seen:
                    seen.add(key)
                    outfit = [by_id[gid] for gid in combo["garment_ids"] if gid in by_id]
                    if len(outfit) == 3:
                        results.append(outfit)
        if len(results) >= 6:
            break

    return results


def _pick_ghost_outfits(garment_dicts: list[dict], gaps: list[dict],
                        style_context: str = "unisex",
                        brand_id: str | None = None) -> list[tuple[list[dict], str]]:
    """Build outfits with 1 ghost garment filling a detected gap.
    Returns list of (garment_dicts, gap_type)."""
    by_cat = {"upper": [], "lower": [], "shoes": []}
    for g in garment_dicts:
        cat = g.get("category")
        if cat in by_cat:
            by_cat[cat].append(g)

    results = []

    # Try live ghost catalog from Shopify brands first, fall back to placeholder
    live_ghosts = get_ghost_garments(gaps, max_ghosts=8, style_context=style_context, brand_id=brand_id)
    if live_ghosts:
        relevant_ghosts = live_ghosts
    else:
        # Fallback to placeholder catalog
        gap_types = {gap["type"] for gap in gaps}
        relevant_ghosts = [g for g in GHOST_CATALOG if g.get("fills_gap") in gap_types]
        if not relevant_ghosts:
            relevant_ghosts = GHOST_CATALOG[:3]

    for ghost in relevant_ghosts:
        cat = ghost["category"]
        # Build outfit: ghost + owned garments from other categories
        needed = [c for c in ["upper", "lower", "shoes"] if c != cat]
        if all(by_cat.get(c) for c in needed):
            outfit = [ghost]
            ghost_ids = {ghost["id"]}
            for c in needed:
                outfit.append(random.choice(by_cat[c]))
            results.append((outfit, ghost.get("fills_gap", "category")))

        if len(results) >= 4:
            break

    return results


def generate_feed(mode: str = "7030", season: str | None = None,
                   tags: list[str] | None = None,
                   style_context: str = "unisex",
                   brand_id: str | None = None) -> dict:
    """Generate the Discover feed.

    mode="7030": owned-owned-owned-rotation rhythm, ghost at positions 4,9,14,19
    mode="full": all ghost outfits (curated looks). With brand_id: only that brand's products.
    tags: optional list of tags to filter cards by (any match = include)
    style_context: filter ghost-plagg by style (menswear/womenswear/unisex/fluid)
    brand_id: if set + mode=full, only show outfits from this brand
    """
    raw_garments = list_garments()
    garment_dicts = [_garment_to_dict(g) for g in raw_garments]

    if season:
        garment_dicts = [
            g for g in garment_dicts
            if not g.get("seasons") or season in g["seasons"] or "all_season" in g["seasons"]
        ]

    analysis = analyze_wardrobe(garment_dicts, season)
    combos = generate_combinations(garment_dicts)
    gaps = detect_gaps(garment_dicts, combos)

    # Wear counts for rotation detection
    all_wears = get_all_wears()
    wear_counts: dict[str, int] = {}
    for w in all_wears:
        gid = w.garment_id
        wear_counts[gid] = wear_counts.get(gid, 0) + 1

    cards: list[dict] = []

    if mode == "full":
        # Full mode: all ghost outfits — scored and sorted by strength
        ghost_outfits = _pick_ghost_outfits(garment_dicts, gaps, style_context, brand_id)
        for outfit, gap_type in ghost_outfits:
            ghost_ids = {g["id"] for g in outfit if g["id"].startswith("ghost-")}
            cards.append(_build_card(outfit, "ghost", ghost_ids, gap_type))

        # Fill remaining slots with more ghost combos
        by_cat = {"upper": [], "lower": [], "shoes": []}
        for g in garment_dicts:
            c = g.get("category")
            if c in by_cat:
                by_cat[c].append(g)

        for ghost in GHOST_CATALOG:
            if len(cards) >= MAX_CARDS:
                break
            cat = ghost["category"]
            needed = [c for c in ["upper", "lower", "shoes"] if c != cat]
            if all(by_cat.get(c) for c in needed):
                outfit = [ghost] + [random.choice(by_cat[c]) for c in needed]
                ghost_ids = {ghost["id"]}
                cards.append(_build_card(outfit, "ghost", ghost_ids, ghost.get("fills_gap")))

        # Sort full-mode cards by strength (sterkeste først)
        cards.sort(key=lambda c: c.get("strength", 0), reverse=True)

    else:
        # 7030 mode: rhythm-based feed
        # Sort combos by strength descending for owned cards
        strong_combos = sorted(combos, key=lambda c: c["strength"], reverse=True)
        by_id = {g["id"]: g for g in garment_dicts}

        # Filter out previously seen combos
        seen = _load_seen()
        strong_combos = [c for c in strong_combos if _combo_key(c["garment_ids"]) not in seen]

        rotation_outfits = _pick_rotation_outfits(garment_dicts, combos, wear_counts)
        ghost_outfits = _pick_ghost_outfits(garment_dicts, gaps, style_context, brand_id)

        owned_idx = 0
        rotation_idx = 0
        ghost_idx = 0

        for pos in range(MAX_CARDS):
            if pos in GHOST_POSITIONS and ghost_idx < len(ghost_outfits):
                # Ghost card
                outfit, gap_type = ghost_outfits[ghost_idx]
                ghost_ids = {g["id"] for g in outfit if g["id"].startswith("ghost-")}
                cards.append(_build_card(outfit, "ghost", ghost_ids, gap_type))
                ghost_idx += 1

            elif pos % 4 == 3 and rotation_idx < len(rotation_outfits):
                # Rotation card (every 4th non-ghost slot)
                outfit = rotation_outfits[rotation_idx]
                cards.append(_build_card(outfit, "rotation"))
                rotation_idx += 1

            elif owned_idx < len(strong_combos):
                # Owned card
                combo = strong_combos[owned_idx]
                outfit = [by_id[gid] for gid in combo["garment_ids"] if gid in by_id]
                if len(outfit) == 3:
                    cards.append(_build_card(outfit, "owned"))
                    mark_seen(combo["garment_ids"])
                owned_idx += 1

            else:
                break  # exhausted all outfits

    # Cap at MAX_CARDS
    cards = cards[:MAX_CARDS]

    # Dedup: remove cards that share ≥2 of 3 garments with a stronger card
    cards = _dedup_similar(cards)

    # Server-side tag filtering (any match = include)
    if tags:
        tag_set = {t.lower() for t in tags}
        cards = [c for c in cards if tag_set & {t.lower() for t in c.get("filter_tags", [])}]

    return {
        "cards": cards,
        "total_cards": len(cards),
        "mode": mode,
        "clarity_estimate": analysis.get("clarity_estimate", 0),
        "gaps_detected": len(gaps),
    }


# ═══ BOOKMARKS ═══

def _load_bookmarks() -> list[dict]:
    if BOOKMARKS_FILE.exists():
        return json.loads(BOOKMARKS_FILE.read_text())
    return []


def _save_bookmarks(bookmarks: list[dict]):
    BOOKMARKS_FILE.write_text(json.dumps(bookmarks, indent=2))


def bookmark_card(card_id: str, garment_ids: list[str], strength: float) -> dict:
    """Save a Discover card as bookmarked."""
    bookmarks = _load_bookmarks()

    # Don't duplicate
    if any(b["card_id"] == card_id for b in bookmarks):
        return {"already_bookmarked": True}

    entry = {
        "card_id": card_id,
        "garment_ids": garment_ids,
        "strength": strength,
        "bookmarked_at": datetime.now(timezone.utc).isoformat(),
    }
    bookmarks.append(entry)
    _save_bookmarks(bookmarks)
    return entry


def remove_bookmark(card_id: str) -> bool:
    """Remove a bookmark by card_id."""
    bookmarks = _load_bookmarks()
    new = [b for b in bookmarks if b["card_id"] != card_id]
    if len(new) == len(bookmarks):
        return False
    _save_bookmarks(new)
    return True


def list_bookmarks() -> dict:
    """List all bookmarked Discover cards."""
    bookmarks = _load_bookmarks()
    return {"bookmarks": bookmarks, "count": len(bookmarks)}


# ═══ ACTION LOGGING ═══

VALID_ACTIONS = {"like", "pass", "hook"}


def _load_actions() -> list[dict]:
    if ACTIONS_FILE.exists():
        return json.loads(ACTIONS_FILE.read_text())
    return []


def _save_actions(actions: list[dict]):
    ACTIONS_FILE.write_text(json.dumps(actions, indent=2))


def log_action(card_id: str, action: str, timestamp: str | None = None,
               garment_ids: list[str] | None = None, strength: float = 0.0) -> dict:
    """Log a swipe action (like/pass/hook) for data collection.
    Hook actions auto-create a bookmark — no separate call needed."""
    if action not in VALID_ACTIONS:
        return {"success": False, "error": f"Invalid action: {action}"}

    actions = _load_actions()
    entry = {
        "card_id": card_id,
        "action": action,
        "timestamp": timestamp or datetime.now(timezone.utc).isoformat(),
    }
    actions.append(entry)
    _save_actions(actions)

    # Hook = auto-bookmark
    bookmarked = False
    if action == "hook" and garment_ids:
        result = bookmark_card(card_id, garment_ids, strength)
        bookmarked = not result.get("already_bookmarked", False)

    return {"success": True, "action": action, "card_id": card_id, "bookmarked": bookmarked}


def get_action_stats() -> dict:
    """Get action counts for analytics."""
    actions = _load_actions()
    counts = {"like": 0, "pass": 0, "hook": 0}
    for a in actions:
        act = a.get("action", "")
        if act in counts:
            counts[act] += 1
    return {"total": len(actions), **counts}


# ═══ SEEN TRACKING ═══

def _load_seen() -> set[str]:
    """Load seen garment-set keys (sorted garment IDs joined by +)."""
    if SEEN_FILE.exists():
        return set(json.loads(SEEN_FILE.read_text()))
    return set()


def _save_seen(seen: set[str]):
    SEEN_FILE.write_text(json.dumps(sorted(seen), indent=2))


def _combo_key(garment_ids: list[str]) -> str:
    """Deterministic key for a garment combo."""
    return "+".join(sorted(garment_ids))


def mark_seen(garment_ids: list[str]):
    """Mark a garment combination as seen."""
    seen = _load_seen()
    seen.add(_combo_key(garment_ids))
    _save_seen(seen)


def clear_seen():
    """Clear all seen cards (new session)."""
    if SEEN_FILE.exists():
        SEEN_FILE.unlink()
