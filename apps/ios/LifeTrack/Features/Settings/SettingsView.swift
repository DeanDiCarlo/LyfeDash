import SwiftUI

struct SettingsView: View {
    @Environment(\.lifeTrackServices) private var services
    @State private var statusMessage = "Permissions are requested only when you enable a source."

    var body: some View {
        NavigationStack {
            List {
                Section("Apple sources") {
                    Button("Connect Health") {
                        Task { await run("Health") { try await services.health.requestAuthorization() } }
                    }
                    Button("Connect Screen Time") {
                        Task { await run("Screen Time") { try await services.screenTime.requestAuthorization() } }
                    }
                    Button("Connect Photos") {
                        Task { await run("Photos") { try await services.photos.requestAuthorization() } }
                    }
                    Button("Enable Location Memory") {
                        Task { await run("Location") { try await services.location.requestAlwaysAuthorization() } }
                    }
                }

                Section("Sync") {
                    Button("Sync pending changes") {
                        Task { await run("Sync") { try await services.sync.syncPendingChanges() } }
                    }
                }

                Section("Status") {
                    Text(statusMessage)
                        .foregroundStyle(Brand.ColorToken.moss)
                }
            }
            .scrollContentBackground(.hidden)
            .background(Brand.ColorToken.paper)
            .navigationTitle("Settings")
        }
    }

    private func run(_ label: String, operation: () async throws -> Void) async {
        do {
            try await operation()
            statusMessage = "\(label) completed."
        } catch {
            statusMessage = "\(label) failed: \(error.localizedDescription)"
        }
    }
}

