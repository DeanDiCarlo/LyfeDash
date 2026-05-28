import SwiftUI

struct LifeTrackServices {
    var health: HealthMetricsProviding
    var screenTime: ScreenTimeProviding
    var photos: PhotoImporting
    var location: LocationProviding
    var supabase: SupabaseConnectionProviding
    var auth: AuthProviding
    var recall: RecallSearching
    var sync: SyncCoordinating

    static let live = LifeTrackServices(
        health: makeHealthProvider(),
        screenTime: StubScreenTimeProvider(),
        photos: StubPhotoImporter(),
        location: StubLocationProvider(),
        supabase: SupabaseConnectionService(),
        auth: makeAuthProvider(),
        recall: StubRecallSearchService(),
        sync: StubSyncCoordinator()
    )

    private static func makeHealthProvider() -> HealthMetricsProviding {
        #if canImport(HealthKit)
        HealthKitMetricsProvider()
        #else
        StubHealthMetricsProvider()
        #endif
    }

    private static func makeAuthProvider() -> AuthProviding {
        #if canImport(Supabase)
        SupabaseAuthService()
        #else
        StubAuthService()
        #endif
    }
}

private struct LifeTrackServicesKey: EnvironmentKey {
    static let defaultValue = LifeTrackServices.live
}

extension EnvironmentValues {
    var lifeTrackServices: LifeTrackServices {
        get { self[LifeTrackServicesKey.self] }
        set { self[LifeTrackServicesKey.self] = newValue }
    }
}
