# CORET V1 — Engine → UI Mapping Specification

Status: **Authoritative**
Date: 1 March 2026
Authors: Claude AI (values) + GPT (framework) + Claude Code (integration)
Council overrides applied: unified descriptors, outfit-first wardrobe, locked values

---

## Core Rule

Engine computes. ViewModel maps. UI renders.

UI must NEVER calculate, modify, or reinterpret engine data. UI may ONLY map, format, visualize, and animate. All structural decisions trace back to an engine function. No exceptions. No shortcuts.

| Layer | Responsibility | Example |
|-------|---------------|---------|
| Engine | Compute structural truth | `totalScore = 72.0` |
| ViewModel | Map to presentation state | `status = .coherent`, `opacity = 0.85` |
| SwiftUI | Render from state | Score label with 0.85 opacity, accent status pill |

---

## Section 1 — Score Presentation (Hero + Components)

### Hero Score

Source: `CohesionEngine.compute(items:profile:).totalScore`
Status: `CohesionEngine.statusLevel(from: totalScore)`

| Status | Score Range | Font Size | Color | Opacity | Animation |
|--------|------------|-----------|-------|---------|-----------|
| Structuring | 0–49 | 72pt | textOnDark (#EAE5DE) | 0.6 | Count-up 300ms |
| Refining | 50–64 | 72pt | textOnDark (#EAE5DE) | 0.75 | Count-up 300ms |
| Coherent | 65–79 | 72pt | textOnDark (#EAE5DE) | 0.85 | Count-up 300ms |
| Aligned | 80–89 | 72pt | accent (#2F4A3C) | 1.0 | Count-up 300ms |
| Architected | 90–100 | 72pt | accent (#2F4A3C) | 1.0 | Count-up 300ms + subtle pulse |

Score always 72pt. Visual weight communicates status through opacity and color, not size.

### Status Label

- Font: 22pt, semibold (600)
- Color: accent (#2F4A3C) for all statuses
- Status pill background: accent at 15% opacity for **Aligned and Architected only**. Other statuses have no pill background.

### Progress Bar

- Height: 4pt
- Fill: accent (#2F4A3C)
- Track: divider (#4A4440)
- Fill percentage: `totalScore / 100`
- Rounded caps
- No circular rings. Horizontal bar only.

### Component Grid (2×2)

Source: `snapshot.alignmentScore`, `.densityScore`, `.paletteScore`, `.rotationScore`

**Council Override 1 — Unified descriptors.** Components use the same CohesionStatus scale as the total score. No "Strong" or "Optimal" variants.

| Score Range | Descriptor |
|------------|------------|
| 0–49 | Structuring |
| 50–64 | Refining |
| 65–79 | Coherent |
| 80–89 | Aligned |
| 90–100 | Architected |

**Card styling:**

| Property | Value |
|----------|-------|
| Background | stone (#E7E2DA) |
| Corner radius | 20pt |
| Padding | 16pt |
| Grid gap | 12pt |
| Component name | 13pt, textMuted (#9A918A) |
| Score | 24pt, medium (500), textPrimary (#1F1C1A) |
| Descriptor | 13pt, textMuted (#9A918A) |

**Low score behavior:** No special treatment. No red highlights. No warning icons. Score and descriptor communicate state. The system does not panic.

Tap any card → Component Detail Screen (push).

---

## Section 2 — Enum Display Labels

All user-facing labels. Norwegian for UI chrome and descriptions. English for structural terminology (component names, status labels, phase names).

### 2a. Archetype

Source: `Archetype` enum

| Engine Value | Display Name | Description (Norwegian) |
|-------------|-------------|------------------------|
| `.structuredMinimal` | Tailored | "Clean lines, definerte former, presis passform. Intensjonell." |
| `.smartCasual` | Smart Casual | "Mellom formelt og avslappet. Kontrollert, men uanstrengt." |
| `.relaxedStreet` | Street | "Komfort først. Myke former, avslappet passform. Ledig." |

### 2b. Silhouette

Source: `Silhouette` enum

| Engine Value | Display (English) | Display (Norwegian) |
|-------------|-------------------|---------------------|
| `.structured` | Structured | Strukturert |
| `.balanced` | Balanced | Balansert |
| `.relaxed` | Relaxed | Avslappet |
| `nil` | Mixed | Blandet |

### 2c. BaseGroup

Source: `BaseGroup` enum. **Unified to evolution wireframe versions.** Council decision overrides onboarding wireframe.

| Engine Value | Display |
|-------------|---------|
| `.neutral` | Neutral |
| `.deep` | Deep-Toned |
| `.light` | Light-Toned |
| `.accent` | Accent-Driven |
| `nil` | Mixed |

### 2d. Temperature

Source: `Temperature` enum

| Engine Value | Display |
|-------------|---------|
| `.warm` | Warm |
| `.cool` | Cool |
| `.neutral` | Neutral |

Temperature never returns nil from `structuralIdentity()`. On tie, resolves to `.neutral`.

### 2e. ItemCategory

Source: `ItemCategory` enum

| Engine Value | Display (English) | Filter Tab (Norwegian) |
|-------------|-------------------|----------------------|
| `.top` | Tops | Overdeler |
| `.bottom` | Bottoms | Underdeler |
| `.shoes` | Shoes | Sko |
| `.outerwear` | Outerwear | Ytterplagg |

### 2f. CohesionStatus

Source: `CohesionStatus` enum. Used for both total score and individual components (Council Override 1).

| Engine Value | Display | Score Range |
|-------------|---------|------------|
| `.structuring` | Structuring | 0–49 |
| `.refining` | Refining | 50–64 |
| `.coherent` | Coherent | 65–79 |
| `.aligned` | Aligned | 80–89 |
| `.architected` | Architected | 90–100 |

### 2g. SeasonMode

Source: `SeasonMode` enum

| Engine Value | Display (Norwegian) |
|-------------|---------------------|
| `.springSummer` | Vår / Sommer |
| `.autumnWinter` | Høst / Vinter |

### 2h. EvolutionPhase

Source: `EvolutionPhase` enum

| Engine Value | Display |
|-------------|---------|
| `.foundation` | Foundation |
| `.developing` | Developing |
| `.refining` | Refining |
| `.cohering` | Cohering |
| `.evolving` | Evolving |

### 2i. EvolutionTrend

Source: `EvolutionTrend` enum

| Engine Value | Display (Norwegian) |
|-------------|---------------------|
| `.improving` | Økende |
| `.stable` | Stabil |
| `.declining` | Synkende |

### 2j. WeaknessArea

Source: `WeaknessArea` enum

| Engine Value | Display | Display (Norwegian) |
|-------------|---------|---------------------|
| `.alignment` | Alignment | Alignment |
| `.density` | Density | Density |
| `.palette` | Palette | Palette |
| `.rotation` | Rotation | Rotasjon |

---

## Section 3 — Color Swatch Lookup Tables

### 3a. Onboarding Swatches (8)

Shown on Screen 3 (Quick-Add). 34pt diameter circles, 8pt gap. Selected: textOnDark border + scale 1.15× + accent shadow.

| Swatch Name | Hex | rawColor | baseGroup | temperature |
|-------------|-----|----------|-----------|-------------|
| Black | #1A1A1A | "Black" | `.neutral` | `.neutral` |
| Charcoal | #4A4A4A | "Charcoal" | `.neutral` | `.cool` |
| Navy | #1B2A3B | "Navy" | `.deep` | `.cool` |
| Brown | #5C3D2E | "Brown" | `.deep` | `.warm` |
| Olive | #4A5A3A | "Olive" | `.deep` | `.warm` |
| White | #F0EBE3 | "White" | `.light` | `.neutral` |
| Cream | #C4B9AA | "Cream" | `.light` | `.warm` |
| Burgundy | #6B2D35 | "Burgundy" | `.accent` | `.warm` |

### 3b. Full Add Item Swatches (10)

Shown in Add Item Sheet and Edit Item Sheet. Extends onboarding set with 2 additional colors.

| Swatch Name | Hex | rawColor | baseGroup | temperature |
|-------------|-----|----------|-----------|-------------|
| Black | #1A1A1A | "Black" | `.neutral` | `.neutral` |
| Charcoal | #4A4A4A | "Charcoal" | `.neutral` | `.cool` |
| Navy | #1B2A3B | "Navy" | `.deep` | `.cool` |
| Brown | #5C3D2E | "Brown" | `.deep` | `.warm` |
| Olive | #4A5A3A | "Olive" | `.deep` | `.warm` |
| White | #F0EBE3 | "White" | `.light` | `.neutral` |
| Cream | #C4B9AA | "Cream" | `.light` | `.warm` |
| Burgundy | #6B2D35 | "Burgundy" | `.accent` | `.warm` |
| Light Gray | #B8B3AC | "Light Gray" | `.light` | `.cool` |
| Rust | #8B4A2B | "Rust" | `.accent` | `.warm` |

User selects a swatch → `baseGroup` and `temperature` mapped automatically. Mapping is invisible to the user.

### 3c. Evolution Timeline Silhouette Fills

SVG silhouettes on timeline cards use fills derived from the item's `baseGroup` + `temperature`.

| BaseGroup | Base Fill Hex | Warm Shift | Cool Shift |
|-----------|-------------|------------|------------|
| `.neutral` | #5A5550 | +5% toward brown/amber | +5% toward blue-gray |
| `.deep` | #3A3835 | +5% toward brown/amber | +5% toward blue-gray |
| `.light` | #8A8580 | +5% toward brown/amber | +5% toward blue-gray |
| `.accent` | #7A5A4A | +5% toward brown/amber | +5% toward blue-gray |

Temperature `.neutral` → use base fill hex with no shift. Opacity: 0.8–0.95.

---

## Section 4 — Structural Identity Composition

Source: `CohesionEngine.structuralIdentity(items:) -> StructuralIdentity`

### Identity String Format

```
[Silhouette Display] · [BaseGroup Display] · [Temperature Display]
```

Example: `"Structured · Deep-Toned · Cool"`

ViewModel composes this string. Engine returns raw `StructuralIdentity` struct.

```swift
let silLabel = identity.dominantSilhouette?.displayName ?? "Mixed"
let bgLabel = identity.dominantBaseGroup?.displayName ?? "Mixed"
let tempLabel = identity.dominantTemperature.displayName
identityString = "\(silLabel) · \(bgLabel) · \(tempLabel)"
```

### nil Fallback

**Council-locked:** nil → "Mixed" / "Blandet". NOT "Balanced" or "Neutral".

| Field | nil Meaning | Fallback |
|-------|-----------|----------|
| `dominantSilhouette` | Tied — no dominant | "Mixed" / "Blandet" |
| `dominantBaseGroup` | Tied — no dominant | "Mixed" |
| `dominantTemperature` | Never nil | N/A (resolves to `.neutral` on tie) |

### Two Display Contexts

**Onboarding AHA (Screen 4):**
- Archetype prefix from `UserProfile.primaryArchetype` (not from StructuralIdentity)
- Format: `[BaseGroup Display] · [Temperature Display]`
- Font: 26pt, DM Serif Display, textOnDark
- Accent-colored dots as separators
- Silhouette not shown separately on AHA — it is communicated visually

**Evolution Hero:**
- Line 1: dominantSilhouette display (42–48pt, bold 800, textOnDark)
- Line 2: `[BaseGroup Display] · [Temperature Display]` (16pt, weight 300, 30% opacity)
- If dominantSilhouette is nil → Line 1 shows "Mixed"

---

## Section 5 — Contribution Context Display Labels

Source: `CohesionEngine.itemContributions(items:profile:component:) -> [ItemContribution]`

Used on Component Detail screen. Each item shows its `contributionScore` and `context`.

### AlignmentMatchType → Display

| Value | Label (Norwegian) | Color |
|-------|-------------------|-------|
| `.primary` | Primær match | accent (#2F4A3C) |
| `.secondary` | Sekundær match | textPrimary (#1F1C1A) |
| `.neutral` | Nøytral | textMuted (#9A918A) |
| `.conflict` | Konflikt | destructive (#7A3E3E) |

### ParticipationLevel → Display

| Value | Label (Norwegian) |
|-------|-------------------|
| `.high` | Høy deltakelse |
| `.low` | Lav deltakelse |

### PaletteRole → Display

| Value | Label (Norwegian) |
|-------|-------------------|
| `.balanced` | Balansert |
| `.excessAccent` | For mye aksent |
| `.temperatureClash` | Temperaturkonflikt |

### UsageLevel → Display

| Value | Label (Norwegian) |
|-------|-------------------|
| `.even` | Jevn |
| `.overused` | Overbrukt |
| `.underused` | Underbrukt |

### Component Detail Screen Layout

- Top 5 contributors sorted by `contributionScore` descending
- Top 5 weaknesses sorted by `contributionScore` ascending
- Each row: item image thumbnail + item description + context label + contribution score bar
- Score bar: fill proportional to `contributionScore` (0–1), accent fill
- Context label colored per table above (alignment only uses color differentiation)

---

## Section 6 — Optimize Candidate Description

Source: `OptimizeEngine.optimize(items:profile:) -> OptimizeResult`

### Candidate Headline

Format (Norwegian): `[Silhouette display] [category display] i [baseGroup display] base`

Examples:
- "Strukturert ytterplagg i nøytral base"
- "Balansert overdel i deep-toned base"
- "Avslappet underdel i light-toned base"

The candidate describes a **structural role**, never a specific garment. No brand names. No garment types (jacket, shirt, etc.).

### Impact Display

Format: `[Weakness display] +[componentDelta] · Cohesion +[totalDelta]`

Example: `"Density +18 · Cohesion +9"`

- Accent color (#2F4A3C), 13pt, semibold
- Deltas rounded to nearest integer
- Only positive improvements shown (negative deltas filtered by engine — secondary candidates require positive improvement)

### Ghosted Silhouette (Candidate Placeholder)

- Dashed border (2pt)
- Accent color at 30% opacity
- Category-appropriate SVG silhouette shape
- No fill — outline only
- Represents the structural role to be filled

---

## Section 7 — Weakness Explanation Text

### 7a. Optimize Tab — Diagnostic Strings

Shown below the weakest area indicator. One string per `WeaknessArea`.

| WeaknessArea | Diagnostic (Norwegian) |
|-------------|----------------------|
| `.alignment` | "Arketype-spredningen er bred. Plagg trekker i ulike strukturelle retninger." |
| `.density` | "Antrekkstettheten er lav. Garderobens kategorier danner få komplette kombinasjoner." |
| `.palette` | "Palettkontrollen er svak. Fargene mangler balanse mellom nøytrale og aksenter." |
| `.rotation` | "Rotasjonsbalansen er ujevn. Noen plagg brukes vesentlig mer enn andre." |

### 7b. Component Detail Screen — Measurement Explanations

Shown at top of Component Detail screen. Explains what the component measures.

| Component | Explanation (Norwegian) |
|-----------|----------------------|
| Alignment | "Måler hvor godt plaggene matcher din primære og sekundære arketyperetning." |
| Density | "Måler hvor mange strukturelt gyldige antrekk garderoben din kan danne." |
| Palette | "Måler fargebalansen mellom nøytrale, dype og aksenttoner, samt temperatursamhold." |
| Rotation | "Måler jevnheten i bruksfrekvens innen hver kategori." |

---

## Section 8 — Onboarding Micro-Insight Rules

Source: Engine output from 3 onboarding items. Shown on Screen 4 (AHA).

**Ordered rules — first match wins.** All strings Norwegian.

| Priority | Condition | Insight String |
|----------|----------|---------------|
| 1 | Any baseGroup ≥ 66% of items | "Din base group dominerer [X]% av garderoben." |
| 2 | All 3 items share same silhouette | "Silhuetten din er fullt [silhouette display]. Konsistent." |
| 3 | Mixed temperature (both warm + cool present) | "Paletten din spenner over varmt og kaldt. Rom for å stramme." |
| 4 | All 3 items match primary archetype | "Full alignment med din [archetype display]-retning." |
| 5 | Default (no rule matched) | "3 plagg kartlagt. Struktur kommer med mer data." |

**Notes:**
- Rule 1: [X] is the percentage (e.g., "67"). With 3 items, 2 matching = 67%, 3 matching = 100%.
- Rule 2: [silhouette display] uses Norwegian label (Strukturert / Balansert / Avslappet).
- Rule 4: [archetype display] uses display name (Tailored / Smart Casual / Street).
- Semi-transparent card background. Deterministic text. Animates fadeInUp at 450ms delay.
- Precision note below: "Presisjonen øker når flere plagg legges til." (13pt, textMuted, italic, 600ms delay)

---

## Section 9 — Edge Case Visual Rules

**Core rule:** Absent data → absent section. No placeholders. No "coming soon." No "add more to unlock."

| State | Screen | Behavior |
|-------|--------|----------|
| Empty wardrobe (0 items) | Dashboard | "Systemet er ikke strukturert ennå. Legg til plagg i Wardrobe for å starte." (textSecondary, centered). No score, no components, no cards. |
| Empty wardrobe | Optimize | "Legg til plagg i garderoben for å låse opp strukturell optimalisering." + button to Wardrobe tab. |
| Empty wardrobe | Evolution | Identity shows "—". Phase: Foundation. Timeline hidden. |
| < 3 items | Dashboard | "Legg til plagg for å starte." (progressive depth applies — see Section 17) |
| Missing categories (no top/bottom/shoes) | Optimize | "Legg til overdeler, underdeler og sko for å aktivere density-optimalisering." |
| No valid outfits | Dashboard | Outfit preview card hidden |
| No valid outfits | Wardrobe | Outfit section hidden. Item grid shown instead. |
| No recommendations | Optimize | "Ingen strukturelle forslag. Garderoben er optimalisert." |
| 0 snapshots | Evolution | Foundation phase. Timeline hidden. "Strukturell historikk dannes." |
| 1 snapshot | Evolution | Single centered timeline card. "Strukturell historikk dannes." |
| Phase regression | Evolution | "Garderoben din rekalibrerer. Dette er en del av prosessen." |
| Single item wardrobe | All | Normal display. Scores reflect single-item state (many components at 0). |
| All items same archetype | Dashboard | High alignment score. Normal display. |
| All items same color | Dashboard | High palette score (monochrome bonus). Normal display. |

---

## Section 10 — Outfit Display (Dashboard + Wardrobe)

### 10a. Dashboard — Outfit Preview

Source: `CohesionEngine.outfitBuilder(items:profile:) -> [ScoredOutfit]`

- Shows `outfits.first` (highest scored outfit)
- If `outfits` is empty → hide card entirely
- Rendered as static flat-lay of 2–4 items
- Stone card (#E7E2DA), subtle shadow (< 8% opacity)
- No score shown on Dashboard preview card
- No animation. Static.

### 10b. Wardrobe — Outfit-First Grid

**Council Override 2:** Wardrobe is outfit-first. `outfitBuilder()` drives the Silhouettes section.

**Layout:**
- Hero card: first outfit (full width)
- Remaining outfits: 2-column grid
- Maximum 8 outfits shown (ViewModel applies `.prefix(8)`, not engine)
- If no outfits → fall back to item grid only

**Outfit card content:**
- Flat-lay rendering of outfit items
- Score shown as **status label** (e.g., "Aligned", "Coherent"), not number
- `silhouetteMix` shown as tag (e.g., "3 Structured · 1 Balanced")
- See Section 18 for ViewModel derivation

### 10c. Outfit Card Background Colors

Temperature-driven color system. Temperature takes priority. BaseGroup refines within neutral temperature.

| dominantTemperature | dominantBaseGroup | Background Hex | Token |
|--------------------|-------------------|---------------|-------|
| `.cool` | any non-nil | #DEE3EA | card-cool |
| `.warm` | any non-nil | #EAE2D6 | card-warm |
| `.neutral` | `.deep` | #D8D4CE | card-deep |
| `.neutral` | `.neutral` | #E7E2DA | card-neutral |
| `.neutral` | `.light` | #EDEAE5 | card-light |
| `.neutral` | `.accent` | #E0D8D3 | card-accent |
| any | nil (baseGroup tie) | #E7E2DA | card-neutral (fallback) |

See Section 18 for how `dominantTemperature` and `dominantBaseGroup` are derived from `ScoredOutfit`.

---

## Section 11 — Evolution Phase Visual Treatment

### 11a. Phase Journey

Shown as vertical list on Evolution tab. All 5 phases displayed (Evolving at top, Foundation at bottom).

| Phase Relation | Text Weight | Text Color |
|---------------|-------------|------------|
| Past (completed) | Regular (400) | textPrimary (#1F1C1A) |
| Current | Semibold (600) + "›" indicator | textPrimary (#1F1C1A) |
| Future (not reached) | Regular (400) | textMuted (#9A918A) |

Container: stone card (#E7E2DA), 18–22pt radius, 24pt vertical spacing between items.

### 11b. Timeline Phase Label Colors

Phase labels on timeline cards use opacity progression reflecting structural maturity.

| Phase | Label Opacity |
|-------|-------------|
| Foundation | 0.4 |
| Developing | 0.5 |
| Refining | 0.6 |
| Cohering | 0.8 |
| Evolving | 1.0 |

Font: 9pt, uppercase, letter-spacing 0.1em. Color: textMuted at specified opacity.

### 11c. Timeline Card Backgrounds

Background progressively darkens as structure improves over time.

| Position | Background Hex |
|----------|---------------|
| Earliest snapshot | #3A3530 |
| → progressively darker → | |
| Latest snapshot | #302C28 |

Card dimensions: 120pt width × 160pt height, 16pt corner radius. Current snapshot: accent border (1.5px, 50% opacity) + 5pt dot indicator (accent).

### 11d. Silhouette SVG Shape Principles

Each anchor item rendered as deterministic SVG silhouette on timeline cards. Shape determined by `category × silhouette` matrix. All shapes at 0° rotation — no editorial transforms.

| Category | Structured | Balanced | Relaxed |
|----------|-----------|----------|---------|
| Top | Sharp shoulders, narrow body | Soft shoulders, regular body | Dropped shoulders, wide body |
| Bottom | Straight leg, narrow | Tapered, regular width | Wide leg, relaxed |
| Shoes | Angular, defined sole | Rounded, moderate | Soft, chunky |
| Outerwear | Defined lapels, structured shoulder | Soft structure, regular fit | Oversized, rounded |

Exact SVG paths defined at SwiftUI implementation. These are shape principles only.

### 11e. Anchor Item Layout on Timeline Card

Source: `EvolutionEngine.snapshotAnchors(items:profile:) -> [WardrobeItem]`

| Item Count | Layout |
|-----------|--------|
| 1 | Centered |
| 2 | Side-by-side |
| 3 | Triangle (1 top, 2 bottom) |
| 4 | 2×2 grid |

Silhouette fill: derived from `baseGroup` + `temperature` (see Section 3c). Deleted items: use frozen anchor data from snapshot (category, silhouette, baseGroup, temperature preserved). Ghosted at 30% opacity with dashed outline.

---

## Section 12 — Momentum Descriptor Display

Source: `EvolutionEngine.momentum(snapshots:) -> MomentumResult`

Engine returns the composed `descriptor` string. ViewModel passes it through directly. No mapping needed.

**Descriptor matrix (for reference — engine computes this):**

| Trend \ Volatility | Low | Medium | High |
|--------------------|-----|--------|------|
| Improving | Upward Stability | Active Strengthening | Rapid Restructuring |
| Stable | Structural Consolidation | Holding Pattern | Unstable Plateau |
| Declining | Gentle Recalibration | Gradual Loosening | Temporary Instability |

< 3 snapshots → `"Structural Emergence"`

Display: caption weight, textMuted, below phase name on Evolution tab.

---

## Section 13 — Greeting Line Composition

Shown at top of Dashboard. Small, calm, secondary text color.

### Time-of-Day Rule

| Hour Range | Greeting |
|-----------|----------|
| 05:00–11:59 | "God morgen." |
| 12:00–16:59 | "God ettermiddag." |
| 17:00–04:59 | "God kveld." |

### Full Greeting Format

```
[Greeting] Strukturen din er [status display].
```

Examples:
- "God morgen. Strukturen din er Coherent."
- "God kveld. Strukturen din er Structuring."

Status display uses English CohesionStatus label (Structuring / Refining / Coherent / Aligned / Architected).

Font: body (16pt), textSecondary (#6B625C).

---

## Section 14 — Number Formatting Rules

| Data Type | Format | Example |
|-----------|--------|---------|
| Cohesion score (total) | Integer, no decimals | "72" |
| Component score | Integer, no decimals | "64" |
| Score delta | Signed integer, prefix +/− | "+9", "−3" |
| Improvement delta | Signed integer, prefix + | "+12" |
| Volatility | 1 decimal place | "4.2" |
| Percentage | Integer with % | "67%" |
| Usage count | Integer | "12" |
| Outfit score | Not shown as number — mapped to status label | "Coherent" |

No trailing zeros. No decimal points on integers. Delta sign always shown.

---

## Section 15 — Removal Impact Display

Source: `CohesionEngine.removalImpact(item:from:profile:) -> RemovalImpact`

Shown in Item Detail delete confirmation alert.

### Three Tiers

ViewModel identifies the most-affected component (largest negative delta) and total delta.

| Total Delta | Tier | Display String (Norwegian) |
|------------|------|---------------------------|
| < 2.0 | Minimal | "Minimal strukturell påvirkning." |
| 2.0–8.0 | Component Warning | "Fjerning reduserer [component] med [delta]." |
| > 8.0 | Significant Impact | "Fjerning påvirker garderoben vesentlig. [component] reduseres med [delta]." |

**Rules:**
- Show only the most-affected component, not all four
- Delta rounded to nearest integer for display
- Component names in Norwegian: Alignment, Density, Palette, Rotasjon
- No red/warning colors. Informational, not alarming. Uses textSecondary.
- [component] = Norwegian display name of the component with largest negative delta
- [delta] = absolute value of the delta as integer

---

## Section 16 — Structural Friction Display

Source: `OptimizeEngine.detectFriction(items:profile:) -> [StructuralFriction]`

Shown on Optimize tab below recommendations. Only items with `totalImprovement > 8` are surfaced.

### Display Format

```
[Item category display] · [Item silhouette display] — fjerning forbedrer [component] med [delta]
```

Example: "Outerwear · Relaxed — fjerning forbedrer Density med +12"

**Rules:**
- Informational tone. No alarm colors.
- "Review Impact" button → pushes to Item Detail with friction context
- Sorted by `totalImprovement` descending
- No destructive color on text — uses textSecondary for description, accent for delta
- If no friction items → section hidden entirely

---

## Section 17 — Progressive Depth UX Triggers

Dashboard sections appear progressively based on **semantic engine output**, not raw item count.

| Condition | Dashboard Shows |
|-----------|----------------|
| `items.count < 3` | Empty state: "Legg til plagg for å starte." |
| `items.count ≥ 3`, `densityScore == 0` | Score + Structural Identity + Optimize preview |
| `densityScore > 0` | + Component grid (2×2) |
| `outfitBuilder` returns ≥ 1 outfit | + Outfit preview card |
| `snapshotCount ≥ 2` | + Evolution phase card |
| `snapshotCount ≥ 3` | + Momentum descriptor |
| `snapshotCount ≥ 5` | + Anchor items on timeline |

**Rules:**
- Sections appear as data becomes structurally available
- No "locked" indicators. No "add more to unlock" messaging.
- Sections fade in with standard animation (200ms, ease-in-out, opacity 0→1)
- Order on Dashboard is fixed (score → components → outfit → optimize → evolution), but sections may be absent

---

## Section 18 — ScoredOutfit ViewModel Derivation

Source: `CohesionEngine.outfitBuilder(items:profile:) -> [ScoredOutfit]`

Engine returns `ScoredOutfit` with raw fields. ViewModel derives display properties.

### dominantSilhouette

```swift
let maxCount = outfit.silhouetteCounts.values.max() ?? 0
let tied = outfit.silhouetteCounts.filter { $0.value == maxCount }
dominantSilhouette = tied.count == 1 ? tied.first?.key : nil
// nil = tied → display "Mixed"
```

### dominantTemperature

```swift
let tempCounts = Dictionary(grouping: outfit.items, by: \.temperature)
    .mapValues(\.count)
let maxCount = tempCounts.values.max() ?? 0
let tied = tempCounts.filter { $0.value == maxCount }
dominantTemperature = tied.count == 1 ? tied.first!.key : .neutral
// Tie → .neutral (never nil)
```

### dominantBaseGroup

```swift
let bgCounts = Dictionary(grouping: outfit.items, by: \.baseGroup)
    .mapValues(\.count)
let maxCount = bgCounts.values.max() ?? 0
let tied = bgCounts.filter { $0.value == maxCount }
dominantBaseGroup = tied.count == 1 ? tied.first?.key : nil
// nil = tied → fallback to card-neutral background
```

### Outfit Status

Map `outfitScore` through same CohesionStatus thresholds:

| outfitScore Range | Status |
|------------------|--------|
| 0–0.49 | Structuring |
| 0.50–0.64 | Refining |
| 0.65–0.79 | Coherent |
| 0.80–0.89 | Aligned |
| 0.90–1.00 | Architected |

Note: `outfitScore` is 0–1 (not 0–100). Multiply by 100 for threshold comparison, or adjust thresholds to 0–1 scale.

### silhouetteMix Formatting

```swift
let mix = outfit.silhouetteCounts
    .sorted { $0.value > $1.value }
    .map { "\($0.value) \($0.key.displayName)" }
    .joined(separator: " · ")
// Example: "3 Structured · 1 Balanced"
```

Shown as tag on outfit card. Uses English silhouette names.

---

## Section 19 — Seasonal Recalibration Display

Source: `SeasonalEngine.recommend(latitude:month:currentSeason:) -> SeasonalRecommendation`

### Card Visibility

| `shouldRecalibrate` | Behavior |
|--------------------|----------|
| `true` | Show recalibration suggestion card on Profile tab |
| `false` | Hide card. Show current season display only. |

### Recalibration Card Content

- Current season: `seasonMode` display (Norwegian)
- Detected season: `detectedSeason` display (Norwegian)
- Button: "Rekalibrér" (accent color)
- Explanation: "Sesong-rekalibrering justerer vektene for cohesion-beregningen." (caption, textMuted)
- On tap: update season, recompute with `adjustedWeights(for:)`, confirmation: "Sesong oppdatert til [season display]."

### Equatorial Handling

`detectedSeason == nil` (equatorial latitude, |lat| < 15°):
- No auto-detection card shown
- Manual season change available: "Endre sesong manuelt" button
- Simple picker: Vår / Sommer or Høst / Vinter

---

## Section 20 — Engine → Screen Matrix

Every engine public function mapped to every screen that uses it.

### CohesionEngine

| Function | Dashboard | Wardrobe | Optimize | Evolution | Profile | Onboarding |
|----------|-----------|----------|----------|-----------|---------|------------|
| `compute(items:profile:)` | Hero score, component grid | — | Current snapshot | — | — | Screen 5 score |
| `compute(items:profile:weights:)` | Via seasonal | — | Via seasonal | — | Recalibration | — |
| `alignmentScore(items:profile:)` | Component grid | — | — | — | — | — |
| `densityScore(items:profile:)` | Component grid, progressive depth | — | — | — | — | — |
| `paletteScore(items:)` | Component grid | — | — | — | — | — |
| `rotationScore(items:)` | Component grid | — | — | — | — | — |
| `statusLevel(from:)` | Hero status, component descriptors | — | — | — | — | Screen 5 status |
| `structuralIdentity(items:)` | — | — | — | Hero identity | — | Screen 4 AHA |
| `itemContributions(items:profile:component:)` | Component Detail | — | — | — | — | — |
| `outfitBuilder(items:profile:)` | Outfit preview | Outfit grid | — | — | — | — |
| `removalImpact(item:from:profile:)` | — | Item Detail delete | — | — | — | — |

### OptimizeEngine

| Function | Dashboard | Wardrobe | Optimize | Evolution | Profile | Onboarding |
|----------|-----------|----------|----------|-----------|---------|------------|
| `optimize(items:profile:)` | Optimize preview card | — | Full results | — | — | Screen 5 preview |
| `weakestArea(from:)` | — | — | Weakness indicator | — | — | — |
| `detectFriction(items:profile:)` | — | — | Friction section | — | — | — |

### SeasonalEngine

| Function | Dashboard | Wardrobe | Optimize | Evolution | Profile | Onboarding |
|----------|-----------|----------|----------|-----------|---------|------------|
| `detectSeason(latitude:month:)` | — | — | — | — | Recalibration card | — |
| `recommend(latitude:month:currentSeason:)` | — | — | — | — | Recalibration card | — |
| `adjustedWeights(for:)` | Weighted compute | — | Weighted compute | — | On recalibrate | — |
| `baseWeights` | Default compute | — | Default compute | — | — | Default compute |

### EvolutionEngine

| Function | Dashboard | Wardrobe | Optimize | Evolution | Profile | Onboarding |
|----------|-----------|----------|----------|-----------|---------|------------|
| `evaluate(snapshots:)` | Evolution card | — | — | Full display | — | — |
| `phase(snapshots:)` | — | — | — | Phase Journey | — | — |
| `volatility(snapshots:)` | — | — | — | Volatility indicator | — | — |
| `trend(snapshots:)` | — | — | — | Trend indicator | — | — |
| `momentum(snapshots:)` | — | — | — | Momentum descriptor | — | — |
| `volatilityLevel(from:)` | — | — | — | Via momentum | — | — |
| `anchorItems(snapshots:)` | — | — | — | Timeline anchors (cross-snapshot) | — | — |
| `snapshotAnchors(items:profile:)` | — | — | — | Timeline card rendering | — | — |

---

## Section 21 — Recompute Trigger Summary

### User Action → Engine Recompute → Tab Updates

| User Action | Source Screen | Engines Triggered | Tabs Updated |
|-------------|-------------|-------------------|--------------|
| Add item | Wardrobe | Cohesion, Optimize, Evolution | Dashboard, Wardrobe, Optimize, Evolution |
| Delete item | Wardrobe (Item Detail) | Cohesion, Optimize, Evolution | Dashboard, Wardrobe, Optimize, Evolution |
| Edit item (structural fields) | Wardrobe (Item Detail) | Cohesion, Optimize, Evolution | Dashboard, Wardrobe, Optimize, Evolution |
| Change archetype | Profile | Cohesion, Optimize, Evolution | Dashboard, Wardrobe, Optimize, Evolution |
| Recalibrate season | Profile | Seasonal, Cohesion, Optimize | Dashboard, Optimize |
| Mark recommendation as acquired | Optimize | → triggers Add Item flow | All (via add item) |
| Pull to refresh | Dashboard | Cohesion, Optimize, Evolution | Dashboard |
| Complete onboarding | Onboarding | Cohesion, Optimize | Dashboard (initial state) |
| Reset profile | Profile | All cleared | → Onboarding (full restart) |

### Non-Triggers

These actions do NOT trigger recompute:
- UI rendering / tab switching
- Scrolling through timeline
- Viewing component detail
- Dismissing an optimize recommendation (removes candidate from result, no structural change)
- Changing season manually without recalibrating (updates preference only)

### Recompute Flow (via EngineCoordinator)

```
User Action
  → ViewModel calls EngineCoordinator.recompute()
    → Fetch persisted data (SwiftData → domain models)
    → CohesionEngine.compute()
    → OptimizeEngine.optimize()
    → EvolutionEngine.evaluate()
    → Update cache (EngineCacheEntity)
    → Create snapshot if needed (EvolutionSnapshotEntity)
    → Notify ViewModels
      → UI re-renders (main thread)
```

Engine runs on background thread. UI updates on main thread. No parallel engine runs. Recompute requests queued if already running.
