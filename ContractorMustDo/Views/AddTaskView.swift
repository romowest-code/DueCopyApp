//
//  AddTaskView.swift
//  ContractorMustDo
//
//  View for creating new tasks.
//

import SwiftUI
import SwiftData

// MARK: - Add Task View

/// Sheet view for creating a new task with all configuration options.
struct AddTaskView: View {
    // MARK: - Properties

    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss
    @EnvironmentObject private var settingsManager: SettingsManager

    @ObservedObject var viewModel: TaskListViewModel

    // Form state
    @State private var title = ""
    @State private var notes = ""
    @State private var dueDate = Date()
    @State private var nagLevel: NagLevel
    @State private var snoozeInterval: SnoozeInterval
    @State private var escalatingEnabled: Bool
    @State private var recurrenceType: RecurrenceType?
    @State private var recurrenceDays: Set<Int> = []
    @State private var recurrenceInterval = 1
    @State private var repeatFromCompletion = false
    @State private var showDatePicker = false

    // MARK: - Initialization

    init(viewModel: TaskListViewModel) {
        self.viewModel = viewModel
        let settings = SettingsManager.shared
        _nagLevel = State(initialValue: settings.defaultNagLevel)
        _snoozeInterval = State(initialValue: settings.defaultSnoozeInterval)
        _escalatingEnabled = State(initialValue: settings.escalatingNotificationsEnabled)
    }

    // MARK: - Body

    var body: some View {
        NavigationStack {
            Form {
                // Task details section
                Section {
                    TextField(Strings.Task.titlePlaceholder, text: $title)
                        .font(.headline)

                    TextField(Strings.Task.notesPlaceholder, text: $notes, axis: .vertical)
                        .lineLimit(3...6)
                }

                // Due date section
                Section {
                    DatePicker(
                        Strings.Task.dueDate,
                        selection: $dueDate,
                        displayedComponents: [.date, .hourAndMinute]
                    )

                    // Quick date buttons
                    quickDateButtons
                }

                // Nagging section
                Section {
                    Picker(Strings.Settings.defaultNagLevel, selection: $nagLevel) {
                        ForEach(NagLevel.allCases, id: \.self) { level in
                            Text(level.displayName).tag(level)
                        }
                    }

                    Picker(Strings.Snooze.snoozeInterval, selection: $snoozeInterval) {
                        ForEach(SnoozeInterval.allCases, id: \.seconds) { interval in
                            Text(interval.displayName).tag(interval)
                        }
                    }

                    Toggle(Strings.Settings.escalatingNotifications, isOn: $escalatingEnabled)
                } header: {
                    Text("Reminders")
                } footer: {
                    Text(nagLevel.description)
                }

                // Recurrence section
                Section {
                    Picker(Strings.Recurrence.repeatTask, selection: $recurrenceType) {
                        Text(Strings.Recurrence.never).tag(nil as RecurrenceType?)
                        ForEach(RecurrenceType.allCases, id: \.self) { type in
                            Text(type.displayName).tag(type as RecurrenceType?)
                        }
                    }

                    if recurrenceType == .weekly {
                        weekdaySelector
                    }

                    if recurrenceType == .custom {
                        Stepper(
                            "Every \(recurrenceInterval) days",
                            value: $recurrenceInterval,
                            in: 1...365
                        )
                    }

                    if recurrenceType != nil {
                        Toggle(Strings.Recurrence.repeatFromCompletion, isOn: $repeatFromCompletion)
                    }
                } header: {
                    Text("Repeat")
                }
            }
            .navigationTitle(Strings.Task.addTask)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button(Strings.Common.cancel) {
                        dismiss()
                    }
                }

                ToolbarItem(placement: .confirmationAction) {
                    Button(Strings.Common.save) {
                        saveTask()
                    }
                    .disabled(title.isEmpty)
                    .fontWeight(.semibold)
                }
            }
        }
    }

    // MARK: - Subviews

    private var quickDateButtons: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 8) {
                QuickDateButton(title: "In 1h") {
                    dueDate = Date().addingTimeInterval(3600)
                }

                QuickDateButton(title: "Today EOD") {
                    dueDate = Calendar.current.date(
                        bySettingHour: 17,
                        minute: 0,
                        second: 0,
                        of: Date()
                    ) ?? Date()
                }

                QuickDateButton(title: "Tomorrow 9am") {
                    let tomorrow = Calendar.current.date(byAdding: .day, value: 1, to: Date()) ?? Date()
                    dueDate = Calendar.current.date(
                        bySettingHour: 9,
                        minute: 0,
                        second: 0,
                        of: tomorrow
                    ) ?? tomorrow
                }

                QuickDateButton(title: "Next Week") {
                    dueDate = Calendar.current.date(byAdding: .weekOfYear, value: 1, to: Date()) ?? Date()
                }
            }
            .padding(.vertical, 4)
        }
    }

    private var weekdaySelector: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(Strings.Recurrence.selectDays)
                .font(.caption)
                .foregroundStyle(.secondary)

            HStack(spacing: 8) {
                ForEach(0..<7, id: \.self) { index in
                    let weekday = index + 1
                    Button {
                        if recurrenceDays.contains(weekday) {
                            recurrenceDays.remove(weekday)
                        } else {
                            recurrenceDays.insert(weekday)
                        }
                    } label: {
                        Text(Strings.DaysOfWeek.all[index])
                            .font(.caption)
                            .fontWeight(recurrenceDays.contains(weekday) ? .bold : .regular)
                            .frame(width: 36, height: 36)
                            .background(
                                Circle()
                                    .fill(recurrenceDays.contains(weekday) ? Color.accentColor : Color(.secondarySystemFill))
                            )
                            .foregroundStyle(recurrenceDays.contains(weekday) ? .white : .primary)
                    }
                    .buttonStyle(.plain)
                }
            }
        }
    }

    // MARK: - Methods

    private func saveTask() {
        viewModel.addTask(
            title: title,
            dueDate: dueDate,
            notes: notes,
            nagLevel: nagLevel,
            snoozeInterval: snoozeInterval,
            escalatingEnabled: escalatingEnabled,
            recurrenceType: recurrenceType,
            recurrenceDays: Array(recurrenceDays),
            recurrenceInterval: recurrenceInterval,
            repeatFromCompletion: repeatFromCompletion,
            context: modelContext
        )
        dismiss()
    }
}

// MARK: - Quick Date Button

/// Button for quick date selection.
private struct QuickDateButton: View {
    let title: String
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            Text(title)
                .font(.caption)
                .fontWeight(.medium)
                .padding(.horizontal, 12)
                .padding(.vertical, 6)
                .background(Color(.secondarySystemFill))
                .cornerRadius(16)
        }
        .buttonStyle(.plain)
    }
}

// MARK: - Preview

#Preview {
    AddTaskView(viewModel: TaskListViewModel())
        .modelContainer(for: TaskItem.self, inMemory: true)
        .environmentObject(SettingsManager.shared)
}
