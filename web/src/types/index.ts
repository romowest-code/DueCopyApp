// Task Types

export type NagLevel = 'gentle' | 'moderate' | 'relentless';

export type SnoozeInterval = 1 | 5 | 15 | 30 | 60; // minutes

export type RecurrenceType = 'daily' | 'weekly' | 'monthly' | 'custom';

export interface Task {
  id: string;
  title: string;
  notes: string;
  dueDate: string; // ISO string
  isCompleted: boolean;
  completedDate: string | null;
  createdDate: string;

  // Nagging settings
  nagLevel: NagLevel;
  snoozeIntervalMinutes: SnoozeInterval;
  escalatingEnabled: boolean;
  escalationLevel: number;
  lastNotificationDate: string | null;
  snoozeCount: number;

  // Recurrence settings
  recurrenceType: RecurrenceType | null;
  recurrenceDays: number[]; // 0 = Sunday, 6 = Saturday
  recurrenceInterval: number;
  repeatFromCompletion: boolean;

  // Notification
  notificationsEnabled: boolean;
}

// Timer Types

export type AlertSound = 'default' | 'bell' | 'chime' | 'alarm' | 'loud';

export interface Timer {
  id: string;
  name: string;
  durationSeconds: number;
  remainingSeconds: number;
  isRunning: boolean;
  isPaused: boolean;
  startTime: string | null;
  alertSound: AlertSound;
  createdDate: string;
}

export interface TimerPreset {
  name: string;
  durationSeconds: number;
}

// Settings Types

export type Theme = 'light' | 'dark' | 'system';

export interface Settings {
  theme: Theme;
  defaultNagLevel: NagLevel;
  defaultSnoozeInterval: SnoozeInterval;
  escalatingNotificationsEnabled: boolean;
  quietHoursEnabled: boolean;
  quietHoursStart: string; // HH:mm
  quietHoursEnd: string; // HH:mm
  defaultAlertSound: AlertSound;
  showCompletedTasks: boolean;
}

// Parsed Task from Natural Language

export interface ParsedTask {
  title: string;
  dueDate: Date | null;
  recurrence: {
    type: RecurrenceType;
    days: number[];
    interval: number;
  } | null;
}
