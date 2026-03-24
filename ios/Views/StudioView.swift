import SwiftUI
import COREEngine

struct StudioView: View {
    @Bindable var viewModel: StudioViewModel
    @Environment(\.theme) private var theme
    @State private var drawerDragOffset: CGFloat = 0

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
    }

    // MARK: - Score Header

    @ViewBuilder
    private var scoreHeader: some View {
        VStack(spacing: 8) {
            Text("\(viewModel.scoreDisplay)")
                .font(.instrumentSerif(64))
                .foregroundStyle(viewModel.totalStrength > 0.7 ? theme.gold : theme.text)
                .contentTransition(.numericText())
                .animation(.spring(response: 0.4, dampingFraction: 0.8), value: viewModel.scoreDisplay)

            if let explanation = viewModel.explanation {
                Text(explanation.headline)
                    .font(.dmSans(13))
                    .foregroundStyle(theme.text2)
                    .multilineTextAlignment(.center)
            }

            // Archetype pill
            Text(viewModel.archetypeMatch.rawValue.capitalized)
                .font(.dmSans(11, weight: .medium))
                .foregroundStyle(theme.gold)
                .padding(.horizontal, 12)
                .padding(.vertical, 5)
                .background(Capsule().fill(theme.gold.opacity(0.12)))
        }
        .frame(maxWidth: .infinity)
        .padding(COREDesign.spacing)
        .glassCard()
        .accessibilityElement(children: .combine)
        .accessibilityLabel("Antrekkscore \(viewModel.scoreDisplay) av 100")
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

    // MARK: - Score Breakdown

    @ViewBuilder
    private var scoreBreakdown: some View {
        if viewModel.outfitScore != nil {
            VStack(alignment: .leading, spacing: 10) {
                scoreBar(label: "Flyt", verdict: viewModel.silhouetteVerdict)
                scoreBar(label: "Farger", verdict: viewModel.colorVerdict)
            }
            .padding(COREDesign.spacing)
            .glassCard()
        }
    }

    @ViewBuilder
    private func scoreBar(label: String, verdict: String) -> some View {
        HStack {
            Text(label)
                .font(.dmSans(13, weight: .medium))
                .foregroundStyle(theme.text2)
                .frame(width: 60, alignment: .leading)
            Text(verdict)
                .font(.dmSans(13))
                .foregroundStyle(verdictColor(verdict))
            Spacer()
        }
    }

    private func verdictColor(_ verdict: String) -> Color {
        switch verdict.lowercased() {
        case "sterk", "strong", "god", "good": theme.sage
        case "svak", "weak", "d\u{00E5}rlig", "poor": Color.coretRed
        default: theme.text3
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
                Task { await viewModel.wearToday() }
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
