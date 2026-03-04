import Foundation

// MARK: - Types

public enum GapType: String, Codable, CaseIterable, Sendable {
    case missingLayer, proportionImbalance, archetypeWeakness, categoryGap
}

public enum GapPriority: String, Codable, CaseIterable, Sendable {
    case high, medium, low
}

public struct GapSuggestion: Identifiable, Codable, Sendable {
    public let id: UUID
    public let candidate: Garment
    public let clarityDelta: Double
    public let label: String

    public init(
        id: UUID = UUID(),
        candidate: Garment,
        clarityDelta: Double,
        label: String
    ) {
        self.id = id
        self.candidate = candidate
        self.clarityDelta = clarityDelta
        self.label = label
    }
}

public struct StructuralGap: Identifiable, Codable, Sendable {
    public let id: UUID
    public let type: GapType
    public let priority: GapPriority
    public let title: String
    public let description: String
    public let suggestions: [GapSuggestion]

    public init(
        id: UUID = UUID(),
        type: GapType,
        priority: GapPriority,
        title: String,
        description: String,
        suggestions: [GapSuggestion]
    ) {
        self.id = id
        self.type = type
        self.priority = priority
        self.title = title
        self.description = description
        self.suggestions = suggestions
    }
}

public struct GarmentFriction: Identifiable, Codable, Sendable {
    public let id: UUID
    public let garment: Garment
    public let clarityBefore: Double
    public let clarityAfter: Double
    public let clarityImprovement: Double

    public init(
        id: UUID = UUID(),
        garment: Garment,
        clarityBefore: Double,
        clarityAfter: Double,
        clarityImprovement: Double
    ) {
        self.id = id
        self.garment = garment
        self.clarityBefore = clarityBefore
        self.clarityAfter = clarityAfter
        self.clarityImprovement = clarityImprovement
    }
}

public struct GapResult: Identifiable, Codable, Sendable {
    public let id: UUID
    public let currentClarity: Double
    public let gaps: [StructuralGap]
    public let friction: [GarmentFriction]

    public init(
        id: UUID = UUID(),
        currentClarity: Double,
        gaps: [StructuralGap],
        friction: [GarmentFriction]
    ) {
        self.id = id
        self.currentClarity = currentClarity
        self.gaps = gaps
        self.friction = friction
    }
}

// MARK: - Engine

/// Gap-based optimization engine. Detects structural gaps and generates concrete suggestions.
public enum OptimizeEngineV2: Sendable {

    // MARK: - Public API

    /// Full analysis: detect gaps, generate suggestions, detect friction.
    public static func analyze(items: [Garment], profile: UserProfile) -> GapResult {
        let clarity = items.isEmpty ? 0 : ClarityEngine.compute(items: items, profile: profile).score
        let gaps = detectGaps(items: items, profile: profile)
        let friction = detectFriction(items: items, profile: profile)

        return GapResult(
            currentClarity: clarity,
            gaps: gaps,
            friction: friction
        )
    }

    /// Detect structural gaps and generate up to 2 suggestions per gap.
    public static func detectGaps(items: [Garment], profile: UserProfile) -> [StructuralGap] {
        var gaps: [StructuralGap] = []

        // Category gaps
        gaps.append(contentsOf: detectCategoryGaps(items: items, profile: profile))

        // Layer gaps
        gaps.append(contentsOf: detectLayerGaps(items: items, profile: profile))

        // Proportion imbalance
        if let proportionGap = detectProportionImbalance(items: items, profile: profile) {
            gaps.append(proportionGap)
        }

        // Archetype weakness
        if let archetypeGap = detectArchetypeWeakness(items: items, profile: profile) {
            gaps.append(archetypeGap)
        }

        // Sort: high > medium > low, then by best suggestion delta descending
        return gaps.sorted { a, b in
            let ap = priorityOrder(a.priority)
            let bp = priorityOrder(b.priority)
            if ap != bp { return ap < bp }
            let aDelta = a.suggestions.first?.clarityDelta ?? 0
            let bDelta = b.suggestions.first?.clarityDelta ?? 0
            return aDelta > bDelta
        }
    }

    /// Detect garments whose removal improves clarity by > 8.
    public static func detectFriction(items: [Garment], profile: UserProfile) -> [GarmentFriction] {
        guard !items.isEmpty else { return [] }

        let currentClarity = ClarityEngine.compute(items: items, profile: profile).score

        var frictions: [GarmentFriction] = []
        for item in items {
            let remaining = items.filter { $0.id != item.id }
            let afterClarity = remaining.isEmpty ? 0 : ClarityEngine.compute(items: remaining, profile: profile).score
            let improvement = afterClarity - currentClarity

            if improvement > 8.0 {
                frictions.append(GarmentFriction(
                    garment: item,
                    clarityBefore: currentClarity,
                    clarityAfter: afterClarity,
                    clarityImprovement: improvement
                ))
            }
        }

        return frictions.sorted { $0.clarityImprovement > $1.clarityImprovement }
    }

    // MARK: - Gap Detection: Categories

    private static func detectCategoryGaps(items: [Garment], profile: UserProfile) -> [StructuralGap] {
        let requiredCategories: [Category] = [.upper, .lower, .shoes]
        var gaps: [StructuralGap] = []

        for category in requiredCategories {
            let count = items.filter { $0.category == category }.count
            if count == 0 {
                let suggestions = categorySuggestions(category: category, items: items, profile: profile)
                gaps.append(StructuralGap(
                    type: .categoryGap,
                    priority: .high,
                    title: "Mangler \(categoryLabel(category))",
                    description: "Ingen \(categoryLabel(category).lowercased()) i garderoben.",
                    suggestions: suggestions
                ))
            }
        }

        return gaps
    }

    // MARK: - Gap Detection: Layers

    private static func detectLayerGaps(items: [Garment], profile: UserProfile) -> [StructuralGap] {
        let uppers = items.filter { $0.category == .upper }
        guard !uppers.isEmpty else { return [] } // Category gap will cover missing uppers

        var gaps: [StructuralGap] = []
        let layers: [(Int, String, GapPriority)] = [
            (1, "ytterlag", .high),
            (2, "mellomlag", .high),
            (3, "baselag", .medium),
        ]

        for (layer, label, priority) in layers {
            let count = uppers.filter { $0.temperature == layer }.count
            if count == 0 {
                let suggestions = layerSuggestions(layer: layer, items: items, profile: profile)
                gaps.append(StructuralGap(
                    type: .missingLayer,
                    priority: priority,
                    title: "Mangler \(label)",
                    description: "Ingen plagg i lag \(layer) (\(label)).",
                    suggestions: suggestions
                ))
            }
        }

        return gaps
    }

    // MARK: - Gap Detection: Proportion Imbalance

    private static func detectProportionImbalance(items: [Garment], profile: UserProfile) -> StructuralGap? {
        let upperCount = items.filter { $0.category == .upper }.count
        let lowerCount = items.filter { $0.category == .lower }.count
        guard upperCount > 0 && lowerCount > 0 else { return nil }

        let ratio = Double(upperCount) / Double(lowerCount)
        let (idealLower, idealUpper) = archetypeIdealRatio(profile.primaryArchetype)
        let tolerance = 0.5

        let isImbalanced = ratio < (idealLower - tolerance) || ratio > (idealUpper + tolerance)
        guard isImbalanced else { return nil }

        let needsMoreUppers = ratio < idealLower
        let suggestions: [GapSuggestion]
        if needsMoreUppers {
            suggestions = proportionSuggestions(category: .upper, items: items, profile: profile)
        } else {
            suggestions = proportionSuggestions(category: .lower, items: items, profile: profile)
        }

        return StructuralGap(
            type: .proportionImbalance,
            priority: .medium,
            title: "Proporsjons-ubalanse",
            description: needsMoreUppers
                ? "For få overdeler i forhold til underdeler."
                : "For mange overdeler i forhold til underdeler.",
            suggestions: suggestions
        )
    }

    // MARK: - Gap Detection: Archetype Weakness

    private static func detectArchetypeWeakness(items: [Garment], profile: UserProfile) -> StructuralGap? {
        guard !items.isEmpty else { return nil }
        let score = CohesionEngine.archetypeScore(items: items, archetype: profile.primaryArchetype)
        guard score < 50 else { return nil }

        let priority: GapPriority = score < 30 ? .high : .medium
        let suggestions = archetypeSuggestions(items: items, profile: profile)

        return StructuralGap(
            type: .archetypeWeakness,
            priority: priority,
            title: "Svak arketypeprofil",
            description: "Primær arketype (\(profile.primaryArchetype.rawValue)) scorer under 50.",
            suggestions: suggestions
        )
    }

    // MARK: - Suggestion Generation

    private static func categorySuggestions(category: Category, items: [Garment], profile: UserProfile) -> [GapSuggestion] {
        let baseGroups = baseGroupsForCategory(category, archetype: profile.primaryArchetype)
        return buildSuggestions(baseGroups: baseGroups, category: category, items: items, profile: profile)
    }

    private static func layerSuggestions(layer: Int, items: [Garment], profile: UserProfile) -> [GapSuggestion] {
        let baseGroups: [BaseGroup]
        switch layer {
        case 1: baseGroups = [.coat, .blazer]
        case 2: baseGroups = [.knit, .hoodie]
        case 3: baseGroups = [.tee, .shirt]
        default: baseGroups = [.shirt]
        }
        return buildSuggestions(
            baseGroups: baseGroups,
            category: .upper,
            temperature: layer,
            items: items,
            profile: profile
        )
    }

    private static func proportionSuggestions(category: Category, items: [Garment], profile: UserProfile) -> [GapSuggestion] {
        let baseGroups = baseGroupsForCategory(category, archetype: profile.primaryArchetype)
        return buildSuggestions(baseGroups: baseGroups, category: category, items: items, profile: profile)
    }

    private static func archetypeSuggestions(items: [Garment], profile: UserProfile) -> [GapSuggestion] {
        // Find baseGroups with highest affinity for primary archetype, not already well-represented
        let existingBaseGroups = Set(items.map(\.baseGroup))
        var candidates: [(BaseGroup, Double)] = []
        for bg in BaseGroup.allCases {
            let affinity = CohesionEngine.archetypeAffinity(baseGroup: bg, archetype: profile.primaryArchetype)
            if affinity >= 0.7 && !existingBaseGroups.contains(bg) {
                candidates.append((bg, affinity))
            }
        }
        candidates.sort { $0.1 > $1.1 }
        let topBaseGroups = Array(candidates.prefix(2).map(\.0))

        guard !topBaseGroups.isEmpty else { return [] }

        return topBaseGroups.compactMap { bg in
            let category = categoryForBaseGroup(bg)
            let candidate = makeSyntheticGarment(baseGroup: bg, category: category, profile: profile)
            let projection = ScoreProjector.project(adding: candidate, to: items, profile: profile)
            return GapSuggestion(
                candidate: candidate,
                clarityDelta: projection.clarityDelta,
                label: "Styrker \(profile.primaryArchetype.rawValue)-profil"
            )
        }
    }

    private static func buildSuggestions(
        baseGroups: [BaseGroup],
        category: Category,
        temperature: Int? = nil,
        items: [Garment],
        profile: UserProfile
    ) -> [GapSuggestion] {
        let limited = Array(baseGroups.prefix(2))
        return limited.map { bg in
            let candidate = makeSyntheticGarment(
                baseGroup: bg,
                category: category,
                temperature: temperature,
                profile: profile
            )
            let projection = ScoreProjector.project(adding: candidate, to: items, profile: profile)
            return GapSuggestion(
                candidate: candidate,
                clarityDelta: projection.clarityDelta,
                label: labelForGap(baseGroup: bg)
            )
        }
    }

    // MARK: - Synthetic Garment Generation

    private static func makeSyntheticGarment(
        baseGroup: BaseGroup,
        category: Category,
        temperature: Int? = nil,
        profile: UserProfile
    ) -> Garment {
        let silhouette = defaultSilhouette(for: category)
        let temp: Int? = category == .upper ? (temperature ?? 3) : nil

        return Garment(
            category: category,
            silhouette: silhouette,
            baseGroup: baseGroup,
            temperature: temp,
            colorTemperature: .neutral
        )
    }

    // MARK: - Lookup Helpers

    private static func baseGroupsForCategory(_ category: Category, archetype: Archetype) -> [BaseGroup] {
        switch (category, archetype) {
        case (.upper, .tailored):    return [.shirt, .blazer]
        case (.upper, .smartCasual): return [.knit, .shirt]
        case (.upper, .street):      return [.tee, .hoodie]
        case (.lower, .tailored):    return [.trousers, .chinos]
        case (.lower, .smartCasual): return [.chinos, .jeans]
        case (.lower, .street):      return [.jeans, .shorts]
        case (.shoes, .tailored):    return [.loafers, .boots]
        case (.shoes, .smartCasual): return [.loafers, .sneakers]
        case (.shoes, .street):      return [.sneakers, .boots]
        case (.accessory, _):        return [.belt, .scarf]
        }
    }

    private static func categoryForBaseGroup(_ bg: BaseGroup) -> Category {
        switch bg {
        case .tee, .shirt, .knit, .hoodie, .blazer, .coat: return .upper
        case .jeans, .chinos, .trousers, .shorts, .skirt: return .lower
        case .sneakers, .boots, .loafers, .sandals: return .shoes
        case .belt, .scarf, .cap, .bag: return .accessory
        }
    }

    private static func defaultSilhouette(for category: Category) -> Silhouette {
        switch category {
        case .upper: return .fitted
        case .lower: return .regular
        case .shoes: return .none
        case .accessory: return .none
        }
    }

    private static func archetypeIdealRatio(_ archetype: Archetype) -> (Double, Double) {
        switch archetype {
        case .tailored:    return (1.5, 2.5)
        case .smartCasual: return (1.2, 2.0)
        case .street:      return (1.0, 1.5)
        }
    }

    private static func categoryLabel(_ category: Category) -> String {
        switch category {
        case .upper: return "Overdeler"
        case .lower: return "Underdeler"
        case .shoes: return "Sko"
        case .accessory: return "Tilbehør"
        }
    }

    private static func labelForGap(baseGroup: BaseGroup) -> String {
        "Legg til \(baseGroup.rawValue)"
    }

    private static func priorityOrder(_ priority: GapPriority) -> Int {
        switch priority {
        case .high: return 0
        case .medium: return 1
        case .low: return 2
        }
    }
}
