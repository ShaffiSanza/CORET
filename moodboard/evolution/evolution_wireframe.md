# CORET — Evolution Tab Wireframe (V1)

## Design Intent

Evolution is a structural design journal. Not a performance dashboard.

Must feel like:
- A premium design journal
- Calm but not empty
- Data-driven, but clothing-centered
- Structured, not gamified
- Visually satisfying without stimulation

Must NOT feel like:
- A performance dashboard or KPI panel
- A gamified progress tracker
- A data analytics screen
- A score improvement tool

Emotional target: "I see who I am becoming structurally."
NOT: "I need to improve my score."

Design ratio: 70% structural, 30% reflective. Never inverted.

Tone: Architectural. Intentional. Grounded.

---

## Core Decision

Abstract "Structural History" bars are removed entirely.

Replaced by a horizontal **Flat-Lay Structural Timeline** using garment
silhouettes. Numbers are secondary. Visual structure is primary.

---

## Evolution Tab Layout (V1)

Main sections, top to bottom:

1. Archetype Hero (identity + phase + momentum)
2. Structural Timeline (horizontal silhouette scroll)
3. Phase Journey (vertical phase list)

```
    ┌─────────────────────────────────────┐
    │ Evolution                           │
    │                                     │
    │ ┌─────────────────────────────────┐ │
    │ │  STRUCTURAL IDENTITY            │ │
    │ │                                 │ │
    │ │  Structured                     │ │
    │ │  Neutral · Warm                 │ │
    │ │                                 │ │
    │ │  "Refining structural cohesion  │ │
    │ │   across all components."       │ │
    │ │                                 │ │
    │ │  Phase: Refining                │ │
    │ │  Momentum: Upward Stability     │ │
    │ └─────────────────────────────────┘ │
    │                                     │
    │  Structural Timeline          → scroll
    │                                     │
    │  ┌──────────┐ ┌──────────┐ ┌──────────┐
    │  │ ┌──────┐ │ │ ┌──────┐ │ │ ┌──────┐ │
    │  │ │jacket│ │ │ │ coat │ │ │ │ wool │ │
    │  │ └──────┘ │ │ └──────┘ │ │ │ coat │ │
    │  │ ┌──────┐ │ │ ┌──────┐ │ │ └──────┘ │
    │  │ │jeans │ │ │ │trouse│ │ │ ┌──────┐ │
    │  │ └──────┘ │ │ └──────┘ │ │ │trouse│ │
    │  │ ┌──────┐ │ │ ┌──────┐ │ │ └──────┘ │
    │  │ │shoes │ │ │ │boots │ │ │ ┌──────┐ │
    │  │ └──────┘ │ │ └──────┘ │ │ │derby │ │
    │  └──────────┘ └──────────┘ │ └──────┘ │
    │   Oct          Dec         └──────────┘
    │   Foundation   Developing   Feb
    │                             Refining ●
    │                                     │
    │ ┌─────────────────────────────────┐ │
    │ │  Phase Journey                  │ │
    │ │                                 │ │
    │ │      Evolving                   │ │
    │ │      Cohering                   │ │
    │ │  ›   Refining                   │ │
    │ │      Developing                 │ │
    │ │      Foundation                 │ │
    │ │                                 │ │
    │ └─────────────────────────────────┘ │
    │                                     │
    └─────────────────────────────────────┘
```

---

## Section 1 — Archetype Hero

The primary identity card. Most prominent element on screen.
Visual reference: HTML hero section with large type and ghosted secondary.

### Elements

- Eyebrow label: "STRUCTURAL IDENTITY" (10pt, uppercase, tracking 0.15em, accent muted)
- Dominant silhouette name: large type (42–48pt, bold 800, textOnDark)
- BaseGroup + Temperature: secondary line (16pt, weight 300, textOnDark at 30% opacity)
- Narrative: body text, textSecondary, max 2 lines
- Phase label: caption, textMuted
- Momentum descriptor: caption, textMuted

### Structural Identity Derivation

Identity is deterministically derived from wardrobe item distributions
at snapshot time. Frozen into snapshot. Never recalculated retroactively.

```
Display format:
  Line 1 (large):   [Dominant Silhouette]
  Line 2 (ghosted): [Dominant BaseGroup] · [Dominant Temperature]
```

**Dominant Silhouette** — plurality across all items:

| Plurality winner | Display |
|-----------------|---------|
| .structured | "Structured" |
| .balanced | "Balanced" |
| .relaxed | "Relaxed" |
| Tie | "Balanced" (default) |

Tie-break rule: if two silhouettes have equal count, prefer in order:
balanced > structured > relaxed (structural stability bias).

**Dominant BaseGroup** — plurality across all items:

| Plurality winner | Display |
|-----------------|---------|
| .neutral | "Neutral" |
| .deep | "Deep-Toned" |
| .light | "Light-Toned" |
| .accent | "Accent-Driven" |
| Tie | "Neutral" (default) |

Tie-break: neutral > deep > light > accent.

**Dominant Temperature** — plurality among warm/cool only (neutral temp excluded):

| Plurality winner | Display |
|-----------------|---------|
| .warm | "Warm" |
| .cool | "Cool" |
| All neutral or tie | "Neutral" |

Tie-break: neutral (no dominant direction).

### Examples

- Line 1: "Structured" / Line 2: "Neutral · Warm"
- Line 1: "Relaxed" / Line 2: "Deep-Toned · Cool"
- Line 1: "Balanced" / Line 2: "Neutral · Neutral"

### Rules

- Deterministic: same wardrobe → same identity
- Derived from item distributions, not archetype intent
- Archetype = what the user intends. Identity = what the wardrobe IS.
- Not AI-generated text. Composed from enum values.
- Stable over time (only shifts when plurality shifts)

### Engine Requirement

New pure function (not yet implemented):

```swift
public struct StructuralIdentity: Codable, Sendable {
    public let dominantSilhouette: Silhouette
    public let dominantBaseGroup: BaseGroup
    public let dominantTemperature: Temperature
    public var displayLine1: String   // "Structured"
    public var displayLine2: String   // "Neutral · Warm"
}

public static func structuralIdentity(items: [WardrobeItem]) -> StructuralIdentity
```

---

## Section 2 — Momentum Descriptor

Replaces raw trend + volatility with architectural language.

### Derivation Matrix

| Trend \ Volatility | Low (< 6) | Medium (6–10) | High (> 10) |
|--------------------|-----------|---------------|-------------|
| Improving | Upward Stability | Active Strengthening | Rapid Restructuring |
| Stable | Structural Consolidation | Holding Pattern | Unstable Plateau |
| Declining | Gentle Recalibration | Gradual Loosening | Temporary Instability |

### Rules

- Displayed as: "Momentum: [descriptor]"
- Caption style, textMuted
- No arrows, no icons, no emoji
- Deterministic: same trend + volatility → same descriptor

### Engine Requirement

New pure helper (not yet implemented):

```swift
public static func momentum(trend: EvolutionTrend, volatility: Double) -> String
```

---

## Section 3 — Structural Timeline (Flat-Lay Silhouettes)

The core visual feature. Replaces abstract score bars with garment silhouettes.

Visual reference: HTML timeline-scroll section. Dark snapshot cards with
SVG garment silhouettes showing visual progression from scattered/colorful
to structured/cohesive.

### Layout

- Horizontal scroll with snap paging
- Show last 4–6 snapshots
- Oldest → left, newest → right
- Current snapshot: subtle accent border (1.5px, accent at 50% opacity) + dot indicator
- Section header: "STRUCTURAL TIMELINE" eyebrow + "Scroll →" hint

### Snapshot Card Dimensions

- Card width: 120pt
- Card height: 160pt
- Corner radius: 16pt
- Background: dark tonal (#3a3530 to #322e2b — progressively darker/cleaner as structure improves)
- Gap between cards: 10pt
- Horizontal padding: 24pt (matches screen margin)

### Snapshot Card Content

Each card contains:
- Silhouette composition of 3–4 anchor items (inside card)
- Date label below card (10pt, semibold, textMuted)
- Phase label below date (9pt, uppercase, tracking 0.1em, phase-colored)
- Current dot indicator (5pt circle, accent, only on current snapshot)

### Phase Colors (Timeline Labels)

| Phase | Color |
|-------|-------|
| Foundation | textOnDark at 20% opacity |
| Developing | textOnDark at 35% opacity |
| Refining | accent (#2F4A3C) |
| Cohering | accent light (#3a6a5a) |
| Evolving | accent (#2F4A3C) full |

### Silhouette Rendering

Garments are rendered as **abstract silhouette shapes**, not photographs.

This is a deliberate design choice: silhouettes are more structural,
more archival, and more visually consistent than real photos at small
scale. They show shape and proportion — which IS structure.

#### Rendering method

Each item category maps to a silhouette template:

| Category | Shape | Approximate proportion |
|----------|-------|----------------------|
| Top | Rectangle with shoulder extensions | 55% card width, 35% card height |
| Bottom | Tapered/wide rectangle below top | 50% card width, 38% card height |
| Shoes | Two small ellipses/rounded rects | 20% card width each, 10% card height |
| Outerwear | Larger rectangle over top position | 60% card width, 42% card height |

#### Silhouette variation by structural properties

The silhouette shape MUST reflect the item's actual Silhouette enum value:

| Silhouette | Shape modifier |
|-----------|---------------|
| .structured | Sharp corners (rx=2–3), straight edges, minimal taper |
| .balanced | Medium corners (rx=4–5), slight taper |
| .relaxed | Rounded corners (rx=6–8), wider proportions, more taper |

#### Color mapping

Silhouette fill color is derived from item's BaseGroup + Temperature:

| BaseGroup | Base fill |
|-----------|-----------|
| .neutral | #5a5550 (warm gray) |
| .deep | #3a3835 (dark charcoal) |
| .light | #8a8580 (light warm gray) |
| .accent | #7a5a4a (muted warm accent) |

Temperature shifts the hue slightly:
- .warm → shift +5% toward brown/amber
- .cool → shift +5% toward blue-gray
- .neutral → no shift

Opacity: 0.8–0.95 (deeper colors slightly more opaque).

### Silhouette Layout (Deterministic — NOT Editorial)

**IMPORTANT**: The HTML reference uses editorial rotation transforms
(rotate(-8°), rotate(5°), etc.) for visual flair. This is correct for
the mockup but WRONG for production.

**Production behavior**: All silhouettes are axis-aligned (0° rotation).
Positions are deterministic based on item count and category.

Items are arranged in a **vertical stack** (natural wearing position):
outerwear/top at top, bottom in middle, shoes at bottom.

#### Stack layout rules (120×160pt canvas)

**3 items (top + bottom + shoes)** — standard outfit:

```
Item positions (x, y, width, height):
  Top:    x=22, y=10,  w=76, h=56
  Bottom: x=26, y=70,  w=68, h=62
  Shoes:  2 shapes at y=138, each w=24, h=14
    Left shoe:  x=24, y=138
    Right shoe: x=72, y=138
```

**4 items (outerwear + top + bottom + shoes)**:

```
Outerwear dominates top area (layered over/replacing top):
  Outerwear: x=18, y=6,   w=84, h=72
  Top:       hidden (outerwear covers it visually)
  Bottom:    x=28, y=82,  w=64, h=54
  Shoes:     Left: x=26, y=140  Right: x=70, y=140  each w=24, h=14
```

When outerwear is present, it takes the top position. The actual top
garment is visually occluded (it's underneath — structurally present
but not visible in the flat-lay, which is realistic).

**2 items** — incomplete outfit:

```
  Item 1: x=22, y=16,  w=76, h=62
  Item 2: x=26, y=86,  w=68, h=58
```

Arranged by category order: outerwear > top > bottom > shoes (top to bottom).

**1 item** — minimal:

```
  Item: x=26, y=36, w=68, h=88 (centered, larger)
```

#### No editorial rotation

- All shapes at 0° rotation
- No random offsets
- No overlapping garments (except outerwear over top, which is structural)
- No decorative elements
- Deterministic: same items → identical layout

### Snapshot Background Progression

Snapshot card backgrounds subtly shift to reflect structural maturity:

| Phase | Background | Rationale |
|-------|-----------|-----------|
| Foundation | #3a3530 | Warmest, least refined |
| Developing | #363230 | Slightly cooler |
| Refining | #343030 | Tightening |
| Cohering | #322e2b | Clean, structured |
| Evolving | #302c28 | Most refined, deepest |

This creates a subtle visual progression: earlier snapshots feel warmer
and rougher, later ones feel cooler and more precise. The user perceives
evolution without reading numbers.

---

## Section 4 — Phase Journey

Vertical list showing all five phases. Current phase highlighted.

### Layout

- All 5 phases listed vertically, highest first (Evolving at top)
- Stone card background (#E7E2DA), embedded feel
- Current phase: semibold text + "›" indicator left-aligned
- Past phases (below current): textPrimary, regular weight
- Future phases (above current): textMuted, lighter weight
- Vertical rhythm: lg (24pt) spacing between items

### Rules

- No checkmarks or completion indicators
- No trophies or level numbers
- No animations on phase change
- No connecting lines between phases
- Current phase highlight is subtle, not loud

---

## Snapshot Data Model (Required Persistence Changes)

`EvolutionSnapshotEntity` (SwiftData) must persist additional fields:

| Field | Type | Purpose |
|-------|------|---------|
| snapshotAnchorItemIDs | [UUID] | Frozen anchor item references |
| snapshotIdentityString | String | Frozen identity display (e.g., "Structured · Neutral · Warm") |
| snapshotMomentumDescriptor | String | Frozen momentum label |
| snapshotPhase | EvolutionPhase (raw) | Phase at snapshot time |
| snapshotScore | Double | Total cohesion score |
| createdAt | Date | Immutable timestamp |

### Rules

- Values are frozen at snapshot creation time
- Snapshots are never recalculated retroactively
- Snapshots are historical documents
- If wardrobe changes later, old snapshots remain intact
- Anchor item IDs reference items that may later be deleted

---

## Anchor Selection Algorithm (Deterministic)

At each snapshot, anchors are selected and their IDs frozen permanently.

### Formula

```
anchorScore = (alignmentMatch × 0.4)
            + (categoryCentrality × 0.35)
            + (usageStability × 0.25)
```

### alignmentMatch (0.0 or 0.7 or 1.0)

How well the item's archetype matches the user's profile:

```
if item.archetypeTag == profile.primaryArchetype → 1.0
if item.archetypeTag == profile.secondaryArchetype → 0.7
else → 0.0
```

### categoryCentrality (0.0–1.0)

Measures how structurally irreplaceable the item is within its category.
Items in smaller categories are harder to replace → more central.

```swift
let categoryCount = items.filter { $0.category == item.category }.count
let isRequired = item.category != .outerwear  // top, bottom, shoes are required
let categoryWeight: Double = isRequired ? 1.0 : 0.7

categoryCentrality = categoryWeight × (1.0 / Double(max(categoryCount, 1)))
```

Clamped to [0.0, 1.0].

Examples:
- 1 top out of 1 top total: 1.0 × 1.0 = **1.0** (irreplaceable)
- 1 top out of 4 tops: 1.0 × 0.25 = **0.25** (many alternatives)
- 1 outerwear out of 1: 0.7 × 1.0 = **0.7** (irreplaceable but optional category)
- 1 outerwear out of 3: 0.7 × 0.33 = **0.23**

### usageStability (0.0–1.0)

Measures how consistently the item is used relative to its category peers.
Items close to their category's average usage are more stable.

```swift
let categoryItems = items.filter { $0.category == item.category }
let categoryMean = categoryItems.map(\.usageCount).mean()  // arithmetic mean
let deviation = abs(Double(item.usageCount) - categoryMean)
let normalizedDeviation = deviation / max(categoryMean, 1.0)

usageStability = 1.0 - min(normalizedDeviation, 1.0)
```

Examples (category mean = 10):
- Item used 10 times: deviation=0, stability = **1.0** (perfectly average)
- Item used 15 times: deviation=5, normalized=0.5, stability = **0.5**
- Item used 0 times: deviation=10, normalized=1.0, stability = **0.0** (never worn)
- Item used 20 times: deviation=10, normalized=1.0, stability = **0.0** (overused)

Edge case: if categoryMean = 0 (all items unused), deviation = 0, stability = 1.0.

### Selection Rules

1. Compute anchorScore for every item
2. Sort descending by anchorScore
3. Select top 3–4 items
4. Constraint: at least 2 distinct categories must be represented
   - If top 3 are all same category, swap the 3rd for the next-highest
     item from a different category
5. Tie-break: prefer older items (earlier createdAt) — stability bias
6. If < 3 items total → select all items, no minimum category constraint

### Engine Requirement

New pure function (not yet implemented):

```swift
public static func anchorItems(
    items: [WardrobeItem],
    profile: UserProfile
) -> [WardrobeItem]
```

---

## Deleted Items Handling (Historical Integrity)

If an item referenced by a snapshot's anchorItemIDs is later deleted:

- Retain the UUID reference in the snapshot
- Render a **placeholder silhouette** in the composition:
  - Same position as the original item would occupy
  - Filled with background color at 30% opacity (ghosted)
  - Dashed outline (1pt, textMuted at 40%)
- Preserve layout structure (don't collapse or reflow)
- Snapshot remains a historical document

Never silently remove anchors from old snapshots.

---

## Accessories Policy

Accessories are allowed in the data model but subordinate in flat-lay rendering.

- Max 1 accessory per snapshot composition
- Rendered at 80–85% scale relative to garments
- Positioned in secondary location (bottom-right corner or behind main stack)
- Must not dominate visual weight
- Not counted as a required anchor item
- V1: accessories are not part of anchor selection (no accessory category exists)

---

## Interaction Model

- Horizontal scroll with snap paging (one card width per snap)
- No autoplay or auto-scroll
- No transition animations between snapshots
- Current snapshot starts in view (rightmost, scroll position right-aligned)
- Tap on snapshot → Snapshot Detail (V1.1, optional)

### Snapshot Detail (V1.1)

Push screen showing:
- Phase at that time
- Identity at that time
- Momentum at that time
- Cohesion score breakdown (alignment, density, palette, rotation)
- Larger flat-lay silhouette composition
- Date

Read-only. Historical view.

---

## Edge States

### No snapshots (new user)

```
    ┌─────────────────────────────────┐
    │  STRUCTURAL IDENTITY            │
    │                                 │
    │  Foundation                     │
    │                                 │
    │  "Building your wardrobe's      │
    │   structural foundation."       │
    │                                 │
    │  Add items to begin your        │
    │  structural journey.            │
    └─────────────────────────────────┘
```

Timeline section hidden. Phase Journey shows Foundation highlighted.

### 1 snapshot

Centered single snapshot card. Text below: "Structural history forming."
Phase Journey visible.

### Regression

Phase Block shows regression narrative:
"Your wardrobe is recalibrating. This is part of the process."
Momentum descriptor reflects the matrix (e.g., "Temporary Instability").
No red color. No negative framing. Regression is normal.

### Empty wardrobe (all items deleted)

Identity line: "—" (dash). Momentum: "Structural Consolidation" (stable + low vol).

---

## HTML Deviations from Production Spec

The HTML mockup (`evolution_timeline.html`) is a visual reference.
The following elements are correct in the mockup but differ from
production behavior:

| HTML behavior | Production behavior | Reason |
|---------------|-------------------|--------|
| SVG garments have rotation transforms (rotate -8°, +5°, etc.) | All silhouettes axis-aligned (0° rotation) | Deterministic layout, no editorial styling |
| "Current Outfits" section showing outfit combinations | Removed — belongs on Dashboard tab | Evolution shows structural journey, not current outfits |
| "Next Step" optimize preview section | Removed — belongs on Optimize tab | Avoid cross-tab feature duplication |
| Garment silhouettes are hand-drawn SVG paths | Silhouettes generated from category + silhouette enum templates | Must be deterministic, not hand-crafted per snapshot |
| Archetype hero shows "Structured" / "Relaxed" as primary/secondary | Shows dominant silhouette (line 1) and baseGroup · temperature (line 2) | Identity = what wardrobe IS, not archetype intent |
| Background uses radial gradient on hero | No gradients | CORET design rule: no gradients |
| Phase Journey section absent | Phase Journey section present | Required by spec |

### What HTML gets RIGHT (preserve in production)

- Dark snapshot card backgrounds with garment silhouettes — correct feel
- Horizontal scroll timeline — correct interaction
- Phase-colored labels below each snapshot — correct information hierarchy
- Current snapshot border highlight + dot — correct emphasis
- Subtle, muted color palette throughout — correct tone
- Tab bar design — correct structure
- Overall "design journal" atmosphere — this IS the target emotional feel
- Silhouette progression telling a visual story — core insight, keep this

---

## Visual System (Bindings to UI Spec)

- Background: Warm Dark Taupe (#2F2A26)
- Cards: Stone (#E7E2DA) for Phase Journey; dark tonal for timeline cards
- Accent: Muted Forest (#2F4A3C)
- Corner radius: 16pt (timeline cards), 18–22pt (section cards)
- Shadow: < 8% opacity
- Typography: SF Pro system font

No gradients. No glow. No sparkle. No gamification.

---

## Engine Work Required (Not Yet Implemented)

All functions are pure, deterministic, with no UI dependencies.
Can be implemented on Linux before Mac is available.

| Function | Location | Purpose |
|----------|----------|---------|
| `structuralIdentity(items:)` | EvolutionEngine or new utility | Derive identity from item distributions |
| `momentum(trend:volatility:)` | EvolutionEngine | Map trend+volatility to architectural language |
| `anchorItems(items:profile:)` | EvolutionEngine or new utility | Select structurally representative items |

### StructuralIdentity type

```swift
public struct StructuralIdentity: Codable, Sendable, Equatable {
    public let dominantSilhouette: Silhouette
    public let dominantBaseGroup: BaseGroup
    public let dominantTemperature: Temperature

    public var displayLine1: String {
        switch dominantSilhouette {
        case .structured: "Structured"
        case .balanced: "Balanced"
        case .relaxed: "Relaxed"
        }
    }

    public var displayLine2: String {
        let bg: String = switch dominantBaseGroup {
        case .neutral: "Neutral"
        case .deep: "Deep-Toned"
        case .light: "Light-Toned"
        case .accent: "Accent-Driven"
        }
        let temp: String = switch dominantTemperature {
        case .warm: "Warm"
        case .cool: "Cool"
        case .neutral: "Neutral"
        }
        return "\(bg) · \(temp)"
    }
}
```

---

## Final Principle

Evolution Timeline should feel like opening a structural design archive.

Not: checking analytics.
Not: chasing a score.
Not: leveling up.

If this screen ever feels like a KPI dashboard, it has drifted from
CORET identity.
