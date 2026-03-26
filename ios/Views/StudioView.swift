import SwiftUI
import COREEngine

// ╔══════════════════════════════════════════════════════════════╗
// ║  STUDIO ART DIRECTION — FROZEN                              ║
// ║                                                              ║
// ║  Background:  #F3EEE7 → #EDE6DD vertical gradient           ║
// ║  Glass:       white 42%, border #DDD6CC — UI surfaces only   ║
// ║  Shadows:     #392C1E warm brown, downward only              ║
// ║  Accent:      #C7A56A muted gold                             ║
// ║  Text:        #2C2824 primary, #746D65 secondary             ║
// ║  Hero:        ZStack overlap, no FX, no cards                ║
// ║  Sizes:       top 220pt, pants 188pt, shoes 104pt            ║
// ║  Overlap:     top→pants 28pt, pants→shoes gap 16pt           ║
// ║                                                              ║
// ║  Do not change without design review.                        ║
// ╚══════════════════════════════════════════════════════════════╝

// MARK: - Gallery Design Tokens

/// Studio gallery palette — locked to light gallery direction.
/// No dark mode. No spotlight. No theatrical lighting.
private enum Gallery {
    // Background — warm stone, subtle vertical gradient only
    static let bgTop    = Color(hex: "F3EEE7")
    static let bgBottom = Color(hex: "EDE6DD")

    // Glass — UI surfaces only (insight card, nav, controls)
    static let glass       = Color.white.opacity(0.42)
    static let glassBorder = Color.white.opacity(0.50)

    // Text
    static let textPrimary   = Color(hex: "2C2824")
    static let textSecondary = Color(hex: "746D65")

    // Accent — muted gold
    static let accent     = Color(hex: "C7A56A")
    static let accentSoft = Color(hex: "D8BE8D")

    // Shadows — warm brown, downward only
    static let shadow       = Color(hex: "392C1E").opacity(0.08)
    static let shadowMedium = Color(hex: "392C1E").opacity(0.12)

    // Borders — warm thin lines
    static let border = Color(hex: "DDD6CC")
}

struct StudioView: View {
    @Bindable var viewModel: StudioViewModel
    @Environment(\.theme) private var theme
    @State private var showWearConfirmation = false
    @State private var heroOnlyMode = false

    private var hasOutfit: Bool { !viewModel.currentOutfitGarments.isEmpty }

    var body: some View {
        // Hero-only validation mode: just background + outfit, nothing else.
        if heroOnlyMode {
            heroOnlyView
        } else {
            fullStudioView
        }
    }

    /// Debug: renders ONLY background + hero. No insight, no nav, no CTA.
    /// Triple-tap to toggle. If hero doesn't work alone, don't continue.
    private var heroOnlyView: some View {
        ZStack(alignment: .topTrailing) {
            LinearGradient(
                colors: [Gallery.bgTop, Gallery.bgBottom],
                startPoint: .top, endPoint: .bottom
            ).ignoresSafeArea()

            outfitHero

            // Debug controls
            VStack(spacing: 8) {
                Button { heroOnlyMode = false } label: {
                    Image(systemName: "xmark.circle.fill")
                        .font(.system(size: 24))
                        .foregroundStyle(Gallery.textSecondary.opacity(0.4))
                }
                Button {
                    viewModel.testOutfitIndex += 1
                    viewModel.loadTestOutfit(viewModel.testOutfitIndex)
                } label: {
                    Text("Next")
                        .font(.dmSans(10, weight: .medium))
                        .foregroundStyle(Gallery.textSecondary)
                        .padding(.horizontal, 10)
                        .padding(.vertical, 5)
                        .background(.ultraThinMaterial)
                        .clipShape(Capsule())
                }
            }
            .padding(20)
        }
        .onAppear { viewModel.loadTestOutfit(0) }
    }

    private var fullStudioView: some View {
        ZStack(alignment: .trailing) {
            ScrollView {
                VStack(spacing: 0) {
                    if hasOutfit {
                        topControls
                        outfitHero
                        insightCard
                            .padding(.horizontal, COREDesign.horizontalPadding)
                            .padding(.top, 16)
                    } else {
                        emptyState
                    }
                    actionButtons
                        .padding(.horizontal, COREDesign.horizontalPadding)
                        .padding(.top, hasOutfit ? 20 : 0)
                        .padding(.bottom, 90)
                }
            }
            // Gallery background — warm stone gradient
            .background(
                LinearGradient(
                    colors: [Gallery.bgTop, Gallery.bgBottom],
                    startPoint: .top,
                    endPoint: .bottom
                )
                .ignoresSafeArea()
            )
            .scrollDisabled(viewModel.isDrawerOpen)

            if viewModel.isDrawerOpen {
                accessoryDrawer
                    .transition(.move(edge: .trailing))
            }
        }
        .animation(.spring(response: 0.4, dampingFraction: 0.8), value: viewModel.isDrawerOpen)
        .onTapGesture(count: 3) { heroOnlyMode = true }
        .alert("Antrekk logget!", isPresented: $showWearConfirmation) {
            Button("OK") { }
        } message: {
            Text("Dagens antrekk er registrert.")
        }
    }

    // MARK: - Empty State

    private var emptyState: some View {
        VStack(spacing: 20) {
            Spacer().frame(height: 80)

            ZStack {
                Circle()
                    .fill(Gallery.accent.opacity(0.08))
                    .frame(width: 100, height: 100)
                Image(systemName: "tshirt")
                    .font(.system(size: 40, weight: .thin))
                    .foregroundStyle(Gallery.accent.opacity(0.5))
            }

            VStack(spacing: 8) {
                (Text("Bygg dagens ")
                    .font(.instrumentSerif(26))
                    .foregroundStyle(Gallery.textPrimary)
                + Text("antrekk")
                    .font(.instrumentSerifItalic(26))
                    .foregroundStyle(Gallery.accent))

                Text("Legg til plagg i garderoben, s\u{00E5} setter du dem sammen her")
                    .font(.dmSans(14))
                    .foregroundStyle(Gallery.textSecondary)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 32)
            }

            Button {
                viewModel.generateSurpriseOutfit()
            } label: {
                HStack(spacing: 8) {
                    Image(systemName: "sparkles").font(.system(size: 14))
                    Text("Generer antrekk automatisk").font(.dmSans(14, weight: .medium))
                }
                .foregroundStyle(Gallery.accent)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 14)
                .background(Gallery.accent.opacity(0.08))
                .clipShape(Capsule())
                .overlay(Capsule().stroke(Gallery.accent.opacity(0.2), lineWidth: 1))
            }
            .padding(.horizontal, 40)
            .padding(.top, 8)
            .disabled(viewModel.availableUppers.isEmpty)
            .opacity(viewModel.availableUppers.isEmpty ? 0.4 : 1)

            if viewModel.availableUppers.isEmpty {
                Text("Ingen plagg enn\u{00E5} \u{2014} g\u{00E5} til Garderobe")
                    .font(.dmSans(12))
                    .foregroundStyle(Gallery.textSecondary.opacity(0.6))
                    .padding(.top, 4)
            }

            Spacer().frame(height: 40)
        }
    }

    // MARK: - Top Controls (minimal)

    private var topControls: some View {
        HStack {
            Spacer()
            Button { viewModel.generateSurpriseOutfit() } label: {
                HStack(spacing: 5) {
                    Image(systemName: "sparkles").font(.system(size: 10))
                    Text("Surprise").font(.dmSans(11, weight: .medium))
                }
                .foregroundStyle(Gallery.textSecondary)
                .padding(.horizontal, 12)
                .padding(.vertical, 7)
                .background(.ultraThinMaterial)
                .clipShape(Capsule())
            }
        }
        .padding(.horizontal, COREDesign.horizontalPadding)
        .padding(.top, 4)
        .padding(.bottom, 4)
    }

    // MARK: - Outfit Hero

    /// Fixed hero zone — 340pt. Fits on all iPhones without scrolling past fold.
    /// iPhone SE: 340/667 = 51%, iPhone 15 Pro: 340/852 = 40%. Always dominant.
    private var outfitHero: some View {
        outfitComposition
            .frame(height: 340)
            .frame(maxWidth: .infinity)
    }

    // MARK: - Outfit Composition (single center axis)

    /// All garments on ONE vertical center line. No drift.
    /// Fixed size ratios: top 1.00, pants 0.85, shoes 0.47.
    /// Top overlaps pants by ~24pt. Pants→shoes gap 14pt.
    /// Scaled to fit 340pt hero zone on all iPhones.
    private var outfitComposition: some View {
        // Fixed pt sizes — scaled to fit 340pt hero
        let topW: CGFloat    = 180
        let pantsW: CGFloat  = 154   // 0.85× top
        let shoeW: CGFloat   = 85    // 0.47× top

        // Heights proportional to category canvas aspect ratios
        let topH: CGFloat    = topW * 1.17   // ~211pt
        let pantsH: CGFloat  = pantsW * 1.40 // ~216pt
        let shoeH: CGFloat   = shoeW * 0.78  // ~66pt

        // Vertical layout: top overlaps pants, shoes have gap
        let overlap: CGFloat = 24    // top→pants overlap
        let gap: CGFloat     = 14    // pants→shoes gap

        // Offsets from center (pants = anchor at y=0)
        let topY    = -(pantsH / 2) - (topH / 2) + overlap
        let pantsY: CGFloat = 0
        let shoeY   = (pantsH / 2) + gap + (shoeH / 2)

        return ZStack {
            // Underdel — center anchor
            if let bottom = viewModel.bottomLayer {
                garmentImage(bottom)
                    .frame(width: pantsW, height: pantsH)
                    .offset(y: pantsY)
                    .zIndex(1)
            } else {
                emptySlot(label: "Underdel")
                    .frame(width: pantsW * 0.8, height: pantsH * 0.5)
                    .offset(y: pantsY)
                    .zIndex(1)
            }

            // Overdel — hero piece, overlaps pants
            if let top = viewModel.topLayer {
                garmentImage(top)
                    .frame(width: topW, height: topH)
                    .offset(y: topY)
                    .zIndex(2)
            } else {
                emptySlot(label: "Overdel")
                    .frame(width: topW * 0.8, height: topH * 0.5)
                    .offset(y: topY)
                    .zIndex(2)
            }

            // Sko — below pants with gap
            if let shoe = viewModel.shoes {
                garmentImage(shoe)
                    .frame(width: shoeW, height: shoeH)
                    .offset(y: shoeY)
                    .zIndex(0)
            } else {
                emptySlot(label: "Sko")
                    .frame(width: shoeW * 0.85, height: shoeH * 0.7)
                    .offset(y: shoeY)
                    .zIndex(0)
            }

            // Ytterlag — floated left, subtle
            if let outer = viewModel.outerLayer {
                garmentImage(outer)
                    .frame(width: topW * 0.68, height: topH * 0.80)
                    .rotationEffect(.degrees(-4))
                    .offset(x: -(topW * 0.55), y: topY * 0.5)
                    .opacity(0.65)
                    .zIndex(3)
            }
        }
        .contentShape(Rectangle())
        .gesture(
            DragGesture(minimumDistance: 30)
                .onEnded { value in
                    if abs(value.translation.width) > abs(value.translation.height) {
                        let dir = value.translation.width < 0 ? 1 : -1
                        withAnimation(.spring(response: 0.35, dampingFraction: 0.8)) {
                            viewModel.swipe(.top, direction: dir)
                        }
                    }
                }
        )
    }

    // MARK: - Garment Image

    /// Clean cutout rendering — no cards, no masks.
    /// Per-category shadow: tops wider, shoes tighter, all downward-only.
    @ViewBuilder
    private func garmentImage(_ garment: Garment) -> some View {
        let shadow = categoryShadow(garment.category)
        if !garment.image.isEmpty, let url = URL(string: garment.image) {
            if url.isFileURL, let data = try? Data(contentsOf: url),
               let uiImage = UIImage(data: data) {
                Image(uiImage: uiImage)
                    .resizable().scaledToFit()
                    .shadow(color: shadow.color, radius: shadow.radius, x: 0, y: shadow.y)
            } else {
                AsyncImage(url: url) { phase in
                    switch phase {
                    case .success(let img):
                        img.resizable().scaledToFit()
                            .shadow(color: shadow.color, radius: shadow.radius, x: 0, y: shadow.y)
                    default:
                        ProgressView().tint(Gallery.textSecondary.opacity(0.3))
                            .frame(maxWidth: .infinity, maxHeight: .infinity)
                    }
                }
            }
        } else {
            let hex = garment.dominantColor.hasPrefix("#")
                ? String(garment.dominantColor.dropFirst())
                : garment.dominantColor
            RoundedRectangle(cornerRadius: 12)
                .fill(Color(hex: hex).opacity(0.3))
                .shadow(color: shadow.color, radius: shadow.radius, x: 0, y: shadow.y)
        }
    }

    /// Per-category shadow spec from Implementation Checklist.
    private struct GarmentShadow {
        let color: Color
        let radius: CGFloat
        let y: CGFloat
    }

    private func categoryShadow(_ category: Category) -> GarmentShadow {
        let base = Color(hex: "392C1E")
        switch category {
        case .upper:
            return GarmentShadow(color: base.opacity(0.10), radius: 24, y: 12)
        case .lower:
            return GarmentShadow(color: base.opacity(0.09), radius: 20, y: 10)
        case .shoes:
            return GarmentShadow(color: base.opacity(0.08), radius: 16, y: 8)
        case .accessory:
            return GarmentShadow(color: base.opacity(0.07), radius: 14, y: 6)
        }
    }

    private func emptySlot(label: String) -> some View {
        VStack(spacing: 4) {
            Image(systemName: "plus")
                .font(.system(size: 14, weight: .light))
                .foregroundStyle(Gallery.textSecondary.opacity(0.35))
            Text(label)
                .font(.dmSans(9, weight: .medium))
                .foregroundStyle(Gallery.textSecondary.opacity(0.25))
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(
            RoundedRectangle(cornerRadius: 10)
                .strokeBorder(Gallery.textSecondary.opacity(0.12), style: StrokeStyle(lineWidth: 1, dash: [5]))
        )
    }

    // MARK: - Insight Card (museum label)

    /// Calm gallery label — supports hero, doesn't compete.
    /// Large score, small label, one descriptor, max 2 metrics.
    private var insightCard: some View {
        VStack(spacing: 12) {
            // Clarity score — large, quiet
            HStack(alignment: .firstTextBaseline, spacing: 8) {
                Text("\(viewModel.scoreDisplay)")
                    .font(.instrumentSerif(48))
                    .foregroundStyle(Gallery.textPrimary)

                VStack(alignment: .leading, spacing: 2) {
                    Text("Clarity")
                        .font(.dmSans(9, weight: .medium))
                        .foregroundStyle(Gallery.textSecondary)
                        .textCase(.uppercase)
                        .tracking(1.5)
                    Text(viewModel.archetypeMatch.rawValue.capitalized)
                        .font(.dmSans(11, weight: .medium))
                        .foregroundStyle(Gallery.accent)
                }

                Spacer()
            }

            // Short descriptor — gallery-label language
            Text(galleryDescriptor)
                .font(.instrumentSerifItalic(13))
                .foregroundStyle(Gallery.textSecondary)
                .frame(maxWidth: .infinity, alignment: .leading)

            // Max 2 supporting metrics
            if viewModel.outfitScore != nil {
                HStack(spacing: 20) {
                    attributeMeter("Flyt", value: verdictValue(viewModel.silhouetteVerdict))
                    attributeMeter("Farger", value: verdictValue(viewModel.colorVerdict))
                }
            }
        }
        .padding(20)
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(Gallery.glass)
                .overlay(
                    RoundedRectangle(cornerRadius: 16)
                        .stroke(Gallery.border.opacity(0.5), lineWidth: 0.5)
                )
                .shadow(color: Gallery.shadow, radius: 16, x: 0, y: 6)
        )
    }

    /// Maps engine score to calm gallery-label descriptors.
    private var galleryDescriptor: String {
        let score = viewModel.scoreDisplay
        if score >= 85 { return "Strong alignment" }
        if score >= 70 { return "Clean balance" }
        if score >= 55 { return "Balanced and wearable" }
        if score >= 40 { return "Room to refine" }
        return "Early composition"
    }

    private func attributeMeter(_ label: String, value: Double) -> some View {
        HStack(spacing: 8) {
            Text(label)
                .font(.dmSans(11, weight: .medium))
                .foregroundStyle(Gallery.textSecondary)
            GeometryReader { g in
                ZStack(alignment: .leading) {
                    Capsule().fill(Gallery.textSecondary.opacity(0.1))
                    Capsule()
                        .fill(value >= 0.7 ? Color.coretSage : value >= 0.4 ? Gallery.accent : Color.coretRed)
                        .frame(width: g.size.width * min(max(value, 0), 1))
                        .animation(.spring(response: 0.5, dampingFraction: 0.8), value: value)
                }
            }.frame(height: 3)
            Text("\(Int(value * 100))")
                .font(.dmSans(11))
                .foregroundStyle(Gallery.textSecondary)
                .frame(width: 26, alignment: .trailing)
        }
    }

    private func verdictValue(_ v: String) -> Double {
        switch v.lowercased() {
        case "strong", "sterk", "harmonious": 0.92
        case "balanced", "good", "god": 0.75
        case "neutral": 0.5
        case "weak", "svak", "uniform": 0.3
        case "poor", "clash": 0.15
        default: 0.5
        }
    }

    // MARK: - Action Buttons

    private var actionButtons: some View {
        HStack(spacing: 12) {
            // Secondary
            Button { viewModel.generateSurpriseOutfit() } label: {
                Text("Overrask")
                    .font(.dmSans(14, weight: .medium))
                    .foregroundStyle(Gallery.textSecondary)
                    .frame(maxWidth: .infinity).padding(.vertical, 16)
                    .background(.ultraThinMaterial)
                    .clipShape(RoundedRectangle(cornerRadius: 14))
                    .overlay(
                        RoundedRectangle(cornerRadius: 14)
                            .stroke(Gallery.border, lineWidth: 0.5)
                    )
            }

            // Primary
            Button {
                Task { await viewModel.wearToday(); showWearConfirmation = true }
            } label: {
                HStack(spacing: 6) {
                    Text("Bruk i dag").font(.dmSans(14, weight: .medium))
                    Image(systemName: "arrow.right").font(.system(size: 12, weight: .medium))
                }
                .foregroundStyle(.white)
                .frame(maxWidth: .infinity).padding(.vertical, 16)
                .background(Gallery.accent)
                .clipShape(RoundedRectangle(cornerRadius: 14))
                .shadow(color: Gallery.accent.opacity(0.25), radius: 12, x: 0, y: 6)
            }
            .disabled(!hasOutfit).opacity(hasOutfit ? 1 : 0.5)
        }
    }

    // MARK: - Accessory Drawer

    private var accessoryDrawer: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text("Tilbeh\u{00F8}r").font(.instrumentSerif(18)).foregroundStyle(Gallery.textPrimary)
                Spacer()
                Button { viewModel.isDrawerOpen = false } label: {
                    Image(systemName: "xmark").foregroundStyle(Gallery.textSecondary).frame(width: 44, height: 44)
                }
            }
            ScrollView {
                VStack(spacing: 8) {
                    ForEach(viewModel.availableAccessories) { acc in
                        let sel = viewModel.selectedAccessories.contains { $0.id == acc.id }
                        Button { viewModel.toggleAccessory(acc) } label: {
                            HStack {
                                RoundedRectangle(cornerRadius: 4).fill(accColor(acc)).frame(width: 20, height: 24)
                                Text(acc.name.isEmpty ? acc.baseGroup.rawValue.capitalized : acc.name)
                                    .font(.dmSans(13)).foregroundStyle(Gallery.textPrimary)
                                Spacer()
                                if sel { Image(systemName: "checkmark.circle.fill").foregroundStyle(Gallery.accent) }
                            }
                            .padding(10)
                            .background(RoundedRectangle(cornerRadius: 8).fill(sel ? Gallery.accent.opacity(0.1) : Gallery.glass))
                        }
                    }
                }
            }
        }
        .padding(16).frame(width: 220)
        .background(RoundedRectangle(cornerRadius: COREDesign.cornerRadius).fill(.ultraThinMaterial))
        .padding(.trailing, 8)
    }

    private func accColor(_ g: Garment) -> Color {
        let h = g.dominantColor
        guard !h.isEmpty, h != "#000000" else { return Gallery.bgBottom }
        return Color(hex: String(h.dropFirst()))
    }
}
