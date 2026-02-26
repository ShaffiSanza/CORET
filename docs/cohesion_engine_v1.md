# CORET – Cohesion Engine V1

## Overview

Cohesion measures structural integrity of a wardrobe relative to the selected archetype direction.

Score Range: 0–100  
Displayed as hybrid: Status + Numeric score

---

# Cohesion Formula

Total Cohesion Score =

(Alignment × 0.35) +
(Density × 0.30) +
(Palette Control × 0.20) +
(Rotation Balance × 0.15)

Each component returns a value between 0–100.

---

# 1️⃣ Archetype Alignment (35%)

Each item has one archetype tag.

User profile has:
- Primary archetype
- Secondary archetype

Item Scoring:

Primary match = 1.0  
Secondary match = 0.7  
Neutral = 0.5  
Conflict = 0.2  

Alignment Score =
Average(item_alignment_values) × 100

---

# 2️⃣ Combination Density (30%)

Definition:
Number of valid outfits ÷ Total theoretical outfits

A valid outfit requires:
- 1 Top
- 1 Bottom
- 1 Shoes
- Optional 1 Outerwear

Validation Rules:

## Archetype Compatibility
All items must not conflict with primary direction.

## Silhouette Balance

Structured = +1  
Balanced = 0  
Relaxed = -1  

Outfit sum must be between -2 and +2.

Outfits ≤ -3 or ≥ +3 are invalid.

## Color Rules

Each item stores:
- Base Group (Neutral / Deep / Light / Accent)
- Temperature (Warm / Cool / Neutral)

Valid outfit if:
- Max 1 Accent
- At least 1 Neutral
- No strong Warm + Cool clash
- Monochrome always allowed

Density Score =
(valid_outfits / total_possible_outfits) × 100

---

# 3️⃣ Palette Control (20%)

Measured by:

- Percentage of Neutral/Deep items
- Number of Accent items
- Temperature spread

Optimal Structure:

60–80% Neutral/Deep  
0–20% Accent  
Limited temperature variance

Penalty applied for over-diversification.

---

# 4️⃣ Rotation Balance (15%)

Measured by relative usage per category.

Within each category:

Calculate usage deviation from mean.

Lower deviation = higher score.

Rotation Score = 100 - normalized_deviation

---

# Status Levels

0–49 → Structuring  
50–64 → Refining  
65–79 → Coherent  
80–89 → Aligned  
90–100 → Architected

---

# Design Principle

- Deterministic
- Transparent on breakdown
- Not easily gamed
- Stable over time