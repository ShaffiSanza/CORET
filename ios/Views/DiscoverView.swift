import SwiftUI
import COREEngine

struct DiscoverView: View {
    @Bindable var viewModel: DiscoverViewModel
    @Environment(\.theme) private var theme
    @State private var dragOffset: CGSize = .zero
    @State private var actionTrigger: Int = 0
    @State private var hasSeenFirstCard = false
    @State private var blobPhase: CGFloat = 0

    var body: some View {
        VStack(spacing: 0) {
            modeToggle
            cardStack
        }
        .background(theme.bg)
        .sensoryFeedback(.impact(weight: .light), trigger: actionTrigger)
        .task { await viewModel.loadFeed() }
    }

    // MARK: - Mode Toggle

    @ViewBuilder
    private var modeToggle: some View {
        HStack(spacing: 0) {
            toggleButton("70/30", mode: .seventyThirty)
            toggleButton("Full", mode: .full)
        }
        .background(Capsule().fill(theme.surface))
        .padding(.horizontal, COREDesign.horizontalPadding)
        .padding(.top, 16)
        .padding(.bottom, 8)
    }

    @ViewBuilder
    private func toggleButton(_ label: String, mode: DiscoverMode) -> some View {
        Button {
            viewModel.switchMode(mode)
        } label: {
            Text(label)
                .font(.dmSans(13, weight: .medium))
                .foregroundStyle(viewModel.mode == mode ? theme.bg : theme.text2)
                .padding(.horizontal, 20)
                .padding(.vertical, 8)
                .background {
                    if viewModel.mode == mode {
                        Capsule().fill(theme.gold)
                    }
                }
        }
        .accessibilityLabel("Modus: \(label)")
        .accessibilityAddTraits(viewModel.mode == mode ? .isSelected : [])
    }

    // MARK: - Card Stack

    @ViewBuilder
    private var cardStack: some View {
        if viewModel.isLoading {
            Spacer()
            ProgressView()
            Spacer()
        } else if let card = viewModel.currentCard {
            ZStack {
                cardView(card)
                    .offset(y: dragOffset.height)
                    .rotationEffect(.degrees(dragOffset.width * 0.01))
                    .opacity(1.0 - abs(dragOffset.height) / 500.0)
                    .gesture(swipeGesture)
                    .animation(.spring(response: 0.4, dampingFraction: 0.75), value: dragOffset)

                actionButtons

                // Scroll dots (left side)
                if viewModel.cards.count > 1 {
                    scrollDots
                }
            }
        } else {
            emptyFeed
        }
    }

    // MARK: - Card View (Glassmorphism + Blobs)

    @ViewBuilder
    private func cardView(_ card: DiscoverCard) -> some View {
        let colors = card.garments.prefix(3).map { cardGarmentColor($0) }

        ZStack(alignment: .bottom) {
            // Card background with animated blobs
            RoundedRectangle(cornerRadius: 28)
                .fill(Color(hex: "0E0C0A"))
                .overlay {
                    // Dynamic gradient blobs based on outfit colors
                    ZStack {
                        if colors.count > 0 {
                            Circle()
                                .fill(colors[0].opacity(0.15))
                                .frame(width: 350, height: 350)
                                .blur(radius: 100)
                                .offset(x: -60, y: -80)
                                .scaleEffect(1 + sin(blobPhase) * 0.1)
                        }
                        if colors.count > 1 {
                            Circle()
                                .fill(colors[1].opacity(0.12))
                                .frame(width: 280, height: 280)
                                .blur(radius: 100)
                                .offset(x: 80, y: 100)
                                .scaleEffect(1 + sin(blobPhase + 2) * 0.1)
                        }
                        if colors.count > 2 {
                            Circle()
                                .fill(colors[2].opacity(0.10))
                                .frame(width: 200, height: 200)
                                .blur(radius: 80)
                                .offset(x: -20, y: 40)
                                .scaleEffect(1 + sin(blobPhase + 4) * 0.1)
                        }
                    }
                    .animation(.easeInOut(duration: 6).repeatForever(autoreverses: true), value: blobPhase)
                    .onAppear { blobPhase = .pi * 2 }
                }
                .clipShape(RoundedRectangle(cornerRadius: 28))

            // Score watermark — large, semi-transparent
            Text("\(Int(card.strength * 100))")
                .font(.instrumentSerif(220))
                .foregroundStyle(.white.opacity(0.035))
                .offset(y: -60)

            // Garment stack with depth
            VStack(spacing: 6) {
                ForEach(Array(card.garments.prefix(4).enumerated()), id: \.element.id) { index, garment in
                    garmentOrb(garment, index: index)
                }
            }
            .frame(maxHeight: .infinity)
            .padding(.top, 40)

            // Glass bottom panel
            VStack(alignment: .leading, spacing: 8) {
                // Missing piece (above everything)
                if let missing = card.missingPiece {
                    HStack(spacing: 6) {
                        Image(systemName: "plus.circle.dashed")
                            .foregroundStyle(theme.gold)
                        Text("Mangler: \(missing.name)")
                            .font(.dmSans(12, weight: .medium))
                            .foregroundStyle(theme.gold)
                    }
                    .padding(8)
                    .background {
                        RoundedRectangle(cornerRadius: 8)
                            .strokeBorder(theme.gold.opacity(0.3), style: StrokeStyle(lineWidth: 1, dash: [4]))
                    }
                }

                // Outfit name
                Text(card.outfitName)
                    .font(.instrumentSerifItalic(22))
                    .foregroundStyle(.white.opacity(0.45))

                // Tags row
                HStack(spacing: 6) {
                    feedTypeBadge(card.feedType)

                    if let explanation = card.score.explanation {
                        Text(explanation.headline)
                            .font(.dmSans(12))
                            .foregroundStyle(.white.opacity(0.2))
                            .lineLimit(1)
                    }
                }

                // Swipe hint
                if !hasSeenFirstCard {
                    HStack(spacing: 4) {
                        Image(systemName: "arrow.up")
                            .font(.system(size: 8))
                        Text("Swipe for neste")
                            .font(.dmSans(9))
                            .tracking(1)
                            .textCase(.uppercase)
                    }
                    .foregroundStyle(.white.opacity(0.06))
                    .frame(maxWidth: .infinity)
                    .padding(.top, 6)
                }
            }
            .padding(.horizontal, 24)
            .padding(.vertical, 16)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background {
                LinearGradient(
                    colors: [.clear, Color(hex: "0E0C0A").opacity(0.85), Color(hex: "0E0C0A").opacity(0.95)],
                    startPoint: .top,
                    endPoint: .bottom
                )
            }
        }
        .clipShape(RoundedRectangle(cornerRadius: 28))
        .overlay(
            RoundedRectangle(cornerRadius: 28)
                .stroke(.white.opacity(0.04), lineWidth: 1)
        )
        .shadow(color: .black.opacity(0.5), radius: 30, y: 10)
        .padding(.horizontal, COREDesign.horizontalPadding)
        .padding(.bottom, 80)
        .padding(.top, 4)
    }

    // MARK: - Garment Orb (with depth stacking)

    @ViewBuilder
    private func garmentOrb(_ garment: Garment, index: Int) -> some View {
        let color = cardGarmentColor(garment)
        let scale = 1.0 - Double(index) * 0.04

        Circle()
            .fill(
                RadialGradient(
                    colors: [color.opacity(0.9), color.opacity(0.6), color.opacity(0.3)],
                    center: .center,
                    startRadius: 0,
                    endRadius: 30
                )
            )
            .frame(width: 56, height: 56)
            .overlay {
                Circle()
                    .stroke(.white.opacity(0.08), lineWidth: 1)
            }
            .shadow(color: color.opacity(0.4), radius: 16, y: 8)
            .shadow(color: .black.opacity(0.3), radius: 8, y: 4)
            .scaleEffect(scale)
            .zIndex(Double(4 - index))
    }

    // MARK: - Scroll Dots

    @ViewBuilder
    private var scrollDots: some View {
        VStack(spacing: 6) {
            ForEach(0..<min(viewModel.cards.count, 8), id: \.self) { index in
                if index == viewModel.currentIndex {
                    RoundedRectangle(cornerRadius: 2)
                        .fill(theme.gold.opacity(0.5))
                        .frame(width: 4, height: 14)
                } else {
                    Circle()
                        .fill(.white.opacity(0.08))
                        .frame(width: 4, height: 4)
                }
            }
        }
        .padding(.leading, 14)
        .frame(maxWidth: .infinity, alignment: .leading)
        .animation(.spring(response: 0.4, dampingFraction: 0.8), value: viewModel.currentIndex)
    }

    @ViewBuilder
    private func feedTypeBadge(_ type: DiscoverCard.FeedType) -> some View {
        let (label, color): (String, Color) = switch type {
        case .owned: ("Eiet", theme.sage)
        case .rotation: ("Rotasjon", theme.gold)
        case .ghost: ("Forslag", Color.coretAmber)
        }
        Text(label)
            .font(.dmSans(9, weight: .semibold))
            .foregroundStyle(color.opacity(0.35))
            .padding(.horizontal, 10)
            .padding(.vertical, 4)
            .background(
                Capsule()
                    .fill(color.opacity(0.04))
                    .overlay(Capsule().stroke(color.opacity(0.06), lineWidth: 1))
            )
    }

    // MARK: - Actions (TikTok-style right side)

    @ViewBuilder
    private var actionButtons: some View {
        VStack(spacing: 18) {
            actionButton(icon: "heart", label: "Lik", color: .white.opacity(0.2)) {
                actionTrigger += 1
                viewModel.like()
                hasSeenFirstCard = true
            }
            actionButton(icon: "bookmark", label: "Lagre", color: .white.opacity(0.2)) {
                actionTrigger += 1
                viewModel.hook()
                hasSeenFirstCard = true
            }
            actionButton(icon: "hand.thumbsdown", label: "Pass", color: .white.opacity(0.12)) {
                actionTrigger += 1
                viewModel.pass()
                hasSeenFirstCard = true
            }
        }
        .padding(.trailing, 16)
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .trailing)
        .offset(y: -20)
    }

    @ViewBuilder
    private func actionButton(icon: String, label: String, color: Color, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            VStack(spacing: 3) {
                Image(systemName: icon)
                    .font(.system(size: 18, weight: .light))
                    .foregroundStyle(color)
                    .frame(width: 46, height: 46)
                    .background(
                        Circle()
                            .fill(.white.opacity(0.06))
                            .overlay(Circle().stroke(.white.opacity(0.06), lineWidth: 1))
                    )
                Text(label.uppercased())
                    .font(.system(size: 7))
                    .tracking(0.5)
                    .foregroundStyle(.white.opacity(0.12))
            }
        }
        .accessibilityLabel(label)
    }

    @ViewBuilder
    private var emptyFeed: some View {
        VStack(spacing: 16) {
            Spacer()
            Image(systemName: "sparkles")
                .font(.system(size: 48))
                .foregroundStyle(theme.text4)
            Text("Ingen antrekk enn\u{00E5}")
                .font(.instrumentSerif(24))
                .foregroundStyle(theme.text2)
            Text("Legg til plagg i garderoben for \u{00E5} se antrekk her")
                .font(.dmSans(14))
                .foregroundStyle(theme.text3)
                .multilineTextAlignment(.center)
            Spacer()
        }
        .padding(.horizontal, 40)
        .accessibilityElement(children: .combine)
    }

    // MARK: - Swipe Gesture

    private var swipeGesture: some Gesture {
        DragGesture()
            .onChanged { value in
                dragOffset = value.translation
            }
            .onEnded { value in
                if value.translation.height < -100 {
                    actionTrigger += 1
                    hasSeenFirstCard = true
                    withAnimation { viewModel.swipeUp() }
                }
                dragOffset = .zero
            }
    }

    private func cardGarmentColor(_ garment: Garment) -> Color {
        let hex = garment.dominantColor
        guard !hex.isEmpty else { return theme.surface }
        let cleaned = hex.hasPrefix("#") ? String(hex.dropFirst()) : hex
        guard !cleaned.isEmpty else { return theme.surface }
        return Color(hex: cleaned)
    }
}
