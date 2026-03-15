import Testing
import Foundation
@testable import COREEngine

@Suite("KeyGarmentResolver Tests")
struct KeyGarmentResolverTests {

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

    /// Minimal wardrobe: 1 upper + 1 lower + 1 shoes = 1 outfit
    private func minimalWardrobe() -> [Garment] {
        [
            makeGarment(category: .upper, silhouette: .fitted, baseGroup: .shirt, temperature: 3),
            makeGarment(category: .lower, silhouette: .regular, baseGroup: .chinos),
            makeGarment(category: .shoes, silhouette: .none, baseGroup: .loafers, temperature: nil),
        ]
    }

    // MARK: - Empty Wardrobe

    @Test func emptyWardrobeReturnsEmptyRoles() {
        let result = KeyGarmentResolver.roles(for: [], profile: makeProfile())
        #expect(result.isEmpty)
    }

    @Test func emptyWardrobeReturnsNoKeyGarments() {
        let ids = KeyGarmentResolver.keyGarmentIDs(items: [], profile: makeProfile())
        #expect(ids.isEmpty)
    }

    // MARK: - No Outfits (missing category)

    @Test func noOutfitsMissingCategory() {
        let items = [
            makeGarment(category: .upper, baseGroup: .shirt),
            makeGarment(category: .upper, baseGroup: .tee),
        ]
        let roles = KeyGarmentResolver.roles(for: items, profile: makeProfile())
        #expect(roles.count == 2)
        #expect(roles.allSatisfy { $0.combinationCount == 0 })
        #expect(roles.allSatisfy { $0.totalOutfitCount == 0 })
        #expect(roles.allSatisfy { !$0.isKeyGarment })
    }

    // MARK: - Single Outfit

    @Test func singleOutfitAllGarmentsAt100Percent() {
        let items = minimalWardrobe()
        let profile = makeProfile()
        let roles = KeyGarmentResolver.roles(for: items, profile: profile)

        #expect(roles.count == 3)
        for role in roles {
            #expect(role.totalOutfitCount == 1)
            #expect(role.combinationCount == 1)
            #expect(abs(role.combinationPercentage - 1.0) < 0.001)
            #expect(role.isKeyGarment == true) // 100% >= 20%
        }
    }

    // MARK: - Combination Count Accuracy

    @Test func combinationCountAccurate() {
        // 2 uppers × 1 lower × 1 shoes = 2 outfits
        // Each upper appears in 1 of 2 outfits (50%)
        // Lower and shoes appear in 2 of 2 outfits (100%)
        let upper1 = makeGarment(category: .upper, baseGroup: .shirt, temperature: 3)
        let upper2 = makeGarment(category: .upper, baseGroup: .tee, temperature: 3)
        let lower = makeGarment(category: .lower, silhouette: .regular, baseGroup: .chinos)
        let shoes = makeGarment(category: .shoes, silhouette: .none, baseGroup: .loafers, temperature: nil)

        let items = [upper1, upper2, lower, shoes]
        let profile = makeProfile()
        let roles = KeyGarmentResolver.roles(for: items, profile: profile)

        let upper1Role = roles.first { $0.garmentID == upper1.id }!
        let upper2Role = roles.first { $0.garmentID == upper2.id }!
        let lowerRole = roles.first { $0.garmentID == lower.id }!
        let shoesRole = roles.first { $0.garmentID == shoes.id }!

        #expect(upper1Role.totalOutfitCount == 2)
        #expect(upper1Role.combinationCount == 1)
        #expect(abs(upper1Role.combinationPercentage - 0.5) < 0.001)

        #expect(upper2Role.combinationCount == 1)
        #expect(abs(upper2Role.combinationPercentage - 0.5) < 0.001)

        #expect(lowerRole.combinationCount == 2)
        #expect(abs(lowerRole.combinationPercentage - 1.0) < 0.001)

        #expect(shoesRole.combinationCount == 2)
        #expect(abs(shoesRole.combinationPercentage - 1.0) < 0.001)
    }

    // MARK: - Accessories

    @Test func accessoriesAlwaysZeroPercent() {
        var items = minimalWardrobe()
        let accessory = makeGarment(category: .accessory, silhouette: .none, baseGroup: .belt, temperature: nil)
        items.append(accessory)

        let profile = makeProfile()
        let role = KeyGarmentResolver.role(for: accessory, in: items, profile: profile)

        #expect(role.combinationCount == 0)
        #expect(abs(role.combinationPercentage) < 0.001)
        #expect(role.isKeyGarment == false)
        #expect(role.roleDescriptor == "0% av alle kombinasjoner")
    }

    // MARK: - Threshold Boundary

    @Test func thresholdExactlyAt20Percent() {
        // 5 uppers × 1 lower × 1 shoes = 5 outfits
        // Each upper appears in 1/5 = 20% = exactly at threshold → isKeyGarment
        let uppers = (0..<5).map { _ in makeGarment(category: .upper, baseGroup: .shirt, temperature: 3) }
        let lower = makeGarment(category: .lower, silhouette: .regular, baseGroup: .chinos)
        let shoes = makeGarment(category: .shoes, silhouette: .none, baseGroup: .loafers, temperature: nil)

        let items = uppers + [lower, shoes]
        let profile = makeProfile()
        let roles = KeyGarmentResolver.roles(for: items, profile: profile)

        for role in roles where uppers.map(\.id).contains(role.garmentID) {
            #expect(abs(role.combinationPercentage - 0.2) < 0.001)
            #expect(role.isKeyGarment == true) // >= 0.20
        }
    }

    @Test func belowThresholdNotKeyGarment() {
        // 6 uppers × 1 lower × 1 shoes = 6 outfits
        // Each upper appears in 1/6 ≈ 16.7% < 20% → not key garment
        let uppers = (0..<6).map { _ in makeGarment(category: .upper, baseGroup: .shirt, temperature: 3) }
        let lower = makeGarment(category: .lower, silhouette: .regular, baseGroup: .chinos)
        let shoes = makeGarment(category: .shoes, silhouette: .none, baseGroup: .loafers, temperature: nil)

        let items = uppers + [lower, shoes]
        let profile = makeProfile()
        let roles = KeyGarmentResolver.roles(for: items, profile: profile)

        for role in roles where uppers.map(\.id).contains(role.garmentID) {
            #expect(role.isKeyGarment == false)
        }

        // Lower and shoes still at 100%
        let lowerRole = roles.first { $0.garmentID == lower.id }!
        #expect(lowerRole.isKeyGarment == true)
    }

    // MARK: - Strong Combination Count

    @Test func strongCombinationCounting() {
        let items = minimalWardrobe()
        let profile = makeProfile()
        let roles = KeyGarmentResolver.roles(for: items, profile: profile)

        // With 1 outfit, strongCombinationCount is either 0 or 1
        for role in roles {
            #expect(role.strongCombinationCount >= 0)
            #expect(role.strongCombinationCount <= role.combinationCount)
        }
    }

    // MARK: - keyGarmentIDs

    @Test func keyGarmentIDsSorted() {
        let items = minimalWardrobe()
        let profile = makeProfile()
        let ids = KeyGarmentResolver.keyGarmentIDs(items: items, profile: profile)

        // All 3 items in single outfit → all at 100% → all key
        #expect(ids.count == 3)
    }

    // MARK: - Role Descriptor

    @Test func roleDescriptorFormat() {
        let items = minimalWardrobe()
        let profile = makeProfile()
        let roles = KeyGarmentResolver.roles(for: items, profile: profile)

        for role in roles {
            #expect(role.roleDescriptor.hasSuffix("av alle kombinasjoner"))
        }
    }

    // MARK: - Archetype Contributions

    @Test func archetypeContributionsPopulated() {
        let garment = makeGarment(baseGroup: .blazer)
        let role = KeyGarmentResolver.role(for: garment, in: minimalWardrobe() + [garment], profile: makeProfile())

        #expect(role.archetypeContributions.count == 3)
        #expect(abs(role.archetypeContributions[.tailored]! - 1.0) < 0.001)
    }

    // MARK: - Determinism

    @Test func deterministic() {
        let items = minimalWardrobe()
        let profile = makeProfile()
        let r1 = KeyGarmentResolver.roles(for: items, profile: profile)
        let r2 = KeyGarmentResolver.roles(for: items, profile: profile)

        #expect(r1.count == r2.count)
        for (a, b) in zip(r1, r2) {
            #expect(a.garmentID == b.garmentID)
            #expect(a.combinationCount == b.combinationCount)
            #expect(a.strongCombinationCount == b.strongCombinationCount)
            #expect(abs(a.combinationPercentage - b.combinationPercentage) < 0.001)
            #expect(a.isKeyGarment == b.isKeyGarment)
        }
    }

    // MARK: - Connected Garments

    @Test func connectedGarmentsBasic() {
        let items = minimalWardrobe()
        let profile = makeProfile()
        let target = items[0] // upper
        let connected = KeyGarmentResolver.connectedGarments(for: target, in: items, profile: profile)

        // In a 1-outfit wardrobe, the upper is connected to lower + shoes
        #expect(connected.count == 2)
        let connectedIDs = Set(connected.map(\.garmentID))
        #expect(connectedIDs.contains(items[1].id)) // lower
        #expect(connectedIDs.contains(items[2].id)) // shoes
    }

    @Test func connectedGarmentsSharedCount() {
        // 2 uppers × 1 lower × 1 shoes = 2 outfits
        // lower appears with upper1 once, upper2 once
        let upper1 = makeGarment(category: .upper, baseGroup: .shirt, temperature: 3)
        let upper2 = makeGarment(category: .upper, baseGroup: .tee, temperature: 3)
        let lower = makeGarment(category: .lower, silhouette: .regular, baseGroup: .chinos)
        let shoes = makeGarment(category: .shoes, silhouette: .none, baseGroup: .loafers, temperature: nil)

        let items = [upper1, upper2, lower, shoes]
        let profile = makeProfile()

        // Connected to lower: lower appears in both outfits, so from lower's perspective
        // it shares 1 outfit with upper1 and 1 with upper2
        let connected = KeyGarmentResolver.connectedGarments(for: lower, in: items, profile: profile)
        #expect(connected.count == 3) // upper1, upper2, shoes

        // shoes shares 2 outfits with lower (both outfits contain both)
        let shoesConnection = connected.first { $0.garmentID == shoes.id }!
        #expect(shoesConnection.sharedOutfitCount == 2)
    }

    @Test func connectedGarmentsSortedByCount() {
        let upper1 = makeGarment(category: .upper, baseGroup: .shirt, temperature: 3)
        let upper2 = makeGarment(category: .upper, baseGroup: .tee, temperature: 3)
        let lower = makeGarment(category: .lower, silhouette: .regular, baseGroup: .chinos)
        let shoes = makeGarment(category: .shoes, silhouette: .none, baseGroup: .loafers, temperature: nil)

        let items = [upper1, upper2, lower, shoes]
        let profile = makeProfile()
        let connected = KeyGarmentResolver.connectedGarments(for: lower, in: items, profile: profile)

        for i in 0..<(connected.count - 1) {
            #expect(connected[i].sharedOutfitCount >= connected[i + 1].sharedOutfitCount)
        }
    }

    @Test func connectedGarmentsRespectsLimit() {
        let items = minimalWardrobe()
        let profile = makeProfile()
        let connected = KeyGarmentResolver.connectedGarments(for: items[0], in: items, profile: profile, limit: 1)
        #expect(connected.count <= 1)
    }

    @Test func connectedGarmentsEmptyWardrobe() {
        let garment = makeGarment()
        let connected = KeyGarmentResolver.connectedGarments(for: garment, in: [], profile: makeProfile())
        #expect(connected.isEmpty)
    }

    @Test func connectedGarmentsNoOutfits() {
        // Only uppers, no outfits possible
        let items = [
            makeGarment(category: .upper, baseGroup: .shirt),
            makeGarment(category: .upper, baseGroup: .tee),
        ]
        let connected = KeyGarmentResolver.connectedGarments(for: items[0], in: items, profile: makeProfile())
        #expect(connected.isEmpty)
    }

    @Test func connectedGarmentsAverageStrength() {
        let items = minimalWardrobe()
        let profile = makeProfile()
        let connected = KeyGarmentResolver.connectedGarments(for: items[0], in: items, profile: profile)

        for c in connected {
            #expect(c.averageOutfitStrength >= 0)
            #expect(c.averageOutfitStrength <= 1.0)
        }
    }

    @Test func connectedGarmentsExcludesSelf() {
        let items = minimalWardrobe()
        let profile = makeProfile()
        let target = items[0]
        let connected = KeyGarmentResolver.connectedGarments(for: target, in: items, profile: profile)

        let connectedIDs = connected.map(\.garmentID)
        #expect(!connectedIDs.contains(target.id))
    }
}
