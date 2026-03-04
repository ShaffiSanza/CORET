import Testing
@testable import COREEngine

// MARK: - Test Helpers

private func makeItem(
    category: ItemCategory,
    silhouette: Silhouette = .balanced,
    baseGroup: BaseGroup = .neutral,
    temperature: Temperature = .neutral,
    archetype: Archetype = .structuredMinimal,
    usageCount: Int = 0
) -> WardrobeItem {
    WardrobeItem(
        imagePath: "test.jpg",
        category: category,
        silhouette: silhouette,
        rawColor: "test",
        baseGroup: baseGroup,
        temperature: temperature,
        archetypeTag: archetype,
        usageCount: usageCount
    )
}

private func makeProfile(
    primary: Archetype = .structuredMinimal,
    secondary: Archetype = .smartCasual
) -> UserProfile {
    UserProfile(
        primaryArchetype: primary,
        secondaryArchetype: secondary,
        seasonMode: .autumnWinter
    )
}

// MARK: - Weakest Area Identification

@Test func weakestAreaIdentifiesLowestScore() {
    let snapshot = CohesionSnapshot(
        alignmentScore: 80,
        densityScore: 30,
        paletteScore: 60,
        rotationScore: 90,
        totalScore: 62,
        statusLevel: .refining
    )
    #expect(OptimizeEngine.weakestArea(from: snapshot) == .density)
}

@Test func weakestAreaPicksAlignmentOnTie() {
    // All zeros — alignment comes first in evaluation order
    let snapshot = CohesionSnapshot(
        alignmentScore: 0,
        densityScore: 0,
        paletteScore: 0,
        rotationScore: 0,
        totalScore: 0,
        statusLevel: .structuring
    )
    #expect(OptimizeEngine.weakestArea(from: snapshot) == .alignment)
}

@Test func weakestAreaIdentifiesPalette() {
    let snapshot = CohesionSnapshot(
        alignmentScore: 90,
        densityScore: 85,
        paletteScore: 40,
        rotationScore: 95,
        totalScore: 78,
        statusLevel: .coherent
    )
    #expect(OptimizeEngine.weakestArea(from: snapshot) == .palette)
}

@Test func weakestAreaIdentifiesRotation() {
    let snapshot = CohesionSnapshot(
        alignmentScore: 90,
        densityScore: 85,
        paletteScore: 80,
        rotationScore: 20,
        totalScore: 75,
        statusLevel: .coherent
    )
    #expect(OptimizeEngine.weakestArea(from: snapshot) == .rotation)
}

// MARK: - Empty Wardrobe

@Test func optimizeEmptyWardrobe() {
    let result = OptimizeEngine.optimize(items: [], profile: makeProfile())

    #expect(result.currentSnapshot.totalScore == 0)
    #expect(result.weakestArea == .alignment)
    #expect(result.friction.isEmpty)
    // Candidates are generated but adding 1 item to empty wardrobe
    // may or may not improve alignment (single item = 100 alignment)
    // Density stays 0 (no outfits possible with 1 item), so total improvement is modest
}

// MARK: - Alignment Weakness

@Test func optimizeRecommendsForAlignmentWeakness() {
    // Items are neutral archetype (not primary, not secondary, not conflicting)
    // so alignment (50) is weakest while density stays high (100)
    let items = [
        makeItem(category: .top, archetype: .smartCasual),
        makeItem(category: .bottom, archetype: .smartCasual),
        makeItem(category: .shoes, archetype: .smartCasual),
    ]
    let profile = makeProfile(primary: .structuredMinimal, secondary: .relaxedStreet)
    let result = OptimizeEngine.optimize(items: items, profile: profile)

    #expect(result.weakestArea == .alignment)
    #expect(result.primary != nil)
    if let primary = result.primary {
        #expect(primary.componentImprovement > 0)
        #expect(primary.candidate.archetypeTag == .structuredMinimal
             || primary.candidate.archetypeTag == .relaxedStreet)
    }
}

// MARK: - Density Weakness

@Test func optimizeRecommendsForDensityWeakness() {
    // Wardrobe missing shoes → density is 0, alignment is 100
    let items = [
        makeItem(category: .top),
        makeItem(category: .bottom),
    ]
    let profile = makeProfile()
    let result = OptimizeEngine.optimize(items: items, profile: profile)

    // Density is 0 (can't form outfits), alignment is 100
    // Weakest should be density (0) since alignment is 100
    // Wait — palette and rotation also factor in. Let me check:
    // alignment = 100, density = 0, palette = (items are 2 neutral → neutralDeep=100%→0, accent=0→100, temp=neutral→100) = 66.67
    // rotation = 100 (each category has 1 item)
    // So density (0) is weakest
    #expect(result.weakestArea == .density)
    #expect(result.primary != nil)

    if let primary = result.primary {
        #expect(primary.componentImprovement > 0)
        // Adding shoes enables outfit formation → density jumps from 0
        #expect(primary.candidate.category == .shoes)
    }
}

@Test func optimizeRecommendsBalancedSilhouetteForDensity() {
    // All structured items → silhouette sum = +3 → invalid outfits → density 0
    let items = [
        makeItem(category: .top, silhouette: .structured),
        makeItem(category: .bottom, silhouette: .structured),
        makeItem(category: .shoes, silhouette: .structured),
    ]
    let profile = makeProfile()
    let result = OptimizeEngine.optimize(items: items, profile: profile)

    #expect(result.weakestArea == .density)
    #expect(result.primary != nil)

    if let primary = result.primary {
        #expect(primary.componentImprovement > 0)
        // Relaxed or balanced candidates would help balance the silhouette
        #expect(primary.candidate.silhouette == .relaxed || primary.candidate.silhouette == .balanced)
    }
}

// MARK: - Palette Weakness

@Test func optimizeRecommendsForPaletteWeakness() {
    // Wardrobe heavy on accent items → palette is weakest
    // Need density to be reasonable, so include all categories
    let items = [
        makeItem(category: .top, baseGroup: .accent),
        makeItem(category: .top, baseGroup: .accent),
        makeItem(category: .bottom, baseGroup: .accent),
        makeItem(category: .bottom, baseGroup: .neutral),
        makeItem(category: .shoes, baseGroup: .accent),
    ]
    let profile = makeProfile()

    let result = OptimizeEngine.optimize(items: items, profile: profile)

    // Palette should be weak due to excess accent (or density due to color clashes)
    #expect(result.weakestArea == .palette || result.weakestArea == .density)
    #expect(result.primary != nil)
    if let primary = result.primary {
        #expect(primary.componentImprovement > 0)
    }
}

// MARK: - Friction Detection

@Test func frictionDetectsHighImpactRemoval() {
    // 3 good items + 1 toxic outerwear (conflicting archetype, accent)
    let items = [
        makeItem(category: .top),
        makeItem(category: .bottom),
        makeItem(category: .shoes),
        makeItem(category: .outerwear, baseGroup: .accent, temperature: .warm, archetype: .relaxedStreet),
    ]
    let profile = makeProfile(primary: .structuredMinimal, secondary: .smartCasual)
    let friction = OptimizeEngine.detectFriction(items: items, profile: profile)

    // Removing the toxic outerwear should improve total by >8
    #expect(!friction.isEmpty)
    #expect(friction[0].item.category == .outerwear)
    #expect(friction[0].totalImprovement > 8)
}

@Test func frictionNotFlaggedBelowThreshold() {
    // 3 good items + 1 secondary-archetype outerwear (mild drag, not toxic)
    let items = [
        makeItem(category: .top),
        makeItem(category: .bottom),
        makeItem(category: .shoes),
        makeItem(category: .outerwear, archetype: .smartCasual),
    ]
    let profile = makeProfile(primary: .structuredMinimal, secondary: .smartCasual)
    let friction = OptimizeEngine.detectFriction(items: items, profile: profile)

    // Secondary archetype outerwear has mild impact, should NOT exceed +8
    #expect(friction.isEmpty)
}

@Test func frictionEmptyForEmptyWardrobe() {
    let friction = OptimizeEngine.detectFriction(items: [], profile: makeProfile())
    #expect(friction.isEmpty)
}

@Test func frictionSortedByImpact() {
    // Two toxic items — verify they're sorted by improvement descending
    let items = [
        makeItem(category: .top),
        makeItem(category: .top),
        makeItem(category: .bottom),
        makeItem(category: .bottom),
        makeItem(category: .shoes),
        makeItem(category: .shoes),
        // Two conflicting outerwear — removing either should help
        makeItem(category: .outerwear, baseGroup: .accent, temperature: .warm, archetype: .relaxedStreet),
        makeItem(category: .outerwear, baseGroup: .accent, temperature: .cool, archetype: .relaxedStreet),
    ]
    let profile = makeProfile(primary: .structuredMinimal, secondary: .smartCasual)
    let friction = OptimizeEngine.detectFriction(items: items, profile: profile)

    if friction.count >= 2 {
        #expect(friction[0].totalImprovement >= friction[1].totalImprovement)
    }
}

// MARK: - Recommendation Limits

@Test func optimizeReturnsMaxTwoSecondary() {
    // Large wardrobe to ensure many candidates have positive improvement
    let items = [
        makeItem(category: .top, archetype: .relaxedStreet),
        makeItem(category: .top, archetype: .relaxedStreet),
        makeItem(category: .bottom, archetype: .relaxedStreet),
        makeItem(category: .bottom, archetype: .relaxedStreet),
        makeItem(category: .shoes, archetype: .relaxedStreet),
        makeItem(category: .shoes, archetype: .relaxedStreet),
    ]
    let profile = makeProfile(primary: .structuredMinimal, secondary: .smartCasual)
    let result = OptimizeEngine.optimize(items: items, profile: profile)

    #expect(result.secondary.count <= 2)
}

@Test func primaryHasHighestImprovement() {
    let items = [
        makeItem(category: .top, archetype: .relaxedStreet),
        makeItem(category: .bottom, archetype: .relaxedStreet),
        makeItem(category: .shoes, archetype: .relaxedStreet),
    ]
    let profile = makeProfile(primary: .structuredMinimal, secondary: .smartCasual)
    let result = OptimizeEngine.optimize(items: items, profile: profile)

    guard let primary = result.primary else { return }
    for sec in result.secondary {
        #expect(primary.componentImprovement >= sec.componentImprovement)
    }
}

// MARK: - Integration

@Test func optimizeFullIntegration() {
    let items = [
        makeItem(category: .top, baseGroup: .neutral, temperature: .warm, usageCount: 5),
        makeItem(category: .top, baseGroup: .neutral, temperature: .warm, usageCount: 5),
        makeItem(category: .bottom, baseGroup: .neutral, temperature: .warm, usageCount: 4),
        makeItem(category: .bottom, baseGroup: .deep, temperature: .warm, usageCount: 4),
        makeItem(category: .shoes, baseGroup: .neutral, temperature: .warm, usageCount: 6),
        makeItem(category: .shoes, baseGroup: .deep, temperature: .warm, usageCount: 6),
    ]
    let profile = makeProfile()
    let result = OptimizeEngine.optimize(items: items, profile: profile)

    // Verify structure
    #expect(result.currentSnapshot.totalScore > 0)
    #expect(result.secondary.count <= 2)
    #expect(result.friction.isEmpty) // All items are well-aligned

    // Verify improvement data consistency
    if let primary = result.primary {
        #expect(primary.totalBefore == result.currentSnapshot.totalScore)
        #expect(primary.componentBefore == primary.componentAfter - primary.componentImprovement)
    }
}

@Test func optimizeHighScoringWardrobeLimitedUpside() {
    // Near-perfect wardrobe — recommendations exist but improvement is modest
    let items = [
        makeItem(category: .top, baseGroup: .neutral, temperature: .warm, usageCount: 5),
        makeItem(category: .top, baseGroup: .deep, temperature: .warm, usageCount: 5),
        makeItem(category: .top, baseGroup: .neutral, temperature: .warm, usageCount: 5),
        makeItem(category: .bottom, baseGroup: .neutral, temperature: .warm, usageCount: 4),
        makeItem(category: .bottom, baseGroup: .deep, temperature: .warm, usageCount: 4),
        makeItem(category: .bottom, baseGroup: .neutral, temperature: .warm, usageCount: 4),
        makeItem(category: .shoes, baseGroup: .neutral, temperature: .warm, usageCount: 6),
        makeItem(category: .shoes, baseGroup: .deep, temperature: .warm, usageCount: 6),
        makeItem(category: .outerwear, baseGroup: .neutral, temperature: .warm, usageCount: 3),
        makeItem(category: .outerwear, baseGroup: .deep, temperature: .warm, usageCount: 3),
    ]
    let profile = makeProfile()
    let result = OptimizeEngine.optimize(items: items, profile: profile)

    #expect(result.currentSnapshot.totalScore > 80)
    #expect(result.friction.isEmpty)
}

@Test func optimizeSingleItem() {
    let items = [makeItem(category: .top)]
    let profile = makeProfile()
    let result = OptimizeEngine.optimize(items: items, profile: profile)

    // Density is 0 (can't form outfits), alignment is 100
    #expect(result.weakestArea == .density)
    // Adding a single candidate still leaves 2+ required categories missing,
    // so density stays 0 — no positive component improvement possible
    #expect(result.primary == nil)
}

@Test func optimizeResultContainsSnapshot() {
    let items = [
        makeItem(category: .top),
        makeItem(category: .bottom),
        makeItem(category: .shoes),
    ]
    let profile = makeProfile()
    let result = OptimizeEngine.optimize(items: items, profile: profile)
    let directSnapshot = CohesionEngine.compute(items: items, profile: profile)

    #expect(result.currentSnapshot.totalScore == directSnapshot.totalScore)
    #expect(result.currentSnapshot.alignmentScore == directSnapshot.alignmentScore)
    #expect(result.currentSnapshot.densityScore == directSnapshot.densityScore)
}
