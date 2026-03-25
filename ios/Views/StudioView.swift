import SwiftUI
import COREEngine

struct StudioView: View {
    @Bindable var viewModel: StudioViewModel
    @Environment(\.theme) private var theme
    @State private var drawerDragOffset: CGFloat = 0
    @State private var showWearConfirmation = false

    var body: some View {
        ZStack(alignment: .trailing) {
            ScrollView {
                VStack(spacing: COREDesign.spacing) {
                    scoreHeader
                    flatLayCanvas
                    scoreBreakdown
                    actionButtons
                }
                .padding(.horizontal, COREDesign.horizontalPadding)
                .padding(.top, 12)
                .padding(.bottom, 100)
            }
            .background(theme.bg)
            .scrollDisabled(viewModel.isDrawerOpen)

            // Edge swipe to open drawer
            if !viewModel.isDrawerOpen {
                Color.clear
                    .frame(width: 20)
                    .frame(maxHeight: .infinity)
                    .contentShape(Rectangle())
                    .gesture(
                        DragGesture()
                            .onEnded { value in
                                if value.translation.width < -50 {
                                    withAnimation(.spring(response: 0.4, dampingFraction: 0.8)) {
                                        viewModel.isDrawerOpen = true
                                    }
                                }
                            }
                    )
                    .frame(maxWidth: .infinity, alignment: .trailing)
            }

            // Accessory drawer
            if viewModel.isDrawerOpen {
                accessoryDrawer
                    .transition(.move(edge: .trailing))
            }
        }
        .animation(.spring(response: COREDesign.springResponse, dampingFraction: COREDesign.springDamping), value: viewModel.isDrawerOpen)
        .alert("Antrekk logget!", isPresented: $showWearConfirmation) {
            Button("OK") { }
        } message: {
            Text("Dagens antrekk er registrert.")
        }
    }

    // MARK: - Score Header

    @ViewBuilder
    private var scoreHeader: some View {
        if !viewModel.currentOutfitGarments.isEmpty {
            HStack {
                Text(viewModel.archetypeMatch.rawValue.capitalized)
                    .font(.dmSans(13, weight: .medium))
                    .foregroundStyle(theme.gold)
                    .padding(.horizontal, 14)
                    .padding(.vertical, 7)
                    .background(Capsule().fill(theme.gold.opacity(0.12)))
                Spacer()
            }
            .padding(.horizontal, 4)
        }
    }

    // MARK: - Flat Lay Canvas

    @ViewBuilder
    private var flatLayCanvas: some View {
        VStack(spacing: 10) {
            slotRow(label: "Ytterlag", garment: viewModel.outerLayer, category: .upper)
            slotRow(label: "Topp", garment: viewModel.topLayer, category: .upper)
            slotRow(label: "Bunn", garment: viewModel.bottomLayer, category: .lower)
            slotRow(label: "Sko", garment: viewModel.shoes, category: .shoes)

            // Accessories toggle
            HStack {
                Text("Tilbeh\u{00F8}r")
                    .font(.dmSans(13, weight: .medium))
                    .foregroundStyle(theme.text2)
                Spacer()
                Button {
                    viewModel.isDrawerOpen.toggle()
                } label: {
                    HStack(spacing: 4) {
                        Text("\(viewModel.selectedAccessories.count)")
                            .font(.dmSans(12))
                        Image(systemName: "chevron.right")
                            .font(.system(size: 10))
                    }
                    .foregroundStyle(theme.gold)
                    .frame(minWidth: 44, minHeight: 44)
                    .contentShape(Rectangle())
                }
                .accessibilityLabel("Tilbeh\u{00F8}r, \(viewModel.selectedAccessories.count) valgt")
            }
            .padding(.horizontal, 14)
            .padding(.vertical, 12)
            .background {
                RoundedRectangle(cornerRadius: COREDesign.cornerRadiusSmall)
                    .fill(theme.surface)
            }
        }
    }

    @State private var pressedSlot: Category?

    @ViewBuilder
    private func slotRow(label: String, garment: Garment?, category: Category) -> some View {
        Menu {
            let available = garmentList(for: category)
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
            HStack {
                // Color swatch instead of emoji
                if let garment {
                    RoundedRectangle(cornerRadius: 4)
                        .fill(slotColor(garment))
                        .frame(width: 24, height: 28)
                }

                Text(label)
                    .font(.dmSans(13, weight: .medium))
                    .foregroundStyle(theme.text2)
                Spacer()
                if let garment {
                    Text(garment.name.isEmpty ? garment.baseGroup.rawValue.capitalized : garment.name)
                        .font(.dmSans(13))
                        .foregroundStyle(theme.text)
                } else {
                    Text("Velg...")
                        .font(.dmSans(13))
                        .foregroundStyle(theme.text4)
                }
            }
            .padding(.horizontal, 14)
            .padding(.vertical, 12)
            .background {
                RoundedRectangle(cornerRadius: COREDesign.cornerRadiusSmall)
                    .fill(garment != nil ? theme.surface : theme.bg)
                    .overlay(
                        RoundedRectangle(cornerRadius: COREDesign.cornerRadiusSmall)
                            .strokeBorder(
                                garment != nil ? Color.clear : theme.border.opacity(0.5),
                                style: garment != nil ? StrokeStyle() : StrokeStyle(lineWidth: 1, dash: [6])
                            )
                    )
            }
        }
        .scaleEffect(pressedSlot == category ? 0.96 : 1.0)
        .animation(.spring(response: 0.4, dampingFraction: 0.8), value: pressedSlot)
        .onLongPressGesture(minimumDuration: .infinity, pressing: { pressing in
            pressedSlot = pressing ? category : nil
        }, perform: {})
        .accessibilityLabel("\(label): \(garment.map { $0.name.isEmpty ? $0.baseGroup.rawValue.capitalized : $0.name } ?? "Ikke valgt")")
    }

    private func slotColor(_ garment: Garment) -> Color {
        let hex = garment.dominantColor
        guard !hex.isEmpty, hex != "#000000" else { return theme.surface }
        return Color(hex: String(hex.dropFirst()))
    }

    private func garmentList(for category: Category) -> [Garment] {
        switch category {
        case .upper: viewModel.availableUppers
        case .lower: viewModel.availableLowers
        case .shoes: viewModel.availableShoes
        case .accessory: viewModel.availableAccessories
        }
    }

    // MARK: - Score Breakdown (Bars + Fashion Intelligence)

    @ViewBuilder
    private var scoreBreakdown: some View {
        if let score = viewModel.outfitScore {
            VStack(alignment: .leading, spacing: 14) {
                // Strength bars
                strengthBar(label: "Flyt", verdict: viewModel.silhouetteVerdict, value: verdictValue(viewModel.silhouetteVerdict))
                strengthBar(label: "Farger", verdict: viewModel.colorVerdict, value: verdictValue(viewModel.colorVerdict))
                strengthBar(label: "Balanse", verdict: viewModel.archetypeMatch.rawValue.capitalized, value: viewModel.totalStrength)

                // Fashion Intelligence feedback
                if let explanation = score.explanation {
                    Divider().opacity(0.3)

                    // Positives
                    if !explanation.positives.isEmpty {
                        ForEach(explanation.positives.prefix(3), id: \.self) { positive in
                            HStack(alignment: .top, spacing: 8) {
                                Image(systemName: "checkmark.circle.fill")
                                    .font(.system(size: 11))
                                    .foregroundStyle(theme.sage)
                                Text(positive)
                                    .font(.dmSans(12))
                                    .foregroundStyle(theme.text2)
                            }
                        }
                    }

                    // Fix suggestion
                    if let fix = explanation.fix {
                        HStack(alignment: .top, spacing: 8) {
                            Image(systemName: "lightbulb.fill")
                                .font(.system(size: 11))
                                .foregroundStyle(theme.gold)
                            Text(fix)
                                .font(.dmSans(12))
                                .foregroundStyle(theme.text3)
                        }
                    }
                }
            }
            .padding(COREDesign.spacing)
            .glassCard()
        }
    }

    @ViewBuilder
    private func strengthBar(label: String, verdict: String, value: Double) -> some View {
        VStack(alignment: .leading, spacing: 5) {
            HStack {
                Text(label)
                    .font(.dmSans(11, weight: .medium))
                    .foregroundStyle(theme.text3)
                    .frame(width: 52, alignment: .leading)
                Spacer()
                Text(verdict)
                    .font(.dmSans(11))
                    .foregroundStyle(barColor(value))
            }
            GeometryReader { geo in
                ZStack(alignment: .leading) {
                    RoundedRectangle(cornerRadius: 2)
                        .fill(theme.surface)
                    RoundedRectangle(cornerRadius: 2)
                        .fill(barColor(value))
                        .frame(width: geo.size.width * min(max(value, 0), 1))
                        .animation(.spring(response: 0.5, dampingFraction: 0.8), value: value)
                }
            }
            .frame(height: 4)
        }
    }

    private func barColor(_ value: Double) -> Color {
        if value >= 0.7 { return theme.sage }
        if value >= 0.4 { return theme.gold }
        return Color.coretRed
    }

    private func verdictValue(_ verdict: String) -> Double {
        switch verdict.lowercased() {
        case "strong", "sterk", "harmonious": 0.9
        case "balanced", "good", "god": 0.75
        case "neutral": 0.5
        case "weak", "svak", "uniform": 0.3
        case "poor", "d\u{00E5}rlig", "clash": 0.15
        default: 0.5
        }
    }

    // MARK: - Action Buttons

    @ViewBuilder
    private var actionButtons: some View {
        HStack(spacing: 12) {
            // Surprise (secondary)
            Button {
                viewModel.generateSurpriseOutfit()
            } label: {
                HStack(spacing: 6) {
                    Image(systemName: "dice")
                    Text("Overrask meg")
                }
                .font(.dmSans(14, weight: .medium))
                .foregroundStyle(theme.gold)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 14)
                .background {
                    RoundedRectangle(cornerRadius: COREDesign.cornerRadiusSmall)
                        .fill(theme.surface)
                }
            }
            .accessibilityLabel("Overrask meg med et tilfeldig antrekk")

            // Wear today (primary)
            Button {
                Task {
                    await viewModel.wearToday()
                    showWearConfirmation = true
                }
            } label: {
                HStack(spacing: 6) {
                    Image(systemName: "checkmark")
                    Text("Bruk i dag")
                }
                .font(.dmSans(14, weight: .medium))
                .foregroundStyle(theme.bg)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 14)
                .background {
                    RoundedRectangle(cornerRadius: COREDesign.cornerRadiusSmall)
                        .fill(theme.gold)
                }
            }
            .disabled(viewModel.currentOutfitGarments.isEmpty)
            .opacity(viewModel.currentOutfitGarments.isEmpty ? 0.5 : 1)
            .accessibilityLabel("Bruk dette antrekket i dag")
        }
    }

    // MARK: - Accessory Drawer

    @ViewBuilder
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
                        .contentShape(Rectangle())
                }
                .accessibilityLabel("Lukk tilbeh\u{00F8}r")
            }

            ScrollView {
                VStack(spacing: 8) {
                    ForEach(viewModel.availableAccessories) { accessory in
                        let isSelected = viewModel.selectedAccessories.contains(where: { $0.id == accessory.id })
                        Button {
                            viewModel.toggleAccessory(accessory)
                        } label: {
                            HStack {
                                RoundedRectangle(cornerRadius: 4)
                                    .fill(accessoryColor(accessory))
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
                            .background {
                                RoundedRectangle(cornerRadius: 8)
                                    .fill(isSelected ? theme.gold.opacity(0.1) : theme.surface)
                            }
                        }
                        .accessibilityLabel("\(accessory.name.isEmpty ? accessory.baseGroup.rawValue.capitalized : accessory.name)\(isSelected ? ", valgt" : "")")
                    }
                }
            }
        }
        .padding(16)
        .frame(width: 220)
        .background {
            RoundedRectangle(cornerRadius: COREDesign.cornerRadius)
                .fill(.ultraThinMaterial)
        }
        .padding(.trailing, 8)
    }

    private func accessoryColor(_ garment: Garment) -> Color {
        let hex = garment.dominantColor
        guard !hex.isEmpty, hex != "#000000" else { return theme.surface }
        return Color(hex: String(hex.dropFirst()))
    }
}
