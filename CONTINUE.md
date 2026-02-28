# CORET – Continue
Last updated: 2026-02-28

## Completed Recently
- [x] structuralIdentity(), momentum(), anchorItems() added to engines
- [x] itemContributions() — per-item contribution scoring (hybrid: direct + delta simulation)
- [x] outfitBuilder() — scored outfit generation with alignment/palette/silhouette sub-scores
- [x] Wireframes: dashboard, wardrobe, optimize, evolution, profile, onboarding (all in `moodboard/`)
- [x] Cross-system consistency audit:
  - Fixed stale test counts across CLAUDE.md
  - Documented WeaknessArea vs CohesionComponent separation
  - Documented ItemContribution/ContributionContext Codable exception
  - Documented outfitBuilder vs densityScore validation difference
  - Added outfitBuilderWorstCaseAllComponentsLow test

## Build Status
swift build: pass
swift test: 166/166 passing

## Engine Status (All Complete + Audited)
| Engine | File | Tests | Status |
|--------|------|-------|--------|
| CohesionEngine | `Engines/CohesionEngine.swift` | 79 | ✅ |
| OptimizeEngine | `Engines/OptimizeEngine.swift` | 19 | ✅ |
| SeasonalEngine | `Engines/SeasonalEngine.swift` | 19 | ✅ |
| EvolutionEngine | `Engines/EvolutionEngine.swift` | 48 | ✅ |
| Scaffold | `COREEngineTests.swift` | 1 | ✅ |

## In Progress
Nothing interrupted. Engine layer is complete and audited.

## Next Session Prompt
```
All four CORET engines are complete and audited (166/166 tests passing on Linux). Read CLAUDE.md for the full system reference.

The engine layer is finished. Remaining work requires a Mac:

1. SwiftUI iOS app in `ios_app/` consuming the COREEngine package
   - See CLAUDE.md Section 8 (Information Architecture) for all screens
   - See CLAUDE.md Section 9 (UI Specification) for design tokens
   - See wireframes in `moodboard/` for each tab
   - 5-tab layout: Dashboard, Wardrobe, Optimize, Evolution, Profile
   - SwiftData persistence wrapping engine types (Section 15)
   - ViewModel + EngineCoordinator architecture (Section 16)

If on Linux, possible next steps:
- Expand archetype system (more archetypes, more conflict pairs)
- Add more edge case tests
- Refine wireframes or UI spec details
- Plan SwiftData model layer (can design without building)
```

## Decisions Made
- CohesionWeights and SeasonalRecommendation types live in SeasonalEngine.swift (not Models/)
- EvolutionPhase, EvolutionTrend, EvolutionSnapshot types live in EvolutionEngine.swift (not Models/)
- CohesionEngine's original compute() delegates to weighted overload with SeasonalEngine.baseWeights
- Volatility uses population standard deviation (÷N, not ÷(N-1))
- WeaknessArea and CohesionComponent kept separate (different domain concepts)
- ItemContribution/ContributionContext are NOT Codable (runtime-only, associated values)
- outfitBuilder scores all combinations without filtering (spectrum, not binary)
