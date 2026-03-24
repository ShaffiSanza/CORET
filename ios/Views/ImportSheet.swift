import SwiftUI
import COREEngine

struct ImportSheet: View {
    let viewModel: WardrobeViewModel
    @Environment(\.theme) private var theme
    @Environment(\.dismiss) private var dismiss

    @State private var pastedText = ""
    @State private var parsedItems: [ParsedItem] = []
    @State private var isImporting = false
    @State private var result: ImportResult?

    struct ParsedItem: Identifiable {
        let id = UUID()
        var name: String
        var category: String
        var baseGroup: String
        var isSelected: Bool = true
    }

    struct ImportResult {
        let imported: Int
        let warnings: [String]
    }

    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                if result != nil {
                    resultView
                } else if !parsedItems.isEmpty {
                    reviewView
                } else {
                    inputView
                }
            }
            .background(theme.bg)
            .navigationTitle("Importer")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Avbryt") { dismiss() }
                }
            }
        }
    }

    // MARK: - Input

    @ViewBuilder
    private var inputView: some View {
        VStack(spacing: 20) {
            Spacer()

            Image(systemName: "square.and.arrow.down")
                .font(.system(size: 48))
                .foregroundStyle(theme.text4)

            Text("Importer garderobe")
                .font(.instrumentSerif(22))
                .foregroundStyle(theme.text)

            Text("Lim inn en liste med plagg.\nEtt plagg per linje: navn, type")
                .font(.dmSans(13))
                .foregroundStyle(theme.text3)
                .multilineTextAlignment(.center)

            TextEditor(text: $pastedText)
                .font(.dmSans(13))
                .frame(height: 160)
                .padding(8)
                .background {
                    RoundedRectangle(cornerRadius: 12)
                        .fill(theme.surface)
                }
                .padding(.horizontal, 20)

            Button {
                parseInput()
            } label: {
                Text("Analyser liste")
                    .font(.dmSans(14, weight: .medium))
                    .foregroundStyle(theme.bg)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 14)
                    .background(RoundedRectangle(cornerRadius: 10).fill(theme.gold))
            }
            .disabled(pastedText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
            .opacity(pastedText.isEmpty ? 0.5 : 1)
            .padding(.horizontal, 20)

            Spacer()
        }
    }

    // MARK: - Review

    @ViewBuilder
    private var reviewView: some View {
        List {
            Section {
                ForEach($parsedItems) { $item in
                    HStack {
                        Button {
                            item.isSelected.toggle()
                        } label: {
                            Image(systemName: item.isSelected ? "checkmark.circle.fill" : "circle")
                                .foregroundStyle(item.isSelected ? theme.gold : theme.text4)
                        }

                        VStack(alignment: .leading, spacing: 2) {
                            Text(item.name)
                                .font(.dmSans(14, weight: .medium))
                                .foregroundStyle(theme.text)
                            HStack(spacing: 6) {
                                Text(item.category)
                                    .font(.dmSans(11))
                                    .foregroundStyle(theme.text3)
                                Text(item.baseGroup)
                                    .font(.dmSans(11))
                                    .foregroundStyle(theme.text3)
                            }
                        }
                    }
                }
            } header: {
                Text("\(parsedItems.filter(\.isSelected).count) av \(parsedItems.count) valgt")
            }
        }
        .listStyle(.insetGrouped)
        .safeAreaInset(edge: .bottom) {
            Button {
                Task { await importSelected() }
            } label: {
                HStack {
                    if isImporting {
                        ProgressView().tint(theme.bg)
                    }
                    Text("Importer \(parsedItems.filter(\.isSelected).count) plagg")
                }
                .font(.dmSans(14, weight: .medium))
                .foregroundStyle(theme.bg)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 14)
                .background(RoundedRectangle(cornerRadius: 10).fill(theme.gold))
            }
            .disabled(isImporting || parsedItems.filter(\.isSelected).isEmpty)
            .padding(16)
            .background(.ultraThinMaterial)
        }
    }

    // MARK: - Result

    @ViewBuilder
    private var resultView: some View {
        if let result {
            VStack(spacing: 20) {
                Spacer()

                Image(systemName: "checkmark.circle.fill")
                    .font(.system(size: 48))
                    .foregroundStyle(theme.sage)

                Text("\(result.imported) plagg importert")
                    .font(.instrumentSerif(24))
                    .foregroundStyle(theme.text)

                if !result.warnings.isEmpty {
                    VStack(alignment: .leading, spacing: 4) {
                        ForEach(result.warnings, id: \.self) { warning in
                            HStack(alignment: .top, spacing: 6) {
                                Image(systemName: "exclamationmark.triangle")
                                    .font(.system(size: 10))
                                    .foregroundStyle(Color.coretAmber)
                                Text(warning)
                                    .font(.dmSans(12))
                                    .foregroundStyle(theme.text3)
                            }
                        }
                    }
                    .padding(12)
                    .background {
                        RoundedRectangle(cornerRadius: 10)
                            .fill(Color.coretAmber.opacity(0.08))
                    }
                    .padding(.horizontal, 20)
                }

                Button("Ferdig") { dismiss() }
                    .font(.dmSans(14, weight: .medium))
                    .foregroundStyle(theme.gold)

                Spacer()
            }
        }
    }

    // MARK: - Logic

    private func parseInput() {
        let lines = pastedText.components(separatedBy: .newlines)
            .map { $0.trimmingCharacters(in: .whitespaces) }
            .filter { !$0.isEmpty }

        parsedItems = lines.map { line in
            let parts = line.components(separatedBy: ",").map { $0.trimmingCharacters(in: .whitespaces) }
            let name = parts.first ?? line
            let typeGuess = guessBaseGroup(from: name)
            return ParsedItem(
                name: name,
                category: typeGuess.category,
                baseGroup: typeGuess.baseGroup
            )
        }
    }

    private func guessBaseGroup(from name: String) -> (category: String, baseGroup: String) {
        let lower = name.lowercased()
        if lower.contains("jeans") { return ("lower", "jeans") }
        if lower.contains("chinos") || lower.contains("bukse") { return ("lower", "chinos") }
        if lower.contains("shorts") { return ("lower", "shorts") }
        if lower.contains("skj\u{00F8}rt") || lower.contains("skirt") { return ("lower", "skirt") }
        if lower.contains("jakke") || lower.contains("coat") || lower.contains("frakk") { return ("upper", "coat") }
        if lower.contains("blazer") { return ("upper", "blazer") }
        if lower.contains("hoodie") || lower.contains("hettegenser") { return ("upper", "hoodie") }
        if lower.contains("skjorte") || lower.contains("shirt") { return ("upper", "shirt") }
        if lower.contains("t-skjorte") || lower.contains("tee") || lower.contains("t-shirt") { return ("upper", "tee") }
        if lower.contains("genser") || lower.contains("knit") || lower.contains("strikk") { return ("upper", "knit") }
        if lower.contains("sneaker") || lower.contains("sko") { return ("shoes", "sneakers") }
        if lower.contains("boots") || lower.contains("st\u{00F8}vel") { return ("shoes", "boots") }
        if lower.contains("loafer") { return ("shoes", "loafers") }
        if lower.contains("sandal") { return ("shoes", "sandals") }
        if lower.contains("belte") || lower.contains("belt") { return ("accessory", "belt") }
        if lower.contains("skjerf") || lower.contains("scarf") { return ("accessory", "scarf") }
        if lower.contains("veske") || lower.contains("bag") { return ("accessory", "bag") }
        if lower.contains("caps") || lower.contains("cap") || lower.contains("lue") { return ("accessory", "cap") }
        return ("upper", "tee")
    }

    private func importSelected() async {
        isImporting = true
        let selected = parsedItems.filter(\.isSelected)
        let garments = selected.map { item in
            APIClient.ImportRequest.ImportGarment(
                name: item.name,
                category: item.category,
                baseGroup: item.baseGroup,
                colorTemperature: nil,
                dominantColor: nil,
                silhouette: nil
            )
        }
        do {
            let response = try await APIClient.shared.importWardrobe(garments: garments)
            result = ImportResult(imported: response.imported, warnings: response.warnings)
        } catch {
            // Fallback: add locally
            for item in selected {
                if let cat = Category(rawValue: item.category),
                   let bg = BaseGroup(rawValue: item.baseGroup) {
                    let garment = Garment(
                        id: UUID(),
                        name: item.name,
                        category: cat,
                        baseGroup: bg
                    )
                    await viewModel.add(garment)
                }
            }
            result = ImportResult(imported: selected.count, warnings: ["Importert lokalt (backend utilgjengelig)"])
        }
        isImporting = false
    }
}
