import Foundation
import SwiftData

@Model
final class DailyMetricAggregate {
    @Attribute(.unique) var id: UUID
    var dayKey: String
    var steps: Int?
    var sleepMinutes: Int?
    var screenTimeMinutes: Int?
    var updatedAt: Date
    var remoteID: UUID?
    var syncState: SyncState

    init(dayKey: String) {
        self.id = UUID()
        self.dayKey = dayKey
        self.updatedAt = Date()
        self.syncState = .pending
    }
}

