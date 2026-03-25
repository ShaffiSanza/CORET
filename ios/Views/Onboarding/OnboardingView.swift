import SwiftUI

struct OnboardingView: View {
    let onComplete: () -> Void
    @State private var currentStep = 0
    @State private var selectedStyle: String = "begge"
    @State private var selectedLifestyle: String = ""
    @State private var selectedTheme: AppTheme = .dark

    private let totalSteps = 4

    var body: some View {
        ZStack {
            backgroundColor.ignoresSafeArea()
                .animation(.easeInOut(duration: 0.3), value: selectedTheme)

            VStack(spacing: 0) {
                progressBar
                    .padding(.top, 16)
                    .padding(.horizontal, 24)
                    .padding(.bottom, 32)

                ScrollView(showsIndicators: false) {
                    stepContent
                        .id(currentStep)
                }

                continueButton
                    .padding(.horizontal, 24)
                    .padding(.top, 16)
                    .padding(.bottom, 48)
            }
        }
    }

    // MARK: - Progress Bar

    private var progressBar: some View {
        HStack(spacing: 6) {
            ForEach(0..<totalSteps, id: \.self) { index in
                RoundedRectangle(cornerRadius: 2)
                    .fill(index <= currentStep ? foregroundColor : foregroundColor.opacity(0.2))
                    .frame(height: 3)
                    .animation(.easeInOut(duration: 0.3), value: currentStep)
            }
        }
    }

    // MARK: - Step Content

    @ViewBuilder
    private var stepContent: some View {
        switch currentStep {
        case 0: styleStep
        case 1: lifestyleStep
        case 2: themeStep
        case 3: startStep
        default: EmptyView()
        }
    }

    // MARK: - Step 1: Style

    private var styleStep: some View {
        VStack(spacing: 24) {
            stepHeader("Hva kler du", italic: " deg i?")
            stepSubtitle("Vi tilpasser opplevelsen for deg")

            VStack(spacing: 12) {
                pillButton("Herrekl\u{00E6}r", isSelected: selectedStyle == "herre") {
                    selectedStyle = "herre"
                }
                pillButton("Damekl\u{00E6}r", isSelected: selectedStyle == "dame") {
                    selectedStyle = "dame"
                }
                pillButton("Begge", isSelected: selectedStyle == "begge") {
                    selectedStyle = "begge"
                }
            }
            .padding(.top, 8)
        }
        .padding(.horizontal, 24)
    }

    // MARK: - Step 2: Lifestyle

    private var lifestyleStep: some View {
        VStack(spacing: 24) {
            stepHeader("Hva driver du", italic: " med?")
            stepSubtitle("Hjelper oss \u{00E5} forst\u{00E5} stilen din bedre")

            LazyVGrid(columns: [
                GridItem(.flexible(), spacing: 12),
                GridItem(.flexible(), spacing: 12)
            ], spacing: 12) {
                lifestyleOption("briefcase", "Jobb / kontor")
                lifestyleOption("book", "Student")
                lifestyleOption("paintbrush.pointed", "Kreativ")
                lifestyleOption("figure.run", "Aktiv / sport")
                lifestyleOption("sparkles", "Moteinteressert")
                lifestyleOption("ellipsis.circle", "Litt av alt")
            }
            .padding(.top, 8)
        }
        .padding(.horizontal, 24)
    }

    private func lifestyleOption(_ icon: String, _ label: String) -> some View {
        let isSelected = selectedLifestyle == label
        return Button {
            selectedLifestyle = label
        } label: {
            HStack(spacing: 10) {
                Image(systemName: icon)
                    .font(.system(size: 16))
                    .frame(width: 24)
                Text(label)
                    .font(.dmSans(14, weight: .medium))
                    .lineLimit(1)
            }
            .foregroundStyle(isSelected ? backgroundColor : foregroundColor)
            .frame(maxWidth: .infinity)
            .padding(.vertical, 14)
            .padding(.horizontal, 12)
            .background(
                RoundedRectangle(cornerRadius: 12)
                    .fill(isSelected ? foregroundColor : Color.clear)
            )
            .overlay(
                RoundedRectangle(cornerRadius: 12)
                    .stroke(foregroundColor.opacity(isSelected ? 0 : 0.2), lineWidth: 1)
            )
        }
        .buttonStyle(.plain)
    }

    // MARK: - Step 3: Theme

    private var themeStep: some View {
        VStack(spacing: 24) {
            stepHeader("Velg din", italic: " stil")
            stepSubtitle("Du kan endre dette n\u{00E5}r som helst i innstillinger")

            HStack(spacing: 16) {
                themeCard(.light, label: "Lys")
                themeCard(.dark, label: "M\u{00F8}rk")
            }
            .padding(.top, 8)
        }
        .padding(.horizontal, 24)
    }

    private func themeCard(_ theme: AppTheme, label: String) -> some View {
        let isSelected = selectedTheme == theme
        let previewBg = theme == .light ? Color(hex: "FFFFFF") : Color(hex: "0A0908")
        let previewText = theme == .light ? Color(hex: "000000") : Color(hex: "EAE5DE")
        let previewGold = theme == .light ? Color(hex: "B8860B") : Color(hex: "C9A96E")

        return Button {
            selectedTheme = theme
        } label: {
            VStack(spacing: 12) {
                RoundedRectangle(cornerRadius: 12)
                    .fill(previewBg)
                    .frame(height: 120)
                    .overlay {
                        VStack(spacing: 6) {
                            Text("CORET")
                                .font(.instrumentSerif(18))
                                .foregroundStyle(previewGold)
                            RoundedRectangle(cornerRadius: 4)
                                .fill(previewText.opacity(0.1))
                                .frame(width: 60, height: 8)
                            RoundedRectangle(cornerRadius: 4)
                                .fill(previewText.opacity(0.06))
                                .frame(width: 40, height: 8)
                        }
                    }
                    .clipShape(RoundedRectangle(cornerRadius: 12))

                Text(label)
                    .font(.dmSans(14, weight: .medium))
                    .foregroundStyle(foregroundColor)
            }
            .padding(12)
            .overlay(
                RoundedRectangle(cornerRadius: 16)
                    .stroke(isSelected ? foregroundColor : foregroundColor.opacity(0.15), lineWidth: isSelected ? 2 : 1)
            )
        }
        .buttonStyle(.plain)
    }

    // MARK: - Step 4: Start

    private var startStep: some View {
        VStack(spacing: 24) {
            stepHeader("Start med", italic: " garderoben")
            stepSubtitle("Legg til dine f\u{00F8}rste plagg")

            VStack(spacing: 12) {
                infoRow("magnifyingglass", "S\u{00F8}k etter produkt", "Finn det i butikken")
                infoRow("camera", "Ta bilde", "Fotografer plagget ditt")
                infoRow("hanger", "Basics", "Vi foresl\u{00E5}r plagg du kanskje eier")
            }
            .padding(.top, 8)
        }
        .padding(.horizontal, 24)
    }

    private func infoRow(_ icon: String, _ title: String, _ subtitle: String) -> some View {
        HStack(spacing: 14) {
            Image(systemName: icon)
                .font(.system(size: 20))
                .foregroundStyle(foregroundColor.opacity(0.6))
                .frame(width: 40)
            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(.dmSans(15, weight: .medium))
                    .foregroundStyle(foregroundColor)
                Text(subtitle)
                    .font(.dmSans(12))
                    .foregroundStyle(mutedColor)
            }
            Spacer()
        }
        .padding(16)
        .overlay(
            RoundedRectangle(cornerRadius: 12)
                .stroke(foregroundColor.opacity(0.12), lineWidth: 1)
        )
    }

    // MARK: - Shared Components

    private func stepHeader(_ text: String, italic: String) -> some View {
        (Text(text)
            .font(.instrumentSerif(32))
            .foregroundStyle(foregroundColor)
        + Text(italic)
            .font(.instrumentSerifItalic(32))
            .foregroundStyle(foregroundColor))
    }

    private func stepSubtitle(_ text: String) -> some View {
        Text(text)
            .font(.dmSans(14))
            .foregroundStyle(mutedColor)
    }

    private func pillButton(_ label: String, isSelected: Bool, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            Text(label)
                .font(.dmSans(16, weight: .medium))
                .foregroundStyle(isSelected ? backgroundColor : foregroundColor)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 16)
                .background(
                    RoundedRectangle(cornerRadius: 12)
                        .fill(isSelected ? foregroundColor : Color.clear)
                )
                .overlay(
                    RoundedRectangle(cornerRadius: 12)
                        .stroke(foregroundColor.opacity(isSelected ? 0 : 0.2), lineWidth: 1)
                )
        }
        .buttonStyle(.plain)
    }

    // MARK: - Continue Button

    private var canContinue: Bool {
        switch currentStep {
        case 0: return true // style has default "begge"
        case 1: return !selectedLifestyle.isEmpty
        default: return true
        }
    }

    private var continueButton: some View {
        Button {
            if currentStep < totalSteps - 1 {
                withAnimation(.easeInOut(duration: 0.25)) {
                    currentStep += 1
                }
            } else {
                UserDefaults.standard.set(selectedTheme.rawValue, forKey: "appTheme")
                UserDefaults.standard.set(selectedStyle, forKey: "stylePreference")
                UserDefaults.standard.set(selectedLifestyle, forKey: "lifestyle")
                onComplete()
            }
        } label: {
            Text(currentStep < totalSteps - 1 ? "Fortsett" : "Kom i gang")
                .font(.dmSans(16, weight: .semibold))
                .foregroundStyle(backgroundColor)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 18)
                .background(Capsule().fill(foregroundColor.opacity(canContinue ? 1 : 0.3)))
        }
        .buttonStyle(.plain)
        .disabled(!canContinue)
    }

    // MARK: - Theme-aware colors

    private var backgroundColor: Color {
        selectedTheme == .dark ? Color(hex: "0A0908") : Color(hex: "FFFFFF")
    }

    private var foregroundColor: Color {
        selectedTheme == .dark ? Color(hex: "EAE5DE") : Color(hex: "000000")
    }

    private var mutedColor: Color {
        selectedTheme == .dark ? Color(hex: "6B625C") : Color(hex: "6B6B6B")
    }
}
