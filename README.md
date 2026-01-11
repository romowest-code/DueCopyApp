# Contractor Must Do

**It won't shut up until you do the work.**

A persistent "nagging" reminder iOS app designed for contractors who need relentless accountability to complete their tasks.

## Overview

Contractor Must Do is a task management app built specifically for solo contractors and tradespeople who juggle multiple jobs and need persistent reminders that can't be easily dismissed. Inspired by the "Due" app's nagging functionality, this app ensures tasks get done by continuously reminding you until they're completed.

## Features

### Persistent Nagging System
- Auto-snooze notifications that keep reminding until done
- Customizable snooze intervals (1 min, 5 min, 15 min, 30 min, 1 hour)
- Escalating notification intensity for ignored reminders
- Per-task "Nag Level" settings (Gentle, Moderate, Relentless)

### Recurring Reminders
- Daily, weekly, monthly repetition patterns
- Specific weekday selection for weekly tasks
- Custom intervals (every X days/weeks/months)
- Repeat-from-completion option

### Natural Language Input
- Quick-add tasks using natural language
- Parse phrases like "call supplier every Monday at 9am"
- Smart date and time detection
- Contractor-specific term recognition

### Countdown Timers
- Multiple countdown timers for job tracking
- Preset timers (15 min break, 30 min break, 1 hour focus, Pomodoro)
- Custom timer creation
- Timer completion notifications

### Widgets
- Lock screen widget showing overdue/upcoming tasks
- Home screen widgets (small, medium, large)
- Quick task overview at a glance

### Siri Integration
- "Add Task" voice command
- "What's overdue?" query
- "Mark task complete" command
- Full Shortcuts app integration

### Customization
- Light, Dark, and High Contrast themes
- Multiple alert sounds
- Quiet hours scheduling
- Default nag level and snooze settings

### Offline Support
- Full functionality without internet
- Local SwiftData persistence
- Works reliably on job sites

## Requirements

- macOS 13+ (Ventura or later)
- Xcode 15.0+
- iOS 16.0+ Simulator or device
- Swift 5.9+

## Quick Start

1. Clone the repository:
   ```bash
   git clone https://github.com/yourusername/DueCopyApp.git
   cd DueCopyApp
   ```

2. Run the setup script (generates Xcode project):
   ```bash
   chmod +x setup.sh
   ./setup.sh
   ```

3. Open and run:
   ```bash
   open ContractorMustDo.xcodeproj
   ```
   Then press `Cmd+R` to run on simulator.

## Alternative: Using Make

```bash
# Full setup (install deps + generate project)
make all

# Open in Xcode
make open

# Build
make build

# Run tests
make test

# Run linter
make lint
```

## Project Structure

```
ContractorMustDo/
├── App/
│   ├── ContractorMustDoApp.swift      # App entry point
│   └── ContentView.swift               # Main tab view
├── Models/
│   ├── TaskItem.swift                  # Task data model
│   └── TimerItem.swift                 # Timer data model
├── Views/
│   ├── TaskListView.swift              # Main task list
│   ├── TaskRowView.swift               # Task list row
│   ├── AddTaskView.swift               # Add task sheet
│   ├── TaskDetailView.swift            # Task detail/edit
│   ├── TimerListView.swift             # Timer management
│   ├── AddTimerView.swift              # Add timer sheet
│   └── SettingsView.swift              # App settings
├── ViewModels/
│   ├── TaskListViewModel.swift         # Task list logic
│   └── TimerViewModel.swift            # Timer logic
├── Services/
│   ├── NotificationService.swift       # Notification scheduling
│   ├── NaturalLanguageParser.swift     # NL input parsing
│   ├── TimerManager.swift              # Timer state management
│   └── SettingsManager.swift           # App settings
├── Widgets/
│   └── TaskWidget/                     # WidgetKit extension
├── Intents/
│   ├── TaskAppIntents.swift            # Task Siri intents
│   └── TimerAppIntents.swift           # Timer Siri intents
└── Resources/
    └── Strings.swift                   # Localized strings
```

## Architecture

The app follows the MVVM (Model-View-ViewModel) architecture pattern:

- **Models**: SwiftData models for persistence (TaskItem, TimerItem)
- **Views**: SwiftUI views for UI presentation
- **ViewModels**: Business logic and state management
- **Services**: Shared services (notifications, settings, timers)

See [ARCHITECTURE.md](ARCHITECTURE.md) for detailed architecture documentation.

## Key Technologies

- **SwiftUI**: Modern declarative UI framework
- **SwiftData**: Apple's persistence framework
- **UserNotifications**: Local notification scheduling
- **WidgetKit**: Home screen and lock screen widgets
- **App Intents**: Siri and Shortcuts integration
- **NaturalLanguage**: Text parsing and processing

## Testing

Run unit tests:
```bash
xcodebuild test -scheme ContractorMustDo -destination 'platform=iOS Simulator,name=iPhone 15'
```

## Code Quality

Run SwiftLint:
```bash
swiftlint lint --strict
```

## Contributing

1. Fork the repository
2. Create a feature branch
3. Make your changes
4. Run tests and linting
5. Submit a pull request

## License

This project is licensed under the MIT License - see the LICENSE file for details.

## Acknowledgments

- Inspired by the [Due](https://www.dueapp.com/) app's persistent reminder approach
- Built with love for contractors who need to get things done
