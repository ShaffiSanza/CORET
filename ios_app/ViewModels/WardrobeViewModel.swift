import Foundation
import Observation
import COREEngine

// MARK: - WardrobeFilter
// Value type used by WardrobeViewModel for filtering the garment grid.

struct WardrobeFilter: Equatable {
    var category: Category?
    var archetype: Archetype?
    var silhouette: Silhouette?

    var isActive: Bool {
        category != nil || archetype != nil || silhouette != nil
    }

    func reset() -> WardrobeFilter { WardrobeFilter() }
}

// MARK: - WardrobeViewModel
// Manages garment grid state and CRUD operations.
// All mutations flow through EngineCoordinator (which triggers recompute).

@MainActor
@Observable
final class WardrobeViewModel {

    // MARK: - State
    var garments: [Garment] = []
    var filter: WardrobeFilter = WardrobeFilter()
    var keyGarmentIDs: Set<UUID> = []
    var isLoading: Bool = false

    // MARK: - Dependencies
    private let coordinator: EngineCoordinator

    // MARK: - Init
    init(coordinator: EngineCoordinator) {
        self.coordinator = coordinator
    }

    // MARK: - Computed

    var filteredGarments: [Garment] {
        garments.filter { garment in
            if let category = filter.category, garment.category != category { return false }
            if let silhouette = filter.silhouette, garment.silhouette != silhouette { return false }
            if filter.archetype != nil {
                // Filter by archetype affinity: only show garments with affinity ≥ 0.5
                // for the selected archetype
                guard let archetype = filter.archetype else { return true }
                let affinity = CohesionEngine.archetypeAffinity(
                    baseGroup: garment.baseGroup,
                    archetype: archetype
                )
                if affinity < 0.5 { return false }
            }
            return true
        }
    }

    var isEmpty: Bool { garments.isEmpty }

    // MARK: - CRUD

    func add(_ garment: Garment) async {
        isLoading = true
        defer { isLoading = false }
        await coordinator.addGarment(garment)
        sync()
    }

    func remove(id: UUID) async {
        isLoading = true
        defer { isLoading = false }
        await coordinator.removeGarment(id: id)
        sync()
    }

    func update(_ garment: Garment) async {
        isLoading = true
        defer { isLoading = false }
        await coordinator.updateGarment(garment)
        sync()
    }

    // MARK: - Simulation (no persistence side effects)

    /// Returns projected impact of removing a garment — used for delete confirmation alert.
    func projectionForRemoving(_ garment: Garment) -> ProjectionResult {
        coordinator.projectRemoving(garment)
    }

    /// Biggest clarity impact component for a removal warning message.
    func removalWarning(for garment: Garment) -> String {
        let projection = projectionForRemoving(garment)
        let delta = projection.clarityDelta
        if delta < -2.0 {
            return "Removing this item will reduce Clarity by \(String(format: "%.0f", abs(delta)))."
        }
        return "This item has low structural impact on your wardrobe."
    }

    // MARK: - Sync

    func sync() {
        garments = coordinator.garments()
        keyGarmentIDs = Set(KeyGarmentResolver.keyGarmentIDs(
            items: garments,
            profile: coordinator.profile()
        ))
    }
}
