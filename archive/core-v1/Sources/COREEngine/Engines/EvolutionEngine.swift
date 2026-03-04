import Foundation

// MARK: - Types

public enum EvolutionPhase: String, Codable, CaseIterable, Sendable {
    case foundation
    case developing
    case refining
    case cohering
    case evolving
}

public enum EvolutionTrend: String, Codable, CaseIterable, Sendable {
    case improving
    case stable
    case declining
}

public struct EvolutionSnapshot: Identifiable, Codable, Sendable {
    public let id: UUID
    public let phase: EvolutionPhase
    public let volatility: Double
    public let trend: EvolutionTrend
    public let narrative: String
    public let snapshotCount: Int
    public let createdAt: Date

    public init(
        id: UUID = UUID(),
        phase: EvolutionPhase,
        volatility: Double,
        trend: EvolutionTrend,
        narrative: String,
        snapshotCount: Int,
        createdAt: Date = Date()
    ) {
        self.id = id
        self.phase = phase
        self.volatility = volatility
        self.trend = trend
        self.narrative = narrative
        self.snapshotCount = snapshotCount
        self.createdAt = createdAt
    }
}

public enum VolatilityLevel: String, Codable, CaseIterable, Sendable {
    case low
    case medium
    case high
}

public struct MomentumResult: Identifiable, Codable, Sendable, Equatable {
    public let id: UUID
    public let trend: EvolutionTrend
    public let volatilityLevel: VolatilityLevel
    public let descriptor: String

    public init(
        id: UUID = UUID(),
        trend: EvolutionTrend,
        volatilityLevel: VolatilityLevel,
        descriptor: String
    ) {
        self.id = id
        self.trend = trend
        self.volatilityLevel = volatilityLevel
        self.descriptor = descriptor
    }
}

// MARK: - EvolutionEngine

public enum EvolutionEngine: Sendable {

    // MARK: - Public API

    public static func evaluate(snapshots: [CohesionSnapshot]) -> EvolutionSnapshot {
        let currentPhase = phase(snapshots: snapshots)
        let currentVolatility = volatility(snapshots: snapshots)
        let currentTrend = trend(snapshots: snapshots)
        let currentNarrative = narrative(for: currentPhase, snapshots: snapshots)

        return EvolutionSnapshot(
            phase: currentPhase,
            volatility: currentVolatility,
            trend: currentTrend,
            narrative: currentNarrative,
            snapshotCount: snapshots.count
        )
    }

    public static func phase(snapshots: [CohesionSnapshot]) -> EvolutionPhase {
        let basePhase = basePhase(snapshots: snapshots)
        let regressed = applyRegression(phase: basePhase, snapshots: snapshots)
        return regressed
    }

    public static func volatility(snapshots: [CohesionSnapshot]) -> Double {
        let last5 = Array(snapshots.suffix(5))
        guard last5.count >= 2 else { return 0 }

        let scores = last5.map(\.totalScore)
        let mean = scores.reduce(0, +) / Double(scores.count)
        let variance = scores.reduce(0.0) { $0 + ($1 - mean) * ($1 - mean) } / Double(scores.count)
        return variance.squareRoot()
    }

    public static func trend(snapshots: [CohesionSnapshot]) -> EvolutionTrend {
        guard snapshots.count >= 2 else { return .stable }

        let last = Array(snapshots.suffix(min(snapshots.count, 3)))
        let scores = last.map(\.totalScore)

        var allNonDecreasing = true
        var allNonIncreasing = true

        for i in 1..<scores.count {
            if scores[i] < scores[i - 1] { allNonDecreasing = false }
            if scores[i] > scores[i - 1] { allNonIncreasing = false }
        }

        // If all equal, that's stable (both flags true)
        if allNonDecreasing && allNonIncreasing { return .stable }
        if allNonDecreasing { return .improving }
        if allNonIncreasing { return .declining }
        return .stable
    }

    // MARK: - Momentum

    public static func momentum(snapshots: [CohesionSnapshot]) -> MomentumResult {
        guard snapshots.count >= 3 else {
            return MomentumResult(
                trend: .stable,
                volatilityLevel: .low,
                descriptor: "Structural Emergence"
            )
        }

        let currentTrend = trend(snapshots: snapshots)
        let vol = volatility(snapshots: snapshots)
        let level = volatilityLevel(from: vol)
        let desc = descriptor(trend: currentTrend, volatilityLevel: level)

        return MomentumResult(
            trend: currentTrend,
            volatilityLevel: level,
            descriptor: desc
        )
    }

    public static func volatilityLevel(from volatility: Double) -> VolatilityLevel {
        if volatility < 6 { return .low }
        if volatility <= 10 { return .medium }
        return .high
    }

    // MARK: - Anchor Items

    public static func anchorItems(snapshots: [CohesionSnapshot]) -> [UUID] {
        guard snapshots.count >= 5 else { return [] }

        let last5 = Array(snapshots.suffix(5))
        guard let latestItemIDs = last5.last?.itemIDs else { return [] }

        // Count frequency of each item across last 5 snapshots
        var frequency: [UUID: Int] = [:]
        for snapshot in last5 {
            for itemID in snapshot.itemIDs {
                frequency[itemID, default: 0] += 1
            }
        }

        // Filter: >= 60% (3 of 5) and present in latest snapshot
        let threshold = 3
        let candidates = frequency
            .filter { $0.value >= threshold && latestItemIDs.contains($0.key) }
            .sorted { $0.value > $1.value }
            .prefix(3)
            .map(\.key)

        return Array(candidates)
    }

    // MARK: - Snapshot Anchors

    /// Selects 3–4 structurally representative items for a snapshot's visual composition.
    /// Uses weighted scoring: alignmentMatch(0.4) + categoryCentrality(0.35) + usageStability(0.25).
    /// Distinct from `anchorItems(snapshots:)` which analyzes cross-snapshot frequency.
    public static func snapshotAnchors(
        items: [WardrobeItem],
        profile: UserProfile
    ) -> [WardrobeItem] {
        guard !items.isEmpty else { return [] }

        // Score each item
        var scored: [(item: WardrobeItem, score: Double)] = []

        // Pre-compute category counts for centrality
        var categoryCounts: [ItemCategory: Int] = [:]
        for item in items {
            categoryCounts[item.category, default: 0] += 1
        }

        // Pre-compute category means for usage stability
        var categoryMeans: [ItemCategory: Double] = [:]
        let categories: [ItemCategory] = [.top, .bottom, .shoes, .outerwear]
        for category in categories {
            let categoryItems = items.filter { $0.category == category }
            guard !categoryItems.isEmpty else { continue }
            let usages = categoryItems.map { Double($0.usageCount) }
            categoryMeans[category] = usages.reduce(0, +) / Double(usages.count)
        }

        for item in items {
            // alignmentMatch: primary=1.0, secondary=0.7, else=0.0
            let alignmentMatch: Double
            if item.archetypeTag == profile.primaryArchetype {
                alignmentMatch = 1.0
            } else if item.archetypeTag == profile.secondaryArchetype {
                alignmentMatch = 0.7
            } else {
                alignmentMatch = 0.0
            }

            // categoryCentrality: categoryWeight × (1 / categoryCount)
            let isRequired = item.category != .outerwear
            let categoryWeight: Double = isRequired ? 1.0 : 0.7
            let categoryCount = categoryCounts[item.category] ?? 1
            let categoryCentrality = min(categoryWeight * (1.0 / Double(max(categoryCount, 1))), 1.0)

            // usageStability: 1 - min(normalizedDeviation, 1)
            let categoryMean = categoryMeans[item.category] ?? 0
            let deviation = abs(Double(item.usageCount) - categoryMean)
            let normalizedDeviation = deviation / max(categoryMean, 1.0)
            let usageStability = 1.0 - min(normalizedDeviation, 1.0)

            let anchorScore = alignmentMatch * 0.4 + categoryCentrality * 0.35 + usageStability * 0.25
            scored.append((item, anchorScore))
        }

        // Sort by score descending, tie-break by earlier createdAt
        scored.sort { a, b in
            if abs(a.score - b.score) >= 0.001 {
                return a.score > b.score
            }
            return a.item.createdAt < b.item.createdAt
        }

        // Select top 3–4 with category diversity constraint
        if items.count < 3 {
            return scored.map(\.item)
        }

        let targetCount = min(scored.count, 4)
        var selected: [WardrobeItem] = []
        var usedIndices: Set<Int> = []

        // Take top items greedily
        for i in 0..<min(targetCount, scored.count) {
            selected.append(scored[i].item)
            usedIndices.insert(i)
        }

        // Enforce at least 2 distinct categories
        let distinctCategories = Set(selected.map(\.category))
        if distinctCategories.count < 2 && selected.count >= 3 {
            // Swap last selected item with next-best from a different category
            let dominantCategory = selected[0].category
            for i in 0..<scored.count where !usedIndices.contains(i) {
                if scored[i].item.category != dominantCategory {
                    selected[selected.count - 1] = scored[i].item
                    break
                }
            }
        }

        return selected
    }

    // MARK: - Private Helpers

    private static let descriptorMatrix: [EvolutionTrend: [VolatilityLevel: String]] = [
        .improving: [
            .low: "Upward Stability",
            .medium: "Active Strengthening",
            .high: "Rapid Restructuring",
        ],
        .stable: [
            .low: "Structural Consolidation",
            .medium: "Holding Pattern",
            .high: "Unstable Plateau",
        ],
        .declining: [
            .low: "Gentle Recalibration",
            .medium: "Gradual Loosening",
            .high: "Temporary Instability",
        ],
    ]

    private static func descriptor(trend: EvolutionTrend, volatilityLevel: VolatilityLevel) -> String {
        descriptorMatrix[trend]?[volatilityLevel] ?? "Structural Emergence"
    }

    private static func basePhase(snapshots: [CohesionSnapshot]) -> EvolutionPhase {
        let count = snapshots.count
        let vol = volatility(snapshots: snapshots)

        // Check from highest phase down
        if count >= 20 {
            let last5Avg = average(of: snapshots.suffix(5))
            if last5Avg >= 80 && vol < 6 { return .evolving }
        }

        if count >= 12 {
            let last5Avg = average(of: snapshots.suffix(5))
            if last5Avg >= 70 && vol < 8 { return .cohering }
        }

        if count >= 7 {
            let last3Avg = average(of: snapshots.suffix(3))
            if last3Avg >= 50 && vol < 10 { return .refining }
        }

        if count >= 3 {
            if let latest = snapshots.last, latest.totalScore >= 30 {
                return .developing
            }
        }

        return .foundation
    }

    private static func applyRegression(phase: EvolutionPhase, snapshots: [CohesionSnapshot]) -> EvolutionPhase {
        guard phase != .foundation else { return .foundation }

        let vol = volatility(snapshots: snapshots)
        let last5 = Array(snapshots.suffix(5))

        // Regression: volatility > 15
        if vol > 15 {
            return regress(phase)
        }

        // Regression: latest score drops > 15 from average of last 5
        if last5.count >= 2, let latest = snapshots.last {
            let avg = average(of: last5)
            if avg - latest.totalScore > 15 {
                return regress(phase)
            }
        }

        return phase
    }

    private static func regress(_ phase: EvolutionPhase) -> EvolutionPhase {
        switch phase {
        case .foundation:  return .foundation
        case .developing:  return .foundation
        case .refining:    return .developing
        case .cohering:    return .refining
        case .evolving:    return .cohering
        }
    }

    private static func average(of snapshots: some Collection<CohesionSnapshot>) -> Double {
        guard !snapshots.isEmpty else { return 0 }
        let sum = snapshots.reduce(0.0) { $0 + $1.totalScore }
        return sum / Double(snapshots.count)
    }

    private static let phaseNarratives: [EvolutionPhase: String] = [
        .foundation: "Building your wardrobe's structural foundation.",
        .developing: "Your wardrobe is developing clear structural direction.",
        .refining: "Refining structural cohesion across all components.",
        .cohering: "Strong structural coherence emerging across your wardrobe.",
        .evolving: "Your wardrobe has reached structural maturity. Evolving intentionally.",
    ]

    private static let regressionNarrative = "Your wardrobe is recalibrating. This is part of the process."

    private static func narrative(for phase: EvolutionPhase, snapshots: [CohesionSnapshot]) -> String {
        // Check if regression was triggered
        let base = basePhase(snapshots: snapshots)
        if phase != base && phase != .foundation {
            // Phase was regressed from base — use regression narrative
            return regressionNarrative
        }
        // Also check direct regression conditions even if base == phase
        // (could happen if base was already regressed to same level)
        let vol = volatility(snapshots: snapshots)
        let last5 = Array(snapshots.suffix(5))
        if vol > 15 {
            return regressionNarrative
        }
        if last5.count >= 2, let latest = snapshots.last {
            let avg = average(of: last5)
            if avg - latest.totalScore > 15 {
                return regressionNarrative
            }
        }

        return phaseNarratives[phase] ?? phaseNarratives[.foundation]!
    }
}
