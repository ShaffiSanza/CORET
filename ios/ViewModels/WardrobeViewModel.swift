import Foundation
import Observation
import COREEngine

// MARK: - WardrobeFilter

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
// Manages garment grid + hero block (Clarity, best outfit, gap).
// All mutations flow through EngineCoordinator (which triggers recompute).
// IA: Dashboard removed — Clarity score lives here now.

@MainActor
@Observable
final class WardrobeViewModel {

    // MARK: - State
    var garments: [Garment] = []
    var filter: WardrobeFilter = WardrobeFilter()
    var keyGarmentIDs: Set<UUID> = []
    var isLoading: Bool = false

    // Hero block state (was Dashboard)
    var claritySnapshot: ClaritySnapshot?
    var bestOutfit: RankedOutfit?
    var primaryGap: StructuralGap?
    var gapResult: GapResult?

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

    var profile: UserProfile { coordinator.profile() }
    var isEmpty: Bool { garments.isEmpty }
    var garmentCount: Int { garments.count }
    var clarityScore: Double { claritySnapshot?.score ?? 0 }
    var clarityBand: ClarityBand { claritySnapshot?.band ?? .fragmentert }

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

    // MARK: - Simulation

    func projectionForAdding(_ garment: Garment) -> ProjectionResult {
        coordinator.projectAdding(garment)
    }

    func projectionForRemoving(_ garment: Garment) -> ProjectionResult {
        coordinator.projectRemoving(garment)
    }

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

        // Hero block
        claritySnapshot = coordinator.latestClarity
        bestOutfit = coordinator.bestOutfit()
        primaryGap = coordinator.primaryGap()
        gapResult = coordinator.latestGapResult
    }
}
