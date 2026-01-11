//
//  AddTimerView.swift
//  ContractorMustDo
//
//  View for creating custom timers.
//

import SwiftUI
import SwiftData

// MARK: - Add Timer View

/// Sheet view for creating a custom timer.
struct AddTimerView: View {
    // MARK: - Properties

    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss
    @EnvironmentObject private var settingsManager: SettingsManager

    @ObservedObject var viewModel: TimerViewModel

    @State private var name = ""
    @State private var hours = 0
    @State private var minutes = 5
    @State private var seconds = 0
    @State private var alertSound: AlertSound
    @State private var repeatAlert = false
    @State private var startImmediately = true

    // MARK: - Initialization

    init(viewModel: TimerViewModel) {
        self.viewModel = viewModel
        _alertSound = State(initialValue: SettingsManager.shared.defaultAlertSound)
    }

    // MARK: - Computed Properties

    private var totalSeconds: TimeInterval {
        TimeInterval(hours * 3600 + minutes * 60 + seconds)
    }

    private var isValid: Bool {
        totalSeconds > 0
    }

    // MARK: - Body

    var body: some View {
        NavigationStack {
            Form {
                // Timer name
                Section {
                    TextField(Strings.Timer.timerName, text: $name)
                }

                // Duration picker
                Section(Strings.Timer.duration) {
                    HStack {
                        Picker("Hours", selection: $hours) {
                            ForEach(0..<24, id: \.self) { hour in
                                Text("\(hour)h").tag(hour)
                            }
                        }
                        .pickerStyle(.wheel)
                        .frame(width: 80)

                        Picker("Minutes", selection: $minutes) {
                            ForEach(0..<60, id: \.self) { min in
                                Text("\(min)m").tag(min)
                            }
                        }
                        .pickerStyle(.wheel)
                        .frame(width: 80)

                        Picker("Seconds", selection: $seconds) {
                            ForEach(0..<60, id: \.self) { sec in
                                Text("\(sec)s").tag(sec)
                            }
                        }
                        .pickerStyle(.wheel)
                        .frame(width: 80)
                    }
                    .frame(height: 120)
                }

                // Alert settings
                Section {
                    Picker(Strings.Sound.alertSound, selection: $alertSound) {
                        ForEach(AlertSound.allCases, id: \.self) { sound in
                            Text(sound.displayName).tag(sound)
                        }
                    }

                    Toggle("Repeat until dismissed", isOn: $repeatAlert)
                }

                // Options
                Section {
                    Toggle("Start immediately", isOn: $startImmediately)
                }
            }
            .navigationTitle(Strings.Timer.addTimer)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button(Strings.Common.cancel) {
                        dismiss()
                    }
                }

                ToolbarItem(placement: .confirmationAction) {
                    Button(Strings.Common.save) {
                        saveTimer()
                    }
                    .disabled(!isValid)
                    .fontWeight(.semibold)
                }
            }
        }
    }

    // MARK: - Methods

    private func saveTimer() {
        let timerName = name.isEmpty ? "Custom Timer" : name

        let timer = TimerItem(
            name: timerName,
            durationSeconds: totalSeconds,
            alertSound: alertSound,
            repeatAlert: repeatAlert
        )

        modelContext.insert(timer)

        if startImmediately {
            viewModel.startTimer(timer)
        }

        dismiss()
    }
}

// MARK: - Preview

#Preview {
    AddTimerView(viewModel: TimerViewModel())
        .modelContainer(for: TimerItem.self, inMemory: true)
        .environmentObject(SettingsManager.shared)
}
