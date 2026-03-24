import SwiftUI
import COREEngine

struct AddGarmentSheet: View {
    @Bindable var viewModel: WardrobeViewModel
    @Environment(\.theme) private var theme
    @Environment(\.dismiss) private var dismiss

    @State private var name: String = ""
    @State private var category: Category = .upper
    @State private var silhouette: Silhouette = .regular
    @State private var baseGroup: BaseGroup = .tee
    @State private var temperature: Int = 3
    @State private var colorTemperature: ColorTemp = .neutral

    var body: some View {
        NavigationStack {
            Form {
                Section("Plagg") {
                    TextField("Navn (valgfritt)", text: $name)

                    Picker("Kategori", selection: $category) {
                        ForEach(Category.allCases, id: \.self) { cat in
                            Text(cat.rawValue.capitalized).tag(cat)
                        }
                    }

                    Picker("Silhuett", selection: $silhouette) {
                        ForEach(Silhouette.allCases, id: \.self) { sil in
                            Text(sil.rawValue.capitalized).tag(sil)
                        }
                    }

                    Picker("Type", selection: $baseGroup) {
                        ForEach(BaseGroup.allCases, id: \.self) { bg in
                            Text(bg.rawValue.capitalized).tag(bg)
                        }
                    }
                }

                Section("Egenskaper") {
                    Stepper("Temperatur: \(temperature)", value: $temperature, in: 1...5)

                    Picker("Fargetemperatur", selection: $colorTemperature) {
                        ForEach(ColorTemp.allCases, id: \.self) { ct in
                            Text(ct.rawValue.capitalized).tag(ct)
                        }
                    }
                }

                // Projection preview
                Section("Effekt p\u{00E5} garderobe") {
                    let garment = buildGarment()
                    let projection = viewModel.projectionForAdding(garment)
                    HStack {
                        Text("Klarhet")
                        Spacer()
                        Text(projectionLabel(projection.clarityDelta))
                            .foregroundStyle(projection.clarityDelta >= 0 ? theme.sage : Color.coretRed)
                    }
                    HStack {
                        Text("Nye kombinasjoner")
                        Spacer()
                        Text("+\(projection.combinationsGained)")
                            .foregroundStyle(theme.sage)
                    }
                }
            }
            .navigationTitle("Nytt plagg")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Avbryt") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Legg til") {
                        Task {
                            await viewModel.add(buildGarment())
                            dismiss()
                        }
                    }
                    .fontWeight(.semibold)
                }
            }
        }
    }

    private func buildGarment() -> Garment {
        Garment(
            id: UUID(),
            category: category,
            silhouette: silhouette,
            baseGroup: baseGroup,
            temperature: temperature,
            colorTemperature: colorTemperature,
            name: name.isEmpty ? baseGroup.rawValue.capitalized : name
        )
    }

    private func projectionLabel(_ delta: Double) -> String {
        if delta > 0 { return "+\(String(format: "%.1f", delta))" }
        if delta < 0 { return String(format: "%.1f", delta) }
        return "0"
    }
}
