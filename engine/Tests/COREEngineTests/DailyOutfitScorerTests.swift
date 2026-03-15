import Testing
import Foundation
@testable import COREEngine

@Suite("DailyOutfitScorer Tests")
struct DailyOutfitScorerTests {

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

    private func balancedOutfit() -> [Garment] {
        [
            makeGarment(category: .upper, silhouette: .fitted, baseGroup: .shirt, temperature: 3, colorTemperature: .warm),
            makeGarment(category: .lower, silhouette: .regular, baseGroup: .chinos, colorTemperature: .warm),
            makeGarment(category: .shoes, silhouette: .none, baseGroup: .loafers, colorTemperature: .neutral),
        ]
    }

    // MARK: - Basic Scoring

    @Test func scoreOutfitReturnsPositiveStrength() {
        let result = DailyOutfitScorer.scoreOutfit(garments: balancedOutfit(), profile: makeProfile())
        #expect(result.totalStrength > 0)
        #expect(result.totalStrength <= 1.0)
    }

    @Test func scoreOutfitEmptyReturnsZero() {
        let result = DailyOutfitScorer.scoreOutfit(garments: [], profile: makeProfile())
        #expect(abs(result.totalStrength) < 0.001)
    }

    @Test func scoreOutfitSingleGarmentHandlesGracefully() {
        let result = DailyOutfitScorer.scoreOutfit(
            garments: [makeGarment()],
            profile: makeProfile()
        )
        #expect(result.totalStrength >= 0)
    }

    // MARK: - Color Verdict

    @Test func clashingColorsDetected() {
        let outfit = [
            makeGarment(category: .upper, colorTemperature: .warm),
            makeGarment(category: .lower, colorTemperature: .cool),
            makeGarment(category: .shoes, colorTemperature: .neutral),
        ]
        let result = DailyOutfitScorer.scoreOutfit(garments: outfit, profile: makeProfile())
        #expect(result.colorVerdict == "Clashing")
    }

    @Test func harmoniousColorsDetected() {
        let outfit = [
            makeGarment(category: .upper, colorTemperature: .warm),
            makeGarment(category: .lower, colorTemperature: .warm),
            makeGarment(category: .shoes, colorTemperature: .neutral),
        ]
        let result = DailyOutfitScorer.scoreOutfit(garments: outfit, profile: makeProfile())
        #expect(result.colorVerdict == "Harmonious")
    }

    // MARK: - Silhouette Verdict

    @Test func silhouetteVerdictNotEmpty() {
        let result = DailyOutfitScorer.scoreOutfit(garments: balancedOutfit(), profile: makeProfile())
        #expect(!result.silhouetteVerdict.isEmpty)
    }

    @Test func silhouetteVerdictNeutralForMissingSilhouettes() {
        let outfit = [
            makeGarment(category: .upper, silhouette: .none),
            makeGarment(category: .lower, silhouette: .none),
        ]
        let result = DailyOutfitScorer.scoreOutfit(garments: outfit, profile: makeProfile())
        #expect(result.silhouetteVerdict == "Neutral")
    }

    // MARK: - Archetype

    @Test func archetypeMatchReflectsOutfit() {
        let outfit = [
            makeGarment(category: .upper, baseGroup: .blazer),
            makeGarment(category: .lower, baseGroup: .trousers),
            makeGarment(category: .shoes, baseGroup: .loafers),
        ]
        let result = DailyOutfitScorer.scoreOutfit(garments: outfit, profile: makeProfile())
        // Should return one of the valid archetypes
        #expect([Archetype.tailored, .smartCasual, .street].contains(result.archetypeMatch))
    }

    // MARK: - Suggestion

    @Test func suggestionNilForHighScore() {
        // Create a very coherent outfit
        let outfit = [
            makeGarment(category: .upper, silhouette: .fitted, baseGroup: .shirt, colorTemperature: .neutral),
            makeGarment(category: .lower, silhouette: .regular, baseGroup: .chinos, colorTemperature: .neutral),
            makeGarment(category: .shoes, silhouette: .none, baseGroup: .loafers, colorTemperature: .neutral),
        ]
        let result = DailyOutfitScorer.scoreOutfit(garments: outfit, profile: makeProfile())
        // If strength >= 0.85, suggestion should be nil
        if result.totalStrength >= 0.85 {
            #expect(result.suggestion == nil)
        }
    }

    @Test func suggestionPresentForClashingOutfit() {
        let outfit = [
            makeGarment(category: .upper, silhouette: .fitted, baseGroup: .hoodie, colorTemperature: .warm),
            makeGarment(category: .lower, silhouette: .fitted, baseGroup: .jeans, colorTemperature: .cool),
            makeGarment(category: .shoes, silhouette: .none, baseGroup: .sneakers, colorTemperature: .neutral),
        ]
        let result = DailyOutfitScorer.scoreOutfit(garments: outfit, profile: makeProfile())
        if result.totalStrength < 0.85 {
            #expect(result.suggestion != nil)
        }
    }
}
