import Foundation

/// Generates human-readable explanations from prioritized rules using I18nEngine.
/// Sounds like a stylist talking to the user, not a calculator.
public enum ExplanationEngine: Sendable {

    /// Generate explanation from prioritized rules.
    /// Uses I18nEngine to resolve templates in the requested locale.
    public static func explain(
        prioritized: PrioritizedRules,
        score: Double,
        archetype: Archetype,
        locale: String = "en"
    ) -> ExplanationResult {
        // Collect positives from matched rules
        let positives: [String] = prioritized.allMatched
            .filter { $0.messageType == "positive" }
            .prefix(3)
            .compactMap { rule in
                let resolved = I18nEngine.resolve(messageKey: rule.messageKey, locale: locale, variables: rule.variables)
                return resolved.positive
            }

        // No issues — pure positive
        guard let primary = prioritized.primaryIssue else {
            let headline = positives.first ?? fallbackHeadline(score: score, locale: locale)
            return ExplanationResult(
                headline: headline,
                detail: nil,
                fix: nil,
                positives: positives
            )
        }

        // Has primary issue — resolve headline + fix
        let primaryResolved = I18nEngine.resolve(messageKey: primary.messageKey, locale: locale, variables: primary.variables)
        let headline = primaryResolved.headline ?? primary.messageKey

        var detail: String? = nil
        if let secondary = prioritized.secondaryIssue {
            let secondaryResolved = I18nEngine.resolve(messageKey: secondary.messageKey, locale: locale, variables: secondary.variables)
            detail = secondaryResolved.headline
        }

        let fix = primaryResolved.fix

        return ExplanationResult(
            headline: headline,
            detail: detail,
            fix: fix,
            positives: positives
        )
    }

    private static func fallbackHeadline(score: Double, locale: String) -> String {
        if locale == "no" {
            if score >= 0.85 { return "Sterk outfit — alt henger sammen." }
            if score >= 0.70 { return "Solid kombinasjon med god balanse." }
            return "En god start — rom for finjustering."
        }
        // English (default)
        if score >= 0.85 { return "Strong outfit — everything connects." }
        if score >= 0.70 { return "Solid combination with good balance." }
        return "A good start — room for fine-tuning."
    }
}
