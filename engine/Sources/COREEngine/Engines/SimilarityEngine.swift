import Foundation

/// Similarity engine — cosine similarity on pre-computed embedding vectors.
/// Pure math, no ML. Embeddings are generated on-device by Core ML.
public enum SimilarityEngine: Sendable {

    // MARK: - Cosine Similarity

    /// Standard cosine similarity between two vectors. Returns 0 for edge cases.
    public static func cosineSimilarity(_ a: [Float], _ b: [Float]) -> Float {
        guard a.count == b.count, !a.isEmpty else { return 0 }

        var dot: Float = 0
        var magA: Float = 0
        var magB: Float = 0

        for i in 0..<a.count {
            dot += a[i] * b[i]
            magA += a[i] * a[i]
            magB += b[i] * b[i]
        }

        let denominator = sqrt(magA) * sqrt(magB)
        guard denominator > 0 else { return 0 }

        return max(-1, min(1, dot / denominator))
    }

    // MARK: - Duplicate Detection

    /// Find groups of near-duplicate garments based on embedding similarity.
    /// Uses union-find for transitive grouping. Returns only groups of 2+.
    public static func duplicates(
        items: [Garment],
        embeddings: [UUID: [Float]],
        threshold: Float = 0.92
    ) -> [[Garment]] {
        guard items.count >= 2 else { return [] }

        // Union-find
        var parent = Array(0..<items.count)

        func find(_ x: Int) -> Int {
            var x = x
            while parent[x] != x {
                parent[x] = parent[parent[x]]
                x = parent[x]
            }
            return x
        }

        func union(_ x: Int, _ y: Int) {
            let px = find(x)
            let py = find(y)
            if px != py { parent[px] = py }
        }

        for i in 0..<items.count {
            guard let embA = embeddings[items[i].id] else { continue }
            for j in (i + 1)..<items.count {
                guard let embB = embeddings[items[j].id] else { continue }
                if cosineSimilarity(embA, embB) >= threshold {
                    union(i, j)
                }
            }
        }

        // Group by root
        var groups: [Int: [Garment]] = [:]
        for i in 0..<items.count {
            let root = find(i)
            groups[root, default: []].append(items[i])
        }

        return groups.values.filter { $0.count >= 2 }.sorted { $0.count > $1.count }
    }

    // MARK: - Most Similar

    /// Find the most similar garments to a target, sorted by similarity descending.
    public static func mostSimilar(
        to garment: Garment,
        in items: [Garment],
        embeddings: [UUID: [Float]],
        limit: Int = 5
    ) -> [(Garment, Float)] {
        guard let targetEmb = embeddings[garment.id] else { return [] }

        var results: [(Garment, Float)] = []
        for item in items where item.id != garment.id {
            guard let emb = embeddings[item.id] else { continue }
            let sim = cosineSimilarity(targetEmb, emb)
            results.append((item, sim))
        }

        results.sort { $0.1 > $1.1 }
        return Array(results.prefix(limit))
    }

    // MARK: - Redundancy Score

    /// Overall wardrobe redundancy (0–100). 100 = all unique, low = many duplicates.
    public static func redundancyScore(items: [Garment], embeddings: [UUID: [Float]]) -> Double {
        guard items.count >= 2 else { return 100 }

        var totalMaxSim = 0.0
        var counted = 0

        for item in items {
            guard let emb = embeddings[item.id] else { continue }
            var maxSim: Float = 0
            for other in items where other.id != item.id {
                guard let otherEmb = embeddings[other.id] else { continue }
                let sim = cosineSimilarity(emb, otherEmb)
                if sim > maxSim { maxSim = sim }
            }
            totalMaxSim += Double(maxSim)
            counted += 1
        }

        guard counted > 0 else { return 100 }
        let avgMaxSim = totalMaxSim / Double(counted)
        // 0 avg similarity = 100 score, 1.0 avg similarity = 0 score
        return (1.0 - avgMaxSim) * 100
    }
}
