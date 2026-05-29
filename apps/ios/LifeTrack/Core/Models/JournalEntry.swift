import Foundation
import SwiftData

@Model
final class JournalEntry {
    @Attribute(.unique) var id: UUID
    var dayKey: String
    var body: String
    var createdAt: Date
    var updatedAt: Date
    var deletedAt: Date?
    var latitude: Double?
    var longitude: Double?
    var remoteID: UUID?
    var syncState: SyncState

    init(dayKey: String, body: String, createdAt: Date = Date()) {
        self.id = UUID()
        self.dayKey = dayKey
        self.body = body
        self.createdAt = createdAt
        self.updatedAt = createdAt
        self.syncState = .pending
    }

    func updateBody(_ newBody: String, updatedAt: Date = Date()) {
        self.body = newBody
        self.updatedAt = updatedAt
        self.syncState = .pending
    }

    func markDeleted(at deletedAt: Date = Date()) {
        self.deletedAt = deletedAt
        self.updatedAt = deletedAt
        self.syncState = .pending
    }
}
