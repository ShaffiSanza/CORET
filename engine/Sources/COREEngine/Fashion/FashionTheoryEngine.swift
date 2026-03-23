import Foundation

/// Loads knowledge_base.json and evaluates outfit against all fashion rules.
/// No hardcoded logic — all rules come from JSON.
public enum FashionTheoryEngine: Sendable {

    // MARK: - Knowledge Base Loading

    /// Load the bundled knowledge base.
    public static func loadKnowledgeBase() -> FashionKnowledgeBase? {
        guard let url = Bundle.module.url(forResource: "knowledge_base", withExtension: "json"),
              let data = try? Data(contentsOf: url),
              let kb = try? JSONDecoder().decode(FashionKnowledgeBase.self, from: data)
        else { return nil }
        return kb
    }

    /// Load knowledge base from raw JSON data (for testing).
    public static func loadKnowledgeBase(from data: Data) -> FashionKnowledgeBase? {
        try? JSONDecoder().decode(FashionKnowledgeBase.self, from: data)
    }

    // MARK: - Evaluation

    /// Evaluate an outfit against all rules in the knowledge base.
    public static func evaluate(
        garments: [Garment],
        profile: UserProfile,
        knowledgeBase: FashionKnowledgeBase
    ) -> [RuleResult] {
        let context = OutfitContext(garments: garments, profile: profile)
        return knowledgeBase.modules.allRules.compactMap { rule in
            let matched = matches(rule: rule, context: context)
            guard matched else { return nil }
            let impact = rule.effect.dimensions.values.reduce(0, +)
            let variables = buildVariables(rule: rule, context: context)
            return RuleResult(
                ruleID: rule.id,
                matched: true,
                impact: impact,
                confidence: rule.confidence,
                dimensions: rule.effect.dimensions,
                tags: rule.effect.tags,
                messageKey: rule.explanation.message_key,
                messageType: rule.explanation.type,
                variables: variables
            )
        }
    }

    // MARK: - Condition Matching

    private static func matches(rule: FashionRule, context: OutfitContext) -> Bool {
        let c = rule.condition

        // Silhouette conditions
        if let upperSils = c.upper_silhouette {
            guard context.upperSilhouettes.contains(where: { upperSils.contains($0.rawValue) }) else { return false }
        }
        if let lowerSils = c.lower_silhouette {
            guard context.lowerSilhouettes.contains(where: { lowerSils.contains($0.rawValue) }) else { return false }
        }

        // Color conditions
        if let hw = c.has_warm, hw != context.hasWarm { return false }
        if let hc = c.has_cool, hc != context.hasCool { return false }
        if let hnb = c.has_neutral_bridge, hnb != context.hasNeutralBridge { return false }
        if let ast = c.all_same_temperature, ast != context.allSameTemperature { return false }
        if let asl = c.all_similar_lightness, asl != context.allSimilarLightness { return false }

        // Outfit theory conditions
        if let hs = c.has_statement, hs != context.hasStatement { return false }
        if let ops = c.other_pieces_simple, ops != context.otherPiecesSimple { return false }
        if let sc = c.statement_count {
            if let min = sc.min, context.statementCount < min { return false }
            if let max = sc.max, context.statementCount > max { return false }
        }
        if let lc = c.layer_count {
            if let min = lc.min, context.layerCount < min { return false }
            if let max = lc.max, context.layerCount > max { return false }
        }
        if let io = c.includes_outer, io != context.includesOuter { return false }
        if let ant = c.all_neutral_temp, ant != context.allNeutralTemp { return false }

        // Archetype conditions
        if let pa = c.profile_archetype {
            guard pa == context.profileArchetype.rawValue else { return false }
        }
        if let oh = c.outfit_has {
            let baseGroups = Set(context.garments.map(\.baseGroup.rawValue))
            guard oh.allSatisfy({ baseGroups.contains($0) }) else { return false }
        }
        if let asa = c.archetype_score_above {
            let score = CohesionEngine.archetypeScore(items: context.garments, archetype: context.profileArchetype)
            guard score > asa else { return false }
        }

        // Color depth conditions
        if let ad = c.all_dark, ad != context.allDark { return false }
        if let al = c.all_light, al != context.allLight { return false }
        if let hnb = c.has_navy_and_black, hnb != context.hasNavyAndBlack { return false }

        // Season conditions
        if let hol = c.has_outer_layer, hol != context.hasOuterLayer { return false }
        if let hs = c.has_shorts, hs != context.hasShorts { return false }
        if let hho = c.has_heavy_outer, hho != context.hasHeavyOuter { return false }

        // Shoe conditions
        if let sbg = c.shoe_base_group {
            guard context.shoeBaseGroups.contains(where: { sbg.contains($0) }) else { return false }
        }
        if let ubg = c.upper_base_group {
            guard context.upperBaseGroups.contains(where: { ubg.contains($0) }) else { return false }
        }

        // Accessory conditions
        if let hat = c.has_accessory_type {
            guard hat.allSatisfy({ context.accessoryBaseGroups.contains($0) }) else { return false }
        }
        if let ac = c.accessory_count {
            if let min = ac.min, context.accessoryCount < min { return false }
            if let max = ac.max, context.accessoryCount > max { return false }
        }

        return true
    }

    // MARK: - Variable Building

    /// Build language-agnostic variable key-value pairs from outfit context.
    /// Variable values are baseGroup rawValues — I18nEngine localises them.
    private static func buildVariables(rule: FashionRule, context: OutfitContext) -> [String: String] {
        var vars: [String: String] = [:]
        for varName in rule.explanation.variables {
            switch varName {
            case "dominant_piece":
                // Strongest visual piece (coat > blazer > hoodie > shirt > tee)
                let priority: [BaseGroup] = [.coat, .blazer, .hoodie, .knit, .shirt, .tee]
                let dominant = context.garments.first { priority.contains($0.baseGroup) }
                vars["dominant_piece"] = dominant?.baseGroup.rawValue ?? "jacket"
            case "clashing_piece":
                // The piece most likely causing style conflict
                let casual: Set<BaseGroup> = [.hoodie, .sneakers, .shorts]
                let clashing = context.garments.first { casual.contains($0.baseGroup) }
                vars["clashing_piece"] = clashing?.baseGroup.rawValue ?? "hoodie"
            case "archetype":
                vars["archetype"] = context.profileArchetype.rawValue
            default:
                vars[varName] = varName
            }
        }
        return vars
    }
}

// MARK: - Outfit Context (pre-computed outfit properties)

private struct OutfitContext: Sendable {
    let garments: [Garment]
    let profileArchetype: Archetype

    let upperSilhouettes: [Silhouette]
    let lowerSilhouettes: [Silhouette]
    let hasWarm: Bool
    let hasCool: Bool
    let hasNeutral: Bool
    let hasNeutralBridge: Bool
    let allSameTemperature: Bool
    let allSimilarLightness: Bool
    let hasStatement: Bool
    let otherPiecesSimple: Bool
    let statementCount: Int
    let layerCount: Int
    let includesOuter: Bool
    let allNeutralTemp: Bool
    let allDark: Bool
    let allLight: Bool
    let hasNavyAndBlack: Bool
    let hasOuterLayer: Bool
    let hasShorts: Bool
    let hasHeavyOuter: Bool
    let shoeBaseGroups: [String]
    let upperBaseGroups: [String]
    let accessoryBaseGroups: Set<String>
    let accessoryCount: Int

    init(garments: [Garment], profile: UserProfile) {
        self.garments = garments
        self.profileArchetype = profile.primaryArchetype

        let uppers = garments.filter { $0.category == .upper }
        let lowers = garments.filter { $0.category == .lower }
        self.upperSilhouettes = uppers.map(\.silhouette).filter { $0 != .none }
        self.lowerSilhouettes = lowers.map(\.silhouette).filter { $0 != .none }

        let temps = garments.map(\.colorTemperature)
        self.hasWarm = temps.contains(.warm)
        self.hasCool = temps.contains(.cool)
        self.hasNeutral = temps.contains(.neutral)
        self.hasNeutralBridge = hasWarm && hasCool && temps.contains(.neutral)
        self.allSameTemperature = Set(temps).count == 1
        self.allNeutralTemp = temps.allSatisfy { $0 == .neutral }
        // Simplified: all similar lightness if all same temperature
        self.allSimilarLightness = allSameTemperature

        // Statement pieces: outerwear, blazer, or items with strong visual presence
        let statementGroups: Set<BaseGroup> = [.coat, .blazer]
        let statements = garments.filter { statementGroups.contains($0.baseGroup) }
        self.statementCount = statements.count
        self.hasStatement = statementCount >= 1
        let simpleGroups: Set<BaseGroup> = [.tee, .shirt, .jeans, .chinos, .trousers, .sneakers, .loafers, .boots]
        let others = garments.filter { !statementGroups.contains($0.baseGroup) }
        self.otherPiecesSimple = others.allSatisfy { simpleGroups.contains($0.baseGroup) }

        let categories = Set(garments.map(\.category))
        self.layerCount = categories.count
        self.includesOuter = garments.contains { $0.baseGroup == .coat || $0.baseGroup == .blazer }

        // Color depth
        let darkGroups: Set<String> = ["#1a1a1e", "#0e0c0a", "#1e2a3a", "#1a2030", "#100c14", "#2a2030"]
        let lightGroups: Set<String> = ["#f0ede8", "#e0dad0", "#f5f0ea", "#c4b89a", "#e8d8c0"]
        let colors = garments.map { $0.dominantColor.lowercased() }
        self.allDark = !colors.isEmpty && colors.allSatisfy { c in darkGroups.contains(c) || c.hasPrefix("#1") || c.hasPrefix("#0") || c.hasPrefix("#2") }
        self.allLight = !colors.isEmpty && colors.allSatisfy { c in lightGroups.contains(c) || c.hasPrefix("#c") || c.hasPrefix("#d") || c.hasPrefix("#e") || c.hasPrefix("#f") }
        let hasNavy = colors.contains { $0.hasPrefix("#1e2") || $0.hasPrefix("#1a1c") || $0.hasPrefix("#1e1") }
        let hasBlack = colors.contains { $0.hasPrefix("#1a1a") || $0.hasPrefix("#0e0") || $0.hasPrefix("#100") }
        self.hasNavyAndBlack = hasNavy && hasBlack

        // Season
        self.hasOuterLayer = garments.contains { $0.baseGroup == .coat }
        self.hasShorts = garments.contains { $0.baseGroup == .shorts }
        self.hasHeavyOuter = garments.contains { $0.baseGroup == .coat }

        // Shoes + uppers base groups
        self.shoeBaseGroups = garments.filter { $0.category == .shoes }.map(\.baseGroup.rawValue)
        self.upperBaseGroups = uppers.map(\.baseGroup.rawValue)

        // Accessories
        let accessories = garments.filter { $0.category == .accessory }
        self.accessoryBaseGroups = Set(accessories.map(\.baseGroup.rawValue))
        self.accessoryCount = accessories.count
    }
}

