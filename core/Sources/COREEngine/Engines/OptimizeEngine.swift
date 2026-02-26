import Foundation

// MARK: - Result Types

public enum WeaknessArea: String, Codable, CaseIterable, Sendable {
    case alignment
    case density
    case palette
    case rotation
}

public struct OptimizeRecommendation: Identifiable, Codable, Sendable {
    public let id: UUID
    public let candidate: WardrobeItem
    public let weaknessArea: WeaknessArea
    public let componentBefore: Double
    public let componentAfter: Double
    public let componentImprovement: Double
    public let totalBefore: Double
    public let totalAfter: Double
    public let totalImprovement: Double

    public init(
        id: UUID = UUID(),
        candidate: WardrobeItem,
        weaknessArea: WeaknessArea,
        componentBefore: Double,
        componentAfter: Double,
        componentImprovement: Double,
        totalBefore: Double,
        totalAfter: Double,
        totalImprovement: Double
    ) {
        self.id = id
        self.candidate = candidate
        self.weaknessArea = weaknessArea
        self.componentBefore = componentBefore
        self.componentAfter = componentAfter
        self.componentImprovement = componentImprovement
        self.totalBefore = totalBefore
        self.totalAfter = totalAfter
        self.totalImprovement = totalImprovement
    }
}

public struct StructuralFriction: Identifiable, Codable, Sendable {
    public let id: UUID
    public let item: WardrobeItem
    public let totalBefore: Double
    public let totalAfter: Double
    public let totalImprovement: Double

    public init(
        id: UUID = UUID(),
        item: WardrobeItem,
        totalBefore: Double,
        totalAfter: Double,
        totalImprovement: Double
    ) {
        self.id = id
        self.item = item
        self.totalBefore = totalBefore
        self.totalAfter = totalAfter
        self.totalImprovement = totalImprovement
    }
}

public struct OptimizeResult: Identifiable, Codable, Sendable {
    public let id: UUID
    public let currentSnapshot: CohesionSnapshot
    public let weakestArea: WeaknessArea
    public let primary: OptimizeRecommendation?
    public let secondary: [OptimizeRecommendation]
    public let friction: [StructuralFriction]

    public init(
        id: UUID = UUID(),
        currentSnapshot: CohesionSnapshot,
        weakestArea: WeaknessArea,
        primary: OptimizeRecommendation?,
        secondary: [OptimizeRecommendation],
        friction: [StructuralFriction]
    ) {
        self.id = id
        self.currentSnapshot = currentSnapshot
        self.weakestArea = weakestArea
        self.primary = primary
        self.secondary = secondary
        self.friction = friction
    }
}

// MARK: - OptimizeEngine

public enum OptimizeEngine: Sendable {

    // MARK: - Public API

    public static func optimize(items: [WardrobeItem], profile: UserProfile) -> OptimizeResult {
        let snapshot = CohesionEngine.compute(items: items, profile: profile)
        let weakness = weakestArea(from: snapshot)

        let candidates = generateCandidates(items: items, profile: profile, weakness: weakness)
        let beforeComponent = componentScore(snapshot, area: weakness)

        var scored: [OptimizeRecommendation] = []
        for candidate in candidates {
            var simulated = items
            simulated.append(candidate)
            let newSnapshot = CohesionEngine.compute(items: simulated, profile: profile)
            let afterComponent = componentScore(newSnapshot, area: weakness)

            scored.append(OptimizeRecommendation(
                candidate: candidate,
                weaknessArea: weakness,
                componentBefore: beforeComponent,
                componentAfter: afterComponent,
                componentImprovement: afterComponent - beforeComponent,
                totalBefore: snapshot.totalScore,
                totalAfter: newSnapshot.totalScore,
                totalImprovement: newSnapshot.totalScore - snapshot.totalScore
            ))
        }

        scored.sort { $0.componentImprovement > $1.componentImprovement }
        let positive = scored.filter { $0.componentImprovement > 0 }

        let primary = positive.first
        let secondary = Array(positive.dropFirst().prefix(2))

        let friction = detectFriction(items: items, profile: profile)

        return OptimizeResult(
            currentSnapshot: snapshot,
            weakestArea: weakness,
            primary: primary,
            secondary: secondary,
            friction: friction
        )
    }

    public static func weakestArea(from snapshot: CohesionSnapshot) -> WeaknessArea {
        let scores: [(WeaknessArea, Double)] = [
            (.alignment, snapshot.alignmentScore),
            (.density, snapshot.densityScore),
            (.palette, snapshot.paletteScore),
            (.rotation, snapshot.rotationScore),
        ]
        return scores.min(by: { $0.1 < $1.1 })!.0
    }

    public static func detectFriction(items: [WardrobeItem], profile: UserProfile) -> [StructuralFriction] {
        let currentSnapshot = CohesionEngine.compute(items: items, profile: profile)
        var results: [StructuralFriction] = []

        for i in items.indices {
            var simulated = items
            simulated.remove(at: i)
            guard !simulated.isEmpty else { continue }

            let newSnapshot = CohesionEngine.compute(items: simulated, profile: profile)
            let improvement = newSnapshot.totalScore - currentSnapshot.totalScore

            if improvement > 8 {
                results.append(StructuralFriction(
                    item: items[i],
                    totalBefore: currentSnapshot.totalScore,
                    totalAfter: newSnapshot.totalScore,
                    totalImprovement: improvement
                ))
            }
        }

        return results.sorted { $0.totalImprovement > $1.totalImprovement }
    }

    // MARK: - Private Helpers

    private static func componentScore(_ snapshot: CohesionSnapshot, area: WeaknessArea) -> Double {
        switch area {
        case .alignment: return snapshot.alignmentScore
        case .density:   return snapshot.densityScore
        case .palette:   return snapshot.paletteScore
        case .rotation:  return snapshot.rotationScore
        }
    }

    private static func dominantTemperature(items: [WardrobeItem]) -> Temperature {
        let warm = items.filter { $0.temperature == .warm }.count
        let cool = items.filter { $0.temperature == .cool }.count
        if warm > cool { return .warm }
        if cool > warm { return .cool }
        return .neutral
    }

    private static func generateCandidates(
        items: [WardrobeItem],
        profile: UserProfile,
        weakness: WeaknessArea
    ) -> [WardrobeItem] {
        let categories: [ItemCategory] = [.top, .bottom, .shoes, .outerwear]
        let domTemp = dominantTemperature(items: items)

        switch weakness {
        case .alignment:
            // Primary archetype items across all categories
            var candidates: [WardrobeItem] = []
            for cat in categories {
                candidates.append(makeCandidate(
                    category: cat, silhouette: .balanced,
                    baseGroup: .neutral, temperature: domTemp,
                    archetype: profile.primaryArchetype
                ))
            }
            // Secondary archetype as fallback options
            for cat in categories {
                candidates.append(makeCandidate(
                    category: cat, silhouette: .balanced,
                    baseGroup: .neutral, temperature: domTemp,
                    archetype: profile.secondaryArchetype
                ))
            }
            return candidates

        case .density:
            // Vary category and silhouette to maximize outfit validity
            var candidates: [WardrobeItem] = []
            let silhouettes: [Silhouette] = [.balanced, .structured, .relaxed]
            for cat in categories {
                for sil in silhouettes {
                    candidates.append(makeCandidate(
                        category: cat, silhouette: sil,
                        baseGroup: .neutral, temperature: domTemp,
                        archetype: profile.primaryArchetype
                    ))
                }
            }
            return candidates

        case .palette:
            // Neutral and deep items to correct palette ratios
            var candidates: [WardrobeItem] = []
            let targetGroups: [BaseGroup] = [.neutral, .deep]
            for cat in categories {
                for group in targetGroups {
                    candidates.append(makeCandidate(
                        category: cat, silhouette: .balanced,
                        baseGroup: group, temperature: domTemp,
                        archetype: profile.primaryArchetype
                    ))
                }
            }
            return candidates

        case .rotation:
            // Add items to each category to dilute usage deviation
            var candidates: [WardrobeItem] = []
            for cat in categories {
                candidates.append(makeCandidate(
                    category: cat, silhouette: .balanced,
                    baseGroup: .neutral, temperature: domTemp,
                    archetype: profile.primaryArchetype
                ))
            }
            return candidates
        }
    }

    private static func makeCandidate(
        category: ItemCategory,
        silhouette: Silhouette,
        baseGroup: BaseGroup,
        temperature: Temperature,
        archetype: Archetype
    ) -> WardrobeItem {
        WardrobeItem(
            imagePath: "",
            category: category,
            silhouette: silhouette,
            rawColor: "candidate",
            baseGroup: baseGroup,
            temperature: temperature,
            archetypeTag: archetype
        )
    }
}
