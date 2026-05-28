import SwiftUI

struct RootTabView: View {
    var body: some View {
        TabView {
            TodayView()
                .tabItem {
                    Label("Today", systemImage: "sun.max")
                }

            TimelineView()
                .tabItem {
                    Label("Timeline", systemImage: "calendar")
                }

            TasksView()
                .tabItem {
                    Label("Tasks", systemImage: "checklist")
                }

            MemoriesView()
                .tabItem {
                    Label("Recall", systemImage: "sparkle.magnifyingglass")
                }

            SettingsView()
                .tabItem {
                    Label("Settings", systemImage: "gearshape")
                }
        }
        .tint(Brand.ColorToken.copper)
    }
}

