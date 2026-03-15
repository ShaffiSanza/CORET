import Testing
import Foundation
@testable import COREEngine

@Suite("DailyOutfitEngine Tests")
struct DailyOutfitEngineTests {

    // MARK: - Helpers

    private func makeGarment(
        id: UUID = UUID(),
        name: String = "",
        category: Category = .upper,
        silhouette: Silhouette = .fitted,
        baseGroup: BaseGroup = .tee,
        temperature: Int? = 3,
        colorTemperature: ColorTemp = .neutral,
        dateAdded: Date = Date()
    ) -> Garment {
        Garment(
            id: id,
            name: name,
            category: category,
            silhouette: silhouette,
            baseGroup: baseGroup,
            temperature: temperature,
            colorTemperature: colorTemperature,
            dateAdded: dateAdded
        )
    }

    private func makeProfile(primary: Archetype = .smartCasual) -> UserProfile {
        UserProfile(primaryArchetype: primary)
    }

    private func fullWardrobe() -> [Garment] {
        [
            makeGarment(name: "Shirt", category: .upper, silhouette: .fitted, baseGroup: .shirt, temperature: 3),
            makeGarment(name: "Hoodie", category: .upper, silhouette: .relaxed, baseGroup: .hoodie, temperature: 2),
            makeGarment(name: "Chinos", category: .lower, silhouette: .regular, baseGroup: .chinos),
            makeGarment(name: "Jeans", category: .lower, silhouette: .slim, baseGroup: .jeans),
            makeGarment(name: "Loafers", category: .shoes, silhouette: .none, baseGroup: .loafers),
            makeGarment(name: "Sneakers", category: .shoes, silhouette: .none, baseGroup: .sneakers),
        ]
    }

    // MARK: - Empty Wardrobe

    @Test func emptyWardrobeReturnsEmptyRecommendation() {
        let result = DailyOutfitEngine.recommend(
            items: [],
            profile: makeProfile(),
            wearLog: [],
            wornOutfits: []
        )
        #expect(result.outfit == nil)
        #expect(result.score == nil)
        #expect(result.rotationTips.isEmpty)
    }

    // MARK: - Full Wardrobe

    @Test func fullWardrobeReturnsOutfit() {
        let result = DailyOutfitEngine.recommend(
            items: fullWardrobe(),
            profile: makeProfile(),
            wearLog: [],
            wornOutfits: []
        )
        #expect(result.outfit != nil)
        #expect(result.outfit!.garments.count == 3)
    }

    @Test func fullWardrobeReturnsScore() {
        let result = DailyOutfitEngine.recommend(
            items: fullWardrobe(),
            profile: makeProfile(),
            wearLog: [],
            wornOutfits: []
        )
        #expect(result.score != nil)
        #expect(result.score!.totalStrength > 0)
    }

    @Test func clarityScorePopulated() {
        let result = DailyOutfitEngine.recommend(
            items: fullWardrobe(),
            profile: makeProfile(),
            wearLog: [],
            wornOutfits: []
        )
        #expect(result.clarityScore > 0)
    }

    @Test func clarityBandPopulated() {
        let result = DailyOutfitEngine.recommend(
            items: fullWardrobe(),
            profile: makeProfile(),
            wearLog: [],
            wornOutfits: []
        )
        #expect([ClarityBand.fragmentert, .iUtvikling, .fokusert, .krystallklar].contains(result.clarityBand))
    }

    // MARK: - Worn Outfits Filtered

    @Test func allOutfitsWornReturnsNilOutfit() {
        let wardrobe = fullWardrobe()
        let allOutfits = BestOutfitFinder.findBest(items: wardrobe, profile: makeProfile(), count: 100)
        let allWorn: Set<Set<UUID>> = Set(allOutfits.map { Set($0.garments.map(\.id)) })

        let result = DailyOutfitEngine.recommend(
            items: wardrobe,
            profile: makeProfile(),
            wearLog: [],
            wornOutfits: allWorn
        )
        #expect(result.outfit == nil)
    }

    // MARK: - Rotation Tips

    @Test func rotationTipsForUnwornGarments() {
        let wardrobe = fullWardrobe()
        // No wear logs → all garments have unusedRisk = 1.0
        let result = DailyOutfitEngine.recommend(
            items: wardrobe,
            profile: makeProfile(),
            wearLog: [],
            wornOutfits: []
        )
        #expect(result.rotationTips.count > 0)
        #expect(result.rotationTips.count <= 3)
    }

    @Test func rotationTipsSortedByRisk() {
        let wardrobe = fullWardrobe()
        let result = DailyOutfitEngine.recommend(
            items: wardrobe,
            profile: makeProfile(),
            wearLog: [],
            wornOutfits: []
        )
        for i in 0..<(result.rotationTips.count - 1) {
            #expect(result.rotationTips[i].unusedRisk >= result.rotationTips[i + 1].unusedRisk)
        }
    }

    @Test func recentlyWornGarmentsNoTip() {
        let wardrobe = fullWardrobe()
        let now = Date()
        // Wear every garment recently
        let wearLog = wardrobe.map { garment in
            WearLog(garmentID: garment.id, date: now)
        }
        let result = DailyOutfitEngine.recommend(
            items: wardrobe,
            profile: makeProfile(),
            wearLog: wearLog,
            wornOutfits: []
        )
        // Recently worn garments should have low unused risk → no tips
        #expect(result.rotationTips.isEmpty)
    }

    // MARK: - Gap Detection

    @Test func detectsGapWhenMissingCategory() {
        let items = [
            makeGarment(category: .upper, baseGroup: .shirt, temperature: 3),
            makeGarment(category: .shoes, baseGroup: .loafers),
        ]
        let result = DailyOutfitEngine.recommend(
            items: items,
            profile: makeProfile(),
            wearLog: [],
            wornOutfits: []
        )
        #expect(result.primaryGap != nil)
        #expect(result.primaryGap!.contains("lower"))
    }

    @Test func detectsGapWhenMissingMidLayer() {
        let items = [
            makeGarment(category: .upper, baseGroup: .shirt, temperature: 3),
            makeGarment(category: .lower, baseGroup: .chinos),
            makeGarment(category: .shoes, baseGroup: .loafers),
        ]
        let result = DailyOutfitEngine.recommend(
            items: items,
            profile: makeProfile(),
            wearLog: [],
            wornOutfits: []
        )
        #expect(result.primaryGap != nil)
        #expect(result.primaryGap!.lowercased().contains("mid"))
    }

    @Test func noGapWhenFullCoverage() {
        var wardrobe = fullWardrobe()
        wardrobe.append(makeGarment(name: "Coat", category: .upper, baseGroup: .coat, temperature: 1))
        let result = DailyOutfitEngine.recommend(
            items: wardrobe,
            profile: makeProfile(),
            wearLog: [],
            wornOutfits: []
        )
        #expect(result.primaryGap == nil)
    }

    // MARK: - Determinism

    @Test func deterministic() {
        let wardrobe = fullWardrobe()
        let profile = makeProfile()
        let r1 = DailyOutfitEngine.recommend(items: wardrobe, profile: profile, wearLog: [], wornOutfits: [])
        let r2 = DailyOutfitEngine.recommend(items: wardrobe, profile: profile, wearLog: [], wornOutfits: [])
        #expect(abs(r1.clarityScore - r2.clarityScore) < 0.001)
        #expect(r1.clarityBand == r2.clarityBand)
        #expect(r1.primaryGap == r2.primaryGap)
    }
}
