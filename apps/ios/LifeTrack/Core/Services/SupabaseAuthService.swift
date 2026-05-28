#if canImport(Supabase)
import Foundation
import Supabase

struct SupabaseAuthService: AuthProviding {
    private let client: SupabaseClient?

    init(client: SupabaseClient? = SupabaseClientFactory.configuredClient()) {
        self.client = client
    }

    func sessionState() async -> AuthSessionState {
        guard let client else {
            return .unconfigured
        }

        guard let session = try? await client.auth.session else {
            return .signedOut
        }

        return .signedIn(email: session.user.email)
    }

    func submit(mode: AuthMode, email: String, password: String) async throws -> AuthSessionState {
        guard let client else {
            throw AuthServiceError.missingConfiguration
        }

        let trimmedEmail = email.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmedEmail.isEmpty, password.count >= 8 else {
            throw AuthServiceError.invalidCredentials
        }

        switch mode {
        case .signIn:
            let session = try await client.auth.signIn(email: trimmedEmail, password: password)
            return .signedIn(email: session.user.email)
        case .signUp:
            let response = try await client.auth.signUp(email: trimmedEmail, password: password)
            return .signedIn(email: response.user.email)
        }
    }

    func signOut() async throws -> AuthSessionState {
        guard let client else {
            throw AuthServiceError.missingConfiguration
        }

        try await client.auth.signOut()
        return .signedOut
    }
}
#endif
