//
//  ContractorMustDoApp.swift
//  ContractorMustDo
//
//  A persistent "nagging" reminder iOS app for contractors.
//

import SwiftUI
import SwiftData

// MARK: - App Entry Point

/// Main application entry point for ContractorMustDo.
///
/// This app provides persistent nagging reminders for contractors who need
/// relentless accountability to complete their tasks.
@main
struct ContractorMustDoApp: App {
    /// Shared notification service for the entire app
    @StateObject private var notificationService = NotificationService.shared

    /// Shared timer manager for the entire app
    @StateObject private var timerManager = TimerManager.shared

    /// App settings manager
    @StateObject private var settingsManager = SettingsManager.shared

    /// SwiftData model container for persistence
    private let modelContainer: ModelContainer

    init() {
        do {
            let schema = Schema([
                TaskItem.self,
                TimerItem.self
            ])
            let modelConfiguration = ModelConfiguration(
                schema: schema,
                isStoredInMemoryOnly: false,
                groupContainer: .identifier("group.com.contractormustdo.app")
            )
            modelContainer = try ModelContainer(for: schema, configurations: [modelConfiguration])
        } catch {
            fatalError("Failed to create ModelContainer: \(error)")
        }

        // Request notification permissions on launch
        Task {
            await NotificationService.shared.requestAuthorization()
        }
    }

    var body: some Scene {
        WindowGroup {
            ContentView()
                .environmentObject(notificationService)
                .environmentObject(timerManager)
                .environmentObject(settingsManager)
        }
        .modelContainer(modelContainer)
    }
}
