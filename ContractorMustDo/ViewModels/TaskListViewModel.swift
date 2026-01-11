//
//  TaskListViewModel.swift
//  ContractorMustDo
//
//  View model for the main task list.
//

import Foundation
import SwiftUI
import SwiftData
import Combine

// MARK: - Task List View Model

/// View model managing the task list display and operations.
///
/// Handles task CRUD operations, sorting, filtering, and notification scheduling.
@MainActor
final class TaskListViewModel: ObservableObject {
    // MARK: - Published Properties

    /// Current filter for the task list
    @Published var filter: TaskFilter = .all

    /// Current sort order
    @Published var sortOrder: TaskSortOrder = .dueDate

    /// Search query for filtering tasks
    @Published var searchQuery = ""

    /// Whether to show completed tasks
    @Published var showCompleted: Bool

    /// Currently selected task for detail view
    @Published var selectedTask: TaskItem?

    /// Whether the add task sheet is presented
    @Published var showingAddTask = false

    /// Error message to display
    @Published var errorMessage: String?

    // MARK: - Properties

    private let notificationService = NotificationService.shared
    private let parser = NaturalLanguageParser.shared
    private var cancellables = Set<AnyCancellable>()

    // MARK: - Initialization

    init() {
        self.showCompleted = SettingsManager.shared.showCompletedTasks
        setupNotificationHandlers()
    }

    // MARK: - Task Operations

    /// Adds a new task.
    ///
    /// - Parameters:
    ///   - title: The task title.
    ///   - dueDate: When the task is due.
    ///   - notes: Optional notes.
    ///   - nagLevel: The nag level for reminders.
    ///   - snoozeInterval: The snooze interval.
    ///   - recurrenceType: Optional recurrence pattern.
    ///   - recurrenceDays: Days for weekly recurrence.
    ///   - context: The SwiftData model context.
    /// - Returns: The created task.
    @discardableResult
    func addTask(
        title: String,
        dueDate: Date,
        notes: String = "",
        nagLevel: NagLevel = .moderate,
        snoozeInterval: SnoozeInterval = .fiveMinutes,
        escalatingEnabled: Bool = false,
        recurrenceType: RecurrenceType? = nil,
        recurrenceDays: [Int] = [],
        recurrenceInterval: Int = 1,
        repeatFromCompletion: Bool = false,
        context: ModelContext
    ) -> TaskItem {
        let task = TaskItem(
            title: title,
            dueDate: dueDate,
            notes: notes,
            nagLevel: nagLevel,
            snoozeInterval: snoozeInterval,
            escalatingEnabled: escalatingEnabled,
            recurrenceType: recurrenceType,
            recurrenceDays: recurrenceDays,
            recurrenceInterval: recurrenceInterval,
            repeatFromCompletion: repeatFromCompletion
        )

        context.insert(task)
        scheduleNotification(for: task)
        updateBadgeCount(context: context)

        return task
    }

    /// Adds a task from natural language input.
    ///
    /// - Parameters:
    ///   - input: The natural language string.
    ///   - context: The SwiftData model context.
    /// - Returns: The created task, or nil if parsing failed.
    @discardableResult
    func addTaskFromNaturalLanguage(
        _ input: String,
        context: ModelContext
    ) -> TaskItem? {
        let parsed = parser.parse(input)

        guard !parsed.title.isEmpty else {
            errorMessage = "Could not parse task from input"
            return nil
        }

        let dueDate = parsed.dueDate ?? Date().addingTimeInterval(3600) // Default to 1 hour from now

        var recurrenceType: RecurrenceType?
        var recurrenceDays: [Int] = []
        var recurrenceInterval = 1

        if let recurrence = parsed.recurrence {
            recurrenceType = recurrence.type
            recurrenceDays = recurrence.days
            recurrenceInterval = recurrence.interval
        }

        return addTask(
            title: parsed.title,
            dueDate: dueDate,
            recurrenceType: recurrenceType,
            recurrenceDays: recurrenceDays,
            recurrenceInterval: recurrenceInterval,
            context: context
        )
    }

    /// Marks a task as completed.
    ///
    /// - Parameters:
    ///   - task: The task to complete.
    ///   - context: The SwiftData model context.
    func completeTask(_ task: TaskItem, context: ModelContext) {
        // Cancel pending notifications
        notificationService.cancelNotifications(for: task)

        // Mark completed and handle recurrence
        if let nextTask = task.markCompleted() {
            context.insert(nextTask)
            scheduleNotification(for: nextTask)
        }

        updateBadgeCount(context: context)
    }

    /// Toggles task completion status.
    ///
    /// - Parameters:
    ///   - task: The task to toggle.
    ///   - context: The SwiftData model context.
    func toggleCompletion(_ task: TaskItem, context: ModelContext) {
        if task.isCompleted {
            // Uncomplete the task
            task.isCompleted = false
            task.completedDate = nil
            scheduleNotification(for: task)
        } else {
            completeTask(task, context: context)
        }
        updateBadgeCount(context: context)
    }

    /// Snoozes a task.
    ///
    /// - Parameters:
    ///   - task: The task to snooze.
    ///   - interval: Optional custom snooze interval.
    func snoozeTask(_ task: TaskItem, interval: SnoozeInterval? = nil) {
        task.snooze()

        let snoozeSeconds = interval?.seconds ?? task.snoozeIntervalSeconds
        task.dueDate = Date().addingTimeInterval(snoozeSeconds)

        notificationService.cancelNotifications(for: task)
        scheduleNotification(for: task)
    }

    /// Deletes a task.
    ///
    /// - Parameters:
    ///   - task: The task to delete.
    ///   - context: The SwiftData model context.
    func deleteTask(_ task: TaskItem, context: ModelContext) {
        notificationService.cancelNotifications(for: task)
        context.delete(task)
        updateBadgeCount(context: context)
    }

    /// Deletes multiple tasks.
    ///
    /// - Parameters:
    ///   - tasks: The tasks to delete.
    ///   - context: The SwiftData model context.
    func deleteTasks(_ tasks: [TaskItem], context: ModelContext) {
        for task in tasks {
            notificationService.cancelNotifications(for: task)
            context.delete(task)
        }
        updateBadgeCount(context: context)
    }

    // MARK: - Filtering and Sorting

    /// Returns filtered and sorted tasks.
    ///
    /// - Parameter tasks: The full list of tasks.
    /// - Returns: Filtered and sorted tasks.
    func filteredTasks(_ tasks: [TaskItem]) -> [TaskItem] {
        var result = tasks

        // Apply completion filter
        if !showCompleted {
            result = result.filter { !$0.isCompleted }
        }

        // Apply category filter
        switch filter {
        case .all:
            break
        case .overdue:
            result = result.filter { $0.isOverdue }
        case .today:
            result = result.filter { $0.isDueToday }
        case .upcoming:
            result = result.filter { !$0.isOverdue && !$0.isDueToday && !$0.isCompleted }
        case .completed:
            result = result.filter { $0.isCompleted }
        }

        // Apply search filter
        if !searchQuery.isEmpty {
            result = result.filter {
                $0.title.localizedCaseInsensitiveContains(searchQuery) ||
                $0.notes.localizedCaseInsensitiveContains(searchQuery)
            }
        }

        // Apply sorting
        return sortTasks(result)
    }

    /// Groups tasks by section.
    ///
    /// - Parameter tasks: The filtered tasks.
    /// - Returns: Dictionary of section to tasks.
    func groupedTasks(_ tasks: [TaskItem]) -> [(section: TaskSection, tasks: [TaskItem])] {
        let filtered = filteredTasks(tasks)
        var groups: [(section: TaskSection, tasks: [TaskItem])] = []

        let overdue = filtered.filter { $0.isOverdue }
        if !overdue.isEmpty {
            groups.append((.overdue, overdue))
        }

        let today = filtered.filter { $0.isDueToday && !$0.isOverdue && !$0.isCompleted }
        if !today.isEmpty {
            groups.append((.today, today))
        }

        let upcoming = filtered.filter { !$0.isOverdue && !$0.isDueToday && !$0.isCompleted }
        if !upcoming.isEmpty {
            groups.append((.upcoming, upcoming))
        }

        if showCompleted {
            let completed = filtered.filter { $0.isCompleted }
            if !completed.isEmpty {
                groups.append((.completed, completed))
            }
        }

        return groups
    }

    /// Returns the count of overdue tasks.
    ///
    /// - Parameter tasks: All tasks.
    /// - Returns: Number of overdue tasks.
    func overdueCount(_ tasks: [TaskItem]) -> Int {
        tasks.filter { $0.isOverdue }.count
    }

    /// Returns the count of tasks due today.
    ///
    /// - Parameter tasks: All tasks.
    /// - Returns: Number of tasks due today.
    func todayCount(_ tasks: [TaskItem]) -> Int {
        tasks.filter { $0.isDueToday && !$0.isCompleted }.count
    }

    // MARK: - Private Methods

    private func sortTasks(_ tasks: [TaskItem]) -> [TaskItem] {
        switch sortOrder {
        case .dueDate:
            return tasks.sorted { $0.dueDate < $1.dueDate }
        case .title:
            return tasks.sorted { $0.title.localizedCompare($1.title) == .orderedAscending }
        case .createdDate:
            return tasks.sorted { $0.createdDate > $1.createdDate }
        case .nagLevel:
            return tasks.sorted {
                NagLevel.allCases.firstIndex(of: $0.nagLevel) ?? 0 >
                NagLevel.allCases.firstIndex(of: $1.nagLevel) ?? 0
            }
        }
    }

    private func scheduleNotification(for task: TaskItem) {
        notificationService.scheduleNotification(for: task) { identifier in
            DispatchQueue.main.async {
                task.notificationIdentifier = identifier
            }
        }
    }

    private func updateBadgeCount(context: ModelContext) {
        let descriptor = FetchDescriptor<TaskItem>(
            predicate: #Predicate { !$0.isCompleted }
        )

        if let count = try? context.fetchCount(descriptor) {
            notificationService.updateBadgeCount(count)
        }
    }

    private func setupNotificationHandlers() {
        NotificationCenter.default.publisher(for: .taskNotificationAction)
            .sink { [weak self] notification in
                self?.handleNotificationAction(notification)
            }
            .store(in: &cancellables)
    }

    private func handleNotificationAction(_ notification: Notification) {
        guard let userInfo = notification.userInfo,
              let taskId = userInfo["taskId"] as? UUID,
              let actionIdentifier = userInfo["actionIdentifier"] as? String else {
            return
        }

        // Post notification for views to handle
        NotificationCenter.default.post(
            name: .taskActionRequested,
            object: nil,
            userInfo: ["taskId": taskId, "action": actionIdentifier]
        )
    }
}

// MARK: - Task Filter

/// Filter options for the task list.
enum TaskFilter: String, CaseIterable {
    case all
    case overdue
    case today
    case upcoming
    case completed

    var displayName: String {
        switch self {
        case .all: return Strings.Task.allTasks
        case .overdue: return Strings.Task.overdue
        case .today: return Strings.Task.today
        case .upcoming: return Strings.Task.upcoming
        case .completed: return Strings.Task.completed
        }
    }
}

// MARK: - Task Sort Order

/// Sort order options for the task list.
enum TaskSortOrder: String, CaseIterable {
    case dueDate
    case title
    case createdDate
    case nagLevel

    var displayName: String {
        switch self {
        case .dueDate: return Strings.Task.dueDate
        case .title: return "Title"
        case .createdDate: return "Created"
        case .nagLevel: return "Priority"
        }
    }
}

// MARK: - Task Section

/// Section headers for grouped task display.
enum TaskSection: String, CaseIterable {
    case overdue
    case today
    case upcoming
    case completed

    var displayName: String {
        switch self {
        case .overdue: return Strings.Task.overdue
        case .today: return Strings.Task.today
        case .upcoming: return Strings.Task.upcoming
        case .completed: return Strings.Task.completed
        }
    }

    var color: Color {
        switch self {
        case .overdue: return .red
        case .today: return .orange
        case .upcoming: return .blue
        case .completed: return .green
        }
    }
}

// MARK: - Notification Names

extension Notification.Name {
    static let taskActionRequested = Notification.Name("taskActionRequested")
}
