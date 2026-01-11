//
//  ContentView.swift
//  ContractorMustDo
//
//  Main content view with tab navigation.
//

import SwiftUI
import SwiftData

// MARK: - Content View

/// Main content view providing tab-based navigation.
///
/// Contains three main sections:
/// - Tasks: Main task list and management
/// - Timers: Countdown timers for job tracking
/// - Settings: App customization options
struct ContentView: View {
    @Environment(\.modelContext) private var modelContext
    @EnvironmentObject private var settingsManager: SettingsManager

    @State private var selectedTab: Tab = .tasks

    var body: some View {
        TabView(selection: $selectedTab) {
            TaskListView()
                .tabItem {
                    Label(Strings.Tab.tasks, systemImage: "checklist")
                }
                .tag(Tab.tasks)

            TimerListView()
                .tabItem {
                    Label(Strings.Tab.timers, systemImage: "timer")
                }
                .tag(Tab.timers)

            SettingsView()
                .tabItem {
                    Label(Strings.Tab.settings, systemImage: "gear")
                }
                .tag(Tab.settings)
        }
        .tint(settingsManager.accentColor)
        .preferredColorScheme(settingsManager.colorSchemePreference)
    }
}

// MARK: - Tab Enum

/// Represents the available tabs in the app.
enum Tab: String, CaseIterable {
    case tasks
    case timers
    case settings
}

// MARK: - Preview

#Preview {
    ContentView()
        .modelContainer(for: [TaskItem.self, TimerItem.self], inMemory: true)
        .environmentObject(NotificationService.shared)
        .environmentObject(TimerManager.shared)
        .environmentObject(SettingsManager.shared)
}
