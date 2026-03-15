import Testing
import Foundation
@testable import COREEngine

@Suite("StyleDirectionEngine Tests")
struct StyleDirectionEngineTests {

    // MARK: - Helpers

    private func makeGarment(
        category: Category = .upper,
        silhouette: Silhouette = .fitted,
        baseGroup: BaseGroup = .tee,
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

    private func makeProfile(primary: Archetype = .smartCasual) -> UserProfile {
        UserProfile(primaryArchetype: primary)
    }

    private func streetWardrobe() -> [Garment] {
        [
            makeGarment(category: .upper, baseGroup: .hoodie, temperature: 3),
            makeGarment(category: .upper, baseGroup: .tee, temperature: 3),
            makeGarment(category: .lower, baseGroup: .jeans),
            makeGarment(category: .shoes, baseGroup: .sneakers),
        ]
    }

    // MARK: - Empty Wardrobe

    @Test func emptyWardrobeReturnsZeroScore() {
        let result = StyleDirectionEngine.analyzeDirection(items: [], profile: makeProfile(), target: .tailored)
        #expect(abs(result.currentScore) < 0.001)
        #expect(result.totalGarments == 0)
        #expect(result.existingMatches == 0)
    }

    @Test func emptyWardrobeStillSuggests() {
        let result = StyleDirectionEngine.analyzeDirection(items: [], profile: makeProfile(), target: .tailored)
        #expect(!result.suggestions.isEmpty)
    }

    // MARK: - Current Score

    @Test func currentScoreReflectsArchetype() {
        let items = streetWardrobe()
        let streetResult = StyleDirectionEngine.analyzeDirection(items: items, profile: makeProfile(), target: .street)
        let tailoredResult = StyleDirectionEngine.analyzeDirection(items: items, profile: makeProfile(), target: .tailored)

        // Street wardrobe should score higher for street than tailored
        #expect(streetResult.currentScore > tailoredResult.currentScore)
    }

    @Test func targetArchetypeSetCorrectly() {
        let result = StyleDirectionEngine.analyzeDirection(items: streetWardrobe(), profile: makeProfile(), target: .tailored)
        #expect(result.targetArchetype == .tailored)
    }

    // MARK: - Suggestions

    @Test func suggestionsNotEmpty() {
        let result = StyleDirectionEngine.analyzeDirection(items: streetWardrobe(), profile: makeProfile(), target: .tailored)
        #expect(!result.suggestions.isEmpty)
    }

    @Test func suggestionsRespectsLimit() {
        let result = StyleDirectionEngine.analyzeDirection(items: streetWardrobe(), profile: makeProfile(), target: .tailored, suggestionLimit: 2)
        #expect(result.suggestions.count <= 2)
    }

    @Test func suggestionsHavePositiveAffinity() {
        let result = StyleDirectionEngine.analyzeDirection(items: streetWardrobe(), profile: makeProfile(), target: .tailored)
        for suggestion in result.suggestions {
            #expect(suggestion.affinity >= 0.5)
        }
    }

    @Test func tailoredSuggestionsIncludeBlazer() {
        let result = StyleDirectionEngine.analyzeDirection(items: streetWardrobe(), profile: makeProfile(), target: .tailored)
        let baseGroups = result.suggestions.map(\.baseGroup)
        #expect(baseGroups.contains(.blazer))
    }

    @Test func suggestionsLabelContainsArchetype() {
        let result = StyleDirectionEngine.analyzeDirection(items: streetWardrobe(), profile: makeProfile(), target: .tailored)
        for suggestion in result.suggestions {
            #expect(suggestion.label.contains("Tailored"))
        }
    }

    // MARK: - Projected Score

    @Test func projectedScoreHigherThanCurrent() {
        let result = StyleDirectionEngine.analyzeDirection(items: streetWardrobe(), profile: makeProfile(), target: .tailored)
        #expect(result.projectedScore >= result.currentScore)
    }

    // MARK: - Existing Matches

    @Test func existingMatchesCounted() {
        // Blazer has high tailored affinity
        let items = [
            makeGarment(category: .upper, baseGroup: .blazer, temperature: 2),
            makeGarment(category: .lower, baseGroup: .trousers),
            makeGarment(category: .shoes, baseGroup: .loafers),
        ]
        let result = StyleDirectionEngine.analyzeDirection(items: items, profile: makeProfile(), target: .tailored)
        #expect(result.existingMatches > 0)
    }

    @Test func streetWardrobeHasLowTailoredMatches() {
        let result = StyleDirectionEngine.analyzeDirection(items: streetWardrobe(), profile: makeProfile(), target: .tailored)
        // Hoodie/tee/jeans/sneakers have low tailored affinity
        #expect(result.existingMatches == 0)
    }

    // MARK: - Prioritizes New Base Groups

    @Test func suggestionsPreferNewBaseGroups() {
        // User already has a blazer — suggestions should prefer base groups they don't have
        let items = [
            makeGarment(category: .upper, baseGroup: .blazer, temperature: 2),
            makeGarment(category: .lower, baseGroup: .jeans),
            makeGarment(category: .shoes, baseGroup: .sneakers),
        ]
        let result = StyleDirectionEngine.analyzeDirection(items: items, profile: makeProfile(), target: .tailored)
        // First suggestion should NOT be blazer since user already has one
        if let first = result.suggestions.first {
            #expect(first.baseGroup != .blazer)
        }
    }

    // MARK: - Determinism

    @Test func deterministic() {
        let items = streetWardrobe()
        let profile = makeProfile()
        let r1 = StyleDirectionEngine.analyzeDirection(items: items, profile: profile, target: .tailored)
        let r2 = StyleDirectionEngine.analyzeDirection(items: items, profile: profile, target: .tailored)

        #expect(abs(r1.currentScore - r2.currentScore) < 0.001)
        #expect(abs(r1.projectedScore - r2.projectedScore) < 0.001)
        #expect(r1.suggestions.count == r2.suggestions.count)
        #expect(r1.existingMatches == r2.existingMatches)
    }
}
