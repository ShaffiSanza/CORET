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
│   ├── ENGINE_SPECS.md    ← All engine specs, IA, UI, brand, monetization (detailed)
│   ├── swiftdata_model_spec_v1.md
│   └── viewmodel_architecture_v1.md
├── core/                  ← V1 Swift package: COREEngine (ARCHIVED, 218/218 tests)
├── core-v2/               ← V2 Swift package: COREEngine (ACTIVE, 244/244 tests)
│   └── Sources/COREEngine/
│       ├── Models/        Garment.swift, Scoring.swift, Identity.swift
│       ├── Engines/       CohesionEngine, ClarityEngine, ScoreProjector,
│       │                  IdentityResolver, KeyGarmentResolver, MilestoneTracker,
│       │                  SeasonalEngineV2, OptimizeEngineV2
│       └── Helpers/       ScoringHelpers.swift (internal)
├── ios_app/               ← Pass 3: SwiftData + ViewModels (requires Mac)
│   ├── Persistence/       6 SwiftData @Model entities
│   ├── Coordinators/      EngineCoordinator.swift
│   └── ViewModels/        5 @Observable ViewModels (one per tab)
└── moodboard/             ← Visual references for UI (HTML + wireframe .md files)
```

**Moodboard note — `digico_wardrobe_grid.png`:**
Reference ONLY for: 2-column grid layout and garment card presentation.
NOT reference for: prices, brand names, social features, shopping UI, lifestyle photography.

---

## 3. Build Status

| Package | Tests | Status |
|---------|-------|--------|
| core-v2 (V2 — ACTIVE) | 244/244 | ✅ All passing |
| core (V1 — ARCHIVED) | 218/218 | ✅ All passing |

**V2 engines:** CohesionEngine (70), ClarityEngine (23), ScoreProjector (22), IdentityResolver (15), KeyGarmentResolver (13), MilestoneTracker (38), SeasonalEngineV2 (26), OptimizeEngineV2 (19), Models (18).

Build commands:
```
cd core-v2 && swift build && swift test
cd core    && swift build && swift test
```

---

## 4. Current Blocker and Build Order

SwiftUI and SwiftData require Mac + Xcode. Development machine is Arch Linux. Engine layer (core-v2) is complete. Pass 3 files (ios_app/) are written as plain Swift for compilation on Mac. SwiftUI views are not yet written.

**When Mac is available:**
1. Open Xcode, add `ios_app/` files to iOS target
2. Import `core-v2/COREEngine` as local Swift package
3. Build and wire SwiftUI views to ViewModels

---

## 5. Technical Conventions

- **Language**: Swift 6 (strict concurrency). swift-tools-version: 6.2.
- **All public types**: Codable, Sendable. Structs also Identifiable. Enums also CaseIterable.
- **Engine pattern**: Caseless `enum` with `static` functions. No state. Pure functions. Deterministic.
- **Architecture**: V2 engine is standalone Swift package in `core-v2/`. No UIKit/SwiftUI dependencies in engine. iOS app imports core-v2 as local package.
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
1. Run: `cd core-v2 && swift build && swift test`
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
