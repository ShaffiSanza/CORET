import SwiftUI
import COREEngine

struct StudioView: View {
    @Bindable var viewModel: StudioViewModel
    @Environment(\.theme) private var theme

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
    }

    // MARK: - Flat Lay Canvas

    @ViewBuilder
    private var flatLayCanvas: some View {
        VStack(spacing: 12) {
            Text("Flat Lay")
                .font(.instrumentSerif(20))
                .foregroundStyle(theme.text)
                .frame(maxWidth: .infinity, alignment: .leading)

            // Slots
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
                    }
                }
                .padding(.horizontal, 14)
                .padding(.vertical, 12)
                .background {
                    RoundedRectangle(cornerRadius: COREDesign.cornerRadiusSmall)
                        .fill(theme.surface)
                }
            }
        }
    }

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
                Text(label)
                    .font(.dmSans(13, weight: .medium))
                    .foregroundStyle(theme.text2)
                Spacer()
                if let garment {
                    Text(garment.name ?? garment.baseGroup.rawValue.capitalized)
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
        case "svak", "weak", "dårlig", "poor": Color.coretRed
        default: theme.text3
        }
    }

    // MARK: - Action Buttons

    @ViewBuilder
    private var actionButtons: some View {
        HStack(spacing: 12) {
            // Surprise
            Button {
                viewModel.generateSurpriseOutfit()
            } label: {
                HStack(spacing: 6) {
                    Image(systemName: "dice")
                    Text("Overrask meg")
                }
                .font(.dmSans(14, weight: .medium))
                .foregroundStyle(theme.text)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 14)
                .background {
                    RoundedRectangle(cornerRadius: COREDesign.cornerRadiusSmall)
                        .fill(theme.surface)
                }
            }

            // Wear today
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
                }
            }

            ScrollView {
                VStack(spacing: 8) {
                    ForEach(viewModel.availableAccessories) { accessory in
                        let isSelected = viewModel.selectedAccessories.contains(where: { $0.id == accessory.id })
                        Button {
                            viewModel.toggleAccessory(accessory)
                        } label: {
                            HStack {
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
}
