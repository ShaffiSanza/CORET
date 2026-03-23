import Foundation

/// Prioritizes evaluated fashion rules by impact, confidence, and relevance.
/// Input: [RuleResult] from FashionTheoryEngine
/// Output: PrioritizedRules (primary issue, secondary issue, primary positive)
public enum RulePriorityEngine: Sendable {

    /// Prioritize rule results. Priority = |impact| x confidence.
    public static func prioritize(_ results: [RuleResult]) -> PrioritizedRules {
        guard !results.isEmpty else {
            return PrioritizedRules()
        }

        let negatives = results
            .filter { $0.impact < 0 }
            .sorted { priority($0) > priority($1) }

        let positives = results
            .filter { $0.impact >= 0 }
            .sorted { priority($0) > priority($1) }

        return PrioritizedRules(
            primaryIssue: negatives.first,
            secondaryIssue: negatives.count > 1 ? negatives[1] : nil,
            primaryPositive: positives.first,
            allMatched: results
        )
    }

    /// Priority score = |impact| x confidence
    private static func priority(_ result: RuleResult) -> Double {
        abs(result.impact) * result.confidence
    }
}
