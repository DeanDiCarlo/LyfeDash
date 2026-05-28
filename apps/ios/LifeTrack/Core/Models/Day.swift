import Foundation
import SwiftData

@Model
final class Day {
    @Attribute(.unique) var id: UUID
    var dateKey: String
    var date: Date
    var timezoneIdentifier: String
    var createdAt: Date
    var updatedAt: Date

    init(date: Date, calendar: Calendar = .current) {
        self.id = UUID()
        self.date = calendar.startOfDay(for: date)
        self.timezoneIdentifier = calendar.timeZone.identifier
        self.dateKey = Day.makeDateKey(for: date, calendar: calendar)
        self.createdAt = Date()
        self.updatedAt = Date()
    }

    static func makeDateKey(for date: Date, calendar: Calendar = .current) -> String {
        let components = calendar.dateComponents([.year, .month, .day], from: date)
        let year = components.year ?? 1970
        let month = components.month ?? 1
        let day = components.day ?? 1
        return String(format: "%04d-%02d-%02d", year, month, day)
    }
}

