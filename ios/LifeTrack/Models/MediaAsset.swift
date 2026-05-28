import Foundation
import SwiftData

enum MediaKind: String, Codable, CaseIterable {
    case image
    case video
}

enum AIProcessingState: String, Codable, CaseIterable {
    case notQueued
    case queued
    case processing
    case complete
    case failed
}

@Model
final class MediaAsset {
    @Attribute(.unique) var id: UUID
    var dayKey: String
    var kind: MediaKind
    var localPhotoAssetIdentifier: String?
    var storagePath: String?
    var thumbnailStoragePath: String?
    var capturedAt: Date?
    var durationSeconds: Double?
    var latitude: Double?
    var longitude: Double?
    var aiState: AIProcessingState
    var remoteID: UUID?
    var syncState: SyncState

    init(dayKey: String, kind: MediaKind) {
        self.id = UUID()
        self.dayKey = dayKey
        self.kind = kind
        self.aiState = .notQueued
        self.syncState = .pending
    }
}

