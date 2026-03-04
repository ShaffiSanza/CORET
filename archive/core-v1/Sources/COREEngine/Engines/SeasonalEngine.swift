import Foundation

// MARK: - Types

public struct CohesionWeights: Identifiable, Codable, Sendable {
    public let id: UUID
    public let alignment: Double
    public let density: Double
    public let palette: Double
    public let rotation: Double

    public init(
        id: UUID = UUID(),
        alignment: Double,
        density: Double,
        palette: Double,
        rotation: Double
    ) {
        self.id = id
        self.alignment = alignment
        self.density = density
        self.palette = palette
        self.rotation = rotation
    }
}

public struct SeasonalRecommendation: Identifiable, Codable, Sendable {
    public let id: UUID
    public let detectedSeason: SeasonMode?
    public let currentSeason: SeasonMode
    public let shouldRecalibrate: Bool
    public let adjustedWeights: CohesionWeights

    public init(
        id: UUID = UUID(),
        detectedSeason: SeasonMode?,
        currentSeason: SeasonMode,
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

// MARK: - SeasonalEngine

public enum SeasonalEngine: Sendable {

    // MARK: - Public API

    public static let baseWeights = CohesionWeights(
        alignment: 0.35, density: 0.30, palette: 0.20, rotation: 0.15
    )

    public static func detectSeason(latitude: Double, month: Int) -> SeasonMode? {
        guard (1...12).contains(month) else { return nil }

        let isSpringOrSummer = (3...8).contains(month)

        if latitude >= 15 {
            return isSpringOrSummer ? .springSummer : .autumnWinter
        } else if latitude <= -15 {
            return isSpringOrSummer ? .autumnWinter : .springSummer
        } else {
            return nil // Equatorial — user chooses
        }
    }

    public static func recommend(
        latitude: Double,
        month: Int,
        currentSeason: SeasonMode
    ) -> SeasonalRecommendation {
        let detected = detectSeason(latitude: latitude, month: month)

        let shouldRecalibrate: Bool
        if let detected {
            shouldRecalibrate = detected != currentSeason
        } else {
            shouldRecalibrate = false
        }

        let weights = adjustedWeights(for: detected ?? currentSeason)

        return SeasonalRecommendation(
            detectedSeason: detected,
            currentSeason: currentSeason,
            shouldRecalibrate: shouldRecalibrate,
            adjustedWeights: weights
        )
    }

    public static func adjustedWeights(for season: SeasonMode) -> CohesionWeights {
        let modA: Double
        let modD: Double
        let modP: Double
        let modR: Double

        switch season {
        case .springSummer:
            modA = 0.95; modD = 0.85; modP = 1.15; modR = 1.15
        case .autumnWinter:
            modA = 1.10; modD = 1.15; modP = 0.85; modR = 0.95
        }

        let rawA = baseWeights.alignment * modA
        let rawD = baseWeights.density * modD
        let rawP = baseWeights.palette * modP
        let rawR = baseWeights.rotation * modR
        let sum = rawA + rawD + rawP + rawR

        return CohesionWeights(
            alignment: rawA / sum,
            density: rawD / sum,
            palette: rawP / sum,
            rotation: rawR / sum
        )
    }
}
