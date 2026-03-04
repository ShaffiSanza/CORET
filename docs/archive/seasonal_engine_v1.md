> SUPERSEDED – This document describes the original specification.
> The actual implementation differs. See CLAUDE.md section 6 for current truth.

# CORET – SeasonalEngine V1

## Purpose

SeasonalEngine adjusts structural weighting and optimization context based on climatic season.

It does NOT:
- Delete wardrobe items
- Permanently alter base scoring logic
- Force user action

It temporarily shifts structural emphasis.

---

## Season Detection

### Input
- UserProfile.location (country + optional latitude)
- Current date

### Hemisphere Rule
- If latitude >= 0 → Northern Hemisphere
- If latitude < 0 → Southern Hemisphere
- If latitude unavailable → fallback to country mapping
- If country unknown → default Northern

### Season Windows (Deterministic)

Northern Hemisphere:
- Spring/Summer: March 1 – August 31
- Autumn/Winter: September 1 – February 28

Southern Hemisphere inverted.

No weather API in V1.
No dynamic temperature sampling.
Deterministic calendar-based.

---

## Recalibration Trigger Logic

SeasonalEngine runs daily at app launch.

If currentSeason != profile.seasonMode → RecalibrationSuggested = true

User sees: "Seasonal recalibration available."

---

## Recalibration Modes

### Mode A: Suggested (default)
User chooses: Apply or Keep current structure.
No forced recalibration.

### Mode B: Auto (optional setting, off by default)
Automatically applies new season weighting.

---

## What Changes During Recalibration

### Component Weight Adjustment (Temporary)

Base weights:
- Alignment: 0.35
- Density: 0.30
- Palette: 0.20
- Rotation: 0.15

### Autumn/Winter Adjustments
- Outerwear density weight +10%
- Silhouette rigidity tolerance reduced (more structure allowed)
- Dark palette weighting tolerance widened

Effect:
- Density calculation multiplies outerwear combinations by seasonalFactor = 1.1
- Palette neutral/deep bias slightly increased

### Spring/Summer Adjustments
- Outerwear weight reduced
- Light palette tolerance increased
- Accent tolerance slightly widened (but still max 1 per outfit)
- Silhouette looseness tolerance slightly widened

---

## Cohesion Impact Model

SeasonalEngine does NOT rewrite CohesionEngine.

It injects a temporary modifier:

adjustedComponent = baseComponent * seasonalModifier

Applied ONLY to:
- Density component
- Palette component

Alignment and Rotation remain unchanged.

### Example
- Base Density = 52
- Autumn modifier = 1.08
- Adjusted Density = 52 × 1.08 = 56.16
- Total recomputed accordingly

---

## Modifier Format

seasonalModifier is always a factor:
- 1.08 = increase 8%
- 0.95 = reduction 5%
- 1.00 = no effect

Never direct additive (+8 points).
Multiplicative adjustment locked as standard for V1.

### Why multiplicative:
1. Scales proportionally with existing score
2. Avoids artificial inflation at low values
3. Keeps system consistent across all levels
4. Deterministic and mathematically clean

---

## Roadmap Regeneration

If recalibration applied:
- OptimizeEngine recomputes targets
- Active targets archived
- New seasonal targets generated
- Archived targets remain visible in Evolution log

---

## Edge Cases

### Edge Case 1 – Minimal Wardrobe
If wardrobe.count < 6: recalibration disabled.
System too unstable for seasonal weight shift.

### Edge Case 2 – Archetype Locked Minimalism
If archetype = structuredMinimal and palette already deep-dominant:
Winter recalibration only adjusts outerwear weight. Palette unchanged.

### Edge Case 3 – User switches location mid-season
If location changed: recompute season immediately, trigger recalibration suggestion.

### Edge Case 4 – User rejects recalibration repeatedly
System does not re-prompt for 30 days.
Cooldown timer stored in profile.

---

## Data Model Additions

Add to UserProfile:
- var latitude: Double?
- var longitude: Double?
- var recalibrationCooldownUntil: Date?

Add to CohesionSnapshot:
- var seasonAdjusted: Bool

---

## Determinism Guarantee

SeasonalEngine must:
- Produce identical result for identical date + location
- Never introduce randomness
- Never permanently modify wardrobe data

---

## Summary

SeasonalEngine is a contextual weighting layer.
Not a structural rewrite. Not cosmetic.
It adjusts emphasis, not identity.
