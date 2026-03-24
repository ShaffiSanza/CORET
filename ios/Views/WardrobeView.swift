import SwiftUI
import COREEngine

struct WardrobeView: View {
    @Bindable var viewModel: WardrobeViewModel
    @Environment(\.theme) private var theme
    @State private var showAddSheet = false
    @State private var selectedGarment: Garment?
    @State private var activeTab: WardrobeTab = .plagg

    enum WardrobeTab { case plagg, antrekk }

    var body: some View {
        ZStack {
            // Ambient blobs
            ambientBlobs

            ScrollView(showsIndicators: false) {
                VStack(spacing: 0) {
                    heroOutfit
                    tabToggle
                    if activeTab == .plagg {
                        garmentContent
                    } else {
                        outfitContent
                    }
                }
                .padding(.bottom, 120)
            }

            // FAB
            VStack {
                Spacer()
                HStack {
                    Spacer()
                    addButton
                }
            }
        }
        .background(theme.bg)
        .sheet(isPresented: $showAddSheet) {
            AddGarmentSheet(viewModel: viewModel)
        }
        .sheet(item: $selectedGarment) { garment in
            GarmentDetailSheet(garment: garment, viewModel: viewModel)
        }
        .task { viewModel.sync() }
    }

    // MARK: - Ambient Blobs

    @ViewBuilder
    private var ambientBlobs: some View {
        ZStack {
            Circle()
                .fill(Color(hex: "3C2D1E").opacity(0.25))
                .frame(width: 320, height: 320)
                .blur(radius: 100)
                .offset(x: -80, y: -40)

            Circle()
                .fill(Color(hex: "32281A").opacity(0.20))
                .frame(width: 280, height: 280)
                .blur(radius: 100)
                .offset(x: 100, y: 300)
        }
        .ignoresSafeArea()
    }

    // MARK: - Hero Outfit Card

    @ViewBuilder
    private var heroOutfit: some View {
        if let outfit = viewModel.bestOutfit {
            VStack(spacing: 0) {
                // Stacked garments
                ZStack {
                    ForEach(Array(outfit.garments.prefix(4).enumerated()), id: \.element.id) { index, garment in
                        garmentPill(garment)
                            .scaleEffect(1.0 - Double(index) * 0.05)
                            .offset(y: CGFloat(index) * 8)
                            .zIndex(Double(4 - index))
                    }
                }
                .frame(height: 160)
                .padding(.top, 20)

                // Score + label
                VStack(spacing: 4) {
                    Text("\(Int(viewModel.clarityScore))")
                        .font(.instrumentSerif(32))
                        .foregroundStyle(theme.text)
                    Text(viewModel.clarityBand.rawValue.capitalized)
                        .font(.dmSans(11, weight: .medium))
                        .foregroundStyle(theme.gold)
                }
                .padding(.bottom, 16)
            }
            .frame(maxWidth: .infinity)
            .background {
                RoundedRectangle(cornerRadius: 20)
                    .fill(.ultraThinMaterial)
                    .environment(\.colorScheme, .dark)
                    .overlay(
                        RoundedRectangle(cornerRadius: 20)
                            .stroke(Color.white.opacity(0.06), lineWidth: 1)
                    )
                    .shadow(color: .black.opacity(0.65), radius: 60, y: 40)
            }
            .padding(.horizontal, 14)
            .padding(.top, 14)
            .padding(.bottom, 20)
        } else {
            // Empty hero
            VStack(spacing: 8) {
                Text("0")
                    .font(.instrumentSerif(48))
                    .foregroundStyle(theme.text.opacity(0.3))
                Text("Legg til plagg for \u{00E5} starte")
                    .font(.dmSans(12))
                    .foregroundStyle(theme.text3)
            }
            .frame(maxWidth: .infinity)
            .frame(height: 180)
            .background {
                RoundedRectangle(cornerRadius: 20)
                    .fill(.ultraThinMaterial)
                    .environment(\.colorScheme, .dark)
            }
            .padding(.horizontal, 14)
            .padding(.top, 14)
            .padding(.bottom, 20)
        }
    }

    @ViewBuilder
    private func garmentPill(_ garment: Garment) -> some View {
        HStack(spacing: 8) {
            Text(garmentEmoji(garment))
                .font(.system(size: 24))
            Text(garment.name.isEmpty ? garment.baseGroup.rawValue.capitalized : garment.name)
                .font(.dmSans(12, weight: .medium))
                .foregroundStyle(theme.text)
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 10)
        .background {
            Capsule()
                .fill(.ultraThinMaterial)
                .environment(\.colorScheme, .dark)
                .overlay(Capsule().stroke(Color.white.opacity(0.06), lineWidth: 1))
                .shadow(color: .black.opacity(0.3), radius: 15, y: 12)
        }
    }

    // MARK: - Tab Toggle

    @ViewBuilder
    private var tabToggle: some View {
        HStack(spacing: 0) {
            tabButton("Plagg", isActive: activeTab == .plagg) { activeTab = .plagg }
            tabButton("Antrekk", isActive: activeTab == .antrekk) { activeTab = .antrekk }
        }
        .padding(3)
        .background {
            RoundedRectangle(cornerRadius: 10)
                .fill(Color.white.opacity(0.03))
                .overlay(
                    RoundedRectangle(cornerRadius: 10)
                        .stroke(theme.border, lineWidth: 1)
                )
        }
        .padding(.horizontal, 20)
        .padding(.bottom, 14)
    }

    @ViewBuilder
    private func tabButton(_ label: String, isActive: Bool, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            Text(label)
                .font(.dmSans(13))
                .foregroundStyle(isActive ? theme.gold : theme.text4)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 8)
                .background {
                    if isActive {
                        RoundedRectangle(cornerRadius: 8)
                            .fill(theme.gold.opacity(0.1))
                    }
                }
        }
    }

    // MARK: - Garment Content (Plagg tab)

    @ViewBuilder
    private var garmentContent: some View {
        let grouped = Dictionary(grouping: viewModel.filteredGarments) { $0.category }
        let order: [Category] = [.upper, .lower, .shoes, .accessory]

        ForEach(order, id: \.self) { category in
            if let items = grouped[category], !items.isEmpty {
                categoryRow(category: category, items: items)
            }
        }

        // Gaps
        if let gaps = viewModel.primaryGap {
            gapCards
        }
    }

    @ViewBuilder
    private func categoryRow(category: Category, items: [Garment]) -> some View {
        VStack(alignment: .leading, spacing: 10) {
            // Category header
            HStack {
                HStack(spacing: 6) {
                    Circle()
                        .fill(theme.gold.opacity(0.5))
                        .frame(width: 6, height: 6)
                    Text(categoryLabel(category).uppercased())
                        .font(.dmSans(9, weight: .medium))
                        .foregroundStyle(theme.text3)
                        .tracking(2)
                }
                Spacer()
                Text("\(items.count)")
                    .font(.dmSans(10))
                    .foregroundStyle(theme.text4)
            }
            .padding(.horizontal, 20)

            // Horizontal scroll of glass cards
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 8) {
                    ForEach(items) { garment in
                        glassGarmentCard(garment)
                            .onTapGesture { selectedGarment = garment }
                    }
                }
                .padding(.horizontal, 16)
            }
        }
        .padding(.bottom, 16)
    }

    @ViewBuilder
    private func glassGarmentCard(_ garment: Garment) -> some View {
        let isKey = viewModel.keyGarmentIDs.contains(garment.id)

        VStack(spacing: 6) {
            // Image area
            ZStack(alignment: .topTrailing) {
                RoundedRectangle(cornerRadius: 10)
                    .fill(theme.surface.opacity(0.3))
                    .frame(width: 120, height: 100)
                    .overlay {
                        Text(garmentEmoji(garment))
                            .font(.system(size: 32))
                    }

                if isKey {
                    Circle()
                        .fill(theme.gold)
                        .frame(width: 8, height: 8)
                        .padding(8)
                }
            }

            // Name
            Text(garment.name.isEmpty ? garment.baseGroup.rawValue.capitalized : garment.name)
                .font(.dmSans(11))
                .foregroundStyle(theme.text)
                .lineLimit(1)
                .frame(width: 110, alignment: .leading)
        }
        .padding(6)
        .frame(width: 132, height: 150)
        .background {
            RoundedRectangle(cornerRadius: 14)
                .fill(.ultraThinMaterial)
                .environment(\.colorScheme, .dark)
                .overlay(
                    RoundedRectangle(cornerRadius: 14)
                        .stroke(Color.white.opacity(0.06), lineWidth: 1)
                )
                .shadow(color: .black.opacity(0.6), radius: 40, y: 30)
        }
    }

    // MARK: - Gap Cards

    @ViewBuilder
    private var gapCards: some View {
        if let gapResult = viewModel.gapResult {
            ForEach(gapResult.gaps.prefix(3)) { gap in
                HStack(spacing: 10) {
                    VStack(alignment: .leading, spacing: 2) {
                        Text(gap.type.rawValue.uppercased())
                            .font(.dmSans(7, weight: .medium))
                            .foregroundStyle(theme.gold)
                            .tracking(2)
                        Text(gap.title)
                            .font(.instrumentSerifItalic(13))
                            .foregroundStyle(theme.text2)
                    }
                    Spacer()
                    Text("+\(String(format: "%.0f", abs(gap.suggestions.first?.clarityDelta ?? 0)))")
                        .font(.dmSans(8, weight: .medium))
                        .foregroundStyle(theme.gold)
                        .padding(.horizontal, 7)
                        .padding(.vertical, 2)
                        .background {
                            RoundedRectangle(cornerRadius: 3)
                                .fill(theme.gold.opacity(0.15))
                        }
                }
                .padding(14)
                .background {
                    RoundedRectangle(cornerRadius: 14)
                        .fill(theme.gold.opacity(0.02))
                        .overlay(
                            RoundedRectangle(cornerRadius: 14)
                                .strokeBorder(theme.gold.opacity(0.15), style: StrokeStyle(lineWidth: 1.5, dash: [6]))
                        )
                }
                .padding(.horizontal, 16)
            }
        }
    }

    // MARK: - Outfit Content (Antrekk tab)

    @ViewBuilder
    private var outfitContent: some View {
        let outfits = BestOutfitFinder.findBest(
            items: viewModel.garments,
            profile: viewModel.profile,
            count: 10
        )

        if outfits.isEmpty {
            Text("Legg til flere plagg for \u{00E5} se antrekk")
                .font(.dmSans(13))
                .foregroundStyle(theme.text3)
                .padding(.top, 40)
        } else {
            VStack(spacing: 10) {
                ForEach(outfits) { outfit in
                    outfitCard(outfit)
                }

                // Add new outfit card
                HStack {
                    Image(systemName: "plus")
                        .font(.system(size: 14))
                    Text("Nytt antrekk")
                        .font(.dmSans(12))
                }
                .foregroundStyle(theme.gold.opacity(0.55))
                .frame(maxWidth: .infinity)
                .padding(20)
                .background {
                    RoundedRectangle(cornerRadius: 14)
                        .strokeBorder(theme.gold.opacity(0.15), style: StrokeStyle(lineWidth: 1.5, dash: [6]))
                }
            }
            .padding(.horizontal, 16)
        }
    }

    @ViewBuilder
    private func outfitCard(_ outfit: RankedOutfit) -> some View {
        HStack(spacing: 14) {
            // Garment emojis
            HStack(spacing: -4) {
                ForEach(outfit.garments.prefix(4)) { g in
                    Text(garmentEmoji(g))
                        .font(.system(size: 20))
                }
            }

            VStack(alignment: .leading, spacing: 2) {
                Text(outfit.label)
                    .font(.dmSans(13, weight: .medium))
                    .foregroundStyle(theme.text)
                Text(outfit.archetypeMatch.rawValue.capitalized)
                    .font(.dmSans(10))
                    .foregroundStyle(theme.text3)
            }

            Spacer()

            Text("\(Int(outfit.strength * 100))")
                .font(.instrumentSerif(18))
                .foregroundStyle(theme.gold)
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 14)
        .background {
            RoundedRectangle(cornerRadius: 14)
                .fill(.ultraThinMaterial)
                .environment(\.colorScheme, .dark)
                .overlay(
                    RoundedRectangle(cornerRadius: 14)
                        .stroke(Color.white.opacity(0.06), lineWidth: 1)
                )
                .shadow(color: .black.opacity(0.4), radius: 24, y: 16)
        }
    }

    // MARK: - Add Button (FAB)

    @ViewBuilder
    private var addButton: some View {
        Button { showAddSheet = true } label: {
            Image(systemName: "plus")
                .font(.system(size: 20, weight: .medium))
                .foregroundStyle(theme.bg)
                .frame(width: 52, height: 52)
                .background(Circle().fill(theme.gold))
                .shadow(color: theme.gold.opacity(0.25), radius: 16, y: 6)
        }
        .padding(.trailing, 20)
        .padding(.bottom, 100)
    }

    // MARK: - Helpers

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
