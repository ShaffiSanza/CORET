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
- [x] **Image Pipeline — Design finalized** (decided, not yet implemented)

## Build Status

```
core-v2: swift build pass, swift test 244/244 passing
core (V1): swift build pass, swift test 218/218 passing (archived)
ios_app/: NOT compilable on Linux — requires Mac + Xcode + Apple SDK
backend/: NOT yet created
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

## Image Pipeline — Final Design

### Architecture: iOS (Swift) + Backend (Python/FastAPI on Railway)

```
Telefon (Swift)                    Server (Python/FastAPI)
┌──────────────────────┐           ┌─────────────────────────┐
│ Kamera / UI          │           │ POST /api/product-search│
│ Guided Capture       │──HTTP────▶│ POST /api/barcode-lookup│
│ Subject Lifting      │◀─────────│ POST /api/image-polish  │
│ SwiftData            │           │                         │
└──────────────────────┘           │ API keys: SerpAPI,      │
                                   │ UPCitemdb, Photoroom    │
                                   └─────────────────────────┘
                                   Hosted: Railway (free tier)
```

### Pipeline Flow (2 steps + Pro upgrade):

```
Legg til plagg
  │
  ├─ Steg 1: PRODUCT LOOKUP (via Python backend)
  │   Innganger (kombinert i én tjeneste):
  │     • Skann strekkode → barcode-lookup → studiobilde
  │     • Skriv merke + modell → product-search → studiobilde
  │   → Hent studiobilde → plassér på #231C18 → ferdig ✓
  │
  ├─ Steg 2: GUIDED CAPTURE (on-device fallback)
  │   Når product lookup ikke finner noe:
  │     • Guidet kamera med overlay (flat-lay, belysning, framing)
  │     • Vision framework subject lifting (VNGenerateForegroundInstanceMaskRequest)
  │     • Core Image composit på #231C18
  │   → ferdig ✓
  │
  └─ Steg 3: API POLISH (Pro-funksjon, valgfri)
      Forbedrer steg 2-resultat via backend:
        • POST /api/image-polish → Photoroom API → polert bilde
        • Kun for Pro-brukere
      → erstatt lokalt bilde → ferdig ✓
```

### Key decisions:
- Raw user photos break CORET's premium aesthetic — pipeline is necessary
- Product images first (steg 1) because 90%+ of branded garments have studio photos
- Guided Capture (steg 2) as fallback for vintage/thrift/unknown brands
- API polish (steg 3) deferred to Pro tier — enhances steg 2 results
- All processed images placed on #231C18 (CORET card surface) for visual consistency
- **Python backend** chosen over Cloudflare Workers — user has Python experience, $0 cost difference
- Backend hosted on **Railway** (free tier, no cold starts)
- Barcode scan and text search combined into one Product Lookup service (not separate tiers)

### Backend implementation (Python):

```
backend/
  main.py                  ← FastAPI app (3 endpoints)
  requirements.txt         ← fastapi, uvicorn, httpx
  .env                     ← API keys (SerpAPI, UPCitemdb, Photoroom)
```

Endpoints:
- `POST /api/product-search` — text query → SerpAPI → best studio image URL
- `POST /api/barcode-lookup` — barcode string → UPCitemdb → product image URL
- `POST /api/image-polish` — upload image → Photoroom API → polished image (Pro only)

### iOS implementation (Swift):

```
ios_app/
  Services/
    ImagePipeline.swift          ← Orchestrator (steg 1 → 2 → 3)
    ProductLookupService.swift   ← HTTP calls to Python backend
    GuidedCaptureService.swift   ← AVFoundation camera + overlay
    SubjectLiftingService.swift  ← Vision framework wrapper
    ImagePolishService.swift     ← HTTP call to backend /image-polish (Pro)
```

## What Python Backend Changes

Adding a Python backend is a **new architectural component**. This affects:

1. **Project structure** — New `backend/` directory at project root
2. **No longer purely local-first** — Steg 1 (product lookup) requires network. Steg 2 (guided capture) remains fully offline as fallback.
3. **Development unblocked on Linux** — Backend can be built and tested NOW on Arch Linux without Mac. This is a major unlock.
4. **CLAUDE.md** — Needs update: add `backend/` to project structure, note Python/FastAPI conventions
5. **Deployment** — Railway deployment config needed (Procfile or railway.toml)
6. **Offline strategy** — App must gracefully handle no-network: skip steg 1, go straight to steg 2 (guided capture). Product lookup is enhancement, not requirement.

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
- **Image pipeline**: 2-step + Pro. Product Lookup (backend) → Guided Capture (on-device) → API Polish (Pro/backend).
- **Python backend**: FastAPI on Railway, chosen over Cloudflare Workers for developer familiarity.
- **Barcode + text search combined**: Single Product Lookup service, multiple input methods.
- **Offline strategy**: No network → skip steg 1, go directly to steg 2 (guided capture). Pipeline never blocks on network.

## Next Session Prompt

```
CORET — resuming. Read CLAUDE.md, then CONTINUE.md.

Pass 3 complete: ios_app/ has persistence + EngineCoordinator + 5 ViewModels.
V2 engine: core-v2/ (244/244 tests). V1 archived.

Image pipeline is fully designed (see CONTINUE.md "Image Pipeline — Final Design").
Architecture: iOS (Swift) + Python backend (FastAPI on Railway).

Next priority — Build Python backend (CAN be done on Linux now!):
1. Create backend/ directory with FastAPI project
2. Implement POST /api/product-search (SerpAPI integration)
3. Implement POST /api/barcode-lookup (UPCitemdb integration)
4. Implement POST /api/image-polish (Photoroom API proxy, Pro only)
5. Add tests for all endpoints
6. Railway deployment config

After backend, remaining work:
- iOS image pipeline services (ios_app/Services/) — requires Mac
- SwiftUI Views for all 5 tabs — requires Mac
- Xcode project setup — requires Mac
- Update CLAUDE.md with backend/ in project structure

Optional work on Linux:
- HTML moodboard updates
- Engine refinements
- Additional spec documentation
```
