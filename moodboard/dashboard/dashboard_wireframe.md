# CORET — Dashboard Tab Wireframe (V1)

## Design Intent

Dashboard is the system state screen.
It shows where the wardrobe stands structurally — not how it looks visually.

This is not a feed. Not a gallery. Not an outfit generator.
It is the operating system home screen.

Primary purpose: Communicate structural state with maximum clarity.
Design principle: CORET is a system that handles clothes, not a fashion app that has numbers.

---

## Screen Structure

```
    ┌─────────────────────────────────────┐
    │  9:41              CORET        ●●● │
    │                                     │
    │  Good Morning.                      │
    │  Your structure is Coherent.        │
    │                                     │
    │           COHESION                  │
    │                                     │
    │             72                      │  ← 72pt score
    │                                     │
    │         Coherent                    │  ← status label
    │  ████████████████████░░░░░░░░       │  ← progress bar
    │                                     │
    │  ┌────────────┐ ┌────────────┐      │
    │  │ Alignment  │ │  Density   │      │
    │  │    78      │ │    64      │      │
    │  │  Aligned   │ │  Refining  │      │
    │  ├────────────┤ ├────────────┤      │
    │  │  Palette   │ │  Rotation  │      │
    │  │    71      │ │    85      │      │
    │  │  Coherent  │ │   Strong   │      │
    │  └────────────┘ └────────────┘      │
    │                                     │
    │  ┌─────────────────────────────────┐│
    │  │  ☀ Outfit preview               ││
    │  │  (static flat lay, 2-4 items)   ││
    │  └─────────────────────────────────┘│
    │                                     │
    │  ┌─────────────────────────────────┐│
    │  │  Optimize                       ││
    │  │  Strukturert ytterplagg         ││
    │  │  Density +18         View →     ││
    │  └─────────────────────────────────┘│
    │                                     │
    │  ┌─────────────────────────────────┐│
    │  │  Refining                       ││
    │  │  Refining structural cohesion.  ││
    │  └─────────────────────────────────┘│
    │                                     │
    │  ┌───┬───┬───┬───┬───┐             │
    │  │ ● │ ◻ │ ◻ │ ◻ │ ◻ │  ← Dashb.  │
    │  └───┴───┴───┴───┴───┘             │
    └─────────────────────────────────────┘
```

---

## Element 1 — Greeting Line

```
┌─────────────────────────────────────┐
│  Good Morning.                      │
│  Your structure is Coherent.        │
└─────────────────────────────────────┘
```

- Small, calm, top of screen
- Time-based greeting: "Good Morning" / "Good Afternoon" / "Good Evening"
- Status pulled from latest CohesionSnapshot: "Your structure is [status]."
- Typography: body (16pt), textSecondary
- NOT a headline. NOT prominent. Context-setting only.

### Greeting Time Ranges

| Time | Greeting |
|------|----------|
| 05:00–11:59 | God morgen. |
| 12:00–17:59 | God ettermiddag. |
| 18:00–04:59 | God kveld. |

Second line: "Din struktur er [status]."

---

## Element 2 — Cohesion Score Block

The hero element. Center of the screen.

```
┌─────────────────────────────────────┐
│           COHESION                  │  ← label
│                                     │
│             72                      │  ← score
│                                     │
│          Coherent                   │  ← status
│  ████████████████████░░░░░░░░       │  ← progress bar
└─────────────────────────────────────┘
```

### Elements

1. **Label**: "COHESION" (11pt, uppercase, letter-spacing 3px, textMuted)
   - Centered above score

2. **Score**: Total cohesion score (0–100)
   - 72pt, bold (700), SF Pro Display, textOnDark
   - Centered
   - Count-up animation on load and refresh (300ms, ease-in-out)

3. **Status label**: CohesionStatus display name
   - 22pt, semibold (600), accent color
   - Centered below score

   | Engine status | Display label |
   |--------------|--------------|
   | .structuring | Structuring |
   | .refining | Refining |
   | .coherent | Coherent |
   | .aligned | Aligned |
   | .architected | Architected |

4. **Progress bar**: Horizontal, thin
   - Full width (within screen margins)
   - Height: 4pt
   - Fill: accent color (#2F4A3C), rounded caps
   - Track: divider color (#4A4440)
   - Fill percentage = totalScore / 100
   - NOT a circular ring. NOT a gauge. Simple horizontal bar.

---

## Element 3 — Component Grid (2x2)

The structural breakdown.

```
┌────────────────┐ ┌────────────────┐
│  Alignment     │ │  Density       │
│      78        │ │      64        │
│   Aligned      │ │   Refining     │
├────────────────┤ ├────────────────┤
│  Palette       │ │  Rotation      │
│      71        │ │      85        │
│  Coherent      │ │    Strong      │
└────────────────┘ └────────────────┘
```

### Card Anatomy

Each of the 4 cards:

```
┌────────────────┐
│  Alignment     │  ← component name (caption, 13pt, textMuted)
│                │
│      78        │  ← component score (h2, 24pt, medium, textPrimary)
│                │
│   Aligned      │  ← descriptor (caption, 13pt, textMuted)
└────────────────┘
```

- Background: stone (#E7E2DA)
- Corner radius: 18–22pt
- Internal padding: 16–20pt
- Cards feel embedded, not floating (minimal shadow, < 8% opacity)
- Grid gap: 12pt horizontal, 12pt vertical

### Component Descriptors

Each component score maps to a descriptor using the same thresholds as CohesionStatus:

| Score Range | Descriptor |
|-------------|-----------|
| 0–49 | Structuring |
| 50–64 | Refining |
| 65–79 | Coherent |
| 80–89 | Strong |
| 90–100 | Optimal |

Note: "Strong" and "Optimal" used for components instead of "Aligned"/"Architected" to differentiate from overall status.

### Tap Behavior

Tap any card → push to **Component Detail Screen**.

---

## Component Detail Screen (Push)

Accessed by tapping any component card on Dashboard.

```
    ┌─────────────────────────────────────┐
    │  ← Dashboard                        │
    │                                     │
    │  ALIGNMENT                          │
    │                                     │
    │             78                      │
    │          Aligned                    │
    │                                     │
    │  ┌─────────────────────────────────┐│
    │  │  Hva påvirker Alignment         ││
    │  │                                 ││
    │  │  Alignment måler hvor godt      ││
    │  │  plaggene matcher arketypen     ││
    │  │  din. Primær-match gir full     ││
    │  │  score. Konflikter trekker ned. ││
    │  └─────────────────────────────────┘│
    │                                     │
    │  ┌─────────────────────────────────┐│
    │  │  Sterkest bidrag                ││
    │  │                                 ││
    │  │  Navy Structured Top    Primary ││
    │  │  Black Balanced Bottom  Primary ││
    │  │  Charcoal Relaxed Shoes Neutral ││
    │  └─────────────────────────────────┘│
    │                                     │
    │  ┌─────────────────────────────────┐│
    │  │  Svakest bidrag                 ││
    │  │                                 ││
    │  │  Olive Relaxed Outerwear        ││
    │  │  Conflict (relaxedStreet)       ││
    │  └─────────────────────────────────┘│
    │                                     │
    │  ┌─────────────────────────────────┐│
    │  │  Se Optimize-forslag →          ││
    │  └─────────────────────────────────┘│
    │                                     │
    └─────────────────────────────────────┘
```

### Elements

1. **Component score + descriptor** (large, centered)
2. **Explanation card**: What this component measures (deterministic text, stone card)
3. **Top contributors**: Items that score highest for this component
   - Each row: item description + match type (Primary/Secondary/Neutral/Conflict)
4. **Top weaknesses**: Items that score lowest or conflict
   - Each row: item description + issue
5. **CTA**: "Se Optimize-forslag →" navigates to Optimize tab filtered to this component

### Component Explanations (Deterministic)

| Component | Explanation |
|-----------|------------|
| Alignment | Måler hvor godt plaggene matcher din arketype. Primær-match gir full score. Sekundær gir 70%. Konflikter trekker ned. |
| Density | Måler hvor mange strukturelt gyldige outfit-kombinasjoner garderoben din produserer. Flere kompatible plagg gir høyere score. |
| Palette | Måler fargebalansen. Ideelt: 60–80% nøytral/dyp base, maks 20% aksent, temperatur-konsistens (varmt ELLER kaldt). |
| Rotation | Måler bruksbalansen på tvers av kategorier. Jevn rotasjon gir høy score. Ujevnt bruk trekker ned. |

### Rules

- Informational only — no editing from this screen
- Contributors sorted by score impact (descending)
- Maximum 5 contributors shown per section
- Items link to Item Detail (push) if tapped

---

## Element 4 — Outfit Preview (Should Have)

```
┌─────────────────────────────────────┐
│  ┌─────────────────────────────────┐│
│  │                                 ││
│  │   ┌─────┐ ┌─────┐ ┌─────┐     ││
│  │   │ Top │ │Btm  │ │Shoes│     ││
│  │   └─────┘ └─────┘ └─────┘     ││
│  │                                 ││
│  │   En outfit fra din garderobe   ││
│  └─────────────────────────────────┘│
└─────────────────────────────────────┘
```

### Elements

- Stone card, full width
- Static flat lay: 2–4 items arranged horizontally
- Items shown as silhouette placeholders (until user adds photos)
- One outfit generated from CohesionEngine valid outfit combinations
- Caption: "En outfit fra din garderobe" (textMuted)

### Rules

- Static. Not animated. Not rotating. Not a carousel.
- Outfit is proof of structure, not main attraction
- Small. Subtle. Subordinate to score.
- If no valid outfit exists (missing category): card hidden
- Tap → no action (informational only in V1)

### Outfit Selection Logic

Pick the highest-scoring valid outfit:
1. Get all valid outfits from density calculation
2. Score each by archetype alignment average
3. Show top-scoring outfit
4. Deterministic: same items always produce same outfit

---

## Element 5 — Optimize Preview Card

```
┌─────────────────────────────────────┐
│  OPTIMIZE                           │  ← section label
│                                     │
│  Strukturert ytterplagg i           │  ← recommendation headline
│  nøytral base                       │
│                                     │
│  Density +18 · Cohesion +9          │  ← impact (accent)
│                                     │
│  Se Optimize →                      │  ← CTA (accent)
└─────────────────────────────────────┘
```

### Elements

- Stone card, full width
- Label: "OPTIMIZE" (11pt, uppercase, textMuted)
- Headline: Primary recommendation description from OptimizeEngine
  - Category + silhouette + baseGroup, plain language
  - Example: "Strukturert ytterplagg i nøytral base"
- Impact: weakest component improvement + total improvement
  - Accent color, 13pt, semibold
- CTA: "Se Optimize →" navigates to Optimize tab

### Rules

- Shows primary recommendation only (not secondary)
- Updated on every engine recompute
- If no recommendation (perfect score): "Ingen strukturelle forslag. Garderoben er optimalisert."
- Tap card (not just CTA) → Optimize tab

---

## Element 6 — Evolution Phase Card

```
┌─────────────────────────────────────┐
│  Refining                           │  ← phase name (h3)
│  Refining structural cohesion       │  ← narrative (caption, textMuted)
│  across all components.             │
└─────────────────────────────────────┘
```

### Elements

- Stone card, full width
- Phase name: EvolutionPhase display (h3, bold, textPrimary)
- Narrative: EvolutionSnapshot.narrative (caption, textMuted)
- No trend or volatility shown here (that's Evolution tab territory)

### Rules

- Tap → Evolution tab
- Single line narrative, not full evolution display
- Calm. Does not compete with score block.

---

## Pull to Refresh

Pulls down → triggers full engine recompute:
1. CohesionEngine.compute()
2. OptimizeEngine.optimize()
3. EvolutionEngine.evaluate()
4. Cache updated
5. All dashboard elements refresh
6. Score count-up animation replays

No spinner UI needed — computation is near-instant for reasonable item counts.

---

## Empty State

When wardrobe has 0 items (after profile reset or before onboarding):

```
    ┌─────────────────────────────────────┐
    │  9:41              CORET        ●●● │
    │                                     │
    │                                     │
    │                                     │
    │                                     │
    │     Systemet er ikke strukturert    │
    │     ennå.                           │
    │                                     │
    │     Legg til plagg i Wardrobe       │
    │     for å starte.                   │
    │                                     │
    │                                     │
    │                                     │
    └─────────────────────────────────────┘
```

- Centered text, textSecondary
- No score. No components. No optimize. No evolution.
- Directs to Wardrobe tab.

---

## Visual System

- Background: Warm Dark Taupe (#2F2A26)
- Component cards: Stone (#E7E2DA), 18–22pt radius
- Preview cards (outfit, optimize, evolution): Stone (#E7E2DA), 18–22pt radius
- Score: 72pt, textOnDark
- Progress bar: 4pt height, accent fill, rounded
- Component grid: 2×2, 12pt gap, equal-width columns
- Screen margin: 20pt
- Vertical spacing between sections: 24pt (lg)
- Cards feel embedded, not floating
- No circular rings. No gamification visuals.

### Scroll Behavior

Dashboard scrolls vertically. Content order top-to-bottom:
1. Greeting line
2. Cohesion score block
3. Component grid (2×2)
4. Outfit preview (should have)
5. Optimize preview card
6. Evolution phase card

All content visible without horizontal scrolling.

---

## Data Dependencies

Dashboard reads (never writes):
- `CohesionSnapshot` (latest) → score, status, component scores
- `EvolutionSnapshot` (latest) → phase, narrative
- `OptimizeResult` (latest) → primary recommendation
- `[WardrobeItem]` → outfit preview generation

All data sourced from EngineCoordinator cache.
Dashboard never calls engines directly.

---

## Layout Decisions — Locked

**Accepted:** 2×2 component grid with score hero above.
**Rejected:** Vertical column layout with rotating outfit center.
**Reason:** Wrong hierarchy. Fashion feel, not system feel.
Outfit is present but as evidence of structure, not as hero or attraction.
