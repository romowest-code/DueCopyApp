'use client';

import { useState, useEffect } from 'react';
import { Task, Timer, Bucket } from '@/types';
import { getTasks, getTimers, getSettings, saveTasks, getBuckets } from '@/lib/storage';
import { requestNotificationPermission, notificationScheduler } from '@/lib/notifications';
import TaskList from '@/components/TaskList';
import TimerList from '@/components/TimerList';
import Settings from '@/components/Settings';
import Navigation from '@/components/Navigation';

type Tab = 'tasks' | 'timers' | 'settings';

export default function Home() {
  const [activeTab, setActiveTab] = useState<Tab>('tasks');
  const [tasks, setTasks] = useState<Task[]>([]);
  const [timers, setTimers] = useState<Timer[]>([]);
  const [buckets, setBuckets] = useState<Bucket[]>([]);
  const [isLoaded, setIsLoaded] = useState(false);

  // Load data on mount
  useEffect(() => {
    setTasks(getTasks());
    setTimers(getTimers());
    setBuckets(getBuckets());
    setIsLoaded(true);

    // Request notification permission
    requestNotificationPermission();

    // Apply theme
    const settings = getSettings();
    applyTheme(settings.theme);
  }, []);

  // Schedule notifications for all tasks
  useEffect(() => {
    if (!isLoaded) return;

    tasks.forEach(task => {
      if (!task.isCompleted) {
        notificationScheduler.scheduleTaskNotification(task, handleTaskNotification);
      }
    });

    return () => {
      notificationScheduler.cancelAll();
    };
  }, [tasks, isLoaded]);

  const handleTaskNotification = (task: Task) => {
    // Update snooze count
    const updatedTasks = tasks.map(t => {
      if (t.id === task.id) {
        return {
          ...t,
          snoozeCount: t.snoozeCount + 1,
          escalationLevel: t.escalatingEnabled ? Math.min(t.escalationLevel + 1, 3) : t.escalationLevel,
          lastNotificationDate: new Date().toISOString(),
        };
      }
      return t;
    });
    setTasks(updatedTasks);
    saveTasks(updatedTasks);
  };

  const applyTheme = (theme: 'light' | 'dark' | 'system') => {
    const isDark =
      theme === 'dark' ||
      (theme === 'system' && window.matchMedia('(prefers-color-scheme: dark)').matches);

    if (isDark) {
      document.documentElement.classList.add('dark');
    } else {
      document.documentElement.classList.remove('dark');
    }
  };

  if (!isLoaded) {
    return (
      <div className="flex items-center justify-center min-h-screen">
        <div className="animate-spin rounded-full h-12 w-12 border-b-2 border-blue-500"></div>
      </div>
    );
  }

  return (
    <main className="max-w-2xl mx-auto px-4 pb-20">
      {/* Header */}
      <header className="py-6">
        <h1 className="text-2xl font-bold text-gray-900 dark:text-white">
          Contractor Must Do
        </h1>
        <p className="text-sm text-gray-500 dark:text-gray-400">
          It won&apos;t shut up until you do the work.
        </p>
      </header>

      {/* Content */}
      <div className="min-h-[calc(100vh-200px)]">
        {activeTab === 'tasks' && (
          <TaskList tasks={tasks} setTasks={setTasks} buckets={buckets} />
        )}
        {activeTab === 'timers' && (
          <TimerList timers={timers} setTimers={setTimers} />
        )}
        {activeTab === 'settings' && (
          <Settings onThemeChange={applyTheme} buckets={buckets} setBuckets={setBuckets} />
        )}
      </div>

      {/* Bottom Navigation */}
      <Navigation activeTab={activeTab} setActiveTab={setActiveTab} taskCount={tasks.filter(t => !t.isCompleted).length} />
    </main>
  );
}
