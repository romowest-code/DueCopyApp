//
//  TimerItem.swift
//  ContractorMustDo
//
//  Timer model for countdown timers and job time tracking.
//

import Foundation
import SwiftData

// MARK: - Timer Item Model

/// Represents a countdown timer for job time tracking.
///
/// Supports REQ-6.x: Timer features for contractors
@Model
final class TimerItem {
    // MARK: - Core Properties

    /// Unique identifier for the timer
    @Attribute(.unique) var id: UUID

    /// Timer name/label
    var name: String

    /// Total duration in seconds
    var durationSeconds: TimeInterval

    /// Remaining time in seconds
    var remainingSeconds: TimeInterval

    /// Whether the timer is currently running
    var isRunning: Bool

    /// Whether the timer is paused
    var isPaused: Bool

    /// When the timer was started (nil if not started)
    var startDate: Date?

    /// When the timer was last paused
    var pausedDate: Date?

    /// When the timer was created
    var createdDate: Date

    // MARK: - Alert Properties

    /// The alert sound to play when timer completes
    var alertSoundRawValue: String

    /// Whether to repeat the alert until acknowledged
    var repeatAlert: Bool

    /// Optional task to trigger reminder for when timer completes
    var linkedTaskID: UUID?

    // MARK: - Preset Properties

    /// Whether this is a preset timer
    var isPreset: Bool

    /// Display order for presets
    var sortOrder: Int

    // MARK: - Computed Properties

    /// The alert sound as an enum
    var alertSound: AlertSound {
        get { AlertSound(rawValue: alertSoundRawValue) ?? .default }
        set { alertSoundRawValue = newValue.rawValue }
    }

    /// Whether the timer has completed
    var isCompleted: Bool {
        remainingSeconds <= 0 && !isRunning
    }

    /// Progress as a value from 0 to 1
    var progress: Double {
        guard durationSeconds > 0 else { return 0 }
        return 1.0 - (remainingSeconds / durationSeconds)
    }

    /// Formatted remaining time string (MM:SS or HH:MM:SS)
    var formattedRemainingTime: String {
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

    /// Creates a new timer with the specified properties.
    ///
    /// - Parameters:
    ///   - name: The timer name
    ///   - durationSeconds: Total duration in seconds
    ///   - alertSound: Sound to play when timer completes
    ///   - repeatAlert: Whether to repeat the alert
    ///   - isPreset: Whether this is a preset timer
    ///   - sortOrder: Display order for presets
    init(
        name: String,
        durationSeconds: TimeInterval,
        alertSound: AlertSound = .default,
        repeatAlert: Bool = false,
        isPreset: Bool = false,
        sortOrder: Int = 0
    ) {
        self.id = UUID()
        self.name = name
        self.durationSeconds = durationSeconds
        self.remainingSeconds = durationSeconds
        self.isRunning = false
        self.isPaused = false
        self.startDate = nil
        self.pausedDate = nil
        self.createdDate = Date()
        self.alertSoundRawValue = alertSound.rawValue
        self.repeatAlert = repeatAlert
        self.linkedTaskID = nil
        self.isPreset = isPreset
        self.sortOrder = sortOrder
    }

    // MARK: - Methods

    /// Starts the timer.
    func start() {
        if isPaused {
            // Resume from pause
            if let pausedAt = pausedDate {
                let pauseDuration = Date().timeIntervalSince(pausedAt)
                startDate = startDate?.addingTimeInterval(pauseDuration)
            }
            isPaused = false
        } else {
            // Fresh start
            startDate = Date()
            remainingSeconds = durationSeconds
        }
        isRunning = true
        pausedDate = nil
    }

    /// Pauses the timer.
    func pause() {
        guard isRunning else { return }
        isPaused = true
        isRunning = false
        pausedDate = Date()
        updateRemainingTime()
    }

    /// Stops and resets the timer.
    func stop() {
        isRunning = false
        isPaused = false
        remainingSeconds = durationSeconds
        startDate = nil
        pausedDate = nil
    }

    /// Updates the remaining time based on elapsed time since start.
    func updateRemainingTime() {
        guard isRunning, let start = startDate else { return }
        let elapsed = Date().timeIntervalSince(start)
        remainingSeconds = max(0, durationSeconds - elapsed)

        if remainingSeconds <= 0 {
            isRunning = false
        }
    }

    /// Creates a copy of this timer for reuse.
    func duplicate() -> TimerItem {
        TimerItem(
            name: name,
            durationSeconds: durationSeconds,
            alertSound: alertSound,
            repeatAlert: repeatAlert,
            isPreset: false,
            sortOrder: 0
        )
    }
}

// MARK: - Timer Presets

/// Standard timer presets for common use cases.
///
/// - REQ-6.3: Timer presets
enum TimerPreset: CaseIterable {
    case fifteenMinuteBreak
    case thirtyMinuteBreak
    case oneHourFocus
    case pomodoro

    var name: String {
        switch self {
        case .fifteenMinuteBreak: return Strings.Timer.fifteenMinuteBreak
        case .thirtyMinuteBreak: return Strings.Timer.thirtyMinuteBreak
        case .oneHourFocus: return Strings.Timer.oneHourFocus
        case .pomodoro: return Strings.Timer.pomodoro
        }
    }

    var durationSeconds: TimeInterval {
        switch self {
        case .fifteenMinuteBreak: return 15 * 60
        case .thirtyMinuteBreak: return 30 * 60
        case .oneHourFocus: return 60 * 60
        case .pomodoro: return 25 * 60
        }
    }

    func createTimer() -> TimerItem {
        TimerItem(
            name: name,
            durationSeconds: durationSeconds,
            isPreset: true,
            sortOrder: Self.allCases.firstIndex(of: self) ?? 0
        )
    }
}

// MARK: - Alert Sound

/// Available alert sounds for timer completion.
///
/// - REQ-8.1: Multiple alert sounds
enum AlertSound: String, CaseIterable, Codable {
    case `default` = "default"
    case bell = "bell"
    case chime = "chime"
    case alarm = "alarm"
    case loud = "loud"
    case airhorn = "airhorn"

    var displayName: String {
        switch self {
        case .default: return Strings.Sound.defaultSound
        case .bell: return Strings.Sound.bell
        case .chime: return Strings.Sound.chime
        case .alarm: return Strings.Sound.alarm
        case .loud: return Strings.Sound.loud
        case .airhorn: return Strings.Sound.airhorn
        }
    }

    var soundFileName: String {
        switch self {
        case .default: return "default_alert"
        case .bell: return "bell_alert"
        case .chime: return "chime_alert"
        case .alarm: return "alarm_alert"
        case .loud: return "loud_alert"
        case .airhorn: return "airhorn_alert"
        }
    }
}
