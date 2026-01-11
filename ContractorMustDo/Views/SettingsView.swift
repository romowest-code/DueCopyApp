//
//  SettingsView.swift
//  ContractorMustDo
//
//  App settings and customization view.
//

import SwiftUI

// MARK: - Settings View

/// View for app settings and customization.
///
/// Supports REQ-8.x: Customization features.
struct SettingsView: View {
    // MARK: - Properties

    @EnvironmentObject private var settingsManager: SettingsManager
    @EnvironmentObject private var notificationService: NotificationService

    @State private var showingResetConfirmation = false
    @State private var showingAbout = false

    // MARK: - Body

    var body: some View {
        NavigationStack {
            Form {
                // Appearance section
                appearanceSection

                // Notification defaults section
                notificationDefaultsSection

                // Quiet hours section
                quietHoursSection

                // Display section
                displaySection

                // About section
                aboutSection

                // Reset section
                resetSection
            }
            .navigationTitle(Strings.Tab.settings)
            .sheet(isPresented: $showingAbout) {
                AboutView()
            }
            .confirmationDialog(
                "Reset Settings",
                isPresented: $showingResetConfirmation,
                titleVisibility: .visible
            ) {
                Button("Reset to Defaults", role: .destructive) {
                    settingsManager.resetToDefaults()
                }
                Button(Strings.Common.cancel, role: .cancel) {}
            } message: {
                Text("This will reset all settings to their default values.")
            }
        }
    }

    // MARK: - Sections

    private var appearanceSection: some View {
        Section(Strings.Settings.appearance) {
            Picker(Strings.Settings.theme, selection: $settingsManager.theme) {
                ForEach(Theme.allCases, id: \.self) { theme in
                    Text(theme.displayName).tag(theme)
                }
            }
        }
    }

    private var notificationDefaultsSection: some View {
        Section {
            Picker(Strings.Settings.defaultNagLevel, selection: $settingsManager.defaultNagLevel) {
                ForEach(NagLevel.allCases, id: \.self) { level in
                    Text(level.displayName).tag(level)
                }
            }

            Picker(Strings.Settings.defaultSnoozeInterval, selection: $settingsManager.defaultSnoozeInterval) {
                ForEach(SnoozeInterval.allCases, id: \.seconds) { interval in
                    Text(interval.displayName).tag(interval)
                }
            }

            Toggle(
                Strings.Settings.escalatingNotifications,
                isOn: $settingsManager.escalatingNotificationsEnabled
            )

            Picker(Strings.Sound.alertSound, selection: $settingsManager.defaultAlertSound) {
                ForEach(AlertSound.allCases, id: \.self) { sound in
                    Text(sound.displayName).tag(sound)
                }
            }
        } header: {
            Text(Strings.Settings.notifications)
        } footer: {
            Text("These settings will be used as defaults for new tasks.")
        }
    }

    private var quietHoursSection: some View {
        Section {
            Toggle(Strings.Settings.quietHours, isOn: $settingsManager.quietHoursEnabled)

            if settingsManager.quietHoursEnabled {
                DatePicker(
                    Strings.Settings.quietHoursStart,
                    selection: $settingsManager.quietHoursStart,
                    displayedComponents: .hourAndMinute
                )

                DatePicker(
                    Strings.Settings.quietHoursEnd,
                    selection: $settingsManager.quietHoursEnd,
                    displayedComponents: .hourAndMinute
                )
            }
        } header: {
            Text(Strings.Settings.quietHours)
        } footer: {
            if settingsManager.quietHoursEnabled {
                Text("Notifications will be queued during quiet hours and delivered when they end.")
            }
        }
    }

    private var displaySection: some View {
        Section("Display") {
            Toggle("Show Completed Tasks", isOn: $settingsManager.showCompletedTasks)
        }
    }

    private var aboutSection: some View {
        Section(Strings.Settings.about) {
            Button {
                showingAbout = true
            } label: {
                HStack {
                    Text("About Contractor Must Do")
                    Spacer()
                    Image(systemName: "chevron.right")
                        .foregroundStyle(.secondary)
                }
            }
            .foregroundStyle(.primary)

            LabeledContent(Strings.Settings.version) {
                Text(appVersion)
            }

            Link(destination: URL(string: "https://github.com/anthropics/claude-code/issues")!) {
                HStack {
                    Text("Send Feedback")
                    Spacer()
                    Image(systemName: "arrow.up.right")
                        .font(.caption)
                }
            }
        }
    }

    private var resetSection: some View {
        Section {
            Button(role: .destructive) {
                showingResetConfirmation = true
            } label: {
                Text("Reset to Defaults")
            }
        }
    }

    // MARK: - Computed Properties

    private var appVersion: String {
        let version = Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "1.0"
        let build = Bundle.main.infoDictionary?["CFBundleVersion"] as? String ?? "1"
        return "\(version) (\(build))"
    }
}

// MARK: - About View

/// About screen with app information.
private struct AboutView: View {
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 24) {
                    // App icon and name
                    VStack(spacing: 12) {
                        Image(systemName: "checkmark.circle.fill")
                            .font(.system(size: 80))
                            .foregroundStyle(.blue)

                        Text("Contractor Must Do")
                            .font(.title)
                            .fontWeight(.bold)

                        Text("It won't shut up until you do the work.")
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                            .italic()
                    }
                    .padding(.top, 40)

                    // Features
                    VStack(alignment: .leading, spacing: 16) {
                        FeatureRow(
                            icon: "bell.badge.fill",
                            title: "Persistent Reminders",
                            description: "Nagging notifications that keep reminding until done"
                        )

                        FeatureRow(
                            icon: "repeat",
                            title: "Recurring Tasks",
                            description: "Daily, weekly, monthly, or custom schedules"
                        )

                        FeatureRow(
                            icon: "text.bubble",
                            title: "Natural Language",
                            description: "Add tasks by typing naturally"
                        )

                        FeatureRow(
                            icon: "timer",
                            title: "Countdown Timers",
                            description: "Track job time with preset and custom timers"
                        )

                        FeatureRow(
                            icon: "rectangle.on.rectangle",
                            title: "Widgets",
                            description: "See tasks at a glance on your home screen"
                        )

                        FeatureRow(
                            icon: "mic.fill",
                            title: "Siri Integration",
                            description: "Add and manage tasks with your voice"
                        )
                    }
                    .padding(.horizontal)

                    Spacer(minLength: 40)
                }
            }
            .navigationTitle(Strings.Settings.about)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button(Strings.Common.done) {
                        dismiss()
                    }
                }
            }
        }
    }
}

// MARK: - Feature Row

private struct FeatureRow: View {
    let icon: String
    let title: String
    let description: String

    var body: some View {
        HStack(alignment: .top, spacing: 16) {
            Image(systemName: icon)
                .font(.title2)
                .foregroundStyle(.blue)
                .frame(width: 32)

            VStack(alignment: .leading, spacing: 4) {
                Text(title)
                    .font(.headline)

                Text(description)
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            }
        }
    }
}

// MARK: - Preview

#Preview {
    SettingsView()
        .environmentObject(SettingsManager.shared)
        .environmentObject(NotificationService.shared)
}
