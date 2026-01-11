# CLAUDE.md - Project Instructions for Claude Code

## Project Overview
**Contractor Must Do Task App** - A persistent "nagging" reminder iOS app for contractors who need relentless accountability to complete their tasks.

Read `REQUIREMENTS.md` for full feature specifications and success criteria.

---

## Tech Stack
- **Language**: Swift 5.9+
- **UI Framework**: SwiftUI
- **Minimum iOS**: 16.0
- **Architecture**: MVVM
- **Persistence**: SwiftData (preferred) or Core Data
- **Notifications**: UserNotifications framework
- **Widgets**: WidgetKit
- **Voice**: App Intents / SiriKit

---

## Project Structure
```
ContractorMustDo/
├── ContractorMustDoApp.swift      # App entry point
├── Models/                         # Data models
├── Views/                          # SwiftUI views
├── ViewModels/                     # View models
├── Services/                       # Business logic services
├── Widgets/                        # WidgetKit extension
├── Intents/                        # Siri/App Intents
├── Resources/                      # Assets, sounds
└── Tests/                          # Unit tests
```

---

## Coding Standards

### Swift Style
- Use SwiftLint with default rules
- Prefer `let` over `var`
- Use trailing closure syntax
- Mark classes as `final` unless inheritance is needed
- Use `// MARK: -` to organize code sections

### SwiftUI Conventions
- Extract reusable views into separate files
- Use `@StateObject` for owned objects, `@ObservedObject` for passed objects
- Prefer `@Environment` for dependency injection
- Keep views small - extract logic to ViewModels

### Naming
- Types: `PascalCase` (e.g., `TaskListView`, `ReminderService`)
- Variables/functions: `camelCase` (e.g., `taskCount`, `scheduleNotification()`)
- Constants: `camelCase` (e.g., `defaultSnoozeInterval`)
- Files match their primary type name

### Documentation
- All public APIs must have doc comments (`///`)
- Include parameter descriptions for functions
- Add `// MARK:` sections in longer files

---

## Build Commands

```bash
# Build the project
xcodebuild -scheme ContractorMustDo -destination 'platform=iOS Simulator,name=iPhone 15'

# Run tests
xcodebuild test -scheme ContractorMustDo -destination 'platform=iOS Simulator,name=iPhone 15'

# Lint
swiftlint lint --strict

# Lint and auto-fix
swiftlint lint --fix
```

---

## Development Workflow

### When Adding a Feature:
1. Check `REQUIREMENTS.md` for the requirement ID (e.g., REQ-1.1)
2. Create/update the necessary Model
3. Create/update the Service layer
4. Create/update the ViewModel
5. Create/update the View
6. Add unit tests
7. Run SwiftLint - fix all errors
8. Update success criteria checkbox in REQUIREMENTS.md

### When Fixing a Bug:
1. Write a failing test first
2. Fix the bug
3. Verify test passes
4. Run full test suite

---

## Key Implementation Notes

### Notification System (Critical)
The nagging system is the core feature. Implementation priorities:
1. `NotificationService` must handle scheduling, rescheduling, and cancellation
2. Use `UNUserNotificationCenter` with `UNTimeIntervalNotificationTrigger`
3. Implement background refresh to reschedule notifications
4. Store notification state in persistence layer

```swift
// Example snooze intervals to support
enum SnoozeInterval: TimeInterval, CaseIterable {
    case oneMinute = 60
    case fiveMinutes = 300
    case fifteenMinutes = 900
    case thirtyMinutes = 1800
    case oneHour = 3600
}
```

### Persistence
- Use SwiftData with `@Model` macro
- Ensure all CRUD operations work offline
- Task model must include: id, title, dueDate, isCompleted, nagLevel, recurrence, snoozeInterval

### Widgets
- Create WidgetKit extension as separate target
- Share data via App Groups
- Support small, medium, large widget families
- Make widgets interactive (iOS 17+)

---

## Success Criteria Checklist
Reference `REQUIREMENTS.md` for the full checklist. Key gates:

- [ ] All REQ-* requirements implemented
- [ ] `swiftlint lint --strict` returns 0 errors
- [ ] `xcodebuild` compiles with 0 warnings
- [ ] All tests pass
- [ ] README.md complete
- [ ] ARCHITECTURE.md complete

---

## Files to Create First (MVP Order)
1. `ContractorMustDoApp.swift` - App entry
2. `Models/Task.swift` - Core data model
3. `Services/PersistenceService.swift` - SwiftData setup
4. `Services/NotificationService.swift` - Nagging logic
5. `ViewModels/TaskListViewModel.swift` - Main list logic
6. `Views/TaskListView.swift` - Main UI
7. `Views/AddTaskView.swift` - Task creation
8. `Views/TaskRowView.swift` - List row component

---

## Testing Requirements
- Unit tests for all Services
- Unit tests for ViewModels
- Test notification scheduling logic thoroughly
- Test recurrence calculations
- Test natural language parsing

---

## Do NOT
- Do not use third-party dependencies unless absolutely necessary
- Do not skip SwiftLint - fix all errors before moving on
- Do not leave `// TODO` comments without implementing
- Do not hardcode strings - use constants or localization

---

## When Complete
Output `<promise>COMPLETE</promise>` only when:
1. All success criteria in REQUIREMENTS.md are checked ✅
2. App builds without errors or warnings
3. SwiftLint passes with 0 errors
4. All documentation is written
5. Tests pass
