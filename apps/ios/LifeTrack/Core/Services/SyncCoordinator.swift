import Foundation
import SwiftData

protocol SyncCoordinating {
    @MainActor
    func syncPendingChanges(modelContext: ModelContext) async throws
}

struct StubSyncCoordinator: SyncCoordinating {
    @MainActor
    func syncPendingChanges(modelContext: ModelContext) async throws {}
}
