import Foundation

public enum ScoringHelpers {

    /// Scores a value against an ideal range [idealLower, idealUpper].
    /// Returns 0–100. In range → 100. Below → proportional. Above → penalized via overPenaltyDivisor.
    static func rangeScore(value: Double, idealLower: Double, idealUpper: Double, overPenaltyDivisor: Double) -> Double {
        if value >= idealLower && value <= idealUpper {
            return 100
        } else if value < idealLower {
            guard idealLower > 0 else { return 0 }
            return (value / idealLower) * 100
        } else {
            guard overPenaltyDivisor > 0 else { return 0 }
            return max(0, (1.0 - (value - idealUpper) / overPenaltyDivisor) * 100)
        }
    }

    /// Shannon entropy normalized by log₂(n). Returns 0–1.
    /// Perfect distribution → 1.0. Single value → 0.0.
    /// Filters out zero counts. Returns 0 if fewer than 2 non-zero buckets.
    static func normalizedEntropy(_ counts: [Int]) -> Double {
        let nonZero = counts.filter { $0 > 0 }
        let n = nonZero.count
        guard n >= 2 else { return 0 }

        let total = Double(nonZero.reduce(0, +))
        guard total > 0 else { return 0 }

        var entropy = 0.0
        for count in nonZero {
            let p = Double(count) / total
            if p > 0 {
                entropy -= p * Foundation.log2(p)
            }
        }

        let maxEntropy = Foundation.log2(Double(n))
        guard maxEntropy > 0 else { return 0 }

        return entropy / maxEntropy
    }

    /// Returns the plurality winner from a frequency map.
    /// Returns nil on tie.
    static func plurality<T: Hashable>(_ items: [T]) -> T? {
        guard !items.isEmpty else { return nil }

        var counts: [T: Int] = [:]
        for item in items {
            counts[item, default: 0] += 1
        }

        let maxCount = counts.values.max() ?? 0
        let winners = counts.filter { $0.value == maxCount }.map(\.key)

        if winners.count == 1 {
            return winners[0]
        }
        return nil
    }

    /// Generates all structurally complete outfit combinations.
    /// An outfit = 1 upper + 1 lower + 1 shoes. Accessories not included.
    public static func generateOutfits(from items: [Garment]) -> [[Garment]] {
        let uppers = items.filter { $0.category == .upper }
        let lowers = items.filter { $0.category == .lower }
        let shoes = items.filter { $0.category == .shoes }

        guard !uppers.isEmpty, !lowers.isEmpty, !shoes.isEmpty else {
            return []
        }

        var outfits: [[Garment]] = []
        for upper in uppers {
            for lower in lowers {
                for shoe in shoes {
                    outfits.append([upper, lower, shoe])
                }
            }
        }
        return outfits
    }
}
