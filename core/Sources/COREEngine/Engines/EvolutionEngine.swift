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

    // MARK: - Private Helpers

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
