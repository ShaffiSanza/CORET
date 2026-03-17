import Testing
import Foundation
@testable import COREEngine

@Suite("Data Model Tests")
struct ModelTests {

    // MARK: - Helpers

    private func makeGarment(
        category: Category = .upper,
        silhouette: Silhouette = .fitted,
        baseGroup: BaseGroup = .tee,
        temperature: Int? = 3,
        usageContext: UsageContext? = nil,
        colorTemperature: ColorTemp = .neutral,
        dominantColor: String = "#000000",
        isFavorite: Bool = false,
        isKeyGarment: Bool = false,
        source: ImportSource = .manual
    ) -> Garment {
        Garment(
            category: category,
            silhouette: silhouette,
            baseGroup: baseGroup,
            temperature: temperature,
            usageContext: usageContext,
            colorTemperature: colorTemperature,
            dominantColor: dominantColor,
            isFavorite: isFavorite,
            isKeyGarment: isKeyGarment,
            source: source
        )
    }

    private func makeProfile(primary: Archetype = .smartCasual) -> UserProfile {
        UserProfile(primaryArchetype: primary)
    }

    // MARK: - Enum Case Counts

    @Test func categoryCaseCount() {
        #expect(Category.allCases.count == 4)
    }

    @Test func silhouetteCaseCount() {
        #expect(Silhouette.allCases.count == 8)
    }

    @Test func baseGroupCaseCount() {
        #expect(BaseGroup.allCases.count == 19)
    }

    @Test func colorTempCaseCount() {
        #expect(ColorTemp.allCases.count == 3)
    }

    @Test func archetypeCaseCount() {
        #expect(Archetype.allCases.count == 3)
    }

    @Test func usageContextCaseCount() {
        #expect(UsageContext.allCases.count == 3)
    }

    @Test func importSourceCaseCount() {
        #expect(ImportSource.allCases.count == 5)
    }

    @Test func clarityBandCaseCount() {
        #expect(ClarityBand.allCases.count == 4)
    }

    @Test func clarityTrendCaseCount() {
        #expect(ClarityTrend.allCases.count == 3)
    }

    // MARK: - Garment Defaults

    @Test func garmentDefaults() {
        let g = makeGarment()
        #expect(g.image == "")
        #expect(g.name == "")
        #expect(g.isFavorite == false)
        #expect(g.isKeyGarment == false)
        #expect(g.source == .manual)
        #expect(g.dominantColor == "#000000")
    }

    @Test func garmentIdentifiable() {
        let g1 = makeGarment()
        let g2 = makeGarment()
        #expect(g1.id != g2.id)
    }

    // MARK: - UserProfile Defaults

    @Test func userProfileDefaults() {
        let p = makeProfile()
        #expect(p.primaryArchetype == .smartCasual)
    }

    @Test func userProfileCustomArchetype() {
        let p = makeProfile(primary: .tailored)
        #expect(p.primaryArchetype == .tailored)
    }

    // MARK: - Codable Round-Trips

    @Test func garmentCodableRoundTrip() throws {
        let original = makeGarment(
            category: .lower,
            silhouette: .slim,
            baseGroup: .jeans,
            temperature: nil,
            usageContext: .everyday,
            colorTemperature: .cool,
            dominantColor: "#1A2B3C",
            isFavorite: true,
            isKeyGarment: true,
            source: .zalando
        )

        let data = try JSONEncoder().encode(original)
        let decoded = try JSONDecoder().decode(Garment.self, from: data)

        #expect(decoded.id == original.id)
        #expect(decoded.category == .lower)
        #expect(decoded.silhouette == .slim)
        #expect(decoded.baseGroup == .jeans)
        #expect(decoded.temperature == nil)
        #expect(decoded.usageContext == .everyday)
        #expect(decoded.colorTemperature == .cool)
        #expect(decoded.dominantColor == "#1A2B3C")
        #expect(decoded.isFavorite == true)
        #expect(decoded.isKeyGarment == true)
        #expect(decoded.source == .zalando)
    }

    @Test func userProfileCodableRoundTrip() throws {
        let original = makeProfile(primary: .street)
        let data = try JSONEncoder().encode(original)
        let decoded = try JSONDecoder().decode(UserProfile.self, from: data)
        #expect(decoded.id == original.id)
        #expect(decoded.primaryArchetype == .street)
    }

    @Test func userProfileBodyFieldsDefaultNil() {
        let p = makeProfile()
        #expect(p.height == nil)
        #expect(p.build == nil)
    }

    @Test func userProfileBodyFieldsRoundTrip() throws {
        let original = UserProfile(primaryArchetype: .tailored, height: 178, build: "athletic")
        let data = try JSONEncoder().encode(original)
        let decoded = try JSONDecoder().decode(UserProfile.self, from: data)
        #expect(decoded.height == 178)
        #expect(decoded.build == "athletic")
    }

    @Test func userProfileBodyFieldsBackwardCompatible() throws {
        // JSON without height/build should decode fine (nil defaults)
        let json = """
        {"id":"00000000-0000-0000-0000-000000000001","primaryArchetype":"street","createdAt":0}
        """.data(using: .utf8)!
        let decoded = try JSONDecoder().decode(UserProfile.self, from: json)
        #expect(decoded.primaryArchetype == .street)
        #expect(decoded.height == nil)
        #expect(decoded.build == nil)
    }

    @Test func cohesionBreakdownCodableRoundTrip() throws {
        let original = CohesionBreakdown(
            layerCoverageScore: 80,
            proportionBalanceScore: 70,
            thirdPieceScore: 60,
            capsuleRatiosScore: 50,
            combinationDensityScore: 40,
            standaloneQualityScore: 30,
            totalScore: 55
        )
        let data = try JSONEncoder().encode(original)
        let decoded = try JSONDecoder().decode(CohesionBreakdown.self, from: data)
        #expect(abs(decoded.totalScore - 55) < 0.001)
        #expect(abs(decoded.layerCoverageScore - 80) < 0.001)
    }

    @Test func claritySnapshotCodableRoundTrip() throws {
        let breakdown = CohesionBreakdown(totalScore: 72)
        let original = ClaritySnapshot(
            score: 75,
            band: .fokusert,
            archetypeScores: [.tailored: 80, .smartCasual: 60, .street: 40],
            dominantArchetype: .tailored,
            cohesionBreakdown: breakdown
        )
        let data = try JSONEncoder().encode(original)
        let decoded = try JSONDecoder().decode(ClaritySnapshot.self, from: data)
        #expect(abs(decoded.score - 75) < 0.001)
        #expect(decoded.band == .fokusert)
        #expect(decoded.dominantArchetype == .tailored)
        #expect(decoded.archetypeScores.count == 3)
    }

    @Test func cohesionWeightsDefaultsSumToOne() {
        let w = CohesionWeights.base
        let sum = w.layerCoverage + w.proportionBalance + w.thirdPiece + w.capsuleRatios + w.combinationDensity + w.standaloneQuality
        #expect(abs(sum - 1.0) < 0.001)
    }
}
