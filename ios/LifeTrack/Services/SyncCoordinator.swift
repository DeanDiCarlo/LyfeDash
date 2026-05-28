import Foundation

protocol SyncCoordinating {
    func syncPendingChanges() async throws
}

struct StubSyncCoordinator: SyncCoordinating {
    func syncPendingChanges() async throws {}
}

