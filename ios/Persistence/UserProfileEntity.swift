import Foundation
import SwiftData
import COREEngine

// MARK: - UserProfileEntity
// Singleton. Only one instance allowed in V1.
// EngineCoordinator enforces this — fetches first result or creates one.
// Mutations trigger EngineCoordinator.recompute().

@Model
final class UserProfileEntity {

    var id: UUID
    var createdAt: Date
    var primaryArchetype: String        // Archetype.rawValue
    var latitude: Double?               // nil until user grants location
    var longitude: Double?
    var lastRecalibrationDate: Date?    // Last accepted seasonal recalibration

    init(
        id: UUID = UUID(),
        createdAt: Date = Date(),
        primaryArchetype: String = Archetype.smartCasual.rawValue,
        latitude: Double? = nil,
        longitude: Double? = nil,
        lastRecalibrationDate: Date? = nil
    ) {
        self.id = id
        self.createdAt = createdAt
        self.primaryArchetype = primaryArchetype
        self.latitude = latitude
        self.longitude = longitude
        self.lastRecalibrationDate = lastRecalibrationDate
    }
}

// MARK: - Conversion

extension UserProfileEntity {

    func toProfile() -> UserProfile {
        UserProfile(
            id: id,
            primaryArchetype: Archetype(rawValue: primaryArchetype) ?? .smartCasual,
            createdAt: createdAt
        )
    }

    static func from(_ profile: UserProfile) -> UserProfileEntity {
        UserProfileEntity(
            id: profile.id,
            createdAt: profile.createdAt,
            primaryArchetype: profile.primaryArchetype.rawValue
        )
    }
}
