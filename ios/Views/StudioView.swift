import SwiftUI
import COREEngine

struct StudioView: View {
    @Bindable var viewModel: StudioViewModel
    @Environment(\.theme) private var theme
    @State private var showWearConfirmation = false

    var body: some View {
        ZStack(alignment: .trailing) {
            ScrollView {
                VStack(spacing: 0) {
                    topBar
                    editorialCanvas
                    scoreBand
                    scoreBreakdown
                        .padding(.horizontal, COREDesign.horizontalPadding)
                        .padding(.top, 12)
                    actionButtons
                        .padding(.horizontal, COREDesign.horizontalPadding)
                        .padding(.top, 12)
                        .padding(.bottom, 100)
                }
            }
            .background(theme.bg)
            .scrollDisabled(viewModel.isDrawerOpen)

            if viewModel.isDrawerOpen {
                accessoryDrawer
                    .transition(.move(edge: .trailing))
            }
        }
        .animation(.spring(response: 0.4, dampingFraction: 0.8), value: viewModel.isDrawerOpen)
        .alert("Antrekk logget!", isPresented: $showWearConfirmation) {
            Button("OK") { }
        } message: {
            Text("Dagens antrekk er registrert.")
        }
    }

    // MARK: - Top Bar

    private var topBar: some View {
        HStack {
            // Score
            HStack(alignment: .firstTextBaseline, spacing: 5) {
                Text("\(viewModel.scoreDisplay)")
                    .font(.instrumentSerif(30))
                    .foregroundStyle(theme.text)
                    .contentTransition(.numericText())
                if viewModel.scoreDisplay > 0 {
                    Text("\u{2191} +\(viewModel.scoreDisplay)")
                        .font(.dmSans(10, weight: .medium))
                        .foregroundStyle(theme.sage)
                }
            }

            Spacer()

            // Actions
            HStack(spacing: 6) {
                Button {
                    viewModel.isDrawerOpen.toggle()
                } label: {
                    Image(systemName: "plus.circle")
                        .font(.system(size: 16))
                        .foregroundStyle(theme.text3)
                        .frame(width: 36, height: 36)
                        .background(theme.surface.opacity(0.6))
                        .clipShape(Circle())
                }

                Button {
                    viewModel.generateSurpriseOutfit()
                } label: {
                    HStack(spacing: 4) {
                        Image(systemName: "sparkles")
                            .font(.system(size: 11))
                        Text("Surprise")
                            .font(.dmSans(11, weight: .medium))
                    }
                    .foregroundStyle(theme.gold)
                    .padding(.horizontal, 12)
                    .padding(.vertical, 8)
                    .background(theme.gold.opacity(0.1))
                    .clipShape(Capsule())
                    .overlay(Capsule().stroke(theme.gold.opacity(0.2), lineWidth: 1))
                }
            }
        }
        .padding(.horizontal, COREDesign.horizontalPadding)
        .padding(.vertical, 12)
    }

    // MARK: - Editorial Canvas

    private var editorialCanvas: some View {
        let canvasHeight: CGFloat = 420

        return ZStack {
            // Subtle atmosphere gradient
            RadialGradient(
                colors: [theme.gold.opacity(0.04), Color.clear],
                center: .init(x: 0.5, y: 0.4),
                startRadius: 0,
                endRadius: 200
            )

            // Garment layers — overlapping editorial layout
            garmentStack

            // Swipe chips (right side)
            swipeChips

            // Accessory pills (bottom)
            accessoryPills
        }
        .frame(height: canvasHeight)
        .background(theme.surface.opacity(0.3))
        .clipShape(RoundedRectangle(cornerRadius: 4))
    }

    // MARK: - Garment Stack

    @ViewBuilder
    private var garmentStack: some View {
        GeometryReader { geo in
            let w = geo.size.width
            let h = geo.size.height

            // Outer layer (jacket/coat) — top, slightly rotated
            garmentCard(viewModel.outerLayer, category: .upper, isOuter: true)
                .frame(width: w * 0.52, height: h * 0.32)
                .position(x: w * 0.48, y: h * 0.14)
                .rotationEffect(.degrees(-3))
                .zIndex(4)

            // Top (tee/shirt) — visible under jacket
            garmentCard(viewModel.topLayer, category: .upper, isOuter: false)
                .frame(width: w * 0.42, height: h * 0.24)
                .position(x: w * 0.48, y: h * 0.34)
                .rotationEffect(.degrees(1.5))
                .zIndex(3)

            // Bottom (jeans/trousers)
            garmentCard(viewModel.bottomLayer, category: .lower, isOuter: false)
                .frame(width: w * 0.44, height: h * 0.32)
                .position(x: w * 0.46, y: h * 0.58)
                .rotationEffect(.degrees(-1))
                .zIndex(2)

            // Shoes — bottom
            garmentCard(viewModel.shoes, category: .shoes, isOuter: false)
                .frame(width: w * 0.38, height: h * 0.16)
                .position(x: w * 0.48, y: h * 0.82)
                .rotationEffect(.degrees(2))
                .zIndex(3)
        }
    }

    @ViewBuilder
    private func garmentCard(_ garment: Garment?, category: Category, isOuter: Bool) -> some View {
        Menu {
            let available = garmentList(for: category, isOuter: isOuter)
            ForEach(available) { item in
                Button(item.name.isEmpty ? item.baseGroup.rawValue.capitalized : item.name) {
                    viewModel.setSlot(item)
                }
            }
            if garment != nil {
                Divider()
                Button("Fjern", role: .destructive) {
                    viewModel.clearSlot(category: category)
                }
            }
        } label: {
            if let garment, !garment.image.isEmpty, let url = URL(string: garment.image) {
                AsyncImage(url: url) { phase in
                    switch phase {
                    case .success(let img):
                        img.resizable()
                            .scaledToFit()
                            .shadow(color: .black.opacity(0.25), radius: 12, y: 6)
                    default:
                        garmentPlaceholder(garment)
                    }
                }
            } else if let garment {
                garmentPlaceholder(garment)
            } else {
                emptySlot
            }
        }
    }

    private func garmentPlaceholder(_ garment: Garment) -> some View {
        RoundedRectangle(cornerRadius: 10)
            .fill(Color(hex: String(garment.dominantColor.dropFirst())))
            .shadow(color: .black.opacity(0.2), radius: 8, y: 4)
    }

    private var emptySlot: some View {
        RoundedRectangle(cornerRadius: 10)
            .strokeBorder(theme.border.opacity(0.4), style: StrokeStyle(lineWidth: 1.5, dash: [8]))
            .background(theme.surface.opacity(0.15))
            .clipShape(RoundedRectangle(cornerRadius: 10))
    }

    private func garmentList(for category: Category, isOuter: Bool) -> [Garment] {
        switch category {
        case .upper:
            if isOuter {
                return viewModel.availableUppers.filter { $0.baseGroup == .coat || $0.baseGroup == .blazer }
            }
            return viewModel.availableUppers.filter { $0.baseGroup != .coat && $0.baseGroup != .blazer }
        case .lower: return viewModel.availableLowers
        case .shoes: return viewModel.availableShoes
        case .accessory: return viewModel.availableAccessories
        }
    }

    // MARK: - Swipe Chips

    private var swipeChips: some View {
        VStack(alignment: .trailing, spacing: 46) {
            chipLabel("Ytterlag", hasGarment: viewModel.outerLayer != nil)
            chipLabel("Overdel", hasGarment: viewModel.topLayer != nil)
            chipLabel("Underdel", hasGarment: viewModel.bottomLayer != nil)
            chipLabel("Sko", hasGarment: viewModel.shoes != nil)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topTrailing)
        .padding(.top, 28)
        .padding(.trailing, 10)
    }

    private func chipLabel(_ label: String, hasGarment: Bool) -> some View {
        HStack(spacing: 4) {
            Circle()
                .fill(hasGarment ? theme.gold : theme.text4)
                .frame(width: 5, height: 5)
            Text(label)
                .font(.dmSans(9, weight: .medium))
            Text("\u{2195}")
                .font(.system(size: 8))
                .opacity(0.5)
        }
        .foregroundStyle(hasGarment ? theme.gold : theme.text4)
        .padding(.horizontal, 8)
        .padding(.vertical, 4)
        .background(.ultraThinMaterial)
        .clipShape(Capsule())
    }

    // MARK: - Accessory Pills

    private var accessoryPills: some View {
        HStack(spacing: 6) {
            ForEach(viewModel.selectedAccessories.prefix(3)) { acc in
                HStack(spacing: 3) {
                    Circle()
                        .fill(theme.gold)
                        .frame(width: 4, height: 4)
                    Text(acc.baseGroup.rawValue.capitalized)
                        .font(.dmSans(8, weight: .medium))
                }
                .foregroundStyle(theme.gold)
                .padding(.horizontal, 8)
                .padding(.vertical, 4)
                .background(theme.gold.opacity(0.1))
                .clipShape(Capsule())
                .overlay(Capsule().stroke(theme.gold.opacity(0.2), lineWidth: 1))
            }

            Button {
                viewModel.isDrawerOpen = true
            } label: {
                Text("+ Legg til")
                    .font(.dmSans(8, weight: .medium))
                    .foregroundStyle(theme.text4)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 4)
                    .background(.ultraThinMaterial)
                    .clipShape(Capsule())
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .bottom)
        .padding(.bottom, 10)
    }

    // MARK: - Score Band

    @ViewBuilder
    private var scoreBand: some View {
        if let score = viewModel.outfitScore, let explanation = score.explanation {
            HStack {
                // FI quote
                if let firstPositive = explanation.positives.first {
                    Text("\u{201C}\(firstPositive)\u{201D}")
                        .font(.instrumentSerifItalic(12))
                        .foregroundStyle(theme.text)
                        .lineLimit(1)
                }
                Spacer()
                Text(viewModel.archetypeMatch.rawValue.capitalized)
                    .font(.dmSans(9, weight: .medium))
                    .foregroundStyle(theme.sage)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 3)
                    .background(theme.sage.opacity(0.1))
                    .clipShape(RoundedRectangle(cornerRadius: 4))
                    .overlay(RoundedRectangle(cornerRadius: 4).stroke(theme.sage.opacity(0.15), lineWidth: 1))
            }
            .padding(.horizontal, COREDesign.horizontalPadding)
            .padding(.vertical, 10)
            .background(theme.surface.opacity(0.4))
        }
    }

    // MARK: - Score Breakdown

    @ViewBuilder
    private var scoreBreakdown: some View {
        if viewModel.outfitScore != nil {
            VStack(spacing: 6) {
                strengthBar(label: "Flyt", value: verdictValue(viewModel.silhouetteVerdict))
                strengthBar(label: "Farger", value: verdictValue(viewModel.colorVerdict))
            }
            .padding(14)
            .glassCard()
        }
    }

    private func strengthBar(label: String, value: Double) -> some View {
        HStack(spacing: 8) {
            Text(label)
                .font(.dmSans(10, weight: .medium))
                .foregroundStyle(theme.text3)
                .frame(width: 42, alignment: .leading)
            GeometryReader { geo in
                ZStack(alignment: .leading) {
                    RoundedRectangle(cornerRadius: 1.5)
                        .fill(theme.surface)
                    RoundedRectangle(cornerRadius: 1.5)
                        .fill(barColor(value))
                        .frame(width: geo.size.width * min(max(value, 0), 1))
                        .animation(.spring(response: 0.5, dampingFraction: 0.8), value: value)
                }
            }
            .frame(height: 3)
            Text("\(Int(value * 100))")
                .font(.dmSans(10))
                .foregroundStyle(theme.text3)
                .frame(width: 22, alignment: .trailing)
        }
    }

    private func barColor(_ value: Double) -> Color {
        if value >= 0.7 { return theme.sage }
        if value >= 0.4 { return theme.gold }
        return Color.coretRed
    }

    private func verdictValue(_ verdict: String) -> Double {
        switch verdict.lowercased() {
        case "strong", "sterk", "harmonious": 0.92
        case "balanced", "good", "god": 0.75
        case "neutral": 0.5
        case "weak", "svak", "uniform": 0.3
        case "poor", "d\u{00E5}rlig", "clash": 0.15
        default: 0.5
        }
    }

    // MARK: - Action Buttons

    private var actionButtons: some View {
        HStack(spacing: 10) {
            Button {
                viewModel.generateSurpriseOutfit()
            } label: {
                HStack(spacing: 6) {
                    Image(systemName: "circle.circle")
                        .font(.system(size: 12))
                    Text("Overrask")
                        .font(.dmSans(13, weight: .medium))
                }
                .foregroundStyle(theme.text2)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 13)
                .background(theme.surface)
                .clipShape(RoundedRectangle(cornerRadius: COREDesign.cornerRadiusSmall))
            }

            Button {
                Task {
                    await viewModel.wearToday()
                    showWearConfirmation = true
                }
            } label: {
                HStack(spacing: 6) {
                    Image(systemName: "checkmark")
                        .font(.system(size: 12))
                    Text("Bruk i dag \u{2192}")
                        .font(.dmSans(13, weight: .medium))
                }
                .foregroundStyle(theme.bg)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 13)
                .background(theme.gold)
                .clipShape(RoundedRectangle(cornerRadius: COREDesign.cornerRadiusSmall))
            }
            .disabled(viewModel.currentOutfitGarments.isEmpty)
            .opacity(viewModel.currentOutfitGarments.isEmpty ? 0.5 : 1)
        }
    }

    // MARK: - Accessory Drawer

    private var accessoryDrawer: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text("Tilbeh\u{00F8}r")
                    .font(.instrumentSerif(18))
                    .foregroundStyle(theme.text)
                Spacer()
                Button { viewModel.isDrawerOpen = false } label: {
                    Image(systemName: "xmark")
                        .foregroundStyle(theme.text3)
                        .frame(width: 44, height: 44)
                }
            }

            ScrollView {
                VStack(spacing: 8) {
                    ForEach(viewModel.availableAccessories) { accessory in
                        let isSelected = viewModel.selectedAccessories.contains(where: { $0.id == accessory.id })
                        Button { viewModel.toggleAccessory(accessory) } label: {
                            HStack {
                                RoundedRectangle(cornerRadius: 4)
                                    .fill(accColor(accessory))
                                    .frame(width: 20, height: 24)
                                Text(accessory.name.isEmpty ? accessory.baseGroup.rawValue.capitalized : accessory.name)
                                    .font(.dmSans(13))
                                    .foregroundStyle(theme.text)
                                Spacer()
                                if isSelected {
                                    Image(systemName: "checkmark.circle.fill")
                                        .foregroundStyle(theme.gold)
                                }
                            }
                            .padding(10)
                            .background(RoundedRectangle(cornerRadius: 8).fill(isSelected ? theme.gold.opacity(0.1) : theme.surface))
                        }
                    }
                }
            }
        }
        .padding(16)
        .frame(width: 220)
        .background(RoundedRectangle(cornerRadius: COREDesign.cornerRadius).fill(.ultraThinMaterial))
        .padding(.trailing, 8)
    }

    private func accColor(_ garment: Garment) -> Color {
        let hex = garment.dominantColor
        guard !hex.isEmpty, hex != "#000000" else { return theme.surface }
        return Color(hex: String(hex.dropFirst()))
    }
}
