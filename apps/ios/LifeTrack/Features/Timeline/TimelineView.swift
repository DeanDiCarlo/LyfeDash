import SwiftUI
import SwiftData

struct TimelineView: View {
    @Query(sort: \JournalEntry.createdAt, order: .reverse) private var entries: [JournalEntry]

    var body: some View {
        NavigationStack {
            List {
                if entries.isEmpty {
                    ContentUnavailableView("No pinned days", systemImage: "pin", description: Text("Journal entries will build your timeline."))
                } else {
                    ForEach(entries) { entry in
                        VStack(alignment: .leading, spacing: Brand.Spacing.xs) {
                            Text(entry.dayKey)
                                .font(.caption.weight(.semibold))
                                .foregroundStyle(Brand.ColorToken.copper)
                            Text(entry.body)
                                .foregroundStyle(Brand.ColorToken.forestInk)
                        }
                    }
                }
            }
            .scrollContentBackground(.hidden)
            .background(Brand.ColorToken.paper)
            .navigationTitle("Timeline")
        }
    }
}

