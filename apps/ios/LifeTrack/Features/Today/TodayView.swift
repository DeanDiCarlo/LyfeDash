import SwiftUI
import SwiftData

struct TodayView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.lifeTrackServices) private var services
    @Query(sort: \JournalEntry.createdAt, order: .reverse) private var entries: [JournalEntry]
    @Query(sort: \TaskTemplate.createdAt, order: .reverse) private var taskTemplates: [TaskTemplate]
    @Query(sort: \TaskInstance.dayKey, order: .reverse) private var taskInstances: [TaskInstance]
    @Query(sort: \DailyMetricAggregate.dayKey, order: .reverse) private var metrics: [DailyMetricAggregate]
    @State private var journalText = ""
    @State private var metricStatus: String?
    @State private var isRefreshingMetrics = false

    private var todayKey: String {
        Day.makeDateKey(for: Date())
    }

    private var todaysEntries: [JournalEntry] {
        entries.filter { $0.dayKey == todayKey && $0.deletedAt == nil }
    }

    private var todaysTasks: [TaskInstance] {
        taskInstances.filter { $0.dayKey == todayKey }
    }

    private var todayMetrics: DailyMetricAggregate? {
        metrics.first { $0.dayKey == todayKey }
    }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: Brand.Spacing.md) {
                    journalComposer
                    metricStrip
                    todayTasks
                    recentEntries
                }
                .padding(Brand.Spacing.md)
            }
            .background(Brand.ColorToken.paper.ignoresSafeArea())
            .navigationTitle("Today")
            .task {
                ensureTodaysTaskInstances()
                await refreshHealthMetrics()
            }
        }
    }

    private var journalComposer: some View {
        PaperCard {
            VStack(alignment: .leading, spacing: Brand.Spacing.sm) {
                Text("One sentence")
                    .font(.headline)
                    .foregroundStyle(Brand.ColorToken.forestInk)

                TextField("What should this day remember?", text: $journalText, axis: .vertical)
                    .textFieldStyle(.plain)
                    .lineLimit(2...4)
                    .padding(Brand.Spacing.sm)
                    .background(Brand.ColorToken.paper)
                    .clipShape(RoundedRectangle(cornerRadius: Brand.Radius.control))

                Button {
                    addJournalEntry()
                } label: {
                    Label("Pin entry", systemImage: "pin")
                        .frame(maxWidth: .infinity)
                }
                .buttonStyle(.borderedProminent)
                .tint(Brand.ColorToken.copper)
                .disabled(journalText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
            }
        }
    }

    private var metricStrip: some View {
        VStack(alignment: .leading, spacing: Brand.Spacing.sm) {
            HStack(spacing: Brand.Spacing.sm) {
                MetricPill(title: "Steps", value: formatNumber(todayMetrics?.steps), icon: "figure.walk")
                MetricPill(title: "Screen", value: formatMinutes(todayMetrics?.screenTimeMinutes), icon: "iphone")
                MetricPill(title: "Sleep", value: formatHours(todayMetrics?.sleepMinutes), icon: "bed.double")
            }

            HStack {
                if let metricStatus {
                    Text(metricStatus)
                        .font(.caption)
                        .foregroundStyle(Brand.ColorToken.moss)
                }

                Spacer()

                Button {
                    Task { await refreshHealthMetrics(requestAuthorization: true) }
                } label: {
                    Label("Refresh", systemImage: "arrow.clockwise")
                        .labelStyle(.iconOnly)
                }
                .buttonStyle(.bordered)
                .tint(Brand.ColorToken.copper)
                .disabled(isRefreshingMetrics)
                .accessibilityLabel("Refresh health metrics")
            }
        }
    }

    private var todayTasks: some View {
        PaperCard {
            VStack(alignment: .leading, spacing: Brand.Spacing.sm) {
                Text("Pinned tasks")
                    .font(.headline)
                    .foregroundStyle(Brand.ColorToken.forestInk)

                if todaysTasks.isEmpty {
                    Text("No tasks pinned for today yet.")
                        .font(.subheadline)
                        .foregroundStyle(Brand.ColorToken.moss)
                } else {
                    ForEach(todaysTasks) { task in
                        Button {
                            toggleTask(task)
                        } label: {
                            HStack {
                                Image(systemName: task.completedAt == nil ? "circle" : "checkmark.circle.fill")
                                    .foregroundStyle(Brand.ColorToken.copper)
                                Text(task.titleSnapshot)
                                    .strikethrough(task.completedAt != nil)
                                    .foregroundStyle(Brand.ColorToken.forestInk)
                                Spacer()
                            }
                        }
                        .buttonStyle(.plain)
                    }
                }
            }
        }
    }

    private var recentEntries: some View {
        PaperCard {
            VStack(alignment: .leading, spacing: Brand.Spacing.sm) {
                Text("Today's notes")
                    .font(.headline)
                    .foregroundStyle(Brand.ColorToken.forestInk)

                if todaysEntries.isEmpty {
                    Text("Start with one sentence.")
                        .font(.subheadline)
                        .foregroundStyle(Brand.ColorToken.moss)
                } else {
                    ForEach(todaysEntries) { entry in
                        VStack(alignment: .leading, spacing: Brand.Spacing.xs) {
                            Text(entry.body)
                                .foregroundStyle(Brand.ColorToken.forestInk)
                                .frame(maxWidth: .infinity, alignment: .leading)
                            Text(entry.syncState.rawValue.capitalized)
                                .font(.caption2)
                                .foregroundStyle(Brand.ColorToken.moss)
                        }
                    }
                }
            }
        }
    }

    private func addJournalEntry() {
        let trimmed = journalText.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return }
        modelContext.insert(JournalEntry(dayKey: todayKey, body: trimmed))
        journalText = ""
    }

    private func refreshHealthMetrics(requestAuthorization: Bool = false) async {
        guard !isRefreshingMetrics else { return }
        isRefreshingMetrics = true
        defer { isRefreshingMetrics = false }

        do {
            if requestAuthorization {
                try await services.health.requestAuthorization()
            }

            let healthMetrics = try await services.health.metrics(for: todayKey)
            let aggregate = todayMetrics ?? DailyMetricAggregate(dayKey: todayKey)
            aggregate.steps = healthMetrics.steps
            aggregate.sleepMinutes = healthMetrics.sleepMinutes
            aggregate.updatedAt = Date()
            aggregate.syncState = .pending

            if todayMetrics == nil {
                modelContext.insert(aggregate)
            }

            try modelContext.save()
            metricStatus = "Health metrics updated."
        } catch {
            metricStatus = error.localizedDescription
        }
    }

    private func ensureTodaysTaskInstances() {
        let existingTemplateIDs = Set(todaysTasks.map(\.templateID))

        for template in taskTemplates where TaskScheduler.isTemplateDue(template, on: Date()) {
            guard !existingTemplateIDs.contains(template.id) else { continue }
            modelContext.insert(TaskInstance(templateID: template.id, dayKey: todayKey, titleSnapshot: template.title))
        }

        try? modelContext.save()
    }

    private func toggleTask(_ task: TaskInstance) {
        task.completedAt = task.completedAt == nil ? Date() : nil
        task.syncState = .pending
        try? modelContext.save()
    }

    private func formatNumber(_ value: Int?) -> String {
        guard let value else { return "--" }
        return value.formatted()
    }

    private func formatMinutes(_ value: Int?) -> String {
        guard let value else { return "--" }
        return "\(value)m"
    }

    private func formatHours(_ value: Int?) -> String {
        guard let value else { return "--" }
        let hours = Double(value) / 60
        return hours.formatted(.number.precision(.fractionLength(1))) + "h"
    }
}

private struct MetricPill: View {
    var title: String
    var value: String
    var icon: String

    var body: some View {
        VStack(alignment: .leading, spacing: Brand.Spacing.xs) {
            Image(systemName: icon)
                .foregroundStyle(Brand.ColorToken.electricTeal)
            Text(value)
                .font(.title3.bold())
                .foregroundStyle(Brand.ColorToken.forestInk)
            Text(title)
                .font(.caption)
                .foregroundStyle(Brand.ColorToken.moss)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(Brand.Spacing.sm)
        .background(Brand.ColorToken.paperElevated)
        .clipShape(RoundedRectangle(cornerRadius: Brand.Radius.card))
    }
}
