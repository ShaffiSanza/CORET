# CORET – Information Architecture V1

## Purpose

Information Architecture defines:
- All V1 screens
- Navigation hierarchy
- Screen responsibilities
- User actions per screen
- Structural priority order

This document defines structure only.
No visual styling. No animations. No implementation details.

---

## Navigation Model

CORET V1 uses a 5-tab bottom navigation structure.

Primary Tabs:
1. Dashboard
2. Wardrobe
3. Optimize
4. Evolution
5. Profile

Navigation is flat at root level.
Each tab may contain internal stack navigation.
No hidden navigation. No hamburger menu. No gamified shortcuts.

---

## Screen Definitions

### Dashboard (Home)

Purpose: Provide structural overview.

Displays:
- Total Cohesion Score
- Cohesion Status label
- Component breakdown (Alignment, Density, Palette, Rotation)
- Seasonal state (if active)
- Current Evolution Phase
- Primary Optimize recommendation (collapsed preview)

User Actions:
- Tap component → open Component Detail
- Tap Optimize suggestion → open Optimize tab
- Tap Evolution phase → open Evolution tab
- Pull to refresh (recompute engine snapshot)

Priority: This is the structural command center.

---

### Component Detail Screen

Accessed from Dashboard.

Displays:
- Component score
- Explanation of what affects it
- Top structural contributors
- Top structural weaknesses

User Actions:
- View items affecting component
- Navigate to Optimize suggestions relevant to this component

No editing here. Informational only.

---

### Wardrobe

Purpose: Manage structural inputs.

Displays:
- Grid or list of items
- Filters by: Category, Archetype, Silhouette, BaseGroup, Season relevance

User Actions:
- Add Item
- Edit Item
- Delete Item
- View Item Detail

---

### Add / Edit Item Screen

Fields:
- Category (required)
- Silhouette (required)
- BaseGroup (required)
- Temperature
- ArchetypeTag
- UsageCount (auto-incremented normally)

Validation:
- Category required
- Silhouette required
- BaseGroup required

On Save:
- Recompute Cohesion
- Trigger Optimize recompute

---

### Item Detail

Displays:
- Full item metadata
- Structural contribution impact
- Usage count
- Alignment match type

User Actions:
- Edit
- Delete

Deletion Warning: "Removing this item will reduce Density by X."

---

### Optimize

Purpose: Future structural improvement.

Displays:
- Primary structural candidate
- Component impact
- Total projected impact
- Two secondary candidates

User Actions:
- View structural explanation
- Mark as Acquired
- Dismiss suggestion
- Re-run simulation manually

Optimize is simulation-based only. Does not auto-add items.

---

### Evolution

Purpose: Long-term structural maturity tracking.

Displays:
- Current Evolution Phase
- Narrative explanation
- Stability window status
- Historical monthly snapshots (list format)

No graphs in V1.

User Actions:
- View past snapshot details

No manual editing.

---

### Profile

Purpose: System configuration.

Displays:
- Primary Archetype
- Secondary Archetype
- Location (for SeasonalEngine)
- Season mode (Suggested / Auto)
- Reset profile

User Actions:
- Edit archetypes
- Change location
- Toggle season mode
- Reset system

Reset requires confirmation.

---

## Navigation Flow

App Launch → Dashboard

From Dashboard:
- Component → Component Detail
- Optimize preview → Optimize
- Evolution badge → Evolution

Wardrobe is independent tab.
Optimize is independent tab.
No circular dependencies.

---

## Screen Hierarchy

Level 0: Dashboard, Wardrobe, Optimize, Evolution, Profile
Level 1: Component Detail, Item Detail, Add/Edit Item

No Level 2 complexity in V1.

---

## State Update Rules

Full engine recompute triggered by:
- Item added
- Item deleted
- Item edited (structural fields)
- Archetype changed
- Seasonal recalibration applied

Dashboard always reflects latest snapshot.

---

## Data Ownership

Wardrobe owns: WardrobeItems
Profile owns: Archetypes, Location, SeasonMode
Engine owns: CohesionSnapshot, OptimizeResult, EvolutionSnapshot

UI never modifies engine directly.
UI triggers events.
Engine recalculates deterministically.

---

## Edge Cases

### Empty Wardrobe
Dashboard shows: "System not yet structured."
Optimize disabled.

### Single Category Dominance
Wardrobe screen displays structural imbalance warning.

### Low Data History
Evolution screen displays: "Structural history forming."

---

## Non-Goals V1
- No social sharing
- No shopping integration
- No budgeting tools
- No gamification
- No outfit generator screen

Outfit-level logic is V2.

---

## Summary

CORET V1 IA is flat, structural, controlled.
Engine-first. No feature clutter. No engagement mechanics.
It reflects system clarity.
