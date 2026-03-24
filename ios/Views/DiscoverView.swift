import SwiftUI
import COREEngine

struct DiscoverView: View {
    @Bindable var viewModel: DiscoverViewModel
    @Environment(\.theme) private var theme
    @State private var dragOffset: CGSize = .zero

    var body: some View {
        VStack(spacing: 0) {
            modeToggle
            cardStack
        }
        .background(theme.bg)
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
        .padding(.vertical, 12)
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
                    .gesture(swipeGesture)
                    .animation(.spring(response: 0.4, dampingFraction: 0.75), value: dragOffset)

                // Side actions
                actionButtons
            }
        } else {
            emptyFeed
        }
    }

    @ViewBuilder
    private func cardView(_ card: DiscoverCard) -> some View {
        ZStack(alignment: .bottom) {
            // Background
            RoundedRectangle(cornerRadius: 28)
                .fill(theme.surface)
                .overlay {
                    // Score watermark
                    Text("\(Int(card.strength * 100))")
                        .font(.instrumentSerif(120))
                        .foregroundStyle(theme.text.opacity(0.04))
                }

            // Outfit garments
            VStack(spacing: 6) {
                ForEach(card.garments.prefix(4)) { garment in
                    Text(garmentEmoji(garment))
                        .font(.system(size: 32))
                }
            }
            .frame(maxHeight: .infinity)

            // Bottom panel
            VStack(alignment: .leading, spacing: 6) {
                Text(card.outfitName)
                    .font(.instrumentSerif(22))
                    .foregroundStyle(theme.text)

                HStack(spacing: 8) {
                    feedTypeBadge(card.feedType)

                    if let score = card.score.explanation {
                        Text(score.headline)
                            .font(.dmSans(12))
                            .foregroundStyle(theme.text3)
                            .lineLimit(1)
                    }
                }

                // Missing piece
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
            }
            .padding(20)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background {
                RoundedRectangle(cornerRadius: 28)
                    .fill(.ultraThinMaterial)
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .padding(.horizontal, COREDesign.horizontalPadding)
        .padding(.bottom, 80)
    }

    @ViewBuilder
    private func feedTypeBadge(_ type: DiscoverCard.FeedType) -> some View {
        let (label, color): (String, Color) = switch type {
        case .owned: ("Eiet", theme.sage)
        case .rotation: ("Rotasjon", theme.gold)
        case .ghost: ("Forslag", Color.coretAmber)
        }
        Text(label)
            .font(.dmSans(10, weight: .semibold))
            .foregroundStyle(color)
            .padding(.horizontal, 8)
            .padding(.vertical, 3)
            .background(Capsule().fill(color.opacity(0.12)))
    }

    // MARK: - Actions

    @ViewBuilder
    private var actionButtons: some View {
        VStack(spacing: 16) {
            actionButton(icon: "heart", color: theme.sage) { viewModel.like() }
            actionButton(icon: "bookmark", color: theme.gold) { viewModel.hook() }
            actionButton(icon: "hand.thumbsdown", color: theme.text3) { viewModel.pass() }
        }
        .padding(.trailing, 12)
        .frame(maxWidth: .infinity, alignment: .trailing)
    }

    @ViewBuilder
    private func actionButton(icon: String, color: Color, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            Image(systemName: icon)
                .font(.system(size: 20))
                .foregroundStyle(color)
                .frame(width: 48, height: 48)
                .background(Circle().fill(.ultraThinMaterial))
        }
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
    }

    // MARK: - Swipe Gesture

    private var swipeGesture: some Gesture {
        DragGesture()
            .onChanged { value in
                dragOffset = value.translation
            }
            .onEnded { value in
                if value.translation.height < -100 {
                    withAnimation { viewModel.swipeUp() }
                }
                dragOffset = .zero
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
