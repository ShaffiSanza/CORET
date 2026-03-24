import SwiftUI
import COREEngine

struct GarmentDetailSheet: View {
    let garment: Garment
    let viewModel: WardrobeViewModel
    @Environment(\.theme) private var theme
    @Environment(\.dismiss) private var dismiss
    @State private var showDeleteConfirmation = false

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: COREDesign.spacing) {
                    heroSection
                    roleSection
                    removalSection
                    deleteButton
                }
                .padding(.horizontal, COREDesign.horizontalPadding)
                .padding(.bottom, 40)
            }
            .background(theme.bg)
            .navigationTitle(garment.name.isEmpty ? garment.baseGroup.rawValue.capitalized : garment.name)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Ferdig") { dismiss() }
                        .foregroundStyle(theme.gold)
                }
            }
            .alert("Slett plagg?", isPresented: $showDeleteConfirmation) {
                Button("Avbryt", role: .cancel) { }
                Button("Slett", role: .destructive) {
                    Task {
                        await viewModel.remove(id: garment.id)
                        dismiss()
                    }
                }
            } message: {
                Text(viewModel.removalWarning(for: garment))
            }
        }
    }

    // MARK: - Hero

    @ViewBuilder
    private var heroSection: some View {
        VStack(spacing: 12) {
            // Garment visual
            ZStack {
                Circle()
                    .fill(theme.surface)
                    .frame(width: 100, height: 100)
                RoundedRectangle(cornerRadius: 12)
                    .fill(garmentColor)
                    .frame(width: 52, height: 60)
            }

            // Key badge
            if garment.isKeyGarment {
                HStack(spacing: 4) {
                    Image(systemName: "star.fill")
                        .font(.system(size: 10))
                    Text("N\u{00F8}kkelplagg")
                        .font(.dmSans(12, weight: .medium))
                }
                .foregroundStyle(theme.gold)
                .padding(.horizontal, 10)
                .padding(.vertical, 4)
                .background(Capsule().fill(theme.gold.opacity(0.12)))
            }

            // Tags
            HStack(spacing: 8) {
                detailTag(garment.category.rawValue.capitalized)
                detailTag(garment.silhouette.rawValue.capitalized)
                detailTag(garment.baseGroup.rawValue.capitalized)
            }
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 20)
    }

    // MARK: - Role

    @ViewBuilder
    private var roleSection: some View {
        let role = KeyGarmentResolver.role(
            for: garment,
            in: viewModel.garments,
            profile: viewModel.profile
        )

        VStack(alignment: .leading, spacing: 10) {
            Text("Rolle i garderoben")
                .font(.dmSans(13, weight: .semibold))
                .foregroundStyle(theme.text3)

            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text("\(role.combinationCount) kombinasjoner")
                        .font(.instrumentSerif(24))
                        .foregroundStyle(theme.text)
                    Text("\(role.strongCombinationCount) sterke")
                        .font(.dmSans(13))
                        .foregroundStyle(theme.sage)
                }
                Spacer()
                // Ring indicator
                ZStack {
                    Circle()
                        .stroke(theme.surface, lineWidth: 6)
                        .frame(width: 56, height: 56)
                    Circle()
                        .trim(from: 0, to: role.combinationPercentage)
                        .stroke(theme.gold, style: StrokeStyle(lineWidth: 6, lineCap: .round))
                        .frame(width: 56, height: 56)
                        .rotationEffect(.degrees(-90))
                    Text("\(Int(role.combinationPercentage * 100))%")
                        .font(.dmSans(12, weight: .medium))
                        .foregroundStyle(theme.text2)
                }
            }

            Text(role.roleDescriptor)
                .font(.dmSans(13))
                .foregroundStyle(theme.text2)
        }
        .padding(COREDesign.spacing)
        .glassCard()
    }

    // MARK: - Removal Simulation

    @ViewBuilder
    private var removalSection: some View {
        let projection = viewModel.projectionForRemoving(garment)

        VStack(alignment: .leading, spacing: 10) {
            Text("Hvis fjernet")
                .font(.dmSans(13, weight: .semibold))
                .foregroundStyle(theme.text3)

            HStack {
                impactItem(
                    label: "Klarhet",
                    value: String(format: "%.1f", projection.clarityDelta),
                    isNegative: projection.clarityDelta < 0
                )
                Spacer()
                impactItem(
                    label: "Kombo tap",
                    value: "\(projection.combinationsLost)",
                    isNegative: projection.combinationsLost > 0
                )
                Spacer()
                impactItem(
                    label: "Hull \u{00E5}pnet",
                    value: "\(projection.gapsOpened.count)",
                    isNegative: !projection.gapsOpened.isEmpty
                )
            }
        }
        .padding(COREDesign.spacing)
        .glassCard()
    }

    @ViewBuilder
    private func impactItem(label: String, value: String, isNegative: Bool) -> some View {
        VStack(spacing: 4) {
            Text(value)
                .font(.instrumentSerif(22))
                .foregroundStyle(isNegative ? Color.coretRed : theme.sage)
            Text(label)
                .font(.dmSans(11))
                .foregroundStyle(theme.text3)
        }
    }

    // MARK: - Delete

    @ViewBuilder
    private var deleteButton: some View {
        Button {
            showDeleteConfirmation = true
        } label: {
            HStack(spacing: 6) {
                Image(systemName: "trash")
                Text("Slett plagg")
            }
            .font(.dmSans(14, weight: .medium))
            .foregroundStyle(Color.coretRed)
            .frame(maxWidth: .infinity)
            .padding(.vertical, 14)
            .background {
                RoundedRectangle(cornerRadius: COREDesign.cornerRadiusSmall)
                    .fill(Color.coretRed.opacity(0.08))
            }
        }
    }

    // MARK: - Helpers

    @ViewBuilder
    private func detailTag(_ text: String) -> some View {
        Text(text)
            .font(.dmSans(11, weight: .medium))
            .foregroundStyle(theme.text2)
            .padding(.horizontal, 10)
            .padding(.vertical, 4)
            .background(Capsule().fill(theme.surface))
    }

    private var garmentColor: Color {
        let hex = garment.dominantColor
        guard !hex.isEmpty, hex != "#000000" else { return theme.surface }
        return Color(hex: String(hex.dropFirst()))
    }
}
