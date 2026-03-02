import Foundation
import SwiftData

// MARK: - SwiftDataStack
// Centralizes ModelContainer configuration.
// All 6 entities registered here. Schema versioning handled here.
//
// Usage in COREApp.swift:
//   .modelContainer(SwiftDataStack.container)

enum SwiftDataStack {

    static let schema = Schema([
        GarmentEntity.self,
        UserProfileEntity.self,
        ClaritySnapshotEntity.self,
        MilestoneEntity.self,
        SavedOutfitEntity.self,
        EngineCacheEntity.self
    ])

    static let modelConfiguration = ModelConfiguration(
        schema: schema,
        isStoredInMemoryOnly: false,
        cloudKitDatabase: .none    // Local-first. No CloudKit in V1.
    )

    static let container: ModelContainer = {
        do {
            return try ModelContainer(for: schema, configurations: [modelConfiguration])
        } catch {
            fatalError("SwiftData ModelContainer failed to initialize: \(error)")
        }
    }()

    // MARK: - In-Memory Container (for Xcode Previews + Tests)

    static func previewContainer() -> ModelContainer {
        let config = ModelConfiguration(schema: schema, isStoredInMemoryOnly: true)
        return (try? ModelContainer(for: schema, configurations: [config]))
            ?? { fatalError("Preview container init failed") }()
    }
}
