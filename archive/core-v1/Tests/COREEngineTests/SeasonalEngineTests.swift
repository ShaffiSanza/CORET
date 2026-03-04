import Testing
@testable import COREEngine

// MARK: - Base Weights

@Test func baseWeightsSumToOne() {
    let w = SeasonalEngine.baseWeights
    let sum = w.alignment + w.density + w.palette + w.rotation
    #expect(abs(sum - 1.0) < 0.001)
}

@Test func baseWeightsMatchSpec() {
    let w = SeasonalEngine.baseWeights
    #expect(w.alignment == 0.35)
    #expect(w.density == 0.30)
    #expect(w.palette == 0.20)
    #expect(w.rotation == 0.15)
}

// MARK: - Season Detection (Northern Hemisphere)

@Test func northernSpring() {
    #expect(SeasonalEngine.detectSeason(latitude: 60, month: 3) == .springSummer)
    #expect(SeasonalEngine.detectSeason(latitude: 60, month: 6) == .springSummer)
    #expect(SeasonalEngine.detectSeason(latitude: 60, month: 8) == .springSummer)
}

@Test func northernAutumn() {
    #expect(SeasonalEngine.detectSeason(latitude: 60, month: 9) == .autumnWinter)
    #expect(SeasonalEngine.detectSeason(latitude: 60, month: 12) == .autumnWinter)
    #expect(SeasonalEngine.detectSeason(latitude: 60, month: 1) == .autumnWinter)
    #expect(SeasonalEngine.detectSeason(latitude: 60, month: 2) == .autumnWinter)
}

@Test func northernBoundaryLatitude() {
    // Exactly 15° = northern
    #expect(SeasonalEngine.detectSeason(latitude: 15, month: 6) == .springSummer)
    #expect(SeasonalEngine.detectSeason(latitude: 15, month: 11) == .autumnWinter)
}

// MARK: - Season Detection (Southern Hemisphere)

@Test func southernFlipped() {
    // Southern: Mar-Aug = autumnWinter, Sep-Feb = springSummer
    #expect(SeasonalEngine.detectSeason(latitude: -30, month: 6) == .autumnWinter)
    #expect(SeasonalEngine.detectSeason(latitude: -30, month: 12) == .springSummer)
    #expect(SeasonalEngine.detectSeason(latitude: -30, month: 1) == .springSummer)
}

@Test func southernBoundaryLatitude() {
    #expect(SeasonalEngine.detectSeason(latitude: -15, month: 6) == .autumnWinter)
    #expect(SeasonalEngine.detectSeason(latitude: -15, month: 11) == .springSummer)
}

// MARK: - Equatorial

@Test func equatorialReturnsNil() {
    #expect(SeasonalEngine.detectSeason(latitude: 0, month: 6) == nil)
    #expect(SeasonalEngine.detectSeason(latitude: 14.9, month: 3) == nil)
    #expect(SeasonalEngine.detectSeason(latitude: -14.9, month: 9) == nil)
}

// MARK: - Invalid Month

@Test func invalidMonthReturnsNil() {
    #expect(SeasonalEngine.detectSeason(latitude: 60, month: 0) == nil)
    #expect(SeasonalEngine.detectSeason(latitude: 60, month: 13) == nil)
    #expect(SeasonalEngine.detectSeason(latitude: 60, month: -1) == nil)
}

// MARK: - Weight Adjustments

@Test func springSummerWeightsSumToOne() {
    let w = SeasonalEngine.adjustedWeights(for: .springSummer)
    let sum = w.alignment + w.density + w.palette + w.rotation
    #expect(abs(sum - 1.0) < 0.001)
}

@Test func autumnWinterWeightsSumToOne() {
    let w = SeasonalEngine.adjustedWeights(for: .autumnWinter)
    let sum = w.alignment + w.density + w.palette + w.rotation
    #expect(abs(sum - 1.0) < 0.001)
}

@Test func springSummerShiftsPaletteAndRotationUp() {
    let ss = SeasonalEngine.adjustedWeights(for: .springSummer)
    let base = SeasonalEngine.baseWeights
    // Palette and rotation should be higher than base proportionally
    #expect(ss.palette > base.palette)
    #expect(ss.rotation > base.rotation)
    // Alignment and density should be lower
    #expect(ss.alignment < base.alignment)
    #expect(ss.density < base.density)
}

@Test func autumnWinterShiftsAlignmentAndDensityUp() {
    let aw = SeasonalEngine.adjustedWeights(for: .autumnWinter)
    let base = SeasonalEngine.baseWeights
    #expect(aw.alignment > base.alignment)
    #expect(aw.density > base.density)
    #expect(aw.palette < base.palette)
    #expect(aw.rotation < base.rotation)
}

// MARK: - Recommendation

@Test func recommendRecalibrateWhenSeasonDiffers() {
    let rec = SeasonalEngine.recommend(latitude: 60, month: 6, currentSeason: .autumnWinter)
    #expect(rec.shouldRecalibrate == true)
    #expect(rec.detectedSeason == .springSummer)
    #expect(rec.currentSeason == .autumnWinter)
}

@Test func recommendNoRecalibrateWhenSameSeason() {
    let rec = SeasonalEngine.recommend(latitude: 60, month: 6, currentSeason: .springSummer)
    #expect(rec.shouldRecalibrate == false)
    #expect(rec.detectedSeason == .springSummer)
}

@Test func recommendNoRecalibrateForEquatorial() {
    let rec = SeasonalEngine.recommend(latitude: 0, month: 6, currentSeason: .springSummer)
    #expect(rec.shouldRecalibrate == false)
    #expect(rec.detectedSeason == nil)
}

@Test func recommendEquatorialUsesCurrentSeasonWeights() {
    let rec = SeasonalEngine.recommend(latitude: 0, month: 6, currentSeason: .autumnWinter)
    // Should use autumnWinter weights since no season detected
    let aw = SeasonalEngine.adjustedWeights(for: .autumnWinter)
    #expect(abs(rec.adjustedWeights.alignment - aw.alignment) < 0.001)
    #expect(abs(rec.adjustedWeights.density - aw.density) < 0.001)
}

// MARK: - CohesionEngine Integration

@Test func computeWithWeightsProducesDifferentTotal() {
    let items = [
        WardrobeItem(imagePath: "t", category: .top, silhouette: .balanced, rawColor: "t",
                     baseGroup: .neutral, temperature: .neutral, archetypeTag: .structuredMinimal),
        WardrobeItem(imagePath: "t", category: .bottom, silhouette: .balanced, rawColor: "t",
                     baseGroup: .neutral, temperature: .neutral, archetypeTag: .structuredMinimal),
        WardrobeItem(imagePath: "t", category: .shoes, silhouette: .balanced, rawColor: "t",
                     baseGroup: .neutral, temperature: .neutral, archetypeTag: .structuredMinimal),
    ]
    let profile = UserProfile(
        primaryArchetype: .structuredMinimal, secondaryArchetype: .smartCasual,
        seasonMode: .autumnWinter
    )

    let baseSnapshot = CohesionEngine.compute(items: items, profile: profile)
    let ssWeights = SeasonalEngine.adjustedWeights(for: .springSummer)
    let ssSnapshot = CohesionEngine.compute(items: items, profile: profile, weights: ssWeights)

    // Component scores should be identical
    #expect(ssSnapshot.alignmentScore == baseSnapshot.alignmentScore)
    #expect(ssSnapshot.densityScore == baseSnapshot.densityScore)
    #expect(ssSnapshot.paletteScore == baseSnapshot.paletteScore)
    #expect(ssSnapshot.rotationScore == baseSnapshot.rotationScore)

    // Total scores should differ (different weights)
    #expect(ssSnapshot.totalScore != baseSnapshot.totalScore)
}

@Test func computeWithBaseWeightsMatchesOriginal() {
    let items = [
        WardrobeItem(imagePath: "t", category: .top, silhouette: .balanced, rawColor: "t",
                     baseGroup: .neutral, temperature: .neutral, archetypeTag: .structuredMinimal),
        WardrobeItem(imagePath: "t", category: .bottom, silhouette: .balanced, rawColor: "t",
                     baseGroup: .neutral, temperature: .neutral, archetypeTag: .structuredMinimal),
        WardrobeItem(imagePath: "t", category: .shoes, silhouette: .balanced, rawColor: "t",
                     baseGroup: .neutral, temperature: .neutral, archetypeTag: .structuredMinimal),
    ]
    let profile = UserProfile(
        primaryArchetype: .structuredMinimal, secondaryArchetype: .smartCasual,
        seasonMode: .autumnWinter
    )

    let original = CohesionEngine.compute(items: items, profile: profile)
    let withBase = CohesionEngine.compute(items: items, profile: profile, weights: SeasonalEngine.baseWeights)

    #expect(abs(original.totalScore - withBase.totalScore) < 0.001)
}
