# CORET – Optimize Engine V1

## Overview

Optimize Engine identifies structural weaknesses and simulates improvements.

It prioritizes forward structural strengthening over removal.

---

## Core Logic

1. Compute current Cohesion Snapshot.
2. Identify weakest component:
   - Density
   - Alignment
   - Palette
   - Rotation

3. Generate structural candidates dynamically:
   - Missing category roles
   - Silhouette imbalance correction
   - Palette correction (neutral/deep increase)
   - Archetype reinforcement

4. For each candidate:
   - Simulate adding hypothetical item
   - Recompute Cohesion
   - Calculate:
     - Component improvement
     - Total improvement

5. Rank candidates by component improvement.

6. Return:
   - 1 Primary candidate
   - Up to 2 Secondary candidates

---

## Impact Display

Primary focus:
Improvement in weakest component.

Secondary:
Total structural impact.

Example:

Density: 52 → 64 (+12)
Total: 74 → 78 (+4)

---

## Remove Logic

Removal simulation runs internally.

Removal suggestion only shown if:
- Impact is significant (> +8 total)
- Labeled as "Structural Friction"

---

## Update Model

Optimize recalculates when:
- Item added
- Item removed
- Archetype changed
- Structural adjustment made
- Season recalibration applied

Not continuously during UI rendering.