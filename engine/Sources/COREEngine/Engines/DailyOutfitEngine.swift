import Foundation

/// Daily outfit recommendation — the "open app, here's your day" engine.
/// Combines BestOutfitFinder, DailyOutfitScorer, and BehaviouralEngine
/// into a single result for the Wardrobe hero block.
public enum DailyOutfitEngine: Sendable {

    /// Complete daily recommendation result.
    public struct DailyRecommendation: Identifiable, Codable, Sendable {
        public let id: UUID
        public let outfit: RankedOutfit?
        public let score: OutfitScore?
        public let rotationTips: [RotationTip]
        public let clarityScore: Double
        public let clarityBand: ClarityBand
        public let primaryGap: String?
        public let createdAt: Date

        public init(
            id: UUID = UUID(),
            outfit: RankedOutfit? = nil,
            score: OutfitScore? = nil,
            rotationTips: [RotationTip] = [],
            clarityScore: Double = 0,
            clarityBand: ClarityBand = .fragmentert,
            primaryGap: String? = nil,
            createdAt: Date = Date()
        ) {
            self.id = id
            self.outfit = outfit
            self.score = score
            self.rotationTips = rotationTips
            self.clarityScore = clarityScore
            self.clarityBand = clarityBand
            self.primaryGap = primaryGap
            self.createdAt = createdAt
        }
    }

    /// A garment the user hasn't worn recently.
    public struct RotationTip: Identifiable, Codable, Sendable {
        public let id: UUID
        public let garmentID: UUID
        public let garmentName: String
        public let daysSinceWorn: Int
        public let unusedRisk: Double

        public init(
            id: UUID = UUID(),
            garmentID: UUID,
            garmentName: String,
            daysSinceWorn: Int,
            unusedRisk: Double
        ) {
            self.id = id
            self.garmentID = garmentID
            self.garmentName = garmentName
            self.daysSinceWorn = daysSinceWorn
            self.unusedRisk = unusedRisk
        }
    }

    /// Generate today's recommendation from wardrobe state.
    public static func recommend(
        items: [Garment],
        profile: UserProfile,
        wearLog: [WearLog],
        wornOutfits: Set<Set<UUID>>
    ) -> DailyRecommendation {
        guard !items.isEmpty else {
            return DailyRecommendation()
        }

        // 1. Best untried outfit
        let bestOutfits = BestOutfitFinder.findUntriedBest(
            items: items,
            wornOutfits: wornOutfits,
            profile: profile,
            count: 1
        )
        let topOutfit = bestOutfits.first

        // 2. Score it
        let outfitScore: OutfitScore?
        if let outfit = topOutfit {
            outfitScore = DailyOutfitScorer.scoreOutfit(garments: outfit.garments, profile: profile)
        } else {
            outfitScore = nil
        }

        // 3. Rotation tips — garments with high unused risk
        let tips = generateRotationTips(items: items, wearLog: wearLog)

        // 4. Clarity
        let clarity = ClarityEngine.compute(items: items, profile: profile)

        // 5. Primary gap from optimize
        let gaps = detectPrimaryGap(items: items)

        return DailyRecommendation(
            outfit: topOutfit,
            score: outfitScore,
            rotationTips: tips,
            clarityScore: clarity.score,
            clarityBand: clarity.band,
            primaryGap: gaps
        )
    }

    // MARK: - Private

    private static func generateRotationTips(items: [Garment], wearLog: [WearLog], limit: Int = 3) -> [RotationTip] {
        let now = Date()

        return items.compactMap { garment -> RotationTip? in
            let risk = BehaviouralEngine.unusedRisk(garment: garment, wearLog: wearLog)
            guard risk >= 0.5 else { return nil }

            let lastWorn = wearLog
                .filter { $0.garmentID == garment.id }
                .map(\.date)
                .max()

            let days: Int
            if let last = lastWorn {
                days = Int(now.timeIntervalSince(last) / 86400)
            } else {
                days = Int(now.timeIntervalSince(garment.dateAdded) / 86400)
            }

            return RotationTip(
                garmentID: garment.id,
                garmentName: garment.name,
                daysSinceWorn: days,
                unusedRisk: risk
            )
        }
        .sorted { $0.unusedRisk > $1.unusedRisk }
        .prefix(limit)
        .map { $0 }
    }

    private static func detectPrimaryGap(items: [Garment]) -> String? {
        let hasUpper = items.contains { $0.category == .upper }
        let hasLower = items.contains { $0.category == .lower }
        let hasShoes = items.contains { $0.category == .shoes }

        if !hasLower { return "Missing lower — add pants or trousers" }
        if !hasUpper { return "Missing upper — add a top or shirt" }
        if !hasShoes { return "Missing shoes" }

        // Check layers
        let hasBase = items.contains { $0.category == .upper && $0.temperature == 3 }
        let hasMid = items.contains { $0.category == .upper && $0.temperature == 2 }
        let hasOuter = items.contains { $0.category == .upper && $0.temperature == 1 }

        if !hasMid { return "Missing mid-layer — a blazer or knit would add structure" }
        if !hasOuter { return "Missing outer layer — a coat would expand seasonal coverage" }
        if !hasBase { return "Missing base layer" }

        return nil
    }
}
