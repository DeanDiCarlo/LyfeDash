import SwiftUI
import SwiftData

@main
struct LifeTrackApp: App {
    private let container: ModelContainer

    init() {
        let schema = Schema([
            Day.self,
            JournalEntry.self,
            TaskTemplate.self,
            TaskInstance.self,
            DailyMetricAggregate.self,
            MediaAsset.self,
            LocationEvent.self
        ])

        do {
            container = try ModelContainer(for: schema)
        } catch {
            fatalError("Unable to initialize Life Track model container: \(error)")
        }
    }

    var body: some Scene {
        WindowGroup {
            RootTabView()
                .environment(\.lifeTrackServices, .live)
        }
        .modelContainer(container)
    }
}

