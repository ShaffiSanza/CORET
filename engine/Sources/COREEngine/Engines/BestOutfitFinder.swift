import Foundation

public enum BestOutfitFinder: Sendable {

    /// Returns the top N strongest outfits from the wardrobe.
    public static func findBest(items: [Garment], profile: UserProfile, count: Int = 5) -> [RankedOutfit] {
        let outfits = ScoringHelpers.generateOutfits(from: items)
        guard !outfits.isEmpty else { return [] }

        let ranked = outfits.map { outfit in
            makeRankedOutfit(outfit: outfit, profile: profile)
        }
        .sorted { $0.strength > $1.strength }

        return Array(ranked.prefix(count))
    }

    /// Returns the top N strongest outfits the user hasn't worn yet.
    public static func findUntriedBest(items: [Garment], wornOutfits: Set<Set<UUID>>, profile: UserProfile, count: Int = 5) -> [RankedOutfit] {
        let outfits = ScoringHelpers.generateOutfits(from: items)
        guard !outfits.isEmpty else { return [] }

        let untried = outfits.filter { outfit in
            let ids = Set(outfit.map(\.id))
            return !wornOutfits.contains(ids)
        }

        let ranked = untried.map { outfit in
            makeRankedOutfit(outfit: outfit, profile: profile)
        }
        .sorted { $0.strength > $1.strength }

        return Array(ranked.prefix(count))
    }

    // MARK: - Private

    private static func makeRankedOutfit(outfit: [Garment], profile: UserProfile) -> RankedOutfit {
        let strength = CohesionEngine.outfitStrength(outfit: outfit, profile: profile)
        let scores = CohesionEngine.allArchetypeScores(items: outfit)
        let dominant = scores.max(by: { $0.value < $1.value })?.key ?? .smartCasual
        let label = generateLabel(outfit: outfit, archetype: dominant)

        return RankedOutfit(
            garments: outfit,
            strength: strength,
            archetypeMatch: dominant,
            label: label
        )
    }

    private static func generateLabel(outfit: [Garment], archetype: Archetype) -> String {
        let archetypeName: String
        switch archetype {
        case .tailored: archetypeName = "Tailored"
        case .smartCasual: archetypeName = "Smart Casual"
        case .street: archetypeName = "Street"
        }

        let temps = outfit.map(\.colorTemperature)
        let hasWarm = temps.contains(.warm)
        let hasCool = temps.contains(.cool)

        let tempLabel: String
        if hasWarm && !hasCool {
            tempLabel = "Warm Tones"
        } else if hasCool && !hasWarm {
            tempLabel = "Cool Tones"
        } else {
            tempLabel = "Neutral"
        }

        return "\(archetypeName) \u{00B7} \(tempLabel)"
    }
}
