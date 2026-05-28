import XCTest
@testable import LifeTrack

final class DayKeyTests: XCTestCase {
    func testDateKeyUsesProvidedCalendarTimezone() {
        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = TimeZone(identifier: "America/Chicago")!

        let date = Date(timeIntervalSince1970: 1_735_695_000)

        XCTAssertEqual(Day.makeDateKey(for: date, calendar: calendar), "2024-12-31")
    }
}

