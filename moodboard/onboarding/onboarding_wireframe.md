# CORET — Onboarding Wireframe (V2)

## Design Intent

Onboarding is the most critical flow in CORET.
It must deliver structural value in under 3 minutes.

This is not a tutorial. Not a walkthrough. Not a sign-up form.
It is the moment the user discovers CORET is a system, not a catalog.

Target: Archetype → 3 items → Identity reveal → First Analysis.
Total time: under 3 minutes.
Total taps: ~10 (2 archetype + 6 item + 2 confirm).

---

## Flow Overview

```
Screen 1 — Primary Archetype
Screen 2 — Secondary Archetype
Screen 3 — Quick-Add: Top + Bottom + Shoes (single scrollable screen)
Screen 4 — AHA: Structural Identity reveal
Screen 5 — First State (curated score + identity + optimize insight)
→ Dashboard
```

5 screens. Category is implicit. The flow guides Top → Bottom → Shoes.
No category picker needed. 2 taps per item (silhouette + color).
Progress dots shown across all screens.

---

## Screen 1 — Primary Archetype

```
    ┌─────────────────────────────────────┐
    │  9:41              CORET        ●●● │
    │  ● ○ ○ ○ ○                         │
    │                                     │
    │  STRUKTURELL RETNING                │
    │                                     │
    │  Hva beskriver                      │
    │  garderoben din?                    │
    │                                     │
    │  Velg retningen som ligger nærmest. │
    │  Dette er din primære base.         │
    │                                     │
    │  ┌───┬──────────────────────────┐   │
    │  │ ▭ │ Tailored                 │ ✓ │
    │  │   │ Clean lines, definerte   │   │
    │  │   │ former, presis passform. │   │
    │  └───┴──────────────────────────┘   │
    │                                     │
    │  ┌───┬──────────────────────────┐   │
    │  │ ▢ │ Smart Casual             │   │
    │  │   │ Mellom formelt og        │   │
    │  │   │ avslappet. Kontrollert.  │   │
    │  └───┴──────────────────────────┘   │
    │                                     │
    │  ┌───┬──────────────────────────┐   │
    │  │ ◯ │ Street                   │   │
    │  │   │ Komfort først. Myke      │   │
    │  │   │ former, ledig passform.  │   │
    │  └───┴──────────────────────────┘   │
    │                                     │
    │  ┌─────────────────────────────────┐│
    │  │  Velg sekundær retning →        ││
    │  └─────────────────────────────────┘│
    └─────────────────────────────────────┘
```

### Elements

- Progress dots: 5 dots, first active
- Label: "STRUKTURELL RETNING" (uppercase, textMuted, letter-spacing 2.5px)
- Header: "Hva beskriver garderoben din?" (h1, DM Serif Display, textOnDark)
- Subtitle: "Velg retningen som ligger nærmest. Dette er din primære base." (body, textMuted)
- 3 archetype cards, full-width, semi-transparent dark background
- Each card: silhouette SVG (left) + archetype name (h3, bold) + 2-line description (caption, textMuted)
- Selected state: accent background tint + accent border + checkmark circle (top-right)
- CTA: "Velg sekundær retning →" (accent button, full width, 12pt radius)

### Archetype Cards — Visual + Engine Mapping

| Card | SVG | User Label | Engine Value | Conflict |
|------|-----|-----------|-------------|----------|
| Sharp geometric rect, rx=2 | Tailored | structuredMinimal | ↔ Street |
| Balanced rect, rx=6 | Smart Casual | smartCasual | neutral |
| Wide rounded rect, rx=12 | Street | relaxedStreet | ↔ Tailored |

SVG silhouettes are abstract structural shapes — NOT fashion illustrations.
- Tailored: sharp rectangular, straight lines, minimal radius
- Smart Casual: medium curves, balanced proportions
- Street: wide rounded shapes, soft curves

### Rules

- No "skip" option. Archetype is required.
- Tap selects → accent border + checkmark appears
- CTA enabled only when selection made
- Brief haptic feedback on selection (soft impact)
- Transition: fade + slight upward movement (200ms, ease-in-out)

### Important: "Street" Visual Communication

"Street" must visually communicate relaxedStreet structure —
comfort, soft shapes, relaxed proportions.
NOT hype-streetwear, NOT trend-driven, NOT brand-focused.
The visual must feel structural, not cultural.

---

## Screen 2 — Secondary Archetype

```
    ┌─────────────────────────────────────┐
    │  9:41              CORET        ●●● │
    │  ● ● ○ ○ ○                         │
    │                                     │
    │  SEKUNDÆR RETNING                   │
    │                                     │
    │  Hva er din andre side?             │
    │                                     │
    │  De fleste garderoben har en        │
    │  blanding. Velg din sekundære.      │
    │                                     │
    │  ┌─────────────────────────────────┐│
    │  │  ● Primær: Tailored             ││
    │  └─────────────────────────────────┘│
    │                                     │
    │  ┌───┬──────────────────────────┐   │
    │  │ ▭ │ Tailored                 │   │
    │  │   │ Allerede valgt som       │   │
    │  │   │ primær.                  │   │  ← disabled (25% opacity)
    │  └───┴──────────────────────────┘   │
    │                                     │
    │  ┌───┬──────────────────────────┐   │
    │  │ ▢ │ Smart Casual             │ ✓ │
    │  │   │ Mellom formelt og        │   │
    │  │   │ avslappet. Kontrollert.  │   │
    │  └───┴──────────────────────────┘   │
    │                                     │
    │  ┌───┬──────────────────────────┐   │
    │  │ ◯ │ Street                   │   │
    │  │   │ Komfort først. Myke      │   │
    │  │   │ former, ledig passform.  │   │
    │  └───┴──────────────────────────┘   │
    │                                     │
    │  ┌─────────────────────────────────┐│
    │  │  Legg til plagg →               ││
    │  └─────────────────────────────────┘│
    └─────────────────────────────────────┘
```

### Elements

- Progress dots: 5 dots, first two filled
- Selection context card: accent-tinted background showing "Primær: [archetype]"
- All 3 archetype cards shown — primary is disabled (25% opacity, non-interactive)
- Disabled card description: "Allerede valgt som primær."
- Remaining 2 cards: same style as Screen 1, selectable
- CTA: "Legg til plagg →"

### Rules

- Primary archetype shown but disabled (user sees what they picked)
- Secondary cannot equal primary (enforced by disabled state)
- No "none" option — secondary is required for engine scoring
- CTA enabled only when selection made
- Secondary selection preserved if user navigates back

---

## Screen 3 — Quick-Add (Top + Bottom + Shoes)

Single scrollable screen with 3 guided steps.

```
    ┌─────────────────────────────────────┐
    │  9:42              CORET        ●●● │
    │  ● ● ● ○ ○                         │
    │                                     │
    │  LEGG TIL PLAGG                     │
    │                                     │
    │  3 plagg. 2 valg hver.              │
    │  Silhuett og farge.                 │
    │  Vi styrer rekkefølgen.             │
    │                                     │
    │  ┌──────────────────────────────┐   │
    │  │  ✓ Din topp                  │   │
    │  │    Structured · Navy         │   │
    │  │                              │   │
    │  │  SILHUETT                    │   │
    │  │  [Structured] [Balanced] [Relaxed]│
    │  │                              │   │
    │  │  FARGE                       │   │
    │  │  ● ● ● ● ● ● ● ●          │   │
    │  └──────────────────────────────┘   │
    │                                     │
    │  ┌──────────────────────────────┐   │
    │  │  ○ Din bunn                  │   │
    │  │    Velg silhuett og farge    │   │
    │  │                              │   │
    │  │  SILHUETT                    │   │
    │  │  [Structured] [Balanced] [Relaxed]│
    │  │                              │   │
    │  │  FARGE                       │   │
    │  │  ● ● ● ● ● ● ● ●          │   │
    │  └──────────────────────────────┘   │
    │                                     │
    │  ┌──────────────────────────────┐   │
    │  │  ○ Dine sko                  │   │
    │  │    Siste plagg               │   │
    │  │                              │   │
    │  │  SILHUETT                    │   │
    │  │  [Structured] [Balanced] [Relaxed]│
    │  │                              │   │
    │  │  FARGE                       │   │
    │  │  ● ● ● ● ● ● ● ●          │   │
    │  └──────────────────────────────┘   │
    │                                     │
    │  ┌─────────────────────────────────┐│
    │  │  Analyser garderoben →          ││  ← disabled until all 3 done
    │  └─────────────────────────────────┘│
    └─────────────────────────────────────┘
```

### Guided Step Structure

Each of the 3 items follows the same pattern:

1. **Step header**: icon (42×42pt, rounded 13pt) + title + subtitle
   - Incomplete: circle icon, muted text, "Velg silhuett og farge"
   - Complete: checkmark icon with accent tint, summary text (e.g. "Structured · Navy")
2. **Pickers box**: semi-transparent container with silhouette + color pickers
   - Incomplete: subtle dark border
   - Complete: accent-tinted background + accent border

### Category-Specific Silhouette SVGs

Each category shows distinct mini garment silhouettes (not just shapes):

**Top silhouettes:**
| Option | SVG | Engine value |
|--------|-----|-------------|
| Structured | Sharp rectangular torso, straight shoulders | .structured |
| Balanced | Medium rounded torso, natural shoulders | .balanced |
| Relaxed | Wide rounded torso, dropped shoulders | .relaxed |

**Bottom silhouettes:**
| Option | SVG | Engine value |
|--------|-----|-------------|
| Structured | Straight-leg pants, sharp lines | .structured |
| Balanced | Regular-fit pants, medium taper | .balanced |
| Relaxed | Wide-leg pants, flared bottom | .relaxed |

**Shoe silhouettes:**
| Option | SVG | Engine value |
|--------|-----|-------------|
| Structured | Sharp rectangular, derby/loafer shape | .structured |
| Balanced | Medium rounded, versatile shoe shape | .balanced |
| Relaxed | Chunky rounded, sneaker shape | .relaxed |

### Color Picker — 8 Swatches

| Color swatch | rawColor | baseGroup | temperature |
|-------------|----------|-----------|-------------|
| Black | "Black" | .neutral | .neutral |
| Charcoal | "Charcoal" | .neutral | .cool |
| Navy | "Navy" | .deep | .cool |
| Brown | "Brown" | .deep | .warm |
| Olive | "Olive" | .deep | .warm |
| White | "White" | .light | .neutral |
| Cream | "Cream" | .light | .warm |
| Burgundy | "Burgundy" | .accent | .warm |

8 swatches. 34pt diameter circles, 8pt gap.
Color name shown on hover/long-press (8pt label below swatch).
Selected state: textOnDark border + slight scale-up (1.15×) + accent shadow.
Mapping to baseGroup + temperature is automatic and invisible to user.

Full wardrobe-add (after onboarding) uses 10 swatches: adds Light Gray (.light/.cool) and Rust (.accent/.warm).

### Implicit Fields (per item)

- category: set by flow position (.top, .bottom, .shoes)
- archetypeTag: defaults to user's primary archetype
- usageCount: 0
- customColorOverride: false
- imagePath: empty (placeholder silhouette used)

### Rules

- Both silhouette and color must be selected per item to mark as "done"
- Step visually transitions from incomplete → complete state on both selections
- CTA "Analyser garderoben →" enabled only when all 3 items are done
- Screen scrolls vertically — all 3 steps visible
- No image capture in onboarding (added later from Wardrobe tab)

---

## Screen 4 — AHA: Structural Identity

The identity reveal moment. Separate from the score.
This is where the user sees their wardrobe reduced to a structural fingerprint.

```
    ┌─────────────────────────────────────┐
    │  9:43              CORET        ●●● │
    │  ● ● ● ● ○                         │
    │                                     │
    │                                     │
    │                                     │
    │                                     │
    │            ┌───────┐                │
    │            │  ◆◆◆  │                │  ← structural icon (accent circle)
    │            └───────┘                │
    │                                     │
    │        DIN NÅVÆRENDE STRUKTUR       │
    │                                     │
    │        Tailored · Deep-Toned · Cool │
    │                                     │
    │                                     │
    │  ┌─────────────────────────────────┐│
    │  │  Din base group dominerer 66%   ││
    │  │  av garderoben.                 ││
    │  │  Silhuett-alignment er høy.     ││
    │  └─────────────────────────────────┘│
    │                                     │
    │  Presisjonen øker når flere plagg   │
    │  legges til.                        │
    │                                     │
    │                                     │
    │  ┌─────────────────────────────────┐│
    │  │  Se din første analyse →        ││
    │  └─────────────────────────────────┘│
    └─────────────────────────────────────┘
```

### Elements

1. **Structural icon** (centered, 72pt accent circle with layered diamond SVG)
   - Subtle, abstract, not decorative
   - Animates in: fadeInUp, 500ms

2. **Label**: "DIN NÅVÆRENDE STRUKTUR" (uppercase, 11pt, letter-spacing 3px, textMuted)
   - Animates in: fadeInUp, delay 150ms

3. **Identity string** (centered, prominent)
   - Format: `[Archetype] · [BaseGroup display] · [Temperature]`
   - Example: "Tailored · Deep-Toned · Cool"
   - DM Serif Display, 26pt, textOnDark
   - Dots in accent color
   - Animates in: fadeInUp, delay 300ms

   **BaseGroup Display Labels:**
   | Engine value | User sees |
   |-------------|-----------|
   | .neutral | Neutral |
   | .deep | Deep-Toned |
   | .light | Light |
   | .accent | Accent |

   Identity is derived from the 3 items via `structuralIdentity(items:)`:
   - Archetype: user's primary archetype display label
   - BaseGroup: plurality of items' baseGroup → display label
   - Temperature: plurality of items' temperature

4. **Micro-insight** (semi-transparent card, centered)
   - Deterministic observation derived from engine data
   - Animates in: fadeInUp, delay 450ms

   Possible micro-insights (rule-based selection, first match wins):
   - If one baseGroup dominates (≥ 66%): "Din base group dominerer [X]% av garderoben."
   - If all silhouettes match: "Silhuetten din er fullt [silhouette]. Konsistent."
   - If temperature is mixed: "Paletten din spenner over varmt og kaldt. Rom for å stramme."
   - If all items match primary archetype: "Full alignment med din [archetype]-retning."
   - Default: "3 plagg kartlagt. Struktur kommer med mer data."

5. **Precision note** (13pt, textMuted, italic, below insight card)
   - "Presisjonen øker når flere plagg legges til."
   - Always shown. Manages expectations from only 3 items.
   - Animates in: fadeInUp, delay 600ms

6. **CTA**: "Se din første analyse →" (accent button)

### Animations

All elements use staggered fadeInUp (opacity 0→1, translateY 14px→0):
- Icon: 0ms delay
- Label: 150ms
- Identity string: 300ms
- Insight card: 450ms
- Precision note: 600ms
- Duration: 500ms each, ease curve

This screen should feel like a revelation, not a report.

---

## Screen 5 — First State (Curated)

The first quantified view. Score + identity + one optimize insight.
NOT the full dashboard — curated to avoid overwhelming.

```
    ┌─────────────────────────────────────┐
    │  9:43              CORET        ●●● │
    │  ● ● ● ● ●                         │
    │                                     │
    │                                     │
    │                                     │
    │            COHESION                 │
    │                                     │
    │              62                     │  ← 72pt, DM Serif Display
    │                                     │
    │          ┌──────────┐               │
    │          │Structuring│              │  ← accent pill
    │          └──────────┘               │
    │                                     │
    │   Tailored · Deep-Toned · Cool      │
    │                                     │
    │                                     │
    │  ┌─────────────────────────────────┐│
    │  │  ＋  Strukturert ytterplagg     ││
    │  │      i nøytral base             ││
    │  │      Density +18 · Cohesion +9  ││
    │  └─────────────────────────────────┘│
    │                                     │
    │                                     │
    │  ┌─────────────────────────────────┐│
    │  │  Gå til Dashboard →             ││
    │  └─────────────────────────────────┘│
    └─────────────────────────────────────┘
```

### Elements

1. **Label**: "COHESION" (uppercase, 11pt, letter-spacing 3px, textMuted)

2. **Score** (centered, large)
   - 72pt, DM Serif Display, textOnDark
   - Count-up animation from 0

3. **Status pill** (centered, below score)
   - Status label from CohesionEngine (e.g. "Structuring")
   - Accent text on accent-tinted background, rounded pill shape
   - 14pt, semibold

4. **Identity string** (centered, smaller than AHA screen)
   - 17pt, medium weight, textOnDark
   - Same format: `[Archetype] · [BaseGroup] · [Temperature]`
   - Dots in accent color

5. **Optimize preview card** (full-width)
   - Left: dashed-border icon with + SVG (48×48pt)
   - Right: primary recommendation text + projected impact
   - From OptimizeEngine.optimize() — shows weakest area fix
   - Impact shown as: "Density +18 · Cohesion +9"
   - Accent color for impact numbers

6. **CTA**: "Gå til Dashboard →" (accent button, full width)

### What Happens Behind the Scenes

After Screen 3 "Analyser garderoben →" is tapped, before Screen 4 renders:

1. 3 WardrobeItems created (top, bottom, shoes)
2. UserProfile created (primary + secondary archetype, season defaults to springSummer)
3. CohesionEngine.compute() runs
4. StructuralIdentity derived
5. OptimizeEngine.optimize() runs (for First State recommendation)
6. First CohesionSnapshot stored
7. Micro-insight selected by rule
8. Screen 4 (AHA) displays identity
9. Screen 5 (First State) displays score + optimize insight

All synchronous. No loading spinner needed for 3 items.

### Rules

- Score IS shown on First State (curated view, not full breakdown)
- No component breakdown (that's Dashboard territory)
- No 2×2 component grid — only total score
- One optimize insight only (primary recommendation)
- This screen builds on the AHA moment with quantified evidence
- Calm, centered, spacious layout

---

## Transition to Dashboard

After "Gå til Dashboard →":
- Tab bar appears (5 tabs)
- Dashboard tab is active
- Dashboard shows full cohesion score + component breakdown (2×2 grid)
- Optimize shows full recommendations + friction
- Wardrobe shows the 3 items (with placeholder silhouettes, no photos)
- Evolution shows Foundation phase

The user is now in the full app with functioning data.
The jump from curated First State to full Dashboard should feel like expanding into the system.

---

## Edge Cases

### All 3 items identical structure
Identity shows the single dominant pattern. Micro-insight:
"Garderoben din er strukturelt uniform. Variasjon gir tetthet."

### Mixed temperature (warm + cool in 3 items)
Temperature shows "Neutral" (tie-break). Micro-insight:
"Paletten din spenner over varmt og kaldt. Rom for å stramme."

### User goes back during quick-add
Back navigation allowed between all screens. All selections preserved.

### Optimize has no recommendation (rare, edge case)
If OptimizeEngine returns no primary candidate (theoretically possible with perfect 100 score),
First State omits the optimize card. Only score + identity shown.

---

## Visual System

- Background: Warm Dark Taupe (#2F2A26) for all screens
- Cards: Semi-transparent dark (rgba(231,226,218,0.04-0.06)) with subtle borders
- Complete/selected state: Accent-tinted (rgba(47,74,60,0.08-0.22))
- Accent: Muted Forest (#2F4A3C) for buttons, selections, impact numbers
- Archetype cards: 20pt radius, semi-transparent dark background
- Color swatches: 34pt diameter circles, 8pt gap
- Selected state: accent border + checkmark on archetype cards, border + scale on swatches
- Progress dots: 5 dots, 3px height, flex, 6px gap
  - Done: accent fill
  - Current: textOnDark fill
  - Future: 10% textOnDark
- Transitions: 200ms ease-in-out, fade + slight vertical movement
- AHA screen: staggered fadeInUp animations (150ms intervals)
- Score: count-up animation (300ms, ease-in-out)

---

## Archetype Description Language

Descriptions must feel structural, not lifestyle:

| Archetype | DO say | DON'T say |
|-----------|--------|-----------|
| Tailored | "Clean lines, definerte former, presis passform. Intensjonell." | "Elegant and sophisticated style for the modern professional." |
| Smart Casual | "Mellom formelt og avslappet. Kontrollert, men uanstrengt." | "The perfect balance for work-to-weekend versatility." |
| Street | "Komfort først. Myke former, avslappet passform. Ledig." | "Urban vibes for the streetwear enthusiast." |

Structural language. Not lifestyle. Not aspirational. Not gendered.

---

## What This Wireframe Does NOT Cover

- Image capture (added later in Wardrobe tab)
- Account creation / authentication (out of scope for V1 wireframe)
- Outerwear addition (user adds from Wardrobe tab after onboarding)
- Season detection (defaults to springSummer, adjusted in Profile)
- Tutorial or walkthrough (CORET should be self-evident)

---

## HTML Reference

`coret_onboarding_v3.html` is the visual reference implementation.
This wireframe is the spec. Where they differ, this wireframe is authoritative.

### v3 HTML Deviations (Accepted)

| Aspect | Wireframe | HTML v3 | Status |
|--------|-----------|---------|--------|
| Font | SF Pro (iOS) | DM Sans/DM Serif (web) | Accepted — web substitute |
| Language | Mixed NO/EN | Primarily Norwegian | Accepted — final language TBD |
| Interactivity | Static spec | Static mockup (no JS) | Accepted |
