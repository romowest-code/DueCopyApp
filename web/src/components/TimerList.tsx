'use client';

import { useState, useEffect } from 'react';
import { v4 as uuidv4 } from 'uuid';
import { Timer, TimerPreset } from '@/types';
import { saveTimers, getSettings } from '@/lib/storage';
import { showTimerComplete } from '@/lib/notifications';

interface TimerListProps {
  timers: Timer[];
  setTimers: (timers: Timer[]) => void;
}

const presets: TimerPreset[] = [
  { name: '15 min break', durationSeconds: 15 * 60 },
  { name: '30 min break', durationSeconds: 30 * 60 },
  { name: '1 hour focus', durationSeconds: 60 * 60 },
  { name: 'Pomodoro (25 min)', durationSeconds: 25 * 60 },
];

const quickTimers = [5, 10, 15, 30, 45, 60];

export default function TimerList({ timers, setTimers }: TimerListProps) {
  const [customMinutes, setCustomMinutes] = useState(5);
  const [customName, setCustomName] = useState('');

  // Update running timers every second
  useEffect(() => {
    const interval = setInterval(() => {
      setTimers(prevTimers => {
        let hasChanges = false;
        const updated = prevTimers.map(timer => {
          if (timer.isRunning && !timer.isPaused) {
            const elapsed = Math.floor((Date.now() - new Date(timer.startTime!).getTime()) / 1000);
            const remaining = Math.max(0, timer.durationSeconds - elapsed);

            if (remaining !== timer.remainingSeconds) {
              hasChanges = true;
              if (remaining === 0) {
                showTimerComplete(timer.name);
                return { ...timer, remainingSeconds: 0, isRunning: false };
              }
              return { ...timer, remainingSeconds: remaining };
            }
          }
          return timer;
        });

        if (hasChanges) {
          saveTimers(updated);
        }
        return hasChanges ? updated : prevTimers;
      });
    }, 1000);

    return () => clearInterval(interval);
  }, [setTimers]);

  const createTimer = (name: string, durationSeconds: number): Timer => {
    const settings = getSettings();
    return {
      id: uuidv4(),
      name,
      durationSeconds,
      remainingSeconds: durationSeconds,
      isRunning: false,
      isPaused: false,
      startTime: null,
      alertSound: settings.defaultAlertSound,
      createdDate: new Date().toISOString(),
    };
  };

  const addAndStartTimer = (name: string, durationSeconds: number) => {
    const timer = createTimer(name, durationSeconds);
    timer.isRunning = true;
    timer.startTime = new Date().toISOString();
    const updated = [...timers, timer];
    setTimers(updated);
    saveTimers(updated);
  };

  const startTimer = (timerId: string) => {
    const updated = timers.map(t => {
      if (t.id === timerId) {
        return {
          ...t,
          isRunning: true,
          isPaused: false,
          startTime: new Date(Date.now() - (t.durationSeconds - t.remainingSeconds) * 1000).toISOString(),
        };
      }
      return t;
    });
    setTimers(updated);
    saveTimers(updated);
  };

  const pauseTimer = (timerId: string) => {
    const updated = timers.map(t => {
      if (t.id === timerId) {
        return { ...t, isPaused: true, isRunning: false };
      }
      return t;
    });
    setTimers(updated);
    saveTimers(updated);
  };

  const resetTimer = (timerId: string) => {
    const updated = timers.map(t => {
      if (t.id === timerId) {
        return {
          ...t,
          remainingSeconds: t.durationSeconds,
          isRunning: false,
          isPaused: false,
          startTime: null,
        };
      }
      return t;
    });
    setTimers(updated);
    saveTimers(updated);
  };

  const deleteTimer = (timerId: string) => {
    const updated = timers.filter(t => t.id !== timerId);
    setTimers(updated);
    saveTimers(updated);
  };

  const formatTime = (seconds: number): string => {
    const h = Math.floor(seconds / 3600);
    const m = Math.floor((seconds % 3600) / 60);
    const s = seconds % 60;

    if (h > 0) {
      return `${h.toString().padStart(2, '0')}:${m.toString().padStart(2, '0')}:${s.toString().padStart(2, '0')}`;
    }
    return `${m.toString().padStart(2, '0')}:${s.toString().padStart(2, '0')}`;
  };

  const activeTimers = timers.filter(t => t.isRunning || t.isPaused);
  const savedTimers = timers.filter(t => !t.isRunning && !t.isPaused && t.remainingSeconds === t.durationSeconds);

  return (
    <div className="space-y-6">
      {/* Presets */}
      <section>
        <h2 className="text-sm font-medium text-gray-500 dark:text-gray-400 uppercase tracking-wide mb-3">
          Presets
        </h2>
        <div className="grid grid-cols-2 gap-2">
          {presets.map((preset) => (
            <button
              key={preset.name}
              onClick={() => addAndStartTimer(preset.name, preset.durationSeconds)}
              className="flex items-center justify-between p-4 bg-white dark:bg-gray-800 border border-gray-200 dark:border-gray-700 rounded-lg hover:border-blue-500 transition-colors"
            >
              <div className="text-left">
                <p className="font-medium text-gray-900 dark:text-white">{preset.name}</p>
                <p className="text-sm text-gray-500">{formatTime(preset.durationSeconds)}</p>
              </div>
              <svg className="w-5 h-5 text-blue-600" fill="currentColor" viewBox="0 0 20 20">
                <path fillRule="evenodd" d="M10 18a8 8 0 100-16 8 8 0 000 16zM9.555 7.168A1 1 0 008 8v4a1 1 0 001.555.832l3-2a1 1 0 000-1.664l-3-2z" clipRule="evenodd" />
              </svg>
            </button>
          ))}
        </div>
      </section>

      {/* Quick Timer */}
      <section>
        <h2 className="text-sm font-medium text-gray-500 dark:text-gray-400 uppercase tracking-wide mb-3">
          Quick Timer
        </h2>
        <div className="flex gap-2 overflow-x-auto pb-2">
          {quickTimers.map((minutes) => (
            <button
              key={minutes}
              onClick={() => addAndStartTimer(`${minutes} min timer`, minutes * 60)}
              className="flex-shrink-0 w-16 h-16 flex flex-col items-center justify-center bg-white dark:bg-gray-800 border border-gray-200 dark:border-gray-700 rounded-xl hover:border-blue-500 transition-colors"
            >
              <span className="text-xl font-semibold text-gray-900 dark:text-white">{minutes}</span>
              <span className="text-xs text-gray-500">min</span>
            </button>
          ))}
        </div>
      </section>

      {/* Active Timers */}
      {activeTimers.length > 0 && (
        <section>
          <h2 className="text-sm font-medium text-gray-500 dark:text-gray-400 uppercase tracking-wide mb-3">
            Active Timers
          </h2>
          <div className="space-y-3">
            {activeTimers.map((timer) => (
              <TimerCard
                key={timer.id}
                timer={timer}
                onStart={() => startTimer(timer.id)}
                onPause={() => pauseTimer(timer.id)}
                onReset={() => resetTimer(timer.id)}
                onDelete={() => deleteTimer(timer.id)}
                formatTime={formatTime}
              />
            ))}
          </div>
        </section>
      )}

      {/* Empty state */}
      {timers.length === 0 && (
        <div className="text-center py-8">
          <svg className="w-16 h-16 mx-auto text-gray-300 dark:text-gray-600 mb-4" fill="none" stroke="currentColor" viewBox="0 0 24 24">
            <path strokeLinecap="round" strokeLinejoin="round" strokeWidth={1.5} d="M12 8v4l3 3m6-3a9 9 0 11-18 0 9 9 0 0118 0z" />
          </svg>
          <p className="text-gray-500 dark:text-gray-400">No active timers</p>
          <p className="text-sm text-gray-400 dark:text-gray-500">Select a preset or quick timer to start</p>
        </div>
      )}
    </div>
  );
}

// Timer Card Component
interface TimerCardProps {
  timer: Timer;
  onStart: () => void;
  onPause: () => void;
  onReset: () => void;
  onDelete: () => void;
  formatTime: (seconds: number) => string;
}

function TimerCard({ timer, onStart, onPause, onReset, onDelete, formatTime }: TimerCardProps) {
  const progress = 1 - timer.remainingSeconds / timer.durationSeconds;
  const isComplete = timer.remainingSeconds === 0;

  return (
    <div className={`bg-white dark:bg-gray-800 border ${isComplete ? 'border-green-500' : 'border-gray-200 dark:border-gray-700'} rounded-xl p-4`}>
      <div className="flex items-center gap-4">
        {/* Progress Ring */}
        <div className="relative w-16 h-16">
          <svg className="w-16 h-16 timer-ring" viewBox="0 0 36 36">
            <circle
              className="text-gray-200 dark:text-gray-700"
              strokeWidth="3"
              stroke="currentColor"
              fill="transparent"
              r="16"
              cx="18"
              cy="18"
            />
            <circle
              className={isComplete ? 'text-green-500' : 'text-blue-500'}
              strokeWidth="3"
              strokeDasharray={`${progress * 100}, 100`}
              strokeLinecap="round"
              stroke="currentColor"
              fill="transparent"
              r="16"
              cx="18"
              cy="18"
            />
          </svg>
          <div className="absolute inset-0 flex items-center justify-center">
            <span className="text-xs font-medium text-gray-600 dark:text-gray-300">
              {Math.round(progress * 100)}%
            </span>
          </div>
        </div>

        {/* Timer Info */}
        <div className="flex-1">
          <p className="font-medium text-gray-900 dark:text-white">{timer.name}</p>
          <p className={`text-2xl font-mono font-bold ${isComplete ? 'text-green-500' : 'text-gray-900 dark:text-white'}`}>
            {formatTime(timer.remainingSeconds)}
          </p>
        </div>

        {/* Controls */}
        <div className="flex gap-2">
          {!isComplete && (
            <>
              {timer.isRunning ? (
                <button
                  onClick={onPause}
                  className="p-3 bg-orange-100 dark:bg-orange-900/30 text-orange-600 dark:text-orange-400 rounded-lg hover:bg-orange-200 dark:hover:bg-orange-900/50"
                >
                  <svg className="w-5 h-5" fill="currentColor" viewBox="0 0 20 20">
                    <path fillRule="evenodd" d="M18 10a8 8 0 11-16 0 8 8 0 0116 0zM7 8a1 1 0 012 0v4a1 1 0 11-2 0V8zm5-1a1 1 0 00-1 1v4a1 1 0 102 0V8a1 1 0 00-1-1z" clipRule="evenodd" />
                  </svg>
                </button>
              ) : (
                <button
                  onClick={onStart}
                  className="p-3 bg-blue-100 dark:bg-blue-900/30 text-blue-600 dark:text-blue-400 rounded-lg hover:bg-blue-200 dark:hover:bg-blue-900/50"
                >
                  <svg className="w-5 h-5" fill="currentColor" viewBox="0 0 20 20">
                    <path fillRule="evenodd" d="M10 18a8 8 0 100-16 8 8 0 000 16zM9.555 7.168A1 1 0 008 8v4a1 1 0 001.555.832l3-2a1 1 0 000-1.664l-3-2z" clipRule="evenodd" />
                  </svg>
                </button>
              )}
            </>
          )}

          <button
            onClick={onReset}
            className="p-3 bg-gray-100 dark:bg-gray-700 text-gray-600 dark:text-gray-300 rounded-lg hover:bg-gray-200 dark:hover:bg-gray-600"
          >
            <svg className="w-5 h-5" fill="none" stroke="currentColor" viewBox="0 0 24 24">
              <path strokeLinecap="round" strokeLinejoin="round" strokeWidth={2} d="M4 4v5h.582m15.356 2A8.001 8.001 0 004.582 9m0 0H9m11 11v-5h-.581m0 0a8.003 8.003 0 01-15.357-2m15.357 2H15" />
            </svg>
          </button>

          <button
            onClick={onDelete}
            className="p-3 bg-gray-100 dark:bg-gray-700 text-red-600 dark:text-red-400 rounded-lg hover:bg-red-100 dark:hover:bg-red-900/30"
          >
            <svg className="w-5 h-5" fill="none" stroke="currentColor" viewBox="0 0 24 24">
              <path strokeLinecap="round" strokeLinejoin="round" strokeWidth={2} d="M19 7l-.867 12.142A2 2 0 0116.138 21H7.862a2 2 0 01-1.995-1.858L5 7m5 4v6m4-6v6m1-10V4a1 1 0 00-1-1h-4a1 1 0 00-1 1v3M4 7h16" />
            </svg>
          </button>
        </div>
      </div>
    </div>
  );
}
