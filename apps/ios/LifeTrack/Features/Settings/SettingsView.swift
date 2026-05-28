import SwiftUI
import SwiftData

struct SettingsView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.lifeTrackServices) private var services
    @State private var statusMessage = "Permissions are requested only when you enable a source."
    @State private var supabaseState: SupabaseConfigurationState = .missing
    @State private var authState: AuthSessionState = .unconfigured
    @State private var authMode: AuthMode = .signIn
    @State private var email = ""
    @State private var password = ""
    @State private var isSubmittingAuth = false

    var body: some View {
        NavigationStack {
            List {
                Section("Account") {
                    supabaseStatusRow
                    authPanel
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
                        Task { await run("Sync") { try await services.sync.syncPendingChanges(modelContext: modelContext) } }
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
                authState = await services.auth.sessionState()
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

    private var authPanel: some View {
        VStack(alignment: .leading, spacing: Brand.Spacing.sm) {
            Text(authStatusText)
                .font(.caption)
                .foregroundStyle(Brand.ColorToken.moss)

            if case .signedIn = authState {
                Button {
                    Task { await signOut() }
                } label: {
                    Label("Sign out", systemImage: "rectangle.portrait.and.arrow.right")
                }
                .disabled(isSubmittingAuth)
            } else {
                Picker("Auth mode", selection: $authMode) {
                    ForEach(AuthMode.allCases) { mode in
                        Text(mode.rawValue).tag(mode)
                    }
                }
                .pickerStyle(.segmented)

                TextField("Email", text: $email)
                    .textInputAutocapitalization(.never)
                    .keyboardType(.emailAddress)
                    .textContentType(.emailAddress)

                SecureField("Password", text: $password)
                    .textContentType(authMode == .signUp ? .newPassword : .password)

                Button {
                    Task { await submitAuth() }
                } label: {
                    Label(authMode.rawValue, systemImage: authMode == .signIn ? "person.crop.circle" : "person.badge.plus")
                }
                .disabled(isSubmittingAuth || supabaseState == .missing)
            }
        }
    }

    private var authStatusText: String {
        switch authState {
        case .unconfigured:
            return "Cloud account unavailable until Supabase is configured."
        case .signedOut:
            return "Sign in to prepare cloud sync."
        case .signedIn(let email):
            return "Signed in\(email.map { " as \($0)" } ?? "")."
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

    private func submitAuth() async {
        isSubmittingAuth = true
        defer { isSubmittingAuth = false }

        do {
            authState = try await services.auth.submit(mode: authMode, email: email, password: password)
            password = ""
            statusMessage = "\(authMode.rawValue) completed."
        } catch {
            statusMessage = "\(authMode.rawValue) failed: \(error.localizedDescription)"
        }
    }

    private func signOut() async {
        isSubmittingAuth = true
        defer { isSubmittingAuth = false }

        do {
            authState = try await services.auth.signOut()
            password = ""
            statusMessage = "Signed out."
        } catch {
            statusMessage = "Sign out failed: \(error.localizedDescription)"
        }
    }
}
