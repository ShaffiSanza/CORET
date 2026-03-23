"""
CORET Backend — Wardrobe Analysis Service

Python port of core engine combination logic for Wardrobe Map V1.
Source: CohesionEngine.swift, ScoringHelpers.swift, OptimizeEngineV2.swift

Computes:
- All valid outfit combinations (upper × lower × shoes)
- Per-garment combo count and role (anchor/support/weak)
- Outfit strength (proportion + archetype + color harmony)
- Structural gap detection
"""

from collections import defaultdict

# ═══ ARCHETYPE AFFINITY TABLE ═══
# From CohesionEngine.swift lines 8-90
# Maps (base_group, archetype) → 0-1 affinity score
AFFINITY = {
    # Upper
    ("tee", "smartCasual"): 0.7, ("tee", "street"): 1.0, ("tee", "tailored"): 0.3,
    ("shirt", "smartCasual"): 0.8, ("shirt", "street"): 0.3, ("shirt", "tailored"): 1.0,
    ("knit", "smartCasual"): 0.9, ("knit", "street"): 0.5, ("knit", "tailored"): 0.7,
    ("hoodie", "smartCasual"): 0.4, ("hoodie", "street"): 1.0, ("hoodie", "tailored"): 0.1,
    ("blazer", "smartCasual"): 0.7, ("blazer", "street"): 0.2, ("blazer", "tailored"): 1.0,
    ("coat", "smartCasual"): 0.7, ("coat", "street"): 0.5, ("coat", "tailored"): 0.9,
    # Lower
    ("jeans", "smartCasual"): 0.7, ("jeans", "street"): 0.9, ("jeans", "tailored"): 0.3,
    ("chinos", "smartCasual"): 0.9, ("chinos", "street"): 0.4, ("chinos", "tailored"): 0.8,
    ("trousers", "smartCasual"): 0.6, ("trousers", "street"): 0.2, ("trousers", "tailored"): 1.0,
    ("shorts", "smartCasual"): 0.6, ("shorts", "street"): 0.8, ("shorts", "tailored"): 0.2,
    ("skirt", "smartCasual"): 0.7, ("skirt", "street"): 0.5, ("skirt", "tailored"): 0.6,
    # Shoes
    ("sneakers", "smartCasual"): 0.6, ("sneakers", "street"): 1.0, ("sneakers", "tailored"): 0.2,
    ("boots", "smartCasual"): 0.7, ("boots", "street"): 0.8, ("boots", "tailored"): 0.7,
    ("loafers", "smartCasual"): 0.8, ("loafers", "street"): 0.2, ("loafers", "tailored"): 1.0,
    ("sandals", "smartCasual"): 0.5, ("sandals", "street"): 0.6, ("sandals", "tailored"): 0.1,
}

# ═══ PROPORTION MATRIX ═══
# From CohesionEngine.swift lines 96-123
# Maps (upper_silhouette, lower_silhouette) → 0-1 proportion score
PROPORTION_MATRIX = {
    ("fitted", "slim"): 0.7, ("fitted", "regular"): 0.85, ("fitted", "tapered"): 0.9, ("fitted", "wide"): 1.0,
    ("relaxed", "slim"): 1.0, ("relaxed", "regular"): 0.85, ("relaxed", "tapered"): 0.7, ("relaxed", "wide"): 0.4,
    ("tapered", "slim"): 0.8, ("tapered", "regular"): 0.9, ("tapered", "tapered"): 0.85, ("tapered", "wide"): 0.65,
    ("oversized", "slim"): 1.0, ("oversized", "regular"): 0.8, ("oversized", "tapered"): 0.65, ("oversized", "wide"): 0.3,
}

DEFAULT_ARCHETYPE = "smartCasual"
KEY_GARMENT_THRESHOLD = 0.20  # ≥20% of combos = anchor
WEAK_GARMENT_MAX_COMBOS = 2
STRONG_OUTFIT_THRESHOLD = 0.65


def _color_harmony(garments: list[dict]) -> float:
    """Color harmony score. From CohesionEngine.outfitColorHarmony."""
    temps = [g.get("color_temperature") for g in garments]
    has_warm = "warm" in temps
    has_cool = "cool" in temps
    if has_warm and has_cool:
        return 0.5  # clash
    return 1.0


def _archetype_coherence(garments: list[dict], archetype: str) -> float:
    """Average archetype affinity. From CohesionEngine.outfitArchetypeCoherence."""
    if not garments:
        return 0.0
    total = sum(
        AFFINITY.get((g.get("base_group", ""), archetype), 0.5)
        for g in garments
    )
    return total / len(garments)


def _proportion_score(outfit: list[dict]) -> float:
    """Proportion score from silhouette matrix. Default 0.5 if silhouettes missing."""
    uppers = [g for g in outfit if g.get("category") == "upper"]
    lowers = [g for g in outfit if g.get("category") == "lower"]
    if not uppers or not lowers:
        return 0.5
    upper_sil = uppers[0].get("silhouette")
    lower_sil = lowers[0].get("silhouette")
    if not upper_sil or not lower_sil or upper_sil == "none" or lower_sil == "none":
        return 0.5
    return PROPORTION_MATRIX.get((upper_sil, lower_sil), 0.5)


def _outfit_strength(outfit: list[dict], archetype: str = DEFAULT_ARCHETYPE) -> dict:
    """Outfit strength. From CohesionEngine.outfitStrength.
    Returns dict with total strength + components."""
    color = _color_harmony(outfit)
    arch = _archetype_coherence(outfit, archetype)
    # Proportion score from silhouette matrix
    proportion = _proportion_score(outfit)
    strength = proportion * 0.40 + arch * 0.35 + color * 0.25
    return {
        "strength": round(strength, 3),
        "color_harmony": color,
        "archetype_coherence": round(arch, 3),
    }


def generate_combinations(garments: list[dict]) -> list[dict]:
    """Generate all valid outfits. From ScoringHelpers.generateOutfits.
    Outfit = 1 upper + 1 lower + 1 shoes.
    Note: Coats are category=upper, base_group=coat — they participate as uppers.
    Swift engine has separate outerwear category with 4-piece outfits (upper × lower × shoes × outerwear).
    Backend V1 keeps 3-piece for simplicity. Outerwear support in V2."""
    uppers = [g for g in garments if g.get("category") == "upper"]
    lowers = [g for g in garments if g.get("category") == "lower"]
    shoes = [g for g in garments if g.get("category") == "shoes"]

    if not uppers or not lowers or not shoes:
        return []

    combos = []
    for u in uppers:
        for l in lowers:
            for s in shoes:
                outfit = [u, l, s]
                score = _outfit_strength(outfit)
                combos.append({
                    "garment_ids": [u["id"], l["id"], s["id"]],
                    "garment_names": [u["name"], l["name"], s["name"]],
                    **score,
                })
    return combos


def compute_garment_stats(garments: list[dict], combinations: list[dict]) -> list[dict]:
    """Per-garment connection stats. Role assignment per KEY_GARMENT_THRESHOLD."""
    total_combos = len(combinations)

    # Count combos per garment + track co-appearing garments
    combo_count = defaultdict(int)
    works_with = defaultdict(set)

    for combo in combinations:
        ids = combo["garment_ids"]
        for gid in ids:
            combo_count[gid] += 1
            for other_id in ids:
                if other_id != gid:
                    works_with[gid].add(other_id)

    stats = []
    for g in garments:
        gid = g["id"]
        count = combo_count.get(gid, 0)
        pct = (count / total_combos * 100) if total_combos > 0 else 0.0

        if pct >= KEY_GARMENT_THRESHOLD * 100:
            role = "anchor"
        elif count <= WEAK_GARMENT_MAX_COMBOS:
            role = "weak"
        else:
            role = "support"

        # Accessories never participate in combos — mark as support, not weak
        if g.get("category") == "accessory" and count == 0:
            role = "support"

        stats.append({
            "id": gid,
            "name": g["name"],
            "category": g.get("category", ""),
            "combo_count": count,
            "role": role,
            "works_with": sorted(works_with.get(gid, set())),
            "combo_percentage": round(pct, 1),
        })

    return stats


def detect_gaps(garments: list[dict], combinations: list[dict]) -> list[dict]:
    """Detect structural gaps. From OptimizeEngineV2.detectGaps."""
    gaps = []
    categories = {g.get("category") for g in garments}

    # Category gaps
    for cat, label, suggestion in [
        ("upper", "Ingen overdeler", "Legg til en t-skjorte eller skjorte"),
        ("lower", "Ingen underdeler", "Legg til en bukse eller jeans"),
        ("shoes", "Ingen sko", "Legg til sneakers eller boots"),
    ]:
        if cat not in categories:
            gaps.append({
                "type": "category",
                "priority": "high",
                "description": label,
                "suggestion": suggestion,
                "projected_combo_gain": 0,
            })

    # If we have at least one combo, check for improvements
    if combinations:
        upper_count = sum(1 for g in garments if g.get("category") == "upper")
        lower_count = sum(1 for g in garments if g.get("category") == "lower")
        shoe_count = sum(1 for g in garments if g.get("category") == "shoes")

        # Proportion imbalance
        if upper_count > 0 and lower_count > 0:
            ratio = upper_count / lower_count
            if ratio > 2.0:
                gain = upper_count * shoe_count  # each new lower adds this many combos
                gaps.append({
                    "type": "proportion",
                    "priority": "medium",
                    "description": f"Ubalanse: {upper_count} overdeler vs {lower_count} underdeler",
                    "suggestion": "Legg til en underdel for bedre balanse",
                    "projected_combo_gain": gain,
                })
            elif ratio < 0.5:
                gain = lower_count * shoe_count
                gaps.append({
                    "type": "proportion",
                    "priority": "medium",
                    "description": f"Ubalanse: {lower_count} underdeler vs {upper_count} overdeler",
                    "suggestion": "Legg til en overdel for bedre balanse",
                    "projected_combo_gain": gain,
                })

        # Layer gap: only one color temperature
        temps = {g.get("color_temperature") for g in garments if g.get("color_temperature")}
        real_temps = temps - {None}
        if len(real_temps) == 1:
            gaps.append({
                "type": "layer",
                "priority": "low",
                "description": f"Kun {next(iter(real_temps))} fargetoner i garderoben",
                "suggestion": "Et nøytralt plagg ville økt kombinasjonsmulighetene",
                "projected_combo_gain": 0,
            })

    return gaps


def analyze_wardrobe(garments: list[dict], season: str | None = None) -> dict:
    """Full wardrobe analysis — the V1 Wardrobe Map computation.
    If season is provided, pre-filters to garments available in that season."""
    if season:
        garments = [
            g for g in garments
            if not g.get("seasons") or season in g["seasons"] or "all_season" in g["seasons"]
        ]
    combinations = generate_combinations(garments)
    stats = compute_garment_stats(garments, combinations)
    gaps = detect_gaps(garments, combinations)

    strong_combos = sum(1 for c in combinations if c["strength"] >= STRONG_OUTFIT_THRESHOLD)
    total = len(combinations)

    # Clarity estimate: simplified V1 backend version.
    # DIVERGES from Swift engine which uses: primaryArchetype × 0.60 + cohesion × 0.40 + breadth bonus.
    # This is intentional — backend lacks archetype data. When iOS connects, Swift engine is authoritative.
    if total > 0:
        strong_ratio = strong_combos / total
        gap_penalty = len(gaps) * 8
        clarity = max(0, min(100, int(strong_ratio * 85 + 15 - gap_penalty)))
    else:
        clarity = 0

    key = [s for s in stats if s["role"] == "anchor"]
    weak = [s for s in stats if s["role"] == "weak"]

    return {
        "total_garments": len(garments),
        "total_combinations": total,
        "strong_combinations": strong_combos,
        "clarity_estimate": clarity,
        "gap_count": len(gaps),
        "key_garments": key,
        "weak_garments": weak,
        "gaps": gaps,
        "all_garments": stats,
    }
