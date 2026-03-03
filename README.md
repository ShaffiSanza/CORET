# CORET — Wardrobe Operating System

> "Your Wardrobe Operating System. Built Around Your Core."

CORET measures structural cohesion in a wardrobe and guides optimization. It is **not** a fashion app, shopping platform, or budgeting tool — it is a deterministic, rule-based structural system.

---

## What It Does

- **Measures** wardrobe cohesion across 6 structural dimensions (layer coverage, proportion balance, combination density, etc.)
- **Optimizes** by detecting structural gaps and suggesting concrete additions
- **Tracks** a structural journey over time with phases, milestones, and momentum
- **Recalibrates** weights seasonally based on location

---

## Build Status

| Package | Tests | Status |
|---------|-------|--------|
| `core-v2/` — V2 engine (active) | 244/244 | ✅ All passing |
| `core/` — V1 engine (archived) | 218/218 | ✅ All passing |

```bash
cd core-v2 && swift build && swift test
cd core    && swift build && swift test
```

Requires Swift 6.2+. No external dependencies.

---

## Repository Structure

```
CORET/
├── core/           V1 engine — archived, stable (218 tests)
├── core-v2/        V2 engine — active, complete (244 tests)
│   └── Sources/COREEngine/
│       ├── Models/     Garment, Scoring, Identity
│       ├── Engines/    8 engines (see below)
│       └── Helpers/    ScoringHelpers (internal)
├── ios_app/        iOS layer — written, not yet compiled (requires Mac)
│   ├── Persistence/    6 SwiftData @Model entities
│   ├── Coordinators/   EngineCoordinator (engine ↔ persistence bridge)
│   └── ViewModels/     5 @Observable ViewModels (one per tab)
├── docs/
│   ├── ENGINE_SPECS.md     ← Full technical specs for all engines + IA + UI
│   ├── swiftdata_model_spec_v1.md
│   └── viewmodel_architecture_v1.md
└── moodboard/      HTML mockups + wireframes for all 5 tabs
```

---

## V2 Engine — Complete

| Engine | Purpose | Tests |
|--------|---------|-------|
| `CohesionEngine` | 6-component structural score | 70 |
| `ClarityEngine` | Top-level aggregation (archetype + cohesion) | 23 |
| `ScoreProjector` | What-if: simulate adding/removing a garment | 22 |
| `IdentityResolver` | Structural identity → label, tags, prose | 15 |
| `KeyGarmentResolver` | Per-garment combination analysis | 13 |
| `MilestoneTracker` | Journey phases, milestones, momentum | 38 |
| `SeasonalEngineV2` | 4-season coverage + weight adjustment | 26 |
| `OptimizeEngineV2` | Gap detection + concrete suggestions | 19 |

Full formula and algorithm detail: [`docs/ENGINE_SPECS.md`](docs/ENGINE_SPECS.md)

---

## V2 Cohesion Formula

```
ClarityScore = primaryArchetypeScore × 0.60 + cohesionTotal × 0.40 + breadthBonus (max +5)

CohesionTotal = LayerCoverage(0.25) + ProportionBalance(0.20) + ThirdPiece(0.15)
              + CapsuleRatios(0.15) + CombinationDensity(0.15) + StandaloneQuality(0.10)
```

Deterministic. No ML. All component scores are individually callable and explainable.

---

## iOS Layer — Written, Not Yet Compiled

The `ios_app/` directory contains production-ready Swift files that require **Mac + Xcode** to compile (SwiftData and Observation are Apple-platform-only).

**Written (Pass 3):**
- `GarmentEntity`, `UserProfileEntity`, `ClaritySnapshotEntity`, `MilestoneEntity`, `SavedOutfitEntity`, `EngineCacheEntity` — SwiftData persistence
- `EngineCoordinator` — bridges SwiftData ↔ V2 engines, handles recompute, snapshots, milestones
- `DashboardViewModel`, `WardrobeViewModel`, `OptimizeViewModel`, `EvolutionViewModel`, `ProfileViewModel` — `@MainActor @Observable`

**Not yet written (Pass 4 — requires Mac):**
- SwiftUI views for all 5 tabs
- `COREApp.swift` entry point
- Xcode project setup (add `ios_app/` files, import `core-v2/` as local package)

---

## What's Left

| Task | Blocker |
|------|---------|
| Compile + test `ios_app/` | Mac + Xcode |
| SwiftUI views (5 tabs) | Mac + Xcode |
| Xcode project setup | Mac |
| SwiftData persistence testing | Mac |
| TestFlight / App Store | Mac |

**On Linux (no blocker):** engine refinements, moodboard updates, documentation.

---

## Architecture Principle

> Engine-first. UI is replaceable. Engine is not.

```
SwiftUI Views
     ↓
ViewModels (@Observable)
     ↓
EngineCoordinator
     ↓              ↓
V2 Engines     SwiftData
(core-v2/)     (ios_app/Persistence/)
```

ViewModels never call engines directly — only through `EngineCoordinator`.

---

## Design System

- **Background**: `#2F2A26` — warm dark taupe
- **Cards**: `#E7E2DA` — light stone
- **Accent**: `#2F4A3C` — deep muted forest green
- **Font**: SF Pro (system). No decorative fonts.
- **Tone**: Calm. Architectural. Non-preachy. Norwegian band names (Krystallklar, Fokusert…).

Full UI spec: [`docs/ENGINE_SPECS.md §9`](docs/ENGINE_SPECS.md)

---

## Key Files to Read

| File | What it covers |
|------|---------------|
| `docs/ENGINE_SPECS.md` | All engine specs, IA, UI, brand, monetization |
| `docs/OPPORTUNITIES_UPGRADES.md` | Product + business opportunities mapped (ML, onboarding, B2B) |
| `CLAUDE.md` | Project rules + conventions (for AI-assisted sessions) |
| `CONTINUE.md` | Session state — what was last done, what's next |
| `moodboard/*/` | HTML mockups for each tab (open in browser) |
