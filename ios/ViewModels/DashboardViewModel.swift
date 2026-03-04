import Foundation
import Observation
import COREEngine

// MARK: - DashboardViewModel
// Exposes current structural state for the Dashboard tab.
// Read-only from UI's perspective — no mutations here.
// Pulls latest computed results from EngineCoordinator.

@MainActor
@Observable
final class DashboardViewModel {

    // MARK: - State
    var claritySnapshot: ClaritySnapshot?
    var gapResult: GapResult?
    var identity: WardrobeIdentity?
    var journeySnapshot: JourneySnapshot?
    var seasonalCoverage: SeasonalCoverage?
    var isLoading: Bool = false

    // MARK: - Dependencies
    private let coordinator: EngineCoordinator

    // MARK: - Init
    init(coordinator: EngineCoordinator) {
        self.coordinator = coordinator
    }

    // MARK: - Computed

    /// Dashboard greeting suffix, e.g. "Your structure is Coherent."
    var greetingSuffix: String {
        guard let snapshot = claritySnapshot else {
            return "System not yet structured."
        }
        return "Your clarity is \(snapshot.band.displayName)."
    }

    /// Primary recommendation headline for Optimize Preview card.
    var primaryGapTitle: String? {
        gapResult?.gaps.first?.title
    }

    /// Projected clarity delta for Optimize Preview card.
    var primaryGapDelta: Double? {
        gapResult?.gaps.first?.suggestions.first?.clarityDelta
    }

    // MARK: - Actions

    /// Pull-to-refresh and app foreground trigger.
    func refresh() async {
        isLoading = true
        defer { isLoading = false }
        await coordinator.recompute()
        sync()
    }

    /// Sync local state from coordinator (called after recompute).
    func sync() {
        claritySnapshot = coordinator.latestClarity
        gapResult = coordinator.latestGapResult
        identity = coordinator.latestIdentity
        journeySnapshot = coordinator.latestJourney
        seasonalCoverage = computeSeasonalCoverage()
    }

    // MARK: - Private

    private func computeSeasonalCoverage() -> SeasonalCoverage? {
        let garments = coordinator.garments()
        guard !garments.isEmpty else { return nil }
        return SeasonalEngineV2.coverage(items: garments)
    }
}

// MARK: - ClarityBand Display

private extension ClarityBand {
    var displayName: String {
        switch self {
        case .fragmentert:  return "Fragmentert"
        case .iUtvikling:   return "I utvikling"
        case .fokusert:     return "Fokusert"
        case .krystallklar: return "Krystallklar"
        }
    }
}
