import Testing
import Foundation
@testable import COREEngine

@Suite("BestOutfitFinder Tests")
struct BestOutfitFinderTests {

    // MARK: - Helpers

    private func makeGarment(
        id: UUID = UUID(),
        category: Category = .upper,
        silhouette: Silhouette = .fitted,
        baseGroup: BaseGroup = .tee,
        temperature: Int? = 3,
        colorTemperature: ColorTemp = .neutral
    ) -> Garment {
        Garment(
            id: id,
            category: category,
            silhouette: silhouette,
            baseGroup: baseGroup,
            temperature: temperature,
            colorTemperature: colorTemperature
        )
    }

    private func makeProfile(primary: Archetype = .smartCasual) -> UserProfile {
        UserProfile(primaryArchetype: primary)
    }

    private func fullWardrobe() -> [Garment] {
        [
            makeGarment(category: .upper, silhouette: .fitted, baseGroup: .shirt, temperature: 3),
            makeGarment(category: .upper, silhouette: .relaxed, baseGroup: .hoodie, temperature: 3),
            makeGarment(category: .lower, silhouette: .regular, baseGroup: .chinos),
            makeGarment(category: .lower, silhouette: .slim, baseGroup: .jeans),
            makeGarment(category: .shoes, silhouette: .none, baseGroup: .loafers),
            makeGarment(category: .shoes, silhouette: .none, baseGroup: .sneakers),
        ]
    }

    // MARK: - findBest

    @Test func findBestReturnsSortedByStrength() {
        let results = BestOutfitFinder.findBest(items: fullWardrobe(), profile: makeProfile())
        for i in 0..<(results.count - 1) {
            #expect(results[i].strength >= results[i + 1].strength)
        }
    }

    @Test func findBestRespectsCount() {
        let results = BestOutfitFinder.findBest(items: fullWardrobe(), profile: makeProfile(), count: 2)
        #expect(results.count <= 2)
    }

    @Test func findBestEmptyWardrobe() {
        let results = BestOutfitFinder.findBest(items: [], profile: makeProfile())
        #expect(results.isEmpty)
    }

    @Test func findBestMissingCategory() {
        let items = [
            makeGarment(category: .upper, baseGroup: .shirt),
            makeGarment(category: .upper, baseGroup: .tee),
        ]
        let results = BestOutfitFinder.findBest(items: items, profile: makeProfile())
        #expect(results.isEmpty)
    }

    @Test func findBestOutfitsHaveThreeGarments() {
        let results = BestOutfitFinder.findBest(items: fullWardrobe(), profile: makeProfile())
        for outfit in results {
            #expect(outfit.garments.count == 3)
        }
    }

    @Test func findBestLabelContainsArchetypeName() {
        let results = BestOutfitFinder.findBest(items: fullWardrobe(), profile: makeProfile())
        guard let first = results.first else { return }
        let hasArchetype = first.label.contains("Tailored") || first.label.contains("Smart Casual") || first.label.contains("Street")
        #expect(hasArchetype)
    }

    // MARK: - findUntriedBest

    @Test func findUntriedBestFiltersWornOutfits() {
        let wardrobe = fullWardrobe()
        let allOutfits = BestOutfitFinder.findBest(items: wardrobe, profile: makeProfile())

        guard let firstOutfit = allOutfits.first else { return }
        let wornSet: Set<Set<UUID>> = [Set(firstOutfit.garments.map(\.id))]

        let untried = BestOutfitFinder.findUntriedBest(items: wardrobe, wornOutfits: wornSet, profile: makeProfile())

        // The worn outfit should not appear
        for outfit in untried {
            let ids = Set(outfit.garments.map(\.id))
            #expect(!wornSet.contains(ids))
        }
    }

    @Test func findUntriedBestAllWornReturnsEmpty() {
        let wardrobe = fullWardrobe()
        let allOutfits = BestOutfitFinder.findBest(items: wardrobe, profile: makeProfile(), count: 100)
        let allWorn: Set<Set<UUID>> = Set(allOutfits.map { Set($0.garments.map(\.id)) })

        let untried = BestOutfitFinder.findUntriedBest(items: wardrobe, wornOutfits: allWorn, profile: makeProfile())
        #expect(untried.isEmpty)
    }

    @Test func findUntriedBestEmptyWornSameAsFindBest() {
        let wardrobe = fullWardrobe()
        let best = BestOutfitFinder.findBest(items: wardrobe, profile: makeProfile(), count: 3)
        let untried = BestOutfitFinder.findUntriedBest(items: wardrobe, wornOutfits: [], profile: makeProfile(), count: 3)

        #expect(best.count == untried.count)
        for (b, u) in zip(best, untried) {
            #expect(abs(b.strength - u.strength) < 0.001)
        }
    }
}
