#if canImport(Supabase)
import Foundation
import SwiftData
import Supabase

enum SupabaseSyncError: LocalizedError {
    case missingConfiguration
    case signedOut
    case invalidDayKey(String)

    var errorDescription: String? {
        switch self {
        case .missingConfiguration:
            return "Supabase is not configured."
        case .signedOut:
            return "Sign in before syncing."
        case .invalidDayKey(let dayKey):
            return "Unable to sync invalid day key \(dayKey)."
        }
    }
}

struct SupabaseJournalSyncCoordinator: SyncCoordinating {
    private let client: SupabaseClient?

    init(client: SupabaseClient? = SupabaseClientFactory.configuredClient()) {
        self.client = client
    }

    @MainActor
    func syncPendingChanges(modelContext: ModelContext) async throws {
        guard let client else {
            throw SupabaseSyncError.missingConfiguration
        }

        let session = try await client.auth.session
        let userID = session.user.id.uuidString

        let descriptor = FetchDescriptor<JournalEntry>(sortBy: [SortDescriptor(\.createdAt)])
        let entries = try modelContext.fetch(descriptor)
        let pendingEntries = entries.filter { $0.syncState != .synced }

        guard !pendingEntries.isEmpty else {
            return
        }

        var remoteDayIDs: [String: UUID] = [:]

        for entry in pendingEntries {
            entry.syncState = .syncing
            try modelContext.save()

            do {
                let dayID: UUID
                if let cachedDayID = remoteDayIDs[entry.dayKey] {
                    dayID = cachedDayID
                } else {
                    dayID = try await upsertDay(dayKey: entry.dayKey, userID: userID, client: client)
                    remoteDayIDs[entry.dayKey] = dayID
                }

                let remoteID = try await upsert(entry: entry, dayID: dayID, userID: userID, client: client)
                entry.remoteID = remoteID
                entry.syncState = .synced
                try modelContext.save()
            } catch {
                entry.syncState = .failed
                try? modelContext.save()
                throw error
            }
        }
    }

    private func upsertDay(dayKey: String, userID: String, client: SupabaseClient) async throws -> UUID {
        guard SyncDateFormatter.date(fromDayKey: dayKey) != nil else {
            throw SupabaseSyncError.invalidDayKey(dayKey)
        }

        let payload = DayUpsertPayload(
            userID: userID,
            dateKey: dayKey,
            date: dayKey,
            timezoneIdentifier: TimeZone.current.identifier,
            updatedAt: SyncDateFormatter.timestamp(Date())
        )

        let remoteDay: RemoteIdentifier = try await client
            .from("days")
            .upsert(payload, onConflict: "user_id,date_key")
            .select("id")
            .single()
            .execute()
            .value

        return remoteDay.id
    }

    private func upsert(entry: JournalEntry, dayID: UUID, userID: String, client: SupabaseClient) async throws -> UUID {
        let payload = JournalEntryPayload(entry: entry, dayID: dayID, userID: userID)

        let remoteEntry: RemoteIdentifier = try await client
            .from("journal_entries")
            .upsert(payload, onConflict: "user_id,client_id")
            .select("id")
            .single()
            .execute()
            .value

        return remoteEntry.id
    }
}

private struct RemoteIdentifier: Decodable {
    let id: UUID
}

private struct DayUpsertPayload: Encodable {
    let userID: String
    let dateKey: String
    let date: String
    let timezoneIdentifier: String
    let updatedAt: String

    enum CodingKeys: String, CodingKey {
        case userID = "user_id"
        case dateKey = "date_key"
        case date
        case timezoneIdentifier = "timezone_identifier"
        case updatedAt = "updated_at"
    }
}

private struct JournalEntryPayload: Encodable {
    let userID: String
    let clientID: UUID
    let dayID: UUID
    let body: String
    let latitude: Double?
    let longitude: Double?
    let createdAt: String
    let updatedAt: String

    init(entry: JournalEntry, dayID: UUID, userID: String) {
        self.userID = userID
        self.clientID = entry.id
        self.dayID = dayID
        self.body = entry.body
        self.latitude = entry.latitude
        self.longitude = entry.longitude
        self.createdAt = SyncDateFormatter.timestamp(entry.createdAt)
        self.updatedAt = SyncDateFormatter.timestamp(entry.updatedAt)
    }

    enum CodingKeys: String, CodingKey {
        case userID = "user_id"
        case clientID = "client_id"
        case dayID = "day_id"
        case body
        case latitude
        case longitude
        case createdAt = "created_at"
        case updatedAt = "updated_at"
    }
}

private enum SyncDateFormatter {
    static func date(fromDayKey dayKey: String) -> Date? {
        dayFormatter.date(from: dayKey)
    }

    static func timestamp(_ date: Date) -> String {
        timestampFormatter.string(from: date)
    }

    private static let dayFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.calendar = Calendar(identifier: .gregorian)
        formatter.locale = Locale(identifier: "en_US_POSIX")
        formatter.timeZone = TimeZone(secondsFromGMT: 0)
        formatter.dateFormat = "yyyy-MM-dd"
        return formatter
    }()

    private static let timestampFormatter: ISO8601DateFormatter = {
        let formatter = ISO8601DateFormatter()
        formatter.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
        return formatter
    }()
}
#endif
