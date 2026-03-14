"""
CORET Backend — Outfit Graph Engine (V1.5)

Graph-walk outfit suggestions starting from anchor garments.
Smarter than brute-force Cartesian — picks best combos by walking
from high-connectivity garments to their strongest neighbors.
"""

from services.wardrobe_analysis import (
    analyze_wardrobe,
    _outfit_strength,
)


def suggest_outfits(garments: list[dict], count: int = 3) -> list[dict]:
    """Suggest top N outfits using anchor-first graph walk.

    Algorithm:
    1. Run analyze_wardrobe to get garment stats
    2. Pick anchors (highest combo %) as starting nodes
    3. For each anchor, find best-scoring complete outfits
    4. Rank by total outfit strength, deduplicate, return top N
    """
    if not garments:
        return []

    analysis = analyze_wardrobe(garments)
    combinations = analysis.get("total_combinations", 0)
    if combinations == 0:
        return []

    # Build garment lookup
    by_id = {g["id"]: g for g in garments}
    uppers = [g for g in garments if g.get("category") == "upper"]
    lowers = [g for g in garments if g.get("category") == "lower"]
    shoes = [g for g in garments if g.get("category") == "shoes"]

    if not uppers or not lowers or not shoes:
        return []

    # Get stats sorted by combo_percentage descending (anchors first)
    stats = sorted(analysis["all_garments"], key=lambda s: s["combo_percentage"], reverse=True)
    works_with_map = {s["id"]: set(s["works_with"]) for s in stats}

    seen = set()
    results = []

    for stat in stats:
        anchor = by_id.get(stat["id"])
        if not anchor:
            continue
        cat = anchor.get("category")

        # Try building outfits starting from this anchor
        if cat == "upper":
            candidates_lower = lowers
            candidates_shoes = shoes
            for lo in candidates_lower:
                for sh in candidates_shoes:
                    _try_outfit(anchor, lo, sh, seen, results)
        elif cat == "lower":
            for up in uppers:
                for sh in shoes:
                    _try_outfit(up, anchor, sh, seen, results)
        elif cat == "shoes":
            for up in uppers:
                for lo in lowers:
                    _try_outfit(up, lo, anchor, seen, results)

        if len(results) >= count * 3:
            break

    # Sort by strength descending
    results.sort(key=lambda r: r["strength"], reverse=True)

    # Deduplicate and take top N
    final = []
    seen_combos = set()
    for r in results:
        key = tuple(sorted(r["garment_ids"]))
        if key not in seen_combos:
            seen_combos.add(key)
            final.append(r)
        if len(final) >= count:
            break

    return final


def _try_outfit(upper: dict, lower: dict, shoes: dict, seen: set, results: list):
    """Score an outfit and add to results if not seen."""
    key = tuple(sorted([upper["id"], lower["id"], shoes["id"]]))
    if key in seen:
        return
    seen.add(key)

    outfit = [upper, lower, shoes]
    score = _outfit_strength(outfit)
    results.append({
        "garment_ids": [upper["id"], lower["id"], shoes["id"]],
        "garment_names": [upper["name"], lower["name"], shoes["name"]],
        **score,
    })
