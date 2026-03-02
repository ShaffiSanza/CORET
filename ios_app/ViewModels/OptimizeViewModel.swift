import Foundation
import Observation
import COREEngine

// MARK: - OptimizeViewModel
// Exposes gap analysis results and manages suggestion interaction.
// Simulation-based only — never auto-adds items.

@MainActor
@Observable
final class OptimizeViewModel {

    // MARK: - State
    var gapResult: GapResult?
    var selectedGap: StructuralGap?
    var projectionForSelected: ProjectionResult?
    var dismissedSuggestionIDs: Set<UUID> = []
    var isLoading: Bool = false

    // MARK: - Dependencies
    private let coordinator: EngineCoordinator
    private let wardrobeViewModel: WardrobeViewModel

    // MARK: - Init
    init(coordinator: EngineCoordinator, wardrobeViewModel: WardrobeViewModel) {
        self.coordinator = coordinator
        self.wardrobeViewModel = wardrobeViewModel
    }

    // MARK: - Computed

    var visibleGaps: [StructuralGap] {
        gapResult?.gaps ?? []
    }

    var primaryGap: StructuralGap? {
        visibleGaps.first
    }

    var secondaryGaps: [StructuralGap] {
        Array(visibleGaps.dropFirst(1).prefix(2))
    }

    var frictionItems: [GarmentFriction] {
        gapResult?.friction ?? []
    }

    var hasFriction: Bool { !frictionItems.isEmpty }

    // MARK: - Gap Selection

    func selectGap(_ gap: StructuralGap) {
        selectedGap = gap
        // Compute projection for first suggestion if available
        if let suggestion = gap.suggestions.first {
            projectionForSelected = coordinator.projectAdding(suggestion.candidate)
        }
    }

    func clearSelection() {
        selectedGap = nil
        projectionForSelected = nil
    }

    // MARK: - Suggestion Actions

    /// User acquired the item — add it to wardrobe using suggestion's candidate garment.
    func markSuggestionAcquired(_ suggestion: GapSuggestion) async {
        isLoading = true
        defer { isLoading = false }
        await wardrobeViewModel.add(suggestion.candidate)
        sync()
    }

    /// Dismiss a suggestion (session-only, not persisted in V1).
    func dismissSuggestion(_ suggestion: GapSuggestion) {
        dismissedSuggestionIDs.insert(suggestion.id)
    }

    /// Manual resimulate — recomputes gap analysis from latest wardrobe state.
    func resimulate() async {
        isLoading = true
        defer { isLoading = false }
        await coordinator.recompute()
        sync()
    }

    // MARK: - Sync

    func sync() {
        gapResult = coordinator.latestGapResult
        clearSelection()
    }
}
