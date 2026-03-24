import SwiftUI
import COREEngine

struct WardrobeView: View {
    @Bindable var viewModel: WardrobeViewModel
    @Environment(\.theme) private var theme
    @State private var showAddSheet = false
    @State private var selectedGarment: Garment?

    var body: some View {
        ScrollView {
            VStack(spacing: COREDesign.spacing) {
                heroBlock
                filterBar
                garmentGrid
            }
            .padding(.horizontal, COREDesign.horizontalPadding)
            .padding(.top, 12)
            .padding(.bottom, 100)
        }
        .background(theme.bg)
        .overlay(alignment: .bottomTrailing) {
            addButton
        }
        .sheet(isPresented: $showAddSheet) {
            AddGarmentSheet(viewModel: viewModel)
        }
        .sheet(item: $selectedGarment) { garment in
            GarmentDetailSheet(garment: garment, viewModel: viewModel)
        }
        .task { viewModel.sync() }
    }

    // MARK: - Hero Block

    @ViewBuilder
    private var heroBlock: some View {
        VStack(spacing: 14) {
            // Clarity score
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text("Klarhet")
                        .font(.dmSans(13, weight: .medium))
                        .foregroundStyle(theme.text3)
                    Text("\(Int(viewModel.clarityScore))")
                        .font(.instrumentSerif(48))
                        .foregroundStyle(theme.text)
                    Text(viewModel.clarityBand.rawValue.capitalized)
                        .font(.dmSans(12))
                        .foregroundStyle(theme.gold)
                }

                Spacer()

                // Best outfit preview
                if let outfit = viewModel.bestOutfit {
                    VStack(spacing: 4) {
                        Text("Dagens antrekk")
                            .font(.dmSans(11, weight: .medium))
                            .foregroundStyle(theme.text3)
                        outfitStack(outfit.garments)
                    }
                }
            }

            // Primary gap
            if let gap = viewModel.primaryGap {
                HStack(spacing: 10) {
                    Image(systemName: "plus.circle.dashed")
                        .foregroundStyle(theme.gold)
                    VStack(alignment: .leading, spacing: 2) {
                        Text(gap.title)
                            .font(.dmSans(13, weight: .medium))
                            .foregroundStyle(theme.text)
                        Text(gap.description)
                            .font(.dmSans(11))
                            .foregroundStyle(theme.text3)
                    }
                    Spacer()
                }
                .padding(12)
                .background {
                    RoundedRectangle(cornerRadius: COREDesign.cornerRadiusSmall)
                        .strokeBorder(theme.gold.opacity(0.3), style: StrokeStyle(lineWidth: 1, dash: [6]))
                }
            }
        }
        .padding(COREDesign.spacing)
        .glassCard()
    }

    // MARK: - Filter Bar

    @ViewBuilder
    private var filterBar: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 8) {
                filterChip("Alle", isActive: !viewModel.filter.isActive) {
                    viewModel.filter = WardrobeFilter()
                }
                ForEach(Category.allCases, id: \.self) { cat in
                    filterChip(categoryLabel(cat), isActive: viewModel.filter.category == cat) {
                        viewModel.filter.category = viewModel.filter.category == cat ? nil : cat
                    }
                }
            }
        }
    }

    @ViewBuilder
    private func filterChip(_ label: String, isActive: Bool, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            Text(label)
                .font(.dmSans(12, weight: .medium))
                .foregroundStyle(isActive ? theme.bg : theme.text2)
                .padding(.horizontal, 14)
                .padding(.vertical, 7)
                .background {
                    Capsule()
                        .fill(isActive ? theme.gold : theme.surface)
                }
        }
    }

    // MARK: - Garment Grid

    @ViewBuilder
    private var garmentGrid: some View {
        if viewModel.isEmpty {
            emptyState
        } else {
            LazyVGrid(columns: [
                GridItem(.flexible(), spacing: 12),
                GridItem(.flexible(), spacing: 12)
            ], spacing: 12) {
                ForEach(viewModel.filteredGarments) { garment in
                    GarmentCard(garment: garment, isKey: viewModel.keyGarmentIDs.contains(garment.id), theme: theme)
                        .onTapGesture { selectedGarment = garment }
                }
            }
        }
    }

    @ViewBuilder
    private var emptyState: some View {
        VStack(spacing: 16) {
            Image(systemName: "hanger")
                .font(.system(size: 48))
                .foregroundStyle(theme.text4)
            Text("Garderoben er tom")
                .font(.instrumentSerif(24))
                .foregroundStyle(theme.text2)
            Text("Legg til ditt f\u{00F8}rste plagg for \u{00E5} komme i gang")
                .font(.dmSans(14))
                .foregroundStyle(theme.text3)
                .multilineTextAlignment(.center)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 60)
    }

    // MARK: - Add Button (FAB)

    @ViewBuilder
    private var addButton: some View {
        Button { showAddSheet = true } label: {
            Image(systemName: "plus")
                .font(.system(size: 22, weight: .medium))
                .foregroundStyle(theme.bg)
                .frame(width: 56, height: 56)
                .background(Circle().fill(theme.gold))
                .shadow(color: theme.gold.opacity(0.3), radius: 12, y: 4)
        }
        .padding(.trailing, COREDesign.horizontalPadding)
        .padding(.bottom, 100)
    }

    // MARK: - Helpers

    @ViewBuilder
    private func outfitStack(_ garments: [Garment]) -> some View {
        HStack(spacing: -8) {
            ForEach(garments.prefix(4)) { garment in
                Circle()
                    .fill(theme.surface)
                    .frame(width: 32, height: 32)
                    .overlay {
                        Text(garmentEmoji(garment))
                            .font(.system(size: 16))
                    }
            }
        }
    }

    private func categoryLabel(_ category: Category) -> String {
        switch category {
        case .upper: "Overkropp"
        case .lower: "Underkropp"
        case .shoes: "Sko"
        case .accessory: "Tilbeh\u{00F8}r"
        }
    }

    private func garmentEmoji(_ garment: Garment) -> String {
        switch garment.baseGroup {
        case .tee, .shirt, .knit, .hoodie: "\u{1F455}"
        case .blazer, .coat: "\u{1F9E5}"
        case .jeans, .chinos, .trousers, .shorts: "\u{1F456}"
        case .skirt: "\u{1FA73}"
        case .sneakers, .boots, .loafers, .sandals: "\u{1F45F}"
        case .belt, .scarf, .cap, .bag: "\u{1F45C}"
        }
    }
}

// MARK: - Garment Card

struct GarmentCard: View {
    let garment: Garment
    let isKey: Bool
    let theme: CORETheme

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            // Image placeholder
            ZStack(alignment: .topTrailing) {
                RoundedRectangle(cornerRadius: COREDesign.cornerRadiusSmall)
                    .fill(theme.surface)
                    .aspectRatio(0.8, contentMode: .fit)
                    .overlay {
                        Text(emoji)
                            .font(.system(size: 36))
                    }

                if isKey {
                    Circle()
                        .fill(theme.gold)
                        .frame(width: 10, height: 10)
                        .padding(8)
                }
            }

            // Info
            VStack(alignment: .leading, spacing: 2) {
                Text(garment.name.isEmpty ? garment.baseGroup.rawValue.capitalized : garment.name)
                    .font(.dmSans(13, weight: .medium))
                    .foregroundStyle(theme.text)
                    .lineLimit(1)
                Text(garment.category.rawValue.capitalized)
                    .font(.dmSans(11))
                    .foregroundStyle(theme.text3)
            }
        }
        .padding(10)
        .glassCard()
    }

    private var emoji: String {
        switch garment.baseGroup {
        case .tee, .shirt, .knit, .hoodie: "\u{1F455}"
        case .blazer, .coat: "\u{1F9E5}"
        case .jeans, .chinos, .trousers, .shorts: "\u{1F456}"
        case .skirt: "\u{1FA73}"
        case .sneakers, .boots, .loafers, .sandals: "\u{1F45F}"
        case .belt, .scarf, .cap, .bag: "\u{1F45C}"
        }
    }
}
