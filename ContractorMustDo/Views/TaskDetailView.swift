//
//  TaskDetailView.swift
//  ContractorMustDo
//
//  Detailed view and editing for a single task.
//

import SwiftUI
import SwiftData

// MARK: - Task Detail View

/// Detail view for viewing and editing a task.
struct TaskDetailView: View {
    // MARK: - Properties

    @Bindable var task: TaskItem
    @ObservedObject var viewModel: TaskListViewModel

    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss

    @State private var isEditing = false
    @State private var showDeleteConfirmation = false

    // Editing state
    @State private var editedTitle: String = ""
    @State private var editedNotes: String = ""
    @State private var editedDueDate: Date = Date()
    @State private var editedNagLevel: NagLevel = .moderate
    @State private var editedSnoozeInterval: SnoozeInterval = .fiveMinutes
    @State private var editedEscalating: Bool = false
    @State private var editedRecurrenceType: RecurrenceType?
    @State private var editedRecurrenceDays: Set<Int> = []
    @State private var editedRecurrenceInterval: Int = 1
    @State private var editedRepeatFromCompletion: Bool = false

    // MARK: - Body

    var body: some View {
        NavigationStack {
            Form {
                if isEditing {
                    editingContent
                } else {
                    viewingContent
                }
            }
            .navigationTitle(isEditing ? Strings.Task.editTask : task.title)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button(isEditing ? Strings.Common.cancel : Strings.Common.done) {
                        if isEditing {
                            isEditing = false
                        } else {
                            dismiss()
                        }
                    }
                }

                ToolbarItem(placement: .confirmationAction) {
                    if isEditing {
                        Button(Strings.Common.save) {
                            saveChanges()
                        }
                        .fontWeight(.semibold)
                    } else {
                        Button(Strings.Common.edit) {
                            startEditing()
                        }
                    }
                }
            }
            .confirmationDialog(
                Strings.Task.deleteTask,
                isPresented: $showDeleteConfirmation,
                titleVisibility: .visible
            ) {
                Button(Strings.Common.delete, role: .destructive) {
                    viewModel.deleteTask(task, context: modelContext)
                    dismiss()
                }
                Button(Strings.Common.cancel, role: .cancel) {}
            }
        }
    }

    // MARK: - Viewing Content

    private var viewingContent: some View {
        Group {
            // Task info section
            Section {
                LabeledContent(Strings.Task.dueDate) {
                    Text(task.dueDate, style: .date)
                    Text(task.dueDate, style: .time)
                }

                if !task.notes.isEmpty {
                    VStack(alignment: .leading, spacing: 4) {
                        Text("Notes")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                        Text(task.notes)
                    }
                }

                if task.isCompleted, let completedDate = task.completedDate {
                    LabeledContent("Completed") {
                        Text(completedDate, style: .relative)
                    }
                }
            }

            // Status section
            Section {
                statusIndicator

                if task.isOverdue {
                    Label("Overdue", systemImage: "exclamationmark.triangle.fill")
                        .foregroundStyle(.red)
                }

                if task.snoozeCount > 0 {
                    LabeledContent("Times Snoozed") {
                        Text("\(task.snoozeCount)")
                    }
                }
            }

            // Reminder settings section
            Section("Reminder Settings") {
                LabeledContent(Strings.Settings.defaultNagLevel) {
                    Text(task.nagLevel.displayName)
                }

                LabeledContent(Strings.Snooze.snoozeInterval) {
                    Text(task.snoozeInterval.displayName)
                }

                if task.escalatingEnabled {
                    Label("Escalating reminders enabled", systemImage: "arrow.up.right")
                        .foregroundStyle(.orange)
                }
            }

            // Recurrence section
            if let recurrence = task.recurrenceType {
                Section("Recurrence") {
                    LabeledContent("Pattern") {
                        Text(recurrence.displayName)
                    }

                    if !task.recurrenceDays.isEmpty {
                        LabeledContent("Days") {
                            Text(formattedRecurrenceDays)
                        }
                    }

                    if task.repeatFromCompletion {
                        Label("Repeats from completion", systemImage: "checkmark.circle")
                    }
                }
            }

            // Actions section
            Section {
                if !task.isCompleted {
                    Button {
                        viewModel.toggleCompletion(task, context: modelContext)
                        dismiss()
                    } label: {
                        Label(Strings.Task.markComplete, systemImage: "checkmark.circle")
                    }
                    .foregroundStyle(.green)

                    snoozeMenu
                } else {
                    Button {
                        viewModel.toggleCompletion(task, context: modelContext)
                    } label: {
                        Label("Mark Incomplete", systemImage: "arrow.uturn.backward")
                    }
                }

                Button(role: .destructive) {
                    showDeleteConfirmation = true
                } label: {
                    Label(Strings.Task.deleteTask, systemImage: "trash")
                }
            }
        }
    }

    // MARK: - Editing Content

    private var editingContent: some View {
        Group {
            Section {
                TextField(Strings.Task.titlePlaceholder, text: $editedTitle)
                    .font(.headline)

                TextField(Strings.Task.notesPlaceholder, text: $editedNotes, axis: .vertical)
                    .lineLimit(3...6)
            }

            Section {
                DatePicker(
                    Strings.Task.dueDate,
                    selection: $editedDueDate,
                    displayedComponents: [.date, .hourAndMinute]
                )
            }

            Section("Reminders") {
                Picker(Strings.Settings.defaultNagLevel, selection: $editedNagLevel) {
                    ForEach(NagLevel.allCases, id: \.self) { level in
                        Text(level.displayName).tag(level)
                    }
                }

                Picker(Strings.Snooze.snoozeInterval, selection: $editedSnoozeInterval) {
                    ForEach(SnoozeInterval.allCases, id: \.seconds) { interval in
                        Text(interval.displayName).tag(interval)
                    }
                }

                Toggle(Strings.Settings.escalatingNotifications, isOn: $editedEscalating)
            }

            Section("Repeat") {
                Picker(Strings.Recurrence.repeatTask, selection: $editedRecurrenceType) {
                    Text(Strings.Recurrence.never).tag(nil as RecurrenceType?)
                    ForEach(RecurrenceType.allCases, id: \.self) { type in
                        Text(type.displayName).tag(type as RecurrenceType?)
                    }
                }

                if editedRecurrenceType == .weekly {
                    weekdaySelector
                }

                if editedRecurrenceType == .custom {
                    Stepper(
                        "Every \(editedRecurrenceInterval) days",
                        value: $editedRecurrenceInterval,
                        in: 1...365
                    )
                }

                if editedRecurrenceType != nil {
                    Toggle(Strings.Recurrence.repeatFromCompletion, isOn: $editedRepeatFromCompletion)
                }
            }
        }
    }

    // MARK: - Subviews

    private var statusIndicator: some View {
        HStack {
            Circle()
                .fill(statusColor)
                .frame(width: 12, height: 12)

            Text(statusText)
                .font(.subheadline)
        }
    }

    private var snoozeMenu: some View {
        Menu {
            ForEach(SnoozeInterval.allCases, id: \.seconds) { interval in
                Button {
                    viewModel.snoozeTask(task, interval: interval)
                    dismiss()
                } label: {
                    Text(interval.displayName)
                }
            }
        } label: {
            Label(Strings.Task.snooze, systemImage: "clock.arrow.circlepath")
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
                        if editedRecurrenceDays.contains(weekday) {
                            editedRecurrenceDays.remove(weekday)
                        } else {
                            editedRecurrenceDays.insert(weekday)
                        }
                    } label: {
                        Text(Strings.DaysOfWeek.all[index])
                            .font(.caption)
                            .fontWeight(editedRecurrenceDays.contains(weekday) ? .bold : .regular)
                            .frame(width: 36, height: 36)
                            .background(
                                Circle()
                                    .fill(
                                        editedRecurrenceDays.contains(weekday) ?
                                        Color.accentColor : Color(.secondarySystemFill)
                                    )
                            )
                            .foregroundStyle(editedRecurrenceDays.contains(weekday) ? .white : .primary)
                    }
                    .buttonStyle(.plain)
                }
            }
        }
    }

    // MARK: - Computed Properties

    private var statusColor: Color {
        if task.isCompleted {
            return .green
        } else if task.isOverdue {
            return .red
        } else if task.isDueToday {
            return .orange
        } else {
            return .blue
        }
    }

    private var statusText: String {
        if task.isCompleted {
            return Strings.Task.completed
        } else if task.isOverdue {
            return Strings.Task.overdue
        } else if task.isDueToday {
            return "Due today"
        } else {
            return Strings.Task.upcoming
        }
    }

    private var formattedRecurrenceDays: String {
        let sortedDays = task.recurrenceDays.sorted()
        return sortedDays.map { Strings.DaysOfWeek.all[$0 - 1] }.joined(separator: ", ")
    }

    // MARK: - Methods

    private func startEditing() {
        editedTitle = task.title
        editedNotes = task.notes
        editedDueDate = task.dueDate
        editedNagLevel = task.nagLevel
        editedSnoozeInterval = task.snoozeInterval
        editedEscalating = task.escalatingEnabled
        editedRecurrenceType = task.recurrenceType
        editedRecurrenceDays = Set(task.recurrenceDays)
        editedRecurrenceInterval = task.recurrenceInterval
        editedRepeatFromCompletion = task.repeatFromCompletion
        isEditing = true
    }

    private func saveChanges() {
        task.title = editedTitle
        task.notes = editedNotes
        task.dueDate = editedDueDate
        task.nagLevel = editedNagLevel
        task.snoozeInterval = editedSnoozeInterval
        task.escalatingEnabled = editedEscalating
        task.recurrenceType = editedRecurrenceType
        task.recurrenceDays = Array(editedRecurrenceDays)
        task.recurrenceInterval = editedRecurrenceInterval
        task.repeatFromCompletion = editedRepeatFromCompletion

        // Reschedule notification
        NotificationService.shared.cancelNotifications(for: task)
        NotificationService.shared.scheduleNotification(for: task)

        isEditing = false
    }
}

// MARK: - Preview

#Preview {
    TaskDetailView(
        task: TaskItem(
            title: "Call supplier about order",
            dueDate: Date(),
            notes: "Need to confirm delivery date for materials",
            nagLevel: .moderate,
            recurrenceType: .weekly,
            recurrenceDays: [2, 4, 6]
        ),
        viewModel: TaskListViewModel()
    )
    .modelContainer(for: TaskItem.self, inMemory: true)
}
