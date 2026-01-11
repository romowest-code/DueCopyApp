import { Task, Timer, Settings } from '@/types';

const TASKS_KEY = 'contractor-must-do-tasks';
const TIMERS_KEY = 'contractor-must-do-timers';
const SETTINGS_KEY = 'contractor-must-do-settings';

// Default settings
export const defaultSettings: Settings = {
  theme: 'system',
  defaultNagLevel: 'moderate',
  defaultSnoozeInterval: 5,
  escalatingNotificationsEnabled: false,
  quietHoursEnabled: false,
  quietHoursStart: '22:00',
  quietHoursEnd: '07:00',
  defaultAlertSound: 'default',
  showCompletedTasks: false,
};

// Tasks
export function getTasks(): Task[] {
  if (typeof window === 'undefined') return [];
  const data = localStorage.getItem(TASKS_KEY);
  return data ? JSON.parse(data) : [];
}

export function saveTasks(tasks: Task[]): void {
  if (typeof window === 'undefined') return;
  localStorage.setItem(TASKS_KEY, JSON.stringify(tasks));
}

export function addTask(task: Task): void {
  const tasks = getTasks();
  tasks.push(task);
  saveTasks(tasks);
}

export function updateTask(updatedTask: Task): void {
  const tasks = getTasks();
  const index = tasks.findIndex(t => t.id === updatedTask.id);
  if (index !== -1) {
    tasks[index] = updatedTask;
    saveTasks(tasks);
  }
}

export function deleteTask(taskId: string): void {
  const tasks = getTasks().filter(t => t.id !== taskId);
  saveTasks(tasks);
}

// Timers
export function getTimers(): Timer[] {
  if (typeof window === 'undefined') return [];
  const data = localStorage.getItem(TIMERS_KEY);
  return data ? JSON.parse(data) : [];
}

export function saveTimers(timers: Timer[]): void {
  if (typeof window === 'undefined') return;
  localStorage.setItem(TIMERS_KEY, JSON.stringify(timers));
}

export function addTimer(timer: Timer): void {
  const timers = getTimers();
  timers.push(timer);
  saveTimers(timers);
}

export function updateTimer(updatedTimer: Timer): void {
  const timers = getTimers();
  const index = timers.findIndex(t => t.id === updatedTimer.id);
  if (index !== -1) {
    timers[index] = updatedTimer;
    saveTimers(timers);
  }
}

export function deleteTimer(timerId: string): void {
  const timers = getTimers().filter(t => t.id !== timerId);
  saveTimers(timers);
}

// Settings
export function getSettings(): Settings {
  if (typeof window === 'undefined') return defaultSettings;
  const data = localStorage.getItem(SETTINGS_KEY);
  return data ? { ...defaultSettings, ...JSON.parse(data) } : defaultSettings;
}

export function saveSettings(settings: Settings): void {
  if (typeof window === 'undefined') return;
  localStorage.setItem(SETTINGS_KEY, JSON.stringify(settings));
}
