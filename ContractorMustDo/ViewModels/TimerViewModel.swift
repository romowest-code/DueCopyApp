//
//  TimerViewModel.swift
//  ContractorMustDo
//
//  View model for timer management.
//

import Foundation
import SwiftUI
import SwiftData
import Combine

// MARK: - Timer View Model

/// View model for managing countdown timers.
///
/// Supports REQ-6.x: Timer features for job time tracking.
@MainActor
final class TimerViewModel: ObservableObject {
    // MARK: - Published Properties

    /// Whether the add timer sheet is presented
    @Published var showingAddTimer = false

    /// Currently selected timer for editing
    @Published var selectedTimer: TimerItem?

    /// Custom duration input (hours)
    @Published var customHours = 0

    /// Custom duration input (minutes)
    @Published var customMinutes = 0

    /// Custom duration input (seconds)
    @Published var customSeconds = 0

    /// Custom timer name
    @Published var customName = ""

    /// Error message to display
    @Published var errorMessage: String?

    // MARK: - Properties

    private let timerManager = TimerManager.shared
    private let notificationService = NotificationService.shared
    private var cancellables = Set<AnyCancellable>()

    // MARK: - Computed Properties

    /// Total custom duration in seconds
    var customDuration: TimeInterval {
        TimeInterval(customHours * 3600 + customMinutes * 60 + customSeconds)
    }

    /// Whether the custom duration is valid
    var isCustomDurationValid: Bool {
        customDuration > 0
    }

    // MARK: - Initialization

    init() {
        setupNotificationHandlers()
    }

    // MARK: - Timer Operations

    /// Creates and starts a timer from a preset.
    ///
    /// - Parameters:
    ///   - preset: The timer preset to use.
    ///   - context: The SwiftData model context.
    /// - Returns: The created timer.
    @discardableResult
    func createFromPreset(
        _ preset: TimerPreset,
        context: ModelContext
    ) -> TimerItem {
        let timer = preset.createTimer()
        context.insert(timer)
        timerManager.start(timer)
        return timer
    }

    /// Creates a custom timer.
    ///
    /// - Parameters:
    ///   - context: The SwiftData model context.
    /// - Returns: The created timer, or nil if invalid.
    @discardableResult
    func createCustomTimer(context: ModelContext) -> TimerItem? {
        guard isCustomDurationValid else {
            errorMessage = "Please enter a valid duration"
            return nil
        }

        let name = customName.isEmpty ? Strings.Timer.addTimer : customName

        let timer = TimerItem(
            name: name,
            durationSeconds: customDuration,
            alertSound: SettingsManager.shared.defaultAlertSound
        )

        context.insert(timer)
        resetCustomInput()

        return timer
    }

    /// Starts a timer.
    ///
    /// - Parameter timer: The timer to start.
    func startTimer(_ timer: TimerItem) {
        timer.start()
        timerManager.start(timer)
    }

    /// Pauses a timer.
    ///
    /// - Parameter timer: The timer to pause.
    func pauseTimer(_ timer: TimerItem) {
        timer.pause()
        timerManager.pause(timer.id)
    }

    /// Resumes a paused timer.
    ///
    /// - Parameter timer: The timer to resume.
    func resumeTimer(_ timer: TimerItem) {
        timer.start()
        timerManager.resume(timer.id)
    }

    /// Stops a timer.
    ///
    /// - Parameter timer: The timer to stop.
    func stopTimer(_ timer: TimerItem) {
        timer.stop()
        timerManager.stop(timer.id)
    }

    /// Resets a timer to its original duration.
    ///
    /// - Parameter timer: The timer to reset.
    func resetTimer(_ timer: TimerItem) {
        timer.stop()
        timerManager.stop(timer.id)
    }

    /// Deletes a timer.
    ///
    /// - Parameters:
    ///   - timer: The timer to delete.
    ///   - context: The SwiftData model context.
    func deleteTimer(_ timer: TimerItem, context: ModelContext) {
        timerManager.stop(timer.id)
        notificationService.cancelTimerNotification(for: timer)
        context.delete(timer)
    }

    /// Duplicates a timer.
    ///
    /// - Parameters:
    ///   - timer: The timer to duplicate.
    ///   - context: The SwiftData model context.
    /// - Returns: The duplicated timer.
    @discardableResult
    func duplicateTimer(_ timer: TimerItem, context: ModelContext) -> TimerItem {
        let duplicate = timer.duplicate()
        context.insert(duplicate)
        return duplicate
    }

    // MARK: - Quick Timer Actions

    /// Creates and starts a quick timer with the specified duration.
    ///
    /// - Parameters:
    ///   - minutes: Duration in minutes.
    ///   - context: The SwiftData model context.
    /// - Returns: The created timer.
    @discardableResult
    func createQuickTimer(minutes: Int, context: ModelContext) -> TimerItem {
        let timer = TimerItem(
            name: "\(minutes) min timer",
            durationSeconds: TimeInterval(minutes * 60),
            alertSound: SettingsManager.shared.defaultAlertSound
        )

        context.insert(timer)
        timerManager.start(timer)

        return timer
    }

    // MARK: - State Queries

    /// Returns the live remaining time for a timer.
    ///
    /// - Parameter timer: The timer to check.
    /// - Returns: The remaining time in seconds.
    func liveRemainingTime(for timer: TimerItem) -> TimeInterval {
        timerManager.remainingTime(for: timer.id) ?? timer.remainingSeconds
    }

    /// Returns whether a timer is actively running.
    ///
    /// - Parameter timer: The timer to check.
    /// - Returns: True if running.
    func isTimerRunning(_ timer: TimerItem) -> Bool {
        timerManager.isRunning(timer.id)
    }

    /// Returns whether a timer is paused.
    ///
    /// - Parameter timer: The timer to check.
    /// - Returns: True if paused.
    func isTimerPaused(_ timer: TimerItem) -> Bool {
        timerManager.isPaused(timer.id)
    }

    // MARK: - Helper Methods

    /// Resets the custom timer input fields.
    func resetCustomInput() {
        customHours = 0
        customMinutes = 0
        customSeconds = 0
        customName = ""
    }

    /// Formats a duration for display.
    ///
    /// - Parameter seconds: Duration in seconds.
    /// - Returns: Formatted string.
    func formatDuration(_ seconds: TimeInterval) -> String {
        let hours = Int(seconds) / 3600
        let minutes = (Int(seconds) % 3600) / 60
        let secs = Int(seconds) % 60

        if hours > 0 {
            return String(format: "%02d:%02d:%02d", hours, minutes, secs)
        } else {
            return String(format: "%02d:%02d", minutes, secs)
        }
    }

    // MARK: - Private Methods

    private func setupNotificationHandlers() {
        NotificationCenter.default.publisher(for: .timerCompleted)
            .sink { [weak self] notification in
                self?.handleTimerCompletion(notification)
            }
            .store(in: &cancellables)
    }

    private func handleTimerCompletion(_ notification: Notification) {
        guard let userInfo = notification.userInfo,
              let timerId = userInfo["timerId"] as? UUID else {
            return
        }

        // Trigger UI update
        objectWillChange.send()

        // Post for UI handling (e.g., showing completion alert)
        NotificationCenter.default.post(
            name: .timerCompletionUI,
            object: nil,
            userInfo: ["timerId": timerId]
        )
    }
}

// MARK: - Notification Names

extension Notification.Name {
    static let timerCompletionUI = Notification.Name("timerCompletionUI")
}
