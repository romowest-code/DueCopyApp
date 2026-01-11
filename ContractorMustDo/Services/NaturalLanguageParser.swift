//
//  NaturalLanguageParser.swift
//  ContractorMustDo
//
//  Parses natural language input for quick task creation.
//

import Foundation
import NaturalLanguage

// MARK: - Natural Language Parser

/// Parses natural language input to extract task details.
///
/// Supports REQ-3.x: Natural language input for task creation.
final class NaturalLanguageParser {
    // MARK: - Singleton

    static let shared = NaturalLanguageParser()

    // MARK: - Properties

    private let dateFormatter: DateFormatter
    private let timeFormatter: DateFormatter
    private let calendar = Calendar.current

    // MARK: - Common Patterns

    /// Common contractor terms for recognition
    private let contractorTerms = [
        "bid follow-up",
        "permit check",
        "invoice reminder",
        "material order",
        "site inspection",
        "client meeting",
        "estimate",
        "walkthrough",
        "punch list",
        "final inspection"
    ]

    /// Time patterns to match
    private let timePatterns: [(pattern: String, hour: Int, minute: Int)] = [
        ("morning", 9, 0),
        ("noon", 12, 0),
        ("afternoon", 14, 0),
        ("evening", 18, 0),
        ("night", 20, 0),
        ("end of day", 17, 0),
        ("eod", 17, 0),
        ("cob", 17, 0) // Close of business
    ]

    /// Day patterns to match
    private let dayPatterns: [String: Int] = [
        "sunday": 1, "sun": 1,
        "monday": 2, "mon": 2,
        "tuesday": 3, "tue": 3, "tues": 3,
        "wednesday": 4, "wed": 4,
        "thursday": 5, "thu": 5, "thurs": 5,
        "friday": 6, "fri": 6,
        "saturday": 7, "sat": 7
    ]

    // MARK: - Initialization

    private init() {
        dateFormatter = DateFormatter()
        dateFormatter.dateStyle = .medium
        dateFormatter.timeStyle = .none

        timeFormatter = DateFormatter()
        timeFormatter.dateStyle = .none
        timeFormatter.timeStyle = .short
    }

    // MARK: - Public Methods

    /// Parses natural language input to extract task details.
    ///
    /// - Parameter input: The natural language string to parse.
    /// - Returns: A ParsedTask with extracted information.
    func parse(_ input: String) -> ParsedTask {
        let lowercased = input.lowercased()

        var result = ParsedTask()
        result.originalInput = input

        // Extract recurrence first (affects how we interpret the rest)
        result.recurrence = extractRecurrence(from: lowercased)

        // Extract time
        result.time = extractTime(from: lowercased)

        // Extract date
        result.date = extractDate(from: lowercased)

        // Combine date and time
        if let date = result.date, let time = result.time {
            result.dueDate = combineDateAndTime(date: date, time: time)
        } else if let date = result.date {
            // Use default time (9 AM)
            result.dueDate = setDefaultTime(for: date)
        } else if let time = result.time {
            // Use today's date with extracted time
            result.dueDate = combineDateAndTime(date: Date(), time: time)
        }

        // Extract title (remove date/time components)
        result.title = extractTitle(from: input, lowercased: lowercased)

        // Check for contractor terms
        result.isContractorTerm = contractorTerms.contains { lowercased.contains($0) }

        return result
    }

    // MARK: - Extraction Methods

    private func extractRecurrence(from input: String) -> RecurrenceInfo? {
        // Check for "every [day]" pattern
        if let dayMatch = extractRecurrenceDay(from: input) {
            return dayMatch
        }

        // Check for "every day" / "daily"
        if input.contains("every day") || input.contains("daily") {
            return RecurrenceInfo(type: .daily, days: [], interval: 1)
        }

        // Check for "every week" / "weekly"
        if input.contains("every week") || input.contains("weekly") {
            return RecurrenceInfo(type: .weekly, days: [], interval: 1)
        }

        // Check for "every month" / "monthly"
        if input.contains("every month") || input.contains("monthly") {
            return RecurrenceInfo(type: .monthly, days: [], interval: 1)
        }

        // Check for "every X days/weeks/months"
        if let intervalMatch = extractIntervalRecurrence(from: input) {
            return intervalMatch
        }

        return nil
    }

    private func extractRecurrenceDay(from input: String) -> RecurrenceInfo? {
        // Pattern: "every Monday", "every Tuesday and Thursday"
        let everyPattern = "every\\s+([a-z,\\s]+(?:and\\s+[a-z]+)?)"

        guard let regex = try? NSRegularExpression(pattern: everyPattern, options: []),
              let match = regex.firstMatch(
                in: input,
                options: [],
                range: NSRange(input.startIndex..., in: input)
              ),
              let daysRange = Range(match.range(at: 1), in: input) else {
            return nil
        }

        let daysString = String(input[daysRange])
        var matchedDays: [Int] = []

        for (dayName, dayNumber) in dayPatterns {
            if daysString.contains(dayName) {
                if !matchedDays.contains(dayNumber) {
                    matchedDays.append(dayNumber)
                }
            }
        }

        guard !matchedDays.isEmpty else { return nil }

        return RecurrenceInfo(type: .weekly, days: matchedDays.sorted(), interval: 1)
    }

    private func extractIntervalRecurrence(from input: String) -> RecurrenceInfo? {
        // Pattern: "every 2 days", "every 3 weeks"
        let pattern = "every\\s+(\\d+)\\s+(day|week|month)s?"

        guard let regex = try? NSRegularExpression(pattern: pattern, options: []),
              let match = regex.firstMatch(
                in: input,
                options: [],
                range: NSRange(input.startIndex..., in: input)
              ),
              let intervalRange = Range(match.range(at: 1), in: input),
              let unitRange = Range(match.range(at: 2), in: input) else {
            return nil
        }

        let interval = Int(input[intervalRange]) ?? 1
        let unit = String(input[unitRange])

        let type: RecurrenceType
        switch unit {
        case "day": type = .daily
        case "week": type = .weekly
        case "month": type = .monthly
        default: type = .custom
        }

        return RecurrenceInfo(type: type, days: [], interval: interval)
    }

    private func extractTime(from input: String) -> DateComponents? {
        // Check named times first
        for (pattern, hour, minute) in timePatterns {
            if input.contains(pattern) {
                return DateComponents(hour: hour, minute: minute)
            }
        }

        // Pattern: "at 9am", "at 2:30pm", "at 14:00"
        let timePattern = "(?:at\\s+)?(\\d{1,2})(?::(\\d{2}))?\\s*(am|pm|a\\.m\\.|p\\.m\\.)?|(?:at\\s+)(\\d{1,2})\\s*(am|pm)"

        guard let regex = try? NSRegularExpression(pattern: timePattern, options: [.caseInsensitive]),
              let match = regex.firstMatch(
                in: input,
                options: [],
                range: NSRange(input.startIndex..., in: input)
              ) else {
            return nil
        }

        var hour: Int?
        var minute = 0
        var isPM = false

        // Extract hour
        if let hourRange = Range(match.range(at: 1), in: input) {
            hour = Int(input[hourRange])
        } else if let hourRange = Range(match.range(at: 4), in: input) {
            hour = Int(input[hourRange])
        }

        // Extract minute
        if let minuteRange = Range(match.range(at: 2), in: input) {
            minute = Int(input[minuteRange]) ?? 0
        }

        // Extract AM/PM
        if let ampmRange = Range(match.range(at: 3), in: input) {
            let ampm = input[ampmRange].lowercased()
            isPM = ampm.hasPrefix("p")
        } else if let ampmRange = Range(match.range(at: 5), in: input) {
            let ampm = input[ampmRange].lowercased()
            isPM = ampm.hasPrefix("p")
        }

        guard var extractedHour = hour else { return nil }

        // Convert to 24-hour format
        if isPM && extractedHour < 12 {
            extractedHour += 12
        } else if !isPM && extractedHour == 12 {
            extractedHour = 0
        }

        return DateComponents(hour: extractedHour, minute: minute)
    }

    private func extractDate(from input: String) -> Date? {
        // Check relative dates
        if input.contains("today") {
            return Date()
        }

        if input.contains("tomorrow") {
            return calendar.date(byAdding: .day, value: 1, to: Date())
        }

        if input.contains("next week") {
            return calendar.date(byAdding: .weekOfYear, value: 1, to: Date())
        }

        // Check day names (without "every")
        if !input.contains("every") {
            for (dayName, dayNumber) in dayPatterns where input.contains(dayName) {
                return nextDate(forWeekday: dayNumber)
            }
        }

        // Try to parse explicit dates
        let detector = try? NSDataDetector(types: NSTextCheckingResult.CheckingType.date.rawValue)
        if let match = detector?.firstMatch(
            in: input,
            options: [],
            range: NSRange(input.startIndex..., in: input)
        ) {
            return match.date
        }

        return nil
    }

    private func extractTitle(from original: String, lowercased: String) -> String {
        var title = original

        // Remove common time/date phrases
        let patternsToRemove = [
            "every\\s+\\w+",
            "at\\s+\\d{1,2}(?::\\d{2})?\\s*(?:am|pm|a\\.m\\.|p\\.m\\.)?",
            "\\d{1,2}(?::\\d{2})?\\s*(?:am|pm)",
            "today",
            "tomorrow",
            "next\\s+\\w+",
            "on\\s+\\w+",
            "daily",
            "weekly",
            "monthly",
            "morning",
            "afternoon",
            "evening",
            "night",
            "noon",
            "eod",
            "cob",
            "end of day"
        ]

        for pattern in patternsToRemove {
            if let regex = try? NSRegularExpression(pattern: pattern, options: [.caseInsensitive]) {
                title = regex.stringByReplacingMatches(
                    in: title,
                    options: [],
                    range: NSRange(title.startIndex..., in: title),
                    withTemplate: ""
                )
            }
        }

        // Clean up extra whitespace
        title = title
            .components(separatedBy: .whitespaces)
            .filter { !$0.isEmpty }
            .joined(separator: " ")
            .trimmingCharacters(in: .whitespaces)

        // Capitalize first letter
        if let first = title.first {
            title = first.uppercased() + title.dropFirst()
        }

        return title.isEmpty ? original : title
    }

    // MARK: - Helper Methods

    private func nextDate(forWeekday weekday: Int) -> Date {
        let today = calendar.component(.weekday, from: Date())
        var daysToAdd = weekday - today

        if daysToAdd <= 0 {
            daysToAdd += 7
        }

        return calendar.date(byAdding: .day, value: daysToAdd, to: Date()) ?? Date()
    }

    private func combineDateAndTime(date: Date, time: DateComponents) -> Date {
        var components = calendar.dateComponents([.year, .month, .day], from: date)
        components.hour = time.hour
        components.minute = time.minute
        components.second = 0
        return calendar.date(from: components) ?? date
    }

    private func setDefaultTime(for date: Date) -> Date {
        var components = calendar.dateComponents([.year, .month, .day], from: date)
        components.hour = 9
        components.minute = 0
        components.second = 0
        return calendar.date(from: components) ?? date
    }
}

// MARK: - Parsed Task

/// Result of parsing natural language input.
struct ParsedTask {
    var originalInput: String = ""
    var title: String = ""
    var dueDate: Date?
    var date: Date?
    var time: DateComponents?
    var recurrence: RecurrenceInfo?
    var isContractorTerm: Bool = false
}

// MARK: - Recurrence Info

/// Information about task recurrence extracted from input.
struct RecurrenceInfo {
    var type: RecurrenceType
    var days: [Int] // Weekday numbers (1 = Sunday)
    var interval: Int
}
