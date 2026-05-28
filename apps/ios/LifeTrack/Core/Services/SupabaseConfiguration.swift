import Foundation

struct SupabaseConfiguration: Equatable {
    let url: URL
    let anonKey: String

    static func load(bundle: Bundle = .main) -> SupabaseConfiguration? {
        guard let secretsURL = bundle.url(forResource: "SupabaseSecrets", withExtension: "plist"),
              let data = try? Data(contentsOf: secretsURL),
              let plist = try? PropertyListSerialization.propertyList(from: data, options: [], format: nil),
              let dictionary = plist as? [String: Any],
              let urlString = dictionary["SUPABASE_URL"] as? String,
              let url = URL(string: urlString),
              let anonKey = dictionary["SUPABASE_ANON_KEY"] as? String,
              !anonKey.isEmpty else {
            return nil
        }

        return SupabaseConfiguration(url: url, anonKey: anonKey)
    }
}

enum SupabaseConfigurationState: Equatable {
    case configured(projectHost: String)
    case missing
}

protocol SupabaseConnectionProviding {
    func configurationState() -> SupabaseConfigurationState
}

struct SupabaseConnectionService: SupabaseConnectionProviding {
    private let configuration: SupabaseConfiguration?

    init(configuration: SupabaseConfiguration? = SupabaseConfiguration.load()) {
        self.configuration = configuration
    }

    func configurationState() -> SupabaseConfigurationState {
        guard let configuration else {
            return .missing
        }

        return .configured(projectHost: configuration.url.host ?? configuration.url.absoluteString)
    }
}

struct StubSupabaseConnectionService: SupabaseConnectionProviding {
    func configurationState() -> SupabaseConfigurationState {
        .missing
    }
}

