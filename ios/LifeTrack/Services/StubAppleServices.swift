import Foundation

struct StubHealthMetricsProvider: HealthMetricsProviding {
    func requestAuthorization() async throws {}

    func metrics(for dayKey: String) async throws -> DailyHealthMetrics {
        DailyHealthMetrics(steps: nil, sleepMinutes: nil)
    }
}

struct StubScreenTimeProvider: ScreenTimeProviding {
    func requestAuthorization() async throws {}

    func dailyTotalMinutes(for dayKey: String) async throws -> Int? {
        nil
    }
}

struct StubPhotoImporter: PhotoImporting {
    func requestAuthorization() async throws {}

    func recentCandidates(limit: Int) async throws -> [ImportedPhotoCandidate] {
        []
    }
}

struct StubLocationProvider: LocationProviding {
    func requestAlwaysAuthorization() async throws {}

    func currentLocationEvent(dayKey: String) async throws -> LocationEvent? {
        nil
    }
}

