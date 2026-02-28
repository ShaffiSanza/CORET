# CORET – Continue
Last updated: 2026-02-28

## Completed Recently
- [x] Engine–UI coverage audit: tab-by-tab wireframe → engine cross-check
- [x] removalImpact() — per-component before/after scores for delete warning UI (6 tests)
- [x] snapshotAnchors() — weighted anchor selection for evolution timeline silhouettes (8 tests)
- [x] SwiftData spec updated with frozen snapshot fields (AnchorItemData, identityString, momentumDescriptor)
- [x] Cross-system consistency audit (test counts, type docs, worst-case test)
- [x] All wireframe tabs verified against engine API — 0 remaining engine gaps

## Build Status
swift build: pass
swift test: 180/180 passing

## Engine Status (All Complete + Audited + UI-Verified)
| Engine | File | Tests | Status |
|--------|------|-------|--------|
| CohesionEngine | `Engines/CohesionEngine.swift` | 85 | ✅ |
| OptimizeEngine | `Engines/OptimizeEngine.swift` | 19 | ✅ |
| SeasonalEngine | `Engines/SeasonalEngine.swift` | 19 | ✅ |
| EvolutionEngine | `Engines/EvolutionEngine.swift` | 56 | ✅ |
| Scaffold | `COREEngineTests.swift` | 1 | ✅ |

## In Progress
Nothing interrupted. Engine layer is complete, audited, and verified against all wireframes.

## Next Session Prompt
```
All four CORET engines are complete and UI-verified (180/180 tests passing on Linux). Read CLAUDE.md for the full system reference.

The engine layer is finished — every wireframe UI element has been traced to an engine function or documented as ViewModel responsibility. Remaining work requires a Mac:

1. SwiftUI iOS app in `ios_app/` consuming the COREEngine package
   - See CLAUDE.md Section 8 (Information Architecture) for all screens
   - See CLAUDE.md Section 9 (UI Specification) for design tokens
   - See wireframes in `moodboard/` for each tab
   - 5-tab layout: Dashboard, Wardrobe, Optimize, Evolution, Profile
   - SwiftData persistence wrapping engine types (Section 15)
   - ViewModel + EngineCoordinator architecture (Section 16)

ViewModel-layer items confirmed as NOT engine (implement in ViewModel):
- Component descriptors (score → "Strong"/"Optimal" mapping)
- StructuralIdentity display strings (nil → "Balanced" fallback)
- Color swatch → baseGroup/temperature lookup table
- Wardrobe filtering/sorting
- Optimize weakness explanation text (4 static strings)
- Onboarding micro-insight rules (5 rules, first-match)

If on Linux, possible next steps:
- Build HTML mockups for remaining tabs (Dashboard, Optimize, Profile)
- Expand archetype system (more archetypes, more conflict pairs)
- Refine wireframes or UI spec details
```

## Decisions Made
- CohesionWeights and SeasonalRecommendation types live in SeasonalEngine.swift (not Models/)
- EvolutionPhase, EvolutionTrend, EvolutionSnapshot types live in EvolutionEngine.swift (not Models/)
- CohesionEngine's original compute() delegates to weighted overload with SeasonalEngine.baseWeights
- Volatility uses population standard deviation (÷N, not ÷(N-1))
- WeaknessArea and CohesionComponent kept separate (different domain concepts)
- ItemContribution/ContributionContext are NOT Codable (runtime-only, associated values)
- outfitBuilder scores all combinations without filtering (spectrum, not binary)
- removalImpact lives in CohesionEngine (structural measurement, not optimization)
- snapshotAnchors lives in EvolutionEngine (per-snapshot selection, distinct from cross-snapshot anchorItems)
- Snapshot anchor data denormalized into EvolutionSnapshotEntity (not soft-delete) for deleted item rendering
