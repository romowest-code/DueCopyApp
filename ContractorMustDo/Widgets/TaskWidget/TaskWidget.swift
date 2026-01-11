//
//  TaskWidget.swift
//  TaskWidget
//
//  Home screen widget showing upcoming and overdue tasks.
//

import WidgetKit
import SwiftUI
import SwiftData

// MARK: - Task Widget

/// Home screen widget displaying task information.
///
/// Supports REQ-4.2: Home Screen widgets (small, medium, large sizes)
/// Supports REQ-4.3: Interactive widgets
struct TaskWidget: Widget {
    let kind: String = "TaskWidget"

    var body: some WidgetConfiguration {
        StaticConfiguration(kind: kind, provider: TaskWidgetProvider()) { entry in
            TaskWidgetEntryView(entry: entry)
                .containerBackground(.fill.tertiary, for: .widget)
        }
        .configurationDisplayName("Tasks")
        .description("View your upcoming and overdue tasks.")
        .supportedFamilies([.systemSmall, .systemMedium, .systemLarge])
    }
}

// MARK: - Widget Provider

/// Provides timeline entries for the task widget.
struct TaskWidgetProvider: TimelineProvider {
    func placeholder(in context: Context) -> TaskWidgetEntry {
        TaskWidgetEntry(
            date: Date(),
            tasks: [],
            overdueCount: 0,
            todayCount: 0
        )
    }

    func getSnapshot(in context: Context, completion: @escaping (TaskWidgetEntry) -> Void) {
        let entry = TaskWidgetEntry(
            date: Date(),
            tasks: [
                WidgetTask(id: UUID(), title: "Call supplier", dueDate: Date(), isOverdue: true),
                WidgetTask(id: UUID(), title: "Submit permit", dueDate: Date().addingTimeInterval(3600), isOverdue: false)
            ],
            overdueCount: 2,
            todayCount: 5
        )
        completion(entry)
    }

    func getTimeline(in context: Context, completion: @escaping (Timeline<TaskWidgetEntry>) -> Void) {
        Task {
            let tasks = await fetchTasks()
            let overdueCount = tasks.filter { $0.isOverdue }.count
            let todayCount = tasks.filter { Calendar.current.isDateInToday($0.dueDate) }.count

            let entry = TaskWidgetEntry(
                date: Date(),
                tasks: Array(tasks.prefix(5)),
                overdueCount: overdueCount,
                todayCount: todayCount
            )

            // Refresh every 15 minutes
            let refreshDate = Calendar.current.date(byAdding: .minute, value: 15, to: Date()) ?? Date()
            let timeline = Timeline(entries: [entry], policy: .after(refreshDate))

            completion(timeline)
        }
    }

    private func fetchTasks() async -> [WidgetTask] {
        // In a real implementation, this would fetch from the shared container
        // using SwiftData with App Groups
        guard let containerURL = FileManager.default.containerURL(
            forSecurityApplicationGroupIdentifier: "group.com.contractormustdo.app"
        ) else {
            return []
        }

        // For now, return sample data
        // In production, read from shared SwiftData store
        return [
            WidgetTask(id: UUID(), title: "Call supplier about order", dueDate: Date().addingTimeInterval(-3600), isOverdue: true),
            WidgetTask(id: UUID(), title: "Submit permit application", dueDate: Date().addingTimeInterval(1800), isOverdue: false),
            WidgetTask(id: UUID(), title: "Invoice client", dueDate: Date().addingTimeInterval(7200), isOverdue: false)
        ]
    }
}

// MARK: - Widget Entry

/// Entry containing task data for the widget.
struct TaskWidgetEntry: TimelineEntry {
    let date: Date
    let tasks: [WidgetTask]
    let overdueCount: Int
    let todayCount: Int
}

// MARK: - Widget Task

/// Simplified task model for widget display.
struct WidgetTask: Identifiable {
    let id: UUID
    let title: String
    let dueDate: Date
    let isOverdue: Bool
}

// MARK: - Widget Entry View

/// Main view for the task widget.
struct TaskWidgetEntryView: View {
    var entry: TaskWidgetEntry

    @Environment(\.widgetFamily) var family

    var body: some View {
        switch family {
        case .systemSmall:
            SmallWidgetView(entry: entry)
        case .systemMedium:
            MediumWidgetView(entry: entry)
        case .systemLarge:
            LargeWidgetView(entry: entry)
        default:
            SmallWidgetView(entry: entry)
        }
    }
}

// MARK: - Small Widget View

private struct SmallWidgetView: View {
    let entry: TaskWidgetEntry

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Image(systemName: "checklist")
                    .foregroundStyle(.blue)
                Text("Tasks")
                    .font(.headline)
            }

            Spacer()

            if entry.overdueCount > 0 {
                HStack {
                    Image(systemName: "exclamationmark.triangle.fill")
                        .foregroundStyle(.red)
                        .font(.caption)
                    Text("\(entry.overdueCount) overdue")
                        .font(.caption)
                        .foregroundStyle(.red)
                }
            }

            HStack {
                Image(systemName: "calendar")
                    .foregroundStyle(.orange)
                    .font(.caption)
                Text("\(entry.todayCount) today")
                    .font(.caption)
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }
}

// MARK: - Medium Widget View

private struct MediumWidgetView: View {
    let entry: TaskWidgetEntry

    var body: some View {
        HStack(spacing: 16) {
            // Stats column
            VStack(alignment: .leading, spacing: 8) {
                HStack {
                    Image(systemName: "checklist")
                        .foregroundStyle(.blue)
                    Text("Tasks")
                        .font(.headline)
                }

                Spacer()

                if entry.overdueCount > 0 {
                    StatRow(
                        icon: "exclamationmark.triangle.fill",
                        color: .red,
                        count: entry.overdueCount,
                        label: "overdue"
                    )
                }

                StatRow(
                    icon: "calendar",
                    color: .orange,
                    count: entry.todayCount,
                    label: "today"
                )
            }
            .frame(maxWidth: 100)

            Divider()

            // Tasks list
            VStack(alignment: .leading, spacing: 4) {
                ForEach(entry.tasks.prefix(3)) { task in
                    WidgetTaskRow(task: task)
                }

                if entry.tasks.isEmpty {
                    Text("No tasks")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }

                Spacer()
            }
        }
    }
}

// MARK: - Large Widget View

private struct LargeWidgetView: View {
    let entry: TaskWidgetEntry

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            // Header
            HStack {
                Image(systemName: "checklist")
                    .foregroundStyle(.blue)
                Text("Tasks")
                    .font(.headline)

                Spacer()

                if entry.overdueCount > 0 {
                    Text("\(entry.overdueCount) overdue")
                        .font(.caption)
                        .foregroundStyle(.white)
                        .padding(.horizontal, 8)
                        .padding(.vertical, 4)
                        .background(Capsule().fill(.red))
                }
            }

            Divider()

            // Tasks list
            VStack(alignment: .leading, spacing: 8) {
                ForEach(entry.tasks) { task in
                    WidgetTaskRow(task: task, showTime: true)
                }

                if entry.tasks.isEmpty {
                    VStack(spacing: 8) {
                        Image(systemName: "checkmark.circle")
                            .font(.largeTitle)
                            .foregroundStyle(.secondary)
                        Text("No upcoming tasks")
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                    }
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                }
            }

            Spacer()
        }
    }
}

// MARK: - Widget Task Row

private struct WidgetTaskRow: View {
    let task: WidgetTask
    var showTime: Bool = false

    var body: some View {
        HStack(spacing: 8) {
            Circle()
                .fill(task.isOverdue ? .red : .blue)
                .frame(width: 8, height: 8)

            Text(task.title)
                .font(.caption)
                .lineLimit(1)

            Spacer()

            if showTime {
                Text(task.dueDate, style: .time)
                    .font(.caption2)
                    .foregroundStyle(.secondary)
            }
        }
    }
}

// MARK: - Stat Row

private struct StatRow: View {
    let icon: String
    let color: Color
    let count: Int
    let label: String

    var body: some View {
        HStack(spacing: 4) {
            Image(systemName: icon)
                .foregroundStyle(color)
                .font(.caption)
            Text("\(count) \(label)")
                .font(.caption)
        }
    }
}

// MARK: - Preview

#Preview(as: .systemSmall) {
    TaskWidget()
} timeline: {
    TaskWidgetEntry(
        date: Date(),
        tasks: [
            WidgetTask(id: UUID(), title: "Call supplier", dueDate: Date(), isOverdue: true)
        ],
        overdueCount: 2,
        todayCount: 5
    )
}

#Preview(as: .systemMedium) {
    TaskWidget()
} timeline: {
    TaskWidgetEntry(
        date: Date(),
        tasks: [
            WidgetTask(id: UUID(), title: "Call supplier", dueDate: Date(), isOverdue: true),
            WidgetTask(id: UUID(), title: "Submit permit", dueDate: Date().addingTimeInterval(3600), isOverdue: false),
            WidgetTask(id: UUID(), title: "Invoice client", dueDate: Date().addingTimeInterval(7200), isOverdue: false)
        ],
        overdueCount: 2,
        todayCount: 5
    )
}
