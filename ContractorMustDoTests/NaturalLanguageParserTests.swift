//
//  NaturalLanguageParserTests.swift
//  ContractorMustDoTests
//
//  Unit tests for NaturalLanguageParser.
//

import XCTest
@testable import ContractorMustDo

final class NaturalLanguageParserTests: XCTestCase {
    // MARK: - Properties

    var parser: NaturalLanguageParser!

    // MARK: - Setup

    override func setUp() {
        super.setUp()
        parser = NaturalLanguageParser.shared
    }

    // MARK: - Basic Parsing Tests

    func testSimpleTaskTitle() {
        let result = parser.parse("Call the supplier")

        XCTAssertEqual(result.title, "Call the supplier")
        XCTAssertNil(result.recurrence)
    }

    func testTitleWithToday() {
        let result = parser.parse("Call supplier today")

        XCTAssertTrue(result.title.contains("Call supplier"))
        XCTAssertNotNil(result.dueDate)

        let calendar = Calendar.current
        XCTAssertTrue(calendar.isDateInToday(result.dueDate!))
    }

    func testTitleWithTomorrow() {
        let result = parser.parse("Submit permit tomorrow")

        XCTAssertTrue(result.title.contains("Submit permit"))
        XCTAssertNotNil(result.dueDate)

        let calendar = Calendar.current
        XCTAssertTrue(calendar.isDateInTomorrow(result.dueDate!))
    }

    // MARK: - Time Parsing Tests

    func testTimeAM() {
        let result = parser.parse("Meeting at 9am")

        XCTAssertNotNil(result.time)
        XCTAssertEqual(result.time?.hour, 9)
        XCTAssertEqual(result.time?.minute, 0)
    }

    func testTimePM() {
        let result = parser.parse("Call client at 2pm")

        XCTAssertNotNil(result.time)
        XCTAssertEqual(result.time?.hour, 14)
        XCTAssertEqual(result.time?.minute, 0)
    }

    func testTimeWithMinutes() {
        let result = parser.parse("Appointment at 10:30am")

        XCTAssertNotNil(result.time)
        XCTAssertEqual(result.time?.hour, 10)
        XCTAssertEqual(result.time?.minute, 30)
    }

    func testNamedTime_Morning() {
        let result = parser.parse("Review plans morning")

        XCTAssertNotNil(result.time)
        XCTAssertEqual(result.time?.hour, 9)
    }

    func testNamedTime_Noon() {
        let result = parser.parse("Lunch meeting at noon")

        XCTAssertNotNil(result.time)
        XCTAssertEqual(result.time?.hour, 12)
    }

    func testNamedTime_EOD() {
        let result = parser.parse("Submit report eod")

        XCTAssertNotNil(result.time)
        XCTAssertEqual(result.time?.hour, 17)
    }

    // MARK: - Recurrence Parsing Tests

    func testDailyRecurrence() {
        let result = parser.parse("Check email every day")

        XCTAssertNotNil(result.recurrence)
        XCTAssertEqual(result.recurrence?.type, .daily)
        XCTAssertEqual(result.recurrence?.interval, 1)
    }

    func testDailyKeyword() {
        let result = parser.parse("Daily standup meeting")

        XCTAssertNotNil(result.recurrence)
        XCTAssertEqual(result.recurrence?.type, .daily)
    }

    func testWeeklyRecurrence() {
        let result = parser.parse("Team sync every week")

        XCTAssertNotNil(result.recurrence)
        XCTAssertEqual(result.recurrence?.type, .weekly)
    }

    func testWeeklyWithDays() {
        let result = parser.parse("Call supplier every Monday")

        XCTAssertNotNil(result.recurrence)
        XCTAssertEqual(result.recurrence?.type, .weekly)
        XCTAssertTrue(result.recurrence?.days.contains(2) ?? false) // Monday = 2
    }

    func testWeeklyWithMultipleDays() {
        let result = parser.parse("Gym every Monday and Wednesday")

        XCTAssertNotNil(result.recurrence)
        XCTAssertEqual(result.recurrence?.type, .weekly)
        XCTAssertTrue(result.recurrence?.days.contains(2) ?? false) // Monday
        XCTAssertTrue(result.recurrence?.days.contains(4) ?? false) // Wednesday
    }

    func testMonthlyRecurrence() {
        let result = parser.parse("Pay rent every month")

        XCTAssertNotNil(result.recurrence)
        XCTAssertEqual(result.recurrence?.type, .monthly)
    }

    func testCustomIntervalDays() {
        let result = parser.parse("Water plants every 3 days")

        XCTAssertNotNil(result.recurrence)
        XCTAssertEqual(result.recurrence?.type, .daily)
        XCTAssertEqual(result.recurrence?.interval, 3)
    }

    func testCustomIntervalWeeks() {
        let result = parser.parse("Team dinner every 2 weeks")

        XCTAssertNotNil(result.recurrence)
        XCTAssertEqual(result.recurrence?.type, .weekly)
        XCTAssertEqual(result.recurrence?.interval, 2)
    }

    // MARK: - Contractor Terms Tests

    func testContractorTermBidFollowUp() {
        let result = parser.parse("bid follow-up for Johnson project")

        XCTAssertTrue(result.isContractorTerm)
    }

    func testContractorTermPermitCheck() {
        let result = parser.parse("permit check for renovation")

        XCTAssertTrue(result.isContractorTerm)
    }

    func testContractorTermInvoiceReminder() {
        let result = parser.parse("invoice reminder for client A")

        XCTAssertTrue(result.isContractorTerm)
    }

    func testNonContractorTerm() {
        let result = parser.parse("Buy groceries")

        XCTAssertFalse(result.isContractorTerm)
    }

    // MARK: - Complex Input Tests

    func testComplexInput() {
        let result = parser.parse("call supplier every Monday at 9am")

        XCTAssertTrue(result.title.contains("Call supplier"))
        XCTAssertNotNil(result.recurrence)
        XCTAssertEqual(result.recurrence?.type, .weekly)
        XCTAssertNotNil(result.time)
        XCTAssertEqual(result.time?.hour, 9)
    }

    func testComplexInputWithTomorrow() {
        let result = parser.parse("Submit permit application tomorrow at 2pm")

        XCTAssertTrue(result.title.contains("Submit permit application"))
        XCTAssertNotNil(result.dueDate)
        XCTAssertNotNil(result.time)
        XCTAssertEqual(result.time?.hour, 14)
    }

    // MARK: - Edge Cases

    func testEmptyInput() {
        let result = parser.parse("")

        XCTAssertTrue(result.title.isEmpty || result.title == result.originalInput)
    }

    func testOnlyTimeInput() {
        let result = parser.parse("at 3pm")

        XCTAssertNotNil(result.time)
        XCTAssertEqual(result.time?.hour, 15)
    }

    func testPreservesOriginalInput() {
        let input = "Call supplier every Monday at 9am"
        let result = parser.parse(input)

        XCTAssertEqual(result.originalInput, input)
    }
}
