import Foundation
import SwiftData
import COREEngine

// MARK: - ClaritySnapshotEntity
// Immutable once written. Never edited after creation.
// Stores the full ClaritySnapshot as a JSON blob (ClaritySnapshot is Codable).
// This approach avoids field duplication and future-proofs the schema.
//
// Creation trigger (enforced by EngineCoordinator):
//   - First snapshot ever
//   - clarityDelta > 5 vs most recent stored snapshot
//   - First recompute of a new calendar month

@Model
final class ClaritySnapshotEntity {

    var id: UUID
    var createdAt: Date
    var score: Double           // Denormalized for fast sorting/filtering without decode
    var snapshotJSON: Data      // Full ClaritySnapshot encoded as JSON

    init(id: UUID = UUID(), createdAt: Date = Date(), score: Double, snapshotJSON: Data) {
        self.id = id
        self.createdAt = createdAt
        self.score = score
        self.snapshotJSON = snapshotJSON
    }
}

// MARK: - Conversion

extension ClaritySnapshotEntity {

    /// Decode stored JSON → ClaritySnapshot. Returns nil if data is corrupt.
    func decode() -> ClaritySnapshot? {
        try? JSONDecoder().decode(ClaritySnapshot.self, from: snapshotJSON)
    }

    /// Create entity from a computed ClaritySnapshot.
    /// Returns nil if encoding fails (should never happen — ClaritySnapshot is Codable).
    static func from(_ snapshot: ClaritySnapshot) -> ClaritySnapshotEntity? {
        guard let data = try? JSONEncoder().encode(snapshot) else { return nil }
        return ClaritySnapshotEntity(
            id: snapshot.id,
            createdAt: snapshot.createdAt,
            score: snapshot.score,
            snapshotJSON: data
        )
    }
}

// MARK: - Snapshot Persistence Policy

extension ClaritySnapshotEntity {

    /// Whether a new snapshot should be persisted given the current and prior state.
    /// Called by EngineCoordinator after each recompute.
    static func shouldPersist(
        newSnapshot: ClaritySnapshot,
        lastStored: ClaritySnapshotEntity?
    ) -> Bool {
        guard let last = lastStored else { return true }   // Always store first snapshot

        // First-of-month trigger
        let calendar = Calendar.current
        if !calendar.isDate(newSnapshot.createdAt, equalTo: last.createdAt, toGranularity: .month) {
            return true
        }

        // Score delta trigger
        let delta = abs(newSnapshot.score - last.score)
        return delta > 5.0
    }
}
