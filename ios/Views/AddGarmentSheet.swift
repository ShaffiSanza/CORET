import SwiftUI
import COREEngine

struct AddGarmentSheet: View {
    @Bindable var viewModel: WardrobeViewModel
    @Environment(\.theme) private var theme
    @Environment(\.dismiss) private var dismiss

    // Form state
    @State private var name: String = ""
    @State private var category: Category = .upper
    @State private var silhouette: Silhouette = .regular
    @State private var baseGroup: BaseGroup = .tee
    @State private var temperature: Int = 3
    @State private var colorTemperature: ColorTemp = .neutral
    @State private var dominantColor: String = "#000000"
    @State private var brand: String = ""

    // Input method state
    @State private var showSearch = false
    @State private var showBarcode = false
    @State private var showCamera = false
    @State private var showImport = false

    // Processing
    @State private var isProcessing = false
    @State private var statusMessage: String?

    var body: some View {
        NavigationStack {
            Form {
                // Entry methods
                Section {
                    Button { showSearch = true } label: {
                        Label("S\u{00F8}k etter produkt", systemImage: "magnifyingglass")
                    }
                    Button { showBarcode = true } label: {
                        Label("Skann strekkode", systemImage: "barcode.viewfinder")
                    }
                    Button { showCamera = true } label: {
                        Label("Ta bilde", systemImage: "camera")
                    }
                    Button { showImport = true } label: {
                        Label("Importer garderobe", systemImage: "square.and.arrow.down")
                    }
                } header: {
                    Text("Legg til med")
                }

                // Manual form
                Section("Plagg") {
                    TextField("Navn", text: $name)
                    if !brand.isEmpty {
                        HStack {
                            Text("Merke")
                            Spacer()
                            Text(brand).foregroundStyle(theme.text2)
                        }
                    }

                    Picker("Kategori", selection: $category) {
                        ForEach(Category.allCases, id: \.self) { cat in
                            Text(cat.rawValue.capitalized).tag(cat)
                        }
                    }

                    Picker("Type", selection: $baseGroup) {
                        ForEach(BaseGroup.allCases, id: \.self) { bg in
                            Text(bg.rawValue.capitalized).tag(bg)
                        }
                    }

                    Picker("Silhuett", selection: $silhouette) {
                        ForEach(Silhouette.allCases, id: \.self) { sil in
                            Text(sil.rawValue.capitalized).tag(sil)
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

                if let status = statusMessage {
                    Section {
                        HStack {
                            if isProcessing {
                                ProgressView().scaleEffect(0.8)
                            } else {
                                Image(systemName: "checkmark.circle.fill")
                                    .foregroundStyle(theme.sage)
                            }
                            Text(status)
                                .font(.dmSans(13))
                                .foregroundStyle(theme.text2)
                        }
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
                    .disabled(isProcessing)
                }
            }
            .sheet(isPresented: $showSearch) {
                ProductSearchSheet { result in
                    applySearchResult(result)
                }
            }
            .sheet(isPresented: $showBarcode) {
                BarcodeScannerSheet { result in
                    applyBarcodeResult(result)
                }
            }
            .sheet(isPresented: $showCamera) {
                CameraCaptureSheet(viewModel: viewModel) { garmentId, imageData in
                    await uploadImage(garmentId: garmentId, imageData: imageData)
                }
            }
            .sheet(isPresented: $showImport) {
                ImportSheet(viewModel: viewModel)
            }
        }
    }

    // MARK: - Apply Results

    private func applySearchResult(_ result: APIClient.ProductSearchResponse) {
        if let title = result.productTitle {
            name = title
        }
        if let b = result.brand {
            brand = b
        }
        // Enrich with metadata
        Task {
            await enrichFromTitle()
        }
    }

    private func applyBarcodeResult(_ result: APIClient.BarcodeLookupResponse) {
        if let title = result.productTitle {
            name = title
        }
        if let b = result.brand {
            brand = b
        }
        if let cat = result.category {
            if let parsed = Category(rawValue: cat.lowercased()) {
                category = parsed
            }
        }
        Task {
            await enrichFromTitle()
        }
    }

    private func enrichFromTitle() async {
        guard !name.isEmpty else { return }
        isProcessing = true
        statusMessage = "Analyserer plagg..."
        do {
            let meta = try await APIClient.shared.extractMetadata(
                productTitle: name,
                brand: brand.isEmpty ? nil : brand
            )
            if let cat = meta.category, let parsed = Category(rawValue: cat) {
                category = parsed
            }
            if let bg = meta.baseGroup, let parsed = BaseGroup(rawValue: bg) {
                baseGroup = parsed
            }
            if let sil = meta.silhouette, let parsed = Silhouette(rawValue: sil) {
                silhouette = parsed
            }
            if let ct = meta.colorTemperature, let parsed = ColorTemp(rawValue: ct) {
                colorTemperature = parsed
            }
            statusMessage = "Ferdig — sjekk felter"
        } catch {
            statusMessage = "Fyll ut manuelt"
        }
        isProcessing = false
    }

    private func uploadImage(garmentId: UUID, imageData: Data) async {
        isProcessing = true
        statusMessage = "Laster opp bilde..."
        do {
            let result = try await APIClient.shared.uploadImage(garmentId: garmentId, imageData: imageData)
            if let color = result.colors?.dominantColor {
                dominantColor = color
            }
            if let ct = result.colors?.colorTemperature, let parsed = ColorTemp(rawValue: ct) {
                colorTemperature = parsed
            }
            statusMessage = "Bilde lastet opp"
        } catch {
            statusMessage = "Bildeopplasting feilet"
        }
        isProcessing = false
    }

    private func buildGarment() -> Garment {
        Garment(
            id: UUID(),
            name: name.isEmpty ? baseGroup.rawValue.capitalized : name,
            category: category,
            silhouette: silhouette,
            baseGroup: baseGroup,
            temperature: temperature,
            colorTemperature: colorTemperature,
            dominantColor: dominantColor,
            brand: brand.isEmpty ? nil : brand
        )
    }

    private func projectionLabel(_ delta: Double) -> String {
        if delta > 0 { return "+\(String(format: "%.1f", delta))" }
        if delta < 0 { return String(format: "%.1f", delta) }
        return "0"
    }
}
