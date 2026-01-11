//
//  TaskItemTests.swift
//  ContractorMustDoTests
//
//  Unit tests for TaskItem model.
//

import XCTest
import SwiftData
@testable import ContractorMustDo

final class TaskItemTests: XCTestCase {
    // MARK: - Properties

    var modelContainer: ModelContainer!
    var modelContext: ModelContext!

    // MARK: - Setup & Teardown

    override func setUpWithError() throws {
        let schema = Schema([TaskItem.self])
        let config = ModelConfiguration(isStoredInMemoryOnly: true)
        modelContainer = try ModelContainer(for: schema, configurations: [config])
        modelContext = ModelContext(modelContainer)
    }

    override func tearDownWithError() throws {
        modelContainer = nil
        modelContext = nil
    }

    // MARK: - Initialization Tests

    func testTaskInitialization() {
        let dueDate = Date()
        let task = TaskItem(
            title: "Test Task",
            dueDate: dueDate,
            notes: "Test notes",
            nagLevel: .moderate
        )

        XCTAssertEqual(task.title, "Test Task")
        XCTAssertEqual(task.notes, "Test notes")
        XCTAssertEqual(task.dueDate, dueDate)
        XCTAssertEqual(task.nagLevel, .moderate)
        XCTAssertFalse(task.isCompleted)
        XCTAssertNil(task.completedDate)
        XCTAssertEqual(task.snoozeCount, 0)
        XCTAssertEqual(task.escalationLevel, 0)
    }

    func testTaskDefaultValues() {
        let task = TaskItem(title: "Minimal Task", dueDate: Date())

        XCTAssertEqual(task.notes, "")
        XCTAssertEqual(task.nagLevel, .moderate)
        XCTAssertEqual(task.snoozeInterval, .fiveMinutes)
        XCTAssertFalse(task.escalatingEnabled)
        XCTAssertNil(task.recurrenceType)
        XCTAssertTrue(task.notificationsEnabled)
    }

    // MARK: - Computed Property Tests

    func testIsOverdue() {
        let pastDate = Date().addingTimeInterval(-3600) // 1 hour ago
        let task = TaskItem(title: "Overdue Task", dueDate: pastDate)

        XCTAssertTrue(task.isOverdue)

        task.isCompleted = true
        XCTAssertFalse(task.isOverdue)
    }

    func testIsDueToday() {
        let today = Date()
        let task = TaskItem(title: "Today Task", dueDate: today)

        XCTAssertTrue(task.isDueToday)

        let tomorrow = Calendar.current.date(byAdding: .day, value: 1, to: today)!
        task.dueDate = tomorrow
        XCTAssertFalse(task.isDueToday)
    }

    func testIsRecurring() {
        let task = TaskItem(title: "Non-recurring Task", dueDate: Date())
        XCTAssertFalse(task.isRecurring)

        task.recurrenceType = .daily
        XCTAssertTrue(task.isRecurring)
    }

    // MARK: - Snooze Tests

    func testSnooze() {
        let task = TaskItem(title: "Snooze Task", dueDate: Date())

        XCTAssertEqual(task.snoozeCount, 0)

        task.snooze()

        XCTAssertEqual(task.snoozeCount, 1)
        XCTAssertNotNil(task.lastNotificationDate)
    }

    func testSnoozeWithEscalation() {
        let task = TaskItem(
            title: "Escalating Task",
            dueDate: Date(),
            escalatingEnabled: true
        )

        XCTAssertEqual(task.escalationLevel, 0)

        task.snooze()
        XCTAssertEqual(task.escalationLevel, 1)

        task.snooze()
        XCTAssertEqual(task.escalationLevel, 2)
    }

    // MARK: - Completion Tests

    func testMarkCompleted() {
        let task = TaskItem(title: "Complete Task", dueDate: Date())

        let nextTask = task.markCompleted()

        XCTAssertTrue(task.isCompleted)
        XCTAssertNotNil(task.completedDate)
        XCTAssertEqual(task.snoozeCount, 0)
        XCTAssertEqual(task.escalationLevel, 0)
        XCTAssertNil(nextTask) // No recurrence
    }

    func testMarkCompletedWithRecurrence() {
        let task = TaskItem(
            title: "Recurring Task",
            dueDate: Date(),
            recurrenceType: .daily,
            recurrenceInterval: 1
        )

        let nextTask = task.markCompleted()

        XCTAssertTrue(task.isCompleted)
        XCTAssertNotNil(nextTask)
        XCTAssertEqual(nextTask?.title, task.title)
        XCTAssertFalse(nextTask?.isCompleted ?? true)
    }

    // MARK: - Recurrence Tests

    func testDailyRecurrence() {
        let baseDate = Date()
        let task = TaskItem(
            title: "Daily Task",
            dueDate: baseDate,
            recurrenceType: .daily,
            recurrenceInterval: 1
        )

        let nextDate = task.calculateNextOccurrence()

        XCTAssertNotNil(nextDate)

        let calendar = Calendar.current
        let expectedDate = calendar.date(byAdding: .day, value: 1, to: baseDate)

        XCTAssertEqual(
            calendar.dateComponents([.year, .month, .day], from: nextDate!),
            calendar.dateComponents([.year, .month, .day], from: expectedDate!)
        )
    }

    func testWeeklyRecurrence() {
        let baseDate = Date()
        let task = TaskItem(
            title: "Weekly Task",
            dueDate: baseDate,
            recurrenceType: .weekly,
            recurrenceInterval: 1
        )

        let nextDate = task.calculateNextOccurrence()

        XCTAssertNotNil(nextDate)

        let calendar = Calendar.current
        let expectedDate = calendar.date(byAdding: .weekOfYear, value: 1, to: baseDate)

        XCTAssertEqual(
            calendar.dateComponents([.year, .month, .day], from: nextDate!),
            calendar.dateComponents([.year, .month, .day], from: expectedDate!)
        )
    }

    func testMonthlyRecurrence() {
        let baseDate = Date()
        let task = TaskItem(
            title: "Monthly Task",
            dueDate: baseDate,
            recurrenceType: .monthly,
            recurrenceInterval: 1
        )

        let nextDate = task.calculateNextOccurrence()

        XCTAssertNotNil(nextDate)

        let calendar = Calendar.current
        let expectedDate = calendar.date(byAdding: .month, value: 1, to: baseDate)

        XCTAssertEqual(
            calendar.dateComponents([.year, .month], from: nextDate!),
            calendar.dateComponents([.year, .month], from: expectedDate!)
        )
    }

    func testCustomIntervalRecurrence() {
        let baseDate = Date()
        let task = TaskItem(
            title: "Custom Task",
            dueDate: baseDate,
            recurrenceType: .custom,
            recurrenceInterval: 5
        )

        let nextDate = task.calculateNextOccurrence()

        XCTAssertNotNil(nextDate)

        let calendar = Calendar.current
        let expectedDate = calendar.date(byAdding: .day, value: 5, to: baseDate)

        XCTAssertEqual(
            calendar.dateComponents([.year, .month, .day], from: nextDate!),
            calendar.dateComponents([.year, .month, .day], from: expectedDate!)
        )
    }

    func testRepeatFromCompletion() {
        let baseDate = Date()
        let completedDate = Date().addingTimeInterval(86400) // Completed tomorrow

        let task = TaskItem(
            title: "Repeat from completion",
            dueDate: baseDate,
            recurrenceType: .daily,
            recurrenceInterval: 1,
            repeatFromCompletion: true
        )

        task.isCompleted = true
        task.completedDate = completedDate

        let nextDate = task.calculateNextOccurrence()

        XCTAssertNotNil(nextDate)

        let calendar = Calendar.current
        let expectedDate = calendar.date(byAdding: .day, value: 1, to: completedDate)

        XCTAssertEqual(
            calendar.dateComponents([.year, .month, .day], from: nextDate!),
            calendar.dateComponents([.year, .month, .day], from: expectedDate!)
        )
    }

    // MARK: - Nag Level Tests

    func testNagLevelFrequencyMultiplier() {
        XCTAssertEqual(NagLevel.gentle.frequencyMultiplier, 2.0)
        XCTAssertEqual(NagLevel.moderate.frequencyMultiplier, 1.0)
        XCTAssertEqual(NagLevel.relentless.frequencyMultiplier, 0.5)
    }

    // MARK: - Snooze Interval Tests

    func testSnoozeIntervalSeconds() {
        XCTAssertEqual(SnoozeInterval.oneMinute.seconds, 60)
        XCTAssertEqual(SnoozeInterval.fiveMinutes.seconds, 300)
        XCTAssertEqual(SnoozeInterval.fifteenMinutes.seconds, 900)
        XCTAssertEqual(SnoozeInterval.thirtyMinutes.seconds, 1800)
        XCTAssertEqual(SnoozeInterval.oneHour.seconds, 3600)
    }

    func testSnoozeIntervalFromSeconds() {
        XCTAssertEqual(SnoozeInterval.fromSeconds(60), .oneMinute)
        XCTAssertEqual(SnoozeInterval.fromSeconds(300), .fiveMinutes)
        XCTAssertEqual(SnoozeInterval.fromSeconds(900), .fifteenMinutes)

        // Custom interval
        let custom = SnoozeInterval.fromSeconds(120)
        XCTAssertEqual(custom.seconds, 120)
    }
}
