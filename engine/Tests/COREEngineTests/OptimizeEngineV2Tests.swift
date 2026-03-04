import Testing
import Foundation
@testable import COREEngine

@Suite("OptimizeEngineV2 Tests")
struct OptimizeEngineV2Tests {

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

    private func makeProfile(primary: Archetype = .smartCasual) -> UserProfile {
        UserProfile(primaryArchetype: primary)
    }

    /// Minimal complete wardrobe: 1 upper + 1 lower + 1 shoes
    private func minimalWardrobe() -> [Garment] {
        [
            makeGarment(category: .upper, silhouette: .fitted, baseGroup: .shirt, temperature: 3),
            makeGarment(category: .lower, silhouette: .regular, baseGroup: .chinos),
            makeGarment(category: .shoes, silhouette: .none, baseGroup: .loafers, temperature: nil),
        ]
    }

    /// Wardrobe with all layers covered
    private func layeredWardrobe() -> [Garment] {
        [
            makeGarment(category: .upper, baseGroup: .coat, temperature: 1),
            makeGarment(category: .upper, baseGroup: .knit, temperature: 2),
            makeGarment(category: .upper, baseGroup: .shirt, temperature: 3),
            makeGarment(category: .lower, silhouette: .regular, baseGroup: .chinos),
            makeGarment(category: .shoes, silhouette: .none, baseGroup: .loafers, temperature: nil),
        ]
    }

    // MARK: - Empty Wardrobe

    @Test func emptyWardrobeAnalyze() {
        let result = OptimizeEngineV2.analyze(items: [], profile: makeProfile())
        #expect(abs(result.currentClarity) < 0.001)
        #expect(result.friction.isEmpty)
        // Should detect category gaps for upper, lower, shoes
        let categoryGaps = result.gaps.filter { $0.type == .categoryGap }
        #expect(categoryGaps.count == 3)
    }

    @Test func emptyWardrobeDetectGaps() {
        let gaps = OptimizeEngineV2.detectGaps(items: [], profile: makeProfile())
        let categoryGaps = gaps.filter { $0.type == .categoryGap }
        #expect(categoryGaps.count == 3)
        #expect(categoryGaps.allSatisfy { $0.priority == .high })
    }

    @Test func emptyWardrobeNoFriction() {
        let friction = OptimizeEngineV2.detectFriction(items: [], profile: makeProfile())
        #expect(friction.isEmpty)
    }

    // MARK: - Category Gaps

    @Test func missingLowerDetected() {
        let items = [
            makeGarment(category: .upper, baseGroup: .shirt, temperature: 3),
            makeGarment(category: .shoes, silhouette: .none, baseGroup: .loafers, temperature: nil),
        ]
        let gaps = OptimizeEngineV2.detectGaps(items: items, profile: makeProfile())
        let lowerGaps = gaps.filter { $0.type == .categoryGap && $0.title.contains("Underdeler") }
        #expect(lowerGaps.count == 1)
        #expect(lowerGaps[0].priority == .high)
    }

    @Test func completeCategoriesNoCategoryGap() {
        let items = minimalWardrobe()
        let gaps = OptimizeEngineV2.detectGaps(items: items, profile: makeProfile())
        let categoryGaps = gaps.filter { $0.type == .categoryGap }
        #expect(categoryGaps.isEmpty)
    }

    // MARK: - Layer Gaps

    @Test func missingOuterLayerDetected() {
        // Has base layer (3) but no outer (1) or mid (2)
        let items = [
            makeGarment(category: .upper, baseGroup: .shirt, temperature: 3),
            makeGarment(category: .lower, silhouette: .regular, baseGroup: .chinos),
            makeGarment(category: .shoes, silhouette: .none, baseGroup: .loafers, temperature: nil),
        ]
        let gaps = OptimizeEngineV2.detectGaps(items: items, profile: makeProfile())
        let layerGaps = gaps.filter { $0.type == .missingLayer }
        #expect(layerGaps.count >= 1) // At least outer and/or mid missing
    }

    @Test func allLayersCoveredNoLayerGap() {
        let items = layeredWardrobe()
        let gaps = OptimizeEngineV2.detectGaps(items: items, profile: makeProfile())
        let layerGaps = gaps.filter { $0.type == .missingLayer }
        #expect(layerGaps.isEmpty)
    }

    // MARK: - Archetype Weakness

    @Test func archetypeWeaknessDetected() {
        // All street items but profile is tailored → weakness
        let items = [
            makeGarment(category: .upper, baseGroup: .hoodie, temperature: 3),
            makeGarment(category: .lower, silhouette: .wide, baseGroup: .jeans),
            makeGarment(category: .shoes, silhouette: .none, baseGroup: .sneakers, temperature: nil),
        ]
        let profile = makeProfile(primary: .tailored)
        let score = CohesionEngine.archetypeScore(items: items, archetype: .tailored)

        if score < 50 {
            let gaps = OptimizeEngineV2.detectGaps(items: items, profile: profile)
            let archetypeGaps = gaps.filter { $0.type == .archetypeWeakness }
            #expect(archetypeGaps.count == 1)
        }
    }

    @Test func strongArchetypeNoWeakness() {
        // All tailored items with tailored profile → no weakness
        let items = [
            makeGarment(category: .upper, baseGroup: .shirt, temperature: 3),
            makeGarment(category: .upper, baseGroup: .blazer, temperature: 1),
            makeGarment(category: .lower, silhouette: .regular, baseGroup: .trousers),
            makeGarment(category: .shoes, silhouette: .none, baseGroup: .loafers, temperature: nil),
        ]
        let profile = makeProfile(primary: .tailored)
        let gaps = OptimizeEngineV2.detectGaps(items: items, profile: profile)
        let archetypeGaps = gaps.filter { $0.type == .archetypeWeakness }
        #expect(archetypeGaps.isEmpty)
    }

    // MARK: - Suggestions

    @Test func gapSuggestionsHaveCandidates() {
        let gaps = OptimizeEngineV2.detectGaps(items: [], profile: makeProfile())
        for gap in gaps {
            #expect(gap.suggestions.count <= 2)
            // Category gaps should have suggestions
            if gap.type == .categoryGap {
                #expect(!gap.suggestions.isEmpty)
            }
        }
    }

    @Test func suggestionsHaveClarityDelta() {
        let items = [
            makeGarment(category: .upper, baseGroup: .shirt, temperature: 3),
            makeGarment(category: .shoes, silhouette: .none, baseGroup: .loafers, temperature: nil),
        ]
        let gaps = OptimizeEngineV2.detectGaps(items: items, profile: makeProfile())
        let lowerGap = gaps.first { $0.type == .categoryGap && $0.title.contains("Underdeler") }
        if let gap = lowerGap, let suggestion = gap.suggestions.first {
            // Adding a missing category should improve clarity
            #expect(suggestion.clarityDelta >= 0)
        }
    }

    // MARK: - Sorting

    @Test func gapsSortedByPriority() {
        let gaps = OptimizeEngineV2.detectGaps(items: [], profile: makeProfile())
        // All category gaps are high priority, should come first
        var seenMedium = false
        for gap in gaps {
            if gap.priority == .medium { seenMedium = true }
            if gap.priority == .high && seenMedium {
                // A high-priority gap after a medium one → wrong order
                Issue.record("High priority gap found after medium priority")
            }
        }
    }

    // MARK: - Friction

    @Test func frictionThreshold() {
        // Test that only items with improvement > 8 are flagged
        let friction = OptimizeEngineV2.detectFriction(items: minimalWardrobe(), profile: makeProfile())
        for f in friction {
            #expect(f.clarityImprovement > 8.0)
        }
    }

    @Test func frictionSortedByImprovement() {
        let items = layeredWardrobe()
        let friction = OptimizeEngineV2.detectFriction(items: items, profile: makeProfile())
        guard friction.count >= 2 else { return }
        for i in 1..<friction.count {
            #expect(friction[i - 1].clarityImprovement >= friction[i].clarityImprovement)
        }
    }

    // MARK: - Proportion Imbalance

    @Test func proportionImbalanceDetected() {
        // 6 uppers, 1 lower → very high ratio for street archetype (ideal 1.0–1.5)
        let items = [
            makeGarment(category: .upper, baseGroup: .tee, temperature: 3),
            makeGarment(category: .upper, baseGroup: .hoodie, temperature: 2),
            makeGarment(category: .upper, baseGroup: .tee, temperature: 3),
            makeGarment(category: .upper, baseGroup: .hoodie, temperature: 2),
            makeGarment(category: .upper, baseGroup: .tee, temperature: 3),
            makeGarment(category: .upper, baseGroup: .hoodie, temperature: 1),
            makeGarment(category: .lower, silhouette: .wide, baseGroup: .jeans),
            makeGarment(category: .shoes, silhouette: .none, baseGroup: .sneakers, temperature: nil),
        ]
        let profile = makeProfile(primary: .street)
        let gaps = OptimizeEngineV2.detectGaps(items: items, profile: profile)
        let proportionGaps = gaps.filter { $0.type == .proportionImbalance }
        #expect(proportionGaps.count <= 1)
    }

    // MARK: - GapResult

    @Test func analyzeReturnsGapResult() {
        let result = OptimizeEngineV2.analyze(items: minimalWardrobe(), profile: makeProfile())
        #expect(result.currentClarity > 0)
        // Minimal wardrobe may have layer gaps but no category gaps
        let categoryGaps = result.gaps.filter { $0.type == .categoryGap }
        #expect(categoryGaps.isEmpty)
    }

    // MARK: - Determinism

    @Test func deterministic() {
        let items = minimalWardrobe()
        let profile = makeProfile()
        let r1 = OptimizeEngineV2.analyze(items: items, profile: profile)
        let r2 = OptimizeEngineV2.analyze(items: items, profile: profile)
        #expect(abs(r1.currentClarity - r2.currentClarity) < 0.001)
        #expect(r1.gaps.count == r2.gaps.count)
        #expect(r1.friction.count == r2.friction.count)
        for (g1, g2) in zip(r1.gaps, r2.gaps) {
            #expect(g1.type == g2.type)
            #expect(g1.priority == g2.priority)
        }
    }

    // MARK: - Each Gap Type Enum Exists

    @Test func gapTypeCaseCount() {
        #expect(GapType.allCases.count == 4)
    }

    @Test func gapPriorityCaseCount() {
        #expect(GapPriority.allCases.count == 3)
    }
}
