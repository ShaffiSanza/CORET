# CORET — Engine & System Specifications

Full technical reference for all V1 and V2 engines, data models, IA, UI, and persistence architecture. Referenced from CLAUDE.md.

---

## Contents

- [§3. Data Model (V1)](#3-data-model-v1)
- [§4. Cohesion Engine (V1)](#4-cohesion-engine-v1)
- [§5. Optimize Engine (V1)](#5-optimize-engine-v1)
- [§6. Seasonal Engine (V1)](#6-seasonal-engine-v1)
- [§7. Structural Evolution (V1)](#7-structural-evolution-v1)
- [§8. Information Architecture](#8-information-architecture)
- [§9. UI Specification](#9-ui-specification)
- [§10. Brand Foundation](#10-brand-foundation)
- [§11. Monetization](#11-monetization)
- [§12. Scaling Strategy](#12-scaling-strategy)
- [§15. SwiftData Persistence Architecture](#15-swiftdata-persistence-architecture)
- [§16. ViewModel Architecture](#16-viewmodel-architecture)
- [§19. V2 Data Model](#19-v2-data-model)
- [§20. V2 CohesionEngine](#20-v2-cohesionengine)
- [§21. V2 ClarityEngine](#21-v2-clarityengine)
- [§22. V2 ScoreProjector](#22-v2-scoreprojector)
- [§23. V2 Scoring Helpers](#23-v2-scoring-helpers-internal)
- [§24. V2 IdentityResolver](#24-v2-identityresolver)
- [§25. V2 KeyGarmentResolver](#25-v2-keygarmentresolver)
- [§26. V2 MilestoneTracker](#26-v2-milestonetracker)
- [§27. V2 SeasonalEngineV2](#27-v2-seasonalenginev2)
- [§28. V2 OptimizeEngineV2](#28-v2-optimizeenginev2)

---

## 3. Data Model (V1)

All types live in `archive/Sources/COREEngine/Models/WardrobeItem.swift`. All public types are Codable, Sendable. Structs are Identifiable. Enums are CaseIterable.

### Enums

**ItemCategory**: `top`, `bottom`, `shoes`, `outerwear`

**Silhouette**: `structured`, `balanced`, `relaxed`

**BaseGroup**: `neutral`, `deep`, `light`, `accent`

**Temperature**: `warm`, `cool`, `neutral`

**Archetype**: `structuredMinimal`, `relaxedStreet`, `smartCasual` (expandable)

**SeasonMode**: `springSummer`, `autumnWinter`

**CohesionStatus**: `structuring`, `refining`, `coherent`, `aligned`, `architected`

### WardrobeItem

| Field | Type | Notes |
|-------|------|-------|
| id | UUID | `let`, immutable |
| imagePath | String | User-uploaded image path |
| category | ItemCategory | Required |
| silhouette | Silhouette | Required |
| rawColor | String | User-selected color name |
| baseGroup | BaseGroup | Mapped from color |
| temperature | Temperature | Mapped from color |
| archetypeTag | Archetype | Single tag per item |
| customColorOverride | Bool | Default false |
| usageCount | Int | Default 0 |
| lastWornDate | Date? | Nullable |
| createdAt | Date | `let`, immutable |

### UserProfile

| Field | Type |
|-------|------|
| id | UUID (`let`) |
| primaryArchetype | Archetype |
| secondaryArchetype | Archetype |
| seasonMode | SeasonMode |
| createdAt | Date (`let`) |

### StructuralIdentity

Defined in `WardrobeItem.swift`. Returned by `CohesionEngine.structuralIdentity(items:)`.

| Field | Type | Notes |
|-------|------|-------|
| id | UUID (`let`) | |
| dominantSilhouette | Silhouette? | nil = no dominant (tied) |
| dominantBaseGroup | BaseGroup? | nil = no dominant (tied) |
| dominantTemperature | Temperature | Never nil. Neutral fallback on tie. |

### CohesionSnapshot

| Field | Type |
|-------|------|
| id | UUID (`let`) |
| alignmentScore | Double |
| densityScore | Double |
| paletteScore | Double |
| rotationScore | Double |
| totalScore | Double |
| statusLevel | CohesionStatus |
| itemIDs | Set\<UUID\> (`let`) |
| createdAt | Date (`let`) |

### Item Contribution Types (Runtime Only)

Defined in `CohesionEngine.swift`. Not persisted — recomputed on demand. `ItemContribution` and `ContributionContext` are NOT Codable. `ContributionContext` uses associated values which prevent auto-synthesis. These types are recomputed on demand and never persisted, so Codable is not required.

**CohesionComponent** (enum): `alignment`, `density`, `palette`, `rotation`

**AlignmentMatchType** (enum): `primary`, `secondary`, `neutral`, `conflict`

**ParticipationLevel** (enum): `high`, `low`

**PaletteRole** (enum): `balanced`, `excessAccent`, `temperatureClash`

**UsageLevel** (enum): `even`, `overused`, `underused`

**ContributionContext** (enum, associated values): `.alignment(AlignmentMatchType)`, `.density(ParticipationLevel)`, `.palette(PaletteRole)`, `.rotation(UsageLevel)`

**ItemContribution** (struct): `id`, `itemID: UUID`, `component: CohesionComponent`, `contributionScore: Double`, `context: ContributionContext`

### Outfit Builder Types

Defined in `CohesionEngine.swift`.

**ScoredOutfit** (struct): `id`, `items: [WardrobeItem]`, `outfitScore: Double`, `alignmentScore: Double`, `paletteHarmony: Double`, `silhouetteConsistency: Double`, `silhouetteCounts: [Silhouette: Int]`

### Removal Impact Types

Defined in `CohesionEngine.swift`.

**RemovalImpact** (struct): `id`, `itemID: UUID`, `alignmentBefore: Double`, `alignmentAfter: Double`, `densityBefore: Double`, `densityAfter: Double`, `paletteBefore: Double`, `paletteAfter: Double`, `rotationBefore: Double`, `rotationAfter: Double`, `totalBefore: Double`, `totalAfter: Double`

### OptimizeEngine Result Types

Defined in `OptimizeEngine.swift`:

**WeaknessArea** (enum): `alignment`, `density`, `palette`, `rotation`

**OptimizeRecommendation** (struct): `id`, `candidate: WardrobeItem`, `weaknessArea`, `componentBefore`, `componentAfter`, `componentImprovement`, `totalBefore`, `totalAfter`, `totalImprovement`

**StructuralFriction** (struct): `id`, `item: WardrobeItem`, `totalBefore`, `totalAfter`, `totalImprovement`

**OptimizeResult** (struct): `id`, `currentSnapshot`, `weakestArea`, `primary: OptimizeRecommendation?`, `secondary: [OptimizeRecommendation]`, `friction: [StructuralFriction]`

---

## 4. Cohesion Engine (V1) — IMPLEMENTED

File: `archive/Sources/COREEngine/Engines/CohesionEngine.swift`
Pattern: `public enum CohesionEngine: Sendable` — caseless enum namespace, all static functions.
Tests: 123 passing in `CohesionEngineTests.swift`

### Formula

```
Total = (Alignment × 0.35) + (Density × 0.30) + (Palette × 0.20) + (Rotation × 0.15)
```

Each component returns 0–100. Total is 0–100.

### Public API

```swift
public static func compute(items: [WardrobeItem], profile: UserProfile) -> CohesionSnapshot
public static func alignmentScore(items: [WardrobeItem], profile: UserProfile) -> Double
public static func densityScore(items: [WardrobeItem], profile: UserProfile) -> Double
public static func paletteScore(items: [WardrobeItem]) -> Double
public static func rotationScore(items: [WardrobeItem]) -> Double
public static func statusLevel(from totalScore: Double) -> CohesionStatus
public static func structuralIdentity(items: [WardrobeItem]) -> StructuralIdentity
public static func itemContributions(items: [WardrobeItem], profile: UserProfile, component: CohesionComponent) -> [ItemContribution]
public static func outfitBuilder(items: [WardrobeItem], profile: UserProfile) -> [ScoredOutfit]
public static func removalImpact(item: WardrobeItem, from items: [WardrobeItem], profile: UserProfile) -> RemovalImpact
public static func layerCoverageScore(items: [WardrobeItem], profile: UserProfile) -> Double
public static func capsuleRatioScore(items: [WardrobeItem], profile: UserProfile) -> Double
public static func structuralDensityScore(items: [WardrobeItem], profile: UserProfile) -> Double
public static func computeV2(items: [WardrobeItem], profile: UserProfile) -> CohesionSnapshot
public static func computeV2(items: [WardrobeItem], profile: UserProfile, weights: CohesionWeights) -> CohesionSnapshot
```

### 4a. Archetype Alignment (weight 0.35)

Each item scored against user profile:

| Match | Score |
|-------|-------|
| Primary archetype | 1.0 |
| Secondary archetype | 0.7 |
| Neutral (no conflict, no match) | 0.5 |
| Conflict | 0.2 |

**Conflict map** (expandable via `archetypesConflict` helper):
- `structuredMinimal` ↔ `relaxedStreet` = conflict
- All other pairs = neutral

Result: `average(itemScores) × 100`
Edge case: empty items → 0.

### 4b. Combination Density (weight 0.30)

Generates all outfits: `tops × bottoms × shoes × (1 + outerwearCount)`.
The `(1 + count)` accounts for no-outerwear outfit plus each outerwear piece.

Each outfit validated against three rules:

1. **Archetype**: No item conflicts with user's primary archetype.
2. **Silhouette balance**: structured=+1, balanced=0, relaxed=-1. Sum must be in [-2, +2].
3. **Color rules** (skipped if monochrome — all items share same baseGroup):
   - Max 1 accent item
   - At least 1 neutral item
   - No warm+cool clash (both .warm and .cool present)

Result: `(validOutfits / totalPossible) × 100`
Edge case: missing any required category (top/bottom/shoes) → 0.

### 4c. Palette Control (weight 0.20)

Three sub-scores, equally weighted (÷3):

1. **Neutral/Deep ratio** (target 60–80%):
   - In [0.6, 0.8] → 100
   - Below 0.6 → `(ratio / 0.6) × 100`
   - Above 0.8 → `((1.0 - ratio) / 0.2) × 100`

2. **Accent ratio** (target 0–20%):
   - ≤ 0.2 → 100
   - Above 0.2 → `max(0, (1.0 - ((ratio - 0.2) / 0.3)) × 100)`

3. **Temperature coherence**:
   - Only warm or only cool → 100
   - Both present: `(1.0 - min(warmRatio, coolRatio) × 2) × 100` (among warm+cool items only, ignoring neutral temp)

Edge case: 0 items → 0.

### 4d. Rotation Balance (weight 0.15)

Per category (top, bottom, shoes, outerwear):
- Categories with 0–1 items → skip (perfect by definition)
- Compute mean usageCount
- Mean absolute deviation: `avg(|count - mean|)`
- Normalize: `deviation / max(mean, 1)`

Average normalized deviation across qualifying categories.
Result: `(1.0 - clamp(avgDeviation, 0, 1)) × 100`
Edge case: all usageCounts 0 → deviation 0 → score 100.

### 4e. Status Levels

| Score Range | Status |
|-------------|--------|
| 0–49 | .structuring |
| 50–64 | .refining |
| 65–79 | .coherent |
| 80–89 | .aligned |
| 90–100 | .architected |

### 4f. Structural Identity

Derives a deterministic identity from current wardrobe state via `structuralIdentity(items:)`.

**Algorithm (per dimension):**
- Count frequency of each enum value across all items
- Value with highest count wins (plurality)
- If tied → `nil` (silhouette, baseGroup) or `.neutral` (temperature)
- Temperature never returns nil. On any tie, resolves to `.neutral`.
- Empty items → all nil / .neutral

No identityString in engine. String composition is ViewModel responsibility.

### 4g. Item Contributions

Per-item contribution scoring for Component Detail screen. Hybrid approach: direct scoring for alignment/rotation, delta simulation for density/palette.

**Types** (defined in `CohesionEngine.swift`, runtime only — not persisted):

```swift
public enum CohesionComponent: String, Codable, CaseIterable, Sendable {
    case alignment, density, palette, rotation
}

public enum ContributionContext: Sendable, Equatable {
    case alignment(AlignmentMatchType)   // .primary, .secondary, .neutral, .conflict
    case density(ParticipationLevel)     // .high, .low
    case palette(PaletteRole)            // .balanced, .excessAccent, .temperatureClash
    case rotation(UsageLevel)            // .even, .overused, .underused
}

public struct ItemContribution: Identifiable, Sendable {
    public let id: UUID
    public let itemID: UUID
    public let component: CohesionComponent
    public let contributionScore: Double  // 0–1, higher = better
    public let context: ContributionContext
}
```

**Scoring strategy per component:**

| Component | Method | Score Range | Context Labels |
|-----------|--------|-------------|----------------|
| Alignment | Direct (reuses `itemAlignmentValue`) | 0.2–1.0 | Primary/Secondary/Neutral/Conflict |
| Rotation | Direct (deviation from category mean) | 0–1 | Even (< 0.2 normalized dev) / Overused / Underused |
| Density | Delta simulation (remove item, recompute) | 0–1 (min-max normalized) | High (delta > 0) / Low (delta ≤ 0) |
| Palette | Delta simulation (remove item, recompute) | 0–1 (min-max normalized) | Balanced / ExcessAccent / TemperatureClash |

**Normalization (delta-based):** `(delta - minDelta) / (maxDelta - minDelta)`. All deltas equal → 0.5.

**Sorting:** Descending by contributionScore. Tie-break: UUID string lexicographic.

**Edge cases:**
- Empty items → empty array
- Single item → alignment/rotation use direct score; density/palette get 0.5 (only one delta)
- Missing category (density baseline 0) → all items get 0.5, context `.low`

### 4h. Outfit Builder

Generates all structurally complete outfit combinations from a wardrobe, scores each, and returns them sorted.

**Combination generation:** `tops × bottoms × shoes × (1 + outerwearCount)`. Same enumeration as density, but scores instead of binary valid/invalid.

**Scoring formula:**
```
outfitScore = alignmentAverage × 0.40 + paletteHarmony × 0.35 + silhouetteConsistency × 0.25
```

Rounded to 2 decimal places: `(rawScore * 100).rounded() / 100`. Sub-scores computed at full Double precision.

**alignmentAverage** (0–1): Average of `itemAlignmentValue()` across all items in outfit. Reuses existing alignment logic (Primary=1.0, Secondary=0.7, Neutral=0.5, Conflict=0.2).

**paletteHarmony** (0–1): Ratio model with 3 binary rules, each worth 1/3:
1. Max 1 accent item
2. At least 1 neutral item
3. No warm+cool clash

Monochrome exception: all items share same baseGroup → paletteHarmony = 1.0 (all rules auto-pass).

**silhouetteConsistency** (0–1): Pairwise compatibility matrix, averaged across all unique pairs:

```
             structured  balanced  relaxed
structured      1.0        0.7      0.3
balanced        0.7        1.0      0.7
relaxed         0.3        0.7      1.0
```

3-item outfit = 3 pairs. 4-item outfit = 6 pairs.

**Sorting:** Descending by outfitScore. Tie-break: sorted item UUID strings concatenated, lexicographic.

**No hard cap:** Engine returns all scored outfits. ViewModel/UI applies `.prefix(N)` for display.

**Edge cases:**
- Missing any required category (top/bottom/shoes) → empty array
- Single item per category → 1 outfit returned
- Empty wardrobe → empty array

**outfitBuilder vs densityScore validation:** outfitBuilder does NOT filter by `isValidOutfit()`. It scores all structurally complete combinations. Outfits that would fail density validation appear with low scores rather than being excluded. This is intentional — outfitBuilder measures quality on a spectrum, while densityScore uses binary validity.

### 4i. Removal Impact

Per-item removal simulation for delete warning UI. Computes before/after scores across all 4 components + total when removing a specific item.

**Function:** `removalImpact(item:from items:profile:) -> RemovalImpact`

**Algorithm:** Two `compute()` calls — one with all items, one without the target item. Returns both sets of component scores and totals.

**Usage:** Wardrobe Item Detail delete confirmation alert: *"Removing this item will reduce Density by X."* The ViewModel picks the component with the largest negative delta.

**Distinct from `detectFriction()`:** `detectFriction` iterates ALL items and only flags those with total improvement > 8. `removalImpact` targets a single specified item, returns per-component deltas, and has no threshold filter.

**Edge cases:**
- Item not in list → before == after (identical scores)
- Empty items → all scores 0
- Removing only item of required category → density drops to 0

### 4j. Layer Coverage Score (V1.5)

Maps to Style Theory Principle 1 (Three-Layer System). Returns 0–100.

**Function:** `layerCoverageScore(items:profile:) -> Double`

**Formula:**
```
layerCoverageScore = (categoryCoverage × 0.40) + (layeringCapacity × 0.35) + (silhouetteSpread × 0.25)
```

**categoryCoverage**: Per-category depth (0→0.0, 1→0.6, 2→0.85, 3+→1.0) weighted by archetype-specific category importance. structuredMinimal weights all categories equally (0.25). smartCasual emphasizes tops (0.30). relaxedStreet emphasizes tops more (0.35), reduces outerwear (0.15).

**layeringCapacity**: Outerwear:top ratio scored against archetype-specific ideal ranges (structuredMinimal 0.5–1.0, smartCasual 0.3–0.8, relaxedStreet 0.2–0.6). In range → 100, below/above → proportionally penalized.

**silhouetteSpread**: 3 unique silhouettes → 100, 2 → 70, 1 → 40.

**Edge cases:** Empty → 0. No tops → layeringCapacity 0. No outerwear → layeringCapacity 0, categoryCoverage penalized.

### 4k. Capsule Ratio Score (V1.5)

Maps to Style Theory Principle 4 (Capsule Balance & Ratios). Returns 0–100.

**Function:** `capsuleRatioScore(items:profile:) -> Double`

**Formula:**
```
capsuleRatioScore = (topBottomRatio + outerProportion + categoryBalance) / 3.0
```

**topBottomRatio**: top:bottom count ratio scored against archetype ideals (structuredMinimal 1.0–1.5, smartCasual 1.25–1.75, relaxedStreet 1.5–2.0). No tops or no bottoms → 0.

**outerProportion**: outerwear/total ratio scored against archetype ideals (structuredMinimal 0.25–0.40, smartCasual 0.20–0.35, relaxedStreet 0.15–0.30).

**categoryBalance**: Shannon entropy normalized by log₂(n) where n = number of non-empty categories. Perfect distribution → 100. Single category → 0. Requires ≥ 2 categories.

**Edge cases:** Empty → 0. Single category → 0.

### 4l. Structural Density Score (V1.5 Composite)

Weighted composite of V1 density + V1.5 signals. Returns 0–100.

**Function:** `structuralDensityScore(items:profile:) -> Double`

**Formula:**
```
structuralDensity = combinationDensity × 0.50 + layerCoverage × 0.25 + capsuleRatio × 0.25
```

### 4m. Compute V2 (V1.5)

Same as `compute()` but uses `structuralDensityScore` for the density slot.

**Functions:**
```swift
public static func computeV2(items:profile:) -> CohesionSnapshot
public static func computeV2(items:profile:weights:) -> CohesionSnapshot
```

Returns `CohesionSnapshot` where `.densityScore` holds the structural density value. All other components unchanged. First overload delegates to weighted with `SeasonalEngine.baseWeights`.

### Design Principles
- Deterministic. No ML.
- Transparent breakdown. All component scores are public.
- Not easily gamed.
- Stable over time.

---

## 5. Optimize Engine (V1) — IMPLEMENTED

File: `archive/Sources/COREEngine/Engines/OptimizeEngine.swift`
Pattern: `public enum OptimizeEngine: Sendable` — caseless enum, all static.
Tests: 19 passing in `OptimizeEngineTests.swift`

### Public API

```swift
public static func optimize(items: [WardrobeItem], profile: UserProfile) -> OptimizeResult
public static func weakestArea(from snapshot: CohesionSnapshot) -> WeaknessArea
public static func detectFriction(items: [WardrobeItem], profile: UserProfile) -> [StructuralFriction]
```

### Core Logic

1. Compute current CohesionSnapshot via CohesionEngine
2. Identify weakest component (lowest score; ties broken by order: alignment, density, palette, rotation)
3. Generate structural candidates dynamically based on weakness type
4. For each candidate: simulate adding to wardrobe, recompute cohesion, measure improvement
5. Rank by component improvement (descending)
6. Return: 1 primary (best) + up to 2 secondary candidates (only those with positive improvement)

### Candidate Generation Strategy

| Weakness | Candidates Generated | Key Dimension Varied |
|----------|---------------------|---------------------|
| Alignment | 4 categories × primary archetype + 4 × secondary archetype = 8 | Archetype |
| Density | 4 categories × 3 silhouettes = 12 | Silhouette |
| Palette | 4 categories × 2 baseGroups (neutral, deep) = 8 | BaseGroup |
| Rotation | 4 categories × 1 = 4 | Category |

All candidates use: balanced silhouette (unless density), neutral baseGroup (unless palette), dominant wardrobe temperature, primary archetype (unless alignment).

### Structural Friction (Removal Simulation)

For each existing item:
- Simulate removal, recompute cohesion
- If total improvement > 8 → flagged as StructuralFriction
- Sorted by improvement descending

Friction is labeled "Structural Friction" in UI. Only surfaced when significant.

### WeaknessArea vs CohesionComponent

WeaknessArea mirrors CohesionComponent cases. Kept separate because WeaknessArea is OptimizeEngine's domain concept (what to fix), while CohesionComponent is CohesionEngine's domain concept (what to measure). Unification deferred to ViewModel layer.

### Recalculation Triggers
- Item added or removed
- Archetype changed
- Season recalibration applied
- NOT during UI rendering

---

## 6. Seasonal Engine (V1) — IMPLEMENTED

File: `archive/Sources/COREEngine/Engines/SeasonalEngine.swift`
Pattern: `public enum SeasonalEngine: Sendable`
Tests: 19 passing in `SeasonalEngineTests.swift`

### Purpose

Adjusts cohesion formula weights based on seasonal context. Detects season from location. Suggests recalibration (never forced).

### Types (defined in SeasonalEngine.swift)

```swift
public struct CohesionWeights: Identifiable, Codable, Sendable {
    public let id: UUID
    public let alignment: Double   // Base: 0.35
    public let density: Double     // Base: 0.30
    public let palette: Double     // Base: 0.20
    public let rotation: Double    // Base: 0.15
}

public struct SeasonalRecommendation: Identifiable, Codable, Sendable {
    public let id: UUID
    public let detectedSeason: SeasonMode?
    public let currentSeason: SeasonMode
    public let shouldRecalibrate: Bool
    public let adjustedWeights: CohesionWeights
}
```

### Season Detection from Latitude

| Latitude | Hemisphere | Mar–Aug | Sep–Feb |
|----------|-----------|---------|---------|
| ≥ 15° | Northern | springSummer | autumnWinter |
| ≤ -15° | Southern | autumnWinter | springSummer |
| -15° < lat < 15° | Equatorial | No auto-detection. User chooses. |

### Seasonal Weight Modifiers (Multiplicative)

**springSummer:**

| Component | Modifier |
|-----------|----------|
| Alignment | ×0.95 |
| Density | ×0.85 |
| Palette | ×1.15 |
| Rotation | ×1.15 |

**autumnWinter:**

| Component | Modifier |
|-----------|----------|
| Alignment | ×1.10 |
| Density | ×1.15 |
| Palette | ×0.85 |
| Rotation | ×0.95 |

After multiplication, **renormalize** so weights sum to 1.0.

### Public API

```swift
public static func detectSeason(latitude: Double, month: Int) -> SeasonMode?
public static func recommend(latitude: Double, month: Int, currentSeason: SeasonMode) -> SeasonalRecommendation
public static func adjustedWeights(for season: SeasonMode) -> CohesionWeights
public static let baseWeights: CohesionWeights
// alignment: 0.35, density: 0.30, palette: 0.20, rotation: 0.15
```

### Edge Cases
- Equatorial latitude: `detectSeason` returns nil, `recommend` sets `shouldRecalibrate = false`
- Same season detected as current: `shouldRecalibrate = false`
- Invalid month (< 1 or > 12): treat as equatorial (no detection)

---

## 7. Structural Evolution (V1) — IMPLEMENTED

File: `archive/Sources/COREEngine/Engines/EvolutionEngine.swift`
Pattern: `public enum EvolutionEngine: Sendable`
Tests: 56 passing in `EvolutionEngineTests.swift`

### Purpose

Tracks wardrobe structural journey over time using narrative phases. Not a score graph — a progression story.

### Types

```swift
public enum EvolutionPhase: String, Codable, CaseIterable, Sendable {
    case foundation, developing, refining, cohering, evolving
}

public enum EvolutionTrend: String, Codable, CaseIterable, Sendable {
    case improving, stable, declining
}

public struct EvolutionSnapshot: Identifiable, Codable, Sendable {
    public let id: UUID
    public let phase: EvolutionPhase
    public let volatility: Double
    public let trend: EvolutionTrend
    public let narrative: String
    public let snapshotCount: Int
    public let createdAt: Date
}
```

### Five Phases

| Phase | Min Snapshots | Score Threshold | Max Volatility |
|-------|--------------|-----------------|----------------|
| Foundation | 0 | — | — |
| Developing | 3 | latest ≥ 30 | — |
| Refining | 7 | last 3 avg ≥ 50 | < 10 |
| Cohering | 12 | last 5 avg ≥ 70 | < 8 |
| Evolving | 20 | last 5 avg ≥ 80 | < 6 |

### Volatility

Standard deviation of last 5 snapshots' `totalScore`. Low: < 6. Medium: 6–10. High: > 10.

### Trend Detection

Based on last 3 snapshots:
- **Improving**: monotonically non-decreasing
- **Declining**: monotonically non-increasing
- **Stable**: neither

### Regression Rules

Phase can regress (never below Foundation):
- Latest score drops > 15 from average of last 5 → regress 1 phase
- Volatility > 15 → regress 1 phase

### Narratives per Phase

| Phase | Narrative |
|-------|-----------|
| Foundation | "Building your wardrobe's structural foundation." |
| Developing | "Your wardrobe is developing clear structural direction." |
| Refining | "Refining structural cohesion across all components." |
| Cohering | "Strong structural coherence emerging across your wardrobe." |
| Evolving | "Your wardrobe has reached structural maturity. Evolving intentionally." |

### Public API

```swift
public static func evaluate(snapshots: [CohesionSnapshot]) -> EvolutionSnapshot
public static func phase(snapshots: [CohesionSnapshot]) -> EvolutionPhase
public static func volatility(snapshots: [CohesionSnapshot]) -> Double
public static func trend(snapshots: [CohesionSnapshot]) -> EvolutionTrend
public static func momentum(snapshots: [CohesionSnapshot]) -> MomentumResult
public static func volatilityLevel(from volatility: Double) -> VolatilityLevel
public static func anchorItems(snapshots: [CohesionSnapshot]) -> [UUID]
public static func snapshotAnchors(items: [WardrobeItem], profile: UserProfile) -> [WardrobeItem]
```

### Momentum

**Types**: `VolatilityLevel` (low/medium/high), `MomentumResult` (trend, volatilityLevel, descriptor).

**Descriptor Matrix (3×3):**

| Trend \ Volatility | Low | Medium | High |
|--------------------|------|--------|------|
| Improving | Upward Stability | Active Strengthening | Rapid Restructuring |
| Stable | Structural Consolidation | Holding Pattern | Unstable Plateau |
| Declining | Gentle Recalibration | Gradual Loosening | Temporary Instability |

< 3 snapshots → `"Structural Emergence"`

### Anchor Items

`anchorItems(snapshots:)`: requires ≥ 5 snapshots, uses last 5 only. Item must appear in ≥ 60% (3 of 5) of snapshots and exist in latest snapshot. Returns max 3 UUIDs, frequency descending.

### Snapshot Anchors

`snapshotAnchors(items:profile:)`: Selects 3–4 structurally representative items.

**Formula:**
```
anchorScore = (alignmentMatch × 0.4) + (categoryCentrality × 0.35) + (usageStability × 0.25)
```

Selection: sort descending, tie-break earlier `createdAt`, require ≥ 2 distinct categories. < 3 items → return all.

---

## 8. Information Architecture

### Tab Bar (5 tabs)

| Tab | Icon | Label | Primary Content |
|-----|------|-------|-----------------|
| 1 | chart.bar | Dashboard | Cohesion score + component breakdown |
| 2 | grid.2x2 | Wardrobe | Item grid + add/edit/delete |
| 3 | arrow.up.right | Optimize | Recommendations + simulation |
| 4 | leaf | Evolution | Phase narrative + trend |
| 5 | person.crop.circle | Profile | Archetype, season, settings |

### Dashboard Screen Layout

```
Dashboard Screen (top to bottom)
├── Greeting Line
│   "Good Morning. Your structure is Coherent."
│   Small, calm, top of screen. Secondary text color.
├── Cohesion Score Block
│   ├── Large centered score (72pt, bold)
│   ├── Status label below ("Coherent")
│   └── Thin horizontal progress bar (forest green fill, rounded)
│       No circular rings. No gamification visuals.
├── Component Grid (2×2)
│   ┌─────────────────┬─────────────────┐
│   │   Alignment     │    Density      │
│   │      78         │      64         │
│   │   Aligned       │   Refining      │
│   ├─────────────────┼─────────────────┤
│   │   Palette       │    Rotation     │
│   │      71         │      85         │
│   │   Coherent      │    Strong       │
│   └─────────────────┴─────────────────┘
│   Tap any card → Component Detail Screen (push)
├── Outfit Preview (Should Have)
│   Static. Small. Not animated. Not rotating.
│   Stone card, soft shadow. Shows 2-4 items.
├── Optimize Preview Card
│   Primary recommendation + projected impact + CTA
└── Evolution Phase Card
    Current phase name + one-line narrative. Tap → Evolution tab.
```

Design principle: CORET is a system that handles clothes, not a fashion app that has numbers. Outfit is present as evidence of structure, not as hero.

### Wardrobe Screen

```
Wardrobe Grid Screen
├── Filter Bar (Category, Archetype, Silhouette, BaseGroup)
├── Item Grid (2-column masonry)
│   └── Item Card: image, name, category, structural tag badges
│   └── Tap → Item Detail Screen
│       ├── Item image, all fields, structural contribution
│       ├── Edit → Edit Item Sheet
│       └── Delete (confirmation: "Removing this item will reduce Density by X.")
└── Add Item FAB → Add Item Sheet (modal)
    ├── Image picker, category, silhouette, baseGroup, temperature, archetype
    └── Save (triggers engine recompute)
```

### Optimize Screen

```
Optimize Screen
├── Weakest Area Indicator
├── Primary Recommendation Card
│   ├── Candidate item description
│   ├── Component impact (e.g., "Density: 52 → 64, +12")
│   ├── Total impact (e.g., "Total: 74 → 78, +4")
│   └── Actions: Mark as Acquired, Dismiss
├── Secondary Recommendations (up to 2, collapsed)
├── Structural Friction Section (items with improvement > 8)
└── Tap → Candidate Detail Screen
```

### Evolution Screen

```
Evolution Screen
├── Current Phase Display (large label + narrative)
├── Trend Indicator (improving / stable / declining)
├── Volatility Indicator
└── Phase History → Evolution Detail Screen
```

### Profile Screen

```
Profile Screen
├── Archetype Section (primary + secondary + edit)
├── Season Section (current mode + recalibration suggestion)
└── Settings Section (About, Pro upgrade)
```

### Navigation Patterns
- **Tab switch**: instant, no animation
- **Push**: item detail, component detail, candidate detail, evolution detail
- **Sheet (modal)**: add item, edit item, archetype edit, season recalibration
- **Alert**: delete confirmation
- Level 0 (tabs) and Level 1 (detail screens) only. No Level 2 in V1.

### State Update Rules

Full engine recompute triggered by: item added/deleted/edited (structural fields), archetype changed, seasonal recalibration applied. NOT during UI rendering.

### Edge Cases

| State | Behavior |
|-------|----------|
| Empty wardrobe | Dashboard: "System not yet structured." Optimize disabled. |
| Single category dominance | Structural imbalance warning |
| < 3 snapshots | Evolution: "Structural history forming." |

---

## 9. UI Specification

### Color Tokens

| Token | Hex | Usage |
|-------|-----|-------|
| background | #2F2A26 | App background, warm dark taupe |
| cardBackground | #E7E2DA | Card surfaces, light stone |
| accent | #2F4A3C | Buttons, active tab, highlights, positive signals |
| accentPressed | #253D30 | Button press state |
| textPrimary | #1F1C1A | Primary text on light surfaces |
| textSecondary | #6B625C | Secondary text |
| textMuted | #9A918A | Muted metadata, captions |
| textOnDark | #EAE5DE | Text on dark backgrounds |
| destructive | #7A3E3E | Structural friction alerts, destructive actions |
| divider | #4A4440 | Subtle dividers on dark backgrounds |
| cardDivider | #D0C8C0 | Dividers on card surfaces |

### Typography

All fonts: SF Pro (system font on iOS). No decorative fonts.

| Style | Font | Size | Weight | Usage |
|-------|------|------|--------|-------|
| logo | SF Pro Display | 20pt | Semibold (600) | CORET header |
| scoreDisplay | SF Pro Display | 72pt | Bold (700) | Numeric score |
| statusLabel | SF Pro Display | 22pt | Semibold (600) | "Coherent", "Aligned" |
| h1 | SF Pro Display | 28–32pt | Semibold (600) | Screen titles |
| h2 | SF Pro Display | 22–24pt | Medium (500) | Section headers |
| h3 | SF Pro Text | 17pt | Semibold (600) | Card titles |
| body | SF Pro Text | 16pt | Regular (400) | Body text |
| caption | SF Pro Text | 13–14pt | Regular (400) | Secondary info |
| tag | SF Pro Text | 12pt | Medium (500) | Category tags |

### Spacing Scale (8pt base)

| Token | Value | Usage |
|-------|-------|-------|
| xs | 4pt | Tight inner spacing |
| sm | 8pt | Between small elements |
| md | 16pt | Card internal padding |
| lg | 24pt | Vertical section spacing |
| xl | 32pt | Large separation |
| xxl | 48pt | Screen-level spacing |

Screen margin: 20pt. Card internal padding: 16–20pt.

### Corner Radius

| Element | Radius |
|---------|--------|
| Card | 18–22pt |
| Button | 12pt |
| Tag/chip | 8pt |
| Item image | 12pt |

Shadow: very subtle (opacity < 8%). No circular progress rings.

### Animations

Duration: 200–300ms. Curve: ease-in-out. Never bouncy. Never springy.

| Element | Duration | Properties |
|---------|----------|------------|
| Card appear | 200ms | opacity 0→1, scale 0.95→1.0 |
| Score update | 300ms | numeric count-up |
| Tab switch | none | Instant |
| Button press | 100ms | scale 1.0→0.97 |
| Status change | 300ms | crossfade text |
| Transitions | 200ms | fade + 4–8pt vertical movement |

Haptics: soft, medium impact. No confetti. No achievement badges. No gamified rewards.

### Layout Patterns

- **Wardrobe Grid**: 2-column masonry, 16pt gap, 20pt screen margin.
- **Score display**: large centered score (72pt), status label below, horizontal progress bar.
- **Component grid**: 2×2 on dashboard. Each card: name + score + descriptor.
- **FAB**: 56pt diameter, accent color, bottom-right, 24pt inset.
- **Touch targets**: minimum 44×44pt. Contrast ratio > 4.5:1.

### Design Rules

- Satisfaction comes from clarity, not stimulation.
- If any screen feels loud, busy, playful, or overstimulating — it is wrong.
- No gradients. No heavy shadows. Flat with subtle depth via color.
- Image treatment: background neutralization, soft shadow, uniform padding, consistent crop ratio.

---

## 10. Brand Foundation

### Positioning
Personal wardrobe operating system measuring, optimizing, and evolving wardrobe structure.

Strategic comparison: closer to Notion (structure), YNAB (control), Obsidian (system-thinking). Does NOT compete with Pinterest, Zara, or Instagram fashion culture.

### Emotional Core
- Internal feeling: Control
- External effect: Cohesive presence

### Target Audience
- Primary: Professionals 25–40 who value structure, clarity, intentional identity
- Secondary: Style-conscious younger users

### Tone
Calm. Architectural. Precise. Gender-neutral. Non-dramatic. Non-preachy.

Never say: "You should", "This is wrong", "Bad score"
Instead: "Structural opportunity", "Room to strengthen", "Recalibrate"

### Visual Identity
- Warm dark taupe background (not black, not gray — warm)
- Light stone cards (not white — warm off-white)
- Deep muted forest green accent (not bright — quiet confidence)
- Logo: CORET in uppercase, spaced typography
- No gradients. No shadows. Flat with subtle depth via color.
- Soft animations: never abrupt, never slow. 200–300ms ease-in-out.

### Product Principles
1. Deterministic first
2. Explainable always
3. Control over hype
4. Structure over trend
5. Calm over stimulation
6. Premium over mass

---

## 11. Monetization

Primary model: **B2C subscription SaaS.**
Primary direction: **Tools (Roadmap + Planning)**. Not depth. Not ML.

Free gives structural understanding. Pro gives structural control.

### Free (V1)
- Full CohesionEngine (all components, full breakdown)
- Basic Optimize (1 primary candidate)
- SeasonalEngine (full)
- StructuralEvolution (phase + narrative)
- Full wardrobe management

### Pro (V1.5+ — not in V1 launch)
- **Roadmap Mode**: multi-step optimize, 2–3 steps ahead
- **Drift Detection**: early instability alerts, structural friction tracking
- **Snapshot Compare**: month-to-month analysis, component trend visibility
- **Advanced Density Tiering**: high-quality outfit scoring, structural depth insight

Target pricing: $9–12/month.

### Revenue Target
€1–3M ARR for sustainability. 5,000–10,000 paying users.

### V1 Monetization Boundary
No paywall in first release. Pro activates in V1.5.

### Explicitly NOT in V1
Machine learning, auto color detection, retail integrations, social features, budget tools, cross-platform, gamification, push notifications, multi-profile.

---

## 12. Scaling Strategy

### Execution Philosophy
V1 — Stable deterministic core.
V1.5 — Deeper structural tools (monetized).
V2 — Intelligent overlay.
V3 — Platform expansion.

Core engine remains deterministic and explainable. No black-box AI replaces the structural model.

### Phase 1 — Deterministic Core (Current)
Rule-based Cohesion engine ✅, Optimize engine ✅, Seasonal recalibration ✅, Structural evolution ✅, Local-first architecture.

### Phase 2 — Structural Intelligence Layer
Outfit-level synergy scoring, high-cohesion pair detection, structural drift detection. Pro-only deep analytics. Still deterministic.

### Phase 3 — Behavioral Learning Layer (Optional ML)
ML added ONLY as behavioral layer (preference weighting, override pattern detection, archetype adaptation). ML will NOT replace the structural engine — it augments it.

### Phase 4 — Commerce Layer (Optional)
Source similar structural roles, affiliate integration, structural purchase simulation. Commerce must never compromise structural integrity.

### Phase 5 — Platform Expansion
Swift core remains central. Wrapped for SwiftUI iOS, backend service, React Native bridge, Web. Engine remains platform-agnostic.

---

## 15. SwiftData Persistence Architecture — NOT YET IMPLEMENTED

File to reference: `docs/swiftdata_model_spec_v1.md`
Status: Blocked (requires Mac + SwiftData)

### Architectural Principles
1. SwiftData stores raw state. Engines compute derived state.
2. Derived state is NOT permanently stored unless explicitly cached.
3. No engine mutates SwiftData directly.
4. UI interacts with ViewModels. ViewModels trigger engine recomputation.
5. Snapshots are immutable once stored.

### Entities

**WardrobeItemEntity**: id, createdAt, updatedAt, category, silhouette, baseGroup, temperature, archetypeTag, usageCount, isArchived (default false).

**UserProfileEntity**: id, createdAt, primaryArchetype, secondaryArchetype, latitude?, longitude?, seasonMode, lastRecalibrationDate?, recalibrationCooldownUntil?, lastEngineRecompute?. Single instance in V1.

**EvolutionSnapshotEntity**: id, snapshotDate, totalScore, alignment, density, palette, rotation, phaseRawValue, volatility, isSeasonAdjusted. Immutable. Created on first day of month OR major structural shift (>10 score delta).

**EngineCacheEntity** (optional): id, lastComputedAt, all score fields, weakestComponent, optimizePrimaryRaw?, optimizeSecondaryRaw. Invalidated on any structural mutation. Never authoritative.

### Delete Rules
- WardrobeItem: hard delete, triggers recompute.
- EvolutionSnapshot: never auto-deleted. Only via full profile reset.
- Profile reset cascades: deletes all items, all snapshots, cache.

### Data Integrity
- category, silhouette, baseGroup: required (save rejected if empty).
- primaryArchetype != secondaryArchetype.

### Migration Strategy
- Additive migrations only. No field renames without mapping.
- EvolutionSnapshotEntity must remain backward-compatible.
- ModelVersion 1 for V1.

---

## 16. ViewModel Architecture — NOT YET IMPLEMENTED

File to reference: `docs/viewmodel_architecture_v1.md`
Status: Blocked (requires Mac + SwiftUI)

### Layer Model
```
Layer 1 — SwiftData Entities (persistence)
Layer 2 — ViewModels (coordination)
Layer 3 — Engines (computation)
Layer 4 — SwiftUI Views (presentation)
```

Flow: User Action → ViewModel → EngineCoordinator → Engine → Snapshot → SwiftData → UI Refresh

### EngineCoordinator (Critical)

Single coordination layer. Responsibilities: fetch persisted data, convert entities → domain models, run engines, update cache, create snapshots, return immutable snapshot objects.

**ViewModels never call engines directly. They call EngineCoordinator.**

### 5 ViewModels

| ViewModel | Purpose | Key Actions |
|-----------|---------|-------------|
| DashboardViewModel | Expose current structural state | Pull to refresh, app foreground |
| WardrobeViewModel | Manage wardrobe persistence | addItem, editItem, deleteItem → recompute |
| OptimizeViewModel | Expose simulation results | markAsAcquired, dismiss, resimulate |
| EvolutionViewModel | Expose maturity history | Read-only. Snapshots immutable. |
| ProfileViewModel | System configuration | updateArchetypes, updateLocation, recalibrate, reset |

### Concurrency
- Engine runs on background thread
- UI updates on main thread
- No parallel engine runs allowed
- Recompute requests queued if already running

### Anti-Patterns (Forbidden)
ViewModels must NOT: contain structural logic, modify engine math, cache business rules, duplicate calculations, or call engines independently.

---

## 19. V2 Data Model

All types live in `engine/Sources/COREEngine/Models/`. All public types are Codable, Sendable. Structs are Identifiable. Enums are CaseIterable.

### Enums

**Category**: `upper`, `lower`, `shoes`, `accessory`
Replaces V1 `ItemCategory`. Outerwear is now `upper` with `temperature: 1`.

**Silhouette**: `fitted`, `relaxed`, `tapered`, `oversized`, `slim`, `regular`, `wide`, `none`
Flat enum (8 values). Validation is ViewModel's job — engine accepts any combination.

**BaseGroup**: `tee`, `shirt`, `knit`, `hoodie`, `blazer`, `coat`, `jeans`, `chinos`, `trousers`, `shorts`, `skirt`, `sneakers`, `boots`, `loafers`, `sandals`, `belt`, `scarf`, `cap`, `bag`
19 values. Garment TYPE, not color group. Drives archetype affinity scoring.

**ColorTemp**: `warm`, `cool`, `neutral`

**Archetype**: `tailored`, `smartCasual`, `street`
(Renamed: structuredMinimal → tailored, relaxedStreet → street)

**UsageContext**: `everyday`, `smart`, `active` (lower body only)

**ImportSource**: `camera`, `email`, `zalando`, `hm`, `manual`

**ClarityBand**: `fragmentert`, `iUtvikling`, `fokusert`, `krystallklar`
Score ranges: 0–30, 30–60, 60–85, 85–100.

**ClarityTrend**: `improving`, `stable`, `declining`

### Garment (replaces WardrobeItem)

| Field | Type | Notes |
|-------|------|-------|
| id | UUID | `let`, immutable |
| image | String | Path, default "" |
| name | String | Default "" |
| category | Category | Required |
| silhouette | Silhouette | Default `.none` |
| baseGroup | BaseGroup | Required (garment type) |
| temperature | Int? | Layer depth 1/2/3, upper only. nil for non-upper. |
| usageContext | UsageContext? | Lower only |
| colorTemperature | ColorTemp | Default `.neutral` |
| dominantColor | String | Hex, default "#000000" |
| isFavorite | Bool | Default false |
| isKeyGarment | Bool | Default false |
| dateAdded | Date | `let`, immutable |
| source | ImportSource | Default `.manual` |

### UserProfile (simplified)

| Field | Type | Notes |
|-------|------|-------|
| id | UUID | `let`, immutable |
| primaryArchetype | Archetype | Default `.smartCasual` |
| createdAt | Date | `let`, immutable |

No secondary archetype. Engine scores against all 3 archetypes simultaneously.

### Result Types (Models/Scoring.swift)

**CohesionWeights**: `id`, `layerCoverage` (0.25), `proportionBalance` (0.20), `thirdPiece` (0.15), `capsuleRatios` (0.15), `combinationDensity` (0.15), `standaloneQuality` (0.10). Static `.base` accessor.

**CohesionBreakdown**: `id`, 6 sub-score fields, `totalScore`, `itemIDs: Set<UUID>`, `createdAt`. All `let`.

**ClaritySnapshot**: `id`, `score`, `band: ClarityBand`, `archetypeScores: [Archetype: Double]`, `dominantArchetype: Archetype`, `cohesionBreakdown: CohesionBreakdown`, `createdAt`. All `let`.

**ProjectionResult**: `id`, `clarityBefore/After/Delta`, `archetypesBefore/After: [Archetype: Double]`, `combinationsGained/Lost: Int`, `gapsFilled/gapsOpened: [String]`, `breakdownBefore/After: CohesionBreakdown`. All `let`.

Archetype conforms to `CodingKeyRepresentable` for `[Archetype: Double]` Codable support.

---

## 20. V2 CohesionEngine — IMPLEMENTED

File: `engine/Sources/COREEngine/Engines/CohesionEngine.swift`
Tests: 70 passing in `CohesionEngineTests.swift`

### Formula

```
Total = LayerCoverage(0.25) + ProportionBalance(0.20) + ThirdPiece(0.15)
      + CapsuleRatios(0.15) + CombinationDensity(0.15) + StandaloneQuality(0.10)
```

### Public API

```swift
public static func layerCoverageScore(items: [Garment]) -> Double
public static func proportionBalanceScore(items: [Garment]) -> Double
public static func thirdPieceScore(items: [Garment], profile: UserProfile) -> Double
public static func capsuleRatiosScore(items: [Garment], profile: UserProfile) -> Double
public static func combinationDensityScore(items: [Garment], profile: UserProfile) -> Double
public static func standaloneQualityScore(items: [Garment]) -> Double
public static func archetypeAffinity(baseGroup: BaseGroup, archetype: Archetype) -> Double
public static func archetypeScore(items: [Garment], archetype: Archetype) -> Double
public static func allArchetypeScores(items: [Garment]) -> [Archetype: Double]
public static func proportionScore(upper: Silhouette, lower: Silhouette) -> Double
public static func compute(items: [Garment], profile: UserProfile) -> CohesionBreakdown
public static func compute(items: [Garment], profile: UserProfile, weights: CohesionWeights) -> CohesionBreakdown
public static func outfitCount(items: [Garment]) -> Int
public static func strongOutfitCount(items: [Garment], profile: UserProfile) -> Int
```

### 20a. Layer Coverage (weight 0.25)

Filters to `category == .upper`. Groups by `temperature` field: outer(1), mid(2), base(3).
Per-layer depth: 0→0.0, 1→0.6, 2→0.85, 3+→1.0.
Weighted: `outer × 0.35 + mid × 0.30 + base × 0.35` × 100.
Coverage bonus: all 3 layers present → +10 (capped at 100).
nil temperature items ignored.

### 20b. Proportion Balance (weight 0.20)

Pairs every upper × lower (excluding `.none` silhouettes), scores via asymmetric matrix:

```
             slim    regular   tapered   wide
fitted       0.7     0.85      0.9       1.0
relaxed      1.0     0.85      0.7       0.4
tapered      0.8     0.9       0.85      0.65
oversized    1.0     0.8       0.65      0.3
```

Score = `average(pairScores) × 100`. Any silhouette not in matrix → 0.5 (neutral).

Edge cases: No upper or no lower → 0. Both present but all `.none` → 50. Only one side → 0.

### 20c. Third Piece (weight 0.15)

`ratio = thirdPieceCount / max(baseCount, 1)`

Archetype-specific ideal ranges:
- tailored: 0.8–1.5
- smartCasual: 0.5–1.0
- street: 0.3–0.8

Scored via `rangeScore()` with overPenaltyDivisor = 1.0.

### 20d. Capsule Ratios (weight 0.15)

Three equally-weighted sub-scores (÷3):
1. **Upper:Lower ratio** — tailored 1.5–2.5, smartCasual 1.2–2.0, street 1.0–1.5. `rangeScore()` with overPenaltyDivisor = 1.5.
2. **Layer distribution entropy** — Shannon entropy of [layer1, layer2, layer3] counts, normalized × 100.
3. **Category balance entropy** — Shannon entropy of [upper, lower, shoes, accessory] counts, normalized × 100.

### 20e. Combination Density (weight 0.15)

Generate outfits: `uppers × lowers × shoes`. Score each: `proportion(0.40) + archetypeCoherence(0.35) + colorHarmony(0.25)`.
Strong threshold: outfitStrength ≥ 0.65.
Score: `rangeScore(strongPerGarment, idealLower: 1.0, idealUpper: 5.0, overPenaltyDivisor: 5.0)`

**colorHarmony**: 1.0 normally, 0.5 if both warm and cool `colorTemperature` present.

### 20f. Standalone Quality (weight 0.10)

Per-garment versatility averaged across wardrobe. Three sub-dimensions (each 1/3):
1. **Color versatility**: neutral→1.0, warm/cool→0.6
2. **Silhouette flexibility**: compatible partners (proportion ≥ 0.7) / total partner silhouettes. Shoes/accessories → 0.5. `.none` → 0.5.
3. **Archetype breadth**: archetypes where `archetypeAffinity ≥ 0.5` / 3

### 20g. Archetype Affinity Table

| BaseGroup | tailored | smartCasual | street |
|-----------|----------|-------------|--------|
| tee | 0.3 | 0.7 | 1.0 |
| shirt | 1.0 | 0.8 | 0.3 |
| knit | 0.7 | 0.9 | 0.5 |
| hoodie | 0.1 | 0.4 | 1.0 |
| blazer | 1.0 | 0.7 | 0.2 |
| coat | 0.9 | 0.7 | 0.5 |
| jeans | 0.3 | 0.7 | 0.9 |
| chinos | 0.8 | 0.9 | 0.4 |
| trousers | 1.0 | 0.6 | 0.2 |
| shorts | 0.2 | 0.6 | 0.8 |
| skirt | 0.6 | 0.7 | 0.5 |
| sneakers | 0.2 | 0.6 | 1.0 |
| boots | 0.7 | 0.7 | 0.8 |
| loafers | 1.0 | 0.8 | 0.2 |
| sandals | 0.1 | 0.5 | 0.6 |
| belt | 0.9 | 0.7 | 0.4 |
| scarf | 0.7 | 0.8 | 0.5 |
| cap | 0.1 | 0.3 | 0.9 |
| bag | 0.7 | 0.7 | 0.6 |

---

## 21. V2 ClarityEngine — IMPLEMENTED

File: `engine/Sources/COREEngine/Engines/ClarityEngine.swift`
Tests: 23 passing in `ClarityEngineTests.swift`

### Formula

```
clarityBase = primaryArchetypeScore × 0.60 + cohesionTotal × 0.40
breadthBonus = if bestSecondaryArchetype > 50: min((secondary - 50) × 0.1, 5.0), else 0
clarityScore = min(clarityBase + breadthBonus, 100)
```

### Public API

```swift
public static func compute(items: [Garment], profile: UserProfile) -> ClaritySnapshot
public static func band(from score: Double) -> ClarityBand
public static func trend(history: [ClaritySnapshot]) -> ClarityTrend
```

### Clarity Bands

| Score Range | Band |
|-------------|------|
| 0–29 | .fragmentert |
| 30–59 | .iUtvikling |
| 60–84 | .fokusert |
| 85–100 | .krystallklar |

### Trend Detection

Based on last 3 snapshots: monotonically increasing (some increase) → `.improving`, monotonically decreasing → `.declining`, all equal or mixed → `.stable`. < 3 snapshots → `.stable`.

---

## 22. V2 ScoreProjector — IMPLEMENTED

File: `engine/Sources/COREEngine/Engines/ScoreProjector.swift`
Tests: 22 passing in `ScoreProjectorTests.swift`

### Public API

```swift
public static func project(adding: Garment, to: [Garment], profile: UserProfile) -> ProjectionResult
public static func reverseProject(removing: Garment, from: [Garment], profile: UserProfile) -> ProjectionResult
```

### Algorithm

Both compute `ClarityEngine.compute()` twice (with and without target) and diff the results.

**project (adding):** combinationsGained = outfitCount(after) - outfitCount(before). gapsFilled = categories/layers that went from 0→≥1.

**reverseProject (removing):** combinationsLost = outfitCount(before) - outfitCount(after). gapsOpened = categories/layers that went from ≥1→0.

### Gap Detection

**Category gaps**: all 4 categories. Format: `"category:upper"`, `"category:shoes"`, etc.
**Layer gaps**: temperature layers 1, 2, 3 for upper items. Format: `"layer:1"`, `"layer:2"`, `"layer:3"`.

Edge cases: Symmetry — project(add X) then reverseProject(remove X) → net zero delta.

---

## 23. V2 Scoring Helpers (Internal)

File: `engine/Sources/COREEngine/Helpers/ScoringHelpers.swift`
Visibility: `internal` — shared across V2 engines, not part of public API.

**rangeScore(value:idealLower:idealUpper:overPenaltyDivisor:) → Double (0–100)**
In range → 100. Below → `(value/idealLower) × 100`. Above → `max(0, (1 - (value-idealUpper)/divisor) × 100)`.

**normalizedEntropy(_ counts: [Int]) → Double (0–1)**
Shannon entropy normalized by log₂(n). Perfect distribution → 1.0. < 2 non-zero buckets → 0.

**plurality<T>(_ items: [T]) → T?**
Returns most frequent item. Returns nil on tie.

**generateOutfits(from items: [Garment]) → [[Garment]]**
All combinations: `uppers × lowers × shoes`. Accessories excluded. Empty if any required category missing.

---

## 24. V2 IdentityResolver — IMPLEMENTED

File: `engine/Sources/COREEngine/Engines/IdentityResolver.swift`
Model: `engine/Sources/COREEngine/Models/Identity.swift`
Tests: 15 passing in `IdentityResolverTests.swift`

### Purpose

Derives structural identity from wardrobe composition → label, tags, and prose for Dashboard hero and Journey screen.

### WardrobeIdentity Type

`id`, `dominantSilhouette: Silhouette?`, `dominantColorTemperature: ColorTemp`, `dominantArchetype: Archetype`, `identityLabel: String`, `tags: [String]`, `prose: String`, `createdAt: Date`.

### Public API

```swift
public static func resolve(items: [Garment], profile: UserProfile) -> WardrobeIdentity
public static func identityLabel(items: [Garment], profile: UserProfile) -> String
public static func identityTags(items: [Garment], profile: UserProfile) -> [String]
```

### Algorithm

1. **dominantSilhouette**: `plurality()` over non-`.none` silhouettes. Tie → nil.
2. **dominantColorTemperature**: `plurality()` over all colorTemps. Tie → `.neutral`.
3. **dominantArchetype**: `allArchetypeScores()`, highest wins. Tie → `profile.primaryArchetype`.
4. **identityLabel**: `"silhouetteLabel · colorTempLabel"`. Nil silhouette → "Blandet".
5. **tags** (max 4): silhouette, color temp, archetype, conditional "Lag-vennlig" if ≥2 distinct upper layers.
6. **prose**: Norwegian lookup from silhouette × colorTemp × archetype.

Edge cases: Empty → label "Blandet · Nøytral", tags `["Ukjent profil"]`, prose "Legg til plagg for å utlede profil."

---

## 25. V2 KeyGarmentResolver — IMPLEMENTED

File: `engine/Sources/COREEngine/Engines/KeyGarmentResolver.swift`
Tests: 13 passing in `KeyGarmentResolverTests.swift`

### Purpose

Per-garment combination analysis. Counts outfit participation, marks key garments (≥20%).

### GarmentRole Type (runtime-only, NOT Codable)

`id`, `garmentID`, `combinationCount`, `strongCombinationCount`, `totalOutfitCount`, `combinationPercentage`, `isKeyGarment`, `roleDescriptor`, `archetypeContributions: [Archetype: Double]`.

### Public API

```swift
public static func role(for: Garment, in: [Garment], profile: UserProfile) -> GarmentRole
public static func roles(for: [Garment], profile: UserProfile) -> [GarmentRole]
public static func keyGarmentIDs(items: [Garment], profile: UserProfile) -> [UUID]
public static let keyGarmentThreshold: Double  // 0.20
```

### Algorithm

1. Generate all outfits via `ScoringHelpers.generateOutfits()`.
2. Count outfits containing garment → `combinationCount`.
3. Filter by `outfitStrength >= 0.65` → `strongCombinationCount`.
4. `combinationPercentage = combinationCount / totalOutfitCount`.
5. `isKeyGarment = combinationPercentage >= 0.20`.
6. Accessories always 0% (excluded from outfit generation).

---

## 26. V2 MilestoneTracker — IMPLEMENTED

File: `engine/Sources/COREEngine/Engines/MilestoneTracker.swift`
Tests: 38 passing in `MilestoneTrackerTests.swift`

### Types

- **MilestoneType**: `journeyStarted`, `gapFilled`, `archetypeMilestone`, `phaseAdvanced`, `ratioShifted`, `clarityPeak`
- **JourneyPhase**: `building`, `developing`, `refining`, `cohering`, `evolving`
- **JourneyTrend**: `improving`, `stable`, `declining`
- **JourneyVolatilityLevel**: `low` (<6), `medium` (6–10), `high` (>10)
- **Milestone**: `id`, `type`, `title`, `description`, `snapshotIndex`, `createdAt`
- **JourneyMomentum**: `id`, `trend`, `volatilityLevel`, `descriptor`
- **JourneySnapshot**: `id`, `phase`, `volatility`, `trend`, `narrative`, `snapshotCount`, `createdAt`

### Public API

```swift
public static func evaluate(history: [ClaritySnapshot]) -> JourneySnapshot
public static func phase(history: [ClaritySnapshot]) -> JourneyPhase
public static func volatility(history: [ClaritySnapshot]) -> Double
public static func trend(history: [ClaritySnapshot]) -> JourneyTrend
public static func volatilityLevel(from: Double) -> JourneyVolatilityLevel
public static func momentum(history: [ClaritySnapshot]) -> JourneyMomentum
public static func milestones(history: [ClaritySnapshot]) -> [Milestone]
public static func clarityDelta(history: [ClaritySnapshot], window: Int) -> Double
```

### Phase Thresholds

Same as V1: building→developing@3+score≥30, refining@7+avg≥50+vol<10, cohering@12+avg≥70+vol<8, evolving@20+avg≥80+vol<6. Regression: latest < last5avg-15 OR vol>15 → drop 1 phase.

### Momentum Descriptor Matrix (3×3)

| Trend \ Volatility | Low | Medium | High |
|--------------------|-----|--------|------|
| Improving | Upward Stability | Active Strengthening | Rapid Restructuring |
| Stable | Structural Consolidation | Holding Pattern | Unstable Plateau |
| Declining | Gentle Recalibration | Gradual Loosening | Temporary Instability |

< 3 snapshots → "Structural Emergence".

### Milestones Detected

- `journeyStarted` — first snapshot
- `clarityPeak` — new all-time high score
- `archetypeMilestone` — score crosses 60/75/90
- `phaseAdvanced` — phase transitions upward

Narratives in Norwegian. Regression narrative: "Garderoben rekalibrerer. Dette er en del av prosessen."

---

## 27. V2 SeasonalEngineV2 — IMPLEMENTED

File: `engine/Sources/COREEngine/Engines/SeasonalEngineV2.swift`
Tests: 26 passing in `SeasonalEngineV2Tests.swift`

### Types

- **Season**: `spring`, `summer`, `autumn`, `winter`
- **SeasonalCoverage**: per-season scores (0–100), `weakestSeason`, `coverage(for:)` accessor
- **SeasonalWeights**: `season` + `CohesionWeights`
- **SeasonalRecommendationV2**: `detectedSeason?`, `currentSeason`, `shouldRecalibrate`, `adjustedWeights`

### Public API

```swift
public static func coverage(items: [Garment]) -> SeasonalCoverage
public static func garmentCoverage(garment: Garment) -> [Season: Double]
public static func detectSeason(latitude: Double, month: Int) -> Season?
public static func adjustedWeights(for: Season) -> CohesionWeights
public static let baseWeights: CohesionWeights
public static func recommend(latitude: Double, month: Int, currentSeason: Season) -> SeasonalRecommendationV2
```

### Coverage Mapping

| Layer + ColorTemp | Spring | Summer | Autumn | Winter |
|-------------------|--------|--------|--------|--------|
| Layer 1 cool/neutral | 0.3 | 0.0 | 1.0 | 1.0 |
| Layer 1 warm | 0.4 | 0.1 | 1.0 | 0.8 |
| Layer 2 (any) | 0.6 | 0.2 | 0.8 | 0.7 |
| Layer 3 warm | 0.8 | 0.6 | 0.5 | 0.3 |
| Layer 3 cool/neutral | 0.9 | 0.8 | 0.4 | 0.3 |
| Non-upper (any) | 0.6 | 0.6 | 0.6 | 0.6 |
| Upper temp nil | treated as layer 2 | | | |

Coverage = average of per-garment values × 100, capped at 100.

### Season Detection (4-season)

Northern (lat≥15): month 3–5→spring, 6–8→summer, 9–11→autumn, 12/1/2→winter. Southern: flipped. Equatorial (|lat|<15): nil.

### Weight Modifiers

Per season, multiplicative modifiers on 6 cohesion weights, then renormalized to sum=1.0. Winter emphasizes layerCoverage+thirdPiece. Summer reduces them, emphasizes standalone quality.

---

## 28. V2 OptimizeEngineV2 — IMPLEMENTED

File: `engine/Sources/COREEngine/Engines/OptimizeEngineV2.swift`
Tests: 19 passing in `OptimizeEngineV2Tests.swift`

### Types

- **GapType**: `missingLayer`, `proportionImbalance`, `archetypeWeakness`, `categoryGap`
- **GapPriority**: `high`, `medium`, `low`
- **GapSuggestion**: `id`, `candidate: Garment`, `clarityDelta`, `label`
- **StructuralGap**: `id`, `type`, `priority`, `title`, `description`, `suggestions: [GapSuggestion]`
- **GarmentFriction**: `id`, `garment`, `clarityBefore`, `clarityAfter`, `clarityImprovement`
- **GapResult**: `id`, `currentClarity`, `gaps: [StructuralGap]`, `friction: [GarmentFriction]`

### Public API

```swift
public static func analyze(items: [Garment], profile: UserProfile) -> GapResult
public static func detectGaps(items: [Garment], profile: UserProfile) -> [StructuralGap]
public static func detectFriction(items: [Garment], profile: UserProfile) -> [GarmentFriction]
```

### Gap Detection Rules

| Gap Type | Condition | Priority |
|----------|-----------|----------|
| categoryGap | Missing upper/lower/shoes | high |
| missingLayer 1 (outer) | No upper with temp=1 | high |
| missingLayer 2 (mid) | No upper with temp=2 | high |
| missingLayer 3 (base) | No upper with temp=3 | medium |
| proportionImbalance | upper:lower ratio outside archetype ideal ± 0.5 | medium |
| archetypeWeakness | Primary archetype score < 50 | high(<30)/medium(30–50) |

Each gap generates up to 2 synthetic `Garment` suggestions, each projected via `ScoreProjector.project()`.

### Friction Detection

Remove each item, recompute clarity. Improvement > 8.0 → flagged as `GarmentFriction`. Sorted by improvement descending.

### Sorting

Gaps sorted: high > medium > low. Within priority: higher clarityDelta first.
