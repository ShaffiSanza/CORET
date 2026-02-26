# CORET – SwiftData Model Specification V1

## Purpose

Defines full persistence architecture for CORET V1 using SwiftData.

Goals:
- Deterministic storage
- Clear ownership boundaries
- No business logic in persistence layer
- Migration-safe
- Future-proof for V2 expansion
- Engine-first architecture preserved

SwiftData is used only for persistence.
All structural logic remains inside engines.

---

## Architectural Principles

1. SwiftData stores raw state.
2. Engines compute derived state.
3. Derived state is NOT permanently stored unless explicitly cached.
4. No engine mutates SwiftData directly.
5. UI interacts with ViewModels.
6. ViewModels trigger engine recomputation.
7. Snapshots are immutable once stored.

---

## Core Entities

### WardrobeItemEntity
- id: UUID
- createdAt: Date
- updatedAt: Date
- category: String (enum rawValue)
- silhouette: String
- baseGroup: String
- temperature: String
- archetypeTag: String
- usageCount: Int
- isArchived: Bool (default false)

Rules:
- Deleting item triggers engine recompute.
- Editing structural field invalidates cached results.

### UserProfileEntity
- id: UUID
- createdAt: Date
- primaryArchetype: String
- secondaryArchetype: String
- latitude: Double?
- longitude: Double?
- seasonMode: String (suggested / auto)
- lastRecalibrationDate: Date?
- recalibrationCooldownUntil: Date?
- lastEngineRecompute: Date?

Only one profile instance allowed in V1.

### EvolutionSnapshotEntity
Immutable record.
- id: UUID
- snapshotDate: Date
- totalScore: Double
- alignment: Double
- density: Double
- palette: Double
- rotation: Double
- phaseRawValue: String
- volatility: Double
- isSeasonAdjusted: Bool (always false for Evolution)

Rules:
- Never edited after creation.
- Created on first day of month OR major structural shift (>10 score delta).

### EngineCacheEntity (Optional Performance Layer)
- id: UUID
- lastComputedAt: Date
- totalScore: Double
- alignment: Double
- density: Double
- palette: Double
- rotation: Double
- weakestComponent: String
- optimizePrimaryRaw: String?
- optimizeSecondaryRaw: [String]

Rules:
- Cache invalidated on: item add/delete/edit, archetype change, seasonal recalibration.
- Cache never authoritative. If missing → engine recompute.

---

## Relationships

V1 intentionally avoids deep relational complexity.
- WardrobeItemEntity: no direct relationships
- UserProfileEntity: global singleton, no foreign keys
- EvolutionSnapshotEntity: independent records
- EngineCacheEntity: independent

---

## Delete Rules

WardrobeItemEntity:
- Hard delete allowed.
- On delete: trigger engine recompute, check if new EvolutionSnapshot required.

EvolutionSnapshotEntity:
- Never auto-deleted.
- Manual purge only via full profile reset.

UserProfileEntity reset deletes:
- All WardrobeItemEntity
- All EvolutionSnapshotEntity
- EngineCacheEntity

---

## Recompute Triggers

Engine must recompute when:
- WardrobeItemEntity inserted
- WardrobeItemEntity deleted
- WardrobeItemEntity structural field edited
- UserProfileEntity archetype changed
- Seasonal recalibration applied

Engine recompute sequence:
1. Generate new CohesionSnapshot
2. Update EngineCacheEntity
3. Evaluate StructuralEvolution
4. Possibly create EvolutionSnapshotEntity

---

## Seasonal Adjustment Handling

SeasonalModifier:
- Applied at compute time only.
- Not stored in WardrobeItemEntity.
- Not stored in EvolutionSnapshotEntity.

If season changes: cache invalidated, recompute executed.

---

## Migration Strategy

V1 → V2 migration assumes:
- Archetype enum may expand.
- New fields may be added to WardrobeItemEntity.
- Evolution phase rules may adjust.

Rules:
1. Never rename stored fields without mapping.
2. Use additive migrations only.
3. Do not remove stored columns in minor updates.
4. EvolutionSnapshotEntity must remain backward-compatible.

Versioning: ModelVersion 1 for V1. Future migrations use versioned container.

---

## Data Integrity Constraints

Enforce at persistence layer:
- WardrobeItemEntity.category cannot be empty.
- silhouette cannot be empty.
- baseGroup cannot be empty.
- primaryArchetype cannot equal secondaryArchetype.

If violated: save rejected, UI displays validation error.

---

## Performance Strategy

- EngineCacheEntity prevents recomputation on passive UI navigation.
- No heavy fetches in Dashboard.
- EvolutionSnapshot fetch limited to last 24 months in UI.
- No live reactive heavy queries.

---

## Future Expansion Compatibility

Designed to support:
- Multiple profiles (V2)
- Cloud sync (V2+)
- Commerce layer references
- ML behavioral layer
- Outfit-level snapshot tracking

---

## Non-Goals V1
- No remote database
- No multi-device sync
- No shared wardrobes
- No live collaboration
- No analytics tracking

CORET is local-first.

---

## Summary

This persistence layer supports the engine. It does not control it.

Clean separation of logic and persistence.
Deterministic engine authority.
Snapshot immutability.
Migration safety.
Performance stability.
Scalability for future layers.
