import Testing
import Foundation
@testable import COREEngine

@Suite("SeasonalEngineV2 Tests")
struct SeasonalEngineV2Tests {

    // MARK: - Helpers

    private func makeGarment(
        category: Category = .upper,
        silhouette: Silhouette = .fitted,
        baseGroup: BaseGroup = .shirt,
        temperature: Int? = 3,
        colorTemperature: ColorTemp = .neutral
    ) -> Garment {
        Garment(
            category: category,
            silhouette: silhouette,
            baseGroup: baseGroup,
            temperature: temperature,
            colorTemperature: colorTemperature
        )
    }

    // MARK: - Coverage: Empty

    @Test func emptyCoverageAllZero() {
        let cov = SeasonalEngineV2.coverage(items: [])
        #expect(abs(cov.springScore) < 0.001)
        #expect(abs(cov.summerScore) < 0.001)
        #expect(abs(cov.autumnScore) < 0.001)
        #expect(abs(cov.winterScore) < 0.001)
    }

    // MARK: - Garment Coverage Mapping

    @Test func layer1CoolNeutralMapping() {
        // Layer 1 + cool/neutral → spring:0.3, summer:0.0, autumn:1.0, winter:1.0
        let garment = makeGarment(baseGroup: .coat, temperature: 1, colorTemperature: .cool)
        let cov = SeasonalEngineV2.garmentCoverage(garment: garment)
        #expect(abs(cov[.spring]! - 0.3) < 0.001)
        #expect(abs(cov[.summer]! - 0.0) < 0.001)
        #expect(abs(cov[.autumn]! - 1.0) < 0.001)
        #expect(abs(cov[.winter]! - 1.0) < 0.001)
    }

    @Test func layer1WarmMapping() {
        let garment = makeGarment(baseGroup: .coat, temperature: 1, colorTemperature: .warm)
        let cov = SeasonalEngineV2.garmentCoverage(garment: garment)
        #expect(abs(cov[.spring]! - 0.4) < 0.001)
        #expect(abs(cov[.summer]! - 0.1) < 0.001)
        #expect(abs(cov[.autumn]! - 1.0) < 0.001)
        #expect(abs(cov[.winter]! - 0.8) < 0.001)
    }

    @Test func layer2AnyMapping() {
        let garment = makeGarment(baseGroup: .knit, temperature: 2, colorTemperature: .warm)
        let cov = SeasonalEngineV2.garmentCoverage(garment: garment)
        #expect(abs(cov[.spring]! - 0.6) < 0.001)
        #expect(abs(cov[.summer]! - 0.2) < 0.001)
        #expect(abs(cov[.autumn]! - 0.8) < 0.001)
        #expect(abs(cov[.winter]! - 0.7) < 0.001)
    }

    @Test func layer3WarmMapping() {
        let garment = makeGarment(baseGroup: .tee, temperature: 3, colorTemperature: .warm)
        let cov = SeasonalEngineV2.garmentCoverage(garment: garment)
        #expect(abs(cov[.spring]! - 0.8) < 0.001)
        #expect(abs(cov[.summer]! - 0.6) < 0.001)
        #expect(abs(cov[.autumn]! - 0.5) < 0.001)
        #expect(abs(cov[.winter]! - 0.3) < 0.001)
    }

    @Test func layer3CoolNeutralMapping() {
        let garment = makeGarment(baseGroup: .tee, temperature: 3, colorTemperature: .neutral)
        let cov = SeasonalEngineV2.garmentCoverage(garment: garment)
        #expect(abs(cov[.spring]! - 0.9) < 0.001)
        #expect(abs(cov[.summer]! - 0.8) < 0.001)
        #expect(abs(cov[.autumn]! - 0.4) < 0.001)
        #expect(abs(cov[.winter]! - 0.3) < 0.001)
    }

    @Test func nonUpperMapping() {
        let garment = makeGarment(category: .lower, silhouette: .regular, baseGroup: .chinos, temperature: nil)
        let cov = SeasonalEngineV2.garmentCoverage(garment: garment)
        #expect(abs(cov[.spring]! - 0.6) < 0.001)
        #expect(abs(cov[.summer]! - 0.6) < 0.001)
        #expect(abs(cov[.autumn]! - 0.6) < 0.001)
        #expect(abs(cov[.winter]! - 0.6) < 0.001)
    }

    @Test func upperNilTempTreatedAsLayer2() {
        let garment = makeGarment(category: .upper, baseGroup: .shirt, temperature: nil, colorTemperature: .neutral)
        let cov = SeasonalEngineV2.garmentCoverage(garment: garment)
        // Should match layer 2 values
        #expect(abs(cov[.spring]! - 0.6) < 0.001)
        #expect(abs(cov[.summer]! - 0.2) < 0.001)
    }

    // MARK: - Coverage Averaging

    @Test func coverageAveragesAcrossItems() {
        // 2 items: layer3 cool/neutral + non-upper
        // layer3 cool: spring=0.9, summer=0.8
        // non-upper: spring=0.6, summer=0.6
        // avg spring = (0.9+0.6)/2 = 0.75 × 100 = 75
        // avg summer = (0.8+0.6)/2 = 0.70 × 100 = 70
        let items = [
            makeGarment(category: .upper, baseGroup: .tee, temperature: 3, colorTemperature: .neutral),
            makeGarment(category: .lower, silhouette: .regular, baseGroup: .chinos, temperature: nil),
        ]
        let cov = SeasonalEngineV2.coverage(items: items)
        #expect(abs(cov.springScore - 75.0) < 0.001)
        #expect(abs(cov.summerScore - 70.0) < 0.001)
    }

    @Test func coverageCappedAt100() {
        // Even with high affinity items, coverage should not exceed 100
        let items = [
            makeGarment(baseGroup: .coat, temperature: 1, colorTemperature: .cool),
            makeGarment(baseGroup: .coat, temperature: 1, colorTemperature: .cool),
        ]
        let cov = SeasonalEngineV2.coverage(items: items)
        #expect(cov.autumnScore <= 100)
        #expect(cov.winterScore <= 100)
    }

    @Test func weakestSeasonIdentified() {
        // Layer 1 cool items → summer = 0 → weakest
        let items = [
            makeGarment(baseGroup: .coat, temperature: 1, colorTemperature: .cool),
        ]
        let cov = SeasonalEngineV2.coverage(items: items)
        #expect(cov.weakestSeason == .summer)
    }

    // MARK: - Season Detection: Northern Hemisphere

    @Test func detectSpringNorthern() {
        #expect(SeasonalEngineV2.detectSeason(latitude: 60, month: 4) == .spring)
    }

    @Test func detectSummerNorthern() {
        #expect(SeasonalEngineV2.detectSeason(latitude: 60, month: 7) == .summer)
    }

    @Test func detectAutumnNorthern() {
        #expect(SeasonalEngineV2.detectSeason(latitude: 60, month: 10) == .autumn)
    }

    @Test func detectWinterNorthern() {
        #expect(SeasonalEngineV2.detectSeason(latitude: 60, month: 1) == .winter)
        #expect(SeasonalEngineV2.detectSeason(latitude: 60, month: 12) == .winter)
    }

    // MARK: - Season Detection: Southern Hemisphere

    @Test func detectSpringSouthern() {
        // Southern spring = Northern autumn months (Sep–Nov)
        #expect(SeasonalEngineV2.detectSeason(latitude: -30, month: 10) == .spring)
    }

    @Test func detectSummerSouthern() {
        #expect(SeasonalEngineV2.detectSeason(latitude: -30, month: 1) == .summer)
    }

    // MARK: - Season Detection: Equatorial

    @Test func equatorialReturnsNil() {
        #expect(SeasonalEngineV2.detectSeason(latitude: 5, month: 6) == nil)
        #expect(SeasonalEngineV2.detectSeason(latitude: -10, month: 6) == nil)
    }

    @Test func invalidMonthReturnsNil() {
        #expect(SeasonalEngineV2.detectSeason(latitude: 60, month: 0) == nil)
        #expect(SeasonalEngineV2.detectSeason(latitude: 60, month: 13) == nil)
    }

    // MARK: - Adjusted Weights

    @Test func adjustedWeightsSumToOne() {
        for season in Season.allCases {
            let w = SeasonalEngineV2.adjustedWeights(for: season)
            let sum = w.layerCoverage + w.proportionBalance + w.thirdPiece
                + w.capsuleRatios + w.combinationDensity + w.standaloneQuality
            #expect(abs(sum - 1.0) < 0.001, "Weights for \(season) should sum to 1.0, got \(sum)")
        }
    }

    @Test func winterEmphasizesLayering() {
        let base = CohesionWeights.base
        let winter = SeasonalEngineV2.adjustedWeights(for: .winter)
        #expect(winter.layerCoverage > base.layerCoverage)
        #expect(winter.thirdPiece > base.thirdPiece)
    }

    @Test func summerReducesLayering() {
        let base = CohesionWeights.base
        let summer = SeasonalEngineV2.adjustedWeights(for: .summer)
        #expect(summer.layerCoverage < base.layerCoverage)
        #expect(summer.standaloneQuality > base.standaloneQuality)
    }

    // MARK: - Recommendation

    @Test func recommendRecalibrateOnDifferentSeason() {
        let rec = SeasonalEngineV2.recommend(latitude: 60, month: 7, currentSeason: .winter)
        #expect(rec.detectedSeason == .summer)
        #expect(rec.shouldRecalibrate == true)
    }

    @Test func recommendNoRecalibrateOnSameSeason() {
        let rec = SeasonalEngineV2.recommend(latitude: 60, month: 7, currentSeason: .summer)
        #expect(rec.shouldRecalibrate == false)
    }

    @Test func recommendEquatorialNoRecalibrate() {
        let rec = SeasonalEngineV2.recommend(latitude: 5, month: 7, currentSeason: .summer)
        #expect(rec.detectedSeason == nil)
        #expect(rec.shouldRecalibrate == false)
    }

    // MARK: - Determinism

    @Test func deterministic() {
        let items = [
            makeGarment(baseGroup: .coat, temperature: 1, colorTemperature: .cool),
            makeGarment(baseGroup: .tee, temperature: 3, colorTemperature: .warm),
            makeGarment(category: .lower, silhouette: .regular, baseGroup: .jeans, temperature: nil),
        ]
        let c1 = SeasonalEngineV2.coverage(items: items)
        let c2 = SeasonalEngineV2.coverage(items: items)
        #expect(abs(c1.springScore - c2.springScore) < 0.001)
        #expect(abs(c1.summerScore - c2.summerScore) < 0.001)
        #expect(abs(c1.autumnScore - c2.autumnScore) < 0.001)
        #expect(abs(c1.winterScore - c2.winterScore) < 0.001)
        #expect(c1.weakestSeason == c2.weakestSeason)
    }
}
