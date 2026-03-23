import Foundation

/// Loads i18n JSON files and resolves templates with variable injection.
/// Fallback chain: locale → "en" → message_key as-is (never crashes).
public enum I18nEngine: Sendable {

    // MARK: - i18n Bundle Model

    private struct I18nBundle: Codable, Sendable {
        let variables: [String: String]
        let fallback: String
        let messages: [String: MessageTemplate]
    }

    private struct MessageTemplate: Codable, Sendable {
        let headline: String?
        let fix: String?
        let positive: String?
    }

    // MARK: - Loading

    /// Load an i18n bundle for a locale from the module bundle.
    private static func loadBundle(locale: String) -> I18nBundle? {
        guard let url = Bundle.module.url(forResource: locale, withExtension: "json", subdirectory: "i18n"),
              let data = try? Data(contentsOf: url),
              let bundle = try? JSONDecoder().decode(I18nBundle.self, from: data)
        else { return nil }
        return bundle
    }

    /// Load an i18n bundle from raw data (for testing).
    public static func loadBundle(from data: Data) -> Bool {
        (try? JSONDecoder().decode(I18nBundle.self, from: data)) != nil
    }

    // MARK: - Resolution

    /// Resolve a message for a given key, locale, and variables.
    /// Fallback: locale → "en" → safe generic string.
    public static func resolve(
        messageKey: String,
        locale: String,
        variables: [String: String] = [:]
    ) -> (headline: String?, fix: String?, positive: String?) {
        // Try requested locale
        if let bundle = loadBundle(locale: locale),
           let template = bundle.messages[messageKey] {
            return (
                headline: inject(template.headline, variables: variables, bundle: bundle),
                fix: inject(template.fix, variables: variables, bundle: bundle),
                positive: template.positive
            )
        }

        // Fallback to English
        if locale != "en",
           let bundle = loadBundle(locale: "en"),
           let template = bundle.messages[messageKey] {
            return (
                headline: inject(template.headline, variables: variables, bundle: bundle),
                fix: inject(template.fix, variables: variables, bundle: bundle),
                positive: template.positive
            )
        }

        // Ultimate fallback — safe generic string
        let fallbackText = loadBundle(locale: locale)?.fallback
            ?? loadBundle(locale: "en")?.fallback
            ?? messageKey
        return (headline: fallbackText, fix: nil, positive: nil)
    }

    /// Resolve a variable value for a locale.
    public static func resolveVariable(_ key: String, locale: String) -> String {
        if let bundle = loadBundle(locale: locale), let value = bundle.variables[key] {
            return value
        }
        if locale != "en", let bundle = loadBundle(locale: "en"), let value = bundle.variables[key] {
            return value
        }
        return key // ultimate fallback: return the key itself
    }

    // MARK: - Template Injection

    /// Inject {variable} placeholders in a template string.
    private static func inject(_ template: String?, variables: [String: String], bundle: I18nBundle) -> String? {
        guard var text = template else { return nil }
        for (key, rawValue) in variables {
            // Resolve variable value through i18n bundle
            let localizedValue = bundle.variables[rawValue] ?? rawValue
            text = text.replacingOccurrences(of: "{\(key)}", with: localizedValue)
        }
        return text
    }
}
