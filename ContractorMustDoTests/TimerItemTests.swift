//
//  TimerItemTests.swift
//  ContractorMustDoTests
//
//  Unit tests for TimerItem model.
//

import XCTest
import SwiftData
@testable import ContractorMustDo

final class TimerItemTests: XCTestCase {
    // MARK: - Initialization Tests

    func testTimerInitialization() {
        let timer = TimerItem(
            name: "Test Timer",
            durationSeconds: 300,
            alertSound: .bell
        )

        XCTAssertEqual(timer.name, "Test Timer")
        XCTAssertEqual(timer.durationSeconds, 300)
        XCTAssertEqual(timer.remainingSeconds, 300)
        XCTAssertEqual(timer.alertSound, .bell)
        XCTAssertFalse(timer.isRunning)
        XCTAssertFalse(timer.isPaused)
        XCTAssertNil(timer.startDate)
    }

    func testTimerDefaultValues() {
        let timer = TimerItem(name: "Minimal Timer", durationSeconds: 60)

        XCTAssertEqual(timer.alertSound, .default)
        XCTAssertFalse(timer.repeatAlert)
        XCTAssertFalse(timer.isPreset)
        XCTAssertEqual(timer.sortOrder, 0)
    }

    // MARK: - Computed Property Tests

    func testIsCompleted() {
        let timer = TimerItem(name: "Timer", durationSeconds: 60)

        XCTAssertFalse(timer.isCompleted)

        timer.remainingSeconds = 0
        XCTAssertTrue(timer.isCompleted)

        timer.isRunning = true
        XCTAssertFalse(timer.isCompleted) // Still running
    }

    func testProgress() {
        let timer = TimerItem(name: "Timer", durationSeconds: 100)

        XCTAssertEqual(timer.progress, 0, accuracy: 0.001)

        timer.remainingSeconds = 50
        XCTAssertEqual(timer.progress, 0.5, accuracy: 0.001)

        timer.remainingSeconds = 0
        XCTAssertEqual(timer.progress, 1.0, accuracy: 0.001)
    }

    func testFormattedRemainingTime() {
        let timer = TimerItem(name: "Timer", durationSeconds: 3665)

        // 1 hour, 1 minute, 5 seconds
        XCTAssertEqual(timer.formattedRemainingTime, "01:01:05")

        timer.remainingSeconds = 65
        XCTAssertEqual(timer.formattedRemainingTime, "01:05")

        timer.remainingSeconds = 5
        XCTAssertEqual(timer.formattedRemainingTime, "00:05")
    }

    // MARK: - Control Tests

    func testStart() {
        let timer = TimerItem(name: "Timer", durationSeconds: 60)

        timer.start()

        XCTAssertTrue(timer.isRunning)
        XCTAssertFalse(timer.isPaused)
        XCTAssertNotNil(timer.startDate)
    }

    func testPause() {
        let timer = TimerItem(name: "Timer", durationSeconds: 60)
        timer.start()

        timer.pause()

        XCTAssertFalse(timer.isRunning)
        XCTAssertTrue(timer.isPaused)
        XCTAssertNotNil(timer.pausedDate)
    }

    func testStop() {
        let timer = TimerItem(name: "Timer", durationSeconds: 60)
        timer.start()
        timer.remainingSeconds = 30

        timer.stop()

        XCTAssertFalse(timer.isRunning)
        XCTAssertFalse(timer.isPaused)
        XCTAssertEqual(timer.remainingSeconds, 60) // Reset to original
        XCTAssertNil(timer.startDate)
    }

    func testDuplicate() {
        let timer = TimerItem(
            name: "Original Timer",
            durationSeconds: 300,
            alertSound: .alarm,
            repeatAlert: true,
            isPreset: true
        )

        let duplicate = timer.duplicate()

        XCTAssertNotEqual(duplicate.id, timer.id)
        XCTAssertEqual(duplicate.name, timer.name)
        XCTAssertEqual(duplicate.durationSeconds, timer.durationSeconds)
        XCTAssertEqual(duplicate.alertSound, timer.alertSound)
        XCTAssertEqual(duplicate.repeatAlert, timer.repeatAlert)
        XCTAssertFalse(duplicate.isPreset) // Duplicates are not presets
    }

    // MARK: - Timer Preset Tests

    func testTimerPresets() {
        XCTAssertEqual(TimerPreset.fifteenMinuteBreak.durationSeconds, 15 * 60)
        XCTAssertEqual(TimerPreset.thirtyMinuteBreak.durationSeconds, 30 * 60)
        XCTAssertEqual(TimerPreset.oneHourFocus.durationSeconds, 60 * 60)
        XCTAssertEqual(TimerPreset.pomodoro.durationSeconds, 25 * 60)
    }

    func testCreateTimerFromPreset() {
        let timer = TimerPreset.pomodoro.createTimer()

        XCTAssertEqual(timer.durationSeconds, 25 * 60)
        XCTAssertTrue(timer.isPreset)
    }

    // MARK: - Alert Sound Tests

    func testAlertSoundValues() {
        XCTAssertEqual(AlertSound.default.rawValue, "default")
        XCTAssertEqual(AlertSound.bell.rawValue, "bell")
        XCTAssertEqual(AlertSound.alarm.rawValue, "alarm")
        XCTAssertEqual(AlertSound.airhorn.rawValue, "airhorn")
    }

    func testAlertSoundFileNames() {
        XCTAssertEqual(AlertSound.default.soundFileName, "default_alert")
        XCTAssertEqual(AlertSound.bell.soundFileName, "bell_alert")
        XCTAssertEqual(AlertSound.loud.soundFileName, "loud_alert")
    }
}
