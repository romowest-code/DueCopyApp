//
//  TaskAppIntents.swift
//  ContractorMustDo
//
//  App Intents for Siri integration and Shortcuts.
//

import AppIntents
import SwiftData

// MARK: - Add Task Intent

/// Siri intent for adding a new task.
///
/// Supports REQ-5.1: "Add task" Siri shortcut
struct AddTaskIntent: AppIntent {
    static var title: LocalizedStringResource = "Add Task"
    static var description = IntentDescription("Add a new task to your list")

    @Parameter(title: "Task Title")
    var title: String

    @Parameter(title: "Due Date", default: Date())
    var dueDate: Date

    @Parameter(title: "Notes", default: "")
    var notes: String

    static var parameterSummary: some ParameterSummary {
        Summary("Add task \(\.$title) due \(\.$dueDate)") {
            \.$notes
        }
    }

    func perform() async throws -> some IntentResult & ProvidesDialog {
        // Create the task using shared container
        let task = TaskItem(
            title: title,
            dueDate: dueDate,
            notes: notes
        )

        // In production, save to shared SwiftData container
        // and schedule notification

        return .result(dialog: "Added task: \(title)")
    }
}

// MARK: - Get Overdue Tasks Intent

/// Siri intent for checking overdue tasks.
///
/// Supports REQ-5.2: "What's overdue?" Siri shortcut
struct GetOverdueTasksIntent: AppIntent {
    static var title: LocalizedStringResource = "What's Overdue?"
    static var description = IntentDescription("Check your overdue tasks")

    func perform() async throws -> some IntentResult & ProvidesDialog {
        // In production, fetch from shared SwiftData container
        let overdueCount = 3 // Placeholder

        if overdueCount == 0 {
            return .result(dialog: "You have no overdue tasks. Great job!")
        } else if overdueCount == 1 {
            return .result(dialog: "You have 1 overdue task.")
        } else {
            return .result(dialog: "You have \(overdueCount) overdue tasks.")
        }
    }
}

// MARK: - Mark Task Complete Intent

/// Siri intent for marking a task as complete.
///
/// Supports REQ-5.3: "Mark [task] complete" voice command
struct MarkTaskCompleteIntent: AppIntent {
    static var title: LocalizedStringResource = "Mark Task Complete"
    static var description = IntentDescription("Mark a task as completed")

    @Parameter(title: "Task")
    var task: TaskEntity

    static var parameterSummary: some ParameterSummary {
        Summary("Mark \(\.$task) complete")
    }

    func perform() async throws -> some IntentResult & ProvidesDialog {
        // In production, update task in shared SwiftData container
        return .result(dialog: "Marked \(task.title) as complete")
    }
}

// MARK: - Snooze Task Intent

/// Siri intent for snoozing a task.
struct SnoozeTaskIntent: AppIntent {
    static var title: LocalizedStringResource = "Snooze Task"
    static var description = IntentDescription("Snooze a task reminder")

    @Parameter(title: "Task")
    var task: TaskEntity

    @Parameter(title: "Duration", default: .fiveMinutes)
    var duration: SnoozeDuration

    static var parameterSummary: some ParameterSummary {
        Summary("Snooze \(\.$task) for \(\.$duration)")
    }

    func perform() async throws -> some IntentResult & ProvidesDialog {
        return .result(dialog: "Snoozed \(task.title) for \(duration.displayName)")
    }
}

// MARK: - Task Entity

/// Entity representing a task for App Intents.
struct TaskEntity: AppEntity {
    static var typeDisplayRepresentation = TypeDisplayRepresentation(name: "Task")

    static var defaultQuery = TaskEntityQuery()

    var id: UUID
    var title: String
    var dueDate: Date
    var isCompleted: Bool

    var displayRepresentation: DisplayRepresentation {
        DisplayRepresentation(title: "\(title)")
    }
}

// MARK: - Task Entity Query

/// Query for finding tasks via Siri.
struct TaskEntityQuery: EntityQuery {
    func entities(for identifiers: [UUID]) async throws -> [TaskEntity] {
        // In production, fetch from shared SwiftData container
        return []
    }

    func suggestedEntities() async throws -> [TaskEntity] {
        // Return most relevant incomplete tasks
        return []
    }
}

// MARK: - Snooze Duration

/// Duration options for snoozing tasks via Siri.
enum SnoozeDuration: String, AppEnum {
    case oneMinute = "1 minute"
    case fiveMinutes = "5 minutes"
    case fifteenMinutes = "15 minutes"
    case thirtyMinutes = "30 minutes"
    case oneHour = "1 hour"

    static var typeDisplayRepresentation = TypeDisplayRepresentation(name: "Snooze Duration")

    static var caseDisplayRepresentations: [SnoozeDuration: DisplayRepresentation] = [
        .oneMinute: "1 minute",
        .fiveMinutes: "5 minutes",
        .fifteenMinutes: "15 minutes",
        .thirtyMinutes: "30 minutes",
        .oneHour: "1 hour"
    ]

    var displayName: String {
        rawValue
    }

    var seconds: TimeInterval {
        switch self {
        case .oneMinute: return 60
        case .fiveMinutes: return 300
        case .fifteenMinutes: return 900
        case .thirtyMinutes: return 1800
        case .oneHour: return 3600
        }
    }
}

// MARK: - App Shortcuts Provider

/// Provides all shortcuts for the Shortcuts app.
///
/// Supports REQ-5.4: Shortcuts app integration for automation
struct AppShortcuts: AppShortcutsProvider {
    static var appShortcuts: [AppShortcut] {
        // Task shortcuts
        AppShortcut(
            intent: AddTaskIntent(),
            phrases: [
                "Add a task in \(.applicationName)",
                "Create a task in \(.applicationName)",
                "New task in \(.applicationName)",
                "Add reminder in \(.applicationName)"
            ],
            shortTitle: "Add Task",
            systemImageName: "plus.circle"
        )

        AppShortcut(
            intent: GetOverdueTasksIntent(),
            phrases: [
                "What's overdue in \(.applicationName)",
                "Show overdue tasks in \(.applicationName)",
                "Check overdue in \(.applicationName)",
                "What did I miss in \(.applicationName)"
            ],
            shortTitle: "What's Overdue?",
            systemImageName: "exclamationmark.triangle"
        )

        AppShortcut(
            intent: MarkTaskCompleteIntent(),
            phrases: [
                "Mark task complete in \(.applicationName)",
                "Complete a task in \(.applicationName)",
                "Finish a task in \(.applicationName)"
            ],
            shortTitle: "Mark Complete",
            systemImageName: "checkmark.circle"
        )

        AppShortcut(
            intent: SnoozeTaskIntent(),
            phrases: [
                "Snooze task in \(.applicationName)",
                "Delay reminder in \(.applicationName)"
            ],
            shortTitle: "Snooze Task",
            systemImageName: "clock.arrow.circlepath"
        )

        // Timer shortcuts
        AppShortcut(
            intent: StartTimerIntent(),
            phrases: [
                "Start a timer in \(.applicationName)",
                "Set a timer in \(.applicationName)",
                "Create timer in \(.applicationName)"
            ],
            shortTitle: "Start Timer",
            systemImageName: "timer"
        )

        AppShortcut(
            intent: StopTimerIntent(),
            phrases: [
                "Stop timer in \(.applicationName)",
                "Cancel timer in \(.applicationName)",
                "Stop all timers in \(.applicationName)"
            ],
            shortTitle: "Stop Timer",
            systemImageName: "stop.circle"
        )

        AppShortcut(
            intent: GetTimerStatusIntent(),
            phrases: [
                "Timer status in \(.applicationName)",
                "Check timer in \(.applicationName)",
                "How much time left in \(.applicationName)"
            ],
            shortTitle: "Timer Status",
            systemImageName: "clock"
        )
    }
}
