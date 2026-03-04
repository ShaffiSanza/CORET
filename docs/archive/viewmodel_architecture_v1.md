# CORET – ViewModel Architecture Specification V1

## Purpose

Defines the ViewModel layer between SwiftData (Persistence) and Engine Layer.

Goals:
- Preserve engine authority
- Prevent business logic leakage into UI
- Keep UI reactive but controlled
- Centralize recomputation triggers
- Avoid duplicate logic across screens

ViewModels coordinate.
Engines compute.
SwiftData stores.

---

## Architectural Layers

Layer 1 – SwiftData Entities
Layer 2 – ViewModels
Layer 3 – Engines
Layer 4 – SwiftUI Views

Flow Direction:
User Action → ViewModel → Engine → Snapshot → SwiftData → UI Refresh

Engines never talk directly to SwiftData.
ViewModels orchestrate all interactions.

---

## Core ViewModels

1. DashboardViewModel
2. WardrobeViewModel
3. OptimizeViewModel
4. EvolutionViewModel
5. ProfileViewModel

All ViewModels:
- Are observable
- Hold derived state
- Never hold business logic
- Never compute structural logic internally

---

## EngineCoordinator (Critical)

Single coordination layer responsible for:
- Running CohesionEngine
- Running OptimizeEngine
- Running SeasonalEngine
- Running EvolutionEngine
- Updating cache
- Creating snapshots when required

Responsibilities:
- Fetch persisted data
- Convert entities → domain models
- Run engines
- Return immutable snapshot objects
- Persist snapshots if required

ViewModels never call engines directly.
They call EngineCoordinator.

---

## DashboardViewModel

Purpose: Expose current structural state.

Properties:
- currentSnapshot
- cohesionScore
- status
- componentBreakdown
- evolutionPhase
- seasonalActive
- optimizePreview

On Init:
- Fetch latest EngineCacheEntity
- If invalid → request recompute from EngineCoordinator

Triggers: Pull to refresh, app foreground event.
No mutation logic inside.

---

## WardrobeViewModel

Purpose: Manage wardrobe persistence.

Properties:
- items (list of WardrobeItemEntity)
- filters
- sortedItems

Functions:
- addItem()
- editItem()
- deleteItem()

Each mutation must:
1. Persist change
2. Trigger EngineCoordinator.recompute()
3. Refresh DashboardViewModel

Does NOT compute structural impact.
May request impact preview from EngineCoordinator.

---

## OptimizeViewModel

Purpose: Expose optimization simulation results.

Properties:
- primaryCandidate
- secondaryCandidates
- weakestComponent
- projectedImpact

On Init:
- Fetch from EngineCacheEntity if valid
- Otherwise request simulation from EngineCoordinator

Actions:
- markCandidateAsAcquired()
- dismissCandidate()
- manualResimulate()

When candidate marked acquired:
- WardrobeViewModel.addItem(simulatedRole)
- Trigger recompute

Does NOT modify persistence directly.

---

## EvolutionViewModel

Purpose: Expose structural maturity history.

Properties:
- currentPhase
- narrative
- stabilityWindow
- monthlySnapshots

On Init:
- Fetch EvolutionSnapshotEntity list
- Determine current phase from EngineCoordinator

No write access. Snapshots are immutable.

---

## ProfileViewModel

Purpose: Manage system configuration.

Properties:
- primaryArchetype
- secondaryArchetype
- location
- seasonMode

Functions:
- updateArchetypes()
- updateLocation()
- applySeasonalRecalibration()
- resetProfile()

Each mutation:
1. Persist change
2. Trigger EngineCoordinator.recompute()

ResetProfile must:
- Delete all WardrobeItemEntity
- Delete all EvolutionSnapshotEntity
- Delete EngineCacheEntity
- Create new UserProfileEntity

---

## Recompute Flow (Critical)

Any structural mutation must follow:
1. Persistence mutation (SwiftData save)
2. EngineCoordinator.recompute()
3. Cache update
4. Snapshot creation if needed
5. Notify relevant ViewModels
6. UI re-renders

Recompute must be synchronous or completion-handled.
No race conditions allowed.

---

## Snapshot Ownership

Only EngineCoordinator can:
- Create EvolutionSnapshotEntity
- Update EngineCacheEntity

ViewModels must not:
- Construct snapshot manually
- Modify engine output

---

## Concurrency Model V1

- Engine runs on background thread
- UI updates on main thread
- No parallel engine runs allowed
- Recompute requests queued if already running

Simple locking mechanism required.

---

## Error Handling

Engine errors must:
- Never crash UI
- Return safe fallback snapshot
- Log diagnostic message (development only)

Invalid persistence state must:
- Block UI action
- Display validation error

---

## Anti-Patterns (Forbidden)

ViewModels must NOT:
- Contain structural logic
- Modify engine math
- Cache business rules
- Duplicate calculations
- Call multiple engines independently

All engine interaction flows through EngineCoordinator.

---

## Future Scalability

Supports without refactoring core engine:
- Multiple profiles (V2)
- Cloud sync
- Live background recompute
- ML behavioral layer
- Commerce integration

---

## Summary

ViewModels: Coordinate. Trigger recompute. Expose derived state. Never compute structure.

EngineCoordinator: Single structural authority bridge between persistence and logic.

This preserves CORET's deterministic architecture.
