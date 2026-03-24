import SwiftUI
import COREEngine

struct ProfileView: View {
    @Bindable var viewModel: ProfileViewModel
    @Environment(\.theme) private var theme

    var body: some View {
        ScrollView(showsIndicators: false) {
            VStack(spacing: COREDesign.spacing) {
                avatarSection
                identitySection
                archetypeSelector
                seasonSection
                milestonesSection
                settingsSection
            }
            .padding(.horizontal, COREDesign.horizontalPadding)
            .padding(.bottom, 120)
        }
        .background(theme.bg)
        .task { viewModel.sync() }
    }

    // MARK: - Avatar

    @ViewBuilder
    private var avatarSection: some View {
        VStack(spacing: 10) {
            // Avatar circle
            Circle()
                .fill(
                    LinearGradient(
                        colors: [theme.gold.opacity(0.3), theme.sage.opacity(0.2)],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
                .frame(width: 80, height: 80)
                .overlay {
                    Text(viewModel.primaryArchetype.rawValue.prefix(1).uppercased())
                        .font(.instrumentSerif(32))
                        .foregroundStyle(theme.text)
                }

            // Identity label
            if !viewModel.identityLabel.isEmpty {
                Text(viewModel.identityLabel)
                    .font(.instrumentSerif(22))
                    .foregroundStyle(theme.text)
            }

            // Tags
            if !viewModel.identityTags.isEmpty {
                FlowLayout(spacing: 6) {
                    ForEach(viewModel.identityTags, id: \.self) { tag in
                        Text(tag)
                            .font(.dmSans(11, weight: .medium))
                            .foregroundStyle(theme.text2)
                            .padding(.horizontal, 10)
                            .padding(.vertical, 4)
                            .background(Capsule().fill(theme.surface))
                    }
                }
            }
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 20)
    }

    // MARK: - Identity

    @ViewBuilder
    private var identitySection: some View {
        if let identity = viewModel.identity {
            VStack(alignment: .leading, spacing: 8) {
                Text("Strukturell Identitet")
                    .font(.dmSans(13, weight: .semibold))
                    .foregroundStyle(theme.text3)

                Text(identity.prose)
                    .font(.dmSans(14))
                    .foregroundStyle(theme.text2)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(COREDesign.spacing)
            .glassCard()
        }
    }

    // MARK: - Archetype

    @ViewBuilder
    private var archetypeSelector: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("Primær Arketype")
                .font(.dmSans(13, weight: .semibold))
                .foregroundStyle(theme.text3)

            HStack(spacing: 10) {
                ForEach(Archetype.allCases, id: \.self) { arch in
                    archetypeChip(arch)
                }
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(COREDesign.spacing)
        .glassCard()
    }

    @ViewBuilder
    private func archetypeChip(_ archetype: Archetype) -> some View {
        let isSelected = viewModel.primaryArchetype == archetype
        Button {
            Task { await viewModel.updateArchetype(archetype) }
        } label: {
            Text(archetypeLabel(archetype))
                .font(.dmSans(13, weight: .medium))
                .foregroundStyle(isSelected ? theme.bg : theme.text2)
                .padding(.horizontal, 14)
                .padding(.vertical, 8)
                .background {
                    Capsule()
                        .fill(isSelected ? theme.gold : theme.surface)
                }
        }
    }

    // MARK: - Season

    @ViewBuilder
    private var seasonSection: some View {
        if let coverage = viewModel.seasonalCoverage {
            VStack(alignment: .leading, spacing: 10) {
                Text("Sesong-dekning")
                    .font(.dmSans(13, weight: .semibold))
                    .foregroundStyle(theme.text3)

                HStack(spacing: 12) {
                    seasonBar("V\u{00E5}r", score: coverage.springScore)
                    seasonBar("Sommer", score: coverage.summerScore)
                    seasonBar("H\u{00F8}st", score: coverage.autumnScore)
                    seasonBar("Vinter", score: coverage.winterScore)
                }

                if viewModel.shouldSuggestRecalibration {
                    Button {
                        Task { await viewModel.applyRecalibration() }
                    } label: {
                        HStack(spacing: 6) {
                            Image(systemName: "arrow.triangle.2.circlepath")
                            Text("Rekalibrér for sesong")
                        }
                        .font(.dmSans(13, weight: .medium))
                        .foregroundStyle(theme.gold)
                    }
                }
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(COREDesign.spacing)
            .glassCard()
        }
    }

    @ViewBuilder
    private func seasonBar(_ label: String, score: Double) -> some View {
        VStack(spacing: 4) {
            Text(label)
                .font(.dmSans(10))
                .foregroundStyle(theme.text3)

            GeometryReader { geo in
                RoundedRectangle(cornerRadius: 3)
                    .fill(theme.surface)
                    .overlay(alignment: .bottom) {
                        RoundedRectangle(cornerRadius: 3)
                            .fill(score > 0.6 ? theme.sage : theme.gold)
                            .frame(height: geo.size.height * score)
                    }
            }
            .frame(height: 50)

            Text("\(Int(score * 100))")
                .font(.dmSans(10, weight: .medium))
                .foregroundStyle(theme.text2)
        }
        .frame(maxWidth: .infinity)
    }

    // MARK: - Milestones

    @ViewBuilder
    private var milestonesSection: some View {
        if !viewModel.milestones.isEmpty {
            VStack(alignment: .leading, spacing: 10) {
                Text("Milepæler")
                    .font(.dmSans(13, weight: .semibold))
                    .foregroundStyle(theme.text3)

                ForEach(viewModel.milestones.suffix(5)) { milestone in
                    HStack(spacing: 10) {
                        Image(systemName: "star.fill")
                            .font(.system(size: 12))
                            .foregroundStyle(theme.gold)
                        VStack(alignment: .leading, spacing: 2) {
                            Text(milestone.title)
                                .font(.dmSans(13, weight: .medium))
                                .foregroundStyle(theme.text)
                            Text(milestone.description)
                                .font(.dmSans(11))
                                .foregroundStyle(theme.text3)
                        }
                    }
                }
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(COREDesign.spacing)
            .glassCard()
        }
    }

    // MARK: - Settings

    @ViewBuilder
    private var settingsSection: some View {
        VStack(spacing: 0) {
            settingsRow(icon: "square.and.arrow.up", label: "Eksporter data") { }
            Divider().padding(.leading, 44)
            settingsRow(icon: "lock.shield", label: "Personvern") { }
            Divider().padding(.leading, 44)
            settingsRow(icon: "info.circle", label: "Om CORET") { }
            Divider().padding(.leading, 44)
            settingsRow(icon: "arrow.counterclockwise", label: "Nullstill profil", isDestructive: true) {
                viewModel.showResetConfirmation = true
            }
        }
        .glassCard()
        .alert("Nullstill profil?", isPresented: $viewModel.showResetConfirmation) {
            Button("Avbryt", role: .cancel) { }
            Button("Nullstill", role: .destructive) {
                Task { await viewModel.resetProfile() }
            }
        } message: {
            Text("Dette sletter alle plagg, antrekk og historikk. Kan ikke angres.")
        }
    }

    @ViewBuilder
    private func settingsRow(icon: String, label: String, isDestructive: Bool = false, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            HStack(spacing: 12) {
                Image(systemName: icon)
                    .font(.system(size: 16))
                    .foregroundStyle(isDestructive ? Color.coretRed : theme.text2)
                    .frame(width: 24)
                Text(label)
                    .font(.dmSans(14))
                    .foregroundStyle(isDestructive ? Color.coretRed : theme.text)
                Spacer()
                Image(systemName: "chevron.right")
                    .font(.system(size: 12))
                    .foregroundStyle(theme.text4)
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 14)
        }
    }

    // MARK: - Helpers

    private func archetypeLabel(_ arch: Archetype) -> String {
        switch arch {
        case .tailored: "Tailored"
        case .smartCasual: "Smart Casual"
        case .street: "Street"
        }
    }
}

// MARK: - Flow Layout

struct FlowLayout: Layout {
    var spacing: CGFloat = 8

    func sizeThatFits(proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) -> CGSize {
        let result = arrange(proposal: proposal, subviews: subviews)
        return result.size
    }

    func placeSubviews(in bounds: CGRect, proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) {
        let result = arrange(proposal: proposal, subviews: subviews)
        for (index, position) in result.positions.enumerated() {
            subviews[index].place(at: CGPoint(x: bounds.minX + position.x, y: bounds.minY + position.y), proposal: .unspecified)
        }
    }

    private func arrange(proposal: ProposedViewSize, subviews: Subviews) -> (size: CGSize, positions: [CGPoint]) {
        let maxWidth = proposal.width ?? .infinity
        var positions: [CGPoint] = []
        var x: CGFloat = 0
        var y: CGFloat = 0
        var rowHeight: CGFloat = 0

        for subview in subviews {
            let size = subview.sizeThatFits(.unspecified)
            if x + size.width > maxWidth, x > 0 {
                x = 0
                y += rowHeight + spacing
                rowHeight = 0
            }
            positions.append(CGPoint(x: x, y: y))
            rowHeight = max(rowHeight, size.height)
            x += size.width + spacing
        }

        return (CGSize(width: maxWidth, height: y + rowHeight), positions)
    }
}
