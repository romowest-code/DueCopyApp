//
//  TimerAppIntents.swift
//  ContractorMustDo
//
//  App Intents for timer Siri integration.
//

import AppIntents

// MARK: - Start Timer Intent

/// Siri intent for starting a timer.
struct StartTimerIntent: AppIntent {
    static var title: LocalizedStringResource = "Start Timer"
    static var description = IntentDescription("Start a countdown timer")

    @Parameter(title: "Duration in Minutes")
    var minutes: Int

    @Parameter(title: "Timer Name", default: "Timer")
    var name: String

    static var parameterSummary: some ParameterSummary {
        Summary("Start \(\.$minutes) minute timer named \(\.$name)")
    }

    func perform() async throws -> some IntentResult & ProvidesDialog {
        guard minutes > 0 else {
            throw IntentError.invalidParameter
        }

        // In production, create and start timer
        return .result(dialog: "Started \(minutes) minute timer: \(name)")
    }
}

// MARK: - Stop Timer Intent

/// Siri intent for stopping a timer.
struct StopTimerIntent: AppIntent {
    static var title: LocalizedStringResource = "Stop Timer"
    static var description = IntentDescription("Stop all running timers")

    func perform() async throws -> some IntentResult & ProvidesDialog {
        // In production, stop all timers via TimerManager
        return .result(dialog: "Stopped all timers")
    }
}

// MARK: - Get Timer Status Intent

/// Siri intent for checking timer status.
struct GetTimerStatusIntent: AppIntent {
    static var title: LocalizedStringResource = "Timer Status"
    static var description = IntentDescription("Check your active timers")

    func perform() async throws -> some IntentResult & ProvidesDialog {
        // In production, fetch from TimerManager
        let activeCount = 0

        if activeCount == 0 {
            return .result(dialog: "No active timers")
        } else {
            return .result(dialog: "You have \(activeCount) active timer(s)")
        }
    }
}

// Note: Timer shortcuts are combined in TaskAppIntents.swift AppShortcuts provider

// MARK: - Intent Errors

/// Errors that can occur during intent execution.
enum IntentError: Swift.Error, CustomLocalizedStringResourceConvertible {
    case invalidParameter
    case taskNotFound
    case timerNotFound

    var localizedStringResource: LocalizedStringResource {
        switch self {
        case .invalidParameter:
            return "Invalid parameter provided"
        case .taskNotFound:
            return "Task not found"
        case .timerNotFound:
            return "Timer not found"
        }
    }
}
