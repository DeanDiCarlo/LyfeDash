import SwiftUI
import SwiftData

struct TimelineView: View {
    @Environment(\.modelContext) private var modelContext
    @Query(sort: \JournalEntry.createdAt, order: .reverse) private var entries: [JournalEntry]
    @State private var editingEntry: JournalEntry?
    @State private var editingText = ""

    private var visibleEntries: [JournalEntry] {
        entries.filter { $0.deletedAt == nil }
    }

    var body: some View {
        NavigationStack {
            List {
                if visibleEntries.isEmpty {
                    ContentUnavailableView("No pinned days", systemImage: "pin", description: Text("Journal entries will build your timeline."))
                } else {
                    ForEach(visibleEntries) { entry in
                        VStack(alignment: .leading, spacing: Brand.Spacing.xs) {
                            Text(entry.dayKey)
                                .font(.caption.weight(.semibold))
                                .foregroundStyle(Brand.ColorToken.copper)
                            Text(entry.body)
                                .foregroundStyle(Brand.ColorToken.forestInk)
                            Text(entry.syncState.rawValue.capitalized)
                                .font(.caption2)
                                .foregroundStyle(Brand.ColorToken.moss)
                        }
                        .swipeActions(edge: .leading) {
                            Button {
                                beginEditing(entry)
                            } label: {
                                Label("Edit", systemImage: "pencil")
                            }
                            .tint(Brand.ColorToken.copper)
                        }
                        .swipeActions {
                            Button(role: .destructive) {
                                delete(entry)
                            } label: {
                                Label("Delete", systemImage: "trash")
                            }
                        }
                    }
                }
            }
            .scrollContentBackground(.hidden)
            .background(Brand.ColorToken.paper)
            .navigationTitle("Timeline")
            .sheet(item: $editingEntry) { entry in
                NavigationStack {
                    Form {
                        TextField("Entry", text: $editingText, axis: .vertical)
                            .lineLimit(2...5)
                    }
                    .navigationTitle("Edit entry")
                    .toolbar {
                        ToolbarItem(placement: .cancellationAction) {
                            Button("Cancel") {
                                editingEntry = nil
                            }
                        }
                        ToolbarItem(placement: .confirmationAction) {
                            Button("Save") {
                                saveEdit(entry)
                            }
                            .disabled(editingText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
                        }
                    }
                }
            }
        }
    }

    private func beginEditing(_ entry: JournalEntry) {
        editingEntry = entry
        editingText = entry.body
    }

    private func saveEdit(_ entry: JournalEntry) {
        let trimmed = editingText.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return }
        entry.updateBody(trimmed)
        try? modelContext.save()
        editingEntry = nil
    }

    private func delete(_ entry: JournalEntry) {
        entry.markDeleted()
        try? modelContext.save()
    }
}
