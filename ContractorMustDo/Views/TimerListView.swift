//
//  TimerListView.swift
//  ContractorMustDo
//
//  View for managing countdown timers.
//

import SwiftUI
import SwiftData

// MARK: - Timer List View

/// Main view for timer management with presets and active timers.
///
/// Supports REQ-6.x: Timer features for job time tracking.
struct TimerListView: View {
    // MARK: - Properties

    @Environment(\.modelContext) private var modelContext
    @EnvironmentObject private var timerManager: TimerManager

    @Query(sort: \TimerItem.createdDate, order: .reverse) private var timers: [TimerItem]

    @StateObject private var viewModel = TimerViewModel()

    // MARK: - Body

    var body: some View {
        NavigationStack {
            List {
                // Presets section
                presetsSection

                // Quick timers section
                quickTimersSection

                // Active timers section
                if !activeTimers.isEmpty {
                    activeTimersSection
                }

                // Saved timers section
                if !savedTimers.isEmpty {
                    savedTimersSection
                }
            }
            .navigationTitle(Strings.Tab.timers)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button {
                        viewModel.showingAddTimer = true
                    } label: {
                        Image(systemName: "plus")
                    }
                }
            }
            .sheet(isPresented: $viewModel.showingAddTimer) {
                AddTimerView(viewModel: viewModel)
            }
        }
    }

    // MARK: - Sections

    private var presetsSection: some View {
        Section(Strings.Timer.presets) {
            ForEach(TimerPreset.allCases, id: \.name) { preset in
                Button {
                    viewModel.createFromPreset(preset, context: modelContext)
                } label: {
                    HStack {
                        Image(systemName: "timer")
                            .foregroundStyle(.secondary)

                        VStack(alignment: .leading) {
                            Text(preset.name)
                                .foregroundStyle(.primary)
                            Text(viewModel.formatDuration(preset.durationSeconds))
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        }

                        Spacer()

                        Image(systemName: "play.fill")
                            .foregroundStyle(.blue)
                    }
                }
                .buttonStyle(.plain)
            }
        }
    }

    private var quickTimersSection: some View {
        Section("Quick Timer") {
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 12) {
                    QuickTimerButton(minutes: 5, viewModel: viewModel, context: modelContext)
                    QuickTimerButton(minutes: 10, viewModel: viewModel, context: modelContext)
                    QuickTimerButton(minutes: 15, viewModel: viewModel, context: modelContext)
                    QuickTimerButton(minutes: 30, viewModel: viewModel, context: modelContext)
                    QuickTimerButton(minutes: 45, viewModel: viewModel, context: modelContext)
                    QuickTimerButton(minutes: 60, viewModel: viewModel, context: modelContext)
                }
                .padding(.vertical, 8)
            }
        }
    }

    private var activeTimersSection: some View {
        Section(Strings.Timer.activeTimers) {
            ForEach(activeTimers) { timer in
                ActiveTimerRow(timer: timer, viewModel: viewModel)
            }
        }
    }

    private var savedTimersSection: some View {
        Section("Saved Timers") {
            ForEach(savedTimers) { timer in
                SavedTimerRow(timer: timer, viewModel: viewModel)
                    .swipeActions(edge: .trailing) {
                        Button(role: .destructive) {
                            viewModel.deleteTimer(timer, context: modelContext)
                        } label: {
                            Label(Strings.Common.delete, systemImage: "trash")
                        }
                    }
            }
        }
    }

    // MARK: - Computed Properties

    private var activeTimers: [TimerItem] {
        timers.filter { timerManager.isRunning($0.id) || timerManager.isPaused($0.id) }
    }

    private var savedTimers: [TimerItem] {
        timers.filter { !timerManager.isRunning($0.id) && !timerManager.isPaused($0.id) && !$0.isPreset }
    }
}

// MARK: - Quick Timer Button

private struct QuickTimerButton: View {
    let minutes: Int
    @ObservedObject var viewModel: TimerViewModel
    let context: ModelContext

    var body: some View {
        Button {
            viewModel.createQuickTimer(minutes: minutes, context: context)
        } label: {
            VStack(spacing: 4) {
                Text("\(minutes)")
                    .font(.title2)
                    .fontWeight(.semibold)
                Text("min")
                    .font(.caption)
            }
            .frame(width: 60, height: 60)
            .background(Color(.secondarySystemFill))
            .cornerRadius(12)
        }
        .buttonStyle(.plain)
    }
}

// MARK: - Active Timer Row

private struct ActiveTimerRow: View {
    let timer: TimerItem
    @ObservedObject var viewModel: TimerViewModel
    @EnvironmentObject private var timerManager: TimerManager

    var body: some View {
        VStack(spacing: 12) {
            // Timer display
            HStack {
                VStack(alignment: .leading) {
                    Text(timer.name)
                        .font(.headline)

                    Text(formattedRemainingTime)
                        .font(.system(size: 36, weight: .medium, design: .monospaced))
                        .foregroundStyle(isRunning ? .primary : .secondary)
                }

                Spacer()

                // Progress ring
                CircularProgressView(progress: progress)
                    .frame(width: 50, height: 50)
            }

            // Controls
            HStack(spacing: 16) {
                if isPaused {
                    Button {
                        viewModel.resumeTimer(timer)
                    } label: {
                        Label("Resume", systemImage: "play.fill")
                            .frame(maxWidth: .infinity)
                    }
                    .buttonStyle(.borderedProminent)
                } else if isRunning {
                    Button {
                        viewModel.pauseTimer(timer)
                    } label: {
                        Label(Strings.Timer.pauseTimer, systemImage: "pause.fill")
                            .frame(maxWidth: .infinity)
                    }
                    .buttonStyle(.borderedProminent)
                    .tint(.orange)
                }

                Button {
                    viewModel.stopTimer(timer)
                } label: {
                    Label(Strings.Timer.stopTimer, systemImage: "stop.fill")
                        .frame(maxWidth: .infinity)
                }
                .buttonStyle(.bordered)
            }
        }
        .padding(.vertical, 8)
    }

    private var isRunning: Bool {
        timerManager.isRunning(timer.id)
    }

    private var isPaused: Bool {
        timerManager.isPaused(timer.id)
    }

    private var formattedRemainingTime: String {
        let remaining = timerManager.remainingTime(for: timer.id) ?? timer.remainingSeconds
        return viewModel.formatDuration(remaining)
    }

    private var progress: Double {
        let remaining = timerManager.remainingTime(for: timer.id) ?? timer.remainingSeconds
        guard timer.durationSeconds > 0 else { return 0 }
        return 1.0 - (remaining / timer.durationSeconds)
    }
}

// MARK: - Saved Timer Row

private struct SavedTimerRow: View {
    let timer: TimerItem
    @ObservedObject var viewModel: TimerViewModel

    var body: some View {
        HStack {
            VStack(alignment: .leading) {
                Text(timer.name)
                    .font(.headline)

                Text(viewModel.formatDuration(timer.durationSeconds))
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }

            Spacer()

            Button {
                viewModel.startTimer(timer)
            } label: {
                Image(systemName: "play.circle.fill")
                    .font(.title)
            }
        }
    }
}

// MARK: - Circular Progress View

private struct CircularProgressView: View {
    let progress: Double

    var body: some View {
        ZStack {
            Circle()
                .stroke(Color(.systemGray5), lineWidth: 4)

            Circle()
                .trim(from: 0, to: progress)
                .stroke(
                    Color.blue,
                    style: StrokeStyle(lineWidth: 4, lineCap: .round)
                )
                .rotationEffect(.degrees(-90))
                .animation(.linear, value: progress)

            Text("\(Int(progress * 100))%")
                .font(.caption2)
                .fontWeight(.medium)
        }
    }
}

// MARK: - Preview

#Preview {
    TimerListView()
        .modelContainer(for: TimerItem.self, inMemory: true)
        .environmentObject(TimerManager.shared)
}
