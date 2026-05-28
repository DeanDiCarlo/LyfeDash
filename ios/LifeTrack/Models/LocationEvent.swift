import Foundation
import SwiftData

enum LocationEventKind: String, Codable, CaseIterable {
    case journal
    case photo
    case significantVisit
    case manualCheckIn
}

@Model
final class LocationEvent {
    @Attribute(.unique) var id: UUID
    var dayKey: String
    var kind: LocationEventKind
    var latitude: Double
    var longitude: Double
    var horizontalAccuracy: Double?
    var createdAt: Date
    var remoteID: UUID?
    var syncState: SyncState

    init(dayKey: String, kind: LocationEventKind, latitude: Double, longitude: Double) {
        self.id = UUID()
        self.dayKey = dayKey
        self.kind = kind
        self.latitude = latitude
        self.longitude = longitude
        self.createdAt = Date()
        self.syncState = .pending
    }
}

