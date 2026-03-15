import Foundation

/// Per-garment combination analysis result. Runtime-only — not persisted.
public struct GarmentRole: Identifiable, Sendable {
    public let id: UUID
    public let garmentID: UUID
    public let combinationCount: Int
    public let strongCombinationCount: Int
    public let totalOutfitCount: Int
    public let combinationPercentage: Double    // 0–1
    public let isKeyGarment: Bool
    public let roleDescriptor: String           // "29% av alle kombinasjoner"
    public let archetypeContributions: [Archetype: Double]

    public init(
        id: UUID = UUID(),
        garmentID: UUID,
        combinationCount: Int,
        strongCombinationCount: Int,
        totalOutfitCount: Int,
        combinationPercentage: Double,
        isKeyGarment: Bool,
        roleDescriptor: String,
        archetypeContributions: [Archetype: Double]
    ) {
        self.id = id
        self.garmentID = garmentID
        self.combinationCount = combinationCount
        self.strongCombinationCount = strongCombinationCount
        self.totalOutfitCount = totalOutfitCount
        self.combinationPercentage = combinationPercentage
        self.isKeyGarment = isKeyGarment
        self.roleDescriptor = roleDescriptor
        self.archetypeContributions = archetypeContributions
    }
}

/// Which other garments appear alongside a target garment in outfits.
public struct ConnectedGarment: Identifiable, Codable, Sendable {
    public let id: UUID
    public let garmentID: UUID
    public let sharedOutfitCount: Int
    public let averageOutfitStrength: Double

    public init(
        id: UUID = UUID(),
        garmentID: UUID,
        sharedOutfitCount: Int,
        averageOutfitStrength: Double
    ) {
        self.id = id
        self.garmentID = garmentID
        self.sharedOutfitCount = sharedOutfitCount
        self.averageOutfitStrength = averageOutfitStrength
    }
}

/// Resolves per-garment structural role based on outfit combination analysis.
public enum KeyGarmentResolver: Sendable {

    /// Threshold for key garment status: garment appears in ≥20% of all outfits.
    public static let keyGarmentThreshold: Double = 0.20

    /// Compute role for a single garment within the wardrobe.
    public static func role(for garment: Garment, in items: [Garment], profile: UserProfile) -> GarmentRole {
        let outfits = ScoringHelpers.generateOutfits(from: items)
        return buildRole(for: garment, outfits: outfits, totalOutfitCount: outfits.count, profile: profile)
    }

    /// Compute roles for all garments. Generates outfits once for efficiency.
    public static func roles(for items: [Garment], profile: UserProfile) -> [GarmentRole] {
        let outfits = ScoringHelpers.generateOutfits(from: items)
        let totalCount = outfits.count
        return items.map { garment in
            buildRole(for: garment, outfits: outfits, totalOutfitCount: totalCount, profile: profile)
        }
    }

    /// Returns IDs of all garments that meet the key garment threshold.
    /// Sorted by combinationPercentage descending.
    public static func keyGarmentIDs(items: [Garment], profile: UserProfile) -> [UUID] {
        roles(for: items, profile: profile)
            .filter(\.isKeyGarment)
            .sorted { $0.combinationPercentage > $1.combinationPercentage }
            .map(\.garmentID)
    }

    /// Returns garments most frequently paired with the target in outfits.
    public static func connectedGarments(for garment: Garment, in items: [Garment], profile: UserProfile, limit: Int = 5) -> [ConnectedGarment] {
        let outfits = ScoringHelpers.generateOutfits(from: items)
        let containing = outfits.filter { outfit in
            outfit.contains { $0.id == garment.id }
        }
        guard !containing.isEmpty else { return [] }

        // Count co-occurrences and accumulate strengths per partner garment
        var counts: [UUID: Int] = [:]
        var strengthSums: [UUID: Double] = [:]

        for outfit in containing {
            let strength = CohesionEngine.outfitStrength(outfit: outfit, profile: profile)
            for item in outfit where item.id != garment.id {
                counts[item.id, default: 0] += 1
                strengthSums[item.id, default: 0] += strength
            }
        }

        return counts.keys
            .map { id in
                let count = counts[id]!
                return ConnectedGarment(
                    garmentID: id,
                    sharedOutfitCount: count,
                    averageOutfitStrength: strengthSums[id]! / Double(count)
                )
            }
            .sorted { $0.sharedOutfitCount > $1.sharedOutfitCount }
            .prefix(limit)
            .map { $0 }
    }

    // MARK: - Private

    private static func buildRole(for garment: Garment, outfits: [[Garment]], totalOutfitCount: Int, profile: UserProfile) -> GarmentRole {
        // Accessories are excluded from outfit generation → always 0
        guard garment.category != .accessory else {
            return GarmentRole(
                garmentID: garment.id,
                combinationCount: 0,
                strongCombinationCount: 0,
                totalOutfitCount: totalOutfitCount,
                combinationPercentage: 0,
                isKeyGarment: false,
                roleDescriptor: "0% av alle kombinasjoner",
                archetypeContributions: archetypeContributions(for: garment)
            )
        }

        guard totalOutfitCount > 0 else {
            return GarmentRole(
                garmentID: garment.id,
                combinationCount: 0,
                strongCombinationCount: 0,
                totalOutfitCount: 0,
                combinationPercentage: 0,
                isKeyGarment: false,
                roleDescriptor: "0% av alle kombinasjoner",
                archetypeContributions: archetypeContributions(for: garment)
            )
        }

        let containingOutfits = outfits.filter { outfit in
            outfit.contains { $0.id == garment.id }
        }
        let combinationCount = containingOutfits.count

        let strongCount = containingOutfits.filter { outfit in
            CohesionEngine.outfitStrength(outfit: outfit, profile: profile) >= 0.65
        }.count

        let percentage = Double(combinationCount) / Double(totalOutfitCount)
        let percentRounded = Int((percentage * 100).rounded())
        let descriptor = "\(percentRounded)% av alle kombinasjoner"

        return GarmentRole(
            garmentID: garment.id,
            combinationCount: combinationCount,
            strongCombinationCount: strongCount,
            totalOutfitCount: totalOutfitCount,
            combinationPercentage: percentage,
            isKeyGarment: percentage >= keyGarmentThreshold,
            roleDescriptor: descriptor,
            archetypeContributions: archetypeContributions(for: garment)
        )
    }

    private static func archetypeContributions(for garment: Garment) -> [Archetype: Double] {
        var result: [Archetype: Double] = [:]
        for archetype in Archetype.allCases {
            result[archetype] = CohesionEngine.archetypeAffinity(baseGroup: garment.baseGroup, archetype: archetype)
        }
        return result
    }
}
