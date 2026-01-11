//
//  SettingsManagerTests.swift
//  ContractorMustDoTests
//
//  Unit tests for SettingsManager.
//

import XCTest
import SwiftUI
@testable import ContractorMustDo

final class SettingsManagerTests: XCTestCase {
    // MARK: - Properties

    var sut: SettingsManager!

    // MARK: - Setup & Teardown

    override func setUp() {
        super.setUp()
        sut = SettingsManager.shared
        // Reset to defaults for consistent testing
        sut.resetToDefaults()
    }

    // MARK: - Default Values Tests

    func testDefaultTheme() {
        XCTAssertEqual(sut.theme, .system)
    }

    func testDefaultNagLevel() {
        XCTAssertEqual(sut.defaultNagLevel, .moderate)
    }

    func testDefaultSnoozeInterval() {
        XCTAssertEqual(sut.defaultSnoozeInterval, .fiveMinutes)
    }

    func testDefaultEscalatingNotifications() {
        XCTAssertFalse(sut.escalatingNotificationsEnabled)
    }

    func testDefaultQuietHours() {
        XCTAssertFalse(sut.quietHoursEnabled)
    }

    func testDefaultAlertSound() {
        XCTAssertEqual(sut.defaultAlertSound, .default)
    }

    // MARK: - Theme Tests

    func testThemeChangePersists() {
        sut.theme = .dark
        XCTAssertEqual(sut.theme, .dark)

        sut.theme = .light
        XCTAssertEqual(sut.theme, .light)
    }

    func testColorSchemeForSystemTheme() {
        sut.theme = .system
        XCTAssertNil(sut.colorSchemePreference)
    }

    func testColorSchemeForLightTheme() {
        sut.theme = .light
        XCTAssertEqual(sut.colorSchemePreference, .light)
    }

    func testColorSchemeForDarkTheme() {
        sut.theme = .dark
        XCTAssertEqual(sut.colorSchemePreference, .dark)
    }

    func testColorSchemeForHighContrastTheme() {
        sut.theme = .highContrast
        XCTAssertEqual(sut.colorSchemePreference, .dark)
    }

    func testAccentColorForHighContrast() {
        sut.theme = .highContrast
        XCTAssertEqual(sut.accentColor, .yellow)
    }

    func testAccentColorForOtherThemes() {
        sut.theme = .light
        XCTAssertEqual(sut.accentColor, .blue)

        sut.theme = .dark
        XCTAssertEqual(sut.accentColor, .blue)
    }

    // MARK: - Quiet Hours Tests

    func testQuietHoursNotActive() {
        sut.quietHoursEnabled = false
        XCTAssertFalse(sut.isInQuietHours)
    }

    func testQuietHoursCalculation() {
        // This test verifies the quiet hours logic works
        // The actual result depends on current time
        sut.quietHoursEnabled = true

        // Set quiet hours to definitely include current time or not
        let now = Date()
        let calendar = Calendar.current

        // Set quiet hours to 1 hour ago to 1 hour from now
        let startTime = calendar.date(byAdding: .hour, value: -1, to: now)!
        let endTime = calendar.date(byAdding: .hour, value: 1, to: now)!

        sut.quietHoursStart = startTime
        sut.quietHoursEnd = endTime

        // Current time should be within quiet hours
        XCTAssertTrue(sut.isInQuietHours)
    }

    // MARK: - Reset Tests

    func testResetToDefaults() {
        // Change all settings
        sut.theme = .dark
        sut.defaultNagLevel = .relentless
        sut.defaultSnoozeInterval = .oneHour
        sut.escalatingNotificationsEnabled = true
        sut.quietHoursEnabled = true
        sut.defaultAlertSound = .airhorn

        // Reset
        sut.resetToDefaults()

        // Verify all are back to defaults
        XCTAssertEqual(sut.theme, .system)
        XCTAssertEqual(sut.defaultNagLevel, .moderate)
        XCTAssertEqual(sut.defaultSnoozeInterval, .fiveMinutes)
        XCTAssertFalse(sut.escalatingNotificationsEnabled)
        XCTAssertFalse(sut.quietHoursEnabled)
        XCTAssertEqual(sut.defaultAlertSound, .default)
    }

    // MARK: - Theme Display Names

    func testThemeDisplayNames() {
        XCTAssertFalse(Theme.system.displayName.isEmpty)
        XCTAssertFalse(Theme.light.displayName.isEmpty)
        XCTAssertFalse(Theme.dark.displayName.isEmpty)
        XCTAssertFalse(Theme.highContrast.displayName.isEmpty)
    }
}
