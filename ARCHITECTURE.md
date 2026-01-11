# Architecture Documentation

## Overview

Contractor Must Do follows the **MVVM (Model-View-ViewModel)** architecture pattern, with additional service layers for cross-cutting concerns like notifications and persistence.

## Architecture Diagram

```
┌─────────────────────────────────────────────────────────────────┐
│                           Views                                  │
│  ┌─────────────┐  ┌─────────────┐  ┌─────────────────────────┐  │
│  │ TaskListView│  │ TimerList   │  │ SettingsView            │  │
│  │ TaskRowView │  │ View        │  │                         │  │
│  │ AddTaskView │  │ AddTimerView│  │                         │  │
│  │ TaskDetail  │  │             │  │                         │  │
│  └──────┬──────┘  └──────┬──────┘  └───────────┬─────────────┘  │
└─────────┼────────────────┼─────────────────────┼────────────────┘
          │                │                     │
          ▼                ▼                     ▼
┌─────────────────────────────────────────────────────────────────┐
│                        ViewModels                                │
│  ┌─────────────────────┐  ┌─────────────────────────────────┐   │
│  │ TaskListViewModel   │  │ TimerViewModel                  │   │
│  │ - filter, sort      │  │ - timer operations              │   │
│  │ - CRUD operations   │  │ - presets                       │   │
│  │ - notification mgmt │  │ - formatting                    │   │
│  └──────────┬──────────┘  └────────────────┬────────────────┘   │
└─────────────┼──────────────────────────────┼────────────────────┘
              │                              │
              ▼                              ▼
┌─────────────────────────────────────────────────────────────────┐
│                          Services                                │
│  ┌────────────────────┐  ┌────────────────┐  ┌───────────────┐  │
│  │ NotificationService│  │ TimerManager   │  │SettingsManager│  │
│  │ - scheduling       │  │ - active timers│  │ - preferences │  │
│  │ - auto-snooze      │  │ - background   │  │ - persistence │  │
│  │ - badge count      │  │   support      │  │               │  │
│  └────────────────────┘  └────────────────┘  └───────────────┘  │
│                                                                  │
│  ┌────────────────────────────────────────────────────────────┐ │
│  │ NaturalLanguageParser                                      │ │
│  │ - date/time extraction                                     │ │
│  │ - recurrence parsing                                       │ │
│  │ - contractor term recognition                              │ │
│  └────────────────────────────────────────────────────────────┘ │
└─────────────────────────────────────────────────────────────────┘
              │
              ▼
┌─────────────────────────────────────────────────────────────────┐
│                          Models                                  │
│  ┌─────────────────────┐  ┌─────────────────────────────────┐   │
│  │ TaskItem            │  │ TimerItem                       │   │
│  │ @Model              │  │ @Model                          │   │
│  │ - id, title, notes  │  │ - id, name, duration            │   │
│  │ - dueDate           │  │ - remainingSeconds              │   │
│  │ - nagLevel          │  │ - alertSound                    │   │
│  │ - recurrence        │  │ - isRunning, isPaused           │   │
│  └─────────────────────┘  └─────────────────────────────────┘   │
└─────────────────────────────────────────────────────────────────┘
              │
              ▼
┌─────────────────────────────────────────────────────────────────┐
│                       SwiftData                                  │
│                   (ModelContainer)                               │
│              App Groups for Widget sharing                       │
└─────────────────────────────────────────────────────────────────┘
```

## Layer Responsibilities

### Models Layer

**Location**: `ContractorMustDo/Models/`

Models are SwiftData `@Model` classes that represent the core data structures:

#### TaskItem
- Core task properties (title, notes, dueDate)
- Nagging configuration (nagLevel, snoozeInterval, escalating)
- Recurrence settings (type, days, interval)
- Computed properties (isOverdue, isDueToday, isRecurring)
- Methods for completion and snoozing

#### TimerItem
- Timer configuration (name, duration, alertSound)
- State tracking (isRunning, isPaused, remainingSeconds)
- Control methods (start, pause, stop)
- Preset support

### Views Layer

**Location**: `ContractorMustDo/Views/`

SwiftUI views handle all UI presentation:

- **TaskListView**: Main task list with filtering, sorting, and quick-add
- **TaskRowView**: Individual task display with swipe actions
- **AddTaskView**: Task creation form with all options
- **TaskDetailView**: View and edit task details
- **TimerListView**: Timer management with presets
- **AddTimerView**: Custom timer creation
- **SettingsView**: App configuration

Views are kept focused on presentation, delegating logic to ViewModels.

### ViewModels Layer

**Location**: `ContractorMustDo/ViewModels/`

ViewModels contain business logic and manage state:

#### TaskListViewModel
- Task filtering and sorting
- CRUD operations coordination
- Notification scheduling
- Natural language parsing integration
- Badge count management

#### TimerViewModel
- Timer creation and control
- Preset management
- Duration formatting
- Timer state queries

ViewModels are `@MainActor` to ensure UI updates happen on the main thread.

### Services Layer

**Location**: `ContractorMustDo/Services/`

Services provide shared functionality across the app:

#### NotificationService
The core of the nagging system:
- Notification authorization
- Task notification scheduling
- Auto-snooze logic with escalation
- Timer completion notifications
- Badge count management
- Quiet hours support

#### TimerManager
Manages active countdown timers:
- Timer state tracking
- Background execution support
- Update timer for live countdown
- Notification scheduling

#### SettingsManager
Persists user preferences:
- Theme selection
- Default nag level and snooze interval
- Quiet hours configuration
- Alert sound preferences

#### NaturalLanguageParser
Parses natural language input:
- Date and time extraction
- Recurrence pattern detection
- Contractor term recognition
- Title cleaning

## Data Flow

### Task Creation Flow

```
User Input → AddTaskView
                ↓
        TaskListViewModel.addTask()
                ↓
    ┌───────────┴───────────┐
    ↓                       ↓
ModelContext.insert()   NotificationService.schedule()
    ↓                       ↓
SwiftData persist      UNUserNotificationCenter
```

### Nagging Notification Flow

```
Notification Fires → User Dismisses/Ignores
                           ↓
              NotificationService receives callback
                           ↓
                    TaskItem.snooze()
                           ↓
              Calculate next snooze interval
              (based on nagLevel × escalation)
                           ↓
              Schedule next notification
                           ↓
                    Repeat until completed
```

### Natural Language Parsing Flow

```
User Input: "call supplier every Monday at 9am"
                    ↓
          NaturalLanguageParser.parse()
                    ↓
    ┌───────────────┼───────────────┐
    ↓               ↓               ↓
Extract Title   Extract Time   Extract Recurrence
"Call supplier"   9:00 AM       Weekly, Monday
                    ↓
            Combine into ParsedTask
                    ↓
          TaskListViewModel.addTask()
```

## Widget Architecture

Widgets use a separate timeline provider and simplified data models:

```
TaskWidget
    ↓
TaskWidgetProvider (TimelineProvider)
    ↓
Fetch from App Group container
    ↓
TaskWidgetEntry
    ↓
TaskWidgetEntryView (adapts to widget family)
```

Widgets refresh every 15 minutes and share data via App Groups.

## App Intents Architecture

Siri integration uses the App Intents framework:

```
Siri: "Add task call supplier"
            ↓
      AddTaskIntent
            ↓
    Intent parameters
    (title, dueDate, notes)
            ↓
    Create TaskItem
            ↓
    Save to shared container
            ↓
    Return IntentResult with dialog
```

## Threading Model

- **Main Thread**: All UI updates, ViewModels (`@MainActor`)
- **Background**: Notification scheduling, SwiftData operations
- **Timer Updates**: RunLoop.common mode for smooth animations

## Persistence Strategy

### SwiftData Configuration
- Schema: TaskItem, TimerItem
- Storage: File-based (not in-memory)
- App Group: Shared container for widget access

### Data Sharing
- Main app and widgets share ModelContainer via App Groups
- Group identifier: `group.com.contractormustdo.app`

## Testing Strategy

### Unit Tests
- Model tests (TaskItemTests, TimerItemTests)
- Parser tests (NaturalLanguageParserTests)
- Settings tests (SettingsManagerTests)

### Test Coverage Goals
- Core models: 90%+
- Services: 80%+
- ViewModels: 70%+

## Design Decisions

### Why SwiftData over Core Data?
- Modern Swift-native API
- Simpler model definitions with `@Model`
- Better SwiftUI integration
- Future-proof investment

### Why MVVM?
- Clear separation of concerns
- Testable business logic
- SwiftUI-friendly pattern
- Industry standard for iOS

### Why Singleton Services?
- Single source of truth for notifications
- Centralized settings management
- Consistent timer state across views
- Simpler dependency management

### Why App Intents over SiriKit?
- Modern framework with better Swift integration
- Simpler implementation
- Shortcuts app compatibility
- Future-proof approach

## Future Considerations

### Cloud Sync
- iCloud backup via CloudKit
- Cross-device sync
- Conflict resolution strategy

### Team Features
- Shared task lists
- Assignment and delegation
- Activity feed

### Location Features
- Geofenced reminders
- Job site detection
- Automatic task suggestions
