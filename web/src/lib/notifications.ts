import { Task } from '@/types';
import { getSettings } from './storage';

// Check if notifications are supported
export function isNotificationSupported(): boolean {
  return typeof window !== 'undefined' && 'Notification' in window;
}

// Request notification permission
export async function requestNotificationPermission(): Promise<boolean> {
  if (!isNotificationSupported()) return false;

  if (Notification.permission === 'granted') return true;
  if (Notification.permission === 'denied') return false;

  const permission = await Notification.requestPermission();
  return permission === 'granted';
}

// Check if we're in quiet hours
export function isInQuietHours(): boolean {
  const settings = getSettings();
  if (!settings.quietHoursEnabled) return false;

  const now = new Date();
  const currentMinutes = now.getHours() * 60 + now.getMinutes();

  const [startHour, startMin] = settings.quietHoursStart.split(':').map(Number);
  const [endHour, endMin] = settings.quietHoursEnd.split(':').map(Number);

  const startMinutes = startHour * 60 + startMin;
  const endMinutes = endHour * 60 + endMin;

  if (startMinutes <= endMinutes) {
    return currentMinutes >= startMinutes && currentMinutes < endMinutes;
  } else {
    // Quiet hours span midnight
    return currentMinutes >= startMinutes || currentMinutes < endMinutes;
  }
}

// Show a notification
export function showNotification(title: string, body: string, tag?: string): void {
  if (!isNotificationSupported()) return;
  if (Notification.permission !== 'granted') return;
  if (isInQuietHours()) return;

  new Notification(title, {
    body,
    icon: '/icon.png',
    tag: tag || undefined,
    requireInteraction: true,
  });
}

// Show task reminder notification
export function showTaskReminder(task: Task): void {
  const isOverdue = new Date(task.dueDate) < new Date();
  const title = isOverdue ? 'Task Overdue!' : 'Task Reminder';
  const body = task.snoozeCount > 0
    ? `${task.title} (Reminder #${task.snoozeCount + 1})`
    : task.title;

  showNotification(title, body, `task-${task.id}`);
}

// Show timer complete notification
export function showTimerComplete(timerName: string): void {
  showNotification('Timer Complete!', timerName);
}

// Calculate snooze interval based on nag level and escalation
export function calculateSnoozeInterval(
  baseIntervalMinutes: number,
  nagLevel: 'gentle' | 'moderate' | 'relentless',
  escalationLevel: number,
  escalatingEnabled: boolean
): number {
  const multipliers = {
    gentle: 2.0,
    moderate: 1.0,
    relentless: 0.5,
  };

  let interval = baseIntervalMinutes * multipliers[nagLevel];

  if (escalatingEnabled && escalationLevel > 0) {
    const escalationFactor = Math.pow(0.75, escalationLevel);
    interval *= escalationFactor;
    interval = Math.max(0.5, interval); // Minimum 30 seconds
  }

  return interval;
}

// Notification scheduler class
class NotificationScheduler {
  private scheduledNotifications: Map<string, NodeJS.Timeout> = new Map();

  scheduleTaskNotification(task: Task, onNotify: (task: Task) => void): void {
    this.cancelTaskNotification(task.id);

    if (!task.notificationsEnabled || task.isCompleted) return;

    const dueDate = new Date(task.dueDate);
    const now = new Date();
    const delay = dueDate.getTime() - now.getTime();

    if (delay <= 0) {
      // Task is already due, show notification immediately and schedule auto-snooze
      showTaskReminder(task);
      this.scheduleAutoSnooze(task, onNotify);
    } else {
      // Schedule for future
      const timeout = setTimeout(() => {
        showTaskReminder(task);
        onNotify(task);
        this.scheduleAutoSnooze(task, onNotify);
      }, delay);

      this.scheduledNotifications.set(task.id, timeout);
    }
  }

  scheduleAutoSnooze(task: Task, onNotify: (task: Task) => void): void {
    if (!task.notificationsEnabled || task.isCompleted) return;

    const intervalMinutes = calculateSnoozeInterval(
      task.snoozeIntervalMinutes,
      task.nagLevel,
      task.escalationLevel,
      task.escalatingEnabled
    );

    const delay = intervalMinutes * 60 * 1000;

    const timeout = setTimeout(() => {
      showTaskReminder(task);
      onNotify(task);
      this.scheduleAutoSnooze(task, onNotify);
    }, delay);

    this.scheduledNotifications.set(`snooze-${task.id}`, timeout);
  }

  cancelTaskNotification(taskId: string): void {
    const timeout = this.scheduledNotifications.get(taskId);
    if (timeout) {
      clearTimeout(timeout);
      this.scheduledNotifications.delete(taskId);
    }

    const snoozeTimeout = this.scheduledNotifications.get(`snooze-${taskId}`);
    if (snoozeTimeout) {
      clearTimeout(snoozeTimeout);
      this.scheduledNotifications.delete(`snooze-${taskId}`);
    }
  }

  cancelAll(): void {
    this.scheduledNotifications.forEach(timeout => clearTimeout(timeout));
    this.scheduledNotifications.clear();
  }
}

export const notificationScheduler = new NotificationScheduler();
