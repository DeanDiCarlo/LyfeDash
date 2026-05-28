import Foundation

enum AuthMode: String, CaseIterable, Identifiable {
    case signIn = "Sign in"
    case signUp = "Create account"

    var id: String { rawValue }
}

enum AuthSessionState: Equatable {
    case unconfigured
    case signedOut
    case signedIn(email: String?)
}

protocol AuthProviding {
    func sessionState() async -> AuthSessionState
    func submit(mode: AuthMode, email: String, password: String) async throws -> AuthSessionState
    func signOut() async throws -> AuthSessionState
}

enum AuthServiceError: LocalizedError {
    case missingConfiguration
    case invalidCredentials

    var errorDescription: String? {
        switch self {
        case .missingConfiguration:
            return "Supabase is not configured."
        case .invalidCredentials:
            return "Enter an email and a password with at least 8 characters."
        }
    }
}

struct StubAuthService: AuthProviding {
    func sessionState() async -> AuthSessionState {
        .unconfigured
    }

    func submit(mode: AuthMode, email: String, password: String) async throws -> AuthSessionState {
        throw AuthServiceError.missingConfiguration
    }

    func signOut() async throws -> AuthSessionState {
        .unconfigured
    }
}

