import Testing
import Foundation
@testable import COREEngine

@Suite("NetworkUnlockCalculator Tests")
struct NetworkUnlockCalculatorTests {

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

    // MARK: - Basic Unlocks

    @Test func addingUpperToWardrobeWithLowerAndShoes() {
        let existing = [
            makeGarment(category: .lower, silhouette: .regular, baseGroup: .chinos),
            makeGarment(category: .shoes, silhouette: .none, baseGroup: .loafers),
        ]
        let newUpper = makeGarment(category: .upper, baseGroup: .shirt, temperature: 3)
        let result = NetworkUnlockCalculator.calculateUnlocks(adding: newUpper, to: existing, profile: makeProfile())

        #expect(result.newCombinationCount > 0)
    }

    @Test func addingToEmptyWardrobe() {
        let result = NetworkUnlockCalculator.calculateUnlocks(
            adding: makeGarment(category: .upper),
            to: [],
            profile: makeProfile()
        )
        #expect(result.newCombinationCount == 0)
    }

    @Test func addingSecondUpperIncreasesCount() {
        let existing = [
            makeGarment(category: .upper, baseGroup: .shirt, temperature: 3),
            makeGarment(category: .lower, baseGroup: .chinos),
            makeGarment(category: .shoes, baseGroup: .loafers),
        ]
        let newUpper = makeGarment(category: .upper, baseGroup: .tee, temperature: 3)
        let result = NetworkUnlockCalculator.calculateUnlocks(adding: newUpper, to: existing, profile: makeProfile())

        // Adding a second upper with 1 lower + 1 shoe = 1 new combo
        #expect(result.newCombinationCount == 1)
    }

    @Test func addingShoesMultipliesCombinations() {
        let existing = [
            makeGarment(category: .upper, baseGroup: .shirt, temperature: 3),
            makeGarment(category: .upper, baseGroup: .tee, temperature: 3),
            makeGarment(category: .lower, baseGroup: .chinos),
            makeGarment(category: .shoes, baseGroup: .loafers),
        ]
        let newShoes = makeGarment(category: .shoes, baseGroup: .sneakers)
        let result = NetworkUnlockCalculator.calculateUnlocks(adding: newShoes, to: existing, profile: makeProfile())

        // 2 uppers * 1 lower * 1 new shoe = 2 new combos
        #expect(result.newCombinationCount == 2)
    }

    // MARK: - Top New Outfits

    @Test func topNewOutfitsMaxThree() {
        let existing = [
            makeGarment(category: .upper, baseGroup: .shirt, temperature: 3),
            makeGarment(category: .upper, baseGroup: .tee, temperature: 3),
            makeGarment(category: .upper, baseGroup: .hoodie, temperature: 3),
            makeGarment(category: .upper, baseGroup: .blazer, temperature: 2),
            makeGarment(category: .shoes, baseGroup: .loafers),
        ]
        let newLower = makeGarment(category: .lower, baseGroup: .chinos)
        let result = NetworkUnlockCalculator.calculateUnlocks(adding: newLower, to: existing, profile: makeProfile())

        #expect(result.topNewOutfits.count <= 3)
    }

    @Test func topNewOutfitsSortedByStrength() {
        let existing = [
            makeGarment(category: .upper, baseGroup: .shirt, temperature: 3),
            makeGarment(category: .upper, baseGroup: .tee, temperature: 3),
            makeGarment(category: .shoes, baseGroup: .loafers),
        ]
        let newLower = makeGarment(category: .lower, baseGroup: .chinos)
        let result = NetworkUnlockCalculator.calculateUnlocks(adding: newLower, to: existing, profile: makeProfile())

        for i in 0..<(result.topNewOutfits.count - 1) {
            #expect(result.topNewOutfits[i].strength >= result.topNewOutfits[i + 1].strength)
        }
    }

    // MARK: - Gaps

    @Test func gapsFilledWhenCategoryMissing() {
        let existing = [
            makeGarment(category: .upper, baseGroup: .shirt, temperature: 3),
            makeGarment(category: .shoes, baseGroup: .loafers),
        ]
        let newLower = makeGarment(category: .lower, baseGroup: .chinos)
        let result = NetworkUnlockCalculator.calculateUnlocks(adding: newLower, to: existing, profile: makeProfile())

        #expect(result.gapsFilled.contains("category:lower"))
    }

    @Test func gapsEmptyWhenCategoryExists() {
        let existing = [
            makeGarment(category: .upper, baseGroup: .shirt, temperature: 3),
            makeGarment(category: .lower, baseGroup: .chinos),
            makeGarment(category: .shoes, baseGroup: .loafers),
        ]
        let newUpper = makeGarment(category: .upper, baseGroup: .tee, temperature: 3)
        let result = NetworkUnlockCalculator.calculateUnlocks(adding: newUpper, to: existing, profile: makeProfile())

        #expect(!result.gapsFilled.contains("category:upper"))
    }
}
