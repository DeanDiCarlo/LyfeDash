import SwiftUI

struct MemoriesView: View {
    @Environment(\.lifeTrackServices) private var services
    @State private var query = ""
    @State private var results: [RecallResult] = []
    @State private var isSearching = false

    var body: some View {
        NavigationStack {
            VStack(spacing: Brand.Spacing.md) {
                PaperCard {
                    VStack(alignment: .leading, spacing: Brand.Spacing.sm) {
                        Text("Memory board")
                            .font(.headline)
                            .foregroundStyle(Brand.ColorToken.forestInk)

                        TextField("Search: low screen time near water", text: $query)
                            .textFieldStyle(.roundedBorder)

                        Button {
                            Task { await search() }
                        } label: {
                            Label("Recall", systemImage: "sparkle.magnifyingglass")
                                .frame(maxWidth: .infinity)
                        }
                        .buttonStyle(.borderedProminent)
                        .tint(Brand.ColorToken.copper)
                        .disabled(query.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty || isSearching)
                    }
                }

                if results.isEmpty {
                    ContentUnavailableView("No connections yet", systemImage: "point.3.connected.trianglepath.dotted", description: Text("Imported memories and AI captions will appear here."))
                } else {
                    List(results) { result in
                        VStack(alignment: .leading) {
                            Text(result.title)
                                .font(.headline)
                            Text(result.excerpt)
                            Text(result.dayKey)
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        }
                    }
                }
            }
            .padding(Brand.Spacing.md)
            .background(Brand.ColorToken.paper.ignoresSafeArea())
            .navigationTitle("Recall")
        }
    }

    private func search() async {
        isSearching = true
        defer { isSearching = false }

        do {
            results = try await services.recall.search(query: query)
        } catch {
            results = []
        }
    }
}

