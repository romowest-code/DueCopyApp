'use client';

import { useState } from 'react';
import { v4 as uuidv4 } from 'uuid';
import { Task, NagLevel, SnoozeInterval, RecurrenceType, Bucket } from '@/types';
import { saveTasks, getSettings } from '@/lib/storage';
import { parseNaturalLanguage } from '@/lib/parser';
import { notificationScheduler } from '@/lib/notifications';
import { formatDistanceToNow, format, isPast, isToday } from 'date-fns';

interface TaskListProps {
  tasks: Task[];
  setTasks: (tasks: Task[]) => void;
  buckets: Bucket[];
}

export default function TaskList({ tasks, setTasks, buckets }: TaskListProps) {
  const [quickAddText, setQuickAddText] = useState('');
  const [filter, setFilter] = useState<'all' | 'overdue' | 'today' | 'upcoming'>('all');
  const [expandedBuckets, setExpandedBuckets] = useState<Set<string>>(new Set(['general', ...buckets.map(b => b.id)]));
  const [addingToBucket, setAddingToBucket] = useState<string | null>(null);
  const [showImportModal, setShowImportModal] = useState(false);
  const [importText, setImportText] = useState('');
  const [importBucketId, setImportBucketId] = useState<string | null>(null);

  const settings = getSettings();

  // Get tomorrow at 9 AM local time
  const getTomorrowAt9AM = (): Date => {
    const tomorrow = new Date();
    tomorrow.setDate(tomorrow.getDate() + 1);
    tomorrow.setHours(9, 0, 0, 0);
    return tomorrow;
  };

  // Import multiple tasks from text (one per line)
  const handleImport = () => {
    const lines = importText.split('\n').filter(line => line.trim());
    if (lines.length === 0) return;

    const defaultDueDate = getTomorrowAt9AM();
    const newTasks: Task[] = lines.map(line => createTask(
      line.trim(),
      defaultDueDate,
      null,
      [],
      1,
      importBucketId
    ));

    const updatedTasks = [...tasks, ...newTasks];
    setTasks(updatedTasks);
    saveTasks(updatedTasks);
    setImportText('');
    setImportBucketId(null);
    setShowImportModal(false);
  };

  // Filter tasks by date filter only
  const getFilteredTasks = (bucketTasks: Task[]) => {
    return bucketTasks.filter(task => {
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
  };

  // Group tasks by bucket
  const generalTasks = tasks.filter(t => !t.bucketId);
  const tasksByBucket = buckets.map(bucket => ({
    bucket,
    tasks: tasks.filter(t => t.bucketId === bucket.id),
  }));

  const handleQuickAdd = (e: React.FormEvent, bucketId: string | null = null) => {
    e.preventDefault();
    if (!quickAddText.trim()) return;

    const parsed = parseNaturalLanguage(quickAddText);
    const newTask = createTask(
      parsed.title || quickAddText,
      parsed.dueDate || new Date(Date.now() + 3600000),
      parsed.recurrence?.type || null,
      parsed.recurrence?.days || [],
      parsed.recurrence?.interval || 1,
      bucketId
    );

    const updatedTasks = [...tasks, newTask];
    setTasks(updatedTasks);
    saveTasks(updatedTasks);
    setQuickAddText('');
    setAddingToBucket(null);
  };

  const createTask = (
    title: string,
    dueDate: Date,
    recurrenceType: RecurrenceType | null = null,
    recurrenceDays: number[] = [],
    recurrenceInterval: number = 1,
    bucketId: string | null = null
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
      bucketId,
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

  const changeTaskBucket = (taskId: string, bucketId: string | null) => {
    const updatedTasks = tasks.map(task =>
      task.id === taskId ? { ...task, bucketId } : task
    );
    setTasks(updatedTasks);
    saveTasks(updatedTasks);
  };

  const toggleBucketExpanded = (bucketId: string) => {
    const newExpanded = new Set(expandedBuckets);
    if (newExpanded.has(bucketId)) {
      newExpanded.delete(bucketId);
    } else {
      newExpanded.add(bucketId);
    }
    setExpandedBuckets(newExpanded);
  };

  const overdueCount = tasks.filter(t => isPast(new Date(t.dueDate)) && !t.isCompleted).length;
  const todayCount = tasks.filter(t => isToday(new Date(t.dueDate)) && !t.isCompleted).length;

  const renderBucketAccordion = (
    bucketId: string,
    name: string,
    color: string | null,
    bucketTasks: Task[]
  ) => {
    const filteredTasks = getFilteredTasks(bucketTasks);
    const isExpanded = expandedBuckets.has(bucketId);
    const taskCount = filteredTasks.filter(t => !t.isCompleted).length;

    return (
      <div key={bucketId} className="bg-white dark:bg-gray-800 rounded-xl border border-gray-200 dark:border-gray-700 overflow-hidden">
        {/* Accordion Header */}
        <button
          onClick={() => toggleBucketExpanded(bucketId)}
          className="w-full px-4 py-3 flex items-center justify-between hover:bg-gray-50 dark:hover:bg-gray-700/50 transition-colors"
        >
          <div className="flex items-center gap-3">
            {color && (
              <span
                className="w-3 h-3 rounded-full"
                style={{ backgroundColor: color }}
              />
            )}
            <span className="font-medium text-gray-900 dark:text-white">{name}</span>
            {taskCount > 0 && (
              <span className="px-2 py-0.5 text-xs rounded-full bg-gray-100 dark:bg-gray-700 text-gray-600 dark:text-gray-400">
                {taskCount}
              </span>
            )}
          </div>
          <svg
            className={`w-5 h-5 text-gray-400 transition-transform ${isExpanded ? 'rotate-180' : ''}`}
            fill="none"
            stroke="currentColor"
            viewBox="0 0 24 24"
          >
            <path strokeLinecap="round" strokeLinejoin="round" strokeWidth={2} d="M19 9l-7 7-7-7" />
          </svg>
        </button>

        {/* Accordion Content */}
        {isExpanded && (
          <div className="border-t border-gray-200 dark:border-gray-700">
            {filteredTasks.length === 0 ? (
              <div className="px-4 py-6 text-center text-gray-400 dark:text-gray-500 text-sm">
                No tasks in this bucket
              </div>
            ) : (
              <div className="divide-y divide-gray-100 dark:divide-gray-700/50">
                {filteredTasks.map((task) => (
                  <TaskRow
                    key={task.id}
                    task={task}
                    buckets={buckets}
                    onToggleComplete={() => toggleComplete(task.id)}
                    onSnooze={(minutes) => snoozeTask(task.id, minutes)}
                    onDelete={() => deleteTask(task.id)}
                    onChangeBucket={(newBucketId) => changeTaskBucket(task.id, newBucketId)}
                  />
                ))}
              </div>
            )}

            {/* Add task to this bucket */}
            {addingToBucket === bucketId ? (
              <form onSubmit={(e) => handleQuickAdd(e, bucketId === 'general' ? null : bucketId)} className="p-3 border-t border-gray-200 dark:border-gray-700">
                <div className="flex gap-2">
                  <input
                    type="text"
                    value={quickAddText}
                    onChange={(e) => setQuickAddText(e.target.value)}
                    placeholder="Add a task..."
                    className="flex-1 px-3 py-2 text-sm rounded-lg border border-gray-200 dark:border-gray-600 bg-gray-50 dark:bg-gray-700 text-gray-900 dark:text-white placeholder-gray-400 focus:outline-none focus:ring-2 focus:ring-blue-500"
                    autoFocus
                  />
                  <button
                    type="submit"
                    className="px-3 py-2 bg-blue-600 text-white text-sm rounded-lg hover:bg-blue-700"
                  >
                    Add
                  </button>
                  <button
                    type="button"
                    onClick={() => {
                      setAddingToBucket(null);
                      setQuickAddText('');
                    }}
                    className="px-3 py-2 text-gray-500 text-sm rounded-lg hover:bg-gray-100 dark:hover:bg-gray-700"
                  >
                    Cancel
                  </button>
                </div>
              </form>
            ) : (
              <button
                onClick={() => setAddingToBucket(bucketId)}
                className="w-full px-4 py-2 text-left text-sm text-blue-600 dark:text-blue-400 hover:bg-gray-50 dark:hover:bg-gray-700/50 border-t border-gray-200 dark:border-gray-700 flex items-center gap-2"
              >
                <svg className="w-4 h-4" fill="none" stroke="currentColor" viewBox="0 0 24 24">
                  <path strokeLinecap="round" strokeLinejoin="round" strokeWidth={2} d="M12 4v16m8-8H4" />
                </svg>
                Add task
              </button>
            )}
          </div>
        )}
      </div>
    );
  };

  return (
    <div className="space-y-4">
      {/* Filter Tabs and Import Button */}
      <div className="flex items-center justify-between gap-2">
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
        <button
          onClick={() => setShowImportModal(true)}
          className="flex items-center gap-1.5 px-3 py-2 text-sm font-medium text-gray-600 dark:text-gray-400 hover:text-gray-900 dark:hover:text-white hover:bg-gray-100 dark:hover:bg-gray-700 rounded-lg transition-colors whitespace-nowrap"
        >
          <svg className="w-4 h-4" fill="none" stroke="currentColor" viewBox="0 0 24 24">
            <path strokeLinecap="round" strokeLinejoin="round" strokeWidth={2} d="M4 16v1a3 3 0 003 3h10a3 3 0 003-3v-1m-4-8l-4-4m0 0L8 8m4-4v12" />
          </svg>
          Import
        </button>
      </div>

      {/* Bucket Accordions */}
      <div className="space-y-3">
        {/* General bucket */}
        {renderBucketAccordion('general', 'General', null, generalTasks)}

        {/* User buckets */}
        {tasksByBucket.map(({ bucket, tasks: bucketTasks }) =>
          renderBucketAccordion(bucket.id, bucket.name, bucket.color, bucketTasks)
        )}
      </div>

      {/* Empty state when no buckets and no tasks */}
      {tasks.length === 0 && buckets.length === 0 && (
        <div className="text-center py-12">
          <svg className="w-16 h-16 mx-auto text-gray-300 dark:text-gray-600 mb-4" fill="none" stroke="currentColor" viewBox="0 0 24 24">
            <path strokeLinecap="round" strokeLinejoin="round" strokeWidth={1.5} d="M9 5H7a2 2 0 00-2 2v12a2 2 0 002 2h10a2 2 0 002-2V7a2 2 0 00-2-2h-2M9 5a2 2 0 002 2h2a2 2 0 002-2M9 5a2 2 0 012-2h2a2 2 0 012 2m-6 9l2 2 4-4" />
          </svg>
          <p className="text-gray-500 dark:text-gray-400">No tasks yet</p>
          <p className="text-sm text-gray-400 dark:text-gray-500">Add a task to get started</p>
        </div>
      )}

      {/* Import Modal */}
      {showImportModal && (
        <div className="fixed inset-0 bg-black/50 flex items-center justify-center z-50 p-4">
          <div className="bg-white dark:bg-gray-800 rounded-xl shadow-xl w-full max-w-lg max-h-[90vh] overflow-hidden">
            {/* Modal Header */}
            <div className="px-4 py-3 border-b border-gray-200 dark:border-gray-700 flex items-center justify-between">
              <h2 className="text-lg font-semibold text-gray-900 dark:text-white">Import Tasks</h2>
              <button
                onClick={() => {
                  setShowImportModal(false);
                  setImportText('');
                  setImportBucketId(null);
                }}
                className="p-1 text-gray-400 hover:text-gray-600 dark:hover:text-gray-300 rounded"
              >
                <svg className="w-5 h-5" fill="none" stroke="currentColor" viewBox="0 0 24 24">
                  <path strokeLinecap="round" strokeLinejoin="round" strokeWidth={2} d="M6 18L18 6M6 6l12 12" />
                </svg>
              </button>
            </div>

            {/* Modal Body */}
            <div className="p-4 space-y-4">
              <div>
                <label className="block text-sm font-medium text-gray-700 dark:text-gray-300 mb-1">
                  Paste tasks (one per line)
                </label>
                <textarea
                  value={importText}
                  onChange={(e) => setImportText(e.target.value)}
                  placeholder="Buy lumber&#10;Call electrician&#10;Schedule inspection&#10;Order fixtures"
                  rows={8}
                  className="w-full px-3 py-2 border border-gray-200 dark:border-gray-600 rounded-lg bg-gray-50 dark:bg-gray-700 text-gray-900 dark:text-white placeholder-gray-400 focus:outline-none focus:ring-2 focus:ring-blue-500 resize-none"
                  autoFocus
                />
                <p className="mt-1 text-xs text-gray-500 dark:text-gray-400">
                  {importText.split('\n').filter(l => l.trim()).length} task(s) to import
                </p>
              </div>

              <div>
                <label className="block text-sm font-medium text-gray-700 dark:text-gray-300 mb-1">
                  Add to bucket
                </label>
                <select
                  value={importBucketId || 'general'}
                  onChange={(e) => setImportBucketId(e.target.value === 'general' ? null : e.target.value)}
                  className="w-full px-3 py-2 border border-gray-200 dark:border-gray-600 rounded-lg bg-gray-50 dark:bg-gray-700 text-gray-900 dark:text-white focus:outline-none focus:ring-2 focus:ring-blue-500"
                >
                  <option value="general">General</option>
                  {buckets.map((bucket) => (
                    <option key={bucket.id} value={bucket.id}>
                      {bucket.name}
                    </option>
                  ))}
                </select>
              </div>

              <div className="bg-blue-50 dark:bg-blue-900/20 rounded-lg p-3">
                <p className="text-sm text-blue-700 dark:text-blue-400">
                  All imported tasks will be due tomorrow at 9:00 AM
                </p>
              </div>
            </div>

            {/* Modal Footer */}
            <div className="px-4 py-3 border-t border-gray-200 dark:border-gray-700 flex justify-end gap-2">
              <button
                onClick={() => {
                  setShowImportModal(false);
                  setImportText('');
                  setImportBucketId(null);
                }}
                className="px-4 py-2 text-sm font-medium text-gray-600 dark:text-gray-400 hover:bg-gray-100 dark:hover:bg-gray-700 rounded-lg"
              >
                Cancel
              </button>
              <button
                onClick={handleImport}
                disabled={!importText.trim()}
                className="px-4 py-2 text-sm font-medium bg-blue-600 text-white rounded-lg hover:bg-blue-700 disabled:opacity-50 disabled:cursor-not-allowed"
              >
                Import {importText.split('\n').filter(l => l.trim()).length} Task(s)
              </button>
            </div>
          </div>
        </div>
      )}
    </div>
  );
}

// Task Row Component
interface TaskRowProps {
  task: Task;
  buckets: Bucket[];
  onToggleComplete: () => void;
  onSnooze: (minutes: number) => void;
  onDelete: () => void;
  onChangeBucket: (bucketId: string | null) => void;
}

function TaskRow({ task, buckets, onToggleComplete, onSnooze, onDelete, onChangeBucket }: TaskRowProps) {
  const [showSnoozeMenu, setShowSnoozeMenu] = useState(false);
  const [showBucketMenu, setShowBucketMenu] = useState(false);

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
    <div className={`px-4 py-3 ${isOverdue ? 'bg-red-50 dark:bg-red-900/10' : ''}`}>
      <div className="flex items-start gap-3">
        {/* Checkbox */}
        <button
          onClick={onToggleComplete}
          className={`mt-0.5 w-5 h-5 rounded-full border-2 flex items-center justify-center transition-colors flex-shrink-0 ${
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
          <div className="flex items-center gap-2 flex-wrap">
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
                    className="w-full px-4 py-2 text-left text-sm hover:bg-gray-100 dark:hover:bg-gray-700 text-gray-700 dark:text-gray-300"
                  >
                    {option.label}
                  </button>
                ))}
              </div>
            )}
          </div>
        )}

        {/* Bucket selector */}
        {buckets.length > 0 && (
          <div className="relative">
            <button
              onClick={() => setShowBucketMenu(!showBucketMenu)}
              className="p-2 text-gray-400 hover:text-gray-600 dark:hover:text-gray-300 rounded-lg hover:bg-gray-100 dark:hover:bg-gray-700"
              title="Move to bucket"
            >
              <svg className="w-5 h-5" fill="none" stroke="currentColor" viewBox="0 0 24 24">
                <path strokeLinecap="round" strokeLinejoin="round" strokeWidth={2} d="M8 7h12m0 0l-4-4m4 4l-4 4m0 6H4m0 0l4 4m-4-4l4-4" />
              </svg>
            </button>

            {showBucketMenu && (
              <div className="absolute right-0 top-full mt-1 bg-white dark:bg-gray-800 border border-gray-200 dark:border-gray-700 rounded-lg shadow-lg py-1 z-10 min-w-[140px]">
                <button
                  onClick={() => {
                    onChangeBucket(null);
                    setShowBucketMenu(false);
                  }}
                  className={`w-full px-4 py-2 text-left text-sm hover:bg-gray-100 dark:hover:bg-gray-700 flex items-center gap-2 ${
                    !task.bucketId ? 'font-medium text-blue-600 dark:text-blue-400' : 'text-gray-700 dark:text-gray-300'
                  }`}
                >
                  General
                </button>
                {buckets.map((bucket) => (
                  <button
                    key={bucket.id}
                    onClick={() => {
                      onChangeBucket(bucket.id);
                      setShowBucketMenu(false);
                    }}
                    className={`w-full px-4 py-2 text-left text-sm hover:bg-gray-100 dark:hover:bg-gray-700 flex items-center gap-2 ${
                      task.bucketId === bucket.id ? 'font-medium text-blue-600 dark:text-blue-400' : 'text-gray-700 dark:text-gray-300'
                    }`}
                  >
                    <span
                      className="w-2 h-2 rounded-full"
                      style={{ backgroundColor: bucket.color }}
                    />
                    {bucket.name}
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
