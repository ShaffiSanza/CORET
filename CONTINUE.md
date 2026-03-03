# CORET – Continue
Last updated: 2026-03-03

## Completed This Session

- [x] **CLAUDE.md split**: ENGINE_SPECS.md written (`docs/ENGINE_SPECS.md`, all §3–28 detail). CLAUDE.md slimmed to ~4k (identity, project structure, build status, blocker, conventions, session protocol).
- [x] **Pass 3 — Persistence layer** (6 SwiftData entities in `ios_app/Persistence/`):
  - `GarmentEntity.swift` — V2 Garment as primitives + `toGarment()` / `from()` / `apply()`
  - `UserProfileEntity.swift` — singleton, V2 UserProfile fields
  - `ClaritySnapshotEntity.swift` — immutable JSON blob + `shouldPersist()` policy
  - `MilestoneEntity.swift` — journey milestone record
  - `SavedOutfitEntity.swift` — user-pinned outfits (garment ID list + saved score)
  - `EngineCacheEntity.swift` — optional performance cache (clarity + gaps as JSON)
  - `SwiftDataStack.swift` — ModelContainer factory + preview container
- [x] **Pass 3 — Coordinator** (`ios_app/Coordinators/EngineCoordinator.swift`):
  - Full CRUD: addGarment, removeGarment, updateGarment
  - Profile mutations: updateArchetype, updateLocation, applyRecalibration, resetProfile
  - What-if simulation: projectAdding, projectRemoving (no persistence side effects)
  - Snapshot persistence policy: delta > 5 or first-of-month
  - Milestone deduplication and persistence
  - Key garment flag sync after each recompute
  - Concurrency: Task.detached for heavy computation, results delivered on MainActor
- [x] **Pass 3 — ViewModels** (5 files in `ios_app/ViewModels/`):
  - `DashboardViewModel.swift` — clarity, gaps, identity, journey, seasonal coverage
  - `WardrobeViewModel.swift` — garment grid + filter + CRUD + removal warning
  - `OptimizeViewModel.swift` — gap selection, suggestion actions (acquire/dismiss)
  - `EvolutionViewModel.swift` — read-only journey timeline, milestones, history
  - `ProfileViewModel.swift` — archetype, location, seasonal recalibration, reset

## Build Status

```
core-v2: swift build pass, swift test 244/244 passing
core (V1): swift build pass, swift test 218/218 passing (archived)
ios_app/: NOT compilable on Linux — requires Mac + Xcode + Apple SDK
```

## V2 iOS Layer Status

| Component | File | Status |
|-----------|------|--------|
| SwiftData stack | `Persistence/SwiftDataStack.swift` | ✅ Written |
| GarmentEntity | `Persistence/GarmentEntity.swift` | ✅ Written |
| UserProfileEntity | `Persistence/UserProfileEntity.swift` | ✅ Written |
| ClaritySnapshotEntity | `Persistence/ClaritySnapshotEntity.swift` | ✅ Written |
| MilestoneEntity | `Persistence/MilestoneEntity.swift` | ✅ Written |
| SavedOutfitEntity | `Persistence/SavedOutfitEntity.swift` | ✅ Written |
| EngineCacheEntity | `Persistence/EngineCacheEntity.swift` | ✅ Written |
| EngineCoordinator | `Coordinators/EngineCoordinator.swift` | ✅ Written |
| DashboardViewModel | `ViewModels/DashboardViewModel.swift` | ✅ Written |
| WardrobeViewModel | `ViewModels/WardrobeViewModel.swift` | ✅ Written |
| OptimizeViewModel | `ViewModels/OptimizeViewModel.swift` | ✅ Written |
| EvolutionViewModel | `ViewModels/EvolutionViewModel.swift` | ✅ Written |
| ProfileViewModel | `ViewModels/ProfileViewModel.swift` | ✅ Written |
| SwiftUI Views | — | ⛔ Requires Mac |

## In Progress — Image Pipeline Design (Decided, Not Yet Implemented)

Discussed and decided on a **hybrid image pipeline** for garment photos:

### Strategy (Tier System):
1. **Tier 1 — Product image search** (preferred): User enters brand + model → search web for official studio photo (Diesel.com, Zalando, etc.). Free, perfect quality, no privacy concern.
2. **Tier 2 — On-device cleanup** (fallback): iOS 16+ subject lifting (Core Image) → remove background → place on CORET dark surface (#231C18). Free, private, offline.
3. **Tier 3 — AI studio enhancement** (V1.5 Pro): Server-side processing (Photoroom/Remove.bg style). Pay-per-image. Optional premium feature.

### Key decisions:
- Raw user photos break CORET's premium aesthetic — pipeline is necessary
- Product images first because 90%+ of branded garments have studio photos online
- On-device cleanup as fallback for vintage/unknown brands
- AI enhancement deferred to V1.5 as paid Pro feature
- All processed images placed on #231C18 (CORET card surface) for visual consistency

### Implementation needed:
- `ImportSource` enum (`.productSearch`, `.photoLibrary`, `.camera`)
- Image pipeline service in ios_app/
- Subject lifting integration (Vision framework)
- Product image search integration

## Decisions Made This Session

- **CLAUDE.md split**: ENGINE_SPECS.md gets all §3–28 detail. CLAUDE.md keeps only identity, structure overview, build status, blocker, conventions, session protocol.
- **ClaritySnapshotEntity**: JSON blob (not individual fields) — ClaritySnapshot is Codable, simpler schema, future-proof.
- **GapResult not persisted**: Derived from current garments, not historical. Only ClaritySnapshot history is stored.
- **SavedOutfitEntity**: Stores garment IDs + score at save time. Garment IDs reference live entities; EngineCoordinator rescores on demand.
- **EngineCoordinator as ObservableObject (not @Observable)**: Uses `@Published`-equivalent pattern via SwiftData + explicit sync calls from ViewModels. ViewModels call `sync()` after recompute.
- **ViewModels use @Observable** (Swift 6 native Observation), not ObservableObject.
- **isKeyGarment flag**: Updated on GarmentEntity by EngineCoordinator after each recompute using KeyGarmentResolver.keyGarmentIDs().
- **Snapshot trigger**: delta > 5.0 OR first-of-month. First snapshot always persisted.
- **Milestone deduplication**: key = type.rawValue + "-" + snapshotIndex.

## Next Session Prompt

```
CORET Pass 3 is complete in ios_app/ (persistence + EngineCoordinator + 5 ViewModels).

V2 engine: core-v2/ (244/244 tests). V1 archived: core/ (218/218 tests).
ios_app/ requires Mac + Xcode to compile (SwiftData, Observation, COREEngine import).

Read CLAUDE.md for slim reference. Read docs/ENGINE_SPECS.md for engine detail.
Read CONTINUE.md "In Progress" section for image pipeline design decisions.

Next priority — Image Pipeline:
- Implement ImportSource enum and image pipeline service
- Hybrid strategy: product image search → on-device cleanup → AI enhancement (V1.5)
- See CONTINUE.md for full tier breakdown and decisions

Remaining work requires Mac:
- SwiftUI Views for all 5 tabs (Dashboard, Wardrobe, Optimize, Evolution, Profile)
- Xcode project setup: add ios_app/ files, import core-v2/ as local package
- On-Mac compilation and testing of ios_app/ layer
- COREApp.swift entry point (SwiftUI App + .modelContainer)

Optional work possible on Linux:
- HTML moodboard updates
- Engine refinements
- Additional spec documentation
```
