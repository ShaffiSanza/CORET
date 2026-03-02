import Foundation
import SwiftData

// MARK: - SavedOutfitEntity
// Persists user-pinned outfits as an ordered list of garment UUIDs.
// Outfits are NOT computed at storage time — garment IDs reference current GarmentEntity.
// EngineCoordinator can rescore a saved outfit on demand using the current garment state.
//
// Deletion: if a referenced garment is deleted, the outfit becomes partial.
// EngineCoordinator filters out stale IDs before rescoring.

@Model
final class SavedOutfitEntity {

    var id: UUID
    var createdAt: Date
    var garmentIDs: [UUID]      // Ordered: [upper, lower, shoes, optional accessories...]
    var savedScore: Double      // Outfit score at time of saving (for display without rescore)
    var label: String           // User-editable label, default ""

    init(
        id: UUID = UUID(),
        createdAt: Date = Date(),
        garmentIDs: [UUID],
        savedScore: Double,
        label: String = ""
    ) {
        self.id = id
        self.createdAt = createdAt
        self.garmentIDs = garmentIDs
        self.savedScore = savedScore
        self.label = label
    }
}
