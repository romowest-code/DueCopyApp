//
//  TaskRowView.swift
//  ContractorMustDo
//
//  Individual task row for the list view.
//

import SwiftUI
import SwiftData

// MARK: - Task Row View

/// Displays a single task in the task list.
struct TaskRowView: View {
    // MARK: - Properties

    let task: TaskItem
    @ObservedObject var viewModel: TaskListViewModel

    @Environment(\.modelContext) private var modelContext

    // MARK: - Body

    var body: some View {
        Button {
            viewModel.selectedTask = task
        } label: {
            HStack(spacing: 12) {
                // Completion checkbox
                completionButton

                // Task content
                VStack(alignment: .leading, spacing: 4) {
                    taskTitle

                    HStack(spacing: 8) {
                        dueDateLabel

                        if task.isRecurring {
                            recurrenceIndicator
                        }

                        nagLevelIndicator
                    }
                }

                Spacer()

                // Snooze button
                if !task.isCompleted {
                    snoozeButton
                }
            }
            .padding(.vertical, 4)
        }
        .buttonStyle(.plain)
        .opacity(task.isCompleted ? 0.6 : 1)
    }

    // MARK: - Subviews

    private var completionButton: some View {
        Button {
            withAnimation(.spring(response: 0.3)) {
                viewModel.toggleCompletion(task, context: modelContext)
            }
        } label: {
            Image(systemName: task.isCompleted ? "checkmark.circle.fill" : "circle")
                .font(.title2)
                .foregroundStyle(task.isCompleted ? .green : .secondary)
        }
        .buttonStyle(.plain)
    }

    private var taskTitle: some View {
        Text(task.title)
            .font(.body)
            .fontWeight(.medium)
            .strikethrough(task.isCompleted)
            .foregroundStyle(task.isCompleted ? .secondary : .primary)
            .lineLimit(2)
    }

    private var dueDateLabel: some View {
        HStack(spacing: 4) {
            Image(systemName: dueDateIcon)
                .font(.caption2)

            Text(formattedDueDate)
                .font(.caption)
        }
        .foregroundStyle(dueDateColor)
    }

    private var recurrenceIndicator: some View {
        HStack(spacing: 2) {
            Image(systemName: "repeat")
                .font(.caption2)

            if let recurrence = task.recurrenceType {
                Text(recurrence.displayName)
                    .font(.caption)
            }
        }
        .foregroundStyle(.secondary)
    }

    private var nagLevelIndicator: some View {
        HStack(spacing: 2) {
            ForEach(0..<nagLevelBars, id: \.self) { _ in
                Rectangle()
                    .fill(nagLevelColor)
                    .frame(width: 3, height: 10)
                    .cornerRadius(1)
            }
        }
    }

    private var snoozeButton: some View {
        Menu {
            ForEach(SnoozeInterval.allCases, id: \.seconds) { interval in
                Button {
                    viewModel.snoozeTask(task, interval: interval)
                } label: {
                    Text(interval.displayName)
                }
            }
        } label: {
            Image(systemName: "clock.arrow.circlepath")
                .font(.body)
                .foregroundStyle(.secondary)
        }
    }

    // MARK: - Computed Properties

    private var dueDateIcon: String {
        if task.isOverdue {
            return "exclamationmark.triangle.fill"
        } else if task.isDueToday {
            return "calendar.badge.exclamationmark"
        } else {
            return "calendar"
        }
    }

    private var dueDateColor: Color {
        if task.isCompleted {
            return .secondary
        } else if task.isOverdue {
            return .red
        } else if task.isDueToday {
            return .orange
        } else {
            return .secondary
        }
    }

    private var formattedDueDate: String {
        let formatter = RelativeDateTimeFormatter()
        formatter.unitsStyle = .abbreviated
        return formatter.localizedString(for: task.dueDate, relativeTo: Date())
    }

    private var nagLevelBars: Int {
        switch task.nagLevel {
        case .gentle: return 1
        case .moderate: return 2
        case .relentless: return 3
        }
    }

    private var nagLevelColor: Color {
        switch task.nagLevel {
        case .gentle: return .green
        case .moderate: return .orange
        case .relentless: return .red
        }
    }
}

// MARK: - Preview

#Preview {
    List {
        TaskRowView(
            task: TaskItem(
                title: "Call supplier about order",
                dueDate: Date().addingTimeInterval(-3600),
                nagLevel: .relentless
            ),
            viewModel: TaskListViewModel()
        )

        TaskRowView(
            task: TaskItem(
                title: "Submit permit application",
                dueDate: Date().addingTimeInterval(3600),
                recurrenceType: .weekly
            ),
            viewModel: TaskListViewModel()
        )
    }
    .modelContainer(for: TaskItem.self, inMemory: true)
}
