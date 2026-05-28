import XCTest
@testable import LifeTrack

final class TaskSchedulerTests: XCTestCase {
    func testDailyTemplateIsDueEveryDay() {
        let template = TaskTemplate(title: "Gym", recurrence: .daily)
        XCTAssertTrue(TaskScheduler.isTemplateDue(template, on: Date()))
    }

    func testWeekdayTemplateIsNotDueOnSaturday() {
        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = TimeZone(identifier: "America/Chicago")!
        let saturday = calendar.date(from: DateComponents(year: 2026, month: 5, day: 30))!
        let template = TaskTemplate(title: "Work", recurrence: .weekdays)

        XCTAssertFalse(TaskScheduler.isTemplateDue(template, on: saturday, calendar: calendar))
    }

    func testArchivedTemplateIsNeverDue() {
        let template = TaskTemplate(title: "Laundry", recurrence: .daily)
        template.archivedAt = Date()

        XCTAssertFalse(TaskScheduler.isTemplateDue(template, on: Date()))
    }
}

