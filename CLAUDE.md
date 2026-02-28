# CORET — Complete System Reference

CORET is a wardrobe operating system. It measures structural cohesion and guides optimization. It is not a fashion app, shopping platform, or budgeting tool. It is a structural system.

Tagline: "Your Wardrobe Operating System."
Secondary: "Built Around Your Core."

Architectural Principle: CORET is engine-first, UI-second. UI is replaceable. Engine is not.

---

## 1. What CORET Is and Is Not

**Is:**
- A personal wardrobe operating system
- A structural measurement and optimization engine
- A deterministic, rule-based scoring system
- A long-term identity tool that evolves with the user

**Is not:**
- A fashion inspiration app
- A shopping platform or retail integration
- A budgeting tool
- A social network
- An ML/AI-powered recommendation engine (V1)

Philosophy: Control over validation. Structure over trend. Identity over status. Optimization over impulse. Measurement without judgment. Creative deviation allowed. CORET measures — the user decides.

---

## 2. Project Structure

```
CORET/
├── CLAUDE.md              ← You are here (complete system reference)
├── CONTINUE.md            ← Session state for resuming
├── README.md
├── docs/
│   ├── brand_foundation.md
│   ├── cohesion_engine_v1.md
│   ├── data_model_v1.md
│   ├── information_architecture_v1.md  ← 5-tab IA, all screens
│   ├── launch_scope_v1.md              ← V1 scope freeze
│   ├── monetization_strategy.md        ← Tools-first monetization
│   ├── optimize_engine_v1.md
│   ├── product_spec.md                 ← SUPERSEDED (see sections 8, 9, 11)
│   ├── seasonal_engine_v1.md           ← SUPERSEDED (see section 6)
│   ├── structural_evolution_v1.md      ← SUPERSEDED (see section 7)
│   ├── ui_specification_v1.md          ← UI tokens, layout, design rules
│   ├── business_vision.md              ← Long-term vision, revenue targets
│   ├── swiftdata_model_spec_v1.md      ← Persistence architecture
│   └── viewmodel_architecture_v1.md    ← ViewModel + EngineCoordinator spec
├── core/                  ← Swift package: COREEngine
│   ├── Package.swift      (swift-tools-version: 6.2)
│   ├── Sources/COREEngine/
│   │   ├── COREEngine.swift           (placeholder)
│   │   ├── Engines/
│   │   │   ├── CohesionEngine.swift   ✅ Complete (57 tests)
│   │   │   ├── OptimizeEngine.swift   ✅ Complete (19 tests)
│   │   │   ├── SeasonalEngine.swift   ✅ Complete (19 tests)
│   │   │   └── EvolutionEngine.swift  ✅ Complete (48 tests)
│   │   └── Models/
│   │       └── WardrobeItem.swift     ✅ Complete (all types + StructuralIdentity)
│   └── Tests/COREEngineTests/
│       ├── COREEngineTests.swift      (scaffold — can be removed)
│       ├── CohesionEngineTests.swift  ✅ 85 tests passing
│       ├── OptimizeEngineTests.swift  ✅ 19 tests passing
│       ├── SeasonalEngineTests.swift  ✅ 19 tests passing
│       └── EvolutionEngineTests.swift ✅ 56 tests passing
├── moodboard/             ← Visual references for UI implementation
│   ├── dashboard/
│   │   ├── dashboard_wireframe.md   ← Full dashboard tab spec + component detail
│   │   └── dashboard_preview.md     ← Quick ASCII reference (superseded by wireframe)
│   ├── evolution/
│   │   ├── evolution_timeline.html    ← Interactive HTML mockup (visual reference)
│   │   └── evolution_wireframe.md     ← Full spec: flat-lay timeline system
│   ├── optimize/
│   │   └── optimize_wireframe.md  ← Optimize tab wireframe + card anatomy
│   ├── onboarding/
│   │   ├── coret_onboarding_v3.html    ← Interactive HTML mockup (visual reference)
│   │   └── onboarding_wireframe.md     ← Full spec: 5-screen onboarding flow
│   ├── profile/
│   │   └── profile_wireframe.md        ← Profile tab spec: identity, season, settings
│   └── wardrobe/
│       ├── wardrobe_wireframe.md     ← CORET wardrobe grid wireframe
│       └── digico_wardrobe_grid.png  ← Grid-only reference (see note below)
└── ios_app/               (empty, future SwiftUI app — requires Mac)
```

**Moodboard note — `digico_wardrobe_grid.png`:**
Reference ONLY for: 2-column grid layout pattern and garment card presentation (clean image, name below, category below name).
Explicitly NOT reference for: prices, brand names, social features (hearts/favorites), shopping UI, lifestyle photography, fashion-discovery language, or editorial styling. These elements contradict CORET's identity as a structural system (see Section 1).

---

## 3. Data Model (V1)

All types live in `core/Sources/COREEngine/Models/WardrobeItem.swift`. All public types are Codable, Sendable. Structs are Identifiable. Enums are CaseIterable.

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

File: `core/Sources/COREEngine/Engines/CohesionEngine.swift`
Pattern: `public enum CohesionEngine: Sendable` — caseless enum namespace, all static functions.
Tests: 85 passing in `CohesionEngineTests.swift`

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

**outfitBuilder vs densityScore validation:** outfitBuilder does NOT filter by `isValidOutfit()`. It scores all structurally complete combinations. Outfits that would fail density validation (archetype conflict, silhouette imbalance, color violations) appear with low scores rather than being excluded. This is intentional — outfitBuilder measures quality on a spectrum, while densityScore uses binary validity.

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

### Design Principles
- Deterministic. No ML.
- Transparent breakdown. All component scores are public.
- Not easily gamed.
- Stable over time.

---

## 5. Optimize Engine (V1) — IMPLEMENTED

File: `core/Sources/COREEngine/Engines/OptimizeEngine.swift`
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

WeaknessArea mirrors CohesionComponent cases (`alignment`, `density`, `palette`, `rotation`). Kept separate because WeaknessArea is OptimizeEngine's domain concept (what to fix), while CohesionComponent is CohesionEngine's domain concept (what to measure). Unification deferred to ViewModel layer where a shared type may make sense.

### Recalculation Triggers
- Item added or removed
- Archetype changed
- Season recalibration applied
- NOT during UI rendering

---

## 6. Seasonal Engine — IMPLEMENTED

File: `core/Sources/COREEngine/Engines/SeasonalEngine.swift`
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

Month ranges use the current date. March = month 3, August = month 8.

### Seasonal Weight Modifiers (Multiplicative)

**springSummer** — lighter wardrobe, more color variety, more rotation:

| Component | Modifier | Rationale |
|-----------|----------|-----------|
| Alignment | ×0.95 | Slightly less strict |
| Density | ×0.85 | Fewer layers, fewer outerwear combos |
| Palette | ×1.15 | Color variety increases |
| Rotation | ×1.15 | More items in rotation |

**autumnWinter** — layering focus, outerwear cohesion, tighter palette:

| Component | Modifier | Rationale |
|-----------|----------|-----------|
| Alignment | ×1.10 | Layering archetype coherence matters |
| Density | ×1.15 | More outerwear combos, layering key |
| Palette | ×0.85 | Darker palette, less variety expected |
| Rotation | ×0.95 | Fewer items rotated |

After multiplication, **renormalize** so weights sum to 1.0:
```
normalizedWeight = modifiedWeight / sum(allModifiedWeights)
```

### Public API

```swift
public static func detectSeason(latitude: Double, month: Int) -> SeasonMode?
// Returns nil for equatorial (|latitude| < 15)

public static func recommend(latitude: Double, month: Int, currentSeason: SeasonMode) -> SeasonalRecommendation

public static func adjustedWeights(for season: SeasonMode) -> CohesionWeights

public static let baseWeights: CohesionWeights
// alignment: 0.35, density: 0.30, palette: 0.20, rotation: 0.15
```

### Edge Cases
- Equatorial latitude: `detectSeason` returns nil, `recommend` sets `shouldRecalibrate = false`
- Same season detected as current: `shouldRecalibrate = false`
- Invalid month (< 1 or > 12): treat as equatorial (no detection)

### Integration with CohesionEngine
CohesionEngine has a weighted overload that SeasonalEngine uses:
```swift
public static func compute(items: [WardrobeItem], profile: UserProfile, weights: CohesionWeights) -> CohesionSnapshot
```
The existing `compute(items:profile:)` delegates to this with `SeasonalEngine.baseWeights`.

---

## 7. Structural Evolution — IMPLEMENTED

File: `core/Sources/COREEngine/Engines/EvolutionEngine.swift`
Pattern: `public enum EvolutionEngine: Sendable`
Tests: 56 passing in `EvolutionEngineTests.swift`

### Purpose

Tracks wardrobe structural journey over time using narrative phases. Not a score graph — a progression story.

### Types (defined in EvolutionEngine.swift)

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

| Phase | Min Snapshots | Score Threshold | Max Volatility | Description |
|-------|--------------|-----------------|----------------|-------------|
| Foundation | 0 | — | — | Default starting phase |
| Developing | 3 | latest ≥ 30 | — | Building structural awareness |
| Refining | 7 | last 3 avg ≥ 50 | < 10 | Targeted improvement |
| Cohering | 12 | last 5 avg ≥ 70 | < 8 | Strong consistency |
| Evolving | 20 | last 5 avg ≥ 80 | < 6 | Mature, intentional adaptation |

### Volatility

Standard deviation of last 5 snapshots' `totalScore`.
```
volatility = stddev(last5.map(\.totalScore))
```
- Low: < 6
- Medium: 6–10
- High: > 10

### Trend Detection

Based on last 3 snapshots:
- **Improving**: each ≥ previous (monotonically non-decreasing)
- **Declining**: each ≤ previous (monotonically non-increasing)
- **Stable**: neither

### Regression Rules

Phase can regress (never below Foundation):
- Latest score drops > 15 from average of last 5 → regress 1 phase
- Volatility > 15 → regress 1 phase
- Regression narrative: "Your wardrobe is recalibrating. This is part of the process."

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

Describes direction and stability over time. Reuses `trend()` and `volatility()` internally.

**Types** (defined in `EvolutionEngine.swift`):
- `VolatilityLevel` (enum): `low` (< 6), `medium` (6–10), `high` (> 10)
- `MomentumResult` (struct): `id`, `trend: EvolutionTrend`, `volatilityLevel: VolatilityLevel`, `descriptor: String`

**Descriptor Matrix** (3×3):

| Trend \ Volatility | Low | Medium | High |
|--------------------|------|--------|------|
| Improving | Upward Stability | Active Strengthening | Rapid Restructuring |
| Stable | Structural Consolidation | Holding Pattern | Unstable Plateau |
| Declining | Gentle Recalibration | Gradual Loosening | Temporary Instability |

< 3 snapshots → `MomentumResult(trend: .stable, volatilityLevel: .low, descriptor: "Structural Emergence")`

### Anchor Items

Identifies structurally consistent items over time via snapshot frequency analysis.

**Algorithm:**
1. Requires ≥ 5 snapshots (else returns empty)
2. Uses last 5 snapshots only
3. Counts frequency of each itemID across snapshots (via `CohesionSnapshot.itemIDs`)
4. Item must appear in ≥ 60% (3 of 5) of snapshots
5. Item must exist in latest snapshot
6. Returns max 3 UUIDs, sorted by frequency descending

### Snapshot Anchors

Selects 3–4 structurally representative items for a snapshot's visual composition on the Evolution timeline. Distinct from `anchorItems(snapshots:)` which analyzes cross-snapshot frequency.

**Function:** `snapshotAnchors(items:profile:) -> [WardrobeItem]`

**Formula:**
```
anchorScore = (alignmentMatch × 0.4) + (categoryCentrality × 0.35) + (usageStability × 0.25)
```

- **alignmentMatch**: primary=1.0, secondary=0.7, else=0.0
- **categoryCentrality**: `categoryWeight × (1 / categoryCount)`. Required categories (top/bottom/shoes) weight 1.0, outerwear 0.7.
- **usageStability**: `1.0 - min(normalizedDeviation, 1.0)`. Deviation = `|usageCount - categoryMean| / max(categoryMean, 1)`.

**Selection rules:**
1. Score all items, sort descending by anchorScore
2. Tie-break: earlier `createdAt` preferred (stability bias)
3. Select top 3–4 items
4. Constraint: at least 2 distinct categories (swap last if needed)
5. < 3 items total → return all items

**Frozen at snapshot creation:** Results stored in `EvolutionSnapshotEntity.snapshotAnchorItems` with structural properties (category, silhouette, baseGroup, temperature) for historical rendering even after item deletion.

### Edge Cases
- 0 snapshots → Foundation phase, volatility 0, trend .stable
- 1–2 snapshots → Foundation or Developing only, trend based on available data
- All snapshots identical score → volatility 0, trend .stable
- < 3 snapshots → momentum returns "Structural Emergence"
- < 5 snapshots → anchorItems returns empty
- snapshotAnchors: empty items → empty, < 3 items → returns all

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

### Screen Map

**Dashboard Tab (Home) — Layout Locked**

Primary purpose: Show system state. Not inspire visually.
Design principle: CORET is a system that handles clothes, not a fashion app that has numbers.

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
│   Each card: stone background, 18-22pt corner radius
│   Component name (caption), score (h2), descriptor (caption muted)
│   Tap any card → Component Detail Screen (push)
│       ├── Component score
│       ├── Explanation of what affects it
│       ├── Top structural contributors
│       ├── Top structural weaknesses
│       └── Navigate to relevant Optimize suggestions
│       (Informational only — no editing)
│   Cards feel modular and embedded, not floating
├── Outfit Preview (Should Have)
│   Static. Small. Not animated. Not rotating.
│   One outfit generated from wardrobe items.
│   Outfit is proof of structure, not main attraction.
│   Stone card, soft shadow, subtle presentation.
│   Shows 2-4 items from wardrobe as clean flat lay.
├── Optimize Preview Card
│   ├── Full width stone card
│   ├── Primary recommendation headline
│   ├── Projected impact (e.g. "Density +9")
│   ├── Short structural explanation
│   └── CTA: "View Optimize" → navigates to Optimize tab
├── Evolution Phase Card
│   ├── Current phase name (e.g. "Refining")
│   ├── One-line narrative
│   └── Tap → Evolution tab
└── Pull to refresh (recompute engine snapshot)
```

Rejected: Vertical column + rotating outfit center.
Reason: Wrong hierarchy. Fashion feel, not system feel.
Outfit is present but as evidence of structure, not as hero or attraction.

**Wardrobe Tab**
```
Wardrobe Grid Screen
├── Filter Bar (Category, Archetype, Silhouette, BaseGroup)
├── Item Grid (2-column masonry)
│   └── Item Card:
│       ├── Clean item image (neutralized background, uniform crop)
│       ├── Item name / description (below image)
│       ├── Category label (below name, caption style)
│       └── Subtle structural tag badges (silhouette, archetype)
│   └── Tap Item → Item Detail Screen (push)
│       ├── Item image (large)
│       ├── All fields displayed
│       ├── Structural contribution impact
│       ├── Alignment match type
│       ├── Usage count
│       ├── Edit button → Edit Item Sheet
│       └── Delete button (confirmation alert)
│           └── Warning: "Removing this item will reduce Density by X."
└── Add Item FAB → Add Item Sheet (modal)
    ├── Image picker
    ├── Category selector (required)
    ├── Silhouette selector (required)
    ├── BaseGroup selector (required)
    ├── Temperature selector
    ├── Archetype tag selector
    └── Save (triggers engine recompute)
```

**Optimize Tab**
```
Optimize Screen
├── Weakest Area Indicator
├── Primary Recommendation Card
│   ├── Candidate item description (category, silhouette, baseGroup, archetype)
│   ├── Component impact (e.g., "Density: 52 → 64, +12")
│   ├── Total impact (e.g., "Total: 74 → 78, +4")
│   ├── "Add to strengthen" label
│   └── Actions: Mark as Acquired, Dismiss suggestion
├── Secondary Recommendations (up to 2, collapsed)
│   └── Tap to expand → same detail as primary
├── Structural Friction Section (only if items flagged, improvement > 8)
│   ├── Friction item card (with image)
│   ├── Impact display (destructive color)
│   └── "Review Impact" → push to Item Detail with friction context
└── Tap any recommendation → Candidate Detail Screen (push)

Optimize is simulation-based only. Does not auto-add items.
```

**Evolution Tab**
```
Evolution Screen
├── Current Phase Display (large label + narrative)
├── Trend Indicator (improving / stable / declining)
├── Volatility Indicator
└── Phase History (push → Evolution Detail Screen)
    ├── Full phase progression timeline
    └── Snapshot history
```

**Profile Tab**
```
Profile Screen
├── Archetype Section
│   ├── Primary archetype display
│   ├── Secondary archetype display
│   └── Edit button → Archetype Edit Sheet
│       ├── Primary picker
│       ├── Secondary picker
│       └── Save (triggers recalculation)
├── Season Section
│   ├── Current season mode
│   ├── Recalibration suggestion (if detected)
│   └── Tap → Season Recalibration Sheet
└── Settings Section
    ├── About CORET
    └── Pro upgrade (if free tier)
```

### Data Ownership

| Screen | Owns | Reads |
|--------|------|-------|
| Dashboard | — | CohesionSnapshot |
| Wardrobe | [WardrobeItem] | — |
| Optimize | — | [WardrobeItem], UserProfile, OptimizeResult |
| Evolution | — | [CohesionSnapshot], EvolutionSnapshot |
| Profile | UserProfile | SeasonalRecommendation |

### Navigation Patterns
- **Tab switch**: instant, no animation
- **Push**: item detail, component detail, candidate detail, evolution detail
- **Sheet (modal)**: add item, edit item, archetype edit, season recalibration
- **Alert**: delete confirmation
- Screen hierarchy: Level 0 (tabs) and Level 1 (detail screens) only. No Level 2 in V1.

### State Update Rules

UI never modifies engine directly. UI triggers events. Engine recalculates deterministically.

Full engine recompute triggered by:
- Item added, deleted, or edited (structural fields)
- Archetype changed
- Seasonal recalibration applied
- NOT during UI rendering

Dashboard always reflects latest snapshot.

### Edge Cases

| State | Behavior |
|-------|----------|
| Empty wardrobe | Dashboard: "System not yet structured." Optimize disabled. |
| Single category dominance | Wardrobe screen: structural imbalance warning |
| Low data history (< 3 snapshots) | Evolution: "Structural history forming." |

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

All fonts: SF Pro (system font on iOS). Clean geometric. No decorative fonts.
Line spacing: 1.25–1.35. No ALL CAPS except logo. Typography must feel restrained.

| Style | Font | Size | Weight | Spacing | Usage |
|-------|------|------|--------|---------|-------|
| logo | SF Pro Display | 20pt | Semibold (600) | 2.5pt | CORET header |
| scoreDisplay | SF Pro Display | 72pt | Bold (700) | 0 | Numeric score (dashboard) |
| statusLabel | SF Pro Display | 22pt | Semibold (600) | 0.5pt | "Coherent", "Aligned" |
| h1 | SF Pro Display | 28–32pt | Semibold (600) | 0 | Screen titles |
| h2 | SF Pro Display | 22–24pt | Medium (500) | 0 | Section headers |
| h3 | SF Pro Text | 17pt | Semibold (600) | 0 | Card titles |
| body | SF Pro Text | 16pt | Regular (400) | 0 | Body text |
| caption | SF Pro Text | 13–14pt | Regular (400) | 0 | Secondary info |
| tag | SF Pro Text | 12pt | Medium (500) | 0.3pt | Category tags, labels |

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

Shadow: very subtle (opacity < 8%). Cards feel embedded, not floating. No circular progress rings.

### Animations

Duration: 200–300ms. Curve: ease-in-out. Never bouncy. Never springy. Never exaggerated.

| Element | Duration | Curve | Properties |
|---------|----------|-------|------------|
| Card appear | 200ms | ease-in-out | opacity 0→1, scale 0.95→1.0 |
| Score update | 300ms | ease-in-out | numeric count-up animation |
| Sheet present | system | system | iOS default sheet |
| Tab switch | none | — | Instant |
| Button press | 100ms | ease-out | scale 1.0→0.97, subtle opacity reduction |
| Status change | 300ms | ease-in-out | crossfade text |
| Transitions | 200ms | ease-in-out | fade + slight vertical movement (4–8pt) |

Haptics: soft, medium impact. No confetti. No achievement badges. No gamified rewards.

### Layout Patterns

**Wardrobe Grid**: 2-column masonry, md (16pt) gap, screen margin (20pt).
**Card**: 16–20pt internal padding. Embedded feel, not floating.
**Score display**: large centered score (72pt), status label below, horizontal progress bar.
**Component grid**: 2×2 grid on dashboard. Each card: name + score + descriptor.
**FAB (add button)**: 56pt diameter, accent color, bottom-right, lg (24pt) inset.
**Recommendation card**: full-width, card background, impact numbers right-aligned. Primary uses accent border.
**Touch targets**: minimum 44×44pt. Accessibility contrast ratio > 4.5:1.

### Design Rules

- Satisfaction comes from clarity, not stimulation.
- If any screen feels loud, busy, playful, or overstimulating — it is wrong.
- Numbers animate upward smoothly (count-up effect).
- No gradients. No heavy shadows. Flat with subtle depth via color.
- Image treatment: background neutralization, soft shadow, uniform padding, consistent crop ratio.

---

## 10. Brand Foundation

### Positioning
Personal wardrobe operating system measuring, optimizing, and evolving wardrobe structure.

Strategic comparison: closer to Notion (structure), YNAB (control), Obsidian (system-thinking). Does NOT compete with Pinterest, Zara, or Instagram fashion culture. CORET is about structure, not consumption.

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

### Product Identity
- Long-term system, not short-term style phase
- Seasonal recalibration supported
- Structural evolution tracked
- Rule-based engine in V1
- We build slowly, carefully, intentionally. We do not chase trends.

---

## 11. Monetization

Primary model: **B2C subscription SaaS.**
Primary direction: **Tools (Roadmap + Planning)**. Not depth. Not ML.

Free gives structural understanding. Pro gives structural control.
Do NOT lock core measurement behind a paywall. Do NOT create artificial friction.
Users pay for clarity of next step, multi-step roadmaps, and long-term oversight — not for basic scoring.

### Free (V1)
- Full CohesionEngine (all components, full breakdown)
- Basic Optimize (1 primary candidate)
- SeasonalEngine (full)
- StructuralEvolution (phase + narrative)
- Full wardrobe management

Free version is complete and worthy.

### Pro (V1.5+ — not in V1 launch)
- **Roadmap Mode**: multi-step optimize, 2–3 steps ahead, prioritized action sequence
- **Drift Detection**: early instability alerts, structural friction tracking
- **Snapshot Compare**: month-to-month analysis, component trend visibility
- **Advanced Density Tiering**: high-quality outfit scoring, structural depth insight

Target pricing: $9–12/month.

### Future Pro+ (V2+)
- Behavioral overlay
- Environmental intelligence
- Cost-aware planning

### Revenue Target
€1–3M ARR for sustainability. 5,000–10,000 paying users.
Exit is optional. Sustainability is mandatory.

### V1 Monetization Boundary
No paywall in first release. Pro activates in V1.5.

### Explicitly NOT in V1
- Machine learning
- Auto color detection
- Retail integrations / shopping / affiliate
- Social features
- Budget tools
- Cross-platform support
- Gamification, badges, streaks
- Push notifications
- Multi-profile support

---

## 12. Scaling Strategy

### Execution Philosophy
V1 — Stable deterministic core.
V1.5 — Deeper structural tools (monetized).
V2 — Intelligent overlay.
V3 — Platform expansion.

Core engine remains deterministic and explainable. No black-box AI replaces the structural model.

### Long-Term Optional Paths
If traction is strong: white-label engine licensing, commerce integration (structural role matching), enterprise partnerships, API exposure. These are not required for success.

### Phase 1 — Deterministic Core (Current)
- Rule-based Cohesion engine ✅
- Dynamic Optimize engine ✅
- Seasonal recalibration ✅
- Structural evolution ✅
- Local-first architecture

### Phase 2 — Structural Intelligence Layer
- Outfit-level synergy scoring
- High-cohesion pair detection
- Impact-per-outfit modeling
- Structural drift detection
- Pro-only deep analytics
- Advanced rotation modeling
- Still deterministic. No ML.

### Phase 3 — Behavioral Learning Layer (Optional ML)
ML added ONLY as behavioral layer:
- User preference weighting
- Override pattern detection
- Archetype adaptation over time
- Predictive structural decay

ML will NOT replace the structural engine. It augments it.

### Phase 4 — Commerce Layer (Optional)
- Source similar structural roles
- Affiliate integration
- Structural purchase simulation
- Budget-aware optimization

Commerce must never compromise structural integrity.

### Phase 5 — Platform Expansion
- Swift core remains central engine
- Wrapped for: SwiftUI iOS, Backend service, React Native bridge, Web
- Engine remains platform-agnostic

---

## 13. Build Status

**Swift package compiles clean on Swift 6.2.**

Build: `cd core && swift build`
Test: `cd core && swift test`

**180/180 tests passing.**

### What Is Done

| Component | File | Tests | Status |
|-----------|------|-------|--------|
| Data models (all types) | `Models/WardrobeItem.swift` | — | ✅ Complete |
| CohesionEngine + structuralIdentity + itemContributions + outfitBuilder + removalImpact | `Engines/CohesionEngine.swift` | 85 | ✅ Complete |
| OptimizeEngine + result types | `Engines/OptimizeEngine.swift` | 19 | ✅ Complete |
| SeasonalEngine + types | `Engines/SeasonalEngine.swift` | 19 | ✅ Complete |
| EvolutionEngine + momentum + anchorItems + snapshotAnchors | `Engines/EvolutionEngine.swift` | 56 | ✅ Complete |
| Package.swift | `core/Package.swift` | — | ✅ Complete |

### What Is Not Done

| Component | File | Spec | Status |
|-----------|------|------|--------|
| SwiftData persistence | TBD | Section 15 | Blocked (requires Mac) |
| ViewModel + EngineCoordinator | TBD | Section 16 | Blocked (requires Mac) |
| SwiftUI iOS app | `ios_app/` | Sections 8, 9 | Blocked (requires Mac) |

---

## 14. Current Blocker and Build Order

### Current Blocker
SwiftUI requires Mac to build and test. Development machine is Arch Linux — cannot run SwiftUI or Xcode.

### All Engine Work Complete (on Linux)

All four engines are implemented and tested:
1. ✅ **CohesionEngine** — 85 tests
2. ✅ **OptimizeEngine** — 19 tests
3. ✅ **SeasonalEngine** — 19 tests
4. ✅ **EvolutionEngine** — 56 tests

### When Mac Is Available
- Import COREEngine as local Swift Package
- Build SwiftUI app on top of finished engines + specs
- Implement SwiftData persistence wrapping engine types

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

**WardrobeItemEntity**: id, createdAt, updatedAt, category (String rawValue), silhouette, baseGroup, temperature, archetypeTag, usageCount, isArchived (default false).

**UserProfileEntity**: id, createdAt, primaryArchetype, secondaryArchetype, latitude?, longitude?, seasonMode, lastRecalibrationDate?, recalibrationCooldownUntil?, lastEngineRecompute?. Single instance in V1.

**EvolutionSnapshotEntity**: id, snapshotDate, totalScore, alignment, density, palette, rotation, phaseRawValue, volatility, isSeasonAdjusted. Immutable. Created on first day of month OR major structural shift (>10 score delta).

**EngineCacheEntity** (optional performance layer): id, lastComputedAt, totalScore, alignment, density, palette, rotation, weakestComponent, optimizePrimaryRaw?, optimizeSecondaryRaw. Invalidated on any structural mutation. Never authoritative — if missing, engine recomputes.

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
- ModelVersion 1 for V1. Versioned container for future.

### Non-Goals V1
No remote database. No multi-device sync. No shared wardrobes. No analytics tracking. CORET is local-first.

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

Single coordination layer — the bridge between persistence and engine logic.

Responsibilities:
- Fetch persisted data, convert entities → domain models
- Run CohesionEngine, OptimizeEngine, SeasonalEngine, EvolutionEngine
- Update cache, create snapshots when required
- Return immutable snapshot objects

**ViewModels never call engines directly. They call EngineCoordinator.**

### 5 ViewModels

| ViewModel | Purpose | Key Actions |
|-----------|---------|-------------|
| DashboardViewModel | Expose current structural state | Pull to refresh, app foreground |
| WardrobeViewModel | Manage wardrobe persistence | addItem, editItem, deleteItem → recompute |
| OptimizeViewModel | Expose simulation results | markAsAcquired, dismiss, resimulate |
| EvolutionViewModel | Expose maturity history | Read-only. Snapshots immutable. |
| ProfileViewModel | System configuration | updateArchetypes, updateLocation, recalibrate, reset |

### Recompute Flow
1. Persistence mutation (SwiftData save)
2. EngineCoordinator.recompute()
3. Cache update
4. Snapshot creation if needed
5. Notify relevant ViewModels
6. UI re-renders

### Concurrency
- Engine runs on background thread
- UI updates on main thread
- No parallel engine runs allowed
- Recompute requests queued if already running

### Anti-Patterns (Forbidden)
ViewModels must NOT: contain structural logic, modify engine math, cache business rules, duplicate calculations, or call engines independently. All engine interaction flows through EngineCoordinator.

---

## 17. Technical Conventions

- **Language**: Swift 6 (strict concurrency). swift-tools-version: 6.2.
- **All public types**: Codable, Sendable. Structs also Identifiable. Enums also CaseIterable.
- **Engine pattern**: Caseless `enum` with `static` functions. No state. Pure functions. Deterministic.
- **Architecture**: Engine is a standalone Swift package (`core/COREEngine`). No UIKit/SwiftUI dependencies in the engine. iOS app will import the package.
- **Storage**: SwiftData (local-first). No cloud sync in V1.
- **Testing**: Swift Testing framework (`import Testing`, `@Test`, `#expect`). NOT XCTest. Engines must be deterministic and fully testable.
- **No external dependencies** in the engine package.
- **File organization**: Models in `Models/`, Engines in `Engines/`, Tests mirror source structure.
- **Edge cases**: All engines must handle empty input gracefully (return 0 or default state, never crash).
- **Floating point**: Use tolerance (< 0.001) for equality checks in tests, not `==`.

---

## 18. Autonomous Session Protocol

### Token Monitoring
- Claude Code must monitor context usage continuously
- When context reaches ~70% used: finish current task, do NOT start new ones
- When context reaches ~85% used: immediately wrap up and save state
- Never start a task you cannot finish within remaining context

### Auto-save Trigger
When context hits 70%+, automatically:
1. Run: `cd core && swift build && swift test`
2. Update CONTINUE.md with:
   - Timestamp
   - Completed this session (bullet list)
   - Current test status (X/Y passing)
   - In-progress work (if any was interrupted)
   - Exact next prompt to paste (complete, self-contained)
   - Any important decisions or trade-offs
3. Run: `git add -A && git commit -m "session: [summary]"`
4. Print to terminal: `SESSION SAVED. Next: Read CONTINUE.md and resume.`

### CONTINUE.md Format
```
# CORET – Continue
Last updated: [timestamp]

## Completed This Session
- [x] item 1
- [x] item 2

## Build Status
swift build: pass/fail
swift test: X/Y passing

## In Progress (if interrupted)
[description or "nothing interrupted"]

## Next Session Prompt
[Complete ready-to-paste prompt]

## Decisions Made
[Any trade-offs or architectural decisions]
```
