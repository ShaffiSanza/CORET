# CORET — Complete System Reference

CORET is a wardrobe operating system. It measures structural cohesion and guides optimization. It is not a fashion app, shopping platform, or budgeting tool. It is a structural system.

Tagline: "Your Wardrobe Operating System."
Secondary: "Built Around Your Core."

Architectural Principle: CORET is engine-first, UI-second. UI is replaceable. Engine is not.

---

## Project Structure

```
CORET/
├── CLAUDE.md              ← You are here
├── CONTINUE.md            ← Session state for resuming
├── README.md
├── docs/
│   ├── brand_foundation.md
│   ├── cohesion_engine_v1.md
│   ├── data_model_v1.md
│   ├── information_architecture.md   (empty, not yet written)
│   ├── monetization_strategy.md      (empty, not yet written)
│   ├── optimize_engine_v1.md
│   └── product_spec.md
├── core/                  ← Swift package: COREEngine
│   ├── Package.swift      (swift-tools-version: 6.2)
│   ├── Sources/COREEngine/
│   │   ├── COREEngine.swift           (placeholder)
│   │   ├── Engines/
│   │   │   └── CohesionEngine.swift   (scoring engine — complete)
│   │   └── Models/
│   │       └── WardrobeItem.swift     (all data models + enums)
│   └── Tests/COREEngineTests/
│       └── CohesionEngineTests.swift  (29 tests — all passing)
└── ios_app/               (empty, future SwiftUI app)
```

---

## Build Status

**Swift package compiles clean on Swift 6.2.**

Build command: `cd core && swift build`
Test command: `cd core && swift test`

### What Is Done
- All data model types implemented in `core/Sources/COREEngine/Models/WardrobeItem.swift`
- All enums: ItemCategory, Silhouette, BaseGroup, Temperature, Archetype, SeasonMode, CohesionStatus
- All structs: WardrobeItem, UserProfile, CohesionSnapshot
- All types are public, Codable, Identifiable (structs), CaseIterable (enums), Sendable (Swift 6 safe)
- Package.swift configured with library target and test target
- **CohesionEngine** fully implemented in `core/Sources/COREEngine/Engines/CohesionEngine.swift`
  - Archetype alignment scoring (weight 0.35)
  - Combination density calculation (weight 0.30)
  - Palette control scoring (weight 0.20)
  - Rotation balance scoring (weight 0.15)
  - Total cohesion computation with weighted formula
  - Status level derivation from total score
  - Conflict map: structuredMinimal ↔ relaxedStreet
  - All edge cases handled (empty wardrobe, missing categories, monochrome bypass)
- **CohesionEngine tests**: 29 tests in `core/Tests/COREEngineTests/CohesionEngineTests.swift` — all passing

### What Is Next (Build Order)
1. ~~**CohesionEngine**~~ ✅ Complete
2. **OptimizeEngine** — `Sources/COREEngine/Engines/OptimizeEngine.swift`
   - Weakest component identification
   - Structural candidate generation
   - Hypothetical item simulation
   - Candidate ranking and recommendation
   - Removal simulation (structural friction detection)
3. **Unit tests** for OptimizeEngine
4. **SwiftUI iOS app** in `ios_app/` consuming the COREEngine package

---

## Brand Foundation

- Positioning: Personal wardrobe operating system measuring, optimizing, and evolving wardrobe structure
- Philosophy: Control over validation. Structure over trend. Identity over status. Optimization over impulse. Measurement without judgment. Creative deviation allowed. CORET measures — the user decides.
- Emotional core: Internal = Control. External = Cohesive presence.
- Target audience: Professionals 25–40 who value structure, clarity, intentional identity. Secondary: style-conscious younger users.
- Tone: Calm, architectural, precise, gender-neutral, non-dramatic, non-preachy.
- Visual: Warm dark taupe background. Light stone cards. Deep muted forest green accent. Soft animations 200–300ms ease-in-out. Logo: CORET uppercase spaced typography.
- Identity: Long-term system, not short-term style phase. Seasonal recalibration. Structural evolution tracked.

---

## Data Model (V1)

All types live in `core/Sources/COREEngine/Models/WardrobeItem.swift`.

### Enums

| Enum | Cases | Notes |
|------|-------|-------|
| `ItemCategory` | top, bottom, shoes, outerwear | Clothing type |
| `Silhouette` | structured, balanced, relaxed | Fit profile |
| `BaseGroup` | neutral, deep, light, accent | Color grouping |
| `Temperature` | warm, cool, neutral | Color temperature |
| `Archetype` | structuredMinimal, relaxedStreet, smartCasual | Expandable |
| `SeasonMode` | springSummer, autumnWinter | Seasonal context |
| `CohesionStatus` | structuring, refining, coherent, aligned, architected | Score tier label |

### WardrobeItem
| Field | Type | Notes |
|-------|------|-------|
| id | UUID | Immutable |
| imagePath | String | User-uploaded image |
| category | ItemCategory | Required |
| silhouette | Silhouette | Required |
| rawColor | String | User-selected color name |
| baseGroup | BaseGroup | Mapped from color |
| temperature | Temperature | Mapped from color |
| archetypeTag | Archetype | Single tag per item |
| customColorOverride | Bool | Default false |
| usageCount | Int | Default 0 |
| lastWornDate | Date? | Nullable |
| createdAt | Date | Immutable |

### UserProfile
| Field | Type |
|-------|------|
| id | UUID |
| primaryArchetype | Archetype |
| secondaryArchetype | Archetype |
| seasonMode | SeasonMode |
| createdAt | Date |

### CohesionSnapshot
| Field | Type |
|-------|------|
| id | UUID |
| alignmentScore | Double |
| densityScore | Double |
| paletteScore | Double |
| rotationScore | Double |
| totalScore | Double |
| statusLevel | CohesionStatus |
| createdAt | Date |

---

## Cohesion Engine (V1)

Score range: 0–100. Displayed as hybrid: Status label + numeric score.

### Formula

```
Total = (Alignment × 0.35) + (Density × 0.30) + (Palette × 0.20) + (Rotation × 0.15)
```

Each component returns 0–100.

### 1. Archetype Alignment (35%)

Each item has one archetype tag. User profile has primary + secondary.

| Match | Score |
|-------|-------|
| Primary match | 1.0 |
| Secondary match | 0.7 |
| Neutral | 0.5 |
| Conflict | 0.2 |

Alignment = Average(item_alignment_values) × 100

### 2. Combination Density (30%)

Valid outfit = 1 Top + 1 Bottom + 1 Shoes + optional Outerwear.

Validation rules:
- **Archetype**: All items must not conflict with primary direction
- **Silhouette balance**: Structured=+1, Balanced=0, Relaxed=-1. Outfit sum must be in [-2, +2]. Outside [-3, +3] is invalid.
- **Color rules**: Max 1 Accent. At least 1 Neutral. No strong Warm+Cool clash. Monochrome always valid.

Density = (valid_outfits / total_possible_outfits) × 100

### 3. Palette Control (20%)

Optimal structure: 60–80% Neutral/Deep, 0–20% Accent, limited temperature variance. Penalty for over-diversification.

### 4. Rotation Balance (15%)

Per-category usage deviation from mean. Lower deviation = higher score.

Rotation = 100 - normalized_deviation

### Status Levels

| Range | Status |
|-------|--------|
| 0–49 | Structuring |
| 50–64 | Refining |
| 65–79 | Coherent |
| 80–89 | Aligned |
| 90–100 | Architected |

### Design Principles
- Deterministic. No ML.
- Transparent breakdown.
- Not easily gamed.
- Stable over time.

---

## Optimize Engine (V1)

Identifies structural weaknesses and simulates improvements. Prioritizes forward strengthening over removal.

### Core Logic
1. Compute current CohesionSnapshot
2. Identify weakest component (Density, Alignment, Palette, or Rotation)
3. Generate structural candidates dynamically:
   - Missing category roles
   - Silhouette imbalance correction
   - Palette correction (increase neutral/deep)
   - Archetype reinforcement
4. For each candidate: simulate adding hypothetical item, recompute cohesion, calculate component + total improvement
5. Rank candidates by component improvement
6. Return: 1 primary candidate + up to 2 secondary candidates

### Impact Display
- Primary: Improvement in weakest component (e.g., Density: 52 → 64, +12)
- Secondary: Total structural impact (e.g., Total: 74 → 78, +4)

### Removal Logic
- Runs internally via simulation
- Only surfaced if impact > +8 total
- Labeled "Structural Friction"

### Recalculation Triggers
- Item added or removed
- Archetype changed
- Structural adjustment made
- Season recalibration applied
- NOT during UI rendering

---

## Product Spec (V1)

iOS-first native app. SwiftUI + SwiftData. Local-first.

### V1 Core Areas
1. **Wardrobe** — Image upload (manual), required fields (category, silhouette, color, archetype tag). Satisfying grid layout, calm UI, structural status at top.
2. **Cohesion Score** — Hybrid: Status label primary, 0–100 secondary. Breakdown on tap.
3. **Optimize View** — Future potential focus. Visual simulation, potential increase display, Priority 1 target (free), Priority 2 target (Pro). Add to strengthen (primary), Reconsider (secondary). No shopping in V1.
4. **Archetype System** — Primary + secondary archetype. Single tag per item. Archetype change via profile. New profile creation supported. Wardrobe persists across profile changes.
5. **Seasonal Recalibration** — Location-based season detection. Suggest recalibration (not forced). New seasonal roadmap. Temporary structural weight adjustment.
6. **Structural Evolution** — Narrative-based evolution tracking (not traditional score graph). Phases displayed over time.

### Monetization (Freemium)
- **Free**: Basic score, 1 active target, limited optimize preview
- **Pro** (target $9–12/month): Full simulation, multiple roadmap targets, advanced analytics, drift tracking, structural evolution detail

### Explicitly NOT in V1
- Machine learning
- Auto color detection
- Retail integrations
- Social features
- Budget tools
- Cross-platform support

---

## Scaling Strategy

### Phase 1 — Deterministic Core (Current)
- Rule-based Cohesion engine
- Dynamic Optimize engine
- Seasonal recalibration
- Structural evolution
- Local-first architecture

### Phase 2 — Structural Intelligence Layer
- Outfit-level synergy scoring
- High-cohesion pair detection
- Impact-per-outfit modeling
- Structural drift detection
- Pro-only deep analytics
- Advanced rotation modeling
- Still deterministic. No ML.

### Phase 3 — Behavioral Learning Layer (Optional ML)
ML added ONLY as behavioral layer:
- User preference weighting
- Override pattern detection
- Archetype adaptation over time
- Predictive structural decay

ML will NOT replace the structural engine. It augments it.

### Phase 4 — Commerce Layer (Optional)
- Source similar structural roles
- Affiliate integration
- Structural purchase simulation
- Budget-aware optimization

Commerce must never compromise structural integrity.

### Phase 5 — Platform Expansion
- Swift core remains central engine
- Wrapped for: SwiftUI iOS, Backend service, React Native bridge, Web
- Engine remains platform-agnostic

---

## Technical Conventions

- **Language**: Swift 6 (strict concurrency). swift-tools-version: 6.2.
- **All public types**: Codable, Sendable. Structs also Identifiable. Enums also CaseIterable.
- **Architecture**: Engine is a standalone Swift package (`core/COREEngine`). No UIKit/SwiftUI dependencies in the engine. iOS app will import the package.
- **Storage**: SwiftData (local-first). No cloud sync in V1.
- **Testing**: XCTest via `swift test`. Engines must be deterministic and fully testable.
- **No external dependencies** in the engine package.
- **File organization**: Models in `Models/`, Engines in `Engines/`, Tests mirror source structure.

---

## Autonomous Session Protocol

### Token Monitoring
- Claude Code must monitor context usage continuously
- When context reaches ~70% used: finish current task, do NOT start new ones
- When context reaches ~85% used: immediately wrap up and save state
- Never start a task you cannot finish within remaining context

### Auto-save Trigger
When context hits 70%+, automatically:
1. Run: `cd core && swift build && swift test`
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
- [x] item 2

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
