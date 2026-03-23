import Foundation

public enum DailyOutfitScorer: Sendable {

    /// Scores an outfit and returns a UI-friendly breakdown.
    public static func scoreOutfit(garments: [Garment], profile: UserProfile) -> OutfitScore {
        guard !garments.isEmpty else {
            return OutfitScore()
        }

        let strength = CohesionEngine.outfitStrength(outfit: garments, profile: profile)
        let silhouetteVerdict = determineSilhouetteVerdict(garments: garments)
        let colorVerdict = determineColorVerdict(garments: garments)
        let archetypeMatch = dominantArchetype(garments: garments)
        let suggestion = strength < 0.85 ? generateSuggestion(garments: garments, profile: profile, currentStrength: strength) : nil

        // Fashion Intelligence — rule-based explanation
        let explanation = generateExplanation(garments: garments, profile: profile, strength: strength, archetype: archetypeMatch)

        return OutfitScore(
            totalStrength: strength,
            silhouetteVerdict: silhouetteVerdict,
            colorVerdict: colorVerdict,
            archetypeMatch: archetypeMatch,
            suggestion: suggestion,
            explanation: explanation
        )
    }

    // MARK: - Private

    private static func determineSilhouetteVerdict(garments: [Garment]) -> String {
        let uppers = garments.filter { $0.category == .upper && $0.silhouette != .none }
        let lowers = garments.filter { $0.category == .lower && $0.silhouette != .none }

        guard let upper = uppers.first, let lower = lowers.first else {
            return "Neutral"
        }

        let score = CohesionEngine.proportionScore(upper: upper.silhouette, lower: lower.silhouette)

        if score >= 0.8 {
            return "Balanced"
        } else if score >= 0.5 {
            return "Contrasting"
        } else {
            return "Uniform"
        }
    }

    private static func determineColorVerdict(garments: [Garment]) -> String {
        let temps = garments.map(\.colorTemperature)
        let hasWarm = temps.contains(.warm)
        let hasCool = temps.contains(.cool)

        if hasWarm && hasCool {
            return "Clashing"
        }
        return "Harmonious"
    }

    private static func dominantArchetype(garments: [Garment]) -> Archetype {
        let scores = CohesionEngine.allArchetypeScores(items: garments)
        return scores.max(by: { $0.value < $1.value })?.key ?? .smartCasual
    }

    private static func generateSuggestion(garments: [Garment], profile: UserProfile, currentStrength: Double) -> String? {
        // Find which component is weakest and suggest accordingly
        let temps = garments.map(\.colorTemperature)
        let hasWarm = temps.contains(.warm)
        let hasCool = temps.contains(.cool)

        if hasWarm && hasCool {
            return "Color temperatures clash. Try replacing the cool-toned piece with a neutral or warm alternative."
        }

        let uppers = garments.filter { $0.category == .upper && $0.silhouette != .none }
        let lowers = garments.filter { $0.category == .lower && $0.silhouette != .none }

        if let upper = uppers.first, let lower = lowers.first {
            let propScore = CohesionEngine.proportionScore(upper: upper.silhouette, lower: lower.silhouette)
            if propScore < 0.5 {
                return "Silhouette balance is weak. Try a more contrasting upper/lower pairing."
            }
        }

        if currentStrength < 0.65 {
            return "Archetype coherence is low. Try garments that align with your \(profile.primaryArchetype.rawValue) profile."
        }

        return nil
    }

    private static func generateExplanation(
        garments: [Garment],
        profile: UserProfile,
        strength: Double,
        archetype: Archetype,
        locale: String = "en"
    ) -> ExplanationResult? {
        guard let kb = FashionTheoryEngine.loadKnowledgeBase() else { return nil }
        let results = FashionTheoryEngine.evaluate(garments: garments, profile: profile, knowledgeBase: kb)
        guard !results.isEmpty else { return nil }
        let prioritized = RulePriorityEngine.prioritize(results)
        return ExplanationEngine.explain(prioritized: prioritized, score: strength, archetype: archetype, locale: locale)
    }
}
