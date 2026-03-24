import Foundation
import Observation
import COREEngine

// MARK: - ProfileViewModel
// Manages: archetype, style_context, identity, season, milestones, style direction.
// Previously: archetype + season only. Now includes Evolution content (identity, milestones)
// and style_context for ghost-plagg filtering.
// Each mutation triggers EngineCoordinator.recompute().

@MainActor
@Observable
final class ProfileViewModel {

    // MARK: - State
    var profile: UserProfile = UserProfile()
    var identity: WardrobeIdentity?
    var milestones: [Milestone] = []
    var journeySnapshot: JourneySnapshot?
    var seasonalCoverage: SeasonalCoverage?
    var seasonalRecommendation: SeasonalRecommendationV2?
    var styleDirection: DirectionAnalysis?
    var isLoading: Bool = false
    var showResetConfirmation: Bool = false

    /// Style context (menswear/womenswear/unisex/fluid)
    /// Stored in backend profile, controls ghost-plagg filtering
    var styleContext: String = "unisex"

    // MARK: - Dependencies
    private let coordinator: EngineCoordinator

    // MARK: - Init
    init(coordinator: EngineCoordinator) {
        self.coordinator = coordinator
    }

    // MARK: - Computed

    var primaryArchetype: Archetype { profile.primaryArchetype }
    var identityLabel: String { identity?.identityLabel ?? "" }
    var identityTags: [String] { identity?.tags ?? [] }
    var identityProse: String { identity?.prose ?? "" }

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

    // MARK: - Style Context

    func updateStyleContext(_ context: String) async {
        styleContext = context
        // TODO: PUT /api/profile {"style_context": context}
    }

    // MARK: - Style Direction

    func setTargetArchetype(_ target: Archetype) {
        let garments = coordinator.garments()
        let profile = coordinator.profile()
        styleDirection = StyleDirectionEngine.analyze(
            items: garments,
            profile: profile,
            target: target
        )
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
        identity = coordinator.latestIdentity
        journeySnapshot = coordinator.latestJourney
        milestones = coordinator.latestMilestones
        seasonalRecommendation = coordinator.seasonalRecommendation()
        seasonalCoverage = computeCoverage()
    }

    private func computeCoverage() -> SeasonalCoverage? {
        let garments = coordinator.garments()
        guard !garments.isEmpty else { return nil }
        return SeasonalEngineV2.coverage(items: garments)
    }
}
