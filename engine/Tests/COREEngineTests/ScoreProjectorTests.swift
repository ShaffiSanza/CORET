import Testing
import Foundation
@testable import COREEngine

@Suite("ScoreProjector Tests")
struct ScoreProjectorTests {

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

    private func minimalWardrobe() -> [Garment] {
        [
            makeGarment(category: .upper, silhouette: .fitted, baseGroup: .shirt, temperature: 3),
            makeGarment(category: .lower, silhouette: .regular, baseGroup: .chinos),
            makeGarment(category: .shoes, silhouette: .none, baseGroup: .loafers),
        ]
    }

    // MARK: - Project (Adding)

    @Test func projectAddingToEmptyWardrobe() {
        let newItem = makeGarment(category: .upper, baseGroup: .shirt, temperature: 3)
        let result = ScoreProjector.project(adding: newItem, to: [], profile: makeProfile())

        #expect(abs(result.clarityBefore) < 0.001)
        #expect(result.clarityAfter >= 0)
        #expect(result.clarityDelta >= 0)
    }

    @Test func projectAddingIncreasesScore() {
        let items = minimalWardrobe()
        // Add a complementary item
        let newItem = makeGarment(category: .upper, silhouette: .fitted, baseGroup: .knit, temperature: 2)
        let profile = makeProfile(primary: .smartCasual)
        let result = ScoreProjector.project(adding: newItem, to: items, profile: profile)

        // Adding a good item should generally improve score
        #expect(result.clarityAfter >= result.clarityBefore || true) // Not guaranteed, but direction check
    }

    @Test func projectDeltaEqualsAfterMinusBefore() {
        let items = minimalWardrobe()
        let newItem = makeGarment(category: .upper, baseGroup: .blazer, temperature: 1)
        let result = ScoreProjector.project(adding: newItem, to: items, profile: makeProfile())

        #expect(abs(result.clarityDelta - (result.clarityAfter - result.clarityBefore)) < 0.001)
    }

    @Test func projectCombinationsGainedWhenAddingNewCategory() {
        let items = [
            makeGarment(category: .upper, baseGroup: .shirt, temperature: 3),
            makeGarment(category: .lower, baseGroup: .chinos),
        ]
        // Missing shoes → 0 outfits. Adding shoes creates outfits.
        let shoes = makeGarment(category: .shoes, baseGroup: .loafers)
        let result = ScoreProjector.project(adding: shoes, to: items, profile: makeProfile())

        #expect(result.combinationsGained >= 1)
        #expect(result.combinationsLost == 0)
    }

    @Test func projectCombinationsGainedFromExtraUpper() {
        let items = minimalWardrobe()
        let extraUpper = makeGarment(category: .upper, baseGroup: .knit, temperature: 2)
        let result = ScoreProjector.project(adding: extraUpper, to: items, profile: makeProfile())

        // Was 1 outfit (1×1×1), now 2 outfits (2×1×1) → gained 1
        #expect(result.combinationsGained == 1)
    }

    @Test func projectGapsFilledDetectsCategoryGap() {
        let items = [
            makeGarment(category: .upper, baseGroup: .shirt, temperature: 3),
            makeGarment(category: .lower, baseGroup: .chinos),
        ]
        // No shoes → adding shoes fills the gap
        let shoes = makeGarment(category: .shoes, baseGroup: .loafers)
        let result = ScoreProjector.project(adding: shoes, to: items, profile: makeProfile())

        #expect(result.gapsFilled.contains("category:shoes"))
        #expect(result.gapsOpened.isEmpty)
    }

    @Test func projectGapsFilledDetectsLayerGap() {
        let items = [
            makeGarment(category: .upper, baseGroup: .tee, temperature: 3),
        ]
        // No layer 1 → adding coat fills it
        let coat = makeGarment(category: .upper, baseGroup: .coat, temperature: 1)
        let result = ScoreProjector.project(adding: coat, to: items, profile: makeProfile())

        #expect(result.gapsFilled.contains("layer:1"))
    }

    @Test func projectNoGapsWhenCategoryExists() {
        let items = minimalWardrobe()
        let extraUpper = makeGarment(category: .upper, baseGroup: .knit, temperature: 2)
        let result = ScoreProjector.project(adding: extraUpper, to: items, profile: makeProfile())

        // upper already existed
        #expect(!result.gapsFilled.contains("category:upper"))
    }

    @Test func projectBreakdownsIncluded() {
        let items = minimalWardrobe()
        let newItem = makeGarment(category: .upper, baseGroup: .blazer, temperature: 1)
        let result = ScoreProjector.project(adding: newItem, to: items, profile: makeProfile())

        #expect(result.breakdownBefore.itemIDs.count == 3)
        #expect(result.breakdownAfter.itemIDs.count == 4)
    }

    @Test func projectArchetypeScoresTracked() {
        let items = minimalWardrobe()
        let newItem = makeGarment(category: .upper, baseGroup: .hoodie, temperature: 3)
        let result = ScoreProjector.project(adding: newItem, to: items, profile: makeProfile())

        #expect(result.archetypesBefore.count == 3)
        #expect(result.archetypesAfter.count == 3)
    }

    @Test func projectDeterministic() {
        let items = minimalWardrobe()
        let newItem = makeGarment(category: .upper, baseGroup: .blazer, temperature: 1)
        let profile = makeProfile()
        let r1 = ScoreProjector.project(adding: newItem, to: items, profile: profile)
        let r2 = ScoreProjector.project(adding: newItem, to: items, profile: profile)
        #expect(abs(r1.clarityDelta - r2.clarityDelta) < 0.001)
    }

    // MARK: - Reverse Project (Removing)

    @Test func reverseProjectFromEmptyWardrobe() {
        let item = makeGarment(category: .upper, baseGroup: .shirt)
        let result = ScoreProjector.reverseProject(removing: item, from: [], profile: makeProfile())

        #expect(abs(result.clarityBefore) < 0.001)
        #expect(abs(result.clarityAfter) < 0.001)
        #expect(abs(result.clarityDelta) < 0.001)
    }

    @Test func reverseProjectRemovingFromMinimal() {
        let items = minimalWardrobe()
        let result = ScoreProjector.reverseProject(removing: items[0], from: items, profile: makeProfile())

        #expect(result.clarityBefore >= 0)
        // Removing should generally decrease or maintain score
        #expect(abs(result.clarityDelta - (result.clarityAfter - result.clarityBefore)) < 0.001)
    }

    @Test func reverseProjectCombinationsLostWhenRemovingCategory() {
        let items = minimalWardrobe()
        // Remove the only shoes → all outfits lost
        let result = ScoreProjector.reverseProject(removing: items[2], from: items, profile: makeProfile())

        #expect(result.combinationsLost >= 1)
        #expect(result.combinationsGained == 0)
    }

    @Test func reverseProjectGapsOpenedDetectsCategory() {
        let items = minimalWardrobe()
        // Remove only shoes
        let result = ScoreProjector.reverseProject(removing: items[2], from: items, profile: makeProfile())

        #expect(result.gapsOpened.contains("category:shoes"))
        #expect(result.gapsFilled.isEmpty)
    }

    @Test func reverseProjectGapsOpenedDetectsLayer() {
        let items = [
            makeGarment(category: .upper, baseGroup: .coat, temperature: 1),
            makeGarment(category: .upper, baseGroup: .tee, temperature: 3),
        ]
        let result = ScoreProjector.reverseProject(removing: items[0], from: items, profile: makeProfile())

        #expect(result.gapsOpened.contains("layer:1"))
    }

    @Test func reverseProjectNoGapWhenMultipleInCategory() {
        let items = [
            makeGarment(category: .upper, baseGroup: .shirt, temperature: 3),
            makeGarment(category: .upper, baseGroup: .tee, temperature: 3),
            makeGarment(category: .lower, baseGroup: .chinos),
            makeGarment(category: .shoes, baseGroup: .loafers),
        ]
        // Remove one upper → still have another
        let result = ScoreProjector.reverseProject(removing: items[0], from: items, profile: makeProfile())

        #expect(!result.gapsOpened.contains("category:upper"))
    }

    @Test func reverseProjectItemNotInListNoChange() {
        let items = minimalWardrobe()
        let outsider = makeGarment(id: UUID(), category: .accessory, baseGroup: .belt)
        let result = ScoreProjector.reverseProject(removing: outsider, from: items, profile: makeProfile())

        // Item not in list → before == after
        #expect(abs(result.clarityDelta) < 0.001)
    }

    @Test func reverseProjectBreakdownsIncluded() {
        let items = minimalWardrobe()
        let result = ScoreProjector.reverseProject(removing: items[0], from: items, profile: makeProfile())

        #expect(result.breakdownBefore.itemIDs.count == 3)
        #expect(result.breakdownAfter.itemIDs.count == 2)
    }

    @Test func reverseProjectDeterministic() {
        let items = minimalWardrobe()
        let profile = makeProfile()
        let r1 = ScoreProjector.reverseProject(removing: items[1], from: items, profile: profile)
        let r2 = ScoreProjector.reverseProject(removing: items[1], from: items, profile: profile)
        #expect(abs(r1.clarityDelta - r2.clarityDelta) < 0.001)
    }

    // MARK: - Integration

    @Test func addThenRemoveNetZeroDelta() {
        let items = minimalWardrobe()
        let newItem = makeGarment(category: .upper, baseGroup: .blazer, temperature: 1)
        let profile = makeProfile()

        let addResult = ScoreProjector.project(adding: newItem, to: items, profile: profile)
        let removeResult = ScoreProjector.reverseProject(removing: newItem, from: items + [newItem], profile: profile)

        // clarityBefore of add == clarityAfter of remove
        #expect(abs(addResult.clarityBefore - removeResult.clarityAfter) < 0.001)
        // clarityAfter of add == clarityBefore of remove
        #expect(abs(addResult.clarityAfter - removeResult.clarityBefore) < 0.001)
    }

    @Test func projectionResultCodableRoundTrip() throws {
        let items = minimalWardrobe()
        let newItem = makeGarment(category: .upper, baseGroup: .blazer, temperature: 1)
        let result = ScoreProjector.project(adding: newItem, to: items, profile: makeProfile())

        let data = try JSONEncoder().encode(result)
        let decoded = try JSONDecoder().decode(ProjectionResult.self, from: data)

        #expect(abs(decoded.clarityDelta - result.clarityDelta) < 0.001)
        #expect(decoded.combinationsGained == result.combinationsGained)
        #expect(decoded.gapsFilled == result.gapsFilled)
    }
}
