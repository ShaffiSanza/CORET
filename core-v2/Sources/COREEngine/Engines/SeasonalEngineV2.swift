import Foundation

// MARK: - Types

public enum Season: String, Codable, CaseIterable, Sendable {
    case spring, summer, autumn, winter
}

public struct SeasonalCoverage: Identifiable, Codable, Sendable {
    public let id: UUID
    public let springScore: Double
    public let summerScore: Double
    public let autumnScore: Double
    public let winterScore: Double
    public let weakestSeason: Season

    public init(
        id: UUID = UUID(),
        springScore: Double,
        summerScore: Double,
        autumnScore: Double,
        winterScore: Double,
        weakestSeason: Season
    ) {
        self.id = id
        self.springScore = springScore
        self.summerScore = summerScore
        self.autumnScore = autumnScore
        self.winterScore = winterScore
        self.weakestSeason = weakestSeason
    }

    public func coverage(for season: Season) -> Double {
        switch season {
        case .spring: return springScore
        case .summer: return summerScore
        case .autumn: return autumnScore
        case .winter: return winterScore
        }
    }
}

public struct SeasonalWeights: Identifiable, Codable, Sendable {
    public let id: UUID
    public let season: Season
    public let weights: CohesionWeights

    public init(id: UUID = UUID(), season: Season, weights: CohesionWeights) {
        self.id = id
        self.season = season
        self.weights = weights
    }
}

public struct SeasonalRecommendationV2: Identifiable, Codable, Sendable {
    public let id: UUID
    public let detectedSeason: Season?
    public let currentSeason: Season
    public let shouldRecalibrate: Bool
    public let adjustedWeights: CohesionWeights

    public init(
        id: UUID = UUID(),
        detectedSeason: Season?,
        currentSeason: Season,
        shouldRecalibrate: Bool,
        adjustedWeights: CohesionWeights
    ) {
        self.id = id
        self.detectedSeason = detectedSeason
        self.currentSeason = currentSeason
        self.shouldRecalibrate = shouldRecalibrate
        self.adjustedWeights = adjustedWeights
    }
}

// MARK: - Engine

/// Seasonal coverage analysis with 4-season support.
/// Per-garment season mapping based on layer depth and color temperature.
public enum SeasonalEngineV2: Sendable {

    /// Base cohesion weights (same as CohesionWeights.base).
    public static let baseWeights: CohesionWeights = .base

    // MARK: - Coverage

    /// Compute per-season wardrobe coverage.
    public static func coverage(items: [Garment]) -> SeasonalCoverage {
        guard !items.isEmpty else {
            return SeasonalCoverage(
                springScore: 0, summerScore: 0, autumnScore: 0, winterScore: 0,
                weakestSeason: .spring
            )
        }

        var springTotal = 0.0
        var summerTotal = 0.0
        var autumnTotal = 0.0
        var winterTotal = 0.0

        for item in items {
            let cov = garmentCoverage(garment: item)
            springTotal += cov[.spring] ?? 0
            summerTotal += cov[.summer] ?? 0
            autumnTotal += cov[.autumn] ?? 0
            winterTotal += cov[.winter] ?? 0
        }

        let count = Double(items.count)
        let spring = min(springTotal / count * 100, 100)
        let summer = min(summerTotal / count * 100, 100)
        let autumn = min(autumnTotal / count * 100, 100)
        let winter = min(winterTotal / count * 100, 100)

        let scores: [(Season, Double)] = [
            (.spring, spring), (.summer, summer), (.autumn, autumn), (.winter, winter)
        ]
        let weakest = scores.min(by: { $0.1 < $1.1 })!.0

        return SeasonalCoverage(
            springScore: spring,
            summerScore: summer,
            autumnScore: autumn,
            winterScore: winter,
            weakestSeason: weakest
        )
    }

    /// Per-garment season affinity values.
    public static func garmentCoverage(garment: Garment) -> [Season: Double] {
        let temp = garment.colorTemperature

        // Non-upper items
        guard garment.category == .upper else {
            return [.spring: 0.6, .summer: 0.6, .autumn: 0.6, .winter: 0.6]
        }

        // Upper items: map by layer depth (temperature) and color temp
        let layer = garment.temperature ?? 2 // nil treated as layer 2

        switch (layer, temp) {
        case (1, .cool), (1, .neutral):
            return [.spring: 0.3, .summer: 0.0, .autumn: 1.0, .winter: 1.0]
        case (1, .warm):
            return [.spring: 0.4, .summer: 0.1, .autumn: 1.0, .winter: 0.8]
        case (2, _):
            return [.spring: 0.6, .summer: 0.2, .autumn: 0.8, .winter: 0.7]
        case (3, .warm):
            return [.spring: 0.8, .summer: 0.6, .autumn: 0.5, .winter: 0.3]
        case (3, .cool), (3, .neutral):
            return [.spring: 0.9, .summer: 0.8, .autumn: 0.4, .winter: 0.3]
        default:
            // Fallback for unexpected layer values → treat as layer 2
            return [.spring: 0.6, .summer: 0.2, .autumn: 0.8, .winter: 0.7]
        }
    }

    // MARK: - Season Detection

    /// Detect current season from latitude and month.
    /// Returns nil for equatorial (|latitude| < 15).
    public static func detectSeason(latitude: Double, month: Int) -> Season? {
        guard month >= 1 && month <= 12 else { return nil }
        guard abs(latitude) >= 15 else { return nil }

        let northern = latitude >= 15
        let baseSeason: Season

        switch month {
        case 3, 4, 5:   baseSeason = .spring
        case 6, 7, 8:   baseSeason = .summer
        case 9, 10, 11:  baseSeason = .autumn
        default:         baseSeason = .winter // 12, 1, 2
        }

        if northern {
            return baseSeason
        } else {
            return flipSeason(baseSeason)
        }
    }

    // MARK: - Adjusted Weights

    /// Adjust cohesion weights for a season, renormalized to sum=1.0.
    public static func adjustedWeights(for season: Season) -> CohesionWeights {
        let base = CohesionWeights.base
        let modifiers = seasonModifiers(for: season)

        let rawLC = base.layerCoverage * modifiers.layerCoverage
        let rawPB = base.proportionBalance * modifiers.proportionBalance
        let rawTP = base.thirdPiece * modifiers.thirdPiece
        let rawCR = base.capsuleRatios * modifiers.capsuleRatios
        let rawCD = base.combinationDensity * modifiers.combinationDensity
        let rawSQ = base.standaloneQuality * modifiers.standaloneQuality

        let sum = rawLC + rawPB + rawTP + rawCR + rawCD + rawSQ

        return CohesionWeights(
            layerCoverage: rawLC / sum,
            proportionBalance: rawPB / sum,
            thirdPiece: rawTP / sum,
            capsuleRatios: rawCR / sum,
            combinationDensity: rawCD / sum,
            standaloneQuality: rawSQ / sum
        )
    }

    /// Seasonal recommendation based on location and current season.
    public static func recommend(latitude: Double, month: Int, currentSeason: Season) -> SeasonalRecommendationV2 {
        let detected = detectSeason(latitude: latitude, month: month)
        let shouldRecalibrate = detected != nil && detected != currentSeason
        let weights = detected.map { adjustedWeights(for: $0) } ?? adjustedWeights(for: currentSeason)

        return SeasonalRecommendationV2(
            detectedSeason: detected,
            currentSeason: currentSeason,
            shouldRecalibrate: shouldRecalibrate,
            adjustedWeights: weights
        )
    }

    // MARK: - Private

    private static func flipSeason(_ season: Season) -> Season {
        switch season {
        case .spring: return .autumn
        case .summer: return .winter
        case .autumn: return .spring
        case .winter: return .summer
        }
    }

    /// Per-season multiplicative modifiers for the 6 cohesion weights.
    private static func seasonModifiers(for season: Season) -> (
        layerCoverage: Double, proportionBalance: Double, thirdPiece: Double,
        capsuleRatios: Double, combinationDensity: Double, standaloneQuality: Double
    ) {
        switch season {
        case .winter:
            // Layering emphasis, third piece important
            return (1.20, 0.95, 1.25, 1.00, 1.00, 0.85)
        case .autumn:
            // Moderate layering emphasis
            return (1.10, 1.00, 1.10, 1.05, 0.95, 0.90)
        case .spring:
            // Balanced, slight standalone quality emphasis
            return (0.95, 1.05, 0.90, 1.00, 1.05, 1.10)
        case .summer:
            // Reduced layering, standalone quality and combinations matter
            return (0.80, 1.05, 0.75, 0.95, 1.15, 1.25)
        }
    }
}
