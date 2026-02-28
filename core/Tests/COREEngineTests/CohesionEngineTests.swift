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

/// Minimal wardrobe that forms valid outfits: 1 top, 1 bottom, 1 shoes — all primary archetype, neutral, balanced.
private func minimalWardrobe() -> [WardrobeItem] {
    [
        makeItem(category: .top),
        makeItem(category: .bottom),
        makeItem(category: .shoes),
    ]
}

// MARK: - Empty Wardrobe

@Test func emptyWardrobe() {
    let snapshot = CohesionEngine.compute(items: [], profile: makeProfile())
    #expect(snapshot.totalScore == 0)
    #expect(snapshot.alignmentScore == 0)
    #expect(snapshot.densityScore == 0)
    #expect(snapshot.paletteScore == 0)
    #expect(snapshot.rotationScore == 0)
    #expect(snapshot.statusLevel == .structuring)
}

// MARK: - Alignment

@Test func singleItemMatchesPrimary() {
    let items = [makeItem(category: .top, archetype: .structuredMinimal)]
    let score = CohesionEngine.alignmentScore(items: items, profile: makeProfile())
    #expect(score == 100)
}

@Test func singleItemMatchesSecondary() {
    let items = [makeItem(category: .top, archetype: .smartCasual)]
    let score = CohesionEngine.alignmentScore(items: items, profile: makeProfile())
    #expect(score == 70)
}

@Test func allConflictingArchetypes() {
    let items = [
        makeItem(category: .top, archetype: .relaxedStreet),
        makeItem(category: .bottom, archetype: .relaxedStreet),
        makeItem(category: .shoes, archetype: .relaxedStreet),
    ]
    let profile = makeProfile(primary: .structuredMinimal, secondary: .smartCasual)
    let score = CohesionEngine.alignmentScore(items: items, profile: profile)
    #expect(abs(score - 20) < 0.001)
}

@Test func mixedAlignmentScores() {
    let items = [
        makeItem(category: .top, archetype: .structuredMinimal),    // 1.0
        makeItem(category: .bottom, archetype: .smartCasual),       // 0.7
        makeItem(category: .shoes, archetype: .relaxedStreet),      // 0.2
    ]
    let profile = makeProfile(primary: .structuredMinimal, secondary: .smartCasual)
    let expected = ((1.0 + 0.7 + 0.2) / 3.0) * 100
    let score = CohesionEngine.alignmentScore(items: items, profile: profile)
    #expect(abs(score - expected) < 0.001)
}

@Test func neutralArchetypeItem() {
    // smartCasual is neutral to relaxedStreet (not conflict, not primary/secondary)
    let items = [makeItem(category: .top, archetype: .smartCasual)]
    let profile = makeProfile(primary: .relaxedStreet, secondary: .relaxedStreet)
    let score = CohesionEngine.alignmentScore(items: items, profile: profile)
    #expect(score == 50)
}

// MARK: - Density

@Test func densityZeroWhenMissingCategory() {
    // Only tops and bottoms, no shoes
    let items = [
        makeItem(category: .top),
        makeItem(category: .bottom),
    ]
    let score = CohesionEngine.densityScore(items: items, profile: makeProfile())
    #expect(score == 0)
}

@Test func minimalValidWardrobeDensity100() {
    let score = CohesionEngine.densityScore(items: minimalWardrobe(), profile: makeProfile())
    #expect(score == 100)
}

@Test func densityWithOuterwear() {
    var items = minimalWardrobe()
    items.append(makeItem(category: .outerwear))
    // 1 top × 1 bottom × 1 shoes × (1 + 1 outerwear) = 2 possible outfits
    // All items match primary, balanced silhouette, neutral color → both valid
    let score = CohesionEngine.densityScore(items: items, profile: makeProfile())
    #expect(score == 100)
}

@Test func densityDropsWithConflictingArchetype() {
    // Add a conflicting outerwear — outfits including it should fail archetype check
    var items = minimalWardrobe()
    items.append(makeItem(category: .outerwear, archetype: .relaxedStreet))
    // Total: 1×1×1×(1+1) = 2 outfits. Without outerwear: valid. With conflicting outerwear: invalid.
    let score = CohesionEngine.densityScore(items: items, profile: makeProfile())
    #expect(score == 50)
}

@Test func densityDropsWithSilhouetteExtremes() {
    // 3 structured items → sum = +3 → invalid
    let items = [
        makeItem(category: .top, silhouette: .structured),
        makeItem(category: .bottom, silhouette: .structured),
        makeItem(category: .shoes, silhouette: .structured),
    ]
    let score = CohesionEngine.densityScore(items: items, profile: makeProfile())
    #expect(score == 0)
}

@Test func densityAllowsSilhouetteSumOfTwo() {
    // 2 structured + 1 balanced → sum = +2 → valid
    let items = [
        makeItem(category: .top, silhouette: .structured),
        makeItem(category: .bottom, silhouette: .structured),
        makeItem(category: .shoes, silhouette: .balanced),
    ]
    let score = CohesionEngine.densityScore(items: items, profile: makeProfile())
    #expect(score == 100)
}

@Test func densityRejectsMultipleAccents() {
    let items = [
        makeItem(category: .top, baseGroup: .accent, temperature: .warm),
        makeItem(category: .bottom, baseGroup: .accent, temperature: .warm),
        makeItem(category: .shoes, baseGroup: .neutral, temperature: .warm),
    ]
    let score = CohesionEngine.densityScore(items: items, profile: makeProfile())
    #expect(score == 0)
}

@Test func densityRejectsNoNeutral() {
    let items = [
        makeItem(category: .top, baseGroup: .deep, temperature: .warm),
        makeItem(category: .bottom, baseGroup: .light, temperature: .warm),
        makeItem(category: .shoes, baseGroup: .deep, temperature: .warm),
    ]
    let score = CohesionEngine.densityScore(items: items, profile: makeProfile())
    #expect(score == 0)
}

@Test func densityRejectsWarmCoolClash() {
    // Different base groups so monochrome doesn't apply
    let items = [
        makeItem(category: .top, baseGroup: .neutral, temperature: .warm),
        makeItem(category: .bottom, baseGroup: .deep, temperature: .cool),
        makeItem(category: .shoes, baseGroup: .neutral, temperature: .neutral),
    ]
    let score = CohesionEngine.densityScore(items: items, profile: makeProfile())
    #expect(score == 0)
}

@Test func monochromeOverridesColorRules() {
    // All same baseGroup → monochrome → skip color rules even with warm+cool clash
    let items = [
        makeItem(category: .top, baseGroup: .neutral, temperature: .warm),
        makeItem(category: .bottom, baseGroup: .neutral, temperature: .cool),
        makeItem(category: .shoes, baseGroup: .neutral, temperature: .neutral),
    ]
    let score = CohesionEngine.densityScore(items: items, profile: makeProfile())
    // Not monochrome here — all neutral baseGroup means monochrome! So it should be valid.
    #expect(score == 100)
}

// MARK: - Palette

@Test func paletteIdealDistribution() {
    // 7 neutral/deep out of 10 = 70% (in [60-80%] target)
    // 1 accent out of 10 = 10% (in [0-20%] target)
    // All same temperature → 100 temp coherence
    var items: [WardrobeItem] = []
    for _ in 0..<4 { items.append(makeItem(category: .top, baseGroup: .neutral)) }
    for _ in 0..<3 { items.append(makeItem(category: .bottom, baseGroup: .deep)) }
    items.append(makeItem(category: .shoes, baseGroup: .light))
    items.append(makeItem(category: .shoes, baseGroup: .light))
    items.append(makeItem(category: .shoes, baseGroup: .accent))
    let score = CohesionEngine.paletteScore(items: items)
    #expect(score == 100)
}

@Test func paletteTooManyAccents() {
    // 5 accent out of 5 = 100% accent, 0% neutral/deep
    let items = [
        makeItem(category: .top, baseGroup: .accent),
        makeItem(category: .bottom, baseGroup: .accent),
        makeItem(category: .shoes, baseGroup: .accent),
        makeItem(category: .outerwear, baseGroup: .accent),
        makeItem(category: .top, baseGroup: .accent),
    ]
    let score = CohesionEngine.paletteScore(items: items)
    // neutralDeep = 0/5 = 0% → (0/0.6)*100 = 0
    // accent = 5/5 = 100% → (1.0 - (0.8/0.3))*100 → negative → clamped to 0
    // temp = all neutral → 100
    // avg = (0 + 0 + 100) / 3 ≈ 33.33
    #expect(abs(score - 100.0 / 3.0) < 0.01)
}

@Test func paletteTemperatureClash() {
    // Equal warm/cool split
    let items = [
        makeItem(category: .top, baseGroup: .neutral, temperature: .warm),
        makeItem(category: .bottom, baseGroup: .neutral, temperature: .cool),
        makeItem(category: .shoes, baseGroup: .neutral, temperature: .warm),
        makeItem(category: .outerwear, baseGroup: .neutral, temperature: .cool),
    ]
    let score = CohesionEngine.paletteScore(items: items)
    // neutralDeep = 4/4 = 100% → ((1-1)/0.2)*100 = 0
    // accent = 0% → 100
    // temp: 2 warm, 2 cool → warmR=0.5, coolR=0.5 → (1-0.5*2)*100 = 0
    // avg = (0 + 100 + 0) / 3 ≈ 33.33
    #expect(abs(score - 100.0 / 3.0) < 0.01)
}

// MARK: - Rotation

@Test func rotationPerfectWhenUnused() {
    let items = minimalWardrobe() // all usageCount = 0
    let score = CohesionEngine.rotationScore(items: items)
    // Each category has 1 item → no deviation possible → 100
    #expect(score == 100)
}

@Test func rotationPerfectWhenEvenUsage() {
    let items = [
        makeItem(category: .top, usageCount: 5),
        makeItem(category: .top, usageCount: 5),
        makeItem(category: .bottom, usageCount: 3),
        makeItem(category: .bottom, usageCount: 3),
        makeItem(category: .shoes, usageCount: 4),
        makeItem(category: .shoes, usageCount: 4),
    ]
    let score = CohesionEngine.rotationScore(items: items)
    #expect(score == 100)
}

@Test func rotationDropsWithUnevenUsage() {
    let items = [
        makeItem(category: .top, usageCount: 10),
        makeItem(category: .top, usageCount: 0),
    ]
    let score = CohesionEngine.rotationScore(items: items)
    // mean = 5, MAD = 5, normalized = 5/5 = 1.0 → score = 0
    #expect(score == 0)
}

@Test func rotationPartialDeviation() {
    let items = [
        makeItem(category: .top, usageCount: 6),
        makeItem(category: .top, usageCount: 4),
        makeItem(category: .bottom, usageCount: 5),
        makeItem(category: .bottom, usageCount: 5),
    ]
    let score = CohesionEngine.rotationScore(items: items)
    // tops: mean=5, MAD=1, norm=1/5=0.2. bottoms: mean=5, MAD=0, norm=0. avg=0.1 → score=90
    #expect(abs(score - 90) < 0.01)
}

// MARK: - Status Levels

@Test func statusBoundaries() {
    #expect(CohesionEngine.statusLevel(from: 0) == .structuring)
    #expect(CohesionEngine.statusLevel(from: 49) == .structuring)
    #expect(CohesionEngine.statusLevel(from: 49.99) == .structuring)
    #expect(CohesionEngine.statusLevel(from: 50) == .refining)
    #expect(CohesionEngine.statusLevel(from: 64) == .refining)
    #expect(CohesionEngine.statusLevel(from: 64.99) == .refining)
    #expect(CohesionEngine.statusLevel(from: 65) == .coherent)
    #expect(CohesionEngine.statusLevel(from: 79) == .coherent)
    #expect(CohesionEngine.statusLevel(from: 79.99) == .coherent)
    #expect(CohesionEngine.statusLevel(from: 80) == .aligned)
    #expect(CohesionEngine.statusLevel(from: 89) == .aligned)
    #expect(CohesionEngine.statusLevel(from: 89.99) == .aligned)
    #expect(CohesionEngine.statusLevel(from: 90) == .architected)
    #expect(CohesionEngine.statusLevel(from: 100) == .architected)
}

// MARK: - Compute Integration

@Test func computeMinimalWardrobeHighScore() {
    let items = minimalWardrobe()
    let profile = makeProfile()
    let snapshot = CohesionEngine.compute(items: items, profile: profile)

    // Alignment: all primary → 100
    #expect(snapshot.alignmentScore == 100)
    // Density: 1 valid outfit, 1 total → 100
    #expect(snapshot.densityScore == 100)
    // Rotation: 1 item per category → 100
    #expect(snapshot.rotationScore == 100)
    // Palette: 3/3 neutral → 100% neutralDeep (over 80% target but >80 scores lower)
    // neutralDeep = 100% → ((1-1)/0.2)*100 = 0. accent = 0% → 100. temp = all neutral → 100.
    // palette = (0+100+100)/3 ≈ 66.67
    #expect(snapshot.paletteScore > 60)
    #expect(snapshot.paletteScore < 70)

    // Total = 100*0.35 + 100*0.30 + ~66.67*0.20 + 100*0.15 = 35+30+13.33+15 = 93.33
    #expect(snapshot.totalScore > 90)
    #expect(snapshot.statusLevel == .architected)
}

@Test func computePerfectWardrobe() {
    // Build a wardrobe that scores high across all dimensions
    let items = [
        // 4 neutral tops → good palette ratio, all primary archetype
        makeItem(category: .top, baseGroup: .neutral, temperature: .warm, usageCount: 5),
        makeItem(category: .top, baseGroup: .neutral, temperature: .warm, usageCount: 5),
        makeItem(category: .top, baseGroup: .deep, temperature: .warm, usageCount: 5),
        // 3 neutral/deep bottoms
        makeItem(category: .bottom, baseGroup: .neutral, temperature: .warm, usageCount: 4),
        makeItem(category: .bottom, baseGroup: .deep, temperature: .warm, usageCount: 4),
        makeItem(category: .bottom, baseGroup: .neutral, temperature: .warm, usageCount: 4),
        // 2 shoes
        makeItem(category: .shoes, baseGroup: .neutral, temperature: .warm, usageCount: 6),
        makeItem(category: .shoes, baseGroup: .deep, temperature: .warm, usageCount: 6),
        // 1 accent outerwear (keeps accent at 1/10 = 10%)
        makeItem(category: .outerwear, baseGroup: .accent, temperature: .warm, usageCount: 3),
        // 1 light item
        makeItem(category: .top, baseGroup: .light, temperature: .warm, usageCount: 5),
    ]
    let profile = makeProfile()
    let snapshot = CohesionEngine.compute(items: items, profile: profile)

    #expect(snapshot.alignmentScore == 100)
    #expect(snapshot.totalScore > 80)
    #expect(snapshot.statusLevel == .aligned || snapshot.statusLevel == .architected)
}

@Test func computeWeakWardrobe() {
    // All conflicting archetypes, bad silhouettes, bad palette
    let items = [
        makeItem(category: .top, silhouette: .structured, baseGroup: .accent, temperature: .warm, archetype: .relaxedStreet, usageCount: 10),
        makeItem(category: .bottom, silhouette: .structured, baseGroup: .accent, temperature: .cool, archetype: .relaxedStreet, usageCount: 0),
        makeItem(category: .shoes, silhouette: .structured, baseGroup: .accent, temperature: .warm, archetype: .relaxedStreet, usageCount: 0),
    ]
    let profile = makeProfile(primary: .structuredMinimal, secondary: .smartCasual)
    let snapshot = CohesionEngine.compute(items: items, profile: profile)

    #expect(abs(snapshot.alignmentScore - 20) < 0.001)
    #expect(snapshot.densityScore == 0) // archetype conflict blocks all outfits
    #expect(snapshot.totalScore < 50)
    #expect(snapshot.statusLevel == .structuring)
}

@Test func computeWeightedFormulaCorrect() {
    // Verify the formula weights are applied correctly
    let items = minimalWardrobe()
    let profile = makeProfile()
    let snapshot = CohesionEngine.compute(items: items, profile: profile)

    let expected = snapshot.alignmentScore * 0.35
        + snapshot.densityScore * 0.30
        + snapshot.paletteScore * 0.20
        + snapshot.rotationScore * 0.15

    #expect(abs(snapshot.totalScore - expected) < 0.001)
}

@Test func computePopulatesItemIDs() {
    let items = minimalWardrobe()
    let profile = makeProfile()
    let snapshot = CohesionEngine.compute(items: items, profile: profile)
    #expect(snapshot.itemIDs.count == 3)
    for item in items {
        #expect(snapshot.itemIDs.contains(item.id))
    }
}

@Test func computeEmptyWardrobeHasEmptyItemIDs() {
    let snapshot = CohesionEngine.compute(items: [], profile: makeProfile())
    #expect(snapshot.itemIDs.isEmpty)
}

// MARK: - Structural Identity

@Test func identityEmptyWardrobe() {
    let identity = CohesionEngine.structuralIdentity(items: [])
    #expect(identity.dominantSilhouette == nil)
    #expect(identity.dominantBaseGroup == nil)
    #expect(identity.dominantTemperature == .neutral)
}

@Test func identityClearDominance() {
    // 2 structured, 1 balanced → structured wins
    // 2 deep, 1 neutral → deep wins
    // 2 cool, 1 warm → cool wins
    let items = [
        makeItem(category: .top, silhouette: .structured, baseGroup: .deep, temperature: .cool),
        makeItem(category: .bottom, silhouette: .structured, baseGroup: .deep, temperature: .cool),
        makeItem(category: .shoes, silhouette: .balanced, baseGroup: .neutral, temperature: .warm),
    ]
    let identity = CohesionEngine.structuralIdentity(items: items)
    #expect(identity.dominantSilhouette == .structured)
    #expect(identity.dominantBaseGroup == .deep)
    #expect(identity.dominantTemperature == .cool)
}

@Test func identityThreeWayTieReturnsMixed() {
    // 1 of each silhouette → tie → nil
    // 1 of each baseGroup (3 of 4) → tie → nil
    let items = [
        makeItem(category: .top, silhouette: .structured, baseGroup: .neutral, temperature: .warm),
        makeItem(category: .bottom, silhouette: .balanced, baseGroup: .deep, temperature: .warm),
        makeItem(category: .shoes, silhouette: .relaxed, baseGroup: .light, temperature: .warm),
    ]
    let identity = CohesionEngine.structuralIdentity(items: items)
    #expect(identity.dominantSilhouette == nil)
    #expect(identity.dominantBaseGroup == nil)
    #expect(identity.dominantTemperature == .warm)
}

@Test func identityTwoWayTieReturnsMixed() {
    // 2 structured, 2 relaxed → tie → nil
    let items = [
        makeItem(category: .top, silhouette: .structured, baseGroup: .neutral),
        makeItem(category: .bottom, silhouette: .structured, baseGroup: .neutral),
        makeItem(category: .shoes, silhouette: .relaxed, baseGroup: .deep),
        makeItem(category: .outerwear, silhouette: .relaxed, baseGroup: .deep),
    ]
    let identity = CohesionEngine.structuralIdentity(items: items)
    #expect(identity.dominantSilhouette == nil)
    #expect(identity.dominantBaseGroup == nil)
}

@Test func identityTemperatureTieResolvesToNeutral() {
    // 1 warm, 1 cool → tie → neutral
    let items = [
        makeItem(category: .top, temperature: .warm),
        makeItem(category: .bottom, temperature: .cool),
    ]
    let identity = CohesionEngine.structuralIdentity(items: items)
    #expect(identity.dominantTemperature == .neutral)
}

@Test func identityTemperatureTieWithNeutralResolvesToNeutral() {
    // 1 warm, 1 neutral → tie → neutral wins (neutral among tied)
    let items = [
        makeItem(category: .top, temperature: .warm),
        makeItem(category: .bottom, temperature: .neutral),
    ]
    let identity = CohesionEngine.structuralIdentity(items: items)
    #expect(identity.dominantTemperature == .neutral)
}

@Test func identityTemperatureNeverNil() {
    // Even with 3-way tie (warm, cool, neutral), returns .neutral
    let items = [
        makeItem(category: .top, temperature: .warm),
        makeItem(category: .bottom, temperature: .cool),
        makeItem(category: .shoes, temperature: .neutral),
    ]
    let identity = CohesionEngine.structuralIdentity(items: items)
    #expect(identity.dominantTemperature == .neutral)
}

@Test func identitySingleItem() {
    let items = [
        makeItem(category: .top, silhouette: .relaxed, baseGroup: .accent, temperature: .warm),
    ]
    let identity = CohesionEngine.structuralIdentity(items: items)
    #expect(identity.dominantSilhouette == .relaxed)
    #expect(identity.dominantBaseGroup == .accent)
    #expect(identity.dominantTemperature == .warm)
}

@Test func identityUniformWardrobe() {
    // All items identical structure → clear dominance
    let items = [
        makeItem(category: .top, silhouette: .balanced, baseGroup: .neutral, temperature: .cool),
        makeItem(category: .bottom, silhouette: .balanced, baseGroup: .neutral, temperature: .cool),
        makeItem(category: .shoes, silhouette: .balanced, baseGroup: .neutral, temperature: .cool),
        makeItem(category: .outerwear, silhouette: .balanced, baseGroup: .neutral, temperature: .cool),
    ]
    let identity = CohesionEngine.structuralIdentity(items: items)
    #expect(identity.dominantSilhouette == .balanced)
    #expect(identity.dominantBaseGroup == .neutral)
    #expect(identity.dominantTemperature == .cool)
}

// MARK: - Item Contributions: Empty

@Test func contributionsEmptyItems() {
    let profile = makeProfile()
    for component in CohesionComponent.allCases {
        let result = CohesionEngine.itemContributions(items: [], profile: profile, component: component)
        #expect(result.isEmpty)
    }
}

// MARK: - Item Contributions: Alignment

@Test func alignmentContributionScores() {
    let items = [
        makeItem(category: .top, archetype: .structuredMinimal),    // primary → 1.0
        makeItem(category: .bottom, archetype: .smartCasual),       // secondary → 0.7
        makeItem(category: .shoes, archetype: .relaxedStreet),      // conflict → 0.2
    ]
    let profile = makeProfile(primary: .structuredMinimal, secondary: .smartCasual)
    let result = CohesionEngine.itemContributions(items: items, profile: profile, component: .alignment)

    #expect(result.count == 3)
    // Sorted descending: primary (1.0), secondary (0.7), conflict (0.2)
    #expect(abs(result[0].contributionScore - 1.0) < 0.001)
    #expect(result[0].context == .alignment(.primary))
    #expect(abs(result[1].contributionScore - 0.7) < 0.001)
    #expect(result[1].context == .alignment(.secondary))
    #expect(abs(result[2].contributionScore - 0.2) < 0.001)
    #expect(result[2].context == .alignment(.conflict))
}

@Test func alignmentContributionNeutralItem() {
    // smartCasual vs primary=relaxedStreet, secondary=relaxedStreet → neutral (0.5)
    let items = [makeItem(category: .top, archetype: .smartCasual)]
    let profile = makeProfile(primary: .relaxedStreet, secondary: .relaxedStreet)
    let result = CohesionEngine.itemContributions(items: items, profile: profile, component: .alignment)

    #expect(result.count == 1)
    #expect(abs(result[0].contributionScore - 0.5) < 0.001)
    #expect(result[0].context == .alignment(.neutral))
}

@Test func alignmentContributionSortingTieBreaksByUUID() {
    // Two items with same archetype → same score → UUID tie-break
    let itemA = makeItem(category: .top, archetype: .structuredMinimal)
    let itemB = makeItem(category: .bottom, archetype: .structuredMinimal)
    let profile = makeProfile()
    let result = CohesionEngine.itemContributions(items: [itemA, itemB], profile: profile, component: .alignment)

    #expect(result.count == 2)
    #expect(abs(result[0].contributionScore - result[1].contributionScore) < 0.001)
    // Tie-broken by UUID string: first should have lexicographically smaller UUID
    #expect(result[0].itemID.uuidString < result[1].itemID.uuidString)
}

@Test func alignmentContributionItemIDsMatch() {
    let items = [
        makeItem(category: .top, archetype: .structuredMinimal),
        makeItem(category: .bottom, archetype: .relaxedStreet),
    ]
    let profile = makeProfile()
    let result = CohesionEngine.itemContributions(items: items, profile: profile, component: .alignment)

    let resultIDs = Set(result.map(\.itemID))
    let inputIDs = Set(items.map(\.id))
    #expect(resultIDs == inputIDs)
}

// MARK: - Item Contributions: Rotation

@Test func rotationContributionEvenUsage() {
    let items = [
        makeItem(category: .top, usageCount: 5),
        makeItem(category: .top, usageCount: 5),
        makeItem(category: .bottom, usageCount: 3),
        makeItem(category: .bottom, usageCount: 3),
    ]
    let result = CohesionEngine.itemContributions(items: items, profile: makeProfile(), component: .rotation)

    #expect(result.count == 4)
    for contribution in result {
        #expect(abs(contribution.contributionScore - 1.0) < 0.001)
        #expect(contribution.context == .rotation(.even))
    }
}

@Test func rotationContributionUnevenUsage() {
    let items = [
        makeItem(category: .top, usageCount: 10),
        makeItem(category: .top, usageCount: 0),
    ]
    let result = CohesionEngine.itemContributions(items: items, profile: makeProfile(), component: .rotation)

    #expect(result.count == 2)
    // mean=5, both have deviation 5, normalized=5/5=1.0, score=0.0
    for contribution in result {
        #expect(abs(contribution.contributionScore - 0.0) < 0.001)
    }
    // One overused (10), one underused (0)
    let overused = result.first { $0.context == .rotation(.overused) }
    let underused = result.first { $0.context == .rotation(.underused) }
    #expect(overused != nil)
    #expect(underused != nil)
}

@Test func rotationContributionSingleItemCategory() {
    // Single item in category → perfect (1.0, .even)
    let items = [makeItem(category: .top, usageCount: 99)]
    let result = CohesionEngine.itemContributions(items: items, profile: makeProfile(), component: .rotation)

    #expect(result.count == 1)
    #expect(abs(result[0].contributionScore - 1.0) < 0.001)
    #expect(result[0].context == .rotation(.even))
}

// MARK: - Item Contributions: Density

@Test func densityContributionOnlyBottomRemovalKillsDensity() {
    // Removing the only bottom kills all outfits → highest delta
    var items = minimalWardrobe() // 1 top, 1 bottom, 1 shoes
    items.append(makeItem(category: .top)) // extra top so removing top doesn't kill density
    let profile = makeProfile()
    let result = CohesionEngine.itemContributions(items: items, profile: profile, component: .density)

    #expect(result.count == 4)
    // The bottom (only one) should have the highest contribution score
    let bottomItem = items.first { $0.category == .bottom }!
    let bottomContribution = result.first { $0.itemID == bottomItem.id }!
    #expect(bottomContribution.context == .density(.high))
    #expect(bottomContribution.contributionScore > 0.5)
}

@Test func densityContributionMissingCategory() {
    // No shoes → density baseline is 0. All deltas are 0.
    let items = [
        makeItem(category: .top),
        makeItem(category: .bottom),
    ]
    let result = CohesionEngine.itemContributions(items: items, profile: makeProfile(), component: .density)

    #expect(result.count == 2)
    for contribution in result {
        #expect(abs(contribution.contributionScore - 0.5) < 0.001)
        #expect(contribution.context == .density(.low))
    }
}

@Test func densityContributionConflictingItemLow() {
    // Conflicting outerwear reduces valid outfits → low participation
    var items = minimalWardrobe()
    items.append(makeItem(category: .outerwear, archetype: .relaxedStreet))
    let profile = makeProfile(primary: .structuredMinimal)
    let result = CohesionEngine.itemContributions(items: items, profile: profile, component: .density)

    let conflictItem = items.last!
    let conflictContrib = result.first { $0.itemID == conflictItem.id }!
    // Removing conflicting outerwear should NOT hurt density (delta ≤ 0)
    #expect(conflictContrib.context == .density(.low))
}

// MARK: - Item Contributions: Palette

@Test func paletteContributionExcessAccent() {
    // 3 accent out of 4 = 75% → excessAccent context
    let items = [
        makeItem(category: .top, baseGroup: .accent),
        makeItem(category: .bottom, baseGroup: .accent),
        makeItem(category: .shoes, baseGroup: .accent),
        makeItem(category: .outerwear, baseGroup: .neutral),
    ]
    let result = CohesionEngine.itemContributions(items: items, profile: makeProfile(), component: .palette)

    let accentContributions = result.filter { $0.context == .palette(.excessAccent) }
    #expect(accentContributions.count == 3)
}

@Test func paletteContributionTemperatureClash() {
    // 3 warm, 1 cool → cool item clashes
    let items = [
        makeItem(category: .top, baseGroup: .neutral, temperature: .warm),
        makeItem(category: .bottom, baseGroup: .neutral, temperature: .warm),
        makeItem(category: .shoes, baseGroup: .neutral, temperature: .warm),
        makeItem(category: .outerwear, baseGroup: .deep, temperature: .cool),
    ]
    let result = CohesionEngine.itemContributions(items: items, profile: makeProfile(), component: .palette)

    let coolItem = items.last!
    let coolContrib = result.first { $0.itemID == coolItem.id }!
    #expect(coolContrib.context == .palette(.temperatureClash))
}

@Test func paletteContributionBalanced() {
    // All neutral, same temperature → all balanced
    let items = [
        makeItem(category: .top, baseGroup: .neutral, temperature: .warm),
        makeItem(category: .bottom, baseGroup: .neutral, temperature: .warm),
        makeItem(category: .shoes, baseGroup: .deep, temperature: .warm),
    ]
    let result = CohesionEngine.itemContributions(items: items, profile: makeProfile(), component: .palette)

    for contribution in result {
        #expect(contribution.context == .palette(.balanced))
    }
}

// MARK: - Item Contributions: General

@Test func contributionCountMatchesItemCount() {
    let items = [
        makeItem(category: .top),
        makeItem(category: .bottom),
        makeItem(category: .shoes),
        makeItem(category: .outerwear),
    ]
    let profile = makeProfile()
    for component in CohesionComponent.allCases {
        let result = CohesionEngine.itemContributions(items: items, profile: profile, component: component)
        #expect(result.count == items.count)
    }
}

@Test func contributionComponentFieldMatchesRequest() {
    let items = minimalWardrobe()
    let profile = makeProfile()
    for component in CohesionComponent.allCases {
        let result = CohesionEngine.itemContributions(items: items, profile: profile, component: component)
        for contribution in result {
            #expect(contribution.component == component)
        }
    }
}

@Test func contributionDeterminism() {
    let items = [
        makeItem(category: .top, archetype: .structuredMinimal, usageCount: 3),
        makeItem(category: .bottom, archetype: .smartCasual, usageCount: 7),
        makeItem(category: .shoes, archetype: .relaxedStreet, usageCount: 1),
    ]
    let profile = makeProfile()

    for component in CohesionComponent.allCases {
        let run1 = CohesionEngine.itemContributions(items: items, profile: profile, component: component)
        let run2 = CohesionEngine.itemContributions(items: items, profile: profile, component: component)

        #expect(run1.count == run2.count)
        for i in 0..<run1.count {
            #expect(run1[i].itemID == run2[i].itemID)
            #expect(abs(run1[i].contributionScore - run2[i].contributionScore) < 0.0001)
            #expect(run1[i].context == run2[i].context)
        }
    }
}
