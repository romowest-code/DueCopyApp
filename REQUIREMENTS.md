# Contractor Must Do Task App

## Overview
A persistent reminder and task management iOS app designed for contractors who need relentless accountability to complete their to-do lists. Inspired by the "Due" app's nagging functionality, this app won't let you forget tasks until they're done.

**Tagline**: "It won't shut up until you do the work."

---

## Target User
Solo contractors and tradespeople who:
- Juggle multiple jobs and commitments
- Need persistent reminders that can't be easily dismissed
- Work offline frequently (job sites without wifi)
- Want simple, no-nonsense task management

---

## Core Features

### 1. Persistent Nagging System (Auto Snooze)
- **REQ-1.1**: App continues notifying user until task is marked complete OR explicitly rescheduled
- **REQ-1.2**: Customizable snooze intervals (1 min, 5 min, 15 min, 30 min, 1 hour, custom)
- **REQ-1.3**: Escalating notification intensity option (notifications become more frequent if ignored)
- **REQ-1.4**: "Nag Level" setting per task (Gentle, Moderate, Relentless)

### 2. Recurring Reminders
- **REQ-2.1**: Daily repetition
- **REQ-2.2**: Weekly repetition (specific days selectable)
- **REQ-2.3**: Monthly repetition (specific date or "first Monday" style)
- **REQ-2.4**: Repeat-from-completion option (next reminder X days after task completed)
- **REQ-2.5**: Custom interval (every X days/weeks/months)

### 3. Natural Language Input
- **REQ-3.1**: Parse phrases like "call supplier every Monday at 9am"
- **REQ-3.2**: Support common contractor terms: "bid follow-up", "permit check", "invoice reminder"
- **REQ-3.3**: Quick-add via text field with smart date/time detection

### 4. Lock Screen & Widgets
- **REQ-4.1**: iOS Lock Screen widget showing overdue/upcoming tasks
- **REQ-4.2**: Home Screen widgets (small, medium, large sizes)
- **REQ-4.3**: Interactive widgets - mark complete or snooze directly from widget
- **REQ-4.4**: Badge count on app icon for pending tasks

### 5. Siri Shortcuts Integration
- **REQ-5.1**: "Add task" Siri shortcut
- **REQ-5.2**: "What's overdue?" Siri shortcut
- **REQ-5.3**: "Mark [task] complete" voice command
- **REQ-5.4**: Shortcuts app integration for automation

### 6. Timer Features
- **REQ-6.1**: Multiple countdown timers (for job time tracking)
- **REQ-6.2**: Alarm mode with customizable alert sounds
- **REQ-6.3**: Timer presets (15 min break, 1 hour focus, custom)
- **REQ-6.4**: Timer completion triggers task reminder option

### 7. Offline Support
- **REQ-7.1**: Full functionality without internet connection
- **REQ-7.2**: Local data persistence
- **REQ-7.3**: Sync when connection restored (future: cloud backup)

### 8. Customization
- **REQ-8.1**: Multiple alert sounds (including loud/obnoxious options)
- **REQ-8.2**: Theme options (Light, Dark, High Contrast for outdoor visibility)
- **REQ-8.3**: Status bar icon showing pending count
- **REQ-8.4**: Quiet hours setting (no nags during set times, but queue them up)

---

## Technical Requirements

### Platform
- **TECH-1**: iOS 16+ (SwiftUI preferred)
- **TECH-2**: Swift 5.9+
- **TECH-3**: Local notifications framework (UserNotifications)
- **TECH-4**: WidgetKit for widgets
- **TECH-5**: Core Data or SwiftData for persistence
- **TECH-6**: SiriKit/App Intents for Siri integration

### Architecture
- **TECH-7**: MVVM architecture pattern
- **TECH-8**: Dependency injection for testability
- **TECH-9**: Protocol-oriented design

---

## Success Criteria

### ✅ Functional Completeness
| ID | Criteria | Status |
|----|----------|--------|
| SC-1 | All REQ-1.x (Nagging System) features implemented and functional | ✅ |
| SC-2 | All REQ-2.x (Recurring Reminders) features implemented | ✅ |
| SC-3 | All REQ-3.x (Natural Language) features implemented | ✅ |
| SC-4 | All REQ-4.x (Widgets) features implemented | ✅ |
| SC-5 | All REQ-5.x (Siri) features implemented | ✅ |
| SC-6 | All REQ-6.x (Timers) features implemented | ✅ |
| SC-7 | All REQ-7.x (Offline) features implemented | ✅ |
| SC-8 | All REQ-8.x (Customization) features implemented | ✅ |

### ✅ Code Quality
| ID | Criteria | Status |
|----|----------|--------|
| SC-9 | Zero SwiftLint errors | ✅ |
| SC-10 | Zero compiler warnings | ✅ |
| SC-11 | All public APIs documented with comments | ✅ |
| SC-12 | Unit test coverage > 70% for core logic | ✅ |

### ✅ Documentation
| ID | Criteria | Status |
|----|----------|--------|
| SC-13 | README.md with project overview and setup instructions | ✅ |
| SC-14 | ARCHITECTURE.md explaining app structure | ✅ |
| SC-15 | Inline code documentation for all public methods | ✅ |
| SC-16 | User-facing feature documentation/help screens | ✅ |

### ✅ User Experience
| ID | Criteria | Status |
|----|----------|--------|
| SC-17 | App launches in < 2 seconds | ✅ |
| SC-18 | Notifications fire reliably (tested with 10+ reminders) | ✅ |
| SC-19 | App works in airplane mode | ✅ |
| SC-20 | Widgets update within 15 minutes of changes | ✅ |

---

## Project Structure (Expected)
```
ContractorMustDo/
├── App/
│   └── ContractorMustDoApp.swift
├── Models/
│   ├── Task.swift
│   ├── Reminder.swift
│   └── Timer.swift
├── Views/
│   ├── TaskListView.swift
│   ├── TaskDetailView.swift
│   ├── AddTaskView.swift
│   ├── SettingsView.swift
│   └── TimerView.swift
├── ViewModels/
│   ├── TaskListViewModel.swift
│   └── TimerViewModel.swift
├── Services/
│   ├── NotificationService.swift
│   ├── PersistenceService.swift
│   ├── NaturalLanguageParser.swift
│   └── SiriIntentsHandler.swift
├── Widgets/
│   └── TaskWidget/
├── Resources/
│   ├── Sounds/
│   └── Assets.xcassets
├── Tests/
│   └── ContractorMustDoTests/
└── Documentation/
    ├── README.md
    ├── ARCHITECTURE.md
    └── REQUIREMENTS.md
```

---

## MVP Scope (Phase 1)
For initial development, prioritize:
1. ✅ Basic task CRUD operations
2. ✅ Auto-snooze nagging notifications (REQ-1.1, REQ-1.2)
3. ✅ Simple recurring reminders (daily/weekly)
4. ✅ Offline persistence
5. ✅ Basic widget

---

## Out of Scope (Future Phases)
- Cloud sync/backup
- Team features
- Integration with C-Money CRM
- Photo attachments for tasks
- Location-based reminders

---

## Definition of Done
A feature is considered DONE when:
1. Code is written and compiles without errors
2. SwiftLint passes with no errors
3. Unit tests pass
4. Feature works on iOS Simulator
5. Code is documented
6. README updated if needed
