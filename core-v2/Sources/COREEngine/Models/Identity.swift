import Foundation

/// Structural identity derived from current wardrobe state.
/// Used for Dashboard hero, Journey screen, and profile display.
public struct WardrobeIdentity: Identifiable, Codable, Sendable {
    public let id: UUID
    public let dominantSilhouette: Silhouette?     // nil = tied
    public let dominantColorTemperature: ColorTemp  // .neutral on tie
    public let dominantArchetype: Archetype         // highest score, profile tiebreak
    public let identityLabel: String                // "Strukturert · Varm"
    public let tags: [String]                       // 3–4 descriptors
    public let prose: String                        // 1–2 sentence identity description
    public let createdAt: Date

    public init(
        id: UUID = UUID(),
        dominantSilhouette: Silhouette?,
        dominantColorTemperature: ColorTemp,
        dominantArchetype: Archetype,
        identityLabel: String,
        tags: [String],
        prose: String,
        createdAt: Date = Date()
    ) {
        self.id = id
        self.dominantSilhouette = dominantSilhouette
        self.dominantColorTemperature = dominantColorTemperature
        self.dominantArchetype = dominantArchetype
        self.identityLabel = identityLabel
        self.tags = tags
        self.prose = prose
        self.createdAt = createdAt
    }
}
