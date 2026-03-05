import Testing
import Foundation
@testable import COREEngine

@Suite("SimilarityEngine Tests")
struct SimilarityEngineTests {

    // MARK: - Helpers

    private func makeGarment(
        id: UUID = UUID(),
        category: Category = .upper,
        baseGroup: BaseGroup = .tee
    ) -> Garment {
        Garment(id: id, category: category, baseGroup: baseGroup)
    }

    // MARK: - cosineSimilarity

    @Test func cosineSimilarityIdentical() {
        let v: [Float] = [1, 2, 3]
        let sim = SimilarityEngine.cosineSimilarity(v, v)
        #expect(abs(sim - 1.0) < 0.001)
    }

    @Test func cosineSimilarityOrthogonal() {
        let a: [Float] = [1, 0, 0]
        let b: [Float] = [0, 1, 0]
        let sim = SimilarityEngine.cosineSimilarity(a, b)
        #expect(abs(sim - 0.0) < 0.001)
    }

    @Test func cosineSimilarityOpposite() {
        let a: [Float] = [1, 0, 0]
        let b: [Float] = [-1, 0, 0]
        let sim = SimilarityEngine.cosineSimilarity(a, b)
        #expect(abs(sim - (-1.0)) < 0.001)
    }

    @Test func cosineSimilarityEmptyVectors() {
        let sim = SimilarityEngine.cosineSimilarity([], [])
        #expect(abs(sim - 0.0) < 0.001)
    }

    @Test func cosineSimilarityMismatchedLengths() {
        let sim = SimilarityEngine.cosineSimilarity([1, 2], [1, 2, 3])
        #expect(abs(sim - 0.0) < 0.001)
    }

    @Test func cosineSimilarityZeroVector() {
        let sim = SimilarityEngine.cosineSimilarity([0, 0, 0], [1, 2, 3])
        #expect(abs(sim - 0.0) < 0.001)
    }

    // MARK: - duplicates

    @Test func duplicatesEmptyItems() {
        let result = SimilarityEngine.duplicates(items: [], embeddings: [:])
        #expect(result.isEmpty)
    }

    @Test func duplicatesSingleItem() {
        let g = makeGarment()
        let result = SimilarityEngine.duplicates(items: [g], embeddings: [g.id: [1, 0, 0]])
        #expect(result.isEmpty)
    }

    @Test func duplicatesFoundAboveThreshold() {
        let g1 = makeGarment()
        let g2 = makeGarment()
        let g3 = makeGarment()

        let embeddings: [UUID: [Float]] = [
            g1.id: [1.0, 0.0, 0.0],
            g2.id: [0.99, 0.05, 0.0],  // Very similar to g1
            g3.id: [0.0, 1.0, 0.0],    // Different
        ]

        let result = SimilarityEngine.duplicates(items: [g1, g2, g3], embeddings: embeddings, threshold: 0.95)
        #expect(result.count == 1)
        #expect(result[0].count == 2)
    }

    @Test func duplicatesNoneFound() {
        let g1 = makeGarment()
        let g2 = makeGarment()

        let embeddings: [UUID: [Float]] = [
            g1.id: [1, 0, 0],
            g2.id: [0, 1, 0],
        ]

        let result = SimilarityEngine.duplicates(items: [g1, g2], embeddings: embeddings)
        #expect(result.isEmpty)
    }

    @Test func duplicatesNoEmbeddings() {
        let g1 = makeGarment()
        let g2 = makeGarment()
        let result = SimilarityEngine.duplicates(items: [g1, g2], embeddings: [:])
        #expect(result.isEmpty)
    }

    // MARK: - mostSimilar

    @Test func mostSimilarBasic() {
        let g1 = makeGarment()
        let g2 = makeGarment()
        let g3 = makeGarment()

        let embeddings: [UUID: [Float]] = [
            g1.id: [1, 0, 0],
            g2.id: [0.9, 0.1, 0],
            g3.id: [0, 1, 0],
        ]

        let result = SimilarityEngine.mostSimilar(to: g1, in: [g1, g2, g3], embeddings: embeddings, limit: 2)
        #expect(result.count == 2)
        #expect(result[0].0.id == g2.id) // g2 is most similar to g1
    }

    @Test func mostSimilarNoEmbeddingForTarget() {
        let g1 = makeGarment()
        let g2 = makeGarment()
        let result = SimilarityEngine.mostSimilar(to: g1, in: [g2], embeddings: [g2.id: [1, 0]])
        #expect(result.isEmpty)
    }

    @Test func mostSimilarExcludesSelf() {
        let g1 = makeGarment()
        let embeddings: [UUID: [Float]] = [g1.id: [1, 0, 0]]
        let result = SimilarityEngine.mostSimilar(to: g1, in: [g1], embeddings: embeddings)
        #expect(result.isEmpty)
    }

    // MARK: - redundancyScore

    @Test func redundancyScoreAllUnique() {
        let g1 = makeGarment()
        let g2 = makeGarment()

        let embeddings: [UUID: [Float]] = [
            g1.id: [1, 0, 0],
            g2.id: [0, 1, 0],
        ]

        let score = SimilarityEngine.redundancyScore(items: [g1, g2], embeddings: embeddings)
        #expect(score > 90)
    }

    @Test func redundancyScoreHighRedundancy() {
        let g1 = makeGarment()
        let g2 = makeGarment()

        let embeddings: [UUID: [Float]] = [
            g1.id: [1, 0, 0],
            g2.id: [0.99, 0.01, 0],
        ]

        let score = SimilarityEngine.redundancyScore(items: [g1, g2], embeddings: embeddings)
        #expect(score < 10)
    }

    @Test func redundancyScoreSingleItem() {
        let g = makeGarment()
        let score = SimilarityEngine.redundancyScore(items: [g], embeddings: [g.id: [1, 0]])
        #expect(abs(score - 100) < 0.001)
    }

    @Test func redundancyScoreNoEmbeddings() {
        let g1 = makeGarment()
        let g2 = makeGarment()
        let score = SimilarityEngine.redundancyScore(items: [g1, g2], embeddings: [:])
        #expect(abs(score - 100) < 0.001)
    }
}
