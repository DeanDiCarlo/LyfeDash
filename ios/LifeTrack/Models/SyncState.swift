import Foundation

enum SyncState: String, Codable, CaseIterable {
    case localOnly
    case pending
    case syncing
    case synced
    case failed
}

