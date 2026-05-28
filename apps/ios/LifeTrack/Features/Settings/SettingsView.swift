import SwiftUI

struct SettingsView: View {
    @Environment(\.lifeTrackServices) private var services
    @State private var statusMessage = "Permissions are requested only when you enable a source."
    @State private var supabaseState: SupabaseConfigurationState = .missing

    var body: some View {
        NavigationStack {
            List {
                Section("Account") {
                    supabaseStatusRow
                }

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
            .task {
                supabaseState = services.supabase.configurationState()
            }
        }
    }

    private var supabaseStatusRow: some View {
        HStack {
            Image(systemName: supabaseStatusIcon)
                .foregroundStyle(supabaseStatusColor)

            VStack(alignment: .leading, spacing: Brand.Spacing.xs) {
                Text("Supabase")
                    .foregroundStyle(Brand.ColorToken.forestInk)
                Text(supabaseStatusText)
                    .font(.caption)
                    .foregroundStyle(Brand.ColorToken.moss)
            }
        }
    }

    private var supabaseStatusIcon: String {
        switch supabaseState {
        case .configured:
            return "checkmark.seal.fill"
        case .missing:
            return "exclamationmark.triangle.fill"
        }
    }

    private var supabaseStatusColor: Color {
        switch supabaseState {
        case .configured:
            return Brand.ColorToken.electricTeal
        case .missing:
            return Brand.ColorToken.copper
        }
    }

    private var supabaseStatusText: String {
        switch supabaseState {
        case .configured(let projectHost):
            return "Configured for \(projectHost)"
        case .missing:
            return "Add SupabaseSecrets.plist for cloud sync."
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
