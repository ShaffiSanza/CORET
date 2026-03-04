import Foundation
import SwiftData
import COREEngine

// MARK: - EngineCacheEntity
// Optional performance layer. Stores the latest computed engine output as JSON blobs.
// Prevents full engine recompute on passive UI navigation (tab switches, app foreground).
//
// Invalidation: any structural mutation → EngineCoordinator deletes or clears this cache.
// Authority: cache is NEVER authoritative. Missing or stale cache → full recompute.
//
// Only one instance allowed. EngineCoordinator enforces singleton pattern.

@Model
final class EngineCacheEntity {

    var id: UUID
    var lastComputedAt: Date
    var clarityJSON: Data?      // Latest ClaritySnapshot encoded as JSON
    var gapResultJSON: Data?    // Latest GapResult encoded as JSON

    init(
        id: UUID = UUID(),
        lastComputedAt: Date = Date(),
        clarityJSON: Data? = nil,
        gapResultJSON: Data? = nil
    ) {
        self.id = id
        self.lastComputedAt = lastComputedAt
        self.clarityJSON = clarityJSON
        self.gapResultJSON = gapResultJSON
    }
}

// MARK: - Conversion

extension EngineCacheEntity {

    var claritySnapshot: ClaritySnapshot? {
        guard let data = clarityJSON else { return nil }
        return try? JSONDecoder().decode(ClaritySnapshot.self, from: data)
    }

    var gapResult: GapResult? {
        guard let data = gapResultJSON else { return nil }
        return try? JSONDecoder().decode(GapResult.self, from: data)
    }

    /// Update cache with latest engine output. Call after every successful recompute.
    func update(clarity: ClaritySnapshot, gaps: GapResult) {
        clarityJSON = try? JSONEncoder().encode(clarity)
        gapResultJSON = try? JSONEncoder().encode(gaps)
        lastComputedAt = Date()
    }

    /// Invalidate all cached data. Call before any structural mutation.
    func invalidate() {
        clarityJSON = nil
        gapResultJSON = nil
    }
}
