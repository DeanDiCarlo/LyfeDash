import Foundation

enum TaskScheduler {
    static func isTemplateDue(_ template: TaskTemplate, on date: Date, calendar: Calendar = .current) -> Bool {
        guard template.archivedAt == nil else { return false }

        switch template.recurrence {
        case .daily:
            return true
        case .weekdays:
            let weekday = calendar.component(.weekday, from: date)
            return weekday >= 2 && weekday <= 6
        case .weekly:
            let createdWeekday = calendar.component(.weekday, from: template.createdAt)
            let targetWeekday = calendar.component(.weekday, from: date)
            return createdWeekday == targetWeekday
        case .adHoc:
            return false
        }
    }
}

