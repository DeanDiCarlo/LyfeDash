import Foundation

struct DailyHealthMetrics {
    var steps: Int?
    var sleepMinutes: Int?
}

protocol HealthMetricsProviding {
    func requestAuthorization() async throws
    func metrics(for dayKey: String) async throws -> DailyHealthMetrics
}

protocol ScreenTimeProviding {
    func requestAuthorization() async throws
    func dailyTotalMinutes(for dayKey: String) async throws -> Int?
}

struct ImportedPhotoCandidate: Identifiable {
    var id: String
    var capturedAt: Date?
    var latitude: Double?
    var longitude: Double?
    var kind: MediaKind
}

protocol PhotoImporting {
    func requestAuthorization() async throws
    func recentCandidates(limit: Int) async throws -> [ImportedPhotoCandidate]
}

protocol LocationProviding {
    func requestAlwaysAuthorization() async throws
    func currentLocationEvent(dayKey: String) async throws -> LocationEvent?
}

