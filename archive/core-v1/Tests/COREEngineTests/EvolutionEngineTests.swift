import Foundation
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

private func makeItem(
    category: ItemCategory,
    silhouette: Silhouette = .balanced,
    baseGroup: BaseGroup = .neutral,
    temperature: Temperature = .neutral,
    archetype: Archetype = .structuredMinimal,
    usageCount: Int = 0,
    createdAt: Date = Date()
) -> WardrobeItem {
    WardrobeItem(
        imagePath: "test.jpg",
        category: category,
        silhouette: silhouette,
        rawColor: "test",
        baseGroup: baseGroup,
        temperature: temperature,
        archetypeTag: archetype,
        usageCount: usageCount,
        createdAt: createdAt
    )
}

private func makeProfile(
    primary: Archetype = .structuredMinimal,
    secondary: Archetype = .smartCasual
) -> UserProfile {
    UserProfile(
        primaryArchetype: primary,
        secondaryArchetype: secondary,
        seasonMode: .autumnWinter
    )
}

private func makeSnapshotWithItems(score: Double, itemIDs: some Collection<UUID>) -> CohesionSnapshot {
    let status = CohesionEngine.statusLevel(from: score)
    return CohesionSnapshot(
        alignmentScore: score,
        densityScore: score,
        paletteScore: score,
        rotationScore: score,
        totalScore: score,
        statusLevel: status,
        itemIDs: Set(itemIDs)
    )
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

// MARK: - Momentum

@Test func momentumFewSnapshotsReturnsEmergence() {
    let result = EvolutionEngine.momentum(snapshots: makeSnapshots(scores: [50, 60]))
    #expect(result.trend == .stable)
    #expect(result.volatilityLevel == .low)
    #expect(result.descriptor == "Structural Emergence")
}

@Test func momentumEmptySnapshotsReturnsEmergence() {
    let result = EvolutionEngine.momentum(snapshots: [])
    #expect(result.descriptor == "Structural Emergence")
}

@Test func momentumImprovingLow() {
    // Monotonically increasing, low volatility
    let result = EvolutionEngine.momentum(snapshots: makeSnapshots(scores: [50, 51, 52, 53, 54]))
    #expect(result.trend == .improving)
    #expect(result.volatilityLevel == .low)
    #expect(result.descriptor == "Upward Stability")
}

@Test func momentumImprovingMedium() {
    // Improving trend but medium volatility (6-10)
    // Last 3: 40, 50, 60 → improving. Last 5 volatility needs to be 6-10.
    // Scores: [30, 60, 30, 50, 60] → last 3 = [30, 50, 60] → improving
    // Last 5 stddev: mean=46, deviations=[16,14,16,4,14], var=avg(256+196+256+16+196)=184, stddev≈13.6 → high
    // Try: [45, 55, 42, 50, 58] → last 3 = [42, 50, 58] → improving
    // Last 5 mean=50, deviations=[5,5,8,0,8], var=avg(25+25+64+0+64)=35.6, stddev≈5.97 → low border
    // Try: [40, 58, 44, 52, 60] → last 3 = [44, 52, 60] → improving
    // Last 5 mean=50.8, var=avg((40-50.8)^2 + (58-50.8)^2 + (44-50.8)^2 + (52-50.8)^2 + (60-50.8)^2)
    // = avg(116.64 + 51.84 + 46.24 + 1.44 + 84.64) = 60.16, stddev≈7.76 → medium!
    let result = EvolutionEngine.momentum(snapshots: makeSnapshots(scores: [40, 58, 44, 52, 60]))
    #expect(result.trend == .improving)
    #expect(result.volatilityLevel == .medium)
    #expect(result.descriptor == "Active Strengthening")
}

@Test func momentumImprovingHigh() {
    // Last 3 improving, very high volatility
    let result = EvolutionEngine.momentum(snapshots: makeSnapshots(scores: [20, 80, 20, 60, 80]))
    #expect(result.trend == .improving)
    #expect(result.volatilityLevel == .high)
    #expect(result.descriptor == "Rapid Restructuring")
}

@Test func momentumStableLow() {
    let result = EvolutionEngine.momentum(snapshots: makeSnapshots(scores: [50, 50, 50, 50, 50]))
    #expect(result.trend == .stable)
    #expect(result.volatilityLevel == .low)
    #expect(result.descriptor == "Structural Consolidation")
}

@Test func momentumStableMedium() {
    // Mixed last 3 → stable, medium volatility
    let result = EvolutionEngine.momentum(snapshots: makeSnapshots(scores: [40, 58, 55, 48, 55]))
    #expect(result.trend == .stable)
    #expect(result.volatilityLevel == .medium)
    #expect(result.descriptor == "Holding Pattern")
}

@Test func momentumStableHigh() {
    // Mixed last 3 → stable, high volatility
    let result = EvolutionEngine.momentum(snapshots: makeSnapshots(scores: [20, 80, 60, 30, 60]))
    #expect(result.trend == .stable)
    #expect(result.volatilityLevel == .high)
    #expect(result.descriptor == "Unstable Plateau")
}

@Test func momentumDecliningLow() {
    let result = EvolutionEngine.momentum(snapshots: makeSnapshots(scores: [54, 53, 52, 51, 50]))
    #expect(result.trend == .declining)
    #expect(result.volatilityLevel == .low)
    #expect(result.descriptor == "Gentle Recalibration")
}

@Test func momentumDecliningMedium() {
    // Declining last 3, medium volatility
    let result = EvolutionEngine.momentum(snapshots: makeSnapshots(scores: [60, 40, 58, 52, 44]))
    #expect(result.trend == .declining)
    #expect(result.volatilityLevel == .medium)
    #expect(result.descriptor == "Gradual Loosening")
}

@Test func momentumDecliningHigh() {
    let result = EvolutionEngine.momentum(snapshots: makeSnapshots(scores: [80, 20, 80, 60, 20]))
    #expect(result.trend == .declining)
    #expect(result.volatilityLevel == .high)
    #expect(result.descriptor == "Temporary Instability")
}

@Test func volatilityLevelThresholds() {
    #expect(EvolutionEngine.volatilityLevel(from: 0) == .low)
    #expect(EvolutionEngine.volatilityLevel(from: 5.99) == .low)
    #expect(EvolutionEngine.volatilityLevel(from: 6) == .medium)
    #expect(EvolutionEngine.volatilityLevel(from: 10) == .medium)
    #expect(EvolutionEngine.volatilityLevel(from: 10.01) == .high)
    #expect(EvolutionEngine.volatilityLevel(from: 50) == .high)
}

// MARK: - Anchor Items

@Test func anchorItemsEmptyWhenFewSnapshots() {
    let snapshots = makeSnapshots(scores: [50, 60, 70, 80])
    #expect(EvolutionEngine.anchorItems(snapshots: snapshots).isEmpty)
}

@Test func anchorItemsEmptyWhenNoSnapshots() {
    #expect(EvolutionEngine.anchorItems(snapshots: []).isEmpty)
}

@Test func anchorItemsDetectsConsistentItems() {
    let itemA = UUID()
    let itemB = UUID()
    let itemC = UUID()

    // itemA appears in all 5, itemB in 4, itemC in 2 (below 60%)
    let snapshots = [
        makeSnapshotWithItems(score: 50, itemIDs: [itemA, itemB, itemC]),
        makeSnapshotWithItems(score: 55, itemIDs: [itemA, itemB, itemC]),
        makeSnapshotWithItems(score: 60, itemIDs: [itemA, itemB]),
        makeSnapshotWithItems(score: 65, itemIDs: [itemA, itemB]),
        makeSnapshotWithItems(score: 70, itemIDs: [itemA, itemB]),
    ]

    let anchors = EvolutionEngine.anchorItems(snapshots: snapshots)
    #expect(anchors.contains(itemA))
    #expect(anchors.contains(itemB))
    #expect(!anchors.contains(itemC))  // only 2/5 = 40% < 60%
}

@Test func anchorItemsRequiresPresenceInLatest() {
    let itemA = UUID()
    let itemB = UUID()

    // itemA in first 4, NOT in last → excluded
    // itemB in all 5 → anchor
    let snapshots = [
        makeSnapshotWithItems(score: 50, itemIDs: [itemA, itemB]),
        makeSnapshotWithItems(score: 55, itemIDs: [itemA, itemB]),
        makeSnapshotWithItems(score: 60, itemIDs: [itemA, itemB]),
        makeSnapshotWithItems(score: 65, itemIDs: [itemA, itemB]),
        makeSnapshotWithItems(score: 70, itemIDs: [itemB]),
    ]

    let anchors = EvolutionEngine.anchorItems(snapshots: snapshots)
    #expect(!anchors.contains(itemA))
    #expect(anchors.contains(itemB))
}

@Test func anchorItemsMaxThree() {
    let ids = (0..<6).map { _ in UUID() }

    // All 6 items in all 5 snapshots → all qualify → max 3 returned
    let allIDs = Set(ids)
    let snapshots = (0..<5).map { i in
        makeSnapshotWithItems(score: Double(50 + i), itemIDs: allIDs)
    }

    let anchors = EvolutionEngine.anchorItems(snapshots: snapshots)
    #expect(anchors.count == 3)
}

@Test func anchorItemsUsesLast5Only() {
    let itemA = UUID()
    let itemB = UUID()

    // 7 snapshots. itemA only in first 2, itemB in all 7.
    // Last 5: itemA not present → not anchor
    let snapshots = [
        makeSnapshotWithItems(score: 40, itemIDs: [itemA, itemB]),
        makeSnapshotWithItems(score: 45, itemIDs: [itemA, itemB]),
        makeSnapshotWithItems(score: 50, itemIDs: [itemB]),
        makeSnapshotWithItems(score: 55, itemIDs: [itemB]),
        makeSnapshotWithItems(score: 60, itemIDs: [itemB]),
        makeSnapshotWithItems(score: 65, itemIDs: [itemB]),
        makeSnapshotWithItems(score: 70, itemIDs: [itemB]),
    ]

    let anchors = EvolutionEngine.anchorItems(snapshots: snapshots)
    #expect(!anchors.contains(itemA))
    #expect(anchors.contains(itemB))
}

@Test func anchorItemsSortedByFrequency() {
    let itemA = UUID()
    let itemB = UUID()
    let itemC = UUID()

    // itemA: 5/5, itemB: 4/5, itemC: 3/5 — all present in last snapshot
    let snapshots = [
        makeSnapshotWithItems(score: 50, itemIDs: [itemA]),
        makeSnapshotWithItems(score: 55, itemIDs: [itemA, itemB]),
        makeSnapshotWithItems(score: 60, itemIDs: [itemA, itemB, itemC]),
        makeSnapshotWithItems(score: 65, itemIDs: [itemA, itemB, itemC]),
        makeSnapshotWithItems(score: 70, itemIDs: [itemA, itemB, itemC]),
    ]

    let anchors = EvolutionEngine.anchorItems(snapshots: snapshots)
    #expect(anchors.count == 3)
    #expect(anchors[0] == itemA)  // 5/5
    #expect(anchors[1] == itemB)  // 4/5
    #expect(anchors[2] == itemC)  // 3/5
}

// MARK: - Integration

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

// MARK: - Snapshot Anchors

@Test func snapshotAnchorsEmptyItems() {
    let result = EvolutionEngine.snapshotAnchors(items: [], profile: makeProfile())
    #expect(result.isEmpty)
}

@Test func snapshotAnchorsFewerThan3Items() {
    let items = [
        makeItem(category: .top),
        makeItem(category: .bottom),
    ]
    let result = EvolutionEngine.snapshotAnchors(items: items, profile: makeProfile())
    #expect(result.count == 2)
}

@Test func snapshotAnchorsPrimaryArchetypeScoresHigher() {
    // Primary archetype item should rank above secondary and neutral
    let past = Date(timeIntervalSince1970: 0)
    let items = [
        makeItem(category: .top, archetype: .smartCasual, usageCount: 5, createdAt: past),
        makeItem(category: .bottom, archetype: .relaxedStreet, usageCount: 5, createdAt: past),
        makeItem(category: .shoes, archetype: .structuredMinimal, usageCount: 5, createdAt: past),
    ]
    let profile = makeProfile(primary: .structuredMinimal, secondary: .smartCasual)
    let result = EvolutionEngine.snapshotAnchors(items: items, profile: profile)

    #expect(result.count == 3)
    // Primary archetype shoes should be first (highest alignment match)
    #expect(result[0].archetypeTag == .structuredMinimal)
}

@Test func snapshotAnchorsCategoryDiversityConstraint() {
    // If top 3 are all same category, swap last for different category
    let past = Date(timeIntervalSince1970: 0)
    let items = [
        makeItem(category: .top, archetype: .structuredMinimal, usageCount: 5, createdAt: past),
        makeItem(category: .top, archetype: .structuredMinimal, usageCount: 5, createdAt: past),
        makeItem(category: .top, archetype: .structuredMinimal, usageCount: 5, createdAt: past),
        makeItem(category: .bottom, archetype: .smartCasual, usageCount: 5, createdAt: past),
    ]
    let profile = makeProfile(primary: .structuredMinimal, secondary: .smartCasual)
    let result = EvolutionEngine.snapshotAnchors(items: items, profile: profile)

    let categories = Set(result.map(\.category))
    #expect(categories.count >= 2) // Must have at least 2 distinct categories
    #expect(categories.contains(.bottom)) // Bottom should be included for diversity
}

@Test func snapshotAnchorsTieBreakByCreatedAt() {
    // Equal scores: older item should come first
    let earlier = Date(timeIntervalSince1970: 1000)
    let later = Date(timeIntervalSince1970: 2000)
    let items = [
        makeItem(category: .top, archetype: .structuredMinimal, usageCount: 5, createdAt: later),
        makeItem(category: .bottom, archetype: .structuredMinimal, usageCount: 5, createdAt: earlier),
        makeItem(category: .shoes, archetype: .structuredMinimal, usageCount: 5, createdAt: later),
    ]
    let profile = makeProfile(primary: .structuredMinimal, secondary: .smartCasual)
    let result = EvolutionEngine.snapshotAnchors(items: items, profile: profile)

    // The bottom (earlier createdAt) should sort first among equal scores
    // But category centrality also matters — all have 1 item per category so equal there
    #expect(result[0].createdAt == earlier)
}

@Test func snapshotAnchorsOuterwearLowerWeight() {
    // Outerwear gets 0.7 category weight vs 1.0 for required categories
    let past = Date(timeIntervalSince1970: 0)
    let items = [
        makeItem(category: .top, archetype: .structuredMinimal, usageCount: 5, createdAt: past),
        makeItem(category: .outerwear, archetype: .structuredMinimal, usageCount: 5, createdAt: past),
        makeItem(category: .bottom, archetype: .structuredMinimal, usageCount: 5, createdAt: past),
        makeItem(category: .shoes, archetype: .structuredMinimal, usageCount: 5, createdAt: past),
    ]
    let profile = makeProfile(primary: .structuredMinimal, secondary: .smartCasual)
    let result = EvolutionEngine.snapshotAnchors(items: items, profile: profile)

    // Outerwear has lower centrality weight (0.7 vs 1.0) so should rank last
    #expect(result.last?.category == .outerwear)
}

@Test func snapshotAnchorsUsageStabilityAllUnused() {
    // All items with 0 usage → categoryMean = 0 → deviation = 0 → stability = 1.0 for all
    let past = Date(timeIntervalSince1970: 0)
    let items = [
        makeItem(category: .top, archetype: .structuredMinimal, usageCount: 0, createdAt: past),
        makeItem(category: .bottom, archetype: .structuredMinimal, usageCount: 0, createdAt: past),
        makeItem(category: .shoes, archetype: .structuredMinimal, usageCount: 0, createdAt: past),
    ]
    let profile = makeProfile(primary: .structuredMinimal, secondary: .smartCasual)
    let result = EvolutionEngine.snapshotAnchors(items: items, profile: profile)

    // Should return all 3 without crashing
    #expect(result.count == 3)
}

@Test func snapshotAnchorsMaxFourItems() {
    let past = Date(timeIntervalSince1970: 0)
    let items = [
        makeItem(category: .top, archetype: .structuredMinimal, usageCount: 5, createdAt: past),
        makeItem(category: .bottom, archetype: .structuredMinimal, usageCount: 5, createdAt: past),
        makeItem(category: .shoes, archetype: .structuredMinimal, usageCount: 5, createdAt: past),
        makeItem(category: .outerwear, archetype: .structuredMinimal, usageCount: 5, createdAt: past),
        makeItem(category: .top, archetype: .structuredMinimal, usageCount: 5, createdAt: past),
    ]
    let profile = makeProfile(primary: .structuredMinimal, secondary: .smartCasual)
    let result = EvolutionEngine.snapshotAnchors(items: items, profile: profile)

    #expect(result.count <= 4)
}
