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
    func syncJournal(modelContext: ModelContext) async throws -> SyncSummary {
        guard let client else {
            throw SupabaseSyncError.missingConfiguration
        }

        let session = try await client.auth.session
        let userID = session.user.id.uuidString
        var summary = SyncSummary()

        try await uploadLocalChanges(modelContext: modelContext, userID: userID, client: client, summary: &summary)
        try await pullRemoteEntries(modelContext: modelContext, userID: userID, client: client, summary: &summary)

        return summary
    }

    @MainActor
    private func uploadLocalChanges(
        modelContext: ModelContext,
        userID: String,
        client: SupabaseClient,
        summary: inout SyncSummary
    ) async throws {
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

                let remoteID: UUID
                if entry.deletedAt == nil {
                    remoteID = try await upsert(entry: entry, dayID: dayID, userID: userID, client: client)
                    summary.uploaded += 1
                } else {
                    remoteID = try await delete(entry: entry, dayID: dayID, userID: userID, client: client)
                    summary.deleted += 1
                }

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

    @MainActor
    private func pullRemoteEntries(
        modelContext: ModelContext,
        userID: String,
        client: SupabaseClient,
        summary: inout SyncSummary
    ) async throws {
        let remoteEntries: [RemoteJournalEntry] = try await client
            .from("journal_entries")
            .select("id,client_id,body,latitude,longitude,created_at,updated_at,deleted_at,days(date_key)")
            .eq("user_id", value: userID)
            .order("updated_at", ascending: false)
            .execute()
            .value

        let descriptor = FetchDescriptor<JournalEntry>()
        let localEntries = try modelContext.fetch(descriptor)
        let localByClientID = Dictionary(uniqueKeysWithValues: localEntries.map { ($0.id, $0) })
        let localByRemoteID = Dictionary(uniqueKeysWithValues: localEntries.compactMap { entry in
            entry.remoteID.map { ($0, entry) }
        })

        for remote in remoteEntries {
            guard let dayKey = remote.days?.dateKey,
                  let createdAt = SyncDateFormatter.dateTime(from: remote.createdAt),
                  let updatedAt = SyncDateFormatter.dateTime(from: remote.updatedAt) else {
                continue
            }

            let deletedAt = remote.deletedAt.flatMap(SyncDateFormatter.dateTime(from:))
            let local = localByClientID[remote.clientID] ?? localByRemoteID[remote.id]

            if let local {
                guard local.syncState == .synced || local.syncState == .localOnly else {
                    continue
                }

                guard remote.updatedAtDateIsNewer(than: local.updatedAt) else {
                    continue
                }

                local.remoteID = remote.id
                local.dayKey = dayKey
                local.body = remote.body
                local.latitude = remote.latitude
                local.longitude = remote.longitude
                local.createdAt = createdAt
                local.updatedAt = updatedAt
                local.deletedAt = deletedAt
                local.syncState = .synced
                summary.downloaded += 1
            } else {
                let entry = JournalEntry(dayKey: dayKey, body: remote.body, createdAt: createdAt)
                entry.remoteID = remote.id
                entry.updatedAt = updatedAt
                entry.deletedAt = deletedAt
                entry.latitude = remote.latitude
                entry.longitude = remote.longitude
                entry.syncState = .synced
                modelContext.insert(entry)
                summary.downloaded += 1
            }
        }

        try modelContext.save()
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

    private func delete(entry: JournalEntry, dayID: UUID, userID: String, client: SupabaseClient) async throws -> UUID {
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
    let deletedAt: String?
    let createdAt: String
    let updatedAt: String

    init(entry: JournalEntry, dayID: UUID, userID: String) {
        self.userID = userID
        self.clientID = entry.id
        self.dayID = dayID
        self.body = entry.body
        self.latitude = entry.latitude
        self.longitude = entry.longitude
        self.deletedAt = entry.deletedAt.map { SyncDateFormatter.timestamp($0) }
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
        case deletedAt = "deleted_at"
        case createdAt = "created_at"
        case updatedAt = "updated_at"
    }
}

private struct RemoteJournalEntry: Decodable {
    let id: UUID
    let clientID: UUID
    let body: String
    let latitude: Double?
    let longitude: Double?
    let createdAt: String
    let updatedAt: String
    let deletedAt: String?
    let days: RemoteDay?

    enum CodingKeys: String, CodingKey {
        case id
        case clientID = "client_id"
        case body
        case latitude
        case longitude
        case createdAt = "created_at"
        case updatedAt = "updated_at"
        case deletedAt = "deleted_at"
        case days
    }

    func updatedAtDateIsNewer(than localUpdatedAt: Date) -> Bool {
        guard let remoteUpdatedAt = SyncDateFormatter.dateTime(from: updatedAt) else {
            return false
        }

        return remoteUpdatedAt > localUpdatedAt
    }
}

private struct RemoteDay: Decodable {
    let dateKey: String

    enum CodingKeys: String, CodingKey {
        case dateKey = "date_key"
    }
}

private enum SyncDateFormatter {
    static func date(fromDayKey dayKey: String) -> Date? {
        dayFormatter.date(from: dayKey)
    }

    static func timestamp(_ date: Date) -> String {
        timestampFormatter.string(from: date)
    }

    static func dateTime(from value: String) -> Date? {
        timestampFormatter.date(from: value) ?? fallbackTimestampFormatter.date(from: value)
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

    private static let fallbackTimestampFormatter: ISO8601DateFormatter = {
        let formatter = ISO8601DateFormatter()
        formatter.formatOptions = [.withInternetDateTime]
        return formatter
    }()
}
#endif
