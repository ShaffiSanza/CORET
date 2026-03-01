# CORET – Continue
Last updated: 2026-03-01

## Completed Recently
- [x] Engine → UI Mapping Specification (`docs/engine_ui_mapping_v1.md`, 21 sections, 893 lines)
  - Council overrides applied: unified CohesionStatus descriptors, outfit-first wardrobe, Claude AI locked values
  - Score presentation with opacity-by-status (0.6→1.0), accent color for Aligned/Architected
  - All 10 enum display label tables, color swatch lookups, identity string composition
  - Temperature-driven outfit card backgrounds, removal impact tiers, progressive depth triggers
  - Full engine→screen matrix (28 functions × 6 screens) + recompute trigger summary
- [x] All four engines complete and audited (180/180 tests)
- [x] All wireframe tabs verified against engine API — 0 remaining engine gaps

## Build Status
swift build: pass
swift test: 180/180 passing

## Engine Status (All Complete)
| Engine | File | Tests | Status |
|--------|------|-------|--------|
| CohesionEngine | `Engines/CohesionEngine.swift` | 85 | ✅ |
| OptimizeEngine | `Engines/OptimizeEngine.swift` | 19 | ✅ |
| SeasonalEngine | `Engines/SeasonalEngine.swift` | 19 | ✅ |
| EvolutionEngine | `Engines/EvolutionEngine.swift` | 56 | ✅ |
| Scaffold | `COREEngineTests.swift` | 1 | ✅ |

## Documentation Status
| Doc | File | Status |
|-----|------|--------|
| Engine → UI Mapping | `docs/engine_ui_mapping_v1.md` | ✅ Authoritative (21 sections) |
| SwiftData Persistence | `docs/swiftdata_model_spec_v1.md` | ✅ Spec complete |
| ViewModel Architecture | `docs/viewmodel_architecture_v1.md` | ✅ Spec complete |
| UI Specification | `docs/ui_specification_v1.md` | ✅ Spec complete |
| All wireframes | `moodboard/*/` | ✅ Complete (6 tabs) |

## In Progress
Nothing interrupted. Engine layer and UI mapping spec are complete.

## Next Session Prompt
```
All four CORET engines are complete (180/180 tests on Linux). The engine → UI mapping spec is done (docs/engine_ui_mapping_v1.md — 21 sections). Read CLAUDE.md for the full system reference.

The engine + spec layer is finished. Every engine function is mapped to every screen. Every enum has display labels. Every edge case has defined behavior. Council overrides are applied.

Remaining work requires a Mac:

1. SwiftUI iOS app in `ios_app/` consuming the COREEngine package
   - See CLAUDE.md Section 8 (Information Architecture) for all screens
   - See CLAUDE.md Section 9 (UI Specification) for design tokens
   - See docs/engine_ui_mapping_v1.md for engine → UI mapping rules
   - See wireframes in `moodboard/` for each tab
   - 5-tab layout: Dashboard, Wardrobe, Optimize, Evolution, Profile
   - SwiftData persistence wrapping engine types (CLAUDE.md Section 15)
   - ViewModel + EngineCoordinator architecture (CLAUDE.md Section 16)

Key council overrides to honor:
- Component descriptors use CohesionStatus scale (Aligned/Architected, NOT Strong/Optimal)
- Wardrobe tab is outfit-first (outfitBuilder() drives grid, not items)
- nil silhouette/baseGroup → "Mixed" (not "Balanced"/"Neutral")
- Score opacity by status: 0.6 (Structuring) → 1.0 (Aligned/Architected)
- Outfit card backgrounds: temperature-driven color system

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
- Component descriptors unified to CohesionStatus scale (Council Override 1, 1 March 2026)
- Wardrobe is outfit-first, outfitBuilder() drives grid (Council Override 2, 28 February 2026)
- nil fallback is "Mixed"/"Blandet", not "Balanced"/"Neutral" (Council Override 3, 1 March 2026)
- BaseGroup display labels unified to evolution wireframe versions: Deep-Toned, Light-Toned, Accent-Driven
