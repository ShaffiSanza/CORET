# Moodboard — Optimize Tab Wireframe

Simulation-based structural recommendations.
Diagnose → Recommend → Simulate. Never auto-add.

```
┌─────────────────────────────────────┐
│ Optimize                            │
│                                     │
│ ┌─────────────────────────────────┐ │
│ │  Weakest Structure              │ │
│ │                                 │ │
│ │  Density                    52  │ │
│ │  ████████████░░░░░░░░░░░░░░░░░ │ │
│ │                                 │ │
│ │  "Your outfit combinations are  │ │
│ │   limited. Strengthen density   │ │
│ │   to unlock more structure."    │ │
│ └─────────────────────────────────┘ │
│                                     │
│  Primary Recommendation             │
│ ┌─────────────────────────────────┐ │
│ │  ┌─────┐                        │ │
│ │  │     │  Balanced Top          │ │
│ │  │ IMG │  TOPS · Neutral        │ │
│ │  │     │  Smart Casual          │ │
│ │  └─────┘                        │ │
│ │                                 │ │
│ │  Density    52 → 64      +12   │ │
│ │  ░░░░░░░░░░░░████░░░░░░░░░░░░ │ │
│ │                                 │ │
│ │  Total      74 → 78       +4   │ │
│ │  ████████████████░░░░░░░░░░░░░ │ │
│ │                                 │ │
│ │  [ Add to Wardrobe ]  [ Dismiss ]│ │
│ └─────────────────────────────────┘ │
│                                     │
│  Also Consider                      │
│ ┌─────────────────────────────────┐ │
│ │  Relaxed Bottom · Neutral       │ │
│ │  Density +8  ·  Total +3    ›  │ │
│ ├─────────────────────────────────┤ │
│ │  Balanced Outerwear · Deep      │ │
│ │  Density +5  ·  Total +2    ›  │ │
│ └─────────────────────────────────┘ │
│                                     │
│  Structural Friction                │
│ ┌─────────────────────────────────┐ │
│ │  ┌─────┐                        │ │
│ │  │     │  Oversized Parka       │ │
│ │  │ IMG │  OUTERWEAR             │ │
│ │  │     │  Relaxed Street        │ │
│ │  └─────┘                        │ │
│ │                                 │ │
│ │  Removing improves Total by +9  │ │
│ │                                 │ │
│ │          [ Review Impact ]      │ │
│ └─────────────────────────────────┘ │
│                                     │
└─────────────────────────────────────┘
```

## Weakest Area Card

```
┌─────────────────────────────────┐
│  Weakest Structure              │  ← h3, textPrimary
│                                 │
│  Component Name             52  │  ← h2 score, accent color
│  ██████████░░░░░░░░░░░░░░░░░░░ │  ← Thin progress bar
│                                 │
│  Structural explanation text    │  ← body, textSecondary
│  (1-2 lines, diagnostic tone)  │
└─────────────────────────────────┘
```

## Primary Recommendation Card

```
┌─────────────────────────────────┐
│  ┌─────┐                        │
│  │ IMG │  Candidate name        │  ← h3 (or placeholder if virtual)
│  │     │  CATEGORY · BaseGroup  │  ← caption, textMuted
│  └─────┘  Archetype tag         │  ← tag style
│                                 │
│  Component   before → after  +N │  ← Improvement highlight (accent)
│  ░░░░░░░░░░░████░░░░░░░░░░░░░ │  ← Before/after progress bar
│                                 │
│  Total       before → after  +N │
│  ████████████████░░░░░░░░░░░░░ │
│                                 │
│  [ Add to Wardrobe ]  [ Dismiss ]│  ← accent button + ghost button
└─────────────────────────────────┘

"Add to Wardrobe" flow:
  User taps → Add Item Sheet (pre-filled with structural role)
  User adds their real item image + confirms
  → Engine recomputes. Candidate resolved.

"Dismiss" flow:
  Candidate removed. Secondary promoted if available.
  Next recompute generates fresh candidates.
```

## Secondary Recommendations (Collapsed)

```
┌─────────────────────────────────┐
│  Candidate description          │  ← Single line summary
│  Component +N  ·  Total +N   › │  ← Impact preview + chevron
├─────────────────────────────────┤
│  Candidate description          │
│  Component +N  ·  Total +N   › │
└─────────────────────────────────┘

Tap → expands to full card (same as primary).
Max 2 secondary candidates.
```

## Structural Friction Section

```
Only shown when items have impact > +8 on removal.

┌─────────────────────────────────┐
│  ┌─────┐                        │
│  │ IMG │  Item name             │  ← Existing wardrobe item
│  │     │  CATEGORY              │
│  └─────┘  Archetype             │
│                                 │
│  Removing improves Total by +N  │  ← destructive color (#7A3E3E)
│                                 │
│          [ Review Impact ]      │  ← Ghost button, not destructive
└─────────────────────────────────┘

"Review Impact" → push to Item Detail Screen
  with friction context shown.
  User decides. CORET measures, never forces.
```

## Empty / Edge States

```
Empty wardrobe:
  "Add items to your wardrobe to unlock structural optimization."
  [ Go to Wardrobe ]

Already optimized (no improvement > 0):
  "Your structure is strong. No immediate optimizations detected."

Missing categories (no valid outfits):
  "Add tops, bottoms, and shoes to enable density optimization."
```

## Design Notes

- All cards: stone background (#E7E2DA), 18-22pt radius
- Screen background: warm dark taupe (#2F2A26)
- Progress bars: thin horizontal, accent fill (#2F4A3C)
- Friction uses destructive color (#7A3E3E) for impact text only
- "Review Impact" is neutral — not a delete button
- Simulation only. Optimize never modifies wardrobe directly.
- Candidates are structural templates, not real items
