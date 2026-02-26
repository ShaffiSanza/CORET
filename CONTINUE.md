# CORET – Continue
Last updated: 2026-02-26

## Completed This Session
- [x] CLAUDE.md rewritten as complete self-contained system reference (16 sections)
- [x] All docs/ files read and consolidated into CLAUDE.md
- [x] SeasonalEngine fully specified (latitude detection, multiplicative modifiers, hemisphere rules, edge cases)
- [x] StructuralEvolution fully specified (5 phases, volatility, regression, snapshots, narratives)
- [x] Information Architecture fully specified (3-tab layout, all screens, navigation flows, data ownership)
- [x] UI Specification fully specified (color tokens, typography scale, spacing system, animations, layout patterns)

## Build Status
swift build: pass
swift test: 48/48 passing (29 CohesionEngine + 19 OptimizeEngine)

## In Progress (if interrupted)
Nothing interrupted.

## Next Session Prompt
```
Build the SeasonalEngine and EvolutionEngine for CORET. Read CLAUDE.md — it contains the complete system specification. Everything you need is in that one file.

Build order:

1. Implement `core/Sources/COREEngine/Engines/SeasonalEngine.swift`
   - See CLAUDE.md Section 6 for full spec
   - New types: CohesionWeights, SeasonalRecommendation
   - Season detection from latitude + month
   - Weight modifiers: springSummer (A×0.95, D×0.85, P×1.15, R×1.15), autumnWinter (A×1.10, D×1.15, P×0.85, R×0.95)
   - Renormalize after multiplication
   - Equatorial edge case (|lat| < 15°): return nil / shouldRecalibrate = false

2. Add `compute(items:profile:weights:)` overload to CohesionEngine
   - Same logic as existing compute, but uses provided CohesionWeights instead of hardcoded 0.35/0.30/0.20/0.15
   - Existing compute() unchanged (backwards compatible)

3. Create `core/Tests/COREEngineTests/SeasonalEngineTests.swift`
   - Test latitude → season detection (northern, southern, equatorial)
   - Test weight modifiers sum to 1.0 after normalization
   - Test recalibration recommendation (same season = false, different = true)
   - Test edge cases (equatorial, invalid month)
   - Test compute with seasonal weights produces different scores than base weights

4. Implement `core/Sources/COREEngine/Engines/EvolutionEngine.swift`
   - See CLAUDE.md Section 7 for full spec
   - New types: EvolutionPhase, EvolutionTrend, EvolutionSnapshot
   - Phase determination from snapshot history (Foundation → Developing → Refining → Cohering → Evolving)
   - Volatility = stddev of last 5 totalScores
   - Trend = last 3 snapshots monotonic direction
   - Regression if score drops >15 or volatility >15

5. Create `core/Tests/COREEngineTests/EvolutionEngineTests.swift`
   - Test each phase threshold
   - Test phase progression
   - Test regression triggers
   - Test volatility calculation
   - Test trend detection (improving, stable, declining)
   - Test edge cases (0 snapshots, 1 snapshot, identical scores)

6. Verify: cd core && swift build && swift test — all green
7. Update CLAUDE.md build status and CONTINUE.md
8. git add -A && git commit -m "feat: seasonal + evolution engines"
```

## Decisions Made
- CLAUDE.md is now the single source of truth — a new session needs only this file
- SeasonalEngine spec: multiplicative modifiers, renormalized to sum=1.0
- Hemisphere threshold: |latitude| >= 15° for auto-detection, < 15° is equatorial
- EvolutionEngine spec: 5 phases with minimum snapshot counts, score thresholds, and volatility caps
- Volatility = stddev of last 5 snapshots (not all snapshots)
- Regression threshold: >15 score drop or >15 volatility
- UI spec uses warm tones throughout — no pure black, no pure white
- Information architecture: 3-tab bar (Wardrobe, Optimize, Profile)
