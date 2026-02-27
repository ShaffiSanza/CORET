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
