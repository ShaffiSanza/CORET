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
│   ├── information_architecture.md
│   ├── monetization_strategy.md
│   ├── optimize_engine_v1.md
│   └── product_spec.md
├── core/                  ← Swift package: COREEngine
│   ├── Package.swift      (swift-tools-version: 6.2)
│   ├── Sources/COREEngine/
│   │   ├── COREEngine.swift           (placeholder)
│   │   ├── Engines/
│   │   │   ├── CohesionEngine.swift   ✅ Complete (29 tests)
│   │   │   └── OptimizeEngine.swift   ✅ Complete (19 tests)
│   │   └── Models/
│   │       └── WardrobeItem.swift     ✅ Complete (all types)
│   └── Tests/COREEngineTests/
│       ├── COREEngineTests.swift      (scaffold — can be removed)
│       ├── CohesionEngineTests.swift  ✅ 29 tests passing
│       └── OptimizeEngineTests.swift  ✅ 19 tests passing
└── ios_app/               (empty, future SwiftUI app — requires Mac)
```

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
| createdAt | Date (`let`) |

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
Tests: 29 passing in `CohesionEngineTests.swift`

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

### Recalculation Triggers
- Item added or removed
- Archetype changed
- Season recalibration applied
- NOT during UI rendering

---

## 6. Seasonal Engine — NOT YET IMPLEMENTED

File to create: `core/Sources/COREEngine/Engines/SeasonalEngine.swift`
Pattern: `public enum SeasonalEngine: Sendable`

### Purpose

Adjusts cohesion formula weights based on seasonal context. Detects season from location. Suggests recalibration (never forced).

### New Types Needed

```swift
public struct CohesionWeights: Codable, Sendable {
    public let alignment: Double   // Base: 0.35
    public let density: Double     // Base: 0.30
    public let palette: Double     // Base: 0.20
    public let rotation: Double    // Base: 0.15
}

public struct SeasonalRecommendation: Identifiable, Codable, Sendable {
    public let id: UUID
    public let detectedSeason: SeasonMode
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
The SeasonalEngine does NOT modify CohesionEngine. Instead, it provides adjusted weights that a future `computeWithWeights` function can use:
```swift
// Future addition to CohesionEngine:
public static func compute(items: [WardrobeItem], profile: UserProfile, weights: CohesionWeights) -> CohesionSnapshot
```
The existing `compute` function continues to use base weights (0.35/0.30/0.20/0.15).

---

## 7. Structural Evolution — NOT YET IMPLEMENTED

File to create: `core/Sources/COREEngine/Engines/EvolutionEngine.swift`
Pattern: `public enum EvolutionEngine: Sendable`

### Purpose

Tracks wardrobe structural journey over time using narrative phases. Not a score graph — a progression story.

### New Types Needed

```swift
public enum EvolutionPhase: String, Codable, CaseIterable, Sendable {
    case foundation
    case developing
    case refining
    case cohering
    case evolving
}

public enum EvolutionTrend: String, Codable, CaseIterable, Sendable {
    case improving
    case stable
    case declining
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
```

### Edge Cases
- 0 snapshots → Foundation phase, volatility 0, trend .stable
- 1–2 snapshots → Foundation or Developing only, trend based on available data
- All snapshots identical score → volatility 0, trend .stable

---

## 8. Information Architecture

### Tab Bar (3 tabs)

| Tab | Icon | Label | Primary Content |
|-----|------|-------|-----------------|
| 1 | grid.2x2 | Wardrobe | Item grid + cohesion status |
| 2 | arrow.up.right | Optimize | Recommendations + simulation |
| 3 | person.crop.circle | Profile | Archetype, evolution, settings |

### Screen Map

**Wardrobe Tab (Home)**
```
Wardrobe Grid Screen
├── Cohesion Status Bar (tap → Cohesion Breakdown Sheet)
├── Category Filter Bar (All / Tops / Bottoms / Shoes / Outerwear)
├── Item Grid (2-column, image + category tag)
│   └── Tap Item → Item Detail Screen (push)
│       ├── Item image (large)
│       ├── All fields displayed
│       ├── Edit button → Edit Item Sheet
│       └── Delete button (confirmation alert)
└── Add Item FAB → Add Item Sheet (modal)
    ├── Image picker
    ├── Category selector
    ├── Silhouette selector
    ├── Color picker → auto-maps baseGroup + temperature
    ├── Archetype tag selector
    └── Save button
```

**Optimize Tab**
```
Optimize Screen
├── Current Score Summary (status label + numeric)
├── Weakest Area Indicator
├── Primary Recommendation Card
│   ├── Candidate item description (category, silhouette, baseGroup, archetype)
│   ├── Component impact (e.g., "Density: 52 → 64, +12")
│   ├── Total impact (e.g., "Total: 74 → 78, +4")
│   └── "Add to strengthen" label
├── Secondary Recommendations (up to 2, collapsed)
│   └── Tap to expand → same detail as primary
├── Structural Friction Section (only if items flagged)
│   ├── Friction item card
│   ├── Impact display
│   └── "Reconsider" label
└── Tap any recommendation → Candidate Detail Screen (push)
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
├── Structural Evolution Section
│   ├── Current phase label
│   ├── Trend indicator
│   ├── Brief narrative
│   └── Tap → Evolution Detail Screen (push)
│       ├── Full phase history
│       ├── Volatility indicator
│       └── Phase progression visualization
└── Settings Section
    ├── About CORET
    └── Pro upgrade (if free tier)
```

### Data Ownership

| Screen | Owns | Reads |
|--------|------|-------|
| Wardrobe | [WardrobeItem] | CohesionSnapshot |
| Optimize | — | [WardrobeItem], UserProfile, OptimizeResult |
| Profile | UserProfile | [CohesionSnapshot], EvolutionSnapshot |

### Navigation Patterns
- **Tab switch**: instant, no animation
- **Push**: item detail, candidate detail, evolution detail
- **Sheet (modal)**: add item, edit item, cohesion breakdown, archetype edit, season recalibration
- **Alert**: delete confirmation

---

## 9. UI Specification

### Color Tokens

| Token | Hex | Usage |
|-------|-----|-------|
| background | #3D3632 | App background, warm dark taupe |
| cardBackground | #E8E0D8 | Card surfaces, light stone |
| accent | #4A6741 | Buttons, highlights, deep muted forest green |
| accentPressed | #3D5636 | Button press state |
| textPrimary | #F5F0EB | Primary text on dark backgrounds |
| textSecondary | #A09890 | Secondary text, captions |
| textOnCard | #2C2826 | Text on card surfaces |
| textOnAccent | #F5F0EB | Text on accent-colored elements |
| destructive | #8B4F4F | Delete actions, muted red |
| divider | #4A4440 | Subtle dividers on dark backgrounds |
| cardDivider | #D0C8C0 | Dividers on card surfaces |

### Typography

All fonts: SF Pro (system font on iOS).

| Style | Font | Size | Weight | Spacing | Usage |
|-------|------|------|--------|---------|-------|
| logo | SF Pro Display | 20pt | Semibold (600) | 2.5pt | CORET header |
| scoreDisplay | SF Pro Display | 48pt | Bold (700) | 0 | Numeric score |
| statusLabel | SF Pro Display | 22pt | Semibold (600) | 0.5pt | "Coherent", "Aligned" |
| h1 | SF Pro Display | 28pt | Semibold (600) | 0 | Screen titles |
| h2 | SF Pro Display | 22pt | Semibold (600) | 0 | Section headers |
| h3 | SF Pro Text | 17pt | Semibold (600) | 0 | Card titles |
| body | SF Pro Text | 15pt | Regular (400) | 0 | Body text |
| caption | SF Pro Text | 13pt | Regular (400) | 0 | Secondary info |
| tag | SF Pro Text | 12pt | Medium (500) | 0.3pt | Category tags, labels |

### Spacing Scale (4pt base)

| Token | Value |
|-------|-------|
| xs | 4pt |
| sm | 8pt |
| md | 16pt |
| lg | 24pt |
| xl | 32pt |
| xxl | 48pt |

### Corner Radius

| Element | Radius |
|---------|--------|
| Card | 16pt |
| Button | 12pt |
| Tag/chip | 8pt |
| Item image | 12pt |
| Score ring | full circle |

### Animations

| Element | Duration | Curve | Properties |
|---------|----------|-------|------------|
| Card appear | 200ms | ease-in-out | opacity 0→1, scale 0.95→1.0 |
| Score update | 300ms | ease-in-out | numeric counter animation |
| Score ring | 500ms | ease-out | stroke animation on first appear |
| Sheet present | system | system | iOS default sheet |
| Tab switch | none | — | Instant |
| Button press | 100ms | ease-out | scale 1.0→0.97 |
| Status change | 300ms | ease-in-out | crossfade text |

### Layout Patterns

**Wardrobe Grid**: 2 columns, md (16pt) gap, md padding.
**Card**: xl (32pt) padding top/bottom, lg (24pt) padding sides.
**Status bar**: fixed top, xxl (48pt) height, centered content.
**FAB (add button)**: 56pt diameter, accent color, bottom-right, lg (24pt) inset.
**Score display**: status label above, numeric below, centered.
**Recommendation card**: full-width, card background, impact numbers right-aligned.

---

## 10. Brand Foundation

### Positioning
Personal wardrobe operating system measuring, optimizing, and evolving wardrobe structure.

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

### Product Identity
- Long-term system, not short-term style phase
- Seasonal recalibration supported
- Structural evolution tracked
- Rule-based engine in V1

---

## 11. Monetization (Freemium)

### Free Tier
- Full wardrobe management
- Basic cohesion score (status label + numeric)
- 1 active optimize target (primary recommendation only)
- Limited score breakdown (total only, no component detail)

### Pro Tier (target $9–12/month)
- Full component breakdown on tap
- Full simulation (all recommendations: primary + secondary)
- Multiple roadmap targets
- Structural friction detection
- Advanced analytics (component trends)
- Drift tracking
- Structural evolution detail (full narrative, phase history)
- Seasonal recalibration

### Explicitly NOT in V1
- Machine learning
- Auto color detection
- Retail integrations
- Social features
- Budget tools
- Cross-platform support

---

## 12. Scaling Strategy

### Phase 1 — Deterministic Core (Current)
- Rule-based Cohesion engine ✅
- Dynamic Optimize engine ✅
- Seasonal recalibration (next)
- Structural evolution (next)
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

**48/48 tests passing.**

### What Is Done

| Component | File | Tests | Status |
|-----------|------|-------|--------|
| Data models (all types) | `Models/WardrobeItem.swift` | — | ✅ Complete |
| CohesionEngine | `Engines/CohesionEngine.swift` | 29 | ✅ Complete |
| OptimizeEngine + result types | `Engines/OptimizeEngine.swift` | 19 | ✅ Complete |
| Package.swift | `core/Package.swift` | — | ✅ Complete |

### What Is Not Done

| Component | File | Status |
|-----------|------|--------|
| SeasonalEngine | `Engines/SeasonalEngine.swift` | Not started |
| EvolutionEngine | `Engines/EvolutionEngine.swift` | Not started |
| SwiftData persistence | TBD | Blocked (needs SwiftData — may need Mac) |
| SwiftUI iOS app | `ios_app/` | Blocked (requires Mac) |

---

## 14. Current Blocker and Build Order

### Current Blocker
SwiftUI requires Mac to build and test. Development machine is Arch Linux — cannot run SwiftUI or Xcode.

### What to Build Before SwiftUI (on Linux)

1. **SeasonalEngine** — `Engines/SeasonalEngine.swift`
   - Season detection from latitude + month
   - Weight modifiers (multiplicative, renormalized)
   - Recalibration recommendation
   - Add `compute(items:profile:weights:)` overload to CohesionEngine
   - Full test suite

2. **EvolutionEngine** — `Engines/EvolutionEngine.swift`
   - Phase determination from snapshot history
   - Volatility calculation (stddev of last 5)
   - Trend detection (last 3)
   - Regression logic
   - Narrative generation
   - Full test suite

3. **New model types** — add to `Models/` or engine files:
   - CohesionWeights, SeasonalRecommendation
   - EvolutionPhase, EvolutionTrend, EvolutionSnapshot

### When Mac Is Available
- Import COREEngine as local Swift Package
- Build SwiftUI app on top of finished engines + specs
- Implement SwiftData persistence wrapping engine types

---

## 15. Technical Conventions

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

## 16. Autonomous Session Protocol

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
