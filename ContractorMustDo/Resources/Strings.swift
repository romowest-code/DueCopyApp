//
//  Strings.swift
//  ContractorMustDo
//
//  Centralized string constants for the app.
//

import Foundation

// MARK: - Strings

/// Centralized string constants to avoid hardcoded strings throughout the app.
enum Strings {
    // MARK: - Tab Names

    enum Tab {
        static let tasks = NSLocalizedString("Tasks", comment: "Tasks tab title")
        static let timers = NSLocalizedString("Timers", comment: "Timers tab title")
        static let settings = NSLocalizedString("Settings", comment: "Settings tab title")
    }

    // MARK: - Task Strings

    enum Task {
        static let addTask = NSLocalizedString("Add Task", comment: "Add task button")
        static let editTask = NSLocalizedString("Edit Task", comment: "Edit task title")
        static let deleteTask = NSLocalizedString("Delete Task", comment: "Delete task button")
        static let markComplete = NSLocalizedString("Mark Complete", comment: "Mark task complete button")
        static let snooze = NSLocalizedString("Snooze", comment: "Snooze task button")
        static let titlePlaceholder = NSLocalizedString("Task title", comment: "Task title placeholder")
        static let notesPlaceholder = NSLocalizedString("Add notes...", comment: "Notes placeholder")
        static let dueDate = NSLocalizedString("Due Date", comment: "Due date label")
        static let noTasks = NSLocalizedString("No tasks yet", comment: "Empty state message")
        static let noTasksSubtitle = NSLocalizedString("Tap + to add your first task", comment: "Empty state subtitle")
        static let overdue = NSLocalizedString("Overdue", comment: "Overdue section header")
        static let today = NSLocalizedString("Today", comment: "Today section header")
        static let upcoming = NSLocalizedString("Upcoming", comment: "Upcoming section header")
        static let completed = NSLocalizedString("Completed", comment: "Completed section header")
        static let allTasks = NSLocalizedString("All Tasks", comment: "All tasks title")
    }

    // MARK: - Nag Level Strings

    enum NagLevel {
        static let gentle = NSLocalizedString("Gentle", comment: "Gentle nag level")
        static let moderate = NSLocalizedString("Moderate", comment: "Moderate nag level")
        static let relentless = NSLocalizedString("Relentless", comment: "Relentless nag level")
        static let gentleDescription = NSLocalizedString(
            "Reminders with longer intervals",
            comment: "Gentle nag level description"
        )
        static let moderateDescription = NSLocalizedString(
            "Regular reminder frequency",
            comment: "Moderate nag level description"
        )
        static let relentlessDescription = NSLocalizedString(
            "Frequent reminders until done",
            comment: "Relentless nag level description"
        )
    }

    // MARK: - Snooze Strings

    enum Snooze {
        static let oneMinute = NSLocalizedString("1 minute", comment: "1 minute snooze")
        static let fiveMinutes = NSLocalizedString("5 minutes", comment: "5 minutes snooze")
        static let fifteenMinutes = NSLocalizedString("15 minutes", comment: "15 minutes snooze")
        static let thirtyMinutes = NSLocalizedString("30 minutes", comment: "30 minutes snooze")
        static let oneHour = NSLocalizedString("1 hour", comment: "1 hour snooze")
        static let customFormat = NSLocalizedString("%d minutes", comment: "Custom snooze format")
        static let snoozeInterval = NSLocalizedString("Snooze Interval", comment: "Snooze interval label")
    }

    // MARK: - Recurrence Strings

    enum Recurrence {
        static let daily = NSLocalizedString("Daily", comment: "Daily recurrence")
        static let weekly = NSLocalizedString("Weekly", comment: "Weekly recurrence")
        static let monthly = NSLocalizedString("Monthly", comment: "Monthly recurrence")
        static let custom = NSLocalizedString("Custom", comment: "Custom recurrence")
        static let repeatTask = NSLocalizedString("Repeat", comment: "Repeat task label")
        static let never = NSLocalizedString("Never", comment: "Never repeat")
        static let repeatFromCompletion = NSLocalizedString(
            "Repeat from completion",
            comment: "Repeat from completion toggle"
        )
        static let everyDay = NSLocalizedString("Every day", comment: "Every day recurrence")
        static let everyWeek = NSLocalizedString("Every week", comment: "Every week recurrence")
        static let everyMonth = NSLocalizedString("Every month", comment: "Every month recurrence")
        static let selectDays = NSLocalizedString("Select days", comment: "Select days label")
    }

    // MARK: - Timer Strings

    enum Timer {
        static let addTimer = NSLocalizedString("Add Timer", comment: "Add timer button")
        static let startTimer = NSLocalizedString("Start", comment: "Start timer button")
        static let pauseTimer = NSLocalizedString("Pause", comment: "Pause timer button")
        static let stopTimer = NSLocalizedString("Stop", comment: "Stop timer button")
        static let resetTimer = NSLocalizedString("Reset", comment: "Reset timer button")
        static let timerName = NSLocalizedString("Timer name", comment: "Timer name placeholder")
        static let duration = NSLocalizedString("Duration", comment: "Duration label")
        static let presets = NSLocalizedString("Presets", comment: "Presets section header")
        static let activeTimers = NSLocalizedString("Active Timers", comment: "Active timers section")
        static let noTimers = NSLocalizedString("No active timers", comment: "Empty timers state")
        static let fifteenMinuteBreak = NSLocalizedString("15 min break", comment: "15 minute break preset")
        static let thirtyMinuteBreak = NSLocalizedString("30 min break", comment: "30 minute break preset")
        static let oneHourFocus = NSLocalizedString("1 hour focus", comment: "1 hour focus preset")
        static let pomodoro = NSLocalizedString("Pomodoro (25 min)", comment: "Pomodoro preset")
        static let timerComplete = NSLocalizedString("Timer Complete", comment: "Timer complete notification")
    }

    // MARK: - Sound Strings

    enum Sound {
        static let defaultSound = NSLocalizedString("Default", comment: "Default sound")
        static let bell = NSLocalizedString("Bell", comment: "Bell sound")
        static let chime = NSLocalizedString("Chime", comment: "Chime sound")
        static let alarm = NSLocalizedString("Alarm", comment: "Alarm sound")
        static let loud = NSLocalizedString("Loud", comment: "Loud sound")
        static let airhorn = NSLocalizedString("Air Horn", comment: "Air horn sound")
        static let alertSound = NSLocalizedString("Alert Sound", comment: "Alert sound label")
    }

    // MARK: - Settings Strings

    enum Settings {
        static let appearance = NSLocalizedString("Appearance", comment: "Appearance section")
        static let theme = NSLocalizedString("Theme", comment: "Theme setting")
        static let lightTheme = NSLocalizedString("Light", comment: "Light theme")
        static let darkTheme = NSLocalizedString("Dark", comment: "Dark theme")
        static let systemTheme = NSLocalizedString("System", comment: "System theme")
        static let highContrastTheme = NSLocalizedString("High Contrast", comment: "High contrast theme")
        static let notifications = NSLocalizedString("Notifications", comment: "Notifications section")
        static let quietHours = NSLocalizedString("Quiet Hours", comment: "Quiet hours setting")
        static let quietHoursStart = NSLocalizedString("Start Time", comment: "Quiet hours start")
        static let quietHoursEnd = NSLocalizedString("End Time", comment: "Quiet hours end")
        static let defaultNagLevel = NSLocalizedString("Default Nag Level", comment: "Default nag level")
        static let defaultSnoozeInterval = NSLocalizedString("Default Snooze", comment: "Default snooze")
        static let escalatingNotifications = NSLocalizedString(
            "Escalating Notifications",
            comment: "Escalating notifications toggle"
        )
        static let about = NSLocalizedString("About", comment: "About section")
        static let version = NSLocalizedString("Version", comment: "Version label")
        static let help = NSLocalizedString("Help", comment: "Help button")
    }

    // MARK: - Notification Strings

    enum Notification {
        static let taskReminder = NSLocalizedString("Task Reminder", comment: "Task reminder notification title")
        static let taskOverdue = NSLocalizedString("Task Overdue", comment: "Overdue notification title")
        static let snoozeAction = NSLocalizedString("Snooze", comment: "Snooze notification action")
        static let completeAction = NSLocalizedString("Complete", comment: "Complete notification action")
        static let permissionRequired = NSLocalizedString(
            "Notification permission required",
            comment: "Permission required message"
        )
        static let enableNotifications = NSLocalizedString(
            "Enable notifications to receive task reminders",
            comment: "Enable notifications prompt"
        )
    }

    // MARK: - Common Strings

    enum Common {
        static let save = NSLocalizedString("Save", comment: "Save button")
        static let cancel = NSLocalizedString("Cancel", comment: "Cancel button")
        static let delete = NSLocalizedString("Delete", comment: "Delete button")
        static let done = NSLocalizedString("Done", comment: "Done button")
        static let edit = NSLocalizedString("Edit", comment: "Edit button")
        static let error = NSLocalizedString("Error", comment: "Error title")
        static let ok = NSLocalizedString("OK", comment: "OK button")
        static let yes = NSLocalizedString("Yes", comment: "Yes button")
        static let no = NSLocalizedString("No", comment: "No button")
    }

    // MARK: - Siri Strings

    enum Siri {
        static let addTaskShortcut = NSLocalizedString("Add Task", comment: "Add task Siri shortcut")
        static let whatsOverdue = NSLocalizedString("What's overdue?", comment: "Overdue Siri shortcut")
        static let markComplete = NSLocalizedString("Mark task complete", comment: "Complete Siri shortcut")
        static let noOverdueTasks = NSLocalizedString("No overdue tasks", comment: "No overdue tasks response")
        static let overdueTasksFormat = NSLocalizedString(
            "You have %d overdue tasks",
            comment: "Overdue tasks count format"
        )
    }

    // MARK: - Days of Week

    enum DaysOfWeek {
        static let sunday = NSLocalizedString("Sun", comment: "Sunday abbreviation")
        static let monday = NSLocalizedString("Mon", comment: "Monday abbreviation")
        static let tuesday = NSLocalizedString("Tue", comment: "Tuesday abbreviation")
        static let wednesday = NSLocalizedString("Wed", comment: "Wednesday abbreviation")
        static let thursday = NSLocalizedString("Thu", comment: "Thursday abbreviation")
        static let friday = NSLocalizedString("Fri", comment: "Friday abbreviation")
        static let saturday = NSLocalizedString("Sat", comment: "Saturday abbreviation")

        static let all: [String] = [sunday, monday, tuesday, wednesday, thursday, friday, saturday]
    }

    // MARK: - Natural Language

    enum NaturalLanguage {
        static let quickAdd = NSLocalizedString(
            "Try: \"call supplier every Monday at 9am\"",
            comment: "Quick add hint"
        )
    }
}
