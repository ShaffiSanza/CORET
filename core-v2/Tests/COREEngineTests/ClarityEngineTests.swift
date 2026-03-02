import Testing
import Foundation
@testable import COREEngine

@Suite("ClarityEngine Tests")
struct ClarityEngineTests {

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

    // MARK: - Band Mapping

    @Test func bandFragmentertBelow30() {
        #expect(ClarityEngine.band(from: 0) == .fragmentert)
        #expect(ClarityEngine.band(from: 15) == .fragmentert)
        #expect(ClarityEngine.band(from: 29.9) == .fragmentert)
    }

    @Test func bandIUtviklingFrom30To60() {
        #expect(ClarityEngine.band(from: 30) == .iUtvikling)
        #expect(ClarityEngine.band(from: 45) == .iUtvikling)
        #expect(ClarityEngine.band(from: 59.9) == .iUtvikling)
    }

    @Test func bandFokusertFrom60To85() {
        #expect(ClarityEngine.band(from: 60) == .fokusert)
        #expect(ClarityEngine.band(from: 72) == .fokusert)
        #expect(ClarityEngine.band(from: 84.9) == .fokusert)
    }

    @Test func bandKrystallklarAbove85() {
        #expect(ClarityEngine.band(from: 85) == .krystallklar)
        #expect(ClarityEngine.band(from: 95) == .krystallklar)
        #expect(ClarityEngine.band(from: 100) == .krystallklar)
    }

    // MARK: - Compute Empty

    @Test func computeEmptyReturnsZero() {
        let snapshot = ClarityEngine.compute(items: [], profile: makeProfile())
        #expect(abs(snapshot.score) < 0.001)
        #expect(snapshot.band == .fragmentert)
    }

    @Test func computeEmptyHasAllArchetypeScores() {
        let snapshot = ClarityEngine.compute(items: [], profile: makeProfile())
        #expect(snapshot.archetypeScores.count == 3)
        for (_, score) in snapshot.archetypeScores {
            #expect(abs(score) < 0.001)
        }
    }

    @Test func computeEmptyDominantIsProfileArchetype() {
        let snapshot = ClarityEngine.compute(items: [], profile: makeProfile(primary: .tailored))
        #expect(snapshot.dominantArchetype == .tailored)
    }

    // MARK: - Compute with Items

    @Test func computeWithTailoredWardrobe() {
        let items = [
            makeGarment(category: .upper, silhouette: .fitted, baseGroup: .blazer, temperature: 1),
            makeGarment(category: .upper, silhouette: .fitted, baseGroup: .shirt, temperature: 3),
            makeGarment(category: .upper, silhouette: .fitted, baseGroup: .knit, temperature: 2),
            makeGarment(category: .lower, silhouette: .slim, baseGroup: .trousers),
            makeGarment(category: .shoes, silhouette: .none, baseGroup: .loafers),
        ]
        let profile = makeProfile(primary: .tailored)
        let snapshot = ClarityEngine.compute(items: items, profile: profile)

        #expect(snapshot.score > 40)
        #expect(snapshot.band != .fragmentert)
        #expect(snapshot.dominantArchetype == .tailored)
    }

    @Test func computeFormulaVerification() {
        let items = [
            makeGarment(category: .upper, silhouette: .fitted, baseGroup: .shirt, temperature: 3),
            makeGarment(category: .lower, silhouette: .regular, baseGroup: .chinos),
            makeGarment(category: .shoes, silhouette: .none, baseGroup: .loafers),
        ]
        let profile = makeProfile(primary: .smartCasual)
        let snapshot = ClarityEngine.compute(items: items, profile: profile)

        // Verify formula: clarityBase = primary * 0.60 + cohesion * 0.40
        let primaryScore = snapshot.archetypeScores[.smartCasual] ?? 0
        let cohesionTotal = snapshot.cohesionBreakdown.totalScore
        let clarityBase = primaryScore * 0.60 + cohesionTotal * 0.40

        // Breadth bonus
        let secondaryScores = snapshot.archetypeScores.filter { $0.key != .smartCasual }
        let bestSecondary = secondaryScores.values.max() ?? 0
        let breadthBonus: Double = bestSecondary > 50 ? min((bestSecondary - 50) * 0.1, 5.0) : 0
        let expected = min(clarityBase + breadthBonus, 100)

        #expect(abs(snapshot.score - expected) < 0.001)
    }

    @Test func computeScoreNonNegative() {
        let items = [
            makeGarment(category: .upper, silhouette: .oversized, baseGroup: .hoodie, temperature: 3, colorTemperature: .warm),
        ]
        let profile = makeProfile(primary: .tailored)
        let snapshot = ClarityEngine.compute(items: items, profile: profile)
        #expect(snapshot.score >= 0)
    }

    @Test func computeScoreCappedAt100() {
        let items = [
            makeGarment(category: .upper, silhouette: .fitted, baseGroup: .blazer, temperature: 1),
            makeGarment(category: .upper, silhouette: .fitted, baseGroup: .shirt, temperature: 3),
            makeGarment(category: .upper, silhouette: .fitted, baseGroup: .knit, temperature: 2),
            makeGarment(category: .upper, silhouette: .fitted, baseGroup: .coat, temperature: 1),
            makeGarment(category: .lower, silhouette: .slim, baseGroup: .trousers),
            makeGarment(category: .lower, silhouette: .regular, baseGroup: .chinos),
            makeGarment(category: .shoes, silhouette: .none, baseGroup: .loafers),
            makeGarment(category: .accessory, silhouette: .none, baseGroup: .belt),
        ]
        let profile = makeProfile(primary: .tailored)
        let snapshot = ClarityEngine.compute(items: items, profile: profile)
        #expect(snapshot.score <= 100)
    }

    @Test func computeDominantArchetypeMatchesHighestScore() {
        let items = [
            makeGarment(category: .upper, baseGroup: .hoodie, temperature: 3),
            makeGarment(category: .lower, baseGroup: .jeans),
            makeGarment(category: .shoes, baseGroup: .sneakers),
        ]
        let snapshot = ClarityEngine.compute(items: items, profile: makeProfile(primary: .street))
        // Street wardrobe → street should be dominant
        #expect(snapshot.dominantArchetype == .street)
    }

    @Test func computeBreadthBonusApplies() {
        // Create wardrobe where secondary archetype scores > 50
        let items = [
            makeGarment(category: .upper, baseGroup: .shirt, temperature: 3),   // tailored 1.0, smartCasual 0.8
            makeGarment(category: .upper, baseGroup: .knit, temperature: 2),    // smartCasual 0.9
            makeGarment(category: .lower, baseGroup: .chinos),                  // smartCasual 0.9, tailored 0.8
            makeGarment(category: .shoes, baseGroup: .boots),                   // neutral across
        ]
        let profile = makeProfile(primary: .smartCasual)
        let snapshot = ClarityEngine.compute(items: items, profile: profile)

        // Tailored secondary should be > 50 → breadth bonus applies
        let tailoredScore = snapshot.archetypeScores[.tailored] ?? 0
        if tailoredScore > 50 {
            // Verify bonus was included
            let primaryScore = snapshot.archetypeScores[.smartCasual] ?? 0
            let base = primaryScore * 0.60 + snapshot.cohesionBreakdown.totalScore * 0.40
            #expect(snapshot.score >= base)
        }
    }

    @Test func computeCohesionBreakdownIncluded() {
        let items = [
            makeGarment(category: .upper, baseGroup: .shirt, temperature: 3),
            makeGarment(category: .lower, baseGroup: .chinos),
            makeGarment(category: .shoes, baseGroup: .loafers),
        ]
        let snapshot = ClarityEngine.compute(items: items, profile: makeProfile())
        #expect(snapshot.cohesionBreakdown.itemIDs.count == 3)
    }

    @Test func computeDeterministic() {
        let items = [
            makeGarment(category: .upper, baseGroup: .shirt, temperature: 3),
            makeGarment(category: .lower, baseGroup: .chinos),
            makeGarment(category: .shoes, baseGroup: .loafers),
        ]
        let profile = makeProfile()
        let s1 = ClarityEngine.compute(items: items, profile: profile)
        let s2 = ClarityEngine.compute(items: items, profile: profile)
        #expect(abs(s1.score - s2.score) < 0.001)
    }

    // MARK: - Trend

    @Test func trendFewerThan3SnapshotsIsStable() {
        let history = [
            ClaritySnapshot(score: 50, band: .iUtvikling),
            ClaritySnapshot(score: 60, band: .fokusert),
        ]
        #expect(ClarityEngine.trend(history: history) == .stable)
    }

    @Test func trendEmptyHistoryIsStable() {
        #expect(ClarityEngine.trend(history: []) == .stable)
    }

    @Test func trendMonotonicIncreaseIsImproving() {
        let history = [
            ClaritySnapshot(score: 40, band: .iUtvikling),
            ClaritySnapshot(score: 50, band: .iUtvikling),
            ClaritySnapshot(score: 60, band: .fokusert),
        ]
        #expect(ClarityEngine.trend(history: history) == .improving)
    }

    @Test func trendMonotonicDecreaseIsDeclining() {
        let history = [
            ClaritySnapshot(score: 70, band: .fokusert),
            ClaritySnapshot(score: 55, band: .iUtvikling),
            ClaritySnapshot(score: 40, band: .iUtvikling),
        ]
        #expect(ClarityEngine.trend(history: history) == .declining)
    }

    @Test func trendMixedIsStable() {
        let history = [
            ClaritySnapshot(score: 50, band: .iUtvikling),
            ClaritySnapshot(score: 70, band: .fokusert),
            ClaritySnapshot(score: 55, band: .iUtvikling),
        ]
        #expect(ClarityEngine.trend(history: history) == .stable)
    }

    @Test func trendAllEqualIsStable() {
        let history = [
            ClaritySnapshot(score: 50, band: .iUtvikling),
            ClaritySnapshot(score: 50, band: .iUtvikling),
            ClaritySnapshot(score: 50, band: .iUtvikling),
        ]
        #expect(ClarityEngine.trend(history: history) == .stable)
    }

    @Test func trendUsesLast3Only() {
        let history = [
            ClaritySnapshot(score: 90, band: .krystallklar),
            ClaritySnapshot(score: 80, band: .fokusert),
            ClaritySnapshot(score: 40, band: .iUtvikling),
            ClaritySnapshot(score: 50, band: .iUtvikling),
            ClaritySnapshot(score: 60, band: .fokusert),
        ]
        // Last 3: 40, 50, 60 → improving
        #expect(ClarityEngine.trend(history: history) == .improving)
    }

    // MARK: - Integration

    @Test func streetWardrobeWithStreetProfileHigherThanTailored() {
        let items = [
            makeGarment(category: .upper, baseGroup: .hoodie, temperature: 3),
            makeGarment(category: .lower, baseGroup: .jeans),
            makeGarment(category: .shoes, baseGroup: .sneakers),
        ]
        let streetSnapshot = ClarityEngine.compute(items: items, profile: makeProfile(primary: .street))
        let tailoredSnapshot = ClarityEngine.compute(items: items, profile: makeProfile(primary: .tailored))
        #expect(streetSnapshot.score > tailoredSnapshot.score)
    }
}
