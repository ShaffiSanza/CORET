import SwiftUI

struct ProductSearchSheet: View {
    let onResult: (APIClient.ProductSearchResult) -> Void
    @Environment(\.theme) private var theme
    @Environment(\.dismiss) private var dismiss

    @State private var query = ""
    @State private var results: [APIClient.ProductSearchResult] = []
    @State private var isSearching = false
    @State private var searchTask: Task<Void, Never>?
    @State private var errorMessage: String?

    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                // Search field
                HStack(spacing: 10) {
                    Image(systemName: "magnifyingglass")
                        .foregroundStyle(theme.text3)
                    TextField("S\u{00F8}k produkt, merke, type...", text: $query)
                        .font(.dmSans(15))
                        .autocorrectionDisabled()
                        .textInputAutocapitalization(.never)
                        .onSubmit { triggerSearch() }
                    if isSearching {
                        ProgressView().scaleEffect(0.7)
                    }
                    if !query.isEmpty {
                        Button { query = ""; results = [] } label: {
                            Image(systemName: "xmark.circle.fill")
                                .foregroundStyle(theme.text4)
                        }
                    }
                }
                .padding(14)
                .background {
                    RoundedRectangle(cornerRadius: 12)
                        .fill(theme.surface)
                }
                .padding(.horizontal, 16)
                .padding(.top, 8)

                // Results
                if let error = errorMessage {
                    VStack(spacing: 8) {
                        Spacer()
                        Image(systemName: "wifi.slash")
                            .font(.system(size: 32))
                            .foregroundStyle(theme.text4)
                        Text(error)
                            .font(.dmSans(13))
                            .foregroundStyle(theme.text3)
                        Spacer()
                    }
                } else if results.isEmpty && !query.isEmpty && !isSearching {
                    VStack(spacing: 8) {
                        Spacer()
                        Text("Ingen kl\u{00E6}r funnet")
                            .font(.dmSans(14))
                            .foregroundStyle(theme.text3)
                        Text("Pr\u{00F8}v et annet s\u{00F8}k")
                            .font(.dmSans(12))
                            .foregroundStyle(theme.text4)
                        Spacer()
                    }
                } else {
                    List(results) { result in
                        Button {
                            onResult(result)
                            dismiss()
                        } label: {
                            HStack(spacing: 12) {
                                if let imageUrl = result.imageUrl, let url = URL(string: imageUrl) {
                                    AsyncImage(url: url) { phase in
                                        switch phase {
                                        case .success(let img):
                                            img.resizable()
                                                .scaledToFill()
                                                .frame(width: 56, height: 64)
                                                .clipShape(RoundedRectangle(cornerRadius: 8))
                                        default:
                                            RoundedRectangle(cornerRadius: 8)
                                                .fill(theme.surface)
                                                .frame(width: 56, height: 64)
                                                .overlay { ProgressView().scaleEffect(0.6) }
                                        }
                                    }
                                } else {
                                    RoundedRectangle(cornerRadius: 8)
                                        .fill(theme.surface)
                                        .frame(width: 56, height: 64)
                                        .overlay {
                                            Image(systemName: "tshirt")
                                                .foregroundStyle(theme.text4)
                                        }
                                }
                                VStack(alignment: .leading, spacing: 3) {
                                    Text(result.productTitle ?? "Ukjent produkt")
                                        .font(.dmSans(14, weight: .medium))
                                        .foregroundStyle(theme.text)
                                        .lineLimit(2)
                                    if let brand = result.brand {
                                        Text(brand)
                                            .font(.dmSans(12))
                                            .foregroundStyle(theme.text3)
                                    }
                                }
                                Spacer()
                                Image(systemName: "arrow.right")
                                    .font(.system(size: 12))
                                    .foregroundStyle(theme.text4)
                            }
                            .padding(.vertical, 4)
                        }
                    }
                    .listStyle(.plain)
                }
            }
            .background(theme.bg)
            .navigationTitle("Produkts\u{00F8}k")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Avbryt") { dismiss() }
                }
            }
            .onChange(of: query) { _, newValue in
                debounceSearch(newValue)
            }
        }
    }

    private func debounceSearch(_ text: String) {
        searchTask?.cancel()
        guard text.count >= 2 else {
            results = []
            return
        }
        searchTask = Task {
            try? await Task.sleep(for: .milliseconds(300))
            guard !Task.isCancelled else { return }
            await triggerSearch()
        }
    }

    @MainActor
    private func triggerSearch() {
        guard !query.isEmpty else { return }
        isSearching = true
        errorMessage = nil
        Task {
            do {
                let response = try await APIClient.shared.productSearch(query: query)
                results = response.results
            } catch {
                errorMessage = "S\u{00F8}ket feilet. Pr\u{00F8}v igjen senere."
                results = []
            }
            isSearching = false
        }
    }
}
