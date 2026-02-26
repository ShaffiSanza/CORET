# CORET – Continue
Last updated: 2026-02-26

## Completed This Session
- [x] OptimizeEngine implemented (`core/Sources/COREEngine/Engines/OptimizeEngine.swift`)
  - Result types: WeaknessArea, OptimizeRecommendation, StructuralFriction, OptimizeResult
  - Weakest component identification from CohesionSnapshot
  - Dynamic candidate generation per weakness type (alignment, density, palette, rotation)
  - Hypothetical item simulation via CohesionEngine recomputation
  - Candidate ranking by component improvement (1 primary + up to 2 secondary)
  - Structural friction detection (removal simulation, >8 total improvement threshold)
- [x] OptimizeEngine tests (`core/Tests/COREEngineTests/OptimizeEngineTests.swift`)
  - 19 tests: weakness identification, candidate generation, friction detection, ranking, edge cases
- [x] CLAUDE.md updated with OptimizeEngine status

## Build Status
swift build: pass
swift test: 48/48 passing (29 CohesionEngine + 19 OptimizeEngine)

## In Progress (if interrupted)
Nothing interrupted. Both engines are fully complete and tested.

## Next Session Prompt
```
Implement the SwiftUI iOS app for CORET. Read CLAUDE.md for full context — specifically the "Product Spec (V1)" section and Brand Foundation. The COREEngine package (core/) contains both CohesionEngine and OptimizeEngine, fully tested.

Set up the iOS app in `ios_app/`:

1. Create Xcode project structure in `ios_app/` as a SwiftUI app
   - Add COREEngine as a local package dependency (path: ../core)
   - Target iOS 17+
   - App name: CORET

2. Implement core screens:
   - **Wardrobe View**: Grid layout of items, structural status at top, add item flow
   - **Cohesion Score View**: Hybrid display (status label primary, 0-100 secondary), breakdown on tap
   - **Optimize View**: Show primary recommendation with impact display, secondary recommendations

3. Implement data layer:
   - SwiftData models wrapping COREEngine types
   - Local persistence

4. Apply brand visual identity:
   - Warm dark taupe background
   - Light stone cards
   - Deep muted forest green accent
   - CORET uppercase spaced typography
   - Soft animations 200-300ms ease-in-out

5. Verify: app builds and runs in simulator
```

## Decisions Made
- OptimizeEngine uses same caseless enum pattern as CohesionEngine (no state, all static)
- Result types (WeaknessArea, OptimizeRecommendation, StructuralFriction, OptimizeResult) defined in the engine file since they're tightly coupled
- All result structs are Identifiable, Codable, Sendable per project conventions
- WeaknessArea is also CaseIterable per enum convention
- Candidate generation is weakness-focused: alignment generates primary/secondary archetype items, density varies silhouettes, palette targets neutral/deep, rotation adds to each category
- Candidates use dominant temperature of existing wardrobe for best palette compatibility
- Friction threshold is strictly >8 total improvement (not >=8)
- Single-item wardrobes correctly return no density recommendations (adding 1 item can't form outfits when 2+ required categories are missing)
