# CORET V2 — Engine → UI Mapping Specification

Status: **Active — Supersedes v1**
Date: 1 March 2026
Authors: GPT (framework) + Claude AI (values + visual mapping) + Claude Code (verification)
Purpose: Define exact translation from engine output to UI behavior under Design System v2.
Constraint: No new engine logic. No feature expansion. Pure mapping layer.

Engine enum values are unchanged. ViewModel maps engine values to v2 display labels.

---

## Core Rule

Engine computes. ViewModel maps. UI renders.

UI must NEVER calculate, modify, or reinterpret engine data.
UI may ONLY map, format, visualize, and animate.

All structural decisions trace back to an engine function.

---

## Design System v2 Changes Summary

| Aspect | v1 | v2 |
|--------|----|----|
| Background | Stone `#E7E2DA` | Deep warm dark `#1A1210` |
| Accent | Muted forest green `#2F4A3C` | Gold `#C9A96E` |
| Display font | SF Pro / DM Sans | Cormorant Garamond (serif) |
| Body font | DM Sans | DM Sans (unchanged) |
| Descriptors | Structuring→Architected | Building→Defined |
| Outfit cards | Static stone/tinted backgrounds | Dynamic gradients from garment colors |
| Friction color | `#7A3E3E` | Amber `#C4944A` (warm, not shaming) |
| Status pills | System UI (bold, colored bg) | Editorial (Cormorant italic, low opacity) |

---

## 1. Cohesion Score → Hero Presentation

### Engine Output
- `CohesionEngine.compute(items:profile:).totalScore` (0–100)
- `CohesionEngine.statusLevel(from:)` → `CohesionStatus`

### Descriptor Mapping (Locked — Unified)

Engine values are unchanged. ViewModel maps to v2 display labels.

| Engine Value | Score Range | Display Label | Ring Color | Ring Opacity | Score Opacity |
|---|---|---|---|---|---|
| `.structuring` | 0–49 | Building | Gold dim `#A08754` | 0.4 | 0.6 |
| `.refining` | 50–64 | Refining | Gold dim `#A08754` | 0.55 | 0.75 |
| `.coherent` | 65–79 | Composed | Gold `#C9A96E` | 0.7 | 0.85 |
| `.aligned` | 80–89 | Intentional | Gold `#C9A96E` | 0.85 | 0.95 |
| `.architected` | 90–100 | Defined | Gold `#C9A96E` | 1.0 | 1.0 |

### Score Ring (replaces progress bar as primary indicator)
- SVG circle, radius 65, centered in 140×140 container
- Track stroke: `#2B2320` (surface-2), width 2.5
- Fill stroke: gold (per table), width 2.5, stroke-linecap round
- `stroke-dasharray: 408`, `stroke-dashoffset = 408 - (score/100 × 408)`
- Rotated -90deg for top-start
- Animation: stroke-dashoffset transition 1s ease-out on load

### Score Number
- Cormorant Garamond, 52pt, weight 300
- Color: `#F2EDEA` (text primary)
- Opacity: per table above
- Centered absolutely inside ring
- Animation: count-up 300ms on load

### Status Label
- Cormorant Garamond, 18pt, weight 400, italic
- Color: `#C9A96E` (gold), opacity 0.85
- Preceded by 6px gold dot (opacity 0.7)
- Example: `● Composed`

### Identity String
- DM Sans, 11px, `#6B6058` (text-muted), letter-spacing 0.5px
- Below status label
- Example: "Structured · Deep-Toned · Cool"

### Secondary Progress Bar
- Width: 80%, centered below identity string
- Height: 2px
- Track: `#2B2320`
- Fill: linear-gradient(90deg, `#A08754`, `#C9A96E`), opacity 0.6
- Rounded caps

### Ambient Glow
- Radial gradient behind ring: `rgba(201,169,110,0.06)`, 200px diameter
- Centered on score

---

## 2. Component Scores → Dashboard Grid

### Engine Output
- `snapshot.alignmentScore`, `.densityScore`, `.paletteScore`, `.rotationScore`

### Descriptor Mapping (Same unified scale)

| Engine Value | Score Range | Display Label |
|---|---|---|
| `.structuring` | 0–49 | Building |
| `.refining` | 50–64 | Refining |
| `.coherent` | 65–79 | Composed |
| `.aligned` | 80–89 | Intentional |
| `.architected` | 90–100 | Defined |

### Card Styling (v2)

- Background: `#231C18` (surface)
- Border: `1px solid rgba(201,169,110,0.10)`
- Corner radius: 16px
- Padding: 16px
- Component name: 10px, uppercase, letter-spacing 1.5px, `#6B6058`
- Score: 30pt, Cormorant Garamond 400, `#F2EDEA`
- Accent line: 24px × 1.5px below score
- Descriptor: 12px, DM Sans, `#A09889`
- Chevron hint: `›` top-right, `#6B6058` at 0.3 opacity
- Grid: 2×2, 10px gap

### Accent Line Color

| Display Label | Line Color |
|---|---|
| Building | Amber `#C4944A` at 0.5 |
| Refining | Amber `#C4944A` at 0.5 |
| Composed | Gold `#C9A96E` at 0.5 |
| Intentional | Green `#8AB88A` at 0.5 |
| Defined | Green `#8AB88A` at 0.5 |

### Low Score Behavior
No special treatment. No warning colors. No alarm icons.
Score + descriptor + accent line communicate state. The system does not panic.

### Tap Target
Component card → push to Component Detail screen.

---

## 3. Enum Display Labels

Engine enum values are unchanged from V1. ViewModel maps to v2 display labels.

### CohesionStatus

| Engine Value | Display (Norwegian) | Display (English) |
|---|---|---|
| `.structuring` | Bygger opp | Building |
| `.refining` | Finjusterer | Refining |
| `.coherent` | Sammensatt | Composed |
| `.aligned` | Bevisst | Intentional |
| `.architected` | Definert | Defined |

### EvolutionPhase

| Engine Value | Display (Norwegian) | Display (English) |
|---|---|---|
| `.foundation` | Fundament | Foundation |
| `.developing` | Utvikling | Developing |
| `.refining` | Finjustering | Refining |
| `.cohering` | Sammensmelting | Cohering |
| `.evolving` | Evolusjon | Evolving |

### Archetype

| Engine Value | Display |
|---|---|
| `.structuredMinimal` | Tailored |
| `.smartCasual` | Smart Casual |
| `.relaxedStreet` | Street |

### Silhouette

| Engine Value | Display (Norwegian) | Display (English) |
|---|---|---|
| `.structured` | Strukturert | Structured |
| `.balanced` | Balansert | Balanced |
| `.relaxed` | Avslappet | Relaxed |
| `nil` | Blandet | Mixed |

### BaseGroup

| Engine Value | Display |
|---|---|
| `.neutral` | Neutral |
| `.deep` | Deep-Toned |
| `.light` | Light-Toned |
| `.accent` | Accent-Driven |
| `nil` | Mixed |

Unified across all screens including onboarding.

### Temperature

| Engine Value | Display |
|---|---|
| `.cool` | Cool |
| `.warm` | Warm |
| `.neutral` | Neutral |

### ItemCategory

| Engine Value | Display (Norwegian) |
|---|---|
| `.top` | Overdel |
| `.bottom` | Underdel |
| `.outerwear` | Ytterplagg |
| `.shoes` | Sko |

### SeasonMode

| Engine Value | Display (Norwegian) |
|---|---|
| `.springSummer` | Vår / Sommer |
| `.autumnWinter` | Høst / Vinter |

### EvolutionTrend

| Engine Value | Display |
|---|---|
| `.improving` | Improving |
| `.stable` | Stable |
| `.declining` | Declining |

### WeaknessArea

| Engine Value | Display |
|---|---|
| `.alignment` | Alignment |
| `.density` | Density |
| `.palette` | Palette |
| `.rotation` | Rotasjon |

---

## 4. Structural Identity Composition

### Engine Output
`CohesionEngine.structuralIdentity(items:) -> StructuralIdentity`

```swift
StructuralIdentity {
    dominantSilhouette: Silhouette?
    dominantBaseGroup: BaseGroup?
    dominantTemperature: Temperature  // never nil
}
```

### Display String
```swift
let silLabel = identity.dominantSilhouette?.displayName ?? "Mixed"
let bgLabel = identity.dominantBaseGroup?.displayName ?? "Mixed"
let tempLabel = identity.dominantTemperature.displayName

identityString = "\(silLabel) · \(bgLabel) · \(tempLabel)"
```

Example: `"Structured · Deep-Toned · Cool"`

### Usage Locations
- Dashboard: below score hero, DM Sans 11px, `#6B6058`
- Evolution hero: Line 1 = silhouette (Cormorant 22pt italic), Line 2 = baseGroup · temperature (DM Sans 12px, `#6B6058`)
- Onboarding AHA: [Archetype] · [BaseGroup] · [Temperature]

### Nil Fallbacks
- Silhouette nil → "Mixed" / "Blandet"
- BaseGroup nil → "Mixed"
- Temperature → never nil (resolves to `.neutral` on tie)

---

## 5. Color Swatch Lookup Tables

### Onboarding Swatches (8)

| Name | Hex | rawColor | baseGroup | temperature |
|---|---|---|---|---|
| Black | #1A1A1A | "Black" | `.neutral` | `.neutral` |
| Charcoal | #4A4A4A | "Charcoal" | `.neutral` | `.cool` |
| Navy | #1B2A3B | "Navy" | `.deep` | `.cool` |
| Brown | #5C3D2E | "Brown" | `.deep` | `.warm` |
| Olive | #4A5A3A | "Olive" | `.deep` | `.warm` |
| White | #F0EBE3 | "White" | `.light` | `.neutral` |
| Cream | #C4B9AA | "Cream" | `.light` | `.warm` |
| Burgundy | #6B2D35 | "Burgundy" | `.accent` | `.warm` |

### Add Item Extended Palette (+2)

| Name | Hex | rawColor | baseGroup | temperature |
|---|---|---|---|---|
| Light Gray | #B8B3AC | "Light Gray" | `.light` | `.cool` |
| Rust | #8B4A2B | "Rust" | `.accent` | `.warm` |

### v2: Dynamic Gradient Generation

In v2, outfit card backgrounds are generated from garment colors, not static swatches.

Gradient algorithm (ViewModel):
```swift
func outfitGradient(from items: [WardrobeItem]) -> LinearGradient {
    let dominantColors = items.prefix(2).map { $0.rawColor.darkened(by: 0.7) }
    let secondary = items.count > 2 ? items[2].rawColor.darkened(by: 0.8) : dominantColors.last!

    return LinearGradient(
        stops: [
            .init(color: dominantColors[0], location: 0.0),
            .init(color: dominantColors.count > 1 ? dominantColors[1] : secondary, location: 0.4),
            .init(color: secondary, location: 1.0)
        ],
        startPoint: .topLeading,
        endPoint: .bottomTrailing
    )
}
```

Ambient glow: radial gradients from same source colors at 0.14–0.16 opacity.

Rule: If the gradient cannot be explained by referencing garment colors, it is not valid.

---

## 6. Contribution Context Display Labels (v2 colors)

Source: `CohesionEngine.itemContributions(items:profile:component:)`

### AlignmentMatchType

| Value | Label | Color |
|---|---|---|
| `.primary` | Primær match | Gold `#C9A96E` |
| `.secondary` | Sekundær match | `#F2EDEA` (text) |
| `.neutral` | Nøytral | `#6B6058` (muted) |
| `.conflict` | Konflikt | Amber `#C4944A` |

### ParticipationLevel

| Value | Label |
|---|---|
| `.high` | Høy deltakelse |
| `.low` | Lav deltakelse |

### PaletteRole

| Value | Label |
|---|---|
| `.balanced` | Balansert |
| `.excessAccent` | Overvekt aksent |
| `.temperatureClash` | Temperaturkonflikt |

### UsageLevel

| Value | Label |
|---|---|
| `.even` | Jevn rotasjon |
| `.overused` | Overbrukt |
| `.underused` | Underbrukt |

---

## 7. Optimize Candidate Description

Source: `OptimizeEngine.optimize(items:profile:) -> OptimizeResult`

### Headline Composition
```swift
"\(candidate.silhouette.norwegian) \(candidate.category.norwegian) i \(candidate.baseGroup.displayName) base"
```
Example: "Strukturert ytterplagg i nøytral base"

### Impact Display
- Format: `+18 Density · +9 Cohesion`
- Font: Cormorant Garamond 20pt (values), DM Sans 11px (labels)
- Color: Gold `#C9A96E` for values, `#A09889` for labels
- Stacked or inline, natural flow (not monospace)

### Ghosted Silhouette
- Dashed SVG border, gold at 30% opacity
- Represents a **role**, never a specific garment
- Same silhouette SVG system as wardrobe items

### Category Display (Norwegian)

| Engine Value | Display |
|---|---|
| `.top` | overdel |
| `.bottom` | underdel |
| `.outerwear` | ytterplagg |
| `.shoes` | sko |

---

## 8. Weakness Explanation Text

### Per WeaknessArea (Optimize tab diagnostic)

| Area | Diagnostic (Norwegian) |
|---|---|
| Alignment | Garderoben mangler konsistent silhuett-retning på tvers av plagg. |
| Density | Garderoben har hull i kategori-dekning eller ubalanserte proporsjoner. |
| Palette | Fargefordelingen mangler balanse mellom nøytrale og aksentfarger. |
| Rotation | Noen plagg er overbrukt mens andre er underbrukt i outfits. |

### Component Detail Measurement Explanation

| Area | Explanation |
|---|---|
| Alignment | Måler hvor konsistent silhuett og arketype-match er på tvers av garderoben. |
| Density | Måler kategori-fordeling, lag-dekning og kapsel-balanse. |
| Palette | Måler fargeharmoni basert på baseGroup- og temperatur-fordeling. |
| Rotation | Måler bruksfordeling — om alle plagg bidrar jevnt til outfits. |

---

## 9. Onboarding Micro-Insight Rules

5 ordered rules (first match wins) for AHA screen:

| Priority | Condition | Insight Template |
|---|---|---|
| 1 | BaseGroup dominance ≥ 66% | "Din garderobe har en tydelig [baseGroup]-profil." |
| 2 | All silhouettes identical | "Alle plaggene dine deler [silhouette] silhuett." |
| 3 | Mixed temperature (no >50%) | "Du har en balansert miks av varme og kalde toner." |
| 4 | Full primary archetype alignment | "Plaggene dine passer godt med [archetype]-stilen." |
| 5 | Default | "En god start — legg til flere plagg for dypere analyse." |

---

## 10. Outfit Display (v2 — Dynamic Gradients)

### Engine Output
`CohesionEngine.outfitBuilder(items:profile:) -> [ScoredOutfit]`

```swift
ScoredOutfit {
    items: [WardrobeItem]
    outfitScore: Double       // 0–1
    alignmentScore: Double
    paletteHarmony: Double
    silhouetteConsistency: Double
    silhouetteCounts: [Silhouette: Int]
}
```

### v2 Card Background: Dynamic Gradient

Replace static tinted backgrounds with garment-derived gradients:

1. Extract dominant rawColors from outfit items (up to 4)
2. Generate `linear-gradient(155deg, ...)` using darkened versions
3. Add `radial-gradient` ambient glow from same colors (0.14–0.16 opacity)
4. Pill type color tinted to match dominant garment color

### Source Color Dots
- Position: bottom-right of card visual area
- Size: 9–10px circles
- Border: `1px solid rgba(255,255,255,0.15)`
- Shadow: `0 1px 4px rgba(0,0,0,0.3)`
- Show one dot per unique garment color
- Purpose: prove gradient is data-derived, not decorative

### Color Explanation Text
- Position: inside card, below card-info
- Font: DM Sans 11px, `#6B6058`, line-height 1.5
- Contains inline 7px color dots referencing source colors
- Template: "Gradient fra [dot] [garment] og [dot] [garment] → [description]."
- Border-top: `1px solid rgba(255,255,255,0.03)`

### Card Info Layout
- Name: Cormorant Garamond 19–20px, italic 400
- Pills: DM Sans 9.5px, uppercase, 0.8px letter-spacing
  - Type pill: tinted to dominant garment color
  - Count pill: `rgba(255,255,255,0.06)` bg
- Status: Cormorant Garamond 13px, italic 400
  - Intentional/Defined → green `#8AB88A`, bg `rgba(106,155,106,0.06)`
  - Gap → amber `#C4944A`, bg `rgba(196,148,74,0.06)`

### Outfit Status Mapping

Map `outfitScore` (0–1) through CohesionStatus thresholds:

| outfitScore × 100 | Engine Value | Display |
|---|---|---|
| 0–49 | `.structuring` | Building |
| 50–64 | `.refining` | Refining |
| 65–79 | `.coherent` | Composed |
| 80–89 | `.aligned` | Intentional |
| 90–100 | `.architected` | Defined |

### silhouetteMix Formatting
```swift
outfit.silhouetteCounts
    .sorted { $0.value > $1.value }
    .map { "\($0.value) \($0.key.displayName)" }
    .joined(separator: " · ")
// Example: "3 Structured · 1 Balanced"
```

### Silhouette Rendering
- SVG stroke-only illustrations (no fill, no photos)
- Stroke colors derived from garment rawColor
- Stroke width: 1.2–1.3px, stroke opacity: 0.4–0.6
- Inner detail at 0.2–0.3 opacity
- Flat-lay: top row (outerwear + top), bottom row (bottoms + shoes)

### Wardrobe View Structure
- **Outfits view** (default): Full outfit cards with dynamic gradients
- **Items view** (toggle): 3-column grid of individual garments
- Toggle: text-driven underline tabs (not segmented control)

### Dashboard Preview
- Uses `outfits.first` (highest scored)
- If outfits empty: hide card
- Same dynamic gradient card, slightly smaller

---

## 11. Evolution Phase Visual Treatment (v2)

### Phase Journey Display

| Phase State | Font | Weight | Color | Opacity |
|---|---|---|---|---|
| Past (completed) | Cormorant Garamond | 300 | `#6B6058` | 0.5 |
| Current | Cormorant Garamond | 400 italic | `#C9A96E` (gold) | 1.0 |
| Future | Cormorant Garamond | 300 | `#6B6058` | 0.3 |

### Phase Progress Dots
- 5 dots, one per phase
- Size: 20px wide × 4px tall, radius 2px
- Filled (past): gold at 0.6
- Current: gold at 1.0
- Empty (future): `#2B2320` with `1px solid rgba(201,169,110,0.08)`

### Evolution Card (Dashboard mini)
- Background: `#231C18`
- Border: `1px solid rgba(201,169,110,0.10)`
- Phase: Cormorant Garamond 22px, italic, `#F2EDEA`
- Narrative: DM Sans 12px, `#A09889`
- Dots below narrative

### Timeline Card Backgrounds (full Evolution tab)
- Each snapshot card uses garment-derived gradient (same system as outfit cards)
- Current snapshot: subtle gold border `1px solid rgba(201,169,110,0.25)`
- Phase label: DM Sans 10px, uppercase, letter-spacing 1.5px

### Silhouette SVG Shape Principles (unchanged)

| Category | Structured | Balanced | Relaxed |
|---|---|---|---|
| Top | Sharp shoulders, narrow body | Soft shoulders, regular body | Dropped shoulders, wide body |
| Bottom | Straight leg, narrow | Tapered, regular width | Wide leg, relaxed |
| Shoes | Angular, defined sole | Rounded, moderate | Soft, chunky |
| Outerwear | Defined lapels, structured shoulder | Soft structure, regular fit | Oversized, rounded |

### Anchor Item Layout (unchanged)

Source: `EvolutionEngine.snapshotAnchors(items:profile:)`

| Item Count | Layout |
|---|---|
| 1 | Centered |
| 2 | Side-by-side |
| 3 | Triangle (1 top, 2 bottom) |
| 4 | 2×2 grid |

---

## 12. Momentum Descriptor Display

Source: `EvolutionEngine.momentum(snapshots:) -> MomentumResult`

Engine returns composed `descriptor` string. ViewModel passes through directly.

### Momentum Matrix (unchanged)

| Trend \ Volatility | Low | Medium | High |
|---|---|---|---|
| Improving | Upward Stability | Active Strengthening | Rapid Restructuring |
| Stable | Structural Consolidation | Holding Pattern | Unstable Plateau |
| Declining | Gentle Recalibration | Gradual Loosening | Temporary Instability |

< 3 snapshots → `"Structural Emergence"`

Display: DM Sans 12px, `#A09889`, below phase on Evolution card.

---

## 13. Greeting Line Composition

| Time | Greeting |
|---|---|
| 05:00–11:59 | God morgen |
| 12:00–17:59 | God ettermiddag |
| 18:00–04:59 | God kveld |

Full: "[Greeting]. Garderoben din er [descriptor]."

Example: "God morgen. Garderoben din er Composed."

v2 note: Greeting is optional on Dashboard. Score hero with status label may be sufficient. Implementation decision.

---

## 14. Number Formatting Rules

| Data Type | Format | Example |
|---|---|---|
| Score (total/component) | Integer, no decimal | 72 |
| Delta (improvement) | Signed integer, + prefix | +18 |
| Delta (regression) | Signed integer, − prefix | −4 |
| Volatility | 1 decimal | 7.2 |
| Outfit score | Not shown as number — mapped to status label | Composed |

Never show decimals to users on scores. Engine computes with doubles; display truncates.

---

## 15. Removal Impact Display

Source: `CohesionEngine.removalImpact(item:from:profile:) -> RemovalImpact`

### ViewModel Logic
1. Calculate delta per component: `before - after`
2. Find component with largest positive delta (most affected)
3. Calculate total delta: `totalBefore - totalAfter`

### Presentation Rules

| Total Delta | Behavior |
|---|---|
| < 2.0 | "Minimal strukturell påvirkning." |
| 2.0–8.0 | "Fjerning reduserer [component] med [delta]." |
| > 8.0 | "Fjerning påvirker garderoben vesentlig. [component] reduseres med [delta]." |

- Show only the most-affected component
- Delta rounded to integer
- No alarm colors. Informational. Amber for high impact, text-muted for minimal.
- Component names in Norwegian: Alignment, Density, Palette, Rotasjon

---

## 16. Structural Friction Display

Source: `OptimizeEngine.detectFriction(items:profile:) -> [StructuralFriction]`

### v2 Treatment

- Friction items shown below Optimize candidates
- No alarm colors — amber `#C4944A` for impact, not red
- Format: "[Item description] — fjerning forbedrer [component] med [delta]"
- Font: DM Sans 12px, `#A09889` for description, amber for impact
- "Se påvirkning" button → navigates to item detail
- Button style: text-only, amber color, not destructive appearance
- If no friction items → section hidden entirely

---

## 17. Progressive Depth UX Triggers

Sections appear as data becomes available. No "locked" indicators. No "add more to unlock."

| Condition | Dashboard Shows |
|---|---|
| `items.count < 3` | Empty state: "Legg til plagg for å starte." |
| `items.count ≥ 3`, `densityScore == 0` | Score + Identity + Optimize preview |
| `densityScore > 0` | + Component grid (2×2) |
| `outfitBuilder` returns ≥ 1 | + Outfit preview card |
| `snapshotCount ≥ 2` | + Evolution phase card |
| `snapshotCount ≥ 3` | + Momentum descriptor |
| `snapshotCount ≥ 5` | + Anchor items on timeline |

The system shows what it knows. Nothing more.

---

## 18. ScoredOutfit ViewModel Derivation

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
// nil = tied → neutral gradient fallback
```

### V2 Active Display Fields
- items → SVG silhouettes in flat-lay
- outfitScore → status descriptor (not number)
- silhouetteCounts → silhouetteMix tag
- Dynamic gradient background from item rawColors
- Source color dots
- Color explanation text
- Pill type tinted to dominant garment color

### V2 Reserved (not displayed)
- alignmentScore (internal)
- paletteHarmony (internal)
- silhouetteConsistency (internal)

---

## 19. Seasonal Recalibration Display

Source: `SeasonalEngine.recommend(latitude:month:currentSeason:) -> SeasonalRecommendation`

### Visibility Rules
- Show recalibration card only when `shouldRecalibrate == true`
- Card appears on Profile tab
- Card style: `#231C18` background, gold border
- "Rekalibrér sesong" button → confirmation flow → full recompute with `adjustedWeights(for:)`

### Equatorial Edge Case
- `detectedSeason == nil` (equatorial, |latitude| < 15°)
- No auto-detection card shown
- Manual season change available: "Endre sesong manuelt" button
- Simple picker: Vår / Sommer or Høst / Vinter

---

## 20. Engine → Screen Matrix

| Engine Function | Dashboard | Wardrobe | Optimize | Evolution | Profile | Onboarding |
|---|---|---|---|---|---|---|
| `CohesionEngine.compute()` | Hero score, grid | — | Current snapshot | — | — | Screen 5 |
| `CohesionEngine.statusLevel()` | Hero status, descriptors | — | — | — | — | Screen 5 |
| `CohesionEngine.alignmentScore()` | Grid | — | — | — | — | — |
| `CohesionEngine.densityScore()` | Grid, progressive depth | — | — | — | — | — |
| `CohesionEngine.paletteScore()` | Grid | — | — | — | — | — |
| `CohesionEngine.rotationScore()` | Grid | — | — | — | — | — |
| `CohesionEngine.structuralIdentity()` | Identity string | — | — | Hero identity | Identity | AHA screen |
| `CohesionEngine.itemContributions()` | Component Detail | — | — | — | — | — |
| `CohesionEngine.outfitBuilder()` | Preview card | Outfit cards | — | — | — | — |
| `CohesionEngine.removalImpact()` | — | Delete warning | — | — | — | — |
| `OptimizeEngine.optimize()` | Mini preview | — | Full results | — | — | Screen 5 |
| `OptimizeEngine.weakestArea()` | — | — | Weakness card | — | — | — |
| `OptimizeEngine.detectFriction()` | — | — | Friction list | — | — | — |
| `SeasonalEngine.detectSeason()` | — | — | — | — | Recal card | — |
| `SeasonalEngine.recommend()` | — | — | — | — | Recal card | — |
| `SeasonalEngine.adjustedWeights()` | Weighted compute | — | Weighted compute | — | On recalibrate | — |
| `EvolutionEngine.evaluate()` | Phase card | — | — | Full display | — | — |
| `EvolutionEngine.phase()` | — | — | — | Phase Journey | — | — |
| `EvolutionEngine.volatility()` | — | — | — | Volatility | — | — |
| `EvolutionEngine.trend()` | — | — | — | Trend | — | — |
| `EvolutionEngine.momentum()` | — | — | — | Descriptor | — | — |
| `EvolutionEngine.anchorItems()` | — | — | — | Timeline (cross-snapshot) | — | — |
| `EvolutionEngine.snapshotAnchors()` | — | — | — | Timeline cards | — | — |

---

## 21. Recompute Trigger Summary

| User Action | Source Screen | Engines Triggered | Tabs Updated |
|---|---|---|---|
| Add item | Wardrobe | Cohesion, Optimize, Evolution | All |
| Edit item (structural) | Wardrobe Detail | Cohesion, Optimize, Evolution | Dashboard, Wardrobe, Optimize, Evolution |
| Delete item | Wardrobe Detail | Cohesion, Optimize, Evolution | All |
| Change archetype | Profile | Cohesion, Optimize, Evolution | All |
| Recalibrate season | Profile | Seasonal, Cohesion, Optimize | Dashboard, Optimize, Profile |
| Mark acquired | Optimize | → Add Item flow | All (via add item) |
| Pull to refresh | Dashboard | Cohesion, Optimize, Evolution | Dashboard |
| Complete onboarding | Onboarding | Cohesion, Optimize | Dashboard |
| Reset profile | Profile | All cleared | → Onboarding |

### Non-Triggers
- UI rendering / tab switching
- Scrolling through timeline
- Viewing component detail
- Dismissing optimize recommendation
- Manual season change without recalibration

---

## Edge Case Visual Rules

| State | Behavior |
|---|---|
| Empty wardrobe (0 items) | Show onboarding CTA. No scores. |
| 1–2 items | Score hero only. No grid, no outfits. |
| No valid outfits | Hide outfit section entirely. |
| No recommendations | Hide Optimize preview on Dashboard. |
| Score regression | No alarm. Show delta as negative. |
| All items same category | Density scores low. Gap detection flags. |
| < 3 snapshots | Hide momentum. Show phase only. |
| nil dominant silhouette | Display "Mixed" / "Blandet" |
| nil dominant baseGroup | Use neutral gradient fallback |

Rule: When data is absent, the UI section is absent.

---

## Responsibility Matrix

| Layer | Responsibility | Example |
|---|---|---|
| Engine | Compute structural truth | `totalScore = 72.0`, `statusLevel = .coherent` |
| ViewModel | Map to v2 presentation | `descriptor = "Composed"`, `ringOpacity = 0.7` |
| SwiftUI | Render from state | Score in ring with gold stroke, italic Composed label |

No exceptions. No shortcuts.

---

## v1 → v2 Migration Checklist

- [ ] Add CohesionStatus → v2 display label mapping in ViewModel
- [ ] Replace stone backgrounds with dark surface (`#1A1210`)
- [ ] Replace green accent with gold accent (`#C9A96E`)
- [ ] Add Cormorant Garamond font to project
- [ ] Implement dynamic gradient generation for outfit cards
- [ ] Implement source color dot rendering
- [ ] Implement color explanation text on outfit cards
- [ ] Replace segmented control with underline tabs in Wardrobe
- [ ] Implement 3-column Items grid view
- [ ] Update status pills to editorial style (Cormorant italic)
- [ ] Add score ring (SVG circle) replacing progress bar as primary
- [ ] Add gold glow to active nav tab
- [ ] Add noise overlay texture
- [ ] Update all color constants in theme file
- [ ] Replace friction red `#7A3E3E` with amber `#C4944A`

---

*Council document. Supersedes engine_ui_mapping_v1.md.*
*Engine enum values unchanged. ViewModel handles all v2 display mapping.*
*Last updated: 1 March 2026*
