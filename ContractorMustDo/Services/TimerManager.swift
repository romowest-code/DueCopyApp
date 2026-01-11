//
//  TimerManager.swift
//  ContractorMustDo
//
//  Manages active countdown timers.
//

import Foundation
import Combine

// MARK: - Timer Manager

/// Manages active countdown timers with background support.
///
/// Supports REQ-6.x: Timer features for job time tracking.
final class TimerManager: ObservableObject {
    // MARK: - Singleton

    static let shared = TimerManager()

    // MARK: - Properties

    /// Currently active timers
    @Published private(set) var activeTimers: [UUID: TimerState] = [:]

    /// Timer for updating all active timers
    private var updateTimer: Timer?

    /// Cancellables for Combine subscriptions
    private var cancellables = Set<AnyCancellable>()

    /// Background task identifier
    private var backgroundTaskID: UIBackgroundTaskIdentifier = .invalid

    // MARK: - Initialization

    private init() {
        setupNotificationObservers()
    }

    // MARK: - Public Methods

    /// Starts a timer.
    ///
    /// - Parameter timer: The timer item to start.
    func start(_ timer: TimerItem) {
        let state = TimerState(timer: timer)
        state.start()
        activeTimers[timer.id] = state

        // Schedule notification
        NotificationService.shared.scheduleTimerNotification(for: timer)

        startUpdateTimer()
    }

    /// Pauses a timer.
    ///
    /// - Parameter timerID: The ID of the timer to pause.
    func pause(_ timerID: UUID) {
        activeTimers[timerID]?.pause()
        cancelNotification(for: timerID)
    }

    /// Resumes a paused timer.
    ///
    /// - Parameter timerID: The ID of the timer to resume.
    func resume(_ timerID: UUID) {
        guard let state = activeTimers[timerID] else { return }
        state.resume()

        // Reschedule notification
        if let timer = state.timer {
            NotificationService.shared.scheduleTimerNotification(for: timer)
        }
    }

    /// Stops and removes a timer.
    ///
    /// - Parameter timerID: The ID of the timer to stop.
    func stop(_ timerID: UUID) {
        activeTimers.removeValue(forKey: timerID)
        cancelNotification(for: timerID)

        if activeTimers.isEmpty {
            stopUpdateTimer()
        }
    }

    /// Returns the remaining time for a timer.
    ///
    /// - Parameter timerID: The ID of the timer.
    /// - Returns: The remaining time in seconds, or nil if not found.
    func remainingTime(for timerID: UUID) -> TimeInterval? {
        activeTimers[timerID]?.remainingSeconds
    }

    /// Returns whether a timer is running.
    ///
    /// - Parameter timerID: The ID of the timer.
    /// - Returns: True if the timer is running.
    func isRunning(_ timerID: UUID) -> Bool {
        activeTimers[timerID]?.isRunning ?? false
    }

    /// Returns whether a timer is paused.
    ///
    /// - Parameter timerID: The ID of the timer.
    /// - Returns: True if the timer is paused.
    func isPaused(_ timerID: UUID) -> Bool {
        activeTimers[timerID]?.isPaused ?? false
    }

    // MARK: - Private Methods

    private func setupNotificationObservers() {
        NotificationCenter.default.publisher(for: UIApplication.willResignActiveNotification)
            .sink { [weak self] _ in
                self?.handleAppBackgrounding()
            }
            .store(in: &cancellables)

        NotificationCenter.default.publisher(for: UIApplication.didBecomeActiveNotification)
            .sink { [weak self] _ in
                self?.handleAppForegrounding()
            }
            .store(in: &cancellables)
    }

    private func handleAppBackgrounding() {
        // Store background entry time for all active timers
        for (_, state) in activeTimers where state.isRunning {
            state.backgroundEntryDate = Date()
        }

        // Start background task
        backgroundTaskID = UIApplication.shared.beginBackgroundTask { [weak self] in
            self?.endBackgroundTask()
        }
    }

    private func handleAppForegrounding() {
        // Update all timers based on elapsed background time
        for (_, state) in activeTimers where state.isRunning {
            state.updateAfterBackground()
        }

        endBackgroundTask()
    }

    private func endBackgroundTask() {
        if backgroundTaskID != .invalid {
            UIApplication.shared.endBackgroundTask(backgroundTaskID)
            backgroundTaskID = .invalid
        }
    }

    private func startUpdateTimer() {
        guard updateTimer == nil else { return }

        updateTimer = Timer.scheduledTimer(withTimeInterval: 0.1, repeats: true) { [weak self] _ in
            self?.updateAllTimers()
        }
        RunLoop.current.add(updateTimer!, forMode: .common)
    }

    private func stopUpdateTimer() {
        updateTimer?.invalidate()
        updateTimer = nil
    }

    private func updateAllTimers() {
        var completedTimers: [UUID] = []

        for (id, state) in activeTimers {
            if state.isRunning {
                state.update()

                if state.isComplete {
                    completedTimers.append(id)
                    handleTimerCompletion(state)
                }
            }
        }

        // Publish changes
        objectWillChange.send()

        // Remove completed timers
        for id in completedTimers {
            activeTimers.removeValue(forKey: id)
        }

        if activeTimers.isEmpty {
            stopUpdateTimer()
        }
    }

    private func handleTimerCompletion(_ state: TimerState) {
        guard let timer = state.timer else { return }

        // Post notification for UI handling
        NotificationCenter.default.post(
            name: .timerCompleted,
            object: nil,
            userInfo: ["timerId": timer.id]
        )
    }

    private func cancelNotification(for timerID: UUID) {
        let identifier = "timer-\(timerID.uuidString)"
        UNUserNotificationCenter.current()
            .removePendingNotificationRequests(withIdentifiers: [identifier])
    }
}

// MARK: - Timer State

/// Tracks the live state of a running timer.
final class TimerState: ObservableObject {
    // MARK: - Properties

    weak var timer: TimerItem?

    @Published private(set) var remainingSeconds: TimeInterval
    @Published private(set) var isRunning = false
    @Published private(set) var isPaused = false

    private var startDate: Date?
    private var pausedDate: Date?
    private let totalDuration: TimeInterval

    var backgroundEntryDate: Date?

    var isComplete: Bool {
        remainingSeconds <= 0
    }

    var progress: Double {
        guard totalDuration > 0 else { return 0 }
        return 1.0 - (remainingSeconds / totalDuration)
    }

    var formattedTime: String {
        let hours = Int(remainingSeconds) / 3600
        let minutes = (Int(remainingSeconds) % 3600) / 60
        let seconds = Int(remainingSeconds) % 60

        if hours > 0 {
            return String(format: "%02d:%02d:%02d", hours, minutes, seconds)
        } else {
            return String(format: "%02d:%02d", minutes, seconds)
        }
    }

    // MARK: - Initialization

    init(timer: TimerItem) {
        self.timer = timer
        self.totalDuration = timer.durationSeconds
        self.remainingSeconds = timer.remainingSeconds
    }

    // MARK: - Methods

    func start() {
        startDate = Date()
        isRunning = true
        isPaused = false
    }

    func pause() {
        pausedDate = Date()
        isPaused = true
        isRunning = false
    }

    func resume() {
        if let paused = pausedDate, let start = startDate {
            let pauseDuration = Date().timeIntervalSince(paused)
            startDate = start.addingTimeInterval(pauseDuration)
        }
        pausedDate = nil
        isPaused = false
        isRunning = true
    }

    func update() {
        guard isRunning, let start = startDate else { return }
        let elapsed = Date().timeIntervalSince(start)
        remainingSeconds = max(0, totalDuration - elapsed)
    }

    func updateAfterBackground() {
        guard let backgroundEntry = backgroundEntryDate, let start = startDate else { return }
        let backgroundDuration = Date().timeIntervalSince(backgroundEntry)
        let totalElapsed = backgroundEntry.timeIntervalSince(start) + backgroundDuration
        remainingSeconds = max(0, totalDuration - totalElapsed)
        backgroundEntryDate = nil
    }
}

// MARK: - Notification Names

extension Notification.Name {
    static let timerCompleted = Notification.Name("timerCompleted")
}

// MARK: - UIApplication Extension for Background Task

#if canImport(UIKit)
import UIKit
#endif
