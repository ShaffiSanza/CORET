import Testing
import Foundation
@testable import COREEngine

@Suite("BehaviouralEngine Tests")
struct BehaviouralEngineTests {

    // MARK: - Helpers

    private func makeGarment(
        id: UUID = UUID(),
        category: Category = .upper,
        baseGroup: BaseGroup = .tee,
        silhouette: Silhouette = .regular,
        colorTemperature: ColorTemp = .neutral
    ) -> Garment {
        Garment(
            id: id,
            category: category,
            silhouette: silhouette,
            baseGroup: baseGroup,
            colorTemperature: colorTemperature
        )
    }

    private func makeProfile(primary: Archetype = .smartCasual) -> UserProfile {
        UserProfile(primaryArchetype: primary)
    }

    private func makeLog(garmentID: UUID, daysAgo: Int) -> WearLog {
        WearLog(garmentID: garmentID, date: Date().addingTimeInterval(Double(-daysAgo) * 86400))
    }

    // MARK: - behaviouralArchetype

    @Test func behaviouralArchetypeEmptyItems() {
        let result = BehaviouralEngine.behaviouralArchetype(items: [], recentWear: [])
        #expect(result == .smartCasual)
    }

    @Test func behaviouralArchetypeEmptyWearLog() {
        let g = makeGarment(baseGroup: .blazer)
        let result = BehaviouralEngine.behaviouralArchetype(items: [g], recentWear: [])
        #expect(result == .smartCasual)
    }

    @Test func behaviouralArchetypeTailoredWear() {
        let g1 = makeGarment(baseGroup: .blazer)
        let g2 = makeGarment(category: .lower, baseGroup: .trousers)
        let g3 = makeGarment(category: .shoes, baseGroup: .loafers)

        let logs = [
            makeLog(garmentID: g1.id, daysAgo: 1),
            makeLog(garmentID: g2.id, daysAgo: 1),
            makeLog(garmentID: g3.id, daysAgo: 2),
            makeLog(garmentID: g1.id, daysAgo: 3),
            makeLog(garmentID: g2.id, daysAgo: 4),
        ]

        let result = BehaviouralEngine.behaviouralArchetype(items: [g1, g2, g3], recentWear: logs)
        #expect(result == .tailored)
    }

    @Test func behaviouralArchetypeStreetWear() {
        let g1 = makeGarment(baseGroup: .hoodie)
        let g2 = makeGarment(category: .lower, baseGroup: .jeans)
        let g3 = makeGarment(category: .shoes, baseGroup: .sneakers)

        let logs = [
            makeLog(garmentID: g1.id, daysAgo: 1),
            makeLog(garmentID: g2.id, daysAgo: 1),
            makeLog(garmentID: g3.id, daysAgo: 2),
        ]

        let result = BehaviouralEngine.behaviouralArchetype(items: [g1, g2, g3], recentWear: logs)
        #expect(result == .street)
    }

    @Test func behaviouralArchetypeRecencyWeighting() {
        // Recent street wear should outweigh old tailored wear
        let hoodie = makeGarment(baseGroup: .hoodie)
        let blazer = makeGarment(baseGroup: .blazer)

        let logs = [
            makeLog(garmentID: hoodie.id, daysAgo: 1),
            makeLog(garmentID: hoodie.id, daysAgo: 2),
            makeLog(garmentID: blazer.id, daysAgo: 60),
            makeLog(garmentID: blazer.id, daysAgo: 65),
        ]

        let result = BehaviouralEngine.behaviouralArchetype(items: [hoodie, blazer], recentWear: logs)
        #expect(result == .street)
    }

    // MARK: - detectDrift

    @Test func detectDriftEmptyInput() {
        let profile = makeProfile(primary: .tailored)
        let drift = BehaviouralEngine.detectDrift(profile: profile, items: [], wearLog: [])
        #expect(abs(drift - 0.0) < 0.001)
    }

    @Test func detectDriftNoDrift() {
        let profile = makeProfile(primary: .street)
        let g1 = makeGarment(baseGroup: .hoodie)
        let g2 = makeGarment(category: .shoes, baseGroup: .sneakers)

        let logs = [
            makeLog(garmentID: g1.id, daysAgo: 1),
            makeLog(garmentID: g2.id, daysAgo: 2),
        ]

        let drift = BehaviouralEngine.detectDrift(profile: profile, items: [g1, g2], wearLog: logs)
        #expect(abs(drift - 0.0) < 0.001)
    }

    @Test func detectDriftSignificant() {
        let profile = makeProfile(primary: .tailored)
        let g1 = makeGarment(baseGroup: .hoodie)
        let g2 = makeGarment(category: .shoes, baseGroup: .sneakers)

        let logs = [
            makeLog(garmentID: g1.id, daysAgo: 1),
            makeLog(garmentID: g2.id, daysAgo: 1),
            makeLog(garmentID: g1.id, daysAgo: 3),
        ]

        let drift = BehaviouralEngine.detectDrift(profile: profile, items: [g1, g2], wearLog: logs)
        #expect(drift > 0.3) // Tailored profile wearing street clothes = drift
    }

    @Test func detectDriftRange() {
        let profile = makeProfile(primary: .smartCasual)
        let g = makeGarment(baseGroup: .knit)
        let logs = [makeLog(garmentID: g.id, daysAgo: 1)]

        let drift = BehaviouralEngine.detectDrift(profile: profile, items: [g], wearLog: logs)
        #expect(drift >= 0 && drift <= 1)
    }

    // MARK: - predictNextWear

    @Test func predictNextWearTooFewLogs() {
        let g = makeGarment()
        let logs = [makeLog(garmentID: g.id, daysAgo: 5)]

        let prediction = BehaviouralEngine.predictNextWear(garment: g, wearLog: logs)
        #expect(prediction == nil)
    }

    @Test func predictNextWearNoLogs() {
        let g = makeGarment()
        let prediction = BehaviouralEngine.predictNextWear(garment: g, wearLog: [])
        #expect(prediction == nil)
    }

    @Test func predictNextWearRegularInterval() {
        let g = makeGarment()
        let logs = [
            makeLog(garmentID: g.id, daysAgo: 21),
            makeLog(garmentID: g.id, daysAgo: 14),
            makeLog(garmentID: g.id, daysAgo: 7),
        ]

        let prediction = BehaviouralEngine.predictNextWear(garment: g, wearLog: logs)
        #expect(prediction != nil)
        // With 7-day intervals, prediction should be ~7 days after last wear
    }

    @Test func predictNextWearIgnoresOtherGarments() {
        let g1 = makeGarment()
        let g2 = makeGarment()
        let logs = [
            makeLog(garmentID: g1.id, daysAgo: 14),
            makeLog(garmentID: g1.id, daysAgo: 7),
            makeLog(garmentID: g2.id, daysAgo: 1), // Should be ignored
        ]

        let prediction = BehaviouralEngine.predictNextWear(garment: g1, wearLog: logs)
        #expect(prediction != nil)
    }

    @Test func predictNextWearAfterLastWear() {
        let g = makeGarment()
        let logs = [
            makeLog(garmentID: g.id, daysAgo: 14),
            makeLog(garmentID: g.id, daysAgo: 7),
        ]

        let prediction = BehaviouralEngine.predictNextWear(garment: g, wearLog: logs)!
        let lastWear = logs.sorted { $0.date < $1.date }.last!.date
        #expect(prediction > lastWear)
    }

    // MARK: - unusedRisk

    @Test func unusedRiskNeverWorn() {
        let g = makeGarment()
        let risk = BehaviouralEngine.unusedRisk(garment: g, wearLog: [])
        #expect(abs(risk - 1.0) < 0.001)
    }

    @Test func unusedRiskRecentlyWorn() {
        let g = makeGarment()
        let logs = [
            makeLog(garmentID: g.id, daysAgo: 0),
            makeLog(garmentID: g.id, daysAgo: 7),
            makeLog(garmentID: g.id, daysAgo: 14),
        ]

        let risk = BehaviouralEngine.unusedRisk(garment: g, wearLog: logs)
        #expect(risk < 0.1) // Just worn today
    }

    @Test func unusedRiskLongAbsence() {
        let g = makeGarment()
        let logs = [
            makeLog(garmentID: g.id, daysAgo: 90),
            makeLog(garmentID: g.id, daysAgo: 97),
        ]

        let risk = BehaviouralEngine.unusedRisk(garment: g, wearLog: logs)
        #expect(risk > 0.8) // Very high risk
    }

    @Test func unusedRiskBounds() {
        let g = makeGarment()
        let logs = [makeLog(garmentID: g.id, daysAgo: 500)]

        let risk = BehaviouralEngine.unusedRisk(garment: g, wearLog: logs)
        #expect(risk >= 0 && risk <= 1)
    }

    // MARK: - rotationScore

    @Test func rotationScoreEmptyInput() {
        let score = BehaviouralEngine.rotationScore(items: [], wearLog: [])
        #expect(abs(score - 0.0) < 0.001)
    }

    @Test func rotationScoreEvenDistribution() {
        let g1 = makeGarment()
        let g2 = makeGarment(baseGroup: .shirt)
        let g3 = makeGarment(baseGroup: .knit)

        var logs: [WearLog] = []
        for i in 0..<10 {
            logs.append(makeLog(garmentID: g1.id, daysAgo: i * 3))
            logs.append(makeLog(garmentID: g2.id, daysAgo: i * 3 + 1))
            logs.append(makeLog(garmentID: g3.id, daysAgo: i * 3 + 2))
        }

        let score = BehaviouralEngine.rotationScore(items: [g1, g2, g3], wearLog: logs)
        #expect(score > 90) // Perfect rotation = high entropy
    }

    @Test func rotationScoreUnevenDistribution() {
        let g1 = makeGarment()
        let g2 = makeGarment(baseGroup: .shirt)
        let g3 = makeGarment(baseGroup: .knit)

        var logs: [WearLog] = []
        // Wear g1 heavily, g2 once, g3 never
        for i in 0..<20 {
            logs.append(makeLog(garmentID: g1.id, daysAgo: i * 2))
        }
        logs.append(makeLog(garmentID: g2.id, daysAgo: 5))

        let score = BehaviouralEngine.rotationScore(items: [g1, g2, g3], wearLog: logs)
        #expect(score < 50) // Poor rotation
    }

    @Test func rotationScoreRange() {
        let g = makeGarment()
        let logs = [makeLog(garmentID: g.id, daysAgo: 1)]

        let score = BehaviouralEngine.rotationScore(items: [g], wearLog: logs)
        #expect(score >= 0 && score <= 100)
    }

    @Test func rotationScoreNoRecentWear() {
        let g = makeGarment()
        let logs = [makeLog(garmentID: g.id, daysAgo: 200)] // Outside 90-day window

        let score = BehaviouralEngine.rotationScore(items: [g], wearLog: logs)
        #expect(abs(score - 0.0) < 0.001)
    }
}
