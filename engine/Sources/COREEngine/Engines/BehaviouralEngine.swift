import Foundation

/// Behavioural analysis engine — wear patterns, drift detection, rotation health.
/// Pure functions, no state. Uses WearLog data to analyse actual wardrobe usage.
public enum BehaviouralEngine: Sendable {

    // MARK: - Behavioural Archetype

    /// Determine the user's behavioural archetype from actual wear data.
    /// Weights recent wears more heavily using exponential decay (30-day half-life).
    /// Returns .smartCasual as default for empty input.
    public static func behaviouralArchetype(items: [Garment], recentWear: [WearLog]) -> Archetype {
        guard !items.isEmpty, !recentWear.isEmpty else { return .smartCasual }

        let itemMap = Dictionary(uniqueKeysWithValues: items.map { ($0.id, $0) })
        let now = recentWear.map(\.date).max() ?? Date()
        let halfLife = 30.0 * 86400.0 // 30 days in seconds

        var archetypeWeights: [Archetype: Double] = [:]
        for archetype in Archetype.allCases {
            archetypeWeights[archetype] = 0
        }

        for log in recentWear {
            guard let garment = itemMap[log.garmentID] else { continue }
            let daysSince = now.timeIntervalSince(log.date)
            let weight = pow(2.0, -(daysSince / halfLife))

            for archetype in Archetype.allCases {
                let affinity = CohesionEngine.archetypeAffinity(baseGroup: garment.baseGroup, archetype: archetype)
                archetypeWeights[archetype, default: 0] += affinity * weight
            }
        }

        let sorted = archetypeWeights.sorted { $0.value > $1.value }
        return sorted.first?.key ?? .smartCasual
    }

    // MARK: - Drift Detection

    /// Compare declared archetype vs behavioural archetype.
    /// Returns 0.0 (no drift) to 1.0 (complete drift).
    /// Empty input returns 0.0.
    public static func detectDrift(profile: UserProfile, items: [Garment], wearLog: [WearLog]) -> Double {
        guard !items.isEmpty, !wearLog.isEmpty else { return 0 }

        let itemMap = Dictionary(uniqueKeysWithValues: items.map { ($0.id, $0) })
        let now = wearLog.map(\.date).max() ?? Date()
        let halfLife = 30.0 * 86400.0

        var archetypeWeights: [Archetype: Double] = [:]
        for archetype in Archetype.allCases {
            archetypeWeights[archetype] = 0
        }

        for log in wearLog {
            guard let garment = itemMap[log.garmentID] else { continue }
            let daysSince = now.timeIntervalSince(log.date)
            let weight = pow(2.0, -(daysSince / halfLife))

            for archetype in Archetype.allCases {
                let affinity = CohesionEngine.archetypeAffinity(baseGroup: garment.baseGroup, archetype: archetype)
                archetypeWeights[archetype, default: 0] += affinity * weight
            }
        }

        let maxWeight = archetypeWeights.values.max() ?? 0
        guard maxWeight > 0 else { return 0 }

        let declaredWeight = archetypeWeights[profile.primaryArchetype] ?? 0
        return 1.0 - (declaredWeight / maxWeight)
    }

    // MARK: - Predict Next Wear

    /// Predict when a garment will next be worn using exponential smoothing on intervals.
    /// Returns nil if fewer than 2 wear logs exist for this garment.
    public static func predictNextWear(garment: Garment, wearLog: [WearLog]) -> Date? {
        let logs = wearLog
            .filter { $0.garmentID == garment.id }
            .sorted { $0.date < $1.date }

        guard logs.count >= 2 else { return nil }

        var intervals: [Double] = []
        for i in 1..<logs.count {
            let interval = logs[i].date.timeIntervalSince(logs[i - 1].date)
            intervals.append(interval)
        }

        // Exponential smoothing (alpha = 0.3)
        let alpha = 0.3
        var smoothed = intervals[0]
        for i in 1..<intervals.count {
            smoothed = alpha * intervals[i] + (1 - alpha) * smoothed
        }

        let lastDate = logs.last!.date
        return lastDate.addingTimeInterval(smoothed)
    }

    // MARK: - Unused Risk

    /// Risk that a garment is becoming unused (0 = actively worn, 1 = at risk).
    /// Never-worn garments return 1.0.
    public static func unusedRisk(garment: Garment, wearLog: [WearLog]) -> Double {
        let logs = wearLog
            .filter { $0.garmentID == garment.id }
            .sorted { $0.date < $1.date }

        guard !logs.isEmpty else { return 1.0 }

        let now = Date()
        let lastWorn = logs.last!.date
        let daysSinceLastWear = now.timeIntervalSince(lastWorn) / 86400.0

        // Average interval between wears
        if logs.count >= 2 {
            var totalInterval = 0.0
            for i in 1..<logs.count {
                totalInterval += logs[i].date.timeIntervalSince(logs[i - 1].date) / 86400.0
            }
            let avgInterval = totalInterval / Double(logs.count - 1)
            return min(daysSinceLastWear / (avgInterval * 2), 1.0)
        }

        // Single wear: use days since that wear vs 30-day threshold
        return min(daysSinceLastWear / 60.0, 1.0)
    }

    // MARK: - Rotation Score

    /// How evenly garments are rotated in the last 90 days (0–100).
    /// High entropy = good rotation. Returns 0 for empty input.
    public static func rotationScore(items: [Garment], wearLog: [WearLog]) -> Double {
        guard !items.isEmpty, !wearLog.isEmpty else { return 0 }

        let now = wearLog.map(\.date).max() ?? Date()
        let cutoff = now.addingTimeInterval(-90 * 86400)

        let recentLogs = wearLog.filter { $0.date >= cutoff }
        guard !recentLogs.isEmpty else { return 0 }

        // Count wears per garment (only for garments in items)
        let itemIDs = Set(items.map(\.id))
        var counts: [UUID: Int] = [:]
        for id in itemIDs {
            counts[id] = 0
        }
        for log in recentLogs where itemIDs.contains(log.garmentID) {
            counts[log.garmentID, default: 0] += 1
        }

        let countArray = Array(counts.values)
        return ScoringHelpers.normalizedEntropy(countArray) * 100
    }
}
