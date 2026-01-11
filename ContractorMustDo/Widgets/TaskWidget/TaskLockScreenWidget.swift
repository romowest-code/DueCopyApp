//
//  TaskLockScreenWidget.swift
//  TaskWidget
//
//  Lock screen widget showing overdue and upcoming tasks.
//

import WidgetKit
import SwiftUI

// MARK: - Lock Screen Widget

/// Lock screen widget for quick task overview.
///
/// Supports REQ-4.1: iOS Lock Screen widget showing overdue/upcoming tasks
struct TaskLockScreenWidget: Widget {
    let kind: String = "TaskLockScreenWidget"

    var body: some WidgetConfiguration {
        StaticConfiguration(kind: kind, provider: LockScreenWidgetProvider()) { entry in
            LockScreenWidgetEntryView(entry: entry)
                .containerBackground(.fill.tertiary, for: .widget)
        }
        .configurationDisplayName("Task Summary")
        .description("See your task counts at a glance.")
        .supportedFamilies([
            .accessoryCircular,
            .accessoryRectangular,
            .accessoryInline
        ])
    }
}

// MARK: - Lock Screen Widget Provider

struct LockScreenWidgetProvider: TimelineProvider {
    func placeholder(in context: Context) -> LockScreenWidgetEntry {
        LockScreenWidgetEntry(date: Date(), overdueCount: 0, todayCount: 0, nextTask: nil)
    }

    func getSnapshot(in context: Context, completion: @escaping (LockScreenWidgetEntry) -> Void) {
        let entry = LockScreenWidgetEntry(
            date: Date(),
            overdueCount: 2,
            todayCount: 5,
            nextTask: "Call supplier"
        )
        completion(entry)
    }

    func getTimeline(in context: Context, completion: @escaping (Timeline<LockScreenWidgetEntry>) -> Void) {
        // In production, fetch from shared container
        let entry = LockScreenWidgetEntry(
            date: Date(),
            overdueCount: 2,
            todayCount: 5,
            nextTask: "Call supplier"
        )

        let refreshDate = Calendar.current.date(byAdding: .minute, value: 15, to: Date()) ?? Date()
        let timeline = Timeline(entries: [entry], policy: .after(refreshDate))

        completion(timeline)
    }
}

// MARK: - Lock Screen Widget Entry

struct LockScreenWidgetEntry: TimelineEntry {
    let date: Date
    let overdueCount: Int
    let todayCount: Int
    let nextTask: String?
}

// MARK: - Lock Screen Widget Entry View

struct LockScreenWidgetEntryView: View {
    var entry: LockScreenWidgetEntry

    @Environment(\.widgetFamily) var family

    var body: some View {
        switch family {
        case .accessoryCircular:
            CircularAccessoryView(entry: entry)
        case .accessoryRectangular:
            RectangularAccessoryView(entry: entry)
        case .accessoryInline:
            InlineAccessoryView(entry: entry)
        default:
            CircularAccessoryView(entry: entry)
        }
    }
}

// MARK: - Circular Accessory View

private struct CircularAccessoryView: View {
    let entry: LockScreenWidgetEntry

    var body: some View {
        ZStack {
            AccessoryWidgetBackground()

            VStack(spacing: 2) {
                if entry.overdueCount > 0 {
                    Image(systemName: "exclamationmark.triangle.fill")
                        .font(.caption)
                    Text("\(entry.overdueCount)")
                        .font(.headline)
                } else {
                    Image(systemName: "checkmark.circle")
                        .font(.title3)
                    Text("\(entry.todayCount)")
                        .font(.caption)
                }
            }
        }
    }
}

// MARK: - Rectangular Accessory View

private struct RectangularAccessoryView: View {
    let entry: LockScreenWidgetEntry

    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            HStack {
                Image(systemName: "checklist")
                Text("Tasks")
                    .font(.headline)
            }

            if entry.overdueCount > 0 {
                HStack(spacing: 4) {
                    Image(systemName: "exclamationmark.triangle.fill")
                    Text("\(entry.overdueCount) overdue")
                }
                .font(.caption)
            }

            if let nextTask = entry.nextTask {
                Text(nextTask)
                    .font(.caption2)
                    .lineLimit(1)
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }
}

// MARK: - Inline Accessory View

private struct InlineAccessoryView: View {
    let entry: LockScreenWidgetEntry

    var body: some View {
        if entry.overdueCount > 0 {
            Label("\(entry.overdueCount) overdue tasks", systemImage: "exclamationmark.triangle.fill")
        } else if entry.todayCount > 0 {
            Label("\(entry.todayCount) tasks today", systemImage: "checklist")
        } else {
            Label("No tasks", systemImage: "checkmark.circle")
        }
    }
}

// MARK: - Preview

#Preview(as: .accessoryCircular) {
    TaskLockScreenWidget()
} timeline: {
    LockScreenWidgetEntry(date: Date(), overdueCount: 2, todayCount: 5, nextTask: "Call supplier")
}

#Preview(as: .accessoryRectangular) {
    TaskLockScreenWidget()
} timeline: {
    LockScreenWidgetEntry(date: Date(), overdueCount: 2, todayCount: 5, nextTask: "Call supplier")
}
