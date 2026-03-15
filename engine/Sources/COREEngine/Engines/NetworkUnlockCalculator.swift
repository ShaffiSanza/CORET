import Foundation

public enum NetworkUnlockCalculator: Sendable {

    /// Calculates the structural impact of adding a garment to the wardrobe.
    public static func calculateUnlocks(adding garment: Garment, to items: [Garment], profile: UserProfile) -> UnlockResult {
        let outfitsBefore = ScoringHelpers.generateOutfits(from: items)
        let outfitsAfter = ScoringHelpers.generateOutfits(from: items + [garment])

        // Find new outfits by comparing ID sets
        let beforeSets = Set(outfitsBefore.map { Set($0.map(\.id)) })
        let newOutfits = outfitsAfter.filter { outfit in
            !beforeSets.contains(Set(outfit.map(\.id)))
        }

        // Score and rank the new outfits, take top 3
        let ranked = newOutfits.map { outfit -> RankedOutfit in
            let strength = CohesionEngine.outfitStrength(outfit: outfit, profile: profile)
            let scores = CohesionEngine.allArchetypeScores(items: outfit)
            let dominant = scores.max(by: { $0.value < $1.value })?.key ?? .smartCasual
            return RankedOutfit(
                garments: outfit,
                strength: strength,
                archetypeMatch: dominant,
                label: "\(dominant.rawValue.capitalized)"
            )
        }
        .sorted { $0.strength > $1.strength }

        let topNew = Array(ranked.prefix(3))

        // Get gaps filled from ScoreProjector
        let projection = ScoreProjector.project(adding: garment, to: items, profile: profile)

        return UnlockResult(
            newCombinationCount: newOutfits.count,
            topNewOutfits: topNew,
            gapsFilled: projection.gapsFilled
        )
    }
}
