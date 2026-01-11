//
//  TaskWidgetBundle.swift
//  TaskWidget
//
//  Widget extension bundle for ContractorMustDo.
//

import WidgetKit
import SwiftUI

// MARK: - Widget Bundle

/// Bundle containing all widgets for the app.
@main
struct TaskWidgetBundle: WidgetBundle {
    var body: some Widget {
        TaskWidget()
        TaskLockScreenWidget()
    }
}
