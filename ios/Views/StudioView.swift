import SwiftUI
import COREEngine

struct StudioView: View {
    @Bindable var viewModel: StudioViewModel
    @Environment(\.theme) private var theme
    @State private var showWearConfirmation = false
    @State private var scoreGlow = false

    private var hasOutfit: Bool { !viewModel.currentOutfitGarments.isEmpty }

    var body: some View {
        ZStack(alignment: .trailing) {
            ScrollView {
                VStack(spacing: 0) {
                    if hasOutfit {
                        topBar
                        editorialCanvas
                        scoreBand
                        scoreBreakdown
                            .padding(.horizontal, COREDesign.horizontalPadding)
                            .padding(.top, 12)
                    } else {
                        emptyState
                    }
                    actionButtons
                        .padding(.horizontal, COREDesign.horizontalPadding)
                        .padding(.top, hasOutfit ? 12 : 0)
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
        .onChange(of: viewModel.scoreDisplay) {
            withAnimation(.easeInOut(duration: 0.3)) { scoreGlow = true }
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                withAnimation(.easeOut(duration: 0.4)) { scoreGlow = false }
            }
        }
        .alert("Antrekk logget!", isPresented: $showWearConfirmation) {
            Button("OK") { }
        } message: {
            Text("Dagens antrekk er registrert.")
        }
    }

    // MARK: - Empty State

    private var emptyState: some View {
        VStack(spacing: 20) {
            Spacer().frame(height: 60)

            ZStack {
                Circle()
                    .fill(theme.gold.opacity(0.06))
                    .frame(width: 120, height: 120)
                Image(systemName: "tshirt")
                    .font(.system(size: 44, weight: .thin))
                    .foregroundStyle(theme.gold.opacity(0.5))
            }

            VStack(spacing: 8) {
                (Text("Bygg dagens ")
                    .font(.instrumentSerif(26))
                    .foregroundStyle(theme.text)
                + Text("antrekk")
                    .font(.instrumentSerifItalic(26))
                    .foregroundStyle(theme.gold))

                Text("Legg til plagg i garderoben, s\u{00E5} setter du dem sammen her")
                    .font(.dmSans(14))
                    .foregroundStyle(theme.text3)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 32)
            }

            // Quick actions
            VStack(spacing: 10) {
                Button {
                    viewModel.generateSurpriseOutfit()
                } label: {
                    HStack(spacing: 8) {
                        Image(systemName: "sparkles")
                            .font(.system(size: 14))
                        Text("Generer antrekk automatisk")
                            .font(.dmSans(14, weight: .medium))
                    }
                    .foregroundStyle(theme.gold)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 14)
                    .background(theme.gold.opacity(0.08))
                    .clipShape(Capsule())
                    .overlay(Capsule().stroke(theme.gold.opacity(0.2), lineWidth: 1))
                }
                .disabled(viewModel.availableUppers.isEmpty)
                .opacity(viewModel.availableUppers.isEmpty ? 0.4 : 1)
            }
            .padding(.horizontal, 40)
            .padding(.top, 8)

            if viewModel.availableUppers.isEmpty {
                Text("Ingen plagg enn\u{00E5} \u{2014} g\u{00E5} til Garderobe")
                    .font(.dmSans(12))
                    .foregroundStyle(theme.text4)
                    .padding(.top, 4)
            }

            Spacer().frame(height: 40)
        }
    }

    // MARK: - Top Bar

    private var topBar: some View {
        HStack {
            HStack(alignment: .firstTextBaseline, spacing: 5) {
                Text("\(viewModel.scoreDisplay)")
                    .font(.instrumentSerif(30))
                    .foregroundStyle(theme.text)
                    .contentTransition(.numericText())
                    .shadow(color: scoreGlow ? theme.gold.opacity(0.5) : .clear, radius: 12)
                if viewModel.scoreDisplay > 0 {
                    Text("\u{2191} +\(viewModel.scoreDisplay)")
                        .font(.dmSans(10, weight: .medium))
                        .foregroundStyle(theme.sage)
                }
            }

            Spacer()

            HStack(spacing: 6) {
                Button { viewModel.isDrawerOpen.toggle() } label: {
                    Image(systemName: "plus.circle")
                        .font(.system(size: 16))
                        .foregroundStyle(theme.text3)
                        .frame(width: 36, height: 36)
                        .background(theme.surface.opacity(0.6))
                        .clipShape(Circle())
                }

                Button { viewModel.generateSurpriseOutfit() } label: {
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
        ZStack {
            // Atmosphere
            RadialGradient(
                colors: [theme.gold.opacity(0.06), Color.clear],
                center: .init(x: 0.5, y: 0.35),
                startRadius: 20, endRadius: 220
            )

            garmentStack

            // Category labels (right edge)
            slotLabels

            // Accessories (bottom)
            accessoryPills
        }
        .frame(height: 440)
        .background(theme.surface.opacity(0.2))
    }

    // MARK: - Garment Stack

    @ViewBuilder
    private var garmentStack: some View {
        GeometryReader { geo in
            let w = geo.size.width
            let h = geo.size.height
            let cx = w * 0.46

            // Outer
            slotView(viewModel.outerLayer, .upper, isOuter: true)
                .frame(width: w * 0.55, height: h * 0.30)
                .position(x: cx, y: h * 0.15)
                .rotationEffect(.degrees(-3))
                .zIndex(4)

            // Top
            slotView(viewModel.topLayer, .upper, isOuter: false)
                .frame(width: w * 0.46, height: h * 0.22)
                .position(x: cx + 4, y: h * 0.36)
                .rotationEffect(.degrees(1.5))
                .zIndex(3)

            // Bottom
            slotView(viewModel.bottomLayer, .lower, isOuter: false)
                .frame(width: w * 0.48, height: h * 0.30)
                .position(x: cx - 2, y: h * 0.60)
                .rotationEffect(.degrees(-1))
                .zIndex(2)

            // Shoes
            slotView(viewModel.shoes, .shoes, isOuter: false)
                .frame(width: w * 0.40, height: h * 0.14)
                .position(x: cx + 2, y: h * 0.83)
                .rotationEffect(.degrees(2))
                .zIndex(3)
        }
    }

    @ViewBuilder
    private func slotView(_ garment: Garment?, _ category: Category, isOuter: Bool) -> some View {
        Menu {
            let items = garmentList(for: category, isOuter: isOuter)
            if items.isEmpty {
                Text("Ingen plagg tilgjengelig")
            }
            ForEach(items) { item in
                Button(item.name.isEmpty ? item.baseGroup.rawValue.capitalized : item.name) {
                    viewModel.setSlot(item)
                }
            }
            if garment != nil {
                Divider()
                Button("Fjern", role: .destructive) { viewModel.clearSlot(category: category) }
            }
        } label: {
            slotContent(garment)
        }
    }

    @ViewBuilder
    private func slotContent(_ garment: Garment?) -> some View {
        if let garment, !garment.image.isEmpty, let url = URL(string: garment.image) {
            if url.isFileURL, let data = try? Data(contentsOf: url),
               let uiImage = UIImage(data: data) {
                Image(uiImage: uiImage)
                    .resizable().scaledToFit()
                    .shadow(color: .black.opacity(0.3), radius: 16, y: 8)
            } else {
                AsyncImage(url: url) { phase in
                    switch phase {
                    case .success(let img):
                        img.resizable().scaledToFit()
                            .shadow(color: .black.opacity(0.3), radius: 16, y: 8)
                    default:
                        colorBlock(garment)
                    }
                }
            }
        } else if let garment {
            colorBlock(garment)
        } else {
            // Empty slot — subtle dashed outline
            RoundedRectangle(cornerRadius: 12)
                .strokeBorder(theme.text4.opacity(0.2), style: StrokeStyle(lineWidth: 1, dash: [6]))
                .background(theme.surface.opacity(0.08))
                .clipShape(RoundedRectangle(cornerRadius: 12))
                .overlay {
                    Image(systemName: "plus")
                        .font(.system(size: 16, weight: .light))
                        .foregroundStyle(theme.text4.opacity(0.3))
                }
        }
    }

    private func colorBlock(_ garment: Garment) -> some View {
        let hex = garment.dominantColor.hasPrefix("#")
            ? String(garment.dominantColor.dropFirst())
            : garment.dominantColor
        return RoundedRectangle(cornerRadius: 12)
            .fill(Color(hex: hex))
            .shadow(color: .black.opacity(0.25), radius: 10, y: 6)
    }

    // MARK: - Slot Labels

    private var slotLabels: some View {
        VStack(alignment: .trailing, spacing: 50) {
            label("Ytterlag", filled: viewModel.outerLayer != nil)
            label("Overdel", filled: viewModel.topLayer != nil)
            label("Underdel", filled: viewModel.bottomLayer != nil)
            label("Sko", filled: viewModel.shoes != nil)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topTrailing)
        .padding(.top, 24)
        .padding(.trailing, 12)
    }

    private func label(_ text: String, filled: Bool) -> some View {
        HStack(spacing: 4) {
            Circle()
                .fill(filled ? theme.gold : theme.text4.opacity(0.4))
                .frame(width: 5, height: 5)
            Text(text)
                .font(.dmSans(9, weight: .medium))
                .foregroundStyle(filled ? theme.gold : theme.text4)
        }
        .padding(.horizontal, 8).padding(.vertical, 4)
        .background(.ultraThinMaterial)
        .clipShape(Capsule())
    }

    // MARK: - Accessory Pills

    private var accessoryPills: some View {
        HStack(spacing: 5) {
            ForEach(viewModel.selectedAccessories.prefix(3)) { acc in
                HStack(spacing: 3) {
                    Circle().fill(theme.gold).frame(width: 4, height: 4)
                    Text(acc.baseGroup.rawValue.capitalized)
                        .font(.dmSans(8, weight: .medium))
                }
                .foregroundStyle(theme.gold)
                .padding(.horizontal, 7).padding(.vertical, 3)
                .background(theme.gold.opacity(0.1))
                .clipShape(Capsule())
                .overlay(Capsule().stroke(theme.gold.opacity(0.2), lineWidth: 1))
            }
            Button { viewModel.isDrawerOpen = true } label: {
                Text("+ Tilbeh\u{00F8}r")
                    .font(.dmSans(8, weight: .medium))
                    .foregroundStyle(theme.text4)
                    .padding(.horizontal, 7).padding(.vertical, 3)
                    .background(.ultraThinMaterial)
                    .clipShape(Capsule())
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .bottom)
        .padding(.bottom, 8)
    }

    // MARK: - Score Band

    @ViewBuilder
    private var scoreBand: some View {
        if let score = viewModel.outfitScore, let explanation = score.explanation {
            HStack {
                if let pos = explanation.positives.first {
                    Text("\u{201C}\(pos)\u{201D}")
                        .font(.instrumentSerifItalic(12))
                        .foregroundStyle(theme.text)
                        .lineLimit(1)
                }
                Spacer()
                Text(viewModel.archetypeMatch.rawValue.capitalized)
                    .font(.dmSans(9, weight: .medium))
                    .foregroundStyle(theme.sage)
                    .padding(.horizontal, 8).padding(.vertical, 3)
                    .background(theme.sage.opacity(0.1))
                    .clipShape(RoundedRectangle(cornerRadius: 4))
            }
            .padding(.horizontal, COREDesign.horizontalPadding)
            .padding(.vertical, 10)
            .background(theme.surface.opacity(0.3))
        }
    }

    // MARK: - Score Breakdown

    @ViewBuilder
    private var scoreBreakdown: some View {
        if viewModel.outfitScore != nil {
            VStack(spacing: 6) {
                bar("Flyt", verdictValue(viewModel.silhouetteVerdict))
                bar("Farger", verdictValue(viewModel.colorVerdict))
            }
            .padding(14)
            .glassCard()
        }
    }

    private func bar(_ lbl: String, _ val: Double) -> some View {
        HStack(spacing: 8) {
            Text(lbl).font(.dmSans(10, weight: .medium)).foregroundStyle(theme.text3).frame(width: 42, alignment: .leading)
            GeometryReader { g in
                ZStack(alignment: .leading) {
                    RoundedRectangle(cornerRadius: 1.5).fill(theme.surface)
                    RoundedRectangle(cornerRadius: 1.5)
                        .fill(val >= 0.7 ? theme.sage : val >= 0.4 ? theme.gold : Color.coretRed)
                        .frame(width: g.size.width * min(max(val, 0), 1))
                        .animation(.spring(response: 0.5, dampingFraction: 0.8), value: val)
                }
            }.frame(height: 3)
            Text("\(Int(val * 100))").font(.dmSans(10)).foregroundStyle(theme.text3).frame(width: 22, alignment: .trailing)
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
        HStack(spacing: 10) {
            Button { viewModel.generateSurpriseOutfit() } label: {
                HStack(spacing: 6) {
                    Image(systemName: "circle.circle").font(.system(size: 12))
                    Text("Overrask").font(.dmSans(13, weight: .medium))
                }
                .foregroundStyle(theme.text2)
                .frame(maxWidth: .infinity).padding(.vertical, 13)
                .background(theme.surface)
                .clipShape(RoundedRectangle(cornerRadius: COREDesign.cornerRadiusSmall))
            }

            Button {
                Task { await viewModel.wearToday(); showWearConfirmation = true }
            } label: {
                HStack(spacing: 6) {
                    Image(systemName: "checkmark").font(.system(size: 12))
                    Text("Bruk i dag \u{2192}").font(.dmSans(13, weight: .medium))
                }
                .foregroundStyle(theme.bg)
                .frame(maxWidth: .infinity).padding(.vertical, 13)
                .background(theme.gold)
                .clipShape(RoundedRectangle(cornerRadius: COREDesign.cornerRadiusSmall))
            }
            .disabled(!hasOutfit).opacity(hasOutfit ? 1 : 0.5)
        }
    }

    // MARK: - Accessory Drawer

    private var accessoryDrawer: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text("Tilbeh\u{00F8}r").font(.instrumentSerif(18)).foregroundStyle(theme.text)
                Spacer()
                Button { viewModel.isDrawerOpen = false } label: {
                    Image(systemName: "xmark").foregroundStyle(theme.text3).frame(width: 44, height: 44)
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
                                    .font(.dmSans(13)).foregroundStyle(theme.text)
                                Spacer()
                                if sel { Image(systemName: "checkmark.circle.fill").foregroundStyle(theme.gold) }
                            }
                            .padding(10)
                            .background(RoundedRectangle(cornerRadius: 8).fill(sel ? theme.gold.opacity(0.1) : theme.surface))
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
        guard !h.isEmpty, h != "#000000" else { return theme.surface }
        return Color(hex: String(h.dropFirst()))
    }

    private func garmentList(for cat: Category, isOuter: Bool) -> [Garment] {
        switch cat {
        case .upper:
            isOuter
                ? viewModel.availableUppers.filter { $0.baseGroup == .coat || $0.baseGroup == .blazer }
                : viewModel.availableUppers.filter { $0.baseGroup != .coat && $0.baseGroup != .blazer }
        case .lower: viewModel.availableLowers
        case .shoes: viewModel.availableShoes
        case .accessory: viewModel.availableAccessories
        }
    }
}
