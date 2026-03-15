import Foundation

public enum CohesionEngine: Sendable {

    // MARK: - Archetype Affinity Table (19 BaseGroups × 3 Archetypes)

    /// Static affinity: how well a garment type fits an archetype (0–1).
    public static func archetypeAffinity(baseGroup: BaseGroup, archetype: Archetype) -> Double {
        switch (baseGroup, archetype) {
        // Upper garment types
        case (.tee, .tailored):     return 0.3
        case (.tee, .smartCasual):  return 0.7
        case (.tee, .street):       return 1.0

        case (.shirt, .tailored):     return 1.0
        case (.shirt, .smartCasual):  return 0.8
        case (.shirt, .street):       return 0.3

        case (.knit, .tailored):     return 0.7
        case (.knit, .smartCasual):  return 0.9
        case (.knit, .street):       return 0.5

        case (.hoodie, .tailored):     return 0.1
        case (.hoodie, .smartCasual):  return 0.4
        case (.hoodie, .street):       return 1.0

        case (.blazer, .tailored):     return 1.0
        case (.blazer, .smartCasual):  return 0.7
        case (.blazer, .street):       return 0.2

        case (.coat, .tailored):     return 0.9
        case (.coat, .smartCasual):  return 0.7
        case (.coat, .street):       return 0.5

        // Lower garment types
        case (.jeans, .tailored):     return 0.3
        case (.jeans, .smartCasual):  return 0.7
        case (.jeans, .street):       return 0.9

        case (.chinos, .tailored):     return 0.8
        case (.chinos, .smartCasual):  return 0.9
        case (.chinos, .street):       return 0.4

        case (.trousers, .tailored):     return 1.0
        case (.trousers, .smartCasual):  return 0.6
        case (.trousers, .street):       return 0.2

        case (.shorts, .tailored):     return 0.2
        case (.shorts, .smartCasual):  return 0.6
        case (.shorts, .street):       return 0.8

        case (.skirt, .tailored):     return 0.6
        case (.skirt, .smartCasual):  return 0.7
        case (.skirt, .street):       return 0.5

        // Shoes
        case (.sneakers, .tailored):     return 0.2
        case (.sneakers, .smartCasual):  return 0.6
        case (.sneakers, .street):       return 1.0

        case (.boots, .tailored):     return 0.7
        case (.boots, .smartCasual):  return 0.7
        case (.boots, .street):       return 0.8

        case (.loafers, .tailored):     return 1.0
        case (.loafers, .smartCasual):  return 0.8
        case (.loafers, .street):       return 0.2

        case (.sandals, .tailored):     return 0.1
        case (.sandals, .smartCasual):  return 0.5
        case (.sandals, .street):       return 0.6

        // Accessories
        case (.belt, .tailored):     return 0.9
        case (.belt, .smartCasual):  return 0.7
        case (.belt, .street):       return 0.4

        case (.scarf, .tailored):     return 0.7
        case (.scarf, .smartCasual):  return 0.8
        case (.scarf, .street):       return 0.5

        case (.cap, .tailored):     return 0.1
        case (.cap, .smartCasual):  return 0.3
        case (.cap, .street):       return 0.9

        case (.bag, .tailored):     return 0.7
        case (.bag, .smartCasual):  return 0.7
        case (.bag, .street):       return 0.6
        }
    }

    // MARK: - Proportion Matrix (upper silhouette × lower silhouette)

    /// Asymmetric proportion compatibility: upper × lower → 0–1.
    /// Returns 0.5 (neutral) if either silhouette is .none or not in the matrix.
    public static func proportionScore(upper: Silhouette, lower: Silhouette) -> Double {
        // Matrix only covers upper silhouettes (fitted, relaxed, tapered, oversized)
        // and lower silhouettes (slim, regular, tapered, wide).
        // .none and mismatched categories return neutral.
        switch (upper, lower) {
        case (.fitted, .slim):      return 0.7
        case (.fitted, .regular):   return 0.85
        case (.fitted, .tapered):   return 0.9
        case (.fitted, .wide):      return 1.0

        case (.relaxed, .slim):     return 1.0
        case (.relaxed, .regular):  return 0.85
        case (.relaxed, .tapered):  return 0.7
        case (.relaxed, .wide):     return 0.4

        case (.tapered, .slim):     return 0.8
        case (.tapered, .regular):  return 0.9
        case (.tapered, .tapered):  return 0.85
        case (.tapered, .wide):     return 0.65

        case (.oversized, .slim):     return 1.0
        case (.oversized, .regular):  return 0.8
        case (.oversized, .tapered):  return 0.65
        case (.oversized, .wide):     return 0.3

        default: return 0.5
        }
    }

    // MARK: - 1. Layer Coverage (weight 0.25)

    /// Does the wardrobe cover all temperature layers?
    /// Filters to upper items, groups by temperature (1=outer, 2=mid, 3=base).
    public static func layerCoverageScore(items: [Garment]) -> Double {
        let uppers = items.filter { $0.category == .upper }
        guard !uppers.isEmpty else { return 0 }

        var layerCounts: [Int: Int] = [1: 0, 2: 0, 3: 0]
        for item in uppers {
            if let temp = item.temperature, temp >= 1, temp <= 3 {
                layerCounts[temp, default: 0] += 1
            }
        }

        func depthScore(_ count: Int) -> Double {
            switch count {
            case 0: return 0.0
            case 1: return 0.6
            case 2: return 0.85
            default: return 1.0
            }
        }

        let outer = depthScore(layerCounts[1] ?? 0)
        let mid = depthScore(layerCounts[2] ?? 0)
        let base = depthScore(layerCounts[3] ?? 0)

        var score = (outer * 0.35 + mid * 0.30 + base * 0.35) * 100

        // Coverage bonus: all 3 layers present
        let layersPresent = layerCounts.values.filter { $0 > 0 }.count
        if layersPresent == 3 {
            score = min(score + 10, 100)
        }

        return score
    }

    // MARK: - 2. Proportion Balance (weight 0.20)

    /// Silhouette contrast between upper and lower body.
    public static func proportionBalanceScore(items: [Garment]) -> Double {
        let uppers = items.filter { $0.category == .upper && $0.silhouette != .none }
        let lowers = items.filter { $0.category == .lower && $0.silhouette != .none }

        guard !uppers.isEmpty, !lowers.isEmpty else {
            // Check if both categories have items but all silhouettes are .none
            let hasUpper = items.contains(where: { $0.category == .upper })
            let hasLower = items.contains(where: { $0.category == .lower })
            if hasUpper && hasLower {
                return 50
            }
            return 0
        }

        var totalScore = 0.0
        var pairCount = 0

        for upper in uppers {
            for lower in lowers {
                totalScore += proportionScore(upper: upper.silhouette, lower: lower.silhouette)
                pairCount += 1
            }
        }

        guard pairCount > 0 else { return 0 }
        return (totalScore / Double(pairCount)) * 100
    }

    // MARK: - 3. Third Piece (weight 0.15)

    /// Ratio of layering pieces (temp 1-2) to base pieces (temp 3).
    public static func thirdPieceScore(items: [Garment], profile: UserProfile) -> Double {
        let uppers = items.filter { $0.category == .upper }
        guard !uppers.isEmpty else { return 0 }

        let thirdPieceCount = uppers.filter { ($0.temperature ?? 0) <= 2 && $0.temperature != nil }.count
        let baseCount = uppers.filter { $0.temperature == 3 }.count

        let ratio = Double(thirdPieceCount) / Double(max(baseCount, 1))

        let (idealLower, idealUpper): (Double, Double) = switch profile.primaryArchetype {
        case .tailored:    (0.8, 1.5)
        case .smartCasual: (0.5, 1.0)
        case .street:      (0.3, 0.8)
        }

        return ScoringHelpers.rangeScore(value: ratio, idealLower: idealLower, idealUpper: idealUpper, overPenaltyDivisor: 1.0)
    }

    // MARK: - 4. Capsule Ratios (weight 0.15)

    /// Three equally-weighted sub-scores: upper:lower ratio, layer distribution entropy, category balance entropy.
    public static func capsuleRatiosScore(items: [Garment], profile: UserProfile) -> Double {
        guard !items.isEmpty else { return 0 }

        let upperLower = upperLowerRatioSubScore(items: items, profile: profile)
        let layerEntropy = layerDistributionSubScore(items: items)
        let categoryEntropy = categoryBalanceSubScore(items: items)

        return (upperLower + layerEntropy + categoryEntropy) / 3.0
    }

    private static func upperLowerRatioSubScore(items: [Garment], profile: UserProfile) -> Double {
        let upperCount = items.filter { $0.category == .upper }.count
        let lowerCount = items.filter { $0.category == .lower }.count

        guard upperCount > 0, lowerCount > 0 else { return 0 }

        let ratio = Double(upperCount) / Double(lowerCount)

        let (idealLower, idealUpper): (Double, Double) = switch profile.primaryArchetype {
        case .tailored:    (1.5, 2.5)
        case .smartCasual: (1.2, 2.0)
        case .street:      (1.0, 1.5)
        }

        return ScoringHelpers.rangeScore(value: ratio, idealLower: idealLower, idealUpper: idealUpper, overPenaltyDivisor: 1.5)
    }

    private static func layerDistributionSubScore(items: [Garment]) -> Double {
        let uppers = items.filter { $0.category == .upper }
        let layer1 = uppers.filter { $0.temperature == 1 }.count
        let layer2 = uppers.filter { $0.temperature == 2 }.count
        let layer3 = uppers.filter { $0.temperature == 3 }.count

        let entropy = ScoringHelpers.normalizedEntropy([layer1, layer2, layer3])
        return entropy * 100
    }

    private static func categoryBalanceSubScore(items: [Garment]) -> Double {
        let counts = Category.allCases.map { cat in
            items.filter { $0.category == cat }.count
        }
        let entropy = ScoringHelpers.normalizedEntropy(counts)
        return entropy * 100
    }

    // MARK: - 5. Combination Density (weight 0.15)

    /// Strong combinations per garment.
    public static func combinationDensityScore(items: [Garment], profile: UserProfile) -> Double {
        let outfits = ScoringHelpers.generateOutfits(from: items)
        guard !outfits.isEmpty else { return 0 }

        let totalGarments = items.filter { $0.category != .accessory }.count
        guard totalGarments > 0 else { return 0 }

        var strongCount = 0
        for outfit in outfits {
            let strength = outfitStrength(outfit: outfit, profile: profile)
            if strength >= 0.65 {
                strongCount += 1
            }
        }

        let strongPerGarment = Double(strongCount) / Double(totalGarments)
        return ScoringHelpers.rangeScore(value: strongPerGarment, idealLower: 1.0, idealUpper: 5.0, overPenaltyDivisor: 5.0)
    }

    /// Scores an outfit on proportion, archetype coherence, and color harmony.
    public static func outfitStrength(outfit: [Garment], profile: UserProfile) -> Double {
        let proportionAvg = outfitProportionAverage(outfit: outfit)
        let archetypeCoherence = outfitArchetypeCoherence(outfit: outfit, profile: profile)
        let colorHarmony = outfitColorHarmony(outfit: outfit)

        return proportionAvg * 0.40 + archetypeCoherence * 0.35 + colorHarmony * 0.25
    }

    private static func outfitProportionAverage(outfit: [Garment]) -> Double {
        let uppers = outfit.filter { $0.category == .upper && $0.silhouette != .none }
        let lowers = outfit.filter { $0.category == .lower && $0.silhouette != .none }

        guard !uppers.isEmpty, !lowers.isEmpty else { return 0.5 }

        var total = 0.0
        var count = 0
        for upper in uppers {
            for lower in lowers {
                total += proportionScore(upper: upper.silhouette, lower: lower.silhouette)
                count += 1
            }
        }
        return count > 0 ? total / Double(count) : 0.5
    }

    private static func outfitArchetypeCoherence(outfit: [Garment], profile: UserProfile) -> Double {
        guard !outfit.isEmpty else { return 0 }
        let total = outfit.reduce(0.0) { sum, item in
            sum + archetypeAffinity(baseGroup: item.baseGroup, archetype: profile.primaryArchetype)
        }
        return total / Double(outfit.count)
    }

    private static func outfitColorHarmony(outfit: [Garment]) -> Double {
        let temps = outfit.map(\.colorTemperature)
        let hasWarm = temps.contains(.warm)
        let hasCool = temps.contains(.cool)

        if hasWarm && hasCool {
            return 0.5  // Clash penalty
        }
        return 1.0
    }

    // MARK: - 6. Standalone Quality (weight 0.10)

    /// Per-garment versatility, averaged across wardrobe.
    public static func standaloneQualityScore(items: [Garment]) -> Double {
        guard !items.isEmpty else { return 0 }

        let total = items.reduce(0.0) { sum, item in
            sum + garmentVersatility(item: item, allItems: items)
        }
        return (total / Double(items.count)) * 100
    }

    private static func garmentVersatility(item: Garment, allItems: [Garment]) -> Double {
        let colorVersatility = colorVersatilityScore(item: item)
        let silhouetteFlexibility = silhouetteFlexibilityScore(item: item, allItems: allItems)
        let archetypeBreadth = archetypeBreadthScore(item: item)

        return (colorVersatility + silhouetteFlexibility + archetypeBreadth) / 3.0
    }

    private static func colorVersatilityScore(item: Garment) -> Double {
        switch item.colorTemperature {
        case .neutral: return 1.0
        case .warm, .cool: return 0.6
        }
    }

    private static func silhouetteFlexibilityScore(item: Garment, allItems: [Garment]) -> Double {
        guard item.silhouette != .none else { return 0.5 }

        // For uppers: count how many lower silhouettes have ≥ 0.7 proportion score
        // For lowers: count how many upper silhouettes have ≥ 0.7 proportion score
        let partnerSilhouettes: [Silhouette]
        if item.category == .upper {
            partnerSilhouettes = [.slim, .regular, .tapered, .wide]
        } else if item.category == .lower {
            partnerSilhouettes = [.fitted, .relaxed, .tapered, .oversized]
        } else {
            return 0.5  // Shoes/accessories — neutral
        }

        guard !partnerSilhouettes.isEmpty else { return 0.5 }

        let compatibleCount: Int
        if item.category == .upper {
            compatibleCount = partnerSilhouettes.filter { lower in
                proportionScore(upper: item.silhouette, lower: lower) >= 0.7
            }.count
        } else {
            compatibleCount = partnerSilhouettes.filter { upper in
                proportionScore(upper: upper, lower: item.silhouette) >= 0.7
            }.count
        }

        return Double(compatibleCount) / Double(partnerSilhouettes.count)
    }

    private static func archetypeBreadthScore(item: Garment) -> Double {
        let affinities = Archetype.allCases.map { archetype in
            archetypeAffinity(baseGroup: item.baseGroup, archetype: archetype)
        }
        let highAffinityCount = affinities.filter { $0 >= 0.5 }.count
        return Double(highAffinityCount) / Double(Archetype.allCases.count)
    }

    // MARK: - Archetype Scoring

    /// Average affinity of all items to a specific archetype.
    public static func archetypeScore(items: [Garment], archetype: Archetype) -> Double {
        guard !items.isEmpty else { return 0 }
        let total = items.reduce(0.0) { sum, item in
            sum + archetypeAffinity(baseGroup: item.baseGroup, archetype: archetype)
        }
        return (total / Double(items.count)) * 100
    }

    /// Scores the wardrobe against all 3 archetypes.
    public static func allArchetypeScores(items: [Garment]) -> [Archetype: Double] {
        var result: [Archetype: Double] = [:]
        for archetype in Archetype.allCases {
            result[archetype] = archetypeScore(items: items, archetype: archetype)
        }
        return result
    }

    // MARK: - Compute

    /// Compute full cohesion breakdown with base weights.
    public static func compute(items: [Garment], profile: UserProfile) -> CohesionBreakdown {
        compute(items: items, profile: profile, weights: .base)
    }

    /// Compute full cohesion breakdown with custom weights.
    public static func compute(items: [Garment], profile: UserProfile, weights: CohesionWeights) -> CohesionBreakdown {
        guard !items.isEmpty else {
            return CohesionBreakdown(itemIDs: Set(items.map(\.id)))
        }

        let lc = layerCoverageScore(items: items)
        let pb = proportionBalanceScore(items: items)
        let tp = thirdPieceScore(items: items, profile: profile)
        let cr = capsuleRatiosScore(items: items, profile: profile)
        let cd = combinationDensityScore(items: items, profile: profile)
        let sq = standaloneQualityScore(items: items)

        let total = lc * weights.layerCoverage
            + pb * weights.proportionBalance
            + tp * weights.thirdPiece
            + cr * weights.capsuleRatios
            + cd * weights.combinationDensity
            + sq * weights.standaloneQuality

        return CohesionBreakdown(
            layerCoverageScore: lc,
            proportionBalanceScore: pb,
            thirdPieceScore: tp,
            capsuleRatiosScore: cr,
            combinationDensityScore: cd,
            standaloneQualityScore: sq,
            totalScore: total,
            itemIDs: Set(items.map(\.id))
        )
    }

    // MARK: - Outfit Count

    /// Returns the count of structurally complete outfits (uppers × lowers × shoes).
    public static func outfitCount(items: [Garment]) -> Int {
        ScoringHelpers.generateOutfits(from: items).count
    }

    /// Returns the count of strong outfits (strength ≥ 0.65).
    public static func strongOutfitCount(items: [Garment], profile: UserProfile) -> Int {
        let outfits = ScoringHelpers.generateOutfits(from: items)
        return outfits.filter { outfitStrength(outfit: $0, profile: profile) >= 0.65 }.count
    }
}
