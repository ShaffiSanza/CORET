import SwiftUI
import COREEngine

struct WardrobeView: View {
    @Bindable var viewModel: WardrobeViewModel
    @Environment(\.theme) private var theme
    @State private var showAddSheet = false
    @State private var selectedGarment: Garment?
    @State private var appeared = false

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
        .sheet(isPresented: $showAddSheet, onDismiss: {
            viewModel.sync()
        }) {
            AddGarmentSheet(viewModel: viewModel)
        }
        .sheet(item: $selectedGarment) { garment in
            GarmentDetailSheet(garment: garment, viewModel: viewModel)
        }
        .onAppear {
            viewModel.sync()
            if !appeared {
                withAnimation(.spring(response: 0.4, dampingFraction: 0.8)) {
                    appeared = true
                }
            }
        }
    }

    // MARK: - Hero Block (Bento Layout)

    @ViewBuilder
    private var heroBlock: some View {
        VStack(spacing: 10) {
            // Row 1: Clarity (left) + Dagens (right)
            HStack(spacing: 10) {
                // Block 1 — Clarity Score
                VStack(alignment: .leading, spacing: 6) {
                    Text("CLARITY")
                        .font(.dmSans(9, weight: .semibold))
                        .tracking(2)
                        .foregroundStyle(theme.text3Fixed)

                    Text("\(Int(viewModel.clarityScore))")
                        .font(.instrumentSerif(48))
                        .foregroundStyle(theme.text)

                    if viewModel.clarityWeeklyDelta != 0 {
                        HStack(spacing: 4) {
                            Image(systemName: viewModel.clarityWeeklyDelta > 0 ? "arrow.up" : "arrow.down")
                                .font(.system(size: 10, weight: .semibold))
                                .foregroundStyle(viewModel.clarityWeeklyDelta > 0 ? theme.sage : Color.coretRed)
                            Text("\(viewModel.clarityWeeklyDelta > 0 ? "+" : "")\(Int(viewModel.clarityWeeklyDelta)) denne uken")
                                .font(.dmSans(11))
                                .foregroundStyle(viewModel.clarityWeeklyDelta > 0 ? theme.sage : Color.coretRed)
                        }
                    }
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(16)
                .glassCard()
                .accessibilityElement(children: .combine)
                .accessibilityLabel("Clarity score \(Int(viewModel.clarityScore))")

                // Block 2 — Dagens outfit
                VStack(spacing: 8) {
                    Text("DAGENS")
                        .font(.dmSans(9, weight: .semibold))
                        .tracking(2)
                        .foregroundStyle(theme.text3Fixed)

                    if let outfit = viewModel.bestOutfit {
                        HStack(spacing: 6) {
                            ForEach(outfit.garments.prefix(3)) { garment in
                                VStack(spacing: 4) {
                                    RoundedRectangle(cornerRadius: 8)
                                        .fill(garmentColor(garment))
                                        .frame(width: 44, height: 52)
                                    Text(garmentShortLabel(garment))
                                        .font(.dmSans(9))
                                        .foregroundStyle(theme.text3Fixed)
                                        .lineLimit(1)
                                }
                            }
                        }
                    } else {
                        Text("Legg til plagg")
                            .font(.dmSans(12))
                            .foregroundStyle(theme.text4)
                            .frame(height: 52)
                    }
                }
                .frame(maxWidth: .infinity)
                .padding(16)
                .glassCard()
                .overlay(
                    RoundedRectangle(cornerRadius: COREDesign.cardCornerRadius)
                        .stroke(theme.gold.opacity(0.15), lineWidth: 1)
                )
                .accessibilityElement(children: .combine)
                .accessibilityLabel("Dagens antrekk")
            }

            // Row 2: Gap block (full width)
            if let gap = viewModel.primaryGap {
                HStack(spacing: 0) {
                    VStack(alignment: .leading, spacing: 4) {
                        Text("GAP \u{00B7} DU MANGLER")
                            .font(.dmSans(9, weight: .semibold))
                            .tracking(1.5)
                            .foregroundStyle(theme.text3Fixed)

                        Text(gap.title)
                            .font(.dmSans(14, weight: .medium))
                            .foregroundStyle(theme.text)

                        Text("Ville l\u{00F8}ftet \(gap.suggestions.count) outfits")
                            .font(.dmSans(11))
                            .foregroundStyle(theme.text3Fixed)
                    }

                    Spacer()

                    Button {
                        showAddSheet = true
                    } label: {
                        Text("Se forslag \u{2192}")
                            .font(.dmSans(11, weight: .medium))
                            .foregroundStyle(theme.gold)
                            .padding(.horizontal, 14)
                            .padding(.vertical, 7)
                            .background(Capsule().fill(theme.gold.opacity(0.08)))
                            .overlay(Capsule().stroke(theme.gold.opacity(0.2), lineWidth: 1))
                    }
                    .accessibilityLabel("Se forslag for \(gap.title)")
                }
                .padding(16)
                .background {
                    RoundedRectangle(cornerRadius: COREDesign.cardCornerRadius)
                        .fill(theme.gold.opacity(0.03))
                        .overlay(
                            RoundedRectangle(cornerRadius: COREDesign.cardCornerRadius)
                                .stroke(theme.gold.opacity(0.15), lineWidth: 1)
                        )
                }
                .accessibilityElement(children: .combine)
                .accessibilityLabel("Du mangler \(gap.title). Ville l\u{00F8}ftet \(gap.suggestions.count) outfits.")
            }
        }
    }

    /// Garment thumbnail color based on dominant color
    private func garmentColor(_ garment: Garment) -> Color {
        let hex = garment.dominantColor
        guard !hex.isEmpty, hex != "#000000" else { return theme.surface }
        return Color(hex: String(hex.dropFirst())) // remove #
    }

    /// Short label for garment thumbnail
    private func garmentShortLabel(_ garment: Garment) -> String {
        switch garment.baseGroup {
        case .coat, .blazer: "Jakke"
        case .tee: "Tee"
        case .shirt: "Skjorte"
        case .knit: "Strikk"
        case .hoodie: "Hoodie"
        case .jeans: "Jeans"
        case .chinos: "Chinos"
        case .trousers: "Bukse"
        case .shorts: "Shorts"
        case .skirt: "Skj\u{00F8}rt"
        case .sneakers: "Sneakers"
        case .boots: "Boots"
        case .loafers: "Loafers"
        case .sandals: "Sandaler"
        case .belt, .scarf, .cap, .bag: garment.baseGroup.rawValue.capitalized
        }
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
        .accessibilityLabel("Filter: \(label)")
        .accessibilityAddTraits(isActive ? .isSelected : [])
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
                ForEach(Array(viewModel.filteredGarments.enumerated()), id: \.element.id) { index, garment in
                    GarmentCard(
                        garment: garment,
                        isKey: viewModel.keyGarmentIDs.contains(garment.id),
                        theme: theme
                    )
                    .onTapGesture { selectedGarment = garment }
                    .opacity(appeared ? 1 : 0)
                    .offset(y: appeared ? 0 : 20)
                    .animation(
                        .spring(response: 0.4, dampingFraction: 0.8)
                            .delay(Double(index) * 0.03),
                        value: appeared
                    )
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
        .accessibilityElement(children: .combine)
        .accessibilityLabel("Garderoben er tom. Legg til ditt f\u{00F8}rste plagg for \u{00E5} komme i gang.")
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
        .accessibilityLabel("Legg til plagg")
    }

    // MARK: - Helpers

    @ViewBuilder
    private func outfitStack(_ garments: [Garment]) -> some View {
        HStack(spacing: -8) {
            ForEach(garments.prefix(4)) { garment in
                Circle()
                    .fill(garmentColor(garment))
                    .frame(width: 32, height: 32)
                    .overlay {
                        RoundedRectangle(cornerRadius: 6)
                            .fill(garmentColor(garment))
                            .frame(width: 20, height: 20)
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
}

// MARK: - Garment Card

struct GarmentCard: View {
    let garment: Garment
    let isKey: Bool
    let theme: CORETheme

    @State private var isPressed = false

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            // Image or color swatch
            ZStack(alignment: .topTrailing) {
                if !garment.image.isEmpty, let url = URL(string: garment.image) {
                    AsyncImage(url: url) { phase in
                        switch phase {
                        case .success(let img):
                            img.resizable()
                                .scaledToFill()
                                .frame(maxWidth: .infinity)
                                .aspectRatio(0.8, contentMode: .fit)
                                .clipShape(RoundedRectangle(cornerRadius: COREDesign.cornerRadiusSmall))
                        default:
                            colorSwatch
                        }
                    }
                } else {
                    colorSwatch
                }

                if isKey {
                    Image(systemName: "star.fill")
                        .font(.system(size: 10))
                        .foregroundStyle(theme.gold)
                        .padding(8)
                }
            }

            // Info
            VStack(alignment: .leading, spacing: 2) {
                Text(garment.name.isEmpty ? garment.baseGroup.rawValue.capitalized : garment.name)
                    .font(.dmSans(13, weight: .medium))
                    .foregroundStyle(theme.text)
                    .lineLimit(1)
                Text(garment.baseGroup.rawValue.capitalized)
                    .font(.dmSans(11))
                    .foregroundStyle(theme.text3)
            }
        }
        .padding(10)
        .glassCard()
        .overlay(
            RoundedRectangle(cornerRadius: COREDesign.cardCornerRadius)
                .stroke(isKey ? theme.gold.opacity(0.4) : Color.clear, lineWidth: 1.5)
        )
        .scaleEffect(isPressed ? 0.96 : 1.0)
        .animation(.spring(response: 0.4, dampingFraction: 0.8), value: isPressed)
        .onLongPressGesture(minimumDuration: .infinity, pressing: { pressing in
            isPressed = pressing
        }, perform: {})
        .accessibilityElement(children: .combine)
        .accessibilityLabel("\(garment.name.isEmpty ? garment.baseGroup.rawValue : garment.name), \(garment.category.rawValue)\(isKey ? ", n\u{00F8}kkelplagg" : "")")
    }

    @ViewBuilder
    private var colorSwatch: some View {
        RoundedRectangle(cornerRadius: COREDesign.cornerRadiusSmall)
            .fill(theme.surface)
            .aspectRatio(0.8, contentMode: .fit)
            .overlay {
                RoundedRectangle(cornerRadius: 10)
                    .fill(cardColor)
                    .frame(width: 48, height: 56)
            }
    }

    private var cardColor: Color {
        let hex = garment.dominantColor
        guard !hex.isEmpty else { return theme.surface }
        let cleaned = hex.hasPrefix("#") ? String(hex.dropFirst()) : hex
        guard !cleaned.isEmpty else { return theme.surface }
        return Color(hex: cleaned)
    }
}
