import Testing
@testable import COREEngine

// MARK: - Test Helpers

private func makeSnapshot(score: Double) -> CohesionSnapshot {
    let status = CohesionEngine.statusLevel(from: score)
    return CohesionSnapshot(
        alignmentScore: score,
        densityScore: score,
        paletteScore: score,
        rotationScore: score,
        totalScore: score,
        statusLevel: status
    )
}

private func makeSnapshots(scores: [Double]) -> [CohesionSnapshot] {
    scores.map { makeSnapshot(score: $0) }
}

// MARK: - Empty / Minimal

@Test func emptySnapshotsReturnFoundation() {
    let evo = EvolutionEngine.evaluate(snapshots: [])
    #expect(evo.phase == .foundation)
    #expect(evo.volatility == 0)
    #expect(evo.trend == .stable)
    #expect(evo.snapshotCount == 0)
}

@Test func singleSnapshotReturnFoundation() {
    let evo = EvolutionEngine.evaluate(snapshots: makeSnapshots(scores: [50]))
    #expect(evo.phase == .foundation)
    #expect(evo.volatility == 0)
    #expect(evo.trend == .stable)
    #expect(evo.snapshotCount == 1)
}

@Test func twoSnapshotsMaxDeveloping() {
    let evo = EvolutionEngine.evaluate(snapshots: makeSnapshots(scores: [40, 50]))
    #expect(evo.phase == .foundation) // Need 3+ for developing
    #expect(evo.trend == .improving)
}

// MARK: - Phase Thresholds

@Test func developingPhaseAt3Snapshots() {
    let evo = EvolutionEngine.evaluate(snapshots: makeSnapshots(scores: [20, 25, 30]))
    #expect(evo.phase == .developing)
}

@Test func developingRequiresLatestAbove30() {
    // 3 snapshots but latest < 30
    let evo = EvolutionEngine.evaluate(snapshots: makeSnapshots(scores: [20, 25, 29]))
    #expect(evo.phase == .foundation)
}

@Test func refiningPhaseAt7Snapshots() {
    let scores = [30.0, 35, 40, 45, 50, 55, 60]
    let evo = EvolutionEngine.evaluate(snapshots: makeSnapshots(scores: scores))
    // Last 3 avg = (50+55+60)/3 = 55 >= 50, count >= 7
    #expect(evo.phase == .refining)
}

@Test func refiningRequiresLowVolatility() {
    // 7 snapshots, last 3 avg >= 50, but high volatility
    let scores = [30.0, 80, 30, 80, 50, 55, 60]
    let evo = EvolutionEngine.evaluate(snapshots: makeSnapshots(scores: scores))
    // Volatility of last 5 [30, 80, 50, 55, 60] is high
    let vol = EvolutionEngine.volatility(snapshots: makeSnapshots(scores: scores))
    if vol >= 10 {
        #expect(evo.phase != .refining || evo.phase == .developing || evo.phase == .foundation)
    }
}

@Test func coheringPhaseAt12Snapshots() {
    let scores = Array(repeating: 75.0, count: 12)
    let evo = EvolutionEngine.evaluate(snapshots: makeSnapshots(scores: scores))
    // Last 5 avg = 75 >= 70, volatility = 0 < 8, count = 12
    #expect(evo.phase == .cohering)
}

@Test func evolvingPhaseAt20Snapshots() {
    let scores = Array(repeating: 85.0, count: 20)
    let evo = EvolutionEngine.evaluate(snapshots: makeSnapshots(scores: scores))
    // Last 5 avg = 85 >= 80, volatility = 0 < 6, count = 20
    #expect(evo.phase == .evolving)
}

@Test func evolvingRequires20Snapshots() {
    // Only 19 snapshots, all 85 — should be cohering not evolving
    let scores = Array(repeating: 85.0, count: 19)
    let evo = EvolutionEngine.evaluate(snapshots: makeSnapshots(scores: scores))
    #expect(evo.phase == .cohering)
}

// MARK: - Volatility

@Test func volatilityZeroForIdenticalScores() {
    let vol = EvolutionEngine.volatility(snapshots: makeSnapshots(scores: [50, 50, 50, 50, 50]))
    #expect(vol == 0)
}

@Test func volatilityZeroForSingleSnapshot() {
    let vol = EvolutionEngine.volatility(snapshots: makeSnapshots(scores: [50]))
    #expect(vol == 0)
}

@Test func volatilityCalculatesCorrectly() {
    // Scores: [60, 80] → mean=70, variance=((60-70)^2 + (80-70)^2)/2 = 100, stddev=10
    let vol = EvolutionEngine.volatility(snapshots: makeSnapshots(scores: [60, 80]))
    #expect(abs(vol - 10.0) < 0.001)
}

@Test func volatilityUsesLast5Only() {
    // 7 snapshots — should only use last 5
    let scores = [10.0, 10, 50, 50, 50, 50, 50]
    let vol = EvolutionEngine.volatility(snapshots: makeSnapshots(scores: scores))
    // Last 5 = [50, 50, 50, 50, 50] → volatility = 0
    #expect(vol == 0)
}

// MARK: - Trend Detection

@Test func trendImprovingMonotonic() {
    let trend = EvolutionEngine.trend(snapshots: makeSnapshots(scores: [40, 50, 60]))
    #expect(trend == .improving)
}

@Test func trendDecliningMonotonic() {
    let trend = EvolutionEngine.trend(snapshots: makeSnapshots(scores: [60, 50, 40]))
    #expect(trend == .declining)
}

@Test func trendStableForMixed() {
    let trend = EvolutionEngine.trend(snapshots: makeSnapshots(scores: [50, 60, 50]))
    #expect(trend == .stable)
}

@Test func trendStableForEqual() {
    let trend = EvolutionEngine.trend(snapshots: makeSnapshots(scores: [50, 50, 50]))
    #expect(trend == .stable)
}

@Test func trendUsesLast3() {
    // 5 snapshots — trend should be based on last 3 only
    let trend = EvolutionEngine.trend(snapshots: makeSnapshots(scores: [10, 20, 60, 50, 40]))
    // Last 3 = [60, 50, 40] → declining
    #expect(trend == .declining)
}

@Test func trendWith2Snapshots() {
    let improving = EvolutionEngine.trend(snapshots: makeSnapshots(scores: [40, 60]))
    #expect(improving == .improving)
    let declining = EvolutionEngine.trend(snapshots: makeSnapshots(scores: [60, 40]))
    #expect(declining == .declining)
}

// MARK: - Regression

@Test func regressionOnScoreDrop() {
    // 7 stable snapshots at 55, then a crash to 30
    var scores = Array(repeating: 55.0, count: 7)
    scores.append(30.0)
    let evo = EvolutionEngine.evaluate(snapshots: makeSnapshots(scores: scores))
    // Base phase would be refining (7+ snapshots, last 3 avg includes 30 → avg = (55+55+30)/3 = 46.7 < 50)
    // Actually last 3 avg < 50 means refining threshold not met. Base = developing (latest 30 >= 30).
    // Then regression check: avg of last 5 = (55+55+55+55+30)/5 = 50, drop = 50-30 = 20 > 15 → regress
    // developing → foundation
    #expect(evo.phase == .foundation)
}

@Test func regressionOnHighVolatility() {
    // Wild swings: high volatility > 15
    let scores = [20.0, 80, 20, 80, 20, 80, 30]
    let vol = EvolutionEngine.volatility(snapshots: makeSnapshots(scores: scores))
    let evo = EvolutionEngine.evaluate(snapshots: makeSnapshots(scores: scores))
    #expect(vol > 15)
    // Should regress from whatever base phase it achieves
    // Base: 7 snapshots, last 3 avg = (20+80+30)/3 ≈ 43 < 50 → not refining
    // Latest = 30 >= 30 and count >= 3 → developing
    // Regression: vol > 15 → developing → foundation
    #expect(evo.phase == .foundation)
}

@Test func noRegressionWhenStable() {
    let scores = Array(repeating: 55.0, count: 7)
    let evo = EvolutionEngine.evaluate(snapshots: makeSnapshots(scores: scores))
    // Last 3 avg = 55 >= 50, vol = 0 < 10, count = 7 → refining
    // No regression: vol = 0, no score drop
    #expect(evo.phase == .refining)
}

@Test func regressionNeverBelowFoundation() {
    // Already at foundation, regression shouldn't go lower
    let scores = [10.0, 5, 80]
    let evo = EvolutionEngine.evaluate(snapshots: makeSnapshots(scores: scores))
    // 3 snapshots, latest 80 >= 30 → developing
    // Vol of last 5 = [10, 5, 80] → high volatility
    let vol = EvolutionEngine.volatility(snapshots: makeSnapshots(scores: scores))
    if vol > 15 {
        // developing → foundation (regression)
        #expect(evo.phase == .foundation)
    }
}

// MARK: - Narratives

@Test func foundationNarrative() {
    let evo = EvolutionEngine.evaluate(snapshots: [])
    #expect(evo.narrative == "Building your wardrobe's structural foundation.")
}

@Test func developingNarrative() {
    let evo = EvolutionEngine.evaluate(snapshots: makeSnapshots(scores: [20, 25, 35]))
    #expect(evo.phase == .developing)
    #expect(evo.narrative == "Your wardrobe is developing clear structural direction.")
}

@Test func regressionNarrative() {
    // Trigger regression via high volatility
    let scores = [20.0, 80, 20, 80, 20, 80, 30]
    let evo = EvolutionEngine.evaluate(snapshots: makeSnapshots(scores: scores))
    #expect(evo.narrative == "Your wardrobe is recalibrating. This is part of the process.")
}

// MARK: - Integration

@Test func evaluateReturnsCorrectSnapshotCount() {
    let snapshots = makeSnapshots(scores: [40, 50, 60, 70, 80])
    let evo = EvolutionEngine.evaluate(snapshots: snapshots)
    #expect(evo.snapshotCount == 5)
}

@Test func fullProgressionJourney() {
    // Simulate a user's journey from nothing to evolving
    var snapshots: [CohesionSnapshot] = []

    // Foundation (0 snapshots)
    #expect(EvolutionEngine.phase(snapshots: snapshots) == .foundation)

    // Build to developing (3 snapshots, latest >= 30)
    snapshots = makeSnapshots(scores: [20, 25, 35])
    #expect(EvolutionEngine.phase(snapshots: snapshots) == .developing)

    // Build to refining (7 snapshots, last 3 avg >= 50)
    snapshots = makeSnapshots(scores: [20, 25, 35, 40, 50, 55, 60])
    #expect(EvolutionEngine.phase(snapshots: snapshots) == .refining)

    // Build to cohering (12 snapshots, last 5 avg >= 70)
    snapshots = makeSnapshots(scores: [20, 25, 35, 40, 50, 55, 60, 70, 72, 74, 76, 78])
    #expect(EvolutionEngine.phase(snapshots: snapshots) == .cohering)

    // Build to evolving (20 snapshots, last 5 avg >= 80)
    snapshots = makeSnapshots(scores: [20, 25, 35, 40, 50, 55, 60, 70, 72, 74, 76, 78, 80, 81, 82, 83, 84, 85, 86, 87])
    #expect(EvolutionEngine.phase(snapshots: snapshots) == .evolving)
}
