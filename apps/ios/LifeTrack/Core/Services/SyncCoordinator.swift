import Foundation
import SwiftData

protocol SyncCoordinating {
    @MainActor
    func syncJournal(modelContext: ModelContext) async throws -> SyncSummary
}

struct StubSyncCoordinator: SyncCoordinating {
    @MainActor
    func syncJournal(modelContext: ModelContext) async throws -> SyncSummary {
        SyncSummary()
    }
}

struct SyncSummary: Equatable {
    var uploaded: Int = 0
    var downloaded: Int = 0
    var deleted: Int = 0
}
