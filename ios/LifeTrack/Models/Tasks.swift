import Foundation
import SwiftData

enum RecurrenceKind: String, Codable, CaseIterable {
    case daily
    case weekdays
    case weekly
    case adHoc
}

@Model
final class TaskTemplate {
    @Attribute(.unique) var id: UUID
    var title: String
    var recurrence: RecurrenceKind
    var createdAt: Date
    var archivedAt: Date?
    var remoteID: UUID?
    var syncState: SyncState

    init(title: String, recurrence: RecurrenceKind) {
        self.id = UUID()
        self.title = title
        self.recurrence = recurrence
        self.createdAt = Date()
        self.syncState = .pending
    }
}

@Model
final class TaskInstance {
    @Attribute(.unique) var id: UUID
    var templateID: UUID
    var dayKey: String
    var titleSnapshot: String
    var completedAt: Date?
    var remoteID: UUID?
    var syncState: SyncState

    init(templateID: UUID, dayKey: String, titleSnapshot: String) {
        self.id = UUID()
        self.templateID = templateID
        self.dayKey = dayKey
        self.titleSnapshot = titleSnapshot
        self.syncState = .pending
    }
}

