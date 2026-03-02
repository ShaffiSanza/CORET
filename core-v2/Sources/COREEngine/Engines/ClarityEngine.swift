import Foundation

public enum ClarityEngine: Sendable {

    /// Compute clarity snapshot from wardrobe state.
    ///
    /// Formula:
    /// ```
    /// clarityBase = primaryArchetypeScore * 0.60 + cohesionTotal * 0.40
    /// breadthBonus = if bestSecondary > 50: min((secondary - 50) * 0.1, 5.0), else 0
    /// clarityScore = min(clarityBase + breadthBonus, 100)
    /// ```
    public static func compute(items: [Garment], profile: UserProfile) -> ClaritySnapshot {
        guard !items.isEmpty else {
            return ClaritySnapshot(
                score: 0,
                band: .fragmentert,
                archetypeScores: [.tailored: 0, .smartCasual: 0, .street: 0],
                dominantArchetype: profile.primaryArchetype,
                cohesionBreakdown: CohesionBreakdown()
            )
        }

        let breakdown = CohesionEngine.compute(items: items, profile: profile)
        let archetypeScores = CohesionEngine.allArchetypeScores(items: items)

        let primaryScore = archetypeScores[profile.primaryArchetype] ?? 0
        let cohesionTotal = breakdown.totalScore

        let clarityBase = primaryScore * 0.60 + cohesionTotal * 0.40

        // Breadth bonus: best secondary archetype above 50
        let secondaryScores = archetypeScores.filter { $0.key != profile.primaryArchetype }
        let bestSecondary = secondaryScores.values.max() ?? 0
        let breadthBonus: Double = bestSecondary > 50 ? min((bestSecondary - 50) * 0.1, 5.0) : 0

        let clarityScore = min(clarityBase + breadthBonus, 100)

        // Dominant = highest scoring archetype
        let dominant = archetypeScores.max(by: { $0.value < $1.value })?.key ?? profile.primaryArchetype

        return ClaritySnapshot(
            score: clarityScore,
            band: band(from: clarityScore),
            archetypeScores: archetypeScores,
            dominantArchetype: dominant,
            cohesionBreakdown: breakdown
        )
    }

    /// Map score to clarity band.
    public static func band(from score: Double) -> ClarityBand {
        switch score {
        case ..<30:    return .fragmentert
        case 30..<60:  return .iUtvikling
        case 60..<85:  return .fokusert
        default:       return .krystallklar
        }
    }

    /// Detect trend from snapshot history.
    /// Last 3 snapshots: monotonic increase → improving, monotonic decrease → declining, else stable.
    /// < 3 snapshots → stable.
    public static func trend(history: [ClaritySnapshot]) -> ClarityTrend {
        guard history.count >= 3 else { return .stable }

        let last3 = history.suffix(3).map(\.score)

        let improving = last3[last3.startIndex] <= last3[last3.index(after: last3.startIndex)]
            && last3[last3.index(after: last3.startIndex)] <= last3[last3.index(last3.startIndex, offsetBy: 2)]
        if improving && last3[last3.startIndex] < last3[last3.index(last3.startIndex, offsetBy: 2)] {
            return .improving
        }

        let declining = last3[last3.startIndex] >= last3[last3.index(after: last3.startIndex)]
            && last3[last3.index(after: last3.startIndex)] >= last3[last3.index(last3.startIndex, offsetBy: 2)]
        if declining && last3[last3.startIndex] > last3[last3.index(last3.startIndex, offsetBy: 2)] {
            return .declining
        }

        return .stable
    }
}
