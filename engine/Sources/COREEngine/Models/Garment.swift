import Foundation

// MARK: - Enums

public enum Category: String, Codable, CaseIterable, Sendable {
    case upper
    case lower
    case shoes
    case accessory
}

public enum Silhouette: String, Codable, CaseIterable, Sendable {
    case fitted
    case relaxed
    case tapered
    case oversized
    case slim
    case regular
    case wide
    case none
}

public enum BaseGroup: String, Codable, CaseIterable, Sendable {
    case tee
    case shirt
    case knit
    case hoodie
    case blazer
    case coat
    case jeans
    case chinos
    case trousers
    case shorts
    case skirt
    case sneakers
    case boots
    case loafers
    case sandals
    case belt
    case scarf
    case cap
    case bag
}

public enum ColorTemp: String, Codable, CaseIterable, Sendable {
    case warm
    case cool
    case neutral
}

public enum Archetype: String, Codable, CaseIterable, Sendable {
    case tailored
    case smartCasual
    case street
}

public enum UsageContext: String, Codable, CaseIterable, Sendable {
    case everyday
    case smart
    case active
}

public enum ImportSource: String, Codable, CaseIterable, Sendable {
    case camera
    case email
    case zalando
    case hm
    case manual
}

public enum ClarityBand: String, Codable, CaseIterable, Sendable {
    case fragmentert
    case iUtvikling
    case fokusert
    case krystallklar
}

public enum ClarityTrend: String, Codable, CaseIterable, Sendable {
    case improving
    case stable
    case declining
}

// MARK: - Garment

public struct Garment: Identifiable, Codable, Sendable {
    public let id: UUID
    public var image: String
    public var name: String
    public var category: Category
    public var silhouette: Silhouette
    public var baseGroup: BaseGroup
    public var temperature: Int?
    public var usageContext: UsageContext?
    public var colorTemperature: ColorTemp
    public var dominantColor: String
    public var isFavorite: Bool
    public var isKeyGarment: Bool
    public let dateAdded: Date
    public var source: ImportSource

    public init(
        id: UUID = UUID(),
        image: String = "",
        name: String = "",
        category: Category,
        silhouette: Silhouette = .none,
        baseGroup: BaseGroup,
        temperature: Int? = nil,
        usageContext: UsageContext? = nil,
        colorTemperature: ColorTemp = .neutral,
        dominantColor: String = "#000000",
        isFavorite: Bool = false,
        isKeyGarment: Bool = false,
        dateAdded: Date = Date(),
        source: ImportSource = .manual
    ) {
        self.id = id
        self.image = image
        self.name = name
        self.category = category
        self.silhouette = silhouette
        self.baseGroup = baseGroup
        self.temperature = temperature
        self.usageContext = usageContext
        self.colorTemperature = colorTemperature
        self.dominantColor = dominantColor
        self.isFavorite = isFavorite
        self.isKeyGarment = isKeyGarment
        self.dateAdded = dateAdded
        self.source = source
    }
}

// MARK: - UserProfile

public struct UserProfile: Identifiable, Codable, Sendable {
    public let id: UUID
    public var primaryArchetype: Archetype
    public var height: Int?       // cm, V2 body-aware scoring
    public var build: String?     // e.g. "compact", "tall-slim", "athletic" — V2
    public let createdAt: Date

    public init(
        id: UUID = UUID(),
        primaryArchetype: Archetype = .smartCasual,
        height: Int? = nil,
        build: String? = nil,
        createdAt: Date = Date()
    ) {
        self.id = id
        self.primaryArchetype = primaryArchetype
        self.height = height
        self.build = build
        self.createdAt = createdAt
    }
}

// MARK: - WearLog

public struct WearLog: Identifiable, Codable, Sendable {
    public let id: UUID
    public let garmentID: UUID
    public let date: Date

    public init(
        id: UUID = UUID(),
        garmentID: UUID,
        date: Date = Date()
    ) {
        self.id = id
        self.garmentID = garmentID
        self.date = date
    }
}
