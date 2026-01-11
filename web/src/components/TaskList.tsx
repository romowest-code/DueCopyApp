'use client';

import { useState } from 'react';
import { v4 as uuidv4 } from 'uuid';
import { Task, NagLevel, SnoozeInterval, RecurrenceType } from '@/types';
import { saveTasks, getSettings } from '@/lib/storage';
import { parseNaturalLanguage } from '@/lib/parser';
import { notificationScheduler } from '@/lib/notifications';
import { formatDistanceToNow, format, isPast, isToday } from 'date-fns';

interface TaskListProps {
  tasks: Task[];
  setTasks: (tasks: Task[]) => void;
}

export default function TaskList({ tasks, setTasks }: TaskListProps) {
  const [quickAddText, setQuickAddText] = useState('');
  const [showAddModal, setShowAddModal] = useState(false);
  const [editingTask, setEditingTask] = useState<Task | null>(null);
  const [filter, setFilter] = useState<'all' | 'overdue' | 'today' | 'upcoming'>('all');

  const settings = getSettings();

  // Filter tasks
  const filteredTasks = tasks.filter(task => {
    if (!settings.showCompletedTasks && task.isCompleted) return false;

    const dueDate = new Date(task.dueDate);
    switch (filter) {
      case 'overdue':
        return isPast(dueDate) && !task.isCompleted;
      case 'today':
        return isToday(dueDate) && !task.isCompleted;
      case 'upcoming':
        return !isPast(dueDate) && !isToday(dueDate) && !task.isCompleted;
      default:
        return true;
    }
  }).sort((a, b) => new Date(a.dueDate).getTime() - new Date(b.dueDate).getTime());

  const handleQuickAdd = (e: React.FormEvent) => {
    e.preventDefault();
    if (!quickAddText.trim()) return;

    const parsed = parseNaturalLanguage(quickAddText);
    const newTask = createTask(
      parsed.title || quickAddText,
      parsed.dueDate || new Date(Date.now() + 3600000),
      parsed.recurrence?.type || null,
      parsed.recurrence?.days || [],
      parsed.recurrence?.interval || 1
    );

    const updatedTasks = [...tasks, newTask];
    setTasks(updatedTasks);
    saveTasks(updatedTasks);
    setQuickAddText('');
  };

  const createTask = (
    title: string,
    dueDate: Date,
    recurrenceType: RecurrenceType | null = null,
    recurrenceDays: number[] = [],
    recurrenceInterval: number = 1
  ): Task => {
    return {
      id: uuidv4(),
      title,
      notes: '',
      dueDate: dueDate.toISOString(),
      isCompleted: false,
      completedDate: null,
      createdDate: new Date().toISOString(),
      nagLevel: settings.defaultNagLevel,
      snoozeIntervalMinutes: settings.defaultSnoozeInterval,
      escalatingEnabled: settings.escalatingNotificationsEnabled,
      escalationLevel: 0,
      lastNotificationDate: null,
      snoozeCount: 0,
      recurrenceType,
      recurrenceDays,
      recurrenceInterval,
      repeatFromCompletion: false,
      notificationsEnabled: true,
    };
  };

  const toggleComplete = (taskId: string) => {
    const updatedTasks = tasks.map(task => {
      if (task.id === taskId) {
        const isNowCompleted = !task.isCompleted;
        if (isNowCompleted) {
          notificationScheduler.cancelTaskNotification(taskId);
        }
        return {
          ...task,
          isCompleted: isNowCompleted,
          completedDate: isNowCompleted ? new Date().toISOString() : null,
          snoozeCount: isNowCompleted ? 0 : task.snoozeCount,
          escalationLevel: isNowCompleted ? 0 : task.escalationLevel,
        };
      }
      return task;
    });
    setTasks(updatedTasks);
    saveTasks(updatedTasks);
  };

  const snoozeTask = (taskId: string, minutes: number) => {
    const updatedTasks = tasks.map(task => {
      if (task.id === taskId) {
        const newDueDate = new Date(Date.now() + minutes * 60 * 1000);
        return {
          ...task,
          dueDate: newDueDate.toISOString(),
          snoozeCount: task.snoozeCount + 1,
        };
      }
      return task;
    });
    setTasks(updatedTasks);
    saveTasks(updatedTasks);
  };

  const deleteTask = (taskId: string) => {
    notificationScheduler.cancelTaskNotification(taskId);
    const updatedTasks = tasks.filter(t => t.id !== taskId);
    setTasks(updatedTasks);
    saveTasks(updatedTasks);
  };

  const overdueCount = tasks.filter(t => isPast(new Date(t.dueDate)) && !t.isCompleted).length;
  const todayCount = tasks.filter(t => isToday(new Date(t.dueDate)) && !t.isCompleted).length;

  return (
    <div className="space-y-4">
      {/* Quick Add Bar */}
      <form onSubmit={handleQuickAdd} className="flex gap-2">
        <input
          type="text"
          value={quickAddText}
          onChange={(e) => setQuickAddText(e.target.value)}
          placeholder='Try: "call supplier every Monday at 9am"'
          className="flex-1 px-4 py-3 rounded-lg border border-gray-200 dark:border-gray-700 bg-white dark:bg-gray-800 text-gray-900 dark:text-white placeholder-gray-400 focus:outline-none focus:ring-2 focus:ring-blue-500"
        />
        <button
          type="submit"
          className="px-4 py-3 bg-blue-600 text-white rounded-lg hover:bg-blue-700 transition-colors"
        >
          <svg className="w-5 h-5" fill="none" stroke="currentColor" viewBox="0 0 24 24">
            <path strokeLinecap="round" strokeLinejoin="round" strokeWidth={2} d="M12 4v16m8-8H4" />
          </svg>
        </button>
      </form>

      {/* Filter Tabs */}
      <div className="flex gap-2 overflow-x-auto pb-2">
        {[
          { id: 'all', label: 'All' },
          { id: 'overdue', label: `Overdue${overdueCount > 0 ? ` (${overdueCount})` : ''}`, danger: true },
          { id: 'today', label: `Today${todayCount > 0 ? ` (${todayCount})` : ''}` },
          { id: 'upcoming', label: 'Upcoming' },
        ].map((tab) => (
          <button
            key={tab.id}
            onClick={() => setFilter(tab.id as typeof filter)}
            className={`px-4 py-2 rounded-full text-sm font-medium whitespace-nowrap transition-colors ${
              filter === tab.id
                ? tab.danger && overdueCount > 0
                  ? 'bg-red-100 dark:bg-red-900/30 text-red-700 dark:text-red-400'
                  : 'bg-blue-100 dark:bg-blue-900/30 text-blue-700 dark:text-blue-400'
                : 'bg-gray-100 dark:bg-gray-800 text-gray-600 dark:text-gray-400 hover:bg-gray-200 dark:hover:bg-gray-700'
            }`}
          >
            {tab.label}
          </button>
        ))}
      </div>

      {/* Task List */}
      {filteredTasks.length === 0 ? (
        <div className="text-center py-12">
          <svg className="w-16 h-16 mx-auto text-gray-300 dark:text-gray-600 mb-4" fill="none" stroke="currentColor" viewBox="0 0 24 24">
            <path strokeLinecap="round" strokeLinejoin="round" strokeWidth={1.5} d="M9 5H7a2 2 0 00-2 2v12a2 2 0 002 2h10a2 2 0 002-2V7a2 2 0 00-2-2h-2M9 5a2 2 0 002 2h2a2 2 0 002-2M9 5a2 2 0 012-2h2a2 2 0 012 2m-6 9l2 2 4-4" />
          </svg>
          <p className="text-gray-500 dark:text-gray-400">No tasks yet</p>
          <p className="text-sm text-gray-400 dark:text-gray-500">Add a task above to get started</p>
        </div>
      ) : (
        <div className="space-y-2">
          {filteredTasks.map((task) => (
            <TaskRow
              key={task.id}
              task={task}
              onToggleComplete={() => toggleComplete(task.id)}
              onSnooze={(minutes) => snoozeTask(task.id, minutes)}
              onDelete={() => deleteTask(task.id)}
              onEdit={() => setEditingTask(task)}
            />
          ))}
        </div>
      )}
    </div>
  );
}

// Task Row Component
interface TaskRowProps {
  task: Task;
  onToggleComplete: () => void;
  onSnooze: (minutes: number) => void;
  onDelete: () => void;
  onEdit: () => void;
}

function TaskRow({ task, onToggleComplete, onSnooze, onDelete, onEdit }: TaskRowProps) {
  const [showSnoozeMenu, setShowSnoozeMenu] = useState(false);

  const dueDate = new Date(task.dueDate);
  const isOverdue = isPast(dueDate) && !task.isCompleted;
  const isDueToday = isToday(dueDate);

  const nagLevelColors = {
    gentle: 'bg-green-500',
    moderate: 'bg-yellow-500',
    relentless: 'bg-red-500',
  };

  const snoozeOptions = [
    { label: '1 min', minutes: 1 },
    { label: '5 min', minutes: 5 },
    { label: '15 min', minutes: 15 },
    { label: '30 min', minutes: 30 },
    { label: '1 hour', minutes: 60 },
  ];

  return (
    <div className={`task-row bg-white dark:bg-gray-800 rounded-lg border ${
      isOverdue ? 'border-red-200 dark:border-red-900' : 'border-gray-200 dark:border-gray-700'
    } p-4`}>
      <div className="flex items-start gap-3">
        {/* Checkbox */}
        <button
          onClick={onToggleComplete}
          className={`mt-1 w-5 h-5 rounded-full border-2 flex items-center justify-center transition-colors ${
            task.isCompleted
              ? 'bg-green-500 border-green-500 text-white'
              : 'border-gray-300 dark:border-gray-600 hover:border-blue-500'
          }`}
        >
          {task.isCompleted && (
            <svg className="w-3 h-3" fill="currentColor" viewBox="0 0 20 20">
              <path fillRule="evenodd" d="M16.707 5.293a1 1 0 010 1.414l-8 8a1 1 0 01-1.414 0l-4-4a1 1 0 011.414-1.414L8 12.586l7.293-7.293a1 1 0 011.414 0z" clipRule="evenodd" />
            </svg>
          )}
        </button>

        {/* Content */}
        <div className="flex-1 min-w-0">
          <div className="flex items-center gap-2">
            <p className={`font-medium ${task.isCompleted ? 'line-through text-gray-400' : 'text-gray-900 dark:text-white'}`}>
              {task.title}
            </p>
            {/* Nag level indicator */}
            <div className="flex gap-0.5">
              {[...Array(task.nagLevel === 'gentle' ? 1 : task.nagLevel === 'moderate' ? 2 : 3)].map((_, i) => (
                <div key={i} className={`w-1 h-3 rounded-sm ${nagLevelColors[task.nagLevel]}`} />
              ))}
            </div>
          </div>

          <div className="flex items-center gap-3 mt-1 text-sm">
            {/* Due date */}
            <span className={`flex items-center gap-1 ${
              isOverdue ? 'text-red-600 dark:text-red-400' :
              isDueToday ? 'text-orange-600 dark:text-orange-400' :
              'text-gray-500 dark:text-gray-400'
            }`}>
              {isOverdue && (
                <svg className="w-4 h-4" fill="currentColor" viewBox="0 0 20 20">
                  <path fillRule="evenodd" d="M8.257 3.099c.765-1.36 2.722-1.36 3.486 0l5.58 9.92c.75 1.334-.213 2.98-1.742 2.98H4.42c-1.53 0-2.493-1.646-1.743-2.98l5.58-9.92zM11 13a1 1 0 11-2 0 1 1 0 012 0zm-1-8a1 1 0 00-1 1v3a1 1 0 002 0V6a1 1 0 00-1-1z" clipRule="evenodd" />
                </svg>
              )}
              {formatDistanceToNow(dueDate, { addSuffix: true })}
            </span>

            {/* Recurrence indicator */}
            {task.recurrenceType && (
              <span className="flex items-center gap-1 text-gray-400">
                <svg className="w-4 h-4" fill="none" stroke="currentColor" viewBox="0 0 24 24">
                  <path strokeLinecap="round" strokeLinejoin="round" strokeWidth={2} d="M4 4v5h.582m15.356 2A8.001 8.001 0 004.582 9m0 0H9m11 11v-5h-.581m0 0a8.003 8.003 0 01-15.357-2m15.357 2H15" />
                </svg>
                {task.recurrenceType}
              </span>
            )}

            {/* Snooze count */}
            {task.snoozeCount > 0 && (
              <span className="text-gray-400">
                Reminder #{task.snoozeCount + 1}
              </span>
            )}
          </div>
        </div>

        {/* Actions */}
        {!task.isCompleted && (
          <div className="relative">
            <button
              onClick={() => setShowSnoozeMenu(!showSnoozeMenu)}
              className="p-2 text-gray-400 hover:text-gray-600 dark:hover:text-gray-300 rounded-lg hover:bg-gray-100 dark:hover:bg-gray-700"
            >
              <svg className="w-5 h-5" fill="none" stroke="currentColor" viewBox="0 0 24 24">
                <path strokeLinecap="round" strokeLinejoin="round" strokeWidth={2} d="M12 8v4l3 3m6-3a9 9 0 11-18 0 9 9 0 0118 0z" />
              </svg>
            </button>

            {showSnoozeMenu && (
              <div className="absolute right-0 top-full mt-1 bg-white dark:bg-gray-800 border border-gray-200 dark:border-gray-700 rounded-lg shadow-lg py-1 z-10 min-w-[120px]">
                {snoozeOptions.map((option) => (
                  <button
                    key={option.minutes}
                    onClick={() => {
                      onSnooze(option.minutes);
                      setShowSnoozeMenu(false);
                    }}
                    className="w-full px-4 py-2 text-left text-sm hover:bg-gray-100 dark:hover:bg-gray-700"
                  >
                    {option.label}
                  </button>
                ))}
              </div>
            )}
          </div>
        )}

        <button
          onClick={onDelete}
          className="p-2 text-gray-400 hover:text-red-600 dark:hover:text-red-400 rounded-lg hover:bg-gray-100 dark:hover:bg-gray-700"
        >
          <svg className="w-5 h-5" fill="none" stroke="currentColor" viewBox="0 0 24 24">
            <path strokeLinecap="round" strokeLinejoin="round" strokeWidth={2} d="M19 7l-.867 12.142A2 2 0 0116.138 21H7.862a2 2 0 01-1.995-1.858L5 7m5 4v6m4-6v6m1-10V4a1 1 0 00-1-1h-4a1 1 0 00-1 1v3M4 7h16" />
          </svg>
        </button>
      </div>
    </div>
  );
}
