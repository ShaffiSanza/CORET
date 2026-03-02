import Foundation
import Observation
import COREEngine

// MARK: - ProfileViewModel
// Manages system configuration: archetype, location, seasonal recalibration, profile reset.
// Each mutation triggers EngineCoordinator.recompute() via coordinator methods.

@MainActor
@Observable
final class ProfileViewModel {

    // MARK: - State
    var profile: UserProfile = UserProfile()
    var seasonalRecommendation: SeasonalRecommendationV2?
    var seasonalCoverage: SeasonalCoverage?
    var isLoading: Bool = false
    var showResetConfirmation: Bool = false

    // MARK: - Dependencies
    private let coordinator: EngineCoordinator

    // MARK: - Init
    init(coordinator: EngineCoordinator) {
        self.coordinator = coordinator
    }

    // MARK: - Computed

    var primaryArchetype: Archetype { profile.primaryArchetype }

    var shouldSuggestRecalibration: Bool {
        seasonalRecommendation?.shouldRecalibrate ?? false
    }

    var detectedSeason: Season? {
        seasonalRecommendation?.detectedSeason
    }

    // MARK: - Archetype

    func updateArchetype(_ archetype: Archetype) async {
        guard archetype != profile.primaryArchetype else { return }
        isLoading = true
        defer { isLoading = false }
        await coordinator.updateArchetype(archetype)
        sync()
    }

    // MARK: - Location + Seasonal

    func updateLocation(latitude: Double, longitude: Double) async {
        await coordinator.updateLocation(latitude: latitude, longitude: longitude)
        sync()
    }

    func applyRecalibration() async {
        guard let season = detectedSeason else { return }
        isLoading = true
        defer { isLoading = false }
        await coordinator.applyRecalibration(season: season)
        sync()
    }

    // MARK: - Profile Reset

    func resetProfile() async {
        isLoading = true
        defer { isLoading = false }
        await coordinator.resetProfile()
        sync()
    }

    // MARK: - Sync

    func sync() {
        profile = coordinator.profile()
        seasonalRecommendation = coordinator.seasonalRecommendation()
        seasonalCoverage = computeCoverage()
    }

    private func computeCoverage() -> SeasonalCoverage? {
        let garments = coordinator.garments()
        guard !garments.isEmpty else { return nil }
        return SeasonalEngineV2.coverage(items: garments)
    }
}
