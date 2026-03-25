# CORET — Project Reference

CORET is a wardrobe operating system. It measures structural cohesion and guides optimization. It is not a fashion app, shopping platform, or budgeting tool. It is a structural system.

Tagline: "Your Wardrobe Operating System."
Secondary: "Built Around Your Core."

Architectural Principle: CORET is engine-first, UI-second. UI is replaceable. Engine is not.

**Full engine specs, IA, UI, brand, monetization, and all section details: see [`docs/ENGINE_SPECS.md`](docs/ENGINE_SPECS.md)**

---

## 1. What CORET Is and Is Not

**Is:**
- A personal wardrobe operating system
- A structural measurement and optimization engine
- A deterministic, rule-based scoring system
- A long-term identity tool that evolves with the user

**Is not:**
- A fashion inspiration app
- A shopping platform or retail integration
- A budgeting tool
- A social network
- An ML/AI-powered recommendation engine (V1)

Philosophy: Control over validation. Structure over trend. Identity over status. Optimization over impulse. Measurement without judgment. Creative deviation allowed. CORET measures — the user decides.

---

## 2. Project Structure

```
CORET/
├── CLAUDE.md              ← You are here (slim reference)
├── CONTINUE.md            ← Session state for resuming
├── docs/
│   ├── ENGINE_SPECS.md    ← All engine specs, IA, UI, brand, monetization
│   ├── OPPORTUNITIES_UPGRADES.md
│   ├── strategy/          Feature roadmap
│   └── archive/           Superseded v1 specs (historical)
├── engine/                ← V2 Swift package: COREEngine (387/387 tests)
│   └── Sources/COREEngine/
│       ├── Models/        Garment.swift (incl. WearLog), Scoring.swift, Identity.swift
│       ├── Engines/       CohesionEngine, ClarityEngine, ScoreProjector,
│       │                  IdentityResolver, KeyGarmentResolver, MilestoneTracker,
│       │                  SeasonalEngineV2, OptimizeEngineV2,
│       │                  BehaviouralEngine, SimilarityEngine
│       └── Helpers/       ScoringHelpers.swift (internal)
├── ios/                   ← iOS frontend: SwiftUI + SwiftData (all views written)
│   ├── App/               CORETApp.swift, ContentView.swift (4-tab nav)
│   ├── Views/             WardrobeView, StudioView, DiscoverView, ProfileView, AddGarmentSheet, GarmentDetailSheet
│   ├── ViewModels/        4 @Observable ViewModels (one per tab)
│   ├── Persistence/       7 SwiftData @Model entities
│   ├── Coordinators/      EngineCoordinator.swift
│   ├── Design/            DesignSystem.swift (tokens, typography, glass card, theme)
│   └── Debug/             MockData.swift (18 real Shopify products for simulator)
├── backend/               ← Python/FastAPI backend (full wardrobe platform)
│   ├── models/            Enums, Pydantic schemas (garment, outfit, wear_log, wardrobe_map, clarity, discover, shopify, profile)
│   ├── services/          Business logic:
│   │                        garment_store, outfit_store, wear_log_store (JSON persistence)
│   │                        image_polish, image_normalize, image_storage (image pipeline)
│   │                        color_extraction, metadata_extractor, product_search, barcode_lookup
│   │                        wardrobe_analysis (combo engine, gap detection, key/weak garments)
│   │                        clarity_tracker (score history for Evolution)
│   │                        wardrobe_io (import validation)
│   │                        discover_feed (feed generation, bookmarks, actions, seen tracking)
│   │                        shopify_client (Shopify Admin API, pagination, rate limiting, style inference)
│   │                        shopify_oauth (OAuth flow, state+nonce+TTL, scope verification)
│   │                        ghost_catalog (brand registry, product sync, gap-to-product matching, brand grid)
│   │                        product_enricher (3-layer enrichment: defaults → heuristics → overrides)
│   │                        outfit_graph (outfit network analysis)
│   │                        security_logger (webhook HMAC, security event logging)
│   │                        user_profile (style_context + archetype, JSON persistence)
│   ├── routers/           pipeline.py, garments.py, wardrobe.py, outfits.py, wear.py, discover.py, brands.py, profile.py, auth.py
│   ├── tests/             pytest test suite (247 tests)
│   ├── data/              Runtime storage: garments.json, outfits.json, wear_logs.json, images/ (gitignored)
│   └── v1_5/              Archived services (receipt_parser) for future release
├── moodboard/             ← Visual references for UI (HTML + wireframe .md files)
└── archive/               ← V1 engine (core-v1, 218/218 tests, historical)
```

**IA:** 4 tabs: Wardrobe, Studio, Discover, Profile. Dashboard removed — Clarity in Wardrobe Bento hero. Evolution removed — Identity + Milestones in Profile tab. Floating nav with active circle + scale animation.

**Moodboard note — `digico_wardrobe_grid.png`:**
Reference ONLY for: 2-column grid layout and garment card presentation.
NOT reference for: prices, brand names, social features, shopping UI, lifestyle photography.

---

## 3. Build Status

| Package | Tests | Status |
|---------|-------|--------|
| engine/ (V2 — ACTIVE) | 387/387 | ✅ All passing |
| backend/ (Python/FastAPI) | 248/248 | ✅ All passing |
| archive/core-v1/ (V1 — ARCHIVED) | 218/218 | ✅ All passing |

**V2 engines:** CohesionEngine (70), ClarityEngine (23), ScoreProjector (22), IdentityResolver (15), KeyGarmentResolver (21), MilestoneTracker (38), SeasonalEngineV2 (26), OptimizeEngineV2 (19), BehaviouralEngine (27), SimilarityEngine (18), DailyOutfitScorer (9), BestOutfitFinder (8), NetworkUnlockCalculator (10), DailyOutfitEngine (13), StyleDirectionEngine (14), Models (18).

**Backend test breakdown:** health (3), color_extraction (21), image_polish (3), image_normalize (10), image_storage (5), product_search (3), barcode_lookup (3), metadata_extractor (4), wardrobe_io (13), garments CRUD (11), wardrobe_analysis (34), outfits (7), wear+clarity (10), discover (35), outfit_graph (8), shopify (25), shopify_oauth (21), security (10), style_context (20).

Build commands:
```
cd engine  && swift build && swift test
cd backend && source .venv/bin/activate && python -m pytest tests/ -v
```

---

## 4. Current Status and Build Order

All code written on both Arch Linux (engine + backend) and Mac (SwiftUI views). iOS views need Xcode build verification and simulator testing.

**iOS views written (need Xcode compilation):**
- CORETApp.swift — entry point + SwiftData container
- ContentView.swift — 4-tab floating nav with active circle animation
- WardrobeView.swift — Bento hero, stagger grid, press feedback, gold key borders
- StudioView.swift — flat lay slots, score pulse, edge-swipe drawer, primary/secondary CTA
- DiscoverView.swift — swipe rotation+opacity, missing piece above reason, haptics
- ProfileView.swift — tab 4, avatar 60pt, identity 26pt, elevated sections
- AddGarmentSheet.swift — form + live projection preview
- GarmentDetailSheet.swift — role analysis, removal simulation
- DesignSystem.swift — tokens, typography, glass card, text3Fixed contrast
- MockData.swift — 18 real Shopify products for simulator

**CRITICAL BUG — Railway deploy returns 500 on all authenticated endpoints:**

Status: UNRESOLVED
URL: https://coret-production.up.railway.app
Health endpoint works: `GET /api/health` → 200 OK
All other endpoints: 500 Internal Server Error

Root cause: `SecurityHeadersMiddleware` (BaseHTTPMiddleware) crashes when
`call_next()` raises an exception (HTTPException from APIKeyMiddleware).
Starlette BaseHTTPMiddleware has known issues with exception propagation.

Already tried (pushed, did not fix):
- fcntl graceful fallback (try/except import) — not the issue, Railway is Linux
- SecurityHeadersMiddleware try/except around call_next — did not resolve

Likely fix: Replace BaseHTTPMiddleware with pure ASGI middleware:
```python
# Instead of BaseHTTPMiddleware:
@app.middleware("http")
async def security_headers(request: Request, call_next):
    response = await call_next(request)
    response.headers["X-Content-Type-Options"] = "nosniff"
    ...
    return response
```
Or use Starlette's recommended pattern for middleware that doesn't need
to read request body.

Files to check: `backend/main.py` lines 121-135
Test after fix: `curl -H "X-API-Key: <key>" https://coret-production.up.railway.app/api/garments`

Security note: HTTPS is correctly enforced by Railway (HTTP → 301 redirect to HTTPS).
HSTS header is present. All curl commands in this doc use https://.

**Next steps (Xcode):**
1. Open Xcode → create iOS project → add engine/ as local Swift package
2. Drag all ios/ folders into project (App, Views, ViewModels, Persistence, Coordinators, Design, Debug)
3. Build → fix any import issues → run on simulator
4. Verify MockData seeds 18 garments on first launch
5. Connect to backend API (replace TODO stubs in ViewModels)
6. Camera capture → `POST /api/garments/{id}/image` → real garment photos
7. Add custom fonts (Instrument Serif, DM Sans) to Xcode project

**Backend API overview (49 endpoints):**
```
# Pipeline (5)
POST /api/product-search, /api/barcode-lookup, /api/extract-colors
POST /api/product-metadata, /api/image-polish

# Garment CRUD + Images (7)
POST/GET /api/garments, GET/PUT/DELETE /api/garments/{id}
POST /api/garments/{id}/image, GET /api/images/{id}/{variant}

# Wardrobe Map + Analysis (8)
GET /api/wardrobe/analysis, /api/wardrobe/garment/{id}
GET /api/wardrobe/gaps, /api/wardrobe/key-garments, /api/wardrobe/weak-garments
GET /api/wardrobe/export, POST /api/wardrobe/import, GET /api/wardrobe/suggest

# Outfits (5)
POST/GET /api/outfits, GET/PUT/DELETE /api/outfits/{id}

# Wear Tracking + Clarity History (4)
POST /api/garments/{id}/wear, GET /api/garments/{id}/wears
GET /api/clarity/history, POST /api/clarity/snapshot

# Discover Feed (7)
GET /api/discover/brands (brand grid for Full mode)
GET /api/discover/feed (mode=7030|full, season, tags, style_context, brand_id)
POST /api/discover/bookmark, DELETE /api/discover/bookmark/{id}
GET /api/discover/bookmarks
POST /api/discover/action, GET /api/discover/stats

# Brand Partners / Shopify (8)
POST /api/brands/register, GET /api/brands, GET /api/brands/{id}
DELETE /api/brands/{id}, POST /api/brands/{id}/sync
GET /api/brands/{id}/products, GET /api/brands/{id}/preview
POST /api/brands/webhook

# Shopify OAuth (2)
GET /api/auth/shopify, GET /api/auth/shopify/callback

# User Profile (2)
GET/PUT /api/profile (style_context, archetype)

# Health (1)
GET /api/health
```

---

## 5. Technical Conventions

- **Language**: Swift 6 (strict concurrency). swift-tools-version: 6.2.
- **All public types**: Codable, Sendable. Structs also Identifiable. Enums also CaseIterable.
- **Engine pattern**: Caseless `enum` with `static` functions. No state. Pure functions. Deterministic.
- **Architecture**: V2 engine is standalone Swift package in `engine/`. No UIKit/SwiftUI dependencies in engine. iOS app imports engine as local package. Python backend in `backend/` (FastAPI on Railway).
- **Storage**: SwiftData (local-first). No cloud sync in V1.
- **Testing**: Swift Testing framework (`import Testing`, `@Test`, `#expect`). NOT XCTest. Engines must be deterministic and fully testable.
- **No external dependencies** in the engine package.
- **File organization**: Models in `Models/`, Engines in `Engines/`, Helpers in `Helpers/` (internal), Tests mirror source structure.
- **Edge cases**: All engines must handle empty input gracefully (return 0 or default state, never crash).
- **Floating point**: Use tolerance (< 0.001) for equality checks in tests, not `==`.
- **ViewModel pattern**: `@MainActor @Observable` classes. Never call engines directly — only through EngineCoordinator.

---

## 6. Autonomous Session Protocol

### Token Monitoring
- Claude Code must monitor context usage continuously
- When context reaches ~70% used: finish current task, do NOT start new ones
- When context reaches ~85% used: immediately wrap up and save state
- Never start a task you cannot finish within remaining context

### Auto-save Trigger
When context hits 70%+, automatically:
1. Run: `cd engine && swift build && swift test`
2. Update CONTINUE.md with:
   - Timestamp
   - Completed this session (bullet list)
   - Current test status (X/Y passing)
   - In-progress work (if any was interrupted)
   - Exact next prompt to paste (complete, self-contained)
   - Any important decisions or trade-offs
3. Run: `git add -A && git commit -m "session: [summary]"`
4. Print to terminal: `SESSION SAVED. Next: Read CONTINUE.md and resume.`

### CONTINUE.md Format
```
# CORET – Continue
Last updated: [timestamp]

## Completed This Session
- [x] item 1

## Build Status
swift build: pass/fail
swift test: X/Y passing

## In Progress (if interrupted)
[description or "nothing interrupted"]

## Next Session Prompt
[Complete ready-to-paste prompt]

## Decisions Made
[Any trade-offs or architectural decisions]
```
