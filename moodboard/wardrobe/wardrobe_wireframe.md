# Moodboard — Wardrobe Tab Wireframe

Inspired by DigiCo grid presentation style (gallery feel,
generous spacing, large image area) but with CORET structure.

```
┌─────────────────────────────────────┐
│ Wardrobe                        + 12│
│ ─────────────────────────────────── │
│ [All] [Tops] [Bottoms] [Outer][Shoe]│
│                                     │
│ ┌───────────────┐ ┌───────────────┐ │
│ │               │ │               │ │
│ │               │ │               │ │
│ │     [IMG]     │ │     [IMG]     │ │
│ │               │ │               │ │
│ │               │ │               │ │
│ │ Wool Jacket   │ │ Wide Trousers │ │
│ │ OUTERWEAR     │ │ BOTTOMS       │ │
│ │ Structured    │ │ Relaxed       │ │
│ └───────────────┘ └───────────────┘ │
│                                     │
│ ┌───────────────┐ ┌───────────────┐ │
│ │               │ │               │ │
│ │               │ │               │ │
│ │     [IMG]     │ │     [IMG]     │ │
│ │               │ │               │ │
│ │               │ │               │ │
│ │ White Shirt   │ │ Derby Shoes   │ │
│ │ TOPS          │ │ SHOES         │ │
│ │ Balanced      │ │ Structured    │ │
│ └───────────────┘ └───────────────┘ │
│                                     │
│           [ + Add Item ]            │
└─────────────────────────────────────┘
```

## Card Anatomy

```
┌───────────────┐
│               │
│   Item Image  │  ← Large area, neutralized background, uniform crop
│               │
│ Item Name     │  ← Body text (16pt, textPrimary)
│ CATEGORY      │  ← Caption muted (13pt, textMuted)
│ Silhouette    │  ← Tag style (12pt, textSecondary)
└───────────────┘
```

## Design Notes

- Large image area (gallery feel, not thumbnail)
- Stone card background (#E7E2DA)
- Name in body text, category in caption muted
- Silhouette tag at bottom of card
- Generous padding between cards (16pt gap)
- Screen background: warm dark taupe (#2F2A26)
- Filter bar uses chip/tag style (8pt radius)
- Item count shown top-right ("+ 12")
- FAB alternative: inline "Add Item" button at grid end
- NO prices, NO hearts, NO social elements
