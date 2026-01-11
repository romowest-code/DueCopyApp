//
//  SettingsManager.swift
//  ContractorMustDo
//
//  Manages app settings and user preferences.
//

import Foundation
import SwiftUI
import Combine

// MARK: - Settings Manager

/// Manages app-wide settings and user preferences.
///
/// Supports REQ-8.x: Customization features
final class SettingsManager: ObservableObject {
    // MARK: - Singleton

    static let shared = SettingsManager()

    // MARK: - Published Properties

    /// Current theme preference
    @Published var theme: Theme {
        didSet { UserDefaults.standard.set(theme.rawValue, forKey: Keys.theme) }
    }

    /// Default nag level for new tasks
    @Published var defaultNagLevel: NagLevel {
        didSet { UserDefaults.standard.set(defaultNagLevel.rawValue, forKey: Keys.defaultNagLevel) }
    }

    /// Default snooze interval for new tasks
    @Published var defaultSnoozeInterval: SnoozeInterval {
        didSet { UserDefaults.standard.set(defaultSnoozeInterval.seconds, forKey: Keys.defaultSnoozeInterval) }
    }

    /// Whether escalating notifications are enabled by default
    @Published var escalatingNotificationsEnabled: Bool {
        didSet { UserDefaults.standard.set(escalatingNotificationsEnabled, forKey: Keys.escalatingEnabled) }
    }

    /// Whether quiet hours are enabled
    @Published var quietHoursEnabled: Bool {
        didSet { UserDefaults.standard.set(quietHoursEnabled, forKey: Keys.quietHoursEnabled) }
    }

    /// Quiet hours start time
    @Published var quietHoursStart: Date {
        didSet { UserDefaults.standard.set(quietHoursStart.timeIntervalSince1970, forKey: Keys.quietHoursStart) }
    }

    /// Quiet hours end time
    @Published var quietHoursEnd: Date {
        didSet { UserDefaults.standard.set(quietHoursEnd.timeIntervalSince1970, forKey: Keys.quietHoursEnd) }
    }

    /// Default alert sound
    @Published var defaultAlertSound: AlertSound {
        didSet { UserDefaults.standard.set(defaultAlertSound.rawValue, forKey: Keys.defaultAlertSound) }
    }

    /// Show completed tasks in list
    @Published var showCompletedTasks: Bool {
        didSet { UserDefaults.standard.set(showCompletedTasks, forKey: Keys.showCompletedTasks) }
    }

    // MARK: - Computed Properties

    /// Returns the appropriate color scheme based on theme
    var colorSchemePreference: ColorScheme? {
        switch theme {
        case .light: return .light
        case .dark, .highContrast: return .dark
        case .system: return nil
        }
    }

    /// Returns the accent color based on theme
    var accentColor: Color {
        switch theme {
        case .highContrast: return .yellow
        default: return .blue
        }
    }

    /// Whether current time is within quiet hours
    var isInQuietHours: Bool {
        guard quietHoursEnabled else { return false }

        let now = Date()
        let calendar = Calendar.current
        let currentMinutes = calendar.component(.hour, from: now) * 60 + calendar.component(.minute, from: now)
        let startMinutes = calendar.component(.hour, from: quietHoursStart) * 60 +
            calendar.component(.minute, from: quietHoursStart)
        let endMinutes = calendar.component(.hour, from: quietHoursEnd) * 60 +
            calendar.component(.minute, from: quietHoursEnd)

        if startMinutes <= endMinutes {
            return currentMinutes >= startMinutes && currentMinutes < endMinutes
        } else {
            // Quiet hours span midnight
            return currentMinutes >= startMinutes || currentMinutes < endMinutes
        }
    }

    // MARK: - Initialization

    private init() {
        let defaults = UserDefaults.standard

        // Load theme
        if let themeRaw = defaults.string(forKey: Keys.theme),
           let savedTheme = Theme(rawValue: themeRaw) {
            self.theme = savedTheme
        } else {
            self.theme = .system
        }

        // Load nag level
        if let nagLevelRaw = defaults.string(forKey: Keys.defaultNagLevel),
           let savedNagLevel = NagLevel(rawValue: nagLevelRaw) {
            self.defaultNagLevel = savedNagLevel
        } else {
            self.defaultNagLevel = .moderate
        }

        // Load snooze interval
        let snoozeSeconds = defaults.double(forKey: Keys.defaultSnoozeInterval)
        if snoozeSeconds > 0 {
            self.defaultSnoozeInterval = SnoozeInterval.fromSeconds(snoozeSeconds)
        } else {
            self.defaultSnoozeInterval = .fiveMinutes
        }

        // Load escalating enabled
        self.escalatingNotificationsEnabled = defaults.bool(forKey: Keys.escalatingEnabled)

        // Load quiet hours
        self.quietHoursEnabled = defaults.bool(forKey: Keys.quietHoursEnabled)

        let startTimestamp = defaults.double(forKey: Keys.quietHoursStart)
        if startTimestamp > 0 {
            self.quietHoursStart = Date(timeIntervalSince1970: startTimestamp)
        } else {
            // Default: 10 PM
            self.quietHoursStart = Calendar.current.date(
                from: DateComponents(hour: 22, minute: 0)
            ) ?? Date()
        }

        let endTimestamp = defaults.double(forKey: Keys.quietHoursEnd)
        if endTimestamp > 0 {
            self.quietHoursEnd = Date(timeIntervalSince1970: endTimestamp)
        } else {
            // Default: 7 AM
            self.quietHoursEnd = Calendar.current.date(
                from: DateComponents(hour: 7, minute: 0)
            ) ?? Date()
        }

        // Load alert sound
        if let soundRaw = defaults.string(forKey: Keys.defaultAlertSound),
           let savedSound = AlertSound(rawValue: soundRaw) {
            self.defaultAlertSound = savedSound
        } else {
            self.defaultAlertSound = .default
        }

        // Load show completed
        self.showCompletedTasks = defaults.bool(forKey: Keys.showCompletedTasks)
    }

    // MARK: - Methods

    /// Resets all settings to defaults.
    func resetToDefaults() {
        theme = .system
        defaultNagLevel = .moderate
        defaultSnoozeInterval = .fiveMinutes
        escalatingNotificationsEnabled = false
        quietHoursEnabled = false
        quietHoursStart = Calendar.current.date(from: DateComponents(hour: 22, minute: 0)) ?? Date()
        quietHoursEnd = Calendar.current.date(from: DateComponents(hour: 7, minute: 0)) ?? Date()
        defaultAlertSound = .default
        showCompletedTasks = false
    }
}

// MARK: - UserDefaults Keys

private extension SettingsManager {
    enum Keys {
        static let theme = "settings.theme"
        static let defaultNagLevel = "settings.defaultNagLevel"
        static let defaultSnoozeInterval = "settings.defaultSnoozeInterval"
        static let escalatingEnabled = "settings.escalatingEnabled"
        static let quietHoursEnabled = "settings.quietHoursEnabled"
        static let quietHoursStart = "settings.quietHoursStart"
        static let quietHoursEnd = "settings.quietHoursEnd"
        static let defaultAlertSound = "settings.defaultAlertSound"
        static let showCompletedTasks = "settings.showCompletedTasks"
    }
}

// MARK: - Theme

/// Available app themes.
///
/// - REQ-8.2: Theme options
enum Theme: String, CaseIterable, Codable {
    case system = "system"
    case light = "light"
    case dark = "dark"
    case highContrast = "highContrast"

    var displayName: String {
        switch self {
        case .system: return Strings.Settings.systemTheme
        case .light: return Strings.Settings.lightTheme
        case .dark: return Strings.Settings.darkTheme
        case .highContrast: return Strings.Settings.highContrastTheme
        }
    }
}
