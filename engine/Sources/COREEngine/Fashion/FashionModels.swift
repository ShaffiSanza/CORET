import Foundation

// MARK: - Knowledge Base JSON Models

public struct FashionKnowledgeBase: Codable, Sendable {
    public let version: String
    public let modules: FashionModules
}

public struct FashionModules: Codable, Sendable {
    public let silhouette_rules: [FashionRule]
    public let color_theory: [FashionRule]
    public let outfit_theories: [FashionRule]
    public let archetypes: [FashionRule]
    public let trend_layer: [FashionRule]
    public let color_depth: [FashionRule]?
    public let season_logic: [FashionRule]?
    public let shoe_matching: [FashionRule]?
    public let accessory_boost: [FashionRule]?

    public var allRules: [FashionRule] {
        var rules: [FashionRule] = []
        rules.append(contentsOf: silhouette_rules)
        rules.append(contentsOf: color_theory)
        rules.append(contentsOf: outfit_theories)
        rules.append(contentsOf: archetypes)
        rules.append(contentsOf: trend_layer)
        rules.append(contentsOf: color_depth ?? [])
        rules.append(contentsOf: season_logic ?? [])
        rules.append(contentsOf: shoe_matching ?? [])
        rules.append(contentsOf: accessory_boost ?? [])
        return rules
    }
}

public struct FashionRule: Codable, Sendable, Identifiable {
    public let id: String
    public let condition: RuleCondition
    public let effect: RuleEffect
    public let confidence: Double
    public let explanation: RuleExplanation
}

public struct RuleCondition: Codable, Sendable {
    // Silhouette conditions
    public let upper_silhouette: [String]?
    public let lower_silhouette: [String]?
    // Color conditions
    public let has_warm: Bool?
    public let has_cool: Bool?
    public let has_neutral_bridge: Bool?
    public let all_same_temperature: Bool?
    public let all_similar_lightness: Bool?
    // Outfit theory conditions
    public let has_statement: Bool?
    public let other_pieces_simple: Bool?
    public let statement_count: ThresholdCondition?
    public let layer_count: ThresholdCondition?
    public let includes_outer: Bool?
    public let all_neutral_temp: Bool?
    // Archetype conditions
    public let profile_archetype: String?
    public let outfit_has: [String]?
    public let archetype_score_above: Double?
    // Color depth conditions
    public let all_dark: Bool?
    public let all_light: Bool?
    public let has_navy_and_black: Bool?
    // Season conditions
    public let has_outer_layer: Bool?
    public let has_shorts: Bool?
    public let has_heavy_outer: Bool?
    // Shoe conditions
    public let shoe_base_group: [String]?
    public let upper_base_group: [String]?
    // Accessory conditions
    public let has_accessory_type: [String]?
    public let accessory_count: ThresholdCondition?
}

public struct ThresholdCondition: Codable, Sendable {
    public let min: Int?
    public let max: Int?
}

public struct RuleEffect: Codable, Sendable {
    public let dimensions: [String: Double]
    public let tags: [String]
}

public struct RuleExplanation: Codable, Sendable {
    public let message_key: String
    public let type: String  // "negative", "positive", "neutral"
    public let variables: [String]  // language-agnostic keys, e.g. ["dominant_piece"]
}

// MARK: - Evaluation Results

public struct RuleResult: Identifiable, Codable, Sendable {
    public let id: String
    public let ruleID: String
    public let matched: Bool
    public let impact: Double  // net impact (sum of dimension effects)
    public let confidence: Double
    public let dimensions: [String: Double]
    public let tags: [String]
    public let messageKey: String
    public let messageType: String  // "negative", "positive", "neutral"
    public let variables: [String: String]  // language-agnostic keys → values

    public init(
        id: String = UUID().uuidString,
        ruleID: String,
        matched: Bool,
        impact: Double,
        confidence: Double,
        dimensions: [String: Double],
        tags: [String],
        messageKey: String,
        messageType: String = "neutral",
        variables: [String: String] = [:]
    ) {
        self.id = id
        self.ruleID = ruleID
        self.matched = matched
        self.impact = impact
        self.confidence = confidence
        self.dimensions = dimensions
        self.tags = tags
        self.messageKey = messageKey
        self.messageType = messageType
        self.variables = variables
    }
}

public struct ExplanationResult: Codable, Sendable {
    public let headline: String
    public let detail: String?
    public let fix: String?
    public let positives: [String]

    public init(
        headline: String,
        detail: String? = nil,
        fix: String? = nil,
        positives: [String] = []
    ) {
        self.headline = headline
        self.detail = detail
        self.fix = fix
        self.positives = positives
    }
}

public struct PrioritizedRules: Codable, Sendable {
    public let primaryIssue: RuleResult?
    public let secondaryIssue: RuleResult?
    public let primaryPositive: RuleResult?
    public let allMatched: [RuleResult]

    public init(
        primaryIssue: RuleResult? = nil,
        secondaryIssue: RuleResult? = nil,
        primaryPositive: RuleResult? = nil,
        allMatched: [RuleResult] = []
    ) {
        self.primaryIssue = primaryIssue
        self.secondaryIssue = secondaryIssue
        self.primaryPositive = primaryPositive
        self.allMatched = allMatched
    }
}
