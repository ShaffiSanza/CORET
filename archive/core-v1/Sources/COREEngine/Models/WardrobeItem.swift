import Foundation

// MARK: - Enums

public enum ItemCategory: String, Codable, CaseIterable, Sendable {
    case top
    case bottom
    case shoes
    case outerwear
}

public enum Silhouette: String, Codable, CaseIterable, Sendable {
    case structured
    case balanced
    case relaxed
}

public enum BaseGroup: String, Codable, CaseIterable, Sendable {
    case neutral
    case deep
    case light
    case accent
}

public enum Temperature: String, Codable, CaseIterable, Sendable {
    case warm
    case cool
    case neutral
}

public enum Archetype: String, Codable, CaseIterable, Sendable {
    case structuredMinimal
    case relaxedStreet
    case smartCasual
}

public enum SeasonMode: String, Codable, CaseIterable, Sendable {
    case springSummer
    case autumnWinter
}

public enum CohesionStatus: String, Codable, CaseIterable, Sendable {
    case structuring
    case refining
    case coherent
    case aligned
    case architected
}

// MARK: - StructuralIdentity

public struct StructuralIdentity: Identifiable, Codable, Sendable, Equatable {
    public let id: UUID
    public let dominantSilhouette: Silhouette?
    public let dominantBaseGroup: BaseGroup?
    public let dominantTemperature: Temperature

    public init(
        id: UUID = UUID(),
        dominantSilhouette: Silhouette?,
        dominantBaseGroup: BaseGroup?,
        dominantTemperature: Temperature
    ) {
        self.id = id
        self.dominantSilhouette = dominantSilhouette
        self.dominantBaseGroup = dominantBaseGroup
        self.dominantTemperature = dominantTemperature
    }
}

// MARK: - WardrobeItem

public struct WardrobeItem: Identifiable, Codable, Sendable {
    public let id: UUID
    public var imagePath: String

    public var category: ItemCategory
    public var silhouette: Silhouette

    public var rawColor: String
    public var baseGroup: BaseGroup
    public var temperature: Temperature

    public var archetypeTag: Archetype

    public var customColorOverride: Bool

    public var usageCount: Int
    public var lastWornDate: Date?

    public let createdAt: Date

    public init(
        id: UUID = UUID(),
        imagePath: String,
        category: ItemCategory,
        silhouette: Silhouette,
        rawColor: String,
        baseGroup: BaseGroup,
        temperature: Temperature,
        archetypeTag: Archetype,
        customColorOverride: Bool = false,
        usageCount: Int = 0,
        lastWornDate: Date? = nil,
        createdAt: Date = Date()
    ) {
        self.id = id
        self.imagePath = imagePath
        self.category = category
        self.silhouette = silhouette
        self.rawColor = rawColor
        self.baseGroup = baseGroup
        self.temperature = temperature
        self.archetypeTag = archetypeTag
        self.customColorOverride = customColorOverride
        self.usageCount = usageCount
        self.lastWornDate = lastWornDate
        self.createdAt = createdAt
    }
}

// MARK: - UserProfile

public struct UserProfile: Identifiable, Codable, Sendable {
    public let id: UUID

    public var primaryArchetype: Archetype
    public var secondaryArchetype: Archetype

    public var seasonMode: SeasonMode

    public let createdAt: Date

    public init(
        id: UUID = UUID(),
        primaryArchetype: Archetype,
        secondaryArchetype: Archetype,
        seasonMode: SeasonMode,
        createdAt: Date = Date()
    ) {
        self.id = id
        self.primaryArchetype = primaryArchetype
        self.secondaryArchetype = secondaryArchetype
        self.seasonMode = seasonMode
        self.createdAt = createdAt
    }
}

// MARK: - CohesionSnapshot

public struct CohesionSnapshot: Identifiable, Codable, Sendable {
    public let id: UUID

    public var alignmentScore: Double
    public var densityScore: Double
    public var paletteScore: Double
    public var rotationScore: Double

    public var totalScore: Double
    public var statusLevel: CohesionStatus

    public let itemIDs: Set<UUID>

    public let createdAt: Date

    public init(
        id: UUID = UUID(),
        alignmentScore: Double,
        densityScore: Double,
        paletteScore: Double,
        rotationScore: Double,
        totalScore: Double,
        statusLevel: CohesionStatus,
        itemIDs: Set<UUID> = [],
        createdAt: Date = Date()
    ) {
        self.id = id
        self.alignmentScore = alignmentScore
        self.densityScore = densityScore
        self.paletteScore = paletteScore
        self.rotationScore = rotationScore
        self.totalScore = totalScore
        self.statusLevel = statusLevel
        self.itemIDs = itemIDs
        self.createdAt = createdAt
    }
}
