import Foundation

// MARK: - Types

public enum MilestoneType: String, Codable, CaseIterable, Sendable {
    case journeyStarted, gapFilled, archetypeMilestone, phaseAdvanced, ratioShifted, clarityPeak
}

public enum JourneyPhase: String, Codable, CaseIterable, Sendable {
    case building, developing, refining, cohering, evolving
}

public enum JourneyTrend: String, Codable, CaseIterable, Sendable {
    case improving, stable, declining
}

public enum JourneyVolatilityLevel: String, Codable, CaseIterable, Sendable {
    case low, medium, high
}

public struct Milestone: Identifiable, Codable, Sendable {
    public let id: UUID
    public let type: MilestoneType
    public let title: String
    public let description: String
    public let snapshotIndex: Int
    public let createdAt: Date

    public init(
        id: UUID = UUID(),
        type: MilestoneType,
        title: String,
        description: String,
        snapshotIndex: Int,
        createdAt: Date = Date()
    ) {
        self.id = id
        self.type = type
        self.title = title
        self.description = description
        self.snapshotIndex = snapshotIndex
        self.createdAt = createdAt
    }
}

public struct JourneyMomentum: Identifiable, Codable, Sendable {
    public let id: UUID
    public let trend: JourneyTrend
    public let volatilityLevel: JourneyVolatilityLevel
    public let descriptor: String

    public init(
        id: UUID = UUID(),
        trend: JourneyTrend,
        volatilityLevel: JourneyVolatilityLevel,
        descriptor: String
    ) {
        self.id = id
        self.trend = trend
        self.volatilityLevel = volatilityLevel
        self.descriptor = descriptor
    }
}

public struct JourneySnapshot: Identifiable, Codable, Sendable {
    public let id: UUID
    public let phase: JourneyPhase
    public let volatility: Double
    public let trend: JourneyTrend
    public let narrative: String
    public let snapshotCount: Int
    public let createdAt: Date

    public init(
        id: UUID = UUID(),
        phase: JourneyPhase,
        volatility: Double,
        trend: JourneyTrend,
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

// MARK: - Engine

/// Tracks wardrobe structural journey over time using narrative phases and milestones.
/// V2 equivalent of V1 EvolutionEngine, using ClaritySnapshot instead of CohesionSnapshot.
public enum MilestoneTracker: Sendable {

    // MARK: - Public API

    /// Full journey evaluation from clarity history.
    public static func evaluate(history: [ClaritySnapshot]) -> JourneySnapshot {
        let p = phase(history: history)
        let v = volatility(history: history)
        let t = trend(history: history)
        let n = narrative(for: p, isRegression: isRegression(history: history))

        return JourneySnapshot(
            phase: p,
            volatility: v,
            trend: t,
            narrative: n,
            snapshotCount: history.count
        )
    }

    /// Current journey phase based on score history.
    public static func phase(history: [ClaritySnapshot]) -> JourneyPhase {
        let count = history.count
        guard count > 0 else { return .building }

        let scores = history.map(\.score)
        let vol = volatility(history: history)

        // Check for regression first
        var candidatePhase = computePhase(count: count, scores: scores, vol: vol)
        if shouldRegress(scores: scores, vol: vol) {
            candidatePhase = regress(candidatePhase)
        }

        return candidatePhase
    }

    /// Population standard deviation of last 5 clarity scores.
    public static func volatility(history: [ClaritySnapshot]) -> Double {
        let scores = history.suffix(5).map(\.score)
        guard scores.count >= 2 else { return 0 }

        let mean = scores.reduce(0, +) / Double(scores.count)
        let variance = scores.map { ($0 - mean) * ($0 - mean) }.reduce(0, +) / Double(scores.count)
        return variance.squareRoot()
    }

    /// Trend from last 3 snapshots.
    public static func trend(history: [ClaritySnapshot]) -> JourneyTrend {
        let scores = history.suffix(3).map(\.score)
        guard scores.count >= 3 else { return .stable }

        let increasing = scores[1] >= scores[0] && scores[2] >= scores[1]
            && (scores[1] > scores[0] || scores[2] > scores[1])
        let decreasing = scores[1] <= scores[0] && scores[2] <= scores[1]
            && (scores[1] < scores[0] || scores[2] < scores[1])

        if increasing { return .improving }
        if decreasing { return .declining }
        return .stable
    }

    /// Classify volatility value into level.
    public static func volatilityLevel(from volatility: Double) -> JourneyVolatilityLevel {
        if volatility < 6 { return .low }
        if volatility <= 10 { return .medium }
        return .high
    }

    /// Momentum descriptor from trend × volatility level matrix.
    public static func momentum(history: [ClaritySnapshot]) -> JourneyMomentum {
        guard history.count >= 3 else {
            return JourneyMomentum(
                trend: .stable,
                volatilityLevel: .low,
                descriptor: "Structural Emergence"
            )
        }

        let t = trend(history: history)
        let v = volatility(history: history)
        let vl = volatilityLevel(from: v)
        let desc = momentumDescriptor(trend: t, volatilityLevel: vl)

        return JourneyMomentum(trend: t, volatilityLevel: vl, descriptor: desc)
    }

    /// Detect milestones from history.
    public static func milestones(history: [ClaritySnapshot]) -> [Milestone] {
        guard !history.isEmpty else { return [] }

        var results: [Milestone] = []

        // Journey started (first snapshot)
        results.append(Milestone(
            type: .journeyStarted,
            title: "Reisen startet",
            description: "Første strukturelle måling registrert.",
            snapshotIndex: 0
        ))

        var peakScore = history[0].score
        var previousPhase = computePhase(count: 1, scores: [history[0].score], vol: 0)

        for i in 1..<history.count {
            let score = history[i].score
            let scoresUpToNow = Array(history[0...i].map(\.score))
            let vol = volatilityForScores(Array(scoresUpToNow.suffix(5)))

            // Clarity peak
            if score > peakScore {
                peakScore = score
                results.append(Milestone(
                    type: .clarityPeak,
                    title: "Ny klarhetstop",
                    description: "Klarhet nådde \(Int(score.rounded())).",
                    snapshotIndex: i
                ))
            }

            // Archetype milestones (score crosses 60, 75, 90)
            let prevScore = history[i - 1].score
            for threshold in [60.0, 75.0, 90.0] {
                if prevScore < threshold && score >= threshold {
                    results.append(Milestone(
                        type: .archetypeMilestone,
                        title: "Klarhet passerte \(Int(threshold))",
                        description: "Strukturen nådde et nytt nivå.",
                        snapshotIndex: i
                    ))
                }
            }

            // Phase advancement
            let currentPhase = computePhase(count: i + 1, scores: scoresUpToNow, vol: vol)
            if phaseIndex(currentPhase) > phaseIndex(previousPhase) {
                results.append(Milestone(
                    type: .phaseAdvanced,
                    title: "Fase avansert",
                    description: "Reisen gikk videre til \(currentPhase.rawValue).",
                    snapshotIndex: i
                ))
            }
            previousPhase = currentPhase
        }

        return results
    }

    /// Score delta over a window of snapshots.
    public static func clarityDelta(history: [ClaritySnapshot], window: Int) -> Double {
        let windowed = Array(history.suffix(window))
        guard let first = windowed.first, let last = windowed.last, windowed.count >= 2 else {
            return 0
        }
        return last.score - first.score
    }

    // MARK: - Private Helpers

    private static func computePhase(count: Int, scores: [Double], vol: Double) -> JourneyPhase {
        // Evolving: 20+ snapshots, last 5 avg ≥ 80, volatility < 6
        if count >= 20 {
            let last5Avg = average(Array(scores.suffix(5)))
            if last5Avg >= 80 && vol < 6 { return .evolving }
        }

        // Cohering: 12+ snapshots, last 5 avg ≥ 70, volatility < 8
        if count >= 12 {
            let last5Avg = average(Array(scores.suffix(5)))
            if last5Avg >= 70 && vol < 8 { return .cohering }
        }

        // Refining: 7+ snapshots, last 3 avg ≥ 50, volatility < 10
        if count >= 7 {
            let last3Avg = average(Array(scores.suffix(3)))
            if last3Avg >= 50 && vol < 10 { return .refining }
        }

        // Developing: 3+ snapshots, latest ≥ 30
        if count >= 3 {
            if let latest = scores.last, latest >= 30 { return .developing }
        }

        return .building
    }

    private static func shouldRegress(scores: [Double], vol: Double) -> Bool {
        guard scores.count >= 5 else { return false }

        let last5 = Array(scores.suffix(5))
        let avg = average(last5)

        // Latest score drops > 15 from last 5 avg
        if let latest = scores.last, latest < avg - 15 { return true }

        // Volatility > 15
        if vol > 15 { return true }

        return false
    }

    private static func isRegression(history: [ClaritySnapshot]) -> Bool {
        let scores = history.map(\.score)
        let vol = volatility(history: history)
        return shouldRegress(scores: scores, vol: vol)
    }

    private static func regress(_ phase: JourneyPhase) -> JourneyPhase {
        switch phase {
        case .evolving: return .cohering
        case .cohering: return .refining
        case .refining: return .developing
        case .developing: return .building
        case .building: return .building
        }
    }

    private static func phaseIndex(_ phase: JourneyPhase) -> Int {
        switch phase {
        case .building: return 0
        case .developing: return 1
        case .refining: return 2
        case .cohering: return 3
        case .evolving: return 4
        }
    }

    private static func average(_ values: [Double]) -> Double {
        guard !values.isEmpty else { return 0 }
        return values.reduce(0, +) / Double(values.count)
    }

    private static func volatilityForScores(_ scores: [Double]) -> Double {
        guard scores.count >= 2 else { return 0 }
        let mean = scores.reduce(0, +) / Double(scores.count)
        let variance = scores.map { ($0 - mean) * ($0 - mean) }.reduce(0, +) / Double(scores.count)
        return variance.squareRoot()
    }

    private static func momentumDescriptor(trend: JourneyTrend, volatilityLevel: JourneyVolatilityLevel) -> String {
        switch (trend, volatilityLevel) {
        case (.improving, .low):    return "Upward Stability"
        case (.improving, .medium): return "Active Strengthening"
        case (.improving, .high):   return "Rapid Restructuring"
        case (.stable, .low):       return "Structural Consolidation"
        case (.stable, .medium):    return "Holding Pattern"
        case (.stable, .high):      return "Unstable Plateau"
        case (.declining, .low):    return "Gentle Recalibration"
        case (.declining, .medium): return "Gradual Loosening"
        case (.declining, .high):   return "Temporary Instability"
        }
    }

    private static func narrative(for phase: JourneyPhase, isRegression: Bool) -> String {
        if isRegression {
            return "Garderoben rekalibrerer. Dette er en del av prosessen."
        }
        switch phase {
        case .building:    return "Bygger garderobestrukturens fundament."
        case .developing:  return "Strukturen utvikler seg i en tydelig retning."
        case .refining:    return "Forfiner strukturell sammenheng på tvers av alle komponenter."
        case .cohering:    return "Sterk strukturell sammenheng vokser frem i garderoben."
        case .evolving:    return "Garderoben har nådd strukturell modenhet. Utvikler seg med intensjon."
        }
    }
}
