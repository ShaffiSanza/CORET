import Foundation

public enum ScoreProjector: Sendable {

    /// Project the impact of adding a garment to the wardrobe.
    public static func project(adding garment: Garment, to items: [Garment], profile: UserProfile) -> ProjectionResult {
        let before = ClarityEngine.compute(items: items, profile: profile)
        let after = ClarityEngine.compute(items: items + [garment], profile: profile)

        let outfitsBefore = CohesionEngine.outfitCount(items: items)
        let outfitsAfter = CohesionEngine.outfitCount(items: items + [garment])

        let gapsFilled = detectGapsFilled(before: items, after: items + [garment])
        let gapsOpened: [String] = []  // Adding never opens gaps

        return ProjectionResult(
            clarityBefore: before.score,
            clarityAfter: after.score,
            clarityDelta: after.score - before.score,
            archetypesBefore: before.archetypeScores,
            archetypesAfter: after.archetypeScores,
            combinationsGained: max(0, outfitsAfter - outfitsBefore),
            combinationsLost: 0,
            gapsFilled: gapsFilled,
            gapsOpened: gapsOpened,
            breakdownBefore: before.cohesionBreakdown,
            breakdownAfter: after.cohesionBreakdown
        )
    }

    /// Project the impact of removing a garment from the wardrobe.
    public static func reverseProject(removing garment: Garment, from items: [Garment], profile: UserProfile) -> ProjectionResult {
        let before = ClarityEngine.compute(items: items, profile: profile)
        let remaining = items.filter { $0.id != garment.id }
        let after = ClarityEngine.compute(items: remaining, profile: profile)

        let outfitsBefore = CohesionEngine.outfitCount(items: items)
        let outfitsAfter = CohesionEngine.outfitCount(items: remaining)

        let gapsFilled: [String] = []  // Removing never fills gaps
        let gapsOpened = detectGapsOpened(before: items, after: remaining)

        return ProjectionResult(
            clarityBefore: before.score,
            clarityAfter: after.score,
            clarityDelta: after.score - before.score,
            archetypesBefore: before.archetypeScores,
            archetypesAfter: after.archetypeScores,
            combinationsGained: 0,
            combinationsLost: max(0, outfitsBefore - outfitsAfter),
            gapsFilled: gapsFilled,
            gapsOpened: gapsOpened,
            breakdownBefore: before.cohesionBreakdown,
            breakdownAfter: after.cohesionBreakdown
        )
    }

    // MARK: - Gap Detection

    /// Detects structural gaps filled by adding items.
    /// A gap is a category or layer that had 0 items and now has ≥ 1.
    private static func detectGapsFilled(before: [Garment], after: [Garment]) -> [String] {
        var gaps: [String] = []

        // Category gaps
        for category in Category.allCases {
            let hadBefore = before.contains { $0.category == category }
            let hasAfter = after.contains { $0.category == category }
            if !hadBefore && hasAfter {
                gaps.append("category:\(category.rawValue)")
            }
        }

        // Layer gaps (for uppers)
        for layer in 1...3 {
            let hadBefore = before.contains { $0.category == .upper && $0.temperature == layer }
            let hasAfter = after.contains { $0.category == .upper && $0.temperature == layer }
            if !hadBefore && hasAfter {
                gaps.append("layer:\(layer)")
            }
        }

        return gaps
    }

    /// Detects structural gaps opened by removing items.
    private static func detectGapsOpened(before: [Garment], after: [Garment]) -> [String] {
        var gaps: [String] = []

        for category in Category.allCases {
            let hadBefore = before.contains { $0.category == category }
            let hasAfter = after.contains { $0.category == category }
            if hadBefore && !hasAfter {
                gaps.append("category:\(category.rawValue)")
            }
        }

        for layer in 1...3 {
            let hadBefore = before.contains { $0.category == .upper && $0.temperature == layer }
            let hasAfter = after.contains { $0.category == .upper && $0.temperature == layer }
            if hadBefore && !hasAfter {
                gaps.append("layer:\(layer)")
            }
        }

        return gaps
    }
}
