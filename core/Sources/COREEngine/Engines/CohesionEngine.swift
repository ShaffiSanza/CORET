import Foundation

// MARK: - Item Contribution Types

public enum CohesionComponent: String, Codable, CaseIterable, Sendable {
    case alignment
    case density
    case palette
    case rotation
}

public enum AlignmentMatchType: String, Codable, CaseIterable, Sendable {
    case primary
    case secondary
    case neutral
    case conflict
}

public enum ParticipationLevel: String, Codable, CaseIterable, Sendable {
    case high
    case low
}

public enum PaletteRole: String, Codable, CaseIterable, Sendable {
    case balanced
    case excessAccent
    case temperatureClash
}

public enum UsageLevel: String, Codable, CaseIterable, Sendable {
    case even
    case overused
    case underused
}

public enum ContributionContext: Sendable, Equatable {
    case alignment(AlignmentMatchType)
    case density(ParticipationLevel)
    case palette(PaletteRole)
    case rotation(UsageLevel)
}

public struct ItemContribution: Identifiable, Sendable {
    public let id: UUID
    public let itemID: UUID
    public let component: CohesionComponent
    public let contributionScore: Double
    public let context: ContributionContext

    public init(
        id: UUID = UUID(),
        itemID: UUID,
        component: CohesionComponent,
        contributionScore: Double,
        context: ContributionContext
    ) {
        self.id = id
        self.itemID = itemID
        self.component = component
        self.contributionScore = contributionScore
        self.context = context
    }
}

// MARK: - CohesionEngine

public enum CohesionEngine: Sendable {

    // MARK: - Public API

    public static func compute(items: [WardrobeItem], profile: UserProfile) -> CohesionSnapshot {
        compute(items: items, profile: profile, weights: SeasonalEngine.baseWeights)
    }

    public static func compute(items: [WardrobeItem], profile: UserProfile, weights: CohesionWeights) -> CohesionSnapshot {
        let alignment = alignmentScore(items: items, profile: profile)
        let density = densityScore(items: items, profile: profile)
        let palette = paletteScore(items: items)
        let rotation = rotationScore(items: items)

        let total = alignment * weights.alignment + density * weights.density + palette * weights.palette + rotation * weights.rotation
        let status = statusLevel(from: total)

        return CohesionSnapshot(
            alignmentScore: alignment,
            densityScore: density,
            paletteScore: palette,
            rotationScore: rotation,
            totalScore: total,
            statusLevel: status,
            itemIDs: Set(items.map(\.id))
        )
    }

    // MARK: - Structural Identity

    public static func structuralIdentity(items: [WardrobeItem]) -> StructuralIdentity {
        guard !items.isEmpty else {
            return StructuralIdentity(
                dominantSilhouette: nil,
                dominantBaseGroup: nil,
                dominantTemperature: .neutral
            )
        }

        let dominantSilhouette = plurality(items.map(\.silhouette))
        let dominantBaseGroup = plurality(items.map(\.baseGroup))
        let dominantTemperature = temperaturePlurality(items.map(\.temperature))

        return StructuralIdentity(
            dominantSilhouette: dominantSilhouette,
            dominantBaseGroup: dominantBaseGroup,
            dominantTemperature: dominantTemperature
        )
    }

    /// Returns the single most frequent value, or nil if tied.
    private static func plurality<T: Hashable>(_ values: [T]) -> T? {
        var counts: [T: Int] = [:]
        for value in values {
            counts[value, default: 0] += 1
        }
        let maxCount = counts.values.max() ?? 0
        let winners = counts.filter { $0.value == maxCount }
        guard winners.count == 1 else { return nil }
        return winners.first!.key
    }

    /// Temperature plurality: ties resolve to .neutral (never nil).
    private static func temperaturePlurality(_ values: [Temperature]) -> Temperature {
        var counts: [Temperature: Int] = [:]
        for value in values {
            counts[value, default: 0] += 1
        }
        let maxCount = counts.values.max() ?? 0
        let winners = counts.filter { $0.value == maxCount }
        if winners.count == 1 {
            return winners.first!.key
        }
        // Tie: prefer .neutral if among winners, else default .neutral
        return .neutral
    }

    // MARK: - Item Contributions

    public static func itemContributions(
        items: [WardrobeItem],
        profile: UserProfile,
        component: CohesionComponent
    ) -> [ItemContribution] {
        guard !items.isEmpty else { return [] }

        switch component {
        case .alignment:
            return alignmentContributions(items: items, profile: profile)
        case .density:
            return densityContributions(items: items, profile: profile)
        case .palette:
            return paletteContributions(items: items)
        case .rotation:
            return rotationContributions(items: items)
        }
    }

    // MARK: - Archetype Alignment (35%)

    public static func alignmentScore(items: [WardrobeItem], profile: UserProfile) -> Double {
        guard !items.isEmpty else { return 0 }

        let sum = items.reduce(0.0) { total, item in
            total + itemAlignmentValue(item: item, profile: profile)
        }
        return (sum / Double(items.count)) * 100
    }

    // MARK: - Combination Density (30%)

    public static func densityScore(items: [WardrobeItem], profile: UserProfile) -> Double {
        let tops = items.filter { $0.category == .top }
        let bottoms = items.filter { $0.category == .bottom }
        let shoes = items.filter { $0.category == .shoes }
        let outerwear = items.filter { $0.category == .outerwear }

        guard !tops.isEmpty, !bottoms.isEmpty, !shoes.isEmpty else { return 0 }

        let totalPossible = tops.count * bottoms.count * shoes.count * (1 + outerwear.count)
        guard totalPossible > 0 else { return 0 }

        var validCount = 0

        for top in tops {
            for bottom in bottoms {
                for shoe in shoes {
                    // Outfit without outerwear
                    let baseOutfit = [top, bottom, shoe]
                    if isValidOutfit(baseOutfit, profile: profile) {
                        validCount += 1
                    }
                    // Outfit with each outerwear piece
                    for outer in outerwear {
                        let fullOutfit = [top, bottom, shoe, outer]
                        if isValidOutfit(fullOutfit, profile: profile) {
                            validCount += 1
                        }
                    }
                }
            }
        }

        return (Double(validCount) / Double(totalPossible)) * 100
    }

    // MARK: - Palette Control (20%)

    public static func paletteScore(items: [WardrobeItem]) -> Double {
        guard !items.isEmpty else { return 0 }

        let count = Double(items.count)

        // 1. Neutral/Deep ratio (target 60-80%)
        let neutralDeepCount = Double(items.filter { $0.baseGroup == .neutral || $0.baseGroup == .deep }.count)
        let neutralDeepRatio = neutralDeepCount / count
        let neutralDeepScore: Double
        if neutralDeepRatio >= 0.6 && neutralDeepRatio <= 0.8 {
            neutralDeepScore = 100
        } else if neutralDeepRatio < 0.6 {
            neutralDeepScore = (neutralDeepRatio / 0.6) * 100
        } else {
            neutralDeepScore = ((1.0 - neutralDeepRatio) / 0.2) * 100
        }

        // 2. Accent ratio (target 0-20%)
        let accentCount = Double(items.filter { $0.baseGroup == .accent }.count)
        let accentRatio = accentCount / count
        let accentScore: Double
        if accentRatio <= 0.2 {
            accentScore = 100
        } else {
            accentScore = max(0, (1.0 - ((accentRatio - 0.2) / 0.3)) * 100)
        }

        // 3. Temperature coherence
        let warmCount = items.filter { $0.temperature == .warm }.count
        let coolCount = items.filter { $0.temperature == .cool }.count
        let tempScore: Double
        if warmCount == 0 || coolCount == 0 {
            tempScore = 100
        } else {
            let totalTempItems = Double(warmCount + coolCount)
            let warmRatio = Double(warmCount) / totalTempItems
            let coolRatio = Double(coolCount) / totalTempItems
            tempScore = (1.0 - min(warmRatio, coolRatio) * 2) * 100
        }

        return (neutralDeepScore + accentScore + tempScore) / 3.0
    }

    // MARK: - Rotation Balance (15%)

    public static func rotationScore(items: [WardrobeItem]) -> Double {
        guard !items.isEmpty else { return 0 }

        let categories: [ItemCategory] = [.top, .bottom, .shoes, .outerwear]
        var deviations: [Double] = []

        for category in categories {
            let categoryItems = items.filter { $0.category == category }
            guard categoryItems.count > 1 else { continue }

            let usages = categoryItems.map { Double($0.usageCount) }
            let mean = usages.reduce(0, +) / Double(usages.count)
            let meanAbsDev = usages.reduce(0.0) { $0 + abs($1 - mean) } / Double(usages.count)
            let normalized = meanAbsDev / max(mean, 1)
            deviations.append(normalized)
        }

        guard !deviations.isEmpty else { return 100 }

        let avgDeviation = deviations.reduce(0, +) / Double(deviations.count)
        let clamped = min(max(avgDeviation, 0), 1)
        return (1.0 - clamped) * 100
    }

    // MARK: - Status Level

    public static func statusLevel(from totalScore: Double) -> CohesionStatus {
        switch totalScore {
        case ..<50:    return .structuring
        case 50..<65:  return .refining
        case 65..<80:  return .coherent
        case 80..<90:  return .aligned
        default:       return .architected
        }
    }

    // MARK: - Private Helpers

    private static func itemAlignmentValue(item: WardrobeItem, profile: UserProfile) -> Double {
        if item.archetypeTag == profile.primaryArchetype {
            return 1.0
        } else if item.archetypeTag == profile.secondaryArchetype {
            return 0.7
        } else if archetypesConflict(item.archetypeTag, profile.primaryArchetype) {
            return 0.2
        } else {
            return 0.5
        }
    }

    private static func archetypesConflict(_ a: Archetype, _ b: Archetype) -> Bool {
        let pair: Set<Archetype> = [a, b]
        return pair == [.structuredMinimal, .relaxedStreet]
    }

    // MARK: - Contribution Helpers

    private static func alignmentContributions(items: [WardrobeItem], profile: UserProfile) -> [ItemContribution] {
        let contributions = items.map { item -> ItemContribution in
            let value = itemAlignmentValue(item: item, profile: profile)

            let matchType: AlignmentMatchType
            if item.archetypeTag == profile.primaryArchetype {
                matchType = .primary
            } else if item.archetypeTag == profile.secondaryArchetype {
                matchType = .secondary
            } else if archetypesConflict(item.archetypeTag, profile.primaryArchetype) {
                matchType = .conflict
            } else {
                matchType = .neutral
            }

            return ItemContribution(
                itemID: item.id,
                component: .alignment,
                contributionScore: value,
                context: .alignment(matchType)
            )
        }
        return sortedContributions(contributions)
    }

    private static func rotationContributions(items: [WardrobeItem]) -> [ItemContribution] {
        let categories: [ItemCategory] = [.top, .bottom, .shoes, .outerwear]
        var categoryMeans: [ItemCategory: Double] = [:]

        for category in categories {
            let categoryItems = items.filter { $0.category == category }
            if categoryItems.count > 1 {
                let usages = categoryItems.map { Double($0.usageCount) }
                categoryMeans[category] = usages.reduce(0, +) / Double(usages.count)
            }
        }

        let contributions = items.map { item -> ItemContribution in
            guard let mean = categoryMeans[item.category] else {
                return ItemContribution(
                    itemID: item.id,
                    component: .rotation,
                    contributionScore: 1.0,
                    context: .rotation(.even)
                )
            }

            let deviation = abs(Double(item.usageCount) - mean)
            let normalized = deviation / max(mean, 1)
            let score = 1.0 - min(max(normalized, 0), 1)

            let usageLevel: UsageLevel
            if normalized < 0.2 {
                usageLevel = .even
            } else if Double(item.usageCount) > mean {
                usageLevel = .overused
            } else {
                usageLevel = .underused
            }

            return ItemContribution(
                itemID: item.id,
                component: .rotation,
                contributionScore: score,
                context: .rotation(usageLevel)
            )
        }
        return sortedContributions(contributions)
    }

    private static func densityContributions(items: [WardrobeItem], profile: UserProfile) -> [ItemContribution] {
        let baseline = densityScore(items: items, profile: profile)

        var deltas: [(item: WardrobeItem, delta: Double)] = []
        for item in items {
            let without = items.filter { $0.id != item.id }
            let scoreWithout = densityScore(items: without, profile: profile)
            deltas.append((item, baseline - scoreWithout))
        }

        let deltaValues = deltas.map(\.delta)
        let minDelta = deltaValues.min() ?? 0
        let maxDelta = deltaValues.max() ?? 0
        let range = maxDelta - minDelta

        let contributions = deltas.map { entry -> ItemContribution in
            let score: Double
            if range < 0.001 {
                score = 0.5
            } else {
                score = (entry.delta - minDelta) / range
            }

            let level: ParticipationLevel = entry.delta > 0 ? .high : .low

            return ItemContribution(
                itemID: entry.item.id,
                component: .density,
                contributionScore: score,
                context: .density(level)
            )
        }
        return sortedContributions(contributions)
    }

    private static func paletteContributions(items: [WardrobeItem]) -> [ItemContribution] {
        let baseline = paletteScore(items: items)

        var deltas: [(item: WardrobeItem, delta: Double)] = []
        for item in items {
            let without = items.filter { $0.id != item.id }
            let scoreWithout = without.isEmpty ? 0 : paletteScore(items: without)
            deltas.append((item, baseline - scoreWithout))
        }

        let warmCount = items.filter { $0.temperature == .warm }.count
        let coolCount = items.filter { $0.temperature == .cool }.count
        let accentCount = items.filter { $0.baseGroup == .accent }.count
        let accentRatio = Double(accentCount) / Double(items.count)

        let deltaValues = deltas.map(\.delta)
        let minDelta = deltaValues.min() ?? 0
        let maxDelta = deltaValues.max() ?? 0
        let range = maxDelta - minDelta

        let contributions = deltas.map { entry -> ItemContribution in
            let score: Double
            if range < 0.001 {
                score = 0.5
            } else {
                score = (entry.delta - minDelta) / range
            }

            let role: PaletteRole
            if entry.item.baseGroup == .accent && accentRatio > 0.2 {
                role = .excessAccent
            } else if entry.item.temperature == .warm && coolCount > warmCount {
                role = .temperatureClash
            } else if entry.item.temperature == .cool && warmCount > coolCount {
                role = .temperatureClash
            } else {
                role = .balanced
            }

            return ItemContribution(
                itemID: entry.item.id,
                component: .palette,
                contributionScore: score,
                context: .palette(role)
            )
        }
        return sortedContributions(contributions)
    }

    private static func sortedContributions(_ contributions: [ItemContribution]) -> [ItemContribution] {
        contributions.sorted { a, b in
            if a.contributionScore != b.contributionScore {
                return a.contributionScore > b.contributionScore
            }
            return a.itemID.uuidString < b.itemID.uuidString
        }
    }

    private static func isValidOutfit(_ outfit: [WardrobeItem], profile: UserProfile) -> Bool {
        // Rule 1: No item conflicts with primary archetype
        for item in outfit {
            if archetypesConflict(item.archetypeTag, profile.primaryArchetype) {
                return false
            }
        }

        // Rule 2: Silhouette balance in [-2, +2]
        let silhouetteSum = outfit.reduce(0) { total, item in
            switch item.silhouette {
            case .structured: return total + 1
            case .balanced:   return total + 0
            case .relaxed:    return total - 1
            }
        }
        if silhouetteSum < -2 || silhouetteSum > 2 {
            return false
        }

        // Rule 3: Color rules (skip if monochrome)
        let baseGroups = Set(outfit.map { $0.baseGroup })
        let isMonochrome = baseGroups.count == 1

        if !isMonochrome {
            let accentCount = outfit.filter { $0.baseGroup == .accent }.count
            if accentCount > 1 { return false }

            let hasNeutral = outfit.contains { $0.baseGroup == .neutral }
            if !hasNeutral { return false }

            let hasWarm = outfit.contains { $0.temperature == .warm }
            let hasCool = outfit.contains { $0.temperature == .cool }
            if hasWarm && hasCool { return false }
        }

        return true
    }
}
