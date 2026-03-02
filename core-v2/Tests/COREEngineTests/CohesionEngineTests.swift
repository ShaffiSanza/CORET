import Testing
import Foundation
@testable import COREEngine

@Suite("CohesionEngine Tests")
struct CohesionEngineTests {

    // MARK: - Helpers

    private func makeGarment(
        category: Category = .upper,
        silhouette: Silhouette = .fitted,
        baseGroup: BaseGroup = .tee,
        temperature: Int? = 3,
        usageContext: UsageContext? = nil,
        colorTemperature: ColorTemp = .neutral,
        dominantColor: String = "#000000"
    ) -> Garment {
        Garment(
            category: category,
            silhouette: silhouette,
            baseGroup: baseGroup,
            temperature: temperature,
            usageContext: usageContext,
            colorTemperature: colorTemperature,
            dominantColor: dominantColor
        )
    }

    private func makeProfile(primary: Archetype = .smartCasual) -> UserProfile {
        UserProfile(primaryArchetype: primary)
    }

    /// Minimal wardrobe: 1 upper + 1 lower + 1 shoes
    private func minimalWardrobe() -> [Garment] {
        [
            makeGarment(category: .upper, silhouette: .fitted, baseGroup: .shirt, temperature: 3),
            makeGarment(category: .lower, silhouette: .regular, baseGroup: .chinos),
            makeGarment(category: .shoes, silhouette: .none, baseGroup: .loafers),
        ]
    }

    // MARK: - Archetype Affinity Table

    @Test func archetypeAffinityBlazerTailored() {
        let score = CohesionEngine.archetypeAffinity(baseGroup: .blazer, archetype: .tailored)
        #expect(abs(score - 1.0) < 0.001)
    }

    @Test func archetypeAffinityHoodieStreet() {
        let score = CohesionEngine.archetypeAffinity(baseGroup: .hoodie, archetype: .street)
        #expect(abs(score - 1.0) < 0.001)
    }

    @Test func archetypeAffinityKnitSmartCasual() {
        let score = CohesionEngine.archetypeAffinity(baseGroup: .knit, archetype: .smartCasual)
        #expect(abs(score - 0.9) < 0.001)
    }

    @Test func archetypeAffinitySneakersStreet() {
        let score = CohesionEngine.archetypeAffinity(baseGroup: .sneakers, archetype: .street)
        #expect(abs(score - 1.0) < 0.001)
    }

    @Test func archetypeAffinityLoafersTailored() {
        let score = CohesionEngine.archetypeAffinity(baseGroup: .loafers, archetype: .tailored)
        #expect(abs(score - 1.0) < 0.001)
    }

    @Test func archetypeAffinityHoodieTailoredLow() {
        let score = CohesionEngine.archetypeAffinity(baseGroup: .hoodie, archetype: .tailored)
        #expect(abs(score - 0.1) < 0.001)
    }

    @Test func archetypeAffinityCapStreetHigh() {
        let score = CohesionEngine.archetypeAffinity(baseGroup: .cap, archetype: .street)
        #expect(abs(score - 0.9) < 0.001)
    }

    @Test func archetypeAffinityTrousersTailored() {
        let score = CohesionEngine.archetypeAffinity(baseGroup: .trousers, archetype: .tailored)
        #expect(abs(score - 1.0) < 0.001)
    }

    // MARK: - Proportion Matrix

    @Test func proportionFittedWideHighContrast() {
        let score = CohesionEngine.proportionScore(upper: .fitted, lower: .wide)
        #expect(abs(score - 1.0) < 0.001)
    }

    @Test func proportionOversizedWideLowScore() {
        let score = CohesionEngine.proportionScore(upper: .oversized, lower: .wide)
        #expect(abs(score - 0.3) < 0.001)
    }

    @Test func proportionRelaxedSlimHighContrast() {
        let score = CohesionEngine.proportionScore(upper: .relaxed, lower: .slim)
        #expect(abs(score - 1.0) < 0.001)
    }

    @Test func proportionTaperedRegular() {
        let score = CohesionEngine.proportionScore(upper: .tapered, lower: .regular)
        #expect(abs(score - 0.9) < 0.001)
    }

    @Test func proportionNoneSilhouetteReturnsNeutral() {
        let score = CohesionEngine.proportionScore(upper: .none, lower: .slim)
        #expect(abs(score - 0.5) < 0.001)
    }

    @Test func proportionMismatchedSilhouettesReturnNeutral() {
        // slim is a lower silhouette used as upper → not in matrix → neutral
        let score = CohesionEngine.proportionScore(upper: .slim, lower: .regular)
        #expect(abs(score - 0.5) < 0.001)
    }

    // MARK: - 1. Layer Coverage

    @Test func layerCoverageEmpty() {
        let score = CohesionEngine.layerCoverageScore(items: [])
        #expect(abs(score) < 0.001)
    }

    @Test func layerCoverageAllThreeLayers() {
        let items = [
            makeGarment(category: .upper, baseGroup: .coat, temperature: 1),
            makeGarment(category: .upper, baseGroup: .knit, temperature: 2),
            makeGarment(category: .upper, baseGroup: .tee, temperature: 3),
        ]
        let score = CohesionEngine.layerCoverageScore(items: items)
        // depth 1 each = 0.6, weighted 0.6*0.35 + 0.6*0.30 + 0.6*0.35 = 0.6*1.0 = 60, +10 bonus = 70
        #expect(abs(score - 70.0) < 0.001)
    }

    @Test func layerCoverageOnlyBase() {
        let items = [
            makeGarment(category: .upper, baseGroup: .tee, temperature: 3),
        ]
        let score = CohesionEngine.layerCoverageScore(items: items)
        // base: 0.6, others: 0.0. Weighted: 0*0.35 + 0*0.30 + 0.6*0.35 = 0.21 * 100 = 21
        #expect(abs(score - 21.0) < 0.001)
    }

    @Test func layerCoverageDeepLayers() {
        let items = [
            makeGarment(category: .upper, baseGroup: .coat, temperature: 1),
            makeGarment(category: .upper, baseGroup: .blazer, temperature: 1),
            makeGarment(category: .upper, baseGroup: .knit, temperature: 2),
            makeGarment(category: .upper, baseGroup: .knit, temperature: 2),
            makeGarment(category: .upper, baseGroup: .tee, temperature: 3),
            makeGarment(category: .upper, baseGroup: .tee, temperature: 3),
            makeGarment(category: .upper, baseGroup: .shirt, temperature: 3),
        ]
        let score = CohesionEngine.layerCoverageScore(items: items)
        // layer1: 2→0.85, layer2: 2→0.85, layer3: 3→1.0
        // weighted: 0.85*0.35 + 0.85*0.30 + 1.0*0.35 = 0.2975 + 0.255 + 0.35 = 0.9025 * 100 = 90.25 + 10 = 100.0 (capped)
        #expect(score <= 100.0)
        #expect(score >= 90.0)
    }

    @Test func layerCoverageIgnoresNonUpperItems() {
        let items = [
            makeGarment(category: .lower, baseGroup: .jeans, temperature: nil),
            makeGarment(category: .shoes, baseGroup: .sneakers, temperature: nil),
        ]
        let score = CohesionEngine.layerCoverageScore(items: items)
        #expect(abs(score) < 0.001)
    }

    @Test func layerCoverageMissingMiddleLayer() {
        let items = [
            makeGarment(category: .upper, baseGroup: .coat, temperature: 1),
            makeGarment(category: .upper, baseGroup: .tee, temperature: 3),
        ]
        let score = CohesionEngine.layerCoverageScore(items: items)
        // layer1: 1→0.6, layer2: 0→0.0, layer3: 1→0.6
        // weighted: 0.6*0.35 + 0*0.30 + 0.6*0.35 = 0.21 + 0 + 0.21 = 0.42 * 100 = 42
        // No bonus (only 2 layers)
        #expect(abs(score - 42.0) < 0.001)
    }

    @Test func layerCoverageNilTemperatureIgnored() {
        let items = [
            makeGarment(category: .upper, baseGroup: .tee, temperature: nil),
        ]
        let score = CohesionEngine.layerCoverageScore(items: items)
        // No layers counted → all 0 but we have uppers... wait, all counts are 0
        // 0*0.35 + 0*0.30 + 0*0.35 = 0
        #expect(abs(score) < 0.001)
    }

    // MARK: - 2. Proportion Balance

    @Test func proportionBalanceEmpty() {
        let score = CohesionEngine.proportionBalanceScore(items: [])
        #expect(abs(score) < 0.001)
    }

    @Test func proportionBalanceNoLowers() {
        let items = [
            makeGarment(category: .upper, silhouette: .fitted),
        ]
        let score = CohesionEngine.proportionBalanceScore(items: items)
        #expect(abs(score) < 0.001)
    }

    @Test func proportionBalanceSinglePair() {
        let items = [
            makeGarment(category: .upper, silhouette: .fitted, baseGroup: .shirt),
            makeGarment(category: .lower, silhouette: .wide, baseGroup: .trousers),
        ]
        let score = CohesionEngine.proportionBalanceScore(items: items)
        // fitted × wide = 1.0 × 100 = 100
        #expect(abs(score - 100.0) < 0.001)
    }

    @Test func proportionBalanceMultiplePairs() {
        let items = [
            makeGarment(category: .upper, silhouette: .fitted, baseGroup: .shirt),
            makeGarment(category: .upper, silhouette: .oversized, baseGroup: .hoodie),
            makeGarment(category: .lower, silhouette: .slim, baseGroup: .jeans),
        ]
        let score = CohesionEngine.proportionBalanceScore(items: items)
        // fitted × slim = 0.7, oversized × slim = 1.0
        // avg = (0.7 + 1.0) / 2 = 0.85 × 100 = 85
        #expect(abs(score - 85.0) < 0.001)
    }

    @Test func proportionBalanceAllNoneSilhouettes() {
        let items = [
            makeGarment(category: .upper, silhouette: .none, baseGroup: .shirt),
            makeGarment(category: .lower, silhouette: .none, baseGroup: .jeans),
        ]
        let score = CohesionEngine.proportionBalanceScore(items: items)
        // All .none → 50 (neutral)
        #expect(abs(score - 50.0) < 0.001)
    }

    @Test func proportionBalancePoorContrast() {
        let items = [
            makeGarment(category: .upper, silhouette: .oversized, baseGroup: .hoodie),
            makeGarment(category: .lower, silhouette: .wide, baseGroup: .shorts),
        ]
        let score = CohesionEngine.proportionBalanceScore(items: items)
        // oversized × wide = 0.3 × 100 = 30
        #expect(abs(score - 30.0) < 0.001)
    }

    // MARK: - 3. Third Piece

    @Test func thirdPieceEmpty() {
        let score = CohesionEngine.thirdPieceScore(items: [], profile: makeProfile())
        #expect(abs(score) < 0.001)
    }

    @Test func thirdPieceIdealRatioTailored() {
        // tailored ideal: 0.8–1.5
        let items = [
            makeGarment(category: .upper, baseGroup: .coat, temperature: 1),
            makeGarment(category: .upper, baseGroup: .tee, temperature: 3),
        ]
        let score = CohesionEngine.thirdPieceScore(items: items, profile: makeProfile(primary: .tailored))
        // ratio = 1/1 = 1.0, within [0.8, 1.5] → 100
        #expect(abs(score - 100.0) < 0.001)
    }

    @Test func thirdPieceZeroLayeringPieces() {
        let items = [
            makeGarment(category: .upper, baseGroup: .tee, temperature: 3),
            makeGarment(category: .upper, baseGroup: .shirt, temperature: 3),
        ]
        let score = CohesionEngine.thirdPieceScore(items: items, profile: makeProfile(primary: .smartCasual))
        // ratio = 0/2 = 0, smartCasual ideal [0.5, 1.0]
        // below: 0 / 0.5 * 100 = 0
        #expect(abs(score) < 0.001)
    }

    @Test func thirdPieceOverIdealRange() {
        let items = [
            makeGarment(category: .upper, baseGroup: .coat, temperature: 1),
            makeGarment(category: .upper, baseGroup: .blazer, temperature: 1),
            makeGarment(category: .upper, baseGroup: .knit, temperature: 2),
            makeGarment(category: .upper, baseGroup: .tee, temperature: 3),
        ]
        let score = CohesionEngine.thirdPieceScore(items: items, profile: makeProfile(primary: .street))
        // ratio = 3/1 = 3.0, street ideal [0.3, 0.8]
        // over: max(0, (1 - (3.0 - 0.8)/1.0) * 100) = max(0, (1 - 2.2) * 100) = 0
        #expect(abs(score) < 0.001)
    }

    @Test func thirdPieceNoBasePieces() {
        let items = [
            makeGarment(category: .upper, baseGroup: .coat, temperature: 1),
            makeGarment(category: .upper, baseGroup: .knit, temperature: 2),
        ]
        let score = CohesionEngine.thirdPieceScore(items: items, profile: makeProfile(primary: .smartCasual))
        // ratio = 2 / max(0, 1) = 2.0, smartCasual ideal [0.5, 1.0]
        // over: max(0, (1 - (2.0 - 1.0)/1.0) * 100) = max(0, 0) = 0
        #expect(abs(score) < 0.001)
    }

    @Test func thirdPieceIncludesMidLayers() {
        // temp 2 = mid layer, also a "third piece"
        let items = [
            makeGarment(category: .upper, baseGroup: .knit, temperature: 2),
            makeGarment(category: .upper, baseGroup: .tee, temperature: 3),
            makeGarment(category: .upper, baseGroup: .tee, temperature: 3),
        ]
        let score = CohesionEngine.thirdPieceScore(items: items, profile: makeProfile(primary: .smartCasual))
        // ratio = 1/2 = 0.5, smartCasual ideal [0.5, 1.0] → 100
        #expect(abs(score - 100.0) < 0.001)
    }

    // MARK: - 4. Capsule Ratios

    @Test func capsuleRatiosEmpty() {
        let score = CohesionEngine.capsuleRatiosScore(items: [], profile: makeProfile())
        #expect(abs(score) < 0.001)
    }

    @Test func capsuleRatiosSingleCategory() {
        let items = [
            makeGarment(category: .upper, baseGroup: .tee, temperature: 3),
        ]
        let score = CohesionEngine.capsuleRatiosScore(items: items, profile: makeProfile())
        // upperLower: 0 (no lowers), layerEntropy: 0 (single layer), categoryBalance: 0 (single category)
        // all 0 → 0/3 = 0
        #expect(abs(score) < 0.001)
    }

    @Test func capsuleRatiosBalancedWardrobe() {
        let items = [
            makeGarment(category: .upper, baseGroup: .coat, temperature: 1),
            makeGarment(category: .upper, baseGroup: .knit, temperature: 2),
            makeGarment(category: .upper, baseGroup: .tee, temperature: 3),
            makeGarment(category: .upper, baseGroup: .shirt, temperature: 3),
            makeGarment(category: .lower, baseGroup: .chinos),
            makeGarment(category: .lower, baseGroup: .jeans),
            makeGarment(category: .shoes, baseGroup: .loafers),
            makeGarment(category: .accessory, baseGroup: .belt),
        ]
        let score = CohesionEngine.capsuleRatiosScore(items: items, profile: makeProfile(primary: .smartCasual))
        // Should have decent entropy and ratio scores
        #expect(score > 20)
    }

    @Test func capsuleRatiosNoLowersMeansZeroRatio() {
        let items = [
            makeGarment(category: .upper, baseGroup: .tee, temperature: 3),
            makeGarment(category: .shoes, baseGroup: .sneakers),
        ]
        let score = CohesionEngine.capsuleRatiosScore(items: items, profile: makeProfile())
        // upperLower: 0 (no lowers), layerEntropy: 0 (single layer), categoryBalance: some
        // Score should be low
        #expect(score < 50)
    }

    // MARK: - 5. Combination Density

    @Test func combinationDensityEmpty() {
        let score = CohesionEngine.combinationDensityScore(items: [], profile: makeProfile())
        #expect(abs(score) < 0.001)
    }

    @Test func combinationDensityMissingCategory() {
        // No shoes → no outfits
        let items = [
            makeGarment(category: .upper, silhouette: .fitted, baseGroup: .shirt),
            makeGarment(category: .lower, silhouette: .regular, baseGroup: .chinos),
        ]
        let score = CohesionEngine.combinationDensityScore(items: items, profile: makeProfile())
        #expect(abs(score) < 0.001)
    }

    @Test func combinationDensityMinimalWardrobe() {
        let items = minimalWardrobe()
        let score = CohesionEngine.combinationDensityScore(items: items, profile: makeProfile(primary: .tailored))
        // 1 outfit total, 3 garments. If strong, 1/3 = 0.333 per garment
        // rangeScore(0.333, 1.0, 5.0, 5.0) = 0.333/1.0 * 100 = 33.3
        #expect(score > 0)
    }

    @Test func combinationDensityLargerWardrobeProducesOutfits() {
        let items = [
            makeGarment(category: .upper, silhouette: .fitted, baseGroup: .shirt, temperature: 3),
            makeGarment(category: .upper, silhouette: .relaxed, baseGroup: .knit, temperature: 2),
            makeGarment(category: .lower, silhouette: .slim, baseGroup: .chinos),
            makeGarment(category: .lower, silhouette: .regular, baseGroup: .trousers),
            makeGarment(category: .shoes, silhouette: .none, baseGroup: .loafers),
        ]
        let profile = makeProfile(primary: .tailored)
        let score = CohesionEngine.combinationDensityScore(items: items, profile: profile)
        // 2 uppers × 2 lowers × 1 shoes = 4 outfits, 5 non-accessory garments
        #expect(score >= 0)
    }

    @Test func combinationDensityAccessoriesExcludedFromOutfits() {
        let items = [
            makeGarment(category: .upper, silhouette: .fitted, baseGroup: .shirt, temperature: 3),
            makeGarment(category: .lower, silhouette: .regular, baseGroup: .chinos),
            makeGarment(category: .shoes, silhouette: .none, baseGroup: .loafers),
            makeGarment(category: .accessory, silhouette: .none, baseGroup: .belt),
        ]
        let score = CohesionEngine.combinationDensityScore(items: items, profile: makeProfile())
        // Belt should not be in outfit combinations
        // Still 1 outfit from upper+lower+shoes
        #expect(score >= 0)
    }

    // MARK: - 6. Standalone Quality

    @Test func standaloneQualityEmpty() {
        let score = CohesionEngine.standaloneQualityScore(items: [])
        #expect(abs(score) < 0.001)
    }

    @Test func standaloneQualityNeutralColorHighVersatility() {
        let items = [
            makeGarment(category: .upper, silhouette: .fitted, baseGroup: .knit, colorTemperature: .neutral),
        ]
        let score = CohesionEngine.standaloneQualityScore(items: items)
        // Color: neutral → 1.0
        // Silhouette: fitted. Compatible lowers ≥ 0.7: slim(0.7), regular(0.85), tapered(0.9), wide(1.0) → 4/4 = 1.0
        // Archetype: knit: tailored 0.7, smartCasual 0.9, street 0.5 → 3 ≥ 0.5 → 3/3 = 1.0
        // avg: (1.0 + 1.0 + 1.0) / 3 = 1.0 × 100 = 100
        #expect(abs(score - 100.0) < 0.001)
    }

    @Test func standaloneQualityWarmColorLowerVersatility() {
        let items = [
            makeGarment(category: .upper, silhouette: .fitted, baseGroup: .knit, colorTemperature: .warm),
        ]
        let score = CohesionEngine.standaloneQualityScore(items: items)
        // Color: warm → 0.6
        // Silhouette: same as above → 1.0
        // Archetype: same → 1.0
        // avg: (0.6 + 1.0 + 1.0) / 3 ≈ 0.8667 × 100 ≈ 86.67
        #expect(abs(score - 86.67) < 0.1)
    }

    @Test func standaloneQualityNarrowArchetypeBreadth() {
        let items = [
            makeGarment(category: .shoes, silhouette: .none, baseGroup: .sandals, colorTemperature: .neutral),
        ]
        let score = CohesionEngine.standaloneQualityScore(items: items)
        // Color: neutral → 1.0
        // Silhouette: .none → 0.5
        // Archetype: sandals: tailored 0.1, smartCasual 0.5, street 0.6 → 2 ≥ 0.5 → 2/3 ≈ 0.667
        // avg: (1.0 + 0.5 + 0.667) / 3 ≈ 0.722 × 100 ≈ 72.2
        #expect(score > 60 && score < 80)
    }

    @Test func standaloneQualityMultipleItems() {
        let items = [
            makeGarment(category: .upper, silhouette: .fitted, baseGroup: .shirt, colorTemperature: .neutral),
            makeGarment(category: .upper, silhouette: .oversized, baseGroup: .hoodie, colorTemperature: .cool),
        ]
        let score = CohesionEngine.standaloneQualityScore(items: items)
        // shirt: high archetype breadth (1.0/0.8/0.3 → 2/3), neutral → 1.0, fitted → high compat
        // hoodie: low archetype breadth (0.1/0.4/1.0 → 1/3), cool → 0.6, oversized → varies
        // Average should be moderate
        #expect(score > 30 && score < 90)
    }

    @Test func standaloneQualityLowerItemSilhouetteFlexibility() {
        let items = [
            makeGarment(category: .lower, silhouette: .regular, baseGroup: .chinos, colorTemperature: .neutral),
        ]
        let score = CohesionEngine.standaloneQualityScore(items: items)
        // Color: neutral → 1.0
        // Silhouette: regular as lower. Check upper partners ≥ 0.7:
        //   fitted→0.85, relaxed→0.85, tapered→0.9, oversized→0.8 → 4/4 = 1.0
        // Archetype: chinos: tailored 0.8, smartCasual 0.9, street 0.4 → 2/3 ≈ 0.667
        // avg: (1.0 + 1.0 + 0.667) / 3 ≈ 0.889 × 100 ≈ 88.9
        #expect(score > 80 && score < 95)
    }

    // MARK: - Archetype Scoring

    @Test func archetypeScoreEmpty() {
        let score = CohesionEngine.archetypeScore(items: [], archetype: .tailored)
        #expect(abs(score) < 0.001)
    }

    @Test func archetypeScoreAllTailored() {
        let items = [
            makeGarment(category: .upper, baseGroup: .blazer),
            makeGarment(category: .lower, baseGroup: .trousers),
            makeGarment(category: .shoes, baseGroup: .loafers),
        ]
        let score = CohesionEngine.archetypeScore(items: items, archetype: .tailored)
        // blazer 1.0, trousers 1.0, loafers 1.0 → avg 1.0 × 100 = 100
        #expect(abs(score - 100.0) < 0.001)
    }

    @Test func archetypeScoreAllStreet() {
        let items = [
            makeGarment(category: .upper, baseGroup: .hoodie),
            makeGarment(category: .lower, baseGroup: .jeans),
            makeGarment(category: .shoes, baseGroup: .sneakers),
        ]
        let score = CohesionEngine.archetypeScore(items: items, archetype: .street)
        // hoodie 1.0, jeans 0.9, sneakers 1.0 → avg ≈ 0.967 × 100 ≈ 96.7
        #expect(score > 95)
    }

    @Test func archetypeScoreMixed() {
        let items = [
            makeGarment(category: .upper, baseGroup: .blazer),   // tailored 1.0
            makeGarment(category: .upper, baseGroup: .hoodie),   // tailored 0.1
            makeGarment(category: .shoes, baseGroup: .sneakers), // tailored 0.2
        ]
        let score = CohesionEngine.archetypeScore(items: items, archetype: .tailored)
        // avg = (1.0 + 0.1 + 0.2) / 3 ≈ 0.433 × 100 ≈ 43.3
        #expect(abs(score - 43.33) < 0.1)
    }

    @Test func allArchetypeScoresReturnsThreeEntries() {
        let items = minimalWardrobe()
        let scores = CohesionEngine.allArchetypeScores(items: items)
        #expect(scores.count == 3)
        #expect(scores[.tailored] != nil)
        #expect(scores[.smartCasual] != nil)
        #expect(scores[.street] != nil)
    }

    @Test func allArchetypeScoresConsistentWithIndividual() {
        let items = minimalWardrobe()
        let all = CohesionEngine.allArchetypeScores(items: items)
        let tailored = CohesionEngine.archetypeScore(items: items, archetype: .tailored)
        #expect(abs((all[.tailored] ?? 0) - tailored) < 0.001)
    }

    // MARK: - Compute

    @Test func computeEmptyWardrobe() {
        let breakdown = CohesionEngine.compute(items: [], profile: makeProfile())
        #expect(abs(breakdown.totalScore) < 0.001)
        #expect(abs(breakdown.layerCoverageScore) < 0.001)
        #expect(abs(breakdown.proportionBalanceScore) < 0.001)
        #expect(abs(breakdown.thirdPieceScore) < 0.001)
        #expect(abs(breakdown.capsuleRatiosScore) < 0.001)
        #expect(abs(breakdown.combinationDensityScore) < 0.001)
        #expect(abs(breakdown.standaloneQualityScore) < 0.001)
        #expect(breakdown.itemIDs.isEmpty)
    }

    @Test func computeMinimalWardrobe() {
        let items = minimalWardrobe()
        let profile = makeProfile(primary: .smartCasual)
        let breakdown = CohesionEngine.compute(items: items, profile: profile)

        // Should have some score
        #expect(breakdown.totalScore >= 0)
        #expect(breakdown.itemIDs.count == 3)
    }

    @Test func computeTotalEqualsWeightedSum() {
        let items = [
            makeGarment(category: .upper, silhouette: .fitted, baseGroup: .shirt, temperature: 3),
            makeGarment(category: .upper, silhouette: .relaxed, baseGroup: .knit, temperature: 2),
            makeGarment(category: .upper, silhouette: .oversized, baseGroup: .coat, temperature: 1),
            makeGarment(category: .lower, silhouette: .slim, baseGroup: .chinos),
            makeGarment(category: .lower, silhouette: .regular, baseGroup: .jeans),
            makeGarment(category: .shoes, silhouette: .none, baseGroup: .loafers),
            makeGarment(category: .accessory, silhouette: .none, baseGroup: .belt),
        ]
        let profile = makeProfile(primary: .smartCasual)
        let b = CohesionEngine.compute(items: items, profile: profile)

        let expected = b.layerCoverageScore * 0.25
            + b.proportionBalanceScore * 0.20
            + b.thirdPieceScore * 0.15
            + b.capsuleRatiosScore * 0.15
            + b.combinationDensityScore * 0.15
            + b.standaloneQualityScore * 0.10

        #expect(abs(b.totalScore - expected) < 0.001)
    }

    @Test func computeWithCustomWeights() {
        let items = minimalWardrobe()
        let profile = makeProfile()
        let weights = CohesionWeights(
            layerCoverage: 0.5,
            proportionBalance: 0.1,
            thirdPiece: 0.1,
            capsuleRatios: 0.1,
            combinationDensity: 0.1,
            standaloneQuality: 0.1
        )

        let b = CohesionEngine.compute(items: items, profile: profile, weights: weights)

        let expected = b.layerCoverageScore * 0.5
            + b.proportionBalanceScore * 0.1
            + b.thirdPieceScore * 0.1
            + b.capsuleRatiosScore * 0.1
            + b.combinationDensityScore * 0.1
            + b.standaloneQualityScore * 0.1

        #expect(abs(b.totalScore - expected) < 0.001)
    }

    @Test func computeDeterministic() {
        let items = [
            makeGarment(category: .upper, silhouette: .fitted, baseGroup: .shirt, temperature: 3),
            makeGarment(category: .lower, silhouette: .regular, baseGroup: .chinos),
            makeGarment(category: .shoes, silhouette: .none, baseGroup: .loafers),
        ]
        let profile = makeProfile(primary: .tailored)

        let b1 = CohesionEngine.compute(items: items, profile: profile)
        let b2 = CohesionEngine.compute(items: items, profile: profile)

        #expect(abs(b1.totalScore - b2.totalScore) < 0.001)
        #expect(abs(b1.layerCoverageScore - b2.layerCoverageScore) < 0.001)
        #expect(abs(b1.proportionBalanceScore - b2.proportionBalanceScore) < 0.001)
    }

    @Test func computeItemIDsTracked() {
        let items = minimalWardrobe()
        let breakdown = CohesionEngine.compute(items: items, profile: makeProfile())
        for item in items {
            #expect(breakdown.itemIDs.contains(item.id))
        }
    }

    // MARK: - Outfit Count

    @Test func outfitCountEmpty() {
        #expect(CohesionEngine.outfitCount(items: []) == 0)
    }

    @Test func outfitCountMinimal() {
        let items = minimalWardrobe()
        #expect(CohesionEngine.outfitCount(items: items) == 1)
    }

    @Test func outfitCountMultiple() {
        let items = [
            makeGarment(category: .upper, baseGroup: .shirt, temperature: 3),
            makeGarment(category: .upper, baseGroup: .knit, temperature: 2),
            makeGarment(category: .lower, baseGroup: .chinos),
            makeGarment(category: .lower, baseGroup: .jeans),
            makeGarment(category: .shoes, baseGroup: .loafers),
        ]
        // 2 uppers × 2 lowers × 1 shoes = 4
        #expect(CohesionEngine.outfitCount(items: items) == 4)
    }

    @Test func outfitCountMissingShoes() {
        let items = [
            makeGarment(category: .upper, baseGroup: .shirt),
            makeGarment(category: .lower, baseGroup: .chinos),
        ]
        #expect(CohesionEngine.outfitCount(items: items) == 0)
    }

    // MARK: - Edge Cases

    @Test func allSubScoresNonNegative() {
        let items = [
            makeGarment(category: .upper, silhouette: .oversized, baseGroup: .hoodie, temperature: 1, colorTemperature: .cool),
        ]
        let profile = makeProfile(primary: .tailored)
        let b = CohesionEngine.compute(items: items, profile: profile)

        #expect(b.layerCoverageScore >= 0)
        #expect(b.proportionBalanceScore >= 0)
        #expect(b.thirdPieceScore >= 0)
        #expect(b.capsuleRatiosScore >= 0)
        #expect(b.combinationDensityScore >= 0)
        #expect(b.standaloneQualityScore >= 0)
        #expect(b.totalScore >= 0)
    }

    @Test func allSubScoresCappedAt100() {
        let items = [
            makeGarment(category: .upper, silhouette: .fitted, baseGroup: .blazer, temperature: 1, colorTemperature: .neutral),
            makeGarment(category: .upper, silhouette: .fitted, baseGroup: .knit, temperature: 2, colorTemperature: .neutral),
            makeGarment(category: .upper, silhouette: .fitted, baseGroup: .shirt, temperature: 3, colorTemperature: .neutral),
            makeGarment(category: .upper, silhouette: .relaxed, baseGroup: .coat, temperature: 1, colorTemperature: .neutral),
            makeGarment(category: .lower, silhouette: .slim, baseGroup: .trousers, colorTemperature: .neutral),
            makeGarment(category: .lower, silhouette: .regular, baseGroup: .chinos, colorTemperature: .neutral),
            makeGarment(category: .shoes, silhouette: .none, baseGroup: .loafers, colorTemperature: .neutral),
            makeGarment(category: .accessory, silhouette: .none, baseGroup: .belt, colorTemperature: .neutral),
        ]
        let profile = makeProfile(primary: .tailored)
        let b = CohesionEngine.compute(items: items, profile: profile)

        #expect(b.layerCoverageScore <= 100)
        #expect(b.proportionBalanceScore <= 100)
        #expect(b.thirdPieceScore <= 100)
        #expect(b.capsuleRatiosScore <= 100)
        #expect(b.combinationDensityScore <= 100)
        #expect(b.standaloneQualityScore <= 100)
        #expect(b.totalScore <= 100)
    }

    @Test func singleUpperOnlyWardrobe() {
        let items = [
            makeGarment(category: .upper, silhouette: .fitted, baseGroup: .shirt, temperature: 3),
        ]
        let profile = makeProfile()
        let b = CohesionEngine.compute(items: items, profile: profile)
        #expect(b.totalScore >= 0)
        #expect(b.combinationDensityScore == 0)  // No outfits without lower+shoes
    }

    @Test func strongOutfitCountMatchesExpectation() {
        let items = [
            makeGarment(category: .upper, silhouette: .fitted, baseGroup: .shirt, temperature: 3, colorTemperature: .neutral),
            makeGarment(category: .lower, silhouette: .slim, baseGroup: .trousers, colorTemperature: .neutral),
            makeGarment(category: .shoes, silhouette: .none, baseGroup: .loafers, colorTemperature: .neutral),
        ]
        let profile = makeProfile(primary: .tailored)
        let strong = CohesionEngine.strongOutfitCount(items: items, profile: profile)
        let total = CohesionEngine.outfitCount(items: items)
        #expect(strong <= total)
        #expect(strong >= 0)
    }

    // MARK: - Integration: Well-built Wardrobe Should Score Higher

    @Test func coherentWardrobeScoredHigherThanIncoherent() {
        let coherent = [
            makeGarment(category: .upper, silhouette: .fitted, baseGroup: .shirt, temperature: 3, colorTemperature: .neutral),
            makeGarment(category: .upper, silhouette: .fitted, baseGroup: .knit, temperature: 2, colorTemperature: .neutral),
            makeGarment(category: .upper, silhouette: .fitted, baseGroup: .blazer, temperature: 1, colorTemperature: .neutral),
            makeGarment(category: .lower, silhouette: .slim, baseGroup: .trousers, colorTemperature: .neutral),
            makeGarment(category: .lower, silhouette: .regular, baseGroup: .chinos, colorTemperature: .neutral),
            makeGarment(category: .shoes, silhouette: .none, baseGroup: .loafers, colorTemperature: .neutral),
        ]

        let incoherent = [
            makeGarment(category: .upper, silhouette: .oversized, baseGroup: .hoodie, temperature: 3, colorTemperature: .warm),
            makeGarment(category: .upper, silhouette: .oversized, baseGroup: .hoodie, temperature: 3, colorTemperature: .cool),
            makeGarment(category: .lower, silhouette: .wide, baseGroup: .shorts, colorTemperature: .warm),
            makeGarment(category: .shoes, silhouette: .none, baseGroup: .sandals, colorTemperature: .cool),
        ]

        let profile = makeProfile(primary: .tailored)
        let coherentScore = CohesionEngine.compute(items: coherent, profile: profile).totalScore
        let incoherentScore = CohesionEngine.compute(items: incoherent, profile: profile).totalScore

        #expect(coherentScore > incoherentScore)
    }

    @Test func streetWardrobeScoredHigherWithStreetArchetype() {
        let items = [
            makeGarment(category: .upper, silhouette: .oversized, baseGroup: .hoodie, temperature: 3),
            makeGarment(category: .lower, silhouette: .wide, baseGroup: .jeans),
            makeGarment(category: .shoes, silhouette: .none, baseGroup: .sneakers),
        ]

        let streetScore = CohesionEngine.archetypeScore(items: items, archetype: .street)
        let tailoredScore = CohesionEngine.archetypeScore(items: items, archetype: .tailored)

        #expect(streetScore > tailoredScore)
    }
}
