import Testing
import Foundation
@testable import COREEngine

@Suite("MilestoneTracker Tests")
struct MilestoneTrackerTests {

    // MARK: - Helpers

    private func makeSnapshot(score: Double) -> ClaritySnapshot {
        ClaritySnapshot(score: score, band: ClarityEngine.band(from: score))
    }

    private func makeHistory(scores: [Double]) -> [ClaritySnapshot] {
        scores.map { makeSnapshot(score: $0) }
    }

    // MARK: - Phase Thresholds

    @Test func emptyHistoryReturnsBuilding() {
        let phase = MilestoneTracker.phase(history: [])
        #expect(phase == .building)
    }

    @Test func singleSnapshotReturnsBuilding() {
        let history = makeHistory(scores: [50])
        #expect(MilestoneTracker.phase(history: history) == .building)
    }

    @Test func twoSnapshotsReturnsBuilding() {
        let history = makeHistory(scores: [50, 60])
        #expect(MilestoneTracker.phase(history: history) == .building)
    }

    @Test func threeSnapshotsAbove30ReturnsDeveloping() {
        let history = makeHistory(scores: [20, 25, 35])
        #expect(MilestoneTracker.phase(history: history) == .developing)
    }

    @Test func threeSnapshotsBelow30ReturnsBuilding() {
        let history = makeHistory(scores: [10, 15, 20])
        #expect(MilestoneTracker.phase(history: history) == .building)
    }

    @Test func sevenSnapshotsRefining() {
        // 7 snapshots, last 3 avg ≥ 50, volatility < 10
        let history = makeHistory(scores: [30, 35, 40, 45, 55, 55, 55])
        let phase = MilestoneTracker.phase(history: history)
        #expect(phase == .refining)
    }

    @Test func twelveSnapshotsCohering() {
        // 12 snapshots, last 5 avg ≥ 70, volatility < 8
        let scores = [30.0, 35, 40, 50, 55, 60, 65, 70, 72, 73, 74, 75]
        let history = makeHistory(scores: scores)
        let phase = MilestoneTracker.phase(history: history)
        #expect(phase == .cohering)
    }

    @Test func twentySnapshotsEvolving() {
        // 20 snapshots, last 5 avg ≥ 80, volatility < 6
        var scores = Array(repeating: 60.0, count: 15)
        scores.append(contentsOf: [82, 83, 84, 85, 86])
        let history = makeHistory(scores: scores)
        let phase = MilestoneTracker.phase(history: history)
        #expect(phase == .evolving)
    }

    // MARK: - Regression

    @Test func regressionOnScoreDrop() {
        // Last 5 avg is ~70, but latest drops >15 below (e.g., to 50)
        var scores = Array(repeating: 60.0, count: 6)
        scores.append(contentsOf: [70, 72, 74, 76, 50]) // last 5: [72,74,76,50] + some above
        let history = makeHistory(scores: scores)
        // This should trigger regression due to latest (50) being > 15 below last 5 avg
        let phase = MilestoneTracker.phase(history: history)
        // The phase would be refining or developing (regressed from whatever it would have been)
        #expect(phase != .cohering) // regression should prevent cohering
    }

    @Test func regressionOnHighVolatility() {
        // High volatility > 15 should cause regression
        let scores = [30.0, 35, 40, 80, 30, 90, 20, 85, 25, 80, 30]
        let history = makeHistory(scores: scores)
        let vol = MilestoneTracker.volatility(history: history)
        // With wild swings, volatility should be high
        #expect(vol > 10)
    }

    // MARK: - Volatility

    @Test func volatilityEmptyReturnsZero() {
        #expect(MilestoneTracker.volatility(history: []) == 0)
    }

    @Test func volatilitySingleReturnsZero() {
        let history = makeHistory(scores: [50])
        #expect(MilestoneTracker.volatility(history: history) == 0)
    }

    @Test func volatilityIdenticalScoresReturnsZero() {
        let history = makeHistory(scores: [50, 50, 50, 50, 50])
        #expect(abs(MilestoneTracker.volatility(history: history)) < 0.001)
    }

    @Test func volatilityUsesLast5() {
        // First scores should not affect volatility (uses last 5)
        let history = makeHistory(scores: [10, 20, 50, 50, 50, 50, 50])
        let vol = MilestoneTracker.volatility(history: history)
        #expect(abs(vol) < 0.001) // last 5 are all 50
    }

    @Test func volatilityKnownValue() {
        // Scores: [40, 60] → mean=50, variance=(100+100)/2=100, stddev=10
        let history = makeHistory(scores: [40, 60])
        let vol = MilestoneTracker.volatility(history: history)
        #expect(abs(vol - 10.0) < 0.001)
    }

    // MARK: - Volatility Level

    @Test func volatilityLevelLow() {
        #expect(MilestoneTracker.volatilityLevel(from: 0) == .low)
        #expect(MilestoneTracker.volatilityLevel(from: 5.9) == .low)
    }

    @Test func volatilityLevelMedium() {
        #expect(MilestoneTracker.volatilityLevel(from: 6) == .medium)
        #expect(MilestoneTracker.volatilityLevel(from: 10) == .medium)
    }

    @Test func volatilityLevelHigh() {
        #expect(MilestoneTracker.volatilityLevel(from: 10.1) == .high)
    }

    // MARK: - Trend

    @Test func trendLessThan3ReturnsStable() {
        #expect(MilestoneTracker.trend(history: []) == .stable)
        #expect(MilestoneTracker.trend(history: makeHistory(scores: [50])) == .stable)
        #expect(MilestoneTracker.trend(history: makeHistory(scores: [50, 60])) == .stable)
    }

    @Test func trendImproving() {
        let history = makeHistory(scores: [40, 50, 60])
        #expect(MilestoneTracker.trend(history: history) == .improving)
    }

    @Test func trendDeclining() {
        let history = makeHistory(scores: [60, 50, 40])
        #expect(MilestoneTracker.trend(history: history) == .declining)
    }

    @Test func trendStableMixed() {
        let history = makeHistory(scores: [50, 60, 50])
        #expect(MilestoneTracker.trend(history: history) == .stable)
    }

    @Test func trendStableAllEqual() {
        let history = makeHistory(scores: [50, 50, 50])
        #expect(MilestoneTracker.trend(history: history) == .stable)
    }

    @Test func trendUsesLast3() {
        // First scores irrelevant, last 3 are improving
        let history = makeHistory(scores: [90, 80, 70, 40, 50, 60])
        #expect(MilestoneTracker.trend(history: history) == .improving)
    }

    // MARK: - Momentum

    @Test func momentumLessThan3ReturnsEmergence() {
        let m = MilestoneTracker.momentum(history: makeHistory(scores: [50, 60]))
        #expect(m.descriptor == "Structural Emergence")
        #expect(m.trend == .stable)
        #expect(m.volatilityLevel == .low)
    }

    @Test func momentumImprovingLow() {
        let history = makeHistory(scores: [50, 55, 60])
        let m = MilestoneTracker.momentum(history: history)
        #expect(m.trend == .improving)
        #expect(m.descriptor == "Upward Stability")
    }

    @Test func momentumDecliningHigh() {
        // Scores that give declining trend with high volatility
        // Need last 5 for vol, last 3 for trend
        let history = makeHistory(scores: [20, 90, 20, 90, 80, 70, 50])
        let m = MilestoneTracker.momentum(history: history)
        #expect(m.trend == .declining)
        // Volatility from last 5: [20, 90, 80, 70, 50] → high vol
        #expect(m.volatilityLevel == .high)
        #expect(m.descriptor == "Temporary Instability")
    }

    // MARK: - Milestones

    @Test func emptyHistoryNoMilestones() {
        let ms = MilestoneTracker.milestones(history: [])
        #expect(ms.isEmpty)
    }

    @Test func firstSnapshotCreatesJourneyStarted() {
        let history = makeHistory(scores: [50])
        let ms = MilestoneTracker.milestones(history: history)
        #expect(ms.count >= 1)
        #expect(ms[0].type == .journeyStarted)
    }

    @Test func clarityPeakDetected() {
        let history = makeHistory(scores: [30, 50, 70])
        let ms = MilestoneTracker.milestones(history: history)
        let peaks = ms.filter { $0.type == .clarityPeak }
        #expect(peaks.count == 2) // 50 beats 30, 70 beats 50
    }

    @Test func archetypeMilestoneAt60() {
        let history = makeHistory(scores: [55, 65])
        let ms = MilestoneTracker.milestones(history: history)
        let archMs = ms.filter { $0.type == .archetypeMilestone }
        #expect(archMs.count >= 1) // Crossed 60
    }

    // MARK: - Clarity Delta

    @Test func clarityDeltaEmpty() {
        #expect(MilestoneTracker.clarityDelta(history: [], window: 5) == 0)
    }

    @Test func clarityDeltaSingle() {
        let history = makeHistory(scores: [50])
        #expect(MilestoneTracker.clarityDelta(history: history, window: 5) == 0)
    }

    @Test func clarityDeltaPositive() {
        let history = makeHistory(scores: [40, 50, 60])
        let delta = MilestoneTracker.clarityDelta(history: history, window: 3)
        #expect(abs(delta - 20.0) < 0.001)
    }

    @Test func clarityDeltaNegative() {
        let history = makeHistory(scores: [60, 50, 40])
        let delta = MilestoneTracker.clarityDelta(history: history, window: 3)
        #expect(abs(delta - (-20.0)) < 0.001)
    }

    @Test func clarityDeltaRespectsWindow() {
        let history = makeHistory(scores: [10, 20, 30, 40, 50])
        let delta = MilestoneTracker.clarityDelta(history: history, window: 2)
        #expect(abs(delta - 10.0) < 0.001) // last 2: [40, 50] → 50-40=10
    }

    // MARK: - Evaluate

    @Test func evaluateReturnsJourneySnapshot() {
        let history = makeHistory(scores: [30, 40, 50])
        let snapshot = MilestoneTracker.evaluate(history: history)
        #expect(snapshot.snapshotCount == 3)
        #expect(!snapshot.narrative.isEmpty)
    }

    // MARK: - Determinism

    @Test func deterministic() {
        let history = makeHistory(scores: [30, 40, 50, 60, 70])
        let s1 = MilestoneTracker.evaluate(history: history)
        let s2 = MilestoneTracker.evaluate(history: history)
        #expect(s1.phase == s2.phase)
        #expect(abs(s1.volatility - s2.volatility) < 0.001)
        #expect(s1.trend == s2.trend)
        #expect(s1.narrative == s2.narrative)
    }
}
