//
//  NotificationService.swift
//  ContractorMustDo
//
//  Handles all notification scheduling, nagging, and auto-snooze logic.
//

import Foundation
import UserNotifications
import Combine

// MARK: - Notification Service

/// Manages the persistent nagging notification system.
///
/// This is the core feature of the app, handling:
/// - REQ-1.1: Auto-snooze until task completion or explicit rescheduling
/// - REQ-1.2: Customizable snooze intervals
/// - REQ-1.3: Escalating notification intensity
/// - REQ-1.4: Nag level settings per task
final class NotificationService: NSObject, ObservableObject {
    // MARK: - Singleton

    static let shared = NotificationService()

    // MARK: - Properties

    private let center = UNUserNotificationCenter.current()

    /// Whether notification permission has been granted
    @Published private(set) var isAuthorized = false

    /// Pending task IDs waiting for quiet hours to end
    private var quietHoursQueue: Set<UUID> = []

    // MARK: - Notification Categories

    private static let taskCategoryIdentifier = "TASK_REMINDER"
    private static let timerCategoryIdentifier = "TIMER_COMPLETE"
    private static let snoozeActionIdentifier = "SNOOZE_ACTION"
    private static let completeActionIdentifier = "COMPLETE_ACTION"
    private static let dismissActionIdentifier = "DISMISS_ACTION"

    // MARK: - Initialization

    private override init() {
        super.init()
        center.delegate = self
        setupNotificationCategories()
        checkAuthorizationStatus()
    }

    // MARK: - Authorization

    /// Requests notification authorization from the user.
    ///
    /// - Returns: Whether authorization was granted.
    @discardableResult
    func requestAuthorization() async -> Bool {
        do {
            let options: UNAuthorizationOptions = [.alert, .sound, .badge, .criticalAlert]
            let granted = try await center.requestAuthorization(options: options)
            await MainActor.run {
                self.isAuthorized = granted
            }
            return granted
        } catch {
            print("Notification authorization error: \(error)")
            return false
        }
    }

    /// Checks current authorization status.
    func checkAuthorizationStatus() {
        center.getNotificationSettings { settings in
            DispatchQueue.main.async {
                self.isAuthorized = settings.authorizationStatus == .authorized
            }
        }
    }

    // MARK: - Notification Categories Setup

    private func setupNotificationCategories() {
        // Task reminder category with snooze and complete actions
        let snoozeAction = UNNotificationAction(
            identifier: Self.snoozeActionIdentifier,
            title: Strings.Notification.snoozeAction,
            options: []
        )

        let completeAction = UNNotificationAction(
            identifier: Self.completeActionIdentifier,
            title: Strings.Notification.completeAction,
            options: [.destructive]
        )

        let taskCategory = UNNotificationCategory(
            identifier: Self.taskCategoryIdentifier,
            actions: [snoozeAction, completeAction],
            intentIdentifiers: [],
            options: [.customDismissAction]
        )

        // Timer complete category
        let dismissAction = UNNotificationAction(
            identifier: Self.dismissActionIdentifier,
            title: Strings.Common.done,
            options: []
        )

        let timerCategory = UNNotificationCategory(
            identifier: Self.timerCategoryIdentifier,
            actions: [dismissAction],
            intentIdentifiers: [],
            options: []
        )

        center.setNotificationCategories([taskCategory, timerCategory])
    }

    // MARK: - Task Notification Scheduling

    /// Schedules a notification for a task.
    ///
    /// - Parameters:
    ///   - task: The task to schedule a notification for.
    ///   - completion: Completion handler with the notification identifier.
    func scheduleNotification(
        for task: TaskItem,
        completion: ((String?) -> Void)? = nil
    ) {
        guard task.notificationsEnabled, !task.isCompleted else {
            completion?(nil)
            return
        }

        // Check quiet hours
        if SettingsManager.shared.isInQuietHours {
            quietHoursQueue.insert(task.id)
            completion?(nil)
            return
        }

        let content = createTaskNotificationContent(for: task)
        let trigger = createTrigger(for: task.dueDate)
        let identifier = "task-\(task.id.uuidString)"

        let request = UNNotificationRequest(
            identifier: identifier,
            content: content,
            trigger: trigger
        )

        center.add(request) { error in
            if let error = error {
                print("Failed to schedule notification: \(error)")
                completion?(nil)
            } else {
                completion?(identifier)
            }
        }
    }

    /// Schedules an auto-snooze notification for a task.
    ///
    /// This is the core nagging feature - after the initial notification,
    /// the app continues to send reminders at the snooze interval until
    /// the task is completed or explicitly rescheduled.
    ///
    /// - Parameters:
    ///   - task: The task to schedule auto-snooze for.
    ///   - completion: Completion handler with the notification identifier.
    func scheduleAutoSnooze(
        for task: TaskItem,
        completion: ((String?) -> Void)? = nil
    ) {
        guard task.notificationsEnabled, !task.isCompleted else {
            completion?(nil)
            return
        }

        // Calculate snooze interval based on nag level and escalation
        var interval = task.snoozeIntervalSeconds * task.nagLevel.frequencyMultiplier

        // Apply escalation if enabled
        if task.escalatingEnabled && task.escalationLevel > 0 {
            let escalationFactor = pow(0.75, Double(task.escalationLevel))
            interval *= escalationFactor
            interval = max(30, interval) // Minimum 30 seconds
        }

        // Check quiet hours
        if SettingsManager.shared.isInQuietHours {
            quietHoursQueue.insert(task.id)
            completion?(nil)
            return
        }

        let content = createAutoSnoozeContent(for: task)
        let trigger = UNTimeIntervalNotificationTrigger(
            timeInterval: interval,
            repeats: false
        )

        let identifier = "snooze-\(task.id.uuidString)-\(Date().timeIntervalSince1970)"

        let request = UNNotificationRequest(
            identifier: identifier,
            content: content,
            trigger: trigger
        )

        center.add(request) { error in
            if let error = error {
                print("Failed to schedule auto-snooze: \(error)")
                completion?(nil)
            } else {
                completion?(identifier)
            }
        }
    }

    /// Cancels all notifications for a task.
    ///
    /// - Parameter task: The task to cancel notifications for.
    func cancelNotifications(for task: TaskItem) {
        let identifierPrefix = "task-\(task.id.uuidString)"
        let snoozePrefix = "snooze-\(task.id.uuidString)"

        center.getPendingNotificationRequests { requests in
            let idsToRemove = requests
                .filter { $0.identifier.hasPrefix(identifierPrefix) || $0.identifier.hasPrefix(snoozePrefix) }
                .map { $0.identifier }
            self.center.removePendingNotificationRequests(withIdentifiers: idsToRemove)
        }

        quietHoursQueue.remove(task.id)
    }

    /// Cancels all pending notifications.
    func cancelAllNotifications() {
        center.removeAllPendingNotificationRequests()
        quietHoursQueue.removeAll()
    }

    // MARK: - Timer Notification Scheduling

    /// Schedules a notification for timer completion.
    ///
    /// - Parameters:
    ///   - timer: The timer to schedule a notification for.
    ///   - completion: Completion handler with the notification identifier.
    func scheduleTimerNotification(
        for timer: TimerItem,
        completion: ((String?) -> Void)? = nil
    ) {
        let content = UNMutableNotificationContent()
        content.title = Strings.Timer.timerComplete
        content.body = timer.name
        content.sound = UNNotificationSound(named: UNNotificationSoundName(timer.alertSound.soundFileName + ".caf"))
        content.categoryIdentifier = Self.timerCategoryIdentifier

        let trigger = UNTimeIntervalNotificationTrigger(
            timeInterval: timer.remainingSeconds,
            repeats: false
        )

        let identifier = "timer-\(timer.id.uuidString)"

        let request = UNNotificationRequest(
            identifier: identifier,
            content: content,
            trigger: trigger
        )

        center.add(request) { error in
            if let error = error {
                print("Failed to schedule timer notification: \(error)")
                completion?(nil)
            } else {
                completion?(identifier)
            }
        }
    }

    /// Cancels notification for a timer.
    ///
    /// - Parameter timer: The timer to cancel notification for.
    func cancelTimerNotification(for timer: TimerItem) {
        let identifier = "timer-\(timer.id.uuidString)"
        center.removePendingNotificationRequests(withIdentifiers: [identifier])
    }

    // MARK: - Badge Management

    /// Updates the app badge count.
    ///
    /// - Parameter count: The number to display on the badge.
    func updateBadgeCount(_ count: Int) {
        Task { @MainActor in
            try? await center.setBadgeCount(count)
        }
    }

    // MARK: - Quiet Hours

    /// Processes queued notifications when quiet hours end.
    func processQuietHoursQueue() {
        guard !SettingsManager.shared.isInQuietHours else { return }

        // Note: In a full implementation, this would fetch tasks from persistence
        // and reschedule notifications for all queued task IDs
        quietHoursQueue.removeAll()
    }

    // MARK: - Private Helpers

    private func createTaskNotificationContent(for task: TaskItem) -> UNMutableNotificationContent {
        let content = UNMutableNotificationContent()

        if task.isOverdue {
            content.title = Strings.Notification.taskOverdue
        } else {
            content.title = Strings.Notification.taskReminder
        }

        content.body = task.title

        if !task.notes.isEmpty {
            content.subtitle = task.notes
        }

        content.sound = .default
        content.categoryIdentifier = Self.taskCategoryIdentifier
        content.userInfo = ["taskId": task.id.uuidString]

        // Use critical alert for relentless nag level
        if task.nagLevel == .relentless {
            content.interruptionLevel = .critical
        }

        return content
    }

    private func createAutoSnoozeContent(for task: TaskItem) -> UNMutableNotificationContent {
        let content = UNMutableNotificationContent()
        content.title = Strings.Notification.taskReminder

        // Add snooze count to body if snoozed multiple times
        if task.snoozeCount > 0 {
            content.body = "\(task.title) (Reminder #\(task.snoozeCount + 1))"
        } else {
            content.body = task.title
        }

        content.sound = .default
        content.categoryIdentifier = Self.taskCategoryIdentifier
        content.userInfo = ["taskId": task.id.uuidString, "isAutoSnooze": true]

        // Escalate interruption level
        switch task.nagLevel {
        case .gentle:
            content.interruptionLevel = .passive
        case .moderate:
            content.interruptionLevel = .active
        case .relentless:
            content.interruptionLevel = .critical
        }

        return content
    }

    private func createTrigger(for date: Date) -> UNNotificationTrigger {
        if date <= Date() {
            // Immediate notification for overdue tasks
            return UNTimeIntervalNotificationTrigger(timeInterval: 1, repeats: false)
        } else {
            let dateComponents = Calendar.current.dateComponents(
                [.year, .month, .day, .hour, .minute, .second],
                from: date
            )
            return UNCalendarNotificationTrigger(dateMatching: dateComponents, repeats: false)
        }
    }
}

// MARK: - UNUserNotificationCenterDelegate

extension NotificationService: UNUserNotificationCenterDelegate {
    func userNotificationCenter(
        _ center: UNUserNotificationCenter,
        willPresent notification: UNNotification,
        withCompletionHandler completionHandler: @escaping (UNNotificationPresentationOptions) -> Void
    ) {
        // Show notification even when app is in foreground
        completionHandler([.banner, .sound, .badge])
    }

    func userNotificationCenter(
        _ center: UNUserNotificationCenter,
        didReceive response: UNNotificationResponse,
        withCompletionHandler completionHandler: @escaping () -> Void
    ) {
        let userInfo = response.notification.request.content.userInfo
        guard let taskIdString = userInfo["taskId"] as? String,
              let taskId = UUID(uuidString: taskIdString) else {
            completionHandler()
            return
        }

        // Post notification for the app to handle the action
        let actionInfo: [String: Any] = [
            "taskId": taskId,
            "actionIdentifier": response.actionIdentifier
        ]

        NotificationCenter.default.post(
            name: .taskNotificationAction,
            object: nil,
            userInfo: actionInfo
        )

        completionHandler()
    }
}

// MARK: - Notification Names

extension Notification.Name {
    static let taskNotificationAction = Notification.Name("taskNotificationAction")
    static let timerNotificationAction = Notification.Name("timerNotificationAction")
}
