import Foundation

/// Analyzes how far the user's wardrobe is from a target archetype
/// and suggests specific additions to move toward it.
public enum StyleDirectionEngine: Sendable {

    /// A single suggestion to move toward the target archetype.
    public struct DirectionSuggestion: Identifiable, Codable, Sendable {
        public let id: UUID
        public let baseGroup: BaseGroup
        public let category: Category
        public let affinity: Double
        public let label: String

        public init(
            id: UUID = UUID(),
            baseGroup: BaseGroup,
            category: Category,
            affinity: Double,
            label: String
        ) {
            self.id = id
            self.baseGroup = baseGroup
            self.category = category
            self.affinity = affinity
            self.label = label
        }
    }

    /// Full analysis result for a target archetype direction.
    public struct DirectionAnalysis: Identifiable, Codable, Sendable {
        public let id: UUID
        public let targetArchetype: Archetype
        public let currentScore: Double
        public let projectedScore: Double
        public let suggestions: [DirectionSuggestion]
        public let existingMatches: Int
        public let totalGarments: Int
        public let createdAt: Date

        public init(
            id: UUID = UUID(),
            targetArchetype: Archetype,
            currentScore: Double,
            projectedScore: Double,
            suggestions: [DirectionSuggestion],
            existingMatches: Int,
            totalGarments: Int,
            createdAt: Date = Date()
        ) {
            self.id = id
            self.targetArchetype = targetArchetype
            self.currentScore = currentScore
            self.projectedScore = projectedScore
            self.suggestions = suggestions
            self.existingMatches = existingMatches
            self.totalGarments = totalGarments
            self.createdAt = createdAt
        }
    }

    /// Analyze how far the wardrobe is from the target archetype
    /// and what to add to move toward it.
    public static func analyzeDirection(
        items: [Garment],
        profile: UserProfile,
        target: Archetype,
        suggestionLimit: Int = 5
    ) -> DirectionAnalysis {
        guard !items.isEmpty else {
            return DirectionAnalysis(
                targetArchetype: target,
                currentScore: 0,
                projectedScore: 0,
                suggestions: generateSuggestions(existing: [], target: target, limit: suggestionLimit),
                existingMatches: 0,
                totalGarments: 0
            )
        }

        // Current archetype scores
        let scores = CohesionEngine.allArchetypeScores(items: items)
        let currentScore = scores[target] ?? 0

        // Count existing garments that already align with target
        let existingMatches = items.filter { garment in
            CohesionEngine.archetypeAffinity(baseGroup: garment.baseGroup, archetype: target) >= 0.7
        }.count

        // Generate suggestions for base groups that would boost the target
        let suggestions = generateSuggestions(existing: items, target: target, limit: suggestionLimit)

        // Project score if all suggestions were added
        let projectedScore = projectScore(items: items, suggestions: suggestions, target: target)

        return DirectionAnalysis(
            targetArchetype: target,
            currentScore: currentScore,
            projectedScore: projectedScore,
            suggestions: suggestions,
            existingMatches: existingMatches,
            totalGarments: items.count
        )
    }

    // MARK: - Private

    private static func generateSuggestions(existing: [Garment], target: Archetype, limit: Int) -> [DirectionSuggestion] {
        let existingBaseGroups = Set(existing.map(\.baseGroup))

        // Score all base groups by their affinity to the target archetype
        // Prioritize base groups the user doesn't already have
        var candidates: [(baseGroup: BaseGroup, category: Category, affinity: Double, isNew: Bool)] = []

        for baseGroup in BaseGroup.allCases {
            let affinity = CohesionEngine.archetypeAffinity(baseGroup: baseGroup, archetype: target)
            guard affinity >= 0.5 else { continue }

            let category = categoryFor(baseGroup: baseGroup)
            let isNew = !existingBaseGroups.contains(baseGroup)

            candidates.append((baseGroup, category, affinity, isNew))
        }

        // Sort: new base groups first, then by affinity descending
        let sorted = candidates.sorted { a, b in
            if a.isNew != b.isNew { return a.isNew }
            return a.affinity > b.affinity
        }

        return sorted.prefix(limit).map { candidate in
            let label: String
            switch target {
            case .tailored:
                label = "Add \(candidate.baseGroup.rawValue) for Tailored structure"
            case .smartCasual:
                label = "Add \(candidate.baseGroup.rawValue) for Smart Casual versatility"
            case .street:
                label = "Add \(candidate.baseGroup.rawValue) for Street edge"
            }

            return DirectionSuggestion(
                baseGroup: candidate.baseGroup,
                category: candidate.category,
                affinity: candidate.affinity,
                label: label
            )
        }
    }

    private static func projectScore(items: [Garment], suggestions: [DirectionSuggestion], target: Archetype) -> Double {
        // Create hypothetical garments for each suggestion
        var hypothetical = items
        for suggestion in suggestions {
            let garment = Garment(
                category: suggestion.category,
                baseGroup: suggestion.baseGroup
            )
            hypothetical.append(garment)
        }

        let scores = CohesionEngine.allArchetypeScores(items: hypothetical)
        return scores[target] ?? 0
    }

    private static func categoryFor(baseGroup: BaseGroup) -> Category {
        switch baseGroup {
        case .tee, .shirt, .knit, .hoodie, .blazer, .coat:
            return .upper
        case .jeans, .chinos, .trousers, .shorts, .skirt:
            return .lower
        case .sneakers, .boots, .loafers, .sandals:
            return .shoes
        case .belt, .scarf, .cap, .bag:
            return .accessory
        }
    }
}
