import SwiftUI

// MARK: - Color Tokens

extension Color {
    // Light theme
    static let coretBg = Color(hex: "FDFAF6")
    static let coretSurface = Color(hex: "F5F0E8")
    static let coretSurface2 = Color(hex: "EDE8DE")
    static let coretGold = Color(hex: "B8860B")
    static let coretGoldDim = Color(hex: "B8860B").opacity(0.55)
    static let coretSage = Color(hex: "5A8A5E")
    static let coretAmber = Color(hex: "C4944A")
    static let coretRed = Color(hex: "B4705A")
    static let coretText = Color(hex: "18140C")
    static let coretText2 = Color(hex: "5A5040")
    static let coretText3 = Color(hex: "8A7D68")
    static let coretText4 = Color(hex: "B0A590")

    // Dark theme
    static let coretBgDark = Color(hex: "0E0C0A")
    static let coretSurfaceDark = Color(hex: "1A1714")
    static let coretCardDark = Color(hex: "221F1A")
    static let coretBorderDark = Color(hex: "2E2A22")
    static let coretGoldDark = Color(hex: "C9A96E")
    static let coretGreenDark = Color(hex: "7A9A6E")
    static let coretTextDark = Color(hex: "EAE5DE")
    static let coretText2Dark = Color(hex: "B0A99E")
    static let coretText3Dark = Color(hex: "6B625C")
    static let coretText4Dark = Color(hex: "4A4540")

    init(hex: String) {
        let hex = hex.trimmingCharacters(in: CharacterSet.alphanumerics.inverted)
        var int: UInt64 = 0
        Scanner(string: hex).scanHexInt64(&int)
        let r, g, b: UInt64
        switch hex.count {
        case 6:
            (r, g, b) = ((int >> 16) & 0xFF, (int >> 8) & 0xFF, int & 0xFF)
        default:
            (r, g, b) = (0, 0, 0)
        }
        self.init(
            red: Double(r) / 255,
            green: Double(g) / 255,
            blue: Double(b) / 255
        )
    }
}

// MARK: - Adaptive Colors (auto light/dark)

extension Color {
    static func coretAdaptive(light: Color, dark: Color) -> Color {
        // SwiftUI will pick based on colorScheme at usage site
        light // Placeholder — use with .environment(\.colorScheme)
    }
}

// MARK: - Typography

struct CORETypography {
    // Titles: Instrument Serif (add to project fonts), fallback to serif
    static let titleFont = "InstrumentSerif-Regular"
    static let titleItalicFont = "InstrumentSerif-Italic"
    // Body: DM Sans (add to project fonts), fallback to system
    static let bodyFont = "DMSans-Regular"
    static let bodyMediumFont = "DMSans-Medium"
    static let bodySemiboldFont = "DMSans-SemiBold"
}

extension Font {
    static func instrumentSerif(_ size: CGFloat) -> Font {
        .custom(CORETypography.titleFont, size: size)
    }

    static func instrumentSerifItalic(_ size: CGFloat) -> Font {
        .custom(CORETypography.titleItalicFont, size: size)
    }

    static func dmSans(_ size: CGFloat, weight: Font.Weight = .regular) -> Font {
        switch weight {
        case .medium:
            return .custom(CORETypography.bodyMediumFont, size: size)
        case .semibold:
            return .custom(CORETypography.bodySemiboldFont, size: size)
        default:
            return .custom(CORETypography.bodyFont, size: size)
        }
    }
}

// MARK: - Design Constants

enum COREDesign {
    static let cornerRadius: CGFloat = 18
    static let cornerRadiusSmall: CGFloat = 10
    static let cardCornerRadius: CGFloat = 14
    static let spacing: CGFloat = 16
    static let horizontalPadding: CGFloat = 20

    // Animation curves
    static let springResponse: Double = 0.4
    static let springDamping: Double = 0.8
}

// MARK: - Glass Card Modifier

struct GlassCard: ViewModifier {
    @Environment(\.colorScheme) var colorScheme

    func body(content: Content) -> some View {
        content
            .background {
                if colorScheme == .dark {
                    RoundedRectangle(cornerRadius: COREDesign.cardCornerRadius)
                        .fill(.ultraThinMaterial)
                        .overlay(
                            RoundedRectangle(cornerRadius: COREDesign.cardCornerRadius)
                                .stroke(Color.white.opacity(0.06), lineWidth: 1)
                        )
                } else {
                    RoundedRectangle(cornerRadius: COREDesign.cardCornerRadius)
                        .fill(.ultraThinMaterial)
                        .overlay(
                            RoundedRectangle(cornerRadius: COREDesign.cardCornerRadius)
                                .stroke(Color.black.opacity(0.07), lineWidth: 1)
                        )
                }
            }
    }
}

extension View {
    func glassCard() -> some View {
        modifier(GlassCard())
    }
}

// MARK: - Adaptive Theme

struct CORETheme {
    let bg: Color
    let surface: Color
    let card: Color
    let border: Color
    let gold: Color
    let sage: Color
    let text: Color
    let text2: Color
    let text3: Color
    let text4: Color

    static let dark = CORETheme(
        bg: .coretBgDark,
        surface: .coretSurfaceDark,
        card: .coretCardDark,
        border: .coretBorderDark,
        gold: .coretGoldDark,
        sage: .coretGreenDark,
        text: .coretTextDark,
        text2: .coretText2Dark,
        text3: .coretText3Dark,
        text4: .coretText4Dark
    )

    static let light = CORETheme(
        bg: .coretBg,
        surface: .coretSurface,
        card: .coretSurface2,
        border: Color(hex: "E0D8CC"),
        gold: .coretGold,
        sage: .coretSage,
        text: .coretText,
        text2: .coretText2,
        text3: .coretText3,
        text4: .coretText4
    )
}

// MARK: - Theme Environment Key

private struct ThemeKey: EnvironmentKey {
    static let defaultValue = CORETheme.dark
}

extension EnvironmentValues {
    var theme: CORETheme {
        get { self[ThemeKey.self] }
        set { self[ThemeKey.self] = newValue }
    }
}
