#if canImport(Supabase)
import Foundation
import Supabase

enum SupabaseClientFactory {
    static func makeClient(configuration: SupabaseConfiguration) -> SupabaseClient {
        SupabaseClient(
            supabaseURL: configuration.url,
            supabaseKey: configuration.anonKey
        )
    }

    static func configuredClient() -> SupabaseClient? {
        guard let configuration = SupabaseConfiguration.load() else {
            return nil
        }

        return makeClient(configuration: configuration)
    }
}
#endif
