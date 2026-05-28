import SwiftUI
import SwiftData

struct TasksView: View {
    @Environment(\.modelContext) private var modelContext
    @Query(sort: \TaskTemplate.createdAt, order: .reverse) private var templates: [TaskTemplate]
    @State private var title = ""
    @State private var recurrence: RecurrenceKind = .daily

    private var activeTemplates: [TaskTemplate] {
        templates.filter { $0.archivedAt == nil }
    }

    var body: some View {
        NavigationStack {
            List {
                Section("New routine") {
                    TextField("Dishes, gym, laundry...", text: $title)
                    Picker("Repeat", selection: $recurrence) {
                        ForEach(RecurrenceKind.allCases, id: \.self) { kind in
                            Text(kind.rawValue.capitalized).tag(kind)
                        }
                    }

                    Button {
                        addTemplate()
                    } label: {
                        Label("Add task", systemImage: "plus")
                    }
                    .disabled(title.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
                }

                Section("Templates") {
                    if activeTemplates.isEmpty {
                        ContentUnavailableView("No routines", systemImage: "checklist")
                    } else {
                        ForEach(activeTemplates) { template in
                            VStack(alignment: .leading) {
                                Text(template.title)
                                Text(template.recurrence.rawValue.capitalized)
                                    .font(.caption)
                                    .foregroundStyle(.secondary)
                            }
                            .swipeActions {
                                Button(role: .destructive) {
                                    archive(template)
                                } label: {
                                    Label("Archive", systemImage: "archivebox")
                                }
                            }
                        }
                    }
                }
            }
            .scrollContentBackground(.hidden)
            .background(Brand.ColorToken.paper)
            .navigationTitle("Tasks")
        }
    }

    private func addTemplate() {
        let trimmed = title.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return }
        let template = TaskTemplate(title: trimmed, recurrence: recurrence)
        modelContext.insert(template)
        modelContext.insert(TaskInstance(templateID: template.id, dayKey: Day.makeDateKey(for: Date()), titleSnapshot: trimmed))
        title = ""
        recurrence = .daily
    }

    private func archive(_ template: TaskTemplate) {
        template.archivedAt = Date()
        template.syncState = .pending
        try? modelContext.save()
    }
}
