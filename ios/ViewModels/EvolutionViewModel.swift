import Foundation
import Observation
import COREEngine

// MARK: - EvolutionViewModel
// Read-only. Exposes journey timeline data.
// Snapshots are immutable — no write access here.

@MainActor
@Observable
final class EvolutionViewModel {

    // MARK: - State
    var journeySnapshot: JourneySnapshot?
    var momentum: JourneyMomentum?
    var milestones: [Milestone] = []
    var clarityHistory: [ClaritySnapshot] = []

    // MARK: - Dependencies
    private let coordinator: EngineCoordinator

    // MARK: - Init
    init(coordinator: EngineCoordinator) {
        self.coordinator = coordinator
    }

    // MARK: - Computed

    var currentPhase: JourneyPhase? { journeySnapshot?.phase }
    var currentNarrative: String? { journeySnapshot?.narrative }
    var currentTrend: JourneyTrend? { journeySnapshot?.trend }
    var volatility: Double { journeySnapshot?.volatility ?? 0 }
    var snapshotCount: Int { clarityHistory.count }

    var hasHistory: Bool { clarityHistory.count >= 3 }

    /// Clarity delta over the last N snapshots (for trend sparkline).
    func clarityDelta(window: Int = 5) -> Double {
        MilestoneTracker.clarityDelta(history: clarityHistory, window: window)
    }

    /// Phase-based milestones for timeline display, sorted by createdAt.
    var phaseMilestones: [Milestone] {
        milestones
            .filter { $0.type == .phaseAdvanced }
            .sorted { $0.createdAt < $1.createdAt }
    }

    var recentMilestones: [Milestone] {
        Array(milestones.sorted { $0.createdAt > $1.createdAt }.prefix(5))
    }

    // MARK: - Sync

    func sync() {
        journeySnapshot = coordinator.latestJourney
        momentum = coordinator.latestMomentum
        milestones = coordinator.latestMilestones
        clarityHistory = coordinator.clarityHistory()
    }
}
