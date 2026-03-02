import Foundation
import SwiftData
import COREEngine

// MARK: - GarmentEntity
// Persists V2 Garment model fields as primitives (no enums).
// All enum conversion happens via toGarment() / from(_:) helpers.
// Editing any structural field must invalidate EngineCacheEntity
// and trigger EngineCoordinator.recompute().

@Model
final class GarmentEntity {

    // MARK: Identity
    var id: UUID
    var name: String
    var image: String
    var dateAdded: Date
    var source: String              // ImportSource.rawValue

    // MARK: Structural
    var category: String            // Category.rawValue
    var silhouette: String          // Silhouette.rawValue
    var baseGroup: String           // BaseGroup.rawValue
    var temperature: Int?           // 1 / 2 / 3 — upper only, nil for others
    var usageContext: String?       // UsageContext.rawValue — lower only, nil for others
    var colorTemperature: String    // ColorTemp.rawValue

    // MARK: Visual
    var dominantColor: String       // Hex string e.g. "#1A1A1A"

    // MARK: Flags
    var isFavorite: Bool
    var isKeyGarment: Bool          // Updated by EngineCoordinator after recompute

    // MARK: Init
    init(
        id: UUID = UUID(),
        name: String = "",
        image: String = "",
        dateAdded: Date = Date(),
        source: String = ImportSource.manual.rawValue,
        category: String,
        silhouette: String = Silhouette.none.rawValue,
        baseGroup: String,
        temperature: Int? = nil,
        usageContext: String? = nil,
        colorTemperature: String = ColorTemp.neutral.rawValue,
        dominantColor: String = "#000000",
        isFavorite: Bool = false,
        isKeyGarment: Bool = false
    ) {
        self.id = id
        self.name = name
        self.image = image
        self.dateAdded = dateAdded
        self.source = source
        self.category = category
        self.silhouette = silhouette
        self.baseGroup = baseGroup
        self.temperature = temperature
        self.usageContext = usageContext
        self.colorTemperature = colorTemperature
        self.dominantColor = dominantColor
        self.isFavorite = isFavorite
        self.isKeyGarment = isKeyGarment
    }
}

// MARK: - Conversion

extension GarmentEntity {

    /// Convert entity → V2 engine domain model.
    func toGarment() -> Garment {
        Garment(
            id: id,
            image: image,
            name: name,
            category: Category(rawValue: category) ?? .upper,
            silhouette: Silhouette(rawValue: silhouette) ?? .none,
            baseGroup: BaseGroup(rawValue: baseGroup) ?? .tee,
            temperature: temperature,
            usageContext: usageContext.flatMap { UsageContext(rawValue: $0) },
            colorTemperature: ColorTemp(rawValue: colorTemperature) ?? .neutral,
            dominantColor: dominantColor,
            isFavorite: isFavorite,
            isKeyGarment: isKeyGarment,
            dateAdded: dateAdded,
            source: ImportSource(rawValue: source) ?? .manual
        )
    }

    /// Create entity from V2 engine domain model.
    static func from(_ garment: Garment) -> GarmentEntity {
        GarmentEntity(
            id: garment.id,
            name: garment.name,
            image: garment.image,
            dateAdded: garment.dateAdded,
            source: garment.source.rawValue,
            category: garment.category.rawValue,
            silhouette: garment.silhouette.rawValue,
            baseGroup: garment.baseGroup.rawValue,
            temperature: garment.temperature,
            usageContext: garment.usageContext?.rawValue,
            colorTemperature: garment.colorTemperature.rawValue,
            dominantColor: garment.dominantColor,
            isFavorite: garment.isFavorite,
            isKeyGarment: garment.isKeyGarment
        )
    }

    /// Update mutable fields from a newer Garment value.
    /// Called by EngineCoordinator.updateGarment(_:).
    func apply(_ garment: Garment) {
        name = garment.name
        image = garment.image
        category = garment.category.rawValue
        silhouette = garment.silhouette.rawValue
        baseGroup = garment.baseGroup.rawValue
        temperature = garment.temperature
        usageContext = garment.usageContext?.rawValue
        colorTemperature = garment.colorTemperature.rawValue
        dominantColor = garment.dominantColor
        isFavorite = garment.isFavorite
        isKeyGarment = garment.isKeyGarment
        source = garment.source.rawValue
        // id and dateAdded are immutable — never overwritten
    }
}
