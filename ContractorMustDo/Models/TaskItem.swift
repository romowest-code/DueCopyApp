//
//  TaskItem.swift
//  ContractorMustDo
//
//  Core task model with nagging and recurrence support.
//

import Foundation
import SwiftData

// MARK: - Task Item Model

/// Represents a task with persistent nagging reminder capabilities.
///
/// This model supports:
/// - REQ-1.x: Persistent nagging system with customizable snooze intervals
/// - REQ-2.x: Recurring reminders with various patterns
/// - REQ-7.x: Offline persistence via SwiftData
@Model
final class TaskItem {
    // MARK: - Core Properties

    /// Unique identifier for the task
    @Attribute(.unique) var id: UUID

    /// Task title/description
    var title: String

    /// Optional detailed notes for the task
    var notes: String

    /// When the task is due
    var dueDate: Date

    /// Whether the task has been completed
    var isCompleted: Bool

    /// When the task was completed (nil if not completed)
    var completedDate: Date?

    /// When the task was created
    var createdDate: Date

    // MARK: - Nagging Properties (REQ-1.x)

    /// The nag level determines notification frequency and intensity
    var nagLevelRawValue: String

    /// Snooze interval in seconds for auto-snooze
    var snoozeIntervalSeconds: TimeInterval

    /// Whether escalating notifications are enabled
    var escalatingEnabled: Bool

    /// Current escalation level (increases when ignored)
    var escalationLevel: Int

    /// Last time a notification was sent for this task
    var lastNotificationDate: Date?

    /// Number of times this task has been snoozed
    var snoozeCount: Int

    // MARK: - Recurrence Properties (REQ-2.x)

    /// The type of recurrence pattern
    var recurrenceTypeRawValue: String?

    /// Days of the week for weekly recurrence (0 = Sunday, 6 = Saturday)
    var recurrenceDays: [Int]

    /// Day of month for monthly recurrence
    var recurrenceDayOfMonth: Int?

    /// Custom interval value (e.g., every X days)
    var recurrenceInterval: Int

    /// Whether to calculate next occurrence from completion date
    var repeatFromCompletion: Bool

    // MARK: - Notification Properties

    /// Identifier for the scheduled notification
    var notificationIdentifier: String?

    /// Whether notifications are enabled for this task
    var notificationsEnabled: Bool

    // MARK: - Computed Properties

    /// The nag level as an enum
    var nagLevel: NagLevel {
        get { NagLevel(rawValue: nagLevelRawValue) ?? .moderate }
        set { nagLevelRawValue = newValue.rawValue }
    }

    /// The snooze interval as an enum
    var snoozeInterval: SnoozeInterval {
        get { SnoozeInterval.fromSeconds(snoozeIntervalSeconds) }
        set { snoozeIntervalSeconds = newValue.seconds }
    }

    /// The recurrence type as an enum
    var recurrenceType: RecurrenceType? {
        get {
            guard let rawValue = recurrenceTypeRawValue else { return nil }
            return RecurrenceType(rawValue: rawValue)
        }
        set { recurrenceTypeRawValue = newValue?.rawValue }
    }

    /// Whether the task is overdue
    var isOverdue: Bool {
        !isCompleted && dueDate < Date()
    }

    /// Whether the task is due today
    var isDueToday: Bool {
        Calendar.current.isDateInToday(dueDate)
    }

    /// Whether this is a recurring task
    var isRecurring: Bool {
        recurrenceType != nil
    }

    // MARK: - Initialization

    /// Creates a new task with the specified properties.
    ///
    /// - Parameters:
    ///   - title: The task title
    ///   - dueDate: When the task is due
    ///   - notes: Optional detailed notes
    ///   - nagLevel: The nagging intensity level
    ///   - snoozeInterval: How long to wait between nags
    ///   - escalatingEnabled: Whether to escalate notifications
    ///   - recurrenceType: Optional recurrence pattern
    ///   - recurrenceDays: Days of week for weekly recurrence
    ///   - recurrenceInterval: Custom interval value
    ///   - repeatFromCompletion: Whether to repeat from completion date
    init(
        title: String,
        dueDate: Date,
        notes: String = "",
        nagLevel: NagLevel = .moderate,
        snoozeInterval: SnoozeInterval = .fiveMinutes,
        escalatingEnabled: Bool = false,
        recurrenceType: RecurrenceType? = nil,
        recurrenceDays: [Int] = [],
        recurrenceDayOfMonth: Int? = nil,
        recurrenceInterval: Int = 1,
        repeatFromCompletion: Bool = false
    ) {
        self.id = UUID()
        self.title = title
        self.dueDate = dueDate
        self.notes = notes
        self.isCompleted = false
        self.completedDate = nil
        self.createdDate = Date()
        self.nagLevelRawValue = nagLevel.rawValue
        self.snoozeIntervalSeconds = snoozeInterval.seconds
        self.escalatingEnabled = escalatingEnabled
        self.escalationLevel = 0
        self.lastNotificationDate = nil
        self.snoozeCount = 0
        self.recurrenceTypeRawValue = recurrenceType?.rawValue
        self.recurrenceDays = recurrenceDays
        self.recurrenceDayOfMonth = recurrenceDayOfMonth
        self.recurrenceInterval = recurrenceInterval
        self.repeatFromCompletion = repeatFromCompletion
        self.notificationIdentifier = nil
        self.notificationsEnabled = true
    }

    // MARK: - Methods

    /// Marks the task as completed and handles recurrence.
    ///
    /// - Returns: A new task if this is a recurring task, nil otherwise.
    func markCompleted() -> TaskItem? {
        isCompleted = true
        completedDate = Date()
        snoozeCount = 0
        escalationLevel = 0

        // Create next occurrence if recurring
        if let nextOccurrence = calculateNextOccurrence() {
            return TaskItem(
                title: title,
                dueDate: nextOccurrence,
                notes: notes,
                nagLevel: nagLevel,
                snoozeInterval: snoozeInterval,
                escalatingEnabled: escalatingEnabled,
                recurrenceType: recurrenceType,
                recurrenceDays: recurrenceDays,
                recurrenceDayOfMonth: recurrenceDayOfMonth,
                recurrenceInterval: recurrenceInterval,
                repeatFromCompletion: repeatFromCompletion
            )
        }

        return nil
    }

    /// Snoozes the task by the configured snooze interval.
    func snooze() {
        snoozeCount += 1

        // Escalate if enabled
        if escalatingEnabled {
            escalationLevel = min(escalationLevel + 1, NagLevel.allCases.count - 1)
        }

        lastNotificationDate = Date()
    }

    /// Calculates the next occurrence date for recurring tasks.
    ///
    /// - Returns: The next due date, or nil if not recurring.
    func calculateNextOccurrence() -> Date? {
        guard let recurrence = recurrenceType else { return nil }

        let baseDate = repeatFromCompletion ? (completedDate ?? Date()) : dueDate
        let calendar = Calendar.current

        switch recurrence {
        case .daily:
            return calendar.date(byAdding: .day, value: recurrenceInterval, to: baseDate)

        case .weekly:
            if recurrenceDays.isEmpty {
                return calendar.date(byAdding: .weekOfYear, value: recurrenceInterval, to: baseDate)
            } else {
                return calculateNextWeekdayOccurrence(from: baseDate, calendar: calendar)
            }

        case .monthly:
            if let dayOfMonth = recurrenceDayOfMonth {
                return calculateNextMonthlyOccurrence(
                    from: baseDate,
                    dayOfMonth: dayOfMonth,
                    calendar: calendar
                )
            } else {
                return calendar.date(byAdding: .month, value: recurrenceInterval, to: baseDate)
            }

        case .custom:
            return calendar.date(byAdding: .day, value: recurrenceInterval, to: baseDate)
        }
    }

    // MARK: - Private Helpers

    private func calculateNextWeekdayOccurrence(from date: Date, calendar: Calendar) -> Date? {
        let currentWeekday = calendar.component(.weekday, from: date)
        let sortedDays = recurrenceDays.sorted()

        // Find next day in current week
        if let nextDay = sortedDays.first(where: { $0 > currentWeekday }) {
            let daysToAdd = nextDay - currentWeekday
            return calendar.date(byAdding: .day, value: daysToAdd, to: date)
        }

        // Wrap to first day of next interval
        if let firstDay = sortedDays.first {
            let daysToEndOfWeek = 7 - currentWeekday + firstDay
            let weeksToAdd = (recurrenceInterval - 1) * 7
            return calendar.date(byAdding: .day, value: daysToEndOfWeek + weeksToAdd, to: date)
        }

        return nil
    }

    private func calculateNextMonthlyOccurrence(
        from date: Date,
        dayOfMonth: Int,
        calendar: Calendar
    ) -> Date? {
        var components = calendar.dateComponents([.year, .month, .day, .hour, .minute], from: date)
        components.month = (components.month ?? 1) + recurrenceInterval
        components.day = dayOfMonth

        // Handle months with fewer days
        if let result = calendar.date(from: components) {
            return result
        }

        // Fall back to last day of month
        components.day = 1
        if let firstOfMonth = calendar.date(from: components),
           let lastOfMonth = calendar.date(byAdding: DateComponents(month: 1, day: -1), to: firstOfMonth) {
            return lastOfMonth
        }

        return nil
    }
}

// MARK: - Nag Level

/// Represents the intensity of task reminders.
///
/// - REQ-1.4: "Nag Level" setting per task
enum NagLevel: String, CaseIterable, Codable {
    case gentle = "gentle"
    case moderate = "moderate"
    case relentless = "relentless"

    /// Display name for the nag level
    var displayName: String {
        switch self {
        case .gentle: return Strings.NagLevel.gentle
        case .moderate: return Strings.NagLevel.moderate
        case .relentless: return Strings.NagLevel.relentless
        }
    }

    /// Description of the nag level behavior
    var description: String {
        switch self {
        case .gentle: return Strings.NagLevel.gentleDescription
        case .moderate: return Strings.NagLevel.moderateDescription
        case .relentless: return Strings.NagLevel.relentlessDescription
        }
    }

    /// The notification frequency multiplier
    var frequencyMultiplier: Double {
        switch self {
        case .gentle: return 2.0
        case .moderate: return 1.0
        case .relentless: return 0.5
        }
    }
}

// MARK: - Snooze Interval

/// Represents available snooze durations.
///
/// - REQ-1.2: Customizable snooze intervals
enum SnoozeInterval: CaseIterable, Codable, Hashable {
    case oneMinute
    case fiveMinutes
    case fifteenMinutes
    case thirtyMinutes
    case oneHour
    case custom(TimeInterval)

    func hash(into hasher: inout Hasher) {
        hasher.combine(seconds)
    }

    static func == (lhs: SnoozeInterval, rhs: SnoozeInterval) -> Bool {
        lhs.seconds == rhs.seconds
    }

    /// All standard snooze intervals
    static var allCases: [SnoozeInterval] {
        [.oneMinute, .fiveMinutes, .fifteenMinutes, .thirtyMinutes, .oneHour]
    }

    /// The interval in seconds
    var seconds: TimeInterval {
        switch self {
        case .oneMinute: return 60
        case .fiveMinutes: return 300
        case .fifteenMinutes: return 900
        case .thirtyMinutes: return 1800
        case .oneHour: return 3600
        case .custom(let interval): return interval
        }
    }

    /// Display name for the interval
    var displayName: String {
        switch self {
        case .oneMinute: return Strings.Snooze.oneMinute
        case .fiveMinutes: return Strings.Snooze.fiveMinutes
        case .fifteenMinutes: return Strings.Snooze.fifteenMinutes
        case .thirtyMinutes: return Strings.Snooze.thirtyMinutes
        case .oneHour: return Strings.Snooze.oneHour
        case .custom(let interval):
            let minutes = Int(interval / 60)
            return String(format: Strings.Snooze.customFormat, minutes)
        }
    }

    /// Creates a SnoozeInterval from seconds
    static func fromSeconds(_ seconds: TimeInterval) -> SnoozeInterval {
        switch seconds {
        case 60: return .oneMinute
        case 300: return .fiveMinutes
        case 900: return .fifteenMinutes
        case 1800: return .thirtyMinutes
        case 3600: return .oneHour
        default: return .custom(seconds)
        }
    }
}

// MARK: - Recurrence Type

/// Represents recurrence patterns for tasks.
///
/// - REQ-2.x: Recurring reminder patterns
enum RecurrenceType: String, CaseIterable, Codable {
    case daily = "daily"
    case weekly = "weekly"
    case monthly = "monthly"
    case custom = "custom"

    /// Display name for the recurrence type
    var displayName: String {
        switch self {
        case .daily: return Strings.Recurrence.daily
        case .weekly: return Strings.Recurrence.weekly
        case .monthly: return Strings.Recurrence.monthly
        case .custom: return Strings.Recurrence.custom
        }
    }
}
