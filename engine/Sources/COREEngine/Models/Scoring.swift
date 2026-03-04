import Foundation

// MARK: - CohesionWeights

public struct CohesionWeights: Identifiable, Codable, Sendable {
    public let id: UUID
    public let layerCoverage: Double
    public let proportionBalance: Double
    public let thirdPiece: Double
    public let capsuleRatios: Double
    public let combinationDensity: Double
    public let standaloneQuality: Double

    public init(
        id: UUID = UUID(),
        layerCoverage: Double = 0.25,
        proportionBalance: Double = 0.20,
        thirdPiece: Double = 0.15,
        capsuleRatios: Double = 0.15,
        combinationDensity: Double = 0.15,
        standaloneQuality: Double = 0.10
    ) {
        self.id = id
        self.layerCoverage = layerCoverage
        self.proportionBalance = proportionBalance
        self.thirdPiece = thirdPiece
        self.capsuleRatios = capsuleRatios
        self.combinationDensity = combinationDensity
        self.standaloneQuality = standaloneQuality
    }

    public static let base = CohesionWeights()
}

// MARK: - CohesionBreakdown

public struct CohesionBreakdown: Identifiable, Codable, Sendable {
    public let id: UUID
    public let layerCoverageScore: Double
    public let proportionBalanceScore: Double
    public let thirdPieceScore: Double
    public let capsuleRatiosScore: Double
    public let combinationDensityScore: Double
    public let standaloneQualityScore: Double
    public let totalScore: Double
    public let itemIDs: Set<UUID>
    public let createdAt: Date

    public init(
        id: UUID = UUID(),
        layerCoverageScore: Double = 0,
        proportionBalanceScore: Double = 0,
        thirdPieceScore: Double = 0,
        capsuleRatiosScore: Double = 0,
        combinationDensityScore: Double = 0,
        standaloneQualityScore: Double = 0,
        totalScore: Double = 0,
        itemIDs: Set<UUID> = [],
        createdAt: Date = Date()
    ) {
        self.id = id
        self.layerCoverageScore = layerCoverageScore
        self.proportionBalanceScore = proportionBalanceScore
        self.thirdPieceScore = thirdPieceScore
        self.capsuleRatiosScore = capsuleRatiosScore
        self.combinationDensityScore = combinationDensityScore
        self.standaloneQualityScore = standaloneQualityScore
        self.totalScore = totalScore
        self.itemIDs = itemIDs
        self.createdAt = createdAt
    }
}

// MARK: - ClaritySnapshot

public struct ClaritySnapshot: Identifiable, Codable, Sendable {
    public let id: UUID
    public let score: Double
    public let band: ClarityBand
    public let archetypeScores: [Archetype: Double]
    public let dominantArchetype: Archetype
    public let cohesionBreakdown: CohesionBreakdown
    public let createdAt: Date

    public init(
        id: UUID = UUID(),
        score: Double = 0,
        band: ClarityBand = .fragmentert,
        archetypeScores: [Archetype: Double] = [:],
        dominantArchetype: Archetype = .smartCasual,
        cohesionBreakdown: CohesionBreakdown = CohesionBreakdown(),
        createdAt: Date = Date()
    ) {
        self.id = id
        self.score = score
        self.band = band
        self.archetypeScores = archetypeScores
        self.dominantArchetype = dominantArchetype
        self.cohesionBreakdown = cohesionBreakdown
        self.createdAt = createdAt
    }
}

// MARK: - Archetype Codable key conformance

extension Archetype: CodingKeyRepresentable {
    public var codingKey: CodingKey {
        AnyCodingKey(stringValue: rawValue)!
    }

    public init?<T: CodingKey>(codingKey: T) {
        self.init(rawValue: codingKey.stringValue)
    }
}

private struct AnyCodingKey: CodingKey {
    var stringValue: String
    var intValue: Int?

    init?(stringValue: String) {
        self.stringValue = stringValue
        self.intValue = nil
    }

    init?(intValue: Int) {
        self.stringValue = String(intValue)
        self.intValue = intValue
    }
}

// MARK: - ProjectionResult

public struct ProjectionResult: Identifiable, Codable, Sendable {
    public let id: UUID
    public let clarityBefore: Double
    public let clarityAfter: Double
    public let clarityDelta: Double
    public let archetypesBefore: [Archetype: Double]
    public let archetypesAfter: [Archetype: Double]
    public let combinationsGained: Int
    public let combinationsLost: Int
    public let gapsFilled: [String]
    public let gapsOpened: [String]
    public let breakdownBefore: CohesionBreakdown
    public let breakdownAfter: CohesionBreakdown

    public init(
        id: UUID = UUID(),
        clarityBefore: Double = 0,
        clarityAfter: Double = 0,
        clarityDelta: Double = 0,
        archetypesBefore: [Archetype: Double] = [:],
        archetypesAfter: [Archetype: Double] = [:],
        combinationsGained: Int = 0,
        combinationsLost: Int = 0,
        gapsFilled: [String] = [],
        gapsOpened: [String] = [],
        breakdownBefore: CohesionBreakdown = CohesionBreakdown(),
        breakdownAfter: CohesionBreakdown = CohesionBreakdown()
    ) {
        self.id = id
        self.clarityBefore = clarityBefore
        self.clarityAfter = clarityAfter
        self.clarityDelta = clarityDelta
        self.archetypesBefore = archetypesBefore
        self.archetypesAfter = archetypesAfter
        self.combinationsGained = combinationsGained
        self.combinationsLost = combinationsLost
        self.gapsFilled = gapsFilled
        self.gapsOpened = gapsOpened
        self.breakdownBefore = breakdownBefore
        self.breakdownAfter = breakdownAfter
    }
}
