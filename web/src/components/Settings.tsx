'use client';

import { useState, useEffect } from 'react';
import { Settings as SettingsType, Theme, NagLevel, SnoozeInterval, AlertSound, Bucket } from '@/types';
import { getSettings, saveSettings, defaultSettings } from '@/lib/storage';
import { requestNotificationPermission, isNotificationSupported } from '@/lib/notifications';
import BucketManager from './BucketManager';

interface SettingsProps {
  onThemeChange: (theme: Theme) => void;
  buckets: Bucket[];
  setBuckets: (buckets: Bucket[]) => void;
}

export default function Settings({ onThemeChange, buckets, setBuckets }: SettingsProps) {
  const [settings, setSettings] = useState<SettingsType>(defaultSettings);
  const [notificationPermission, setNotificationPermission] = useState<NotificationPermission>('default');

  useEffect(() => {
    setSettings(getSettings());
    if (isNotificationSupported()) {
      setNotificationPermission(Notification.permission);
    }
  }, []);

  const updateSetting = <K extends keyof SettingsType>(key: K, value: SettingsType[K]) => {
    const updated = { ...settings, [key]: value };
    setSettings(updated);
    saveSettings(updated);

    if (key === 'theme') {
      onThemeChange(value as Theme);
    }
  };

  const handleRequestNotifications = async () => {
    const granted = await requestNotificationPermission();
    setNotificationPermission(granted ? 'granted' : 'denied');
  };

  const resetToDefaults = () => {
    setSettings(defaultSettings);
    saveSettings(defaultSettings);
    onThemeChange(defaultSettings.theme);
  };

  return (
    <div className="space-y-6">
      {/* Appearance Section */}
      <section className="bg-white dark:bg-gray-800 rounded-xl border border-gray-200 dark:border-gray-700 overflow-hidden">
        <h2 className="px-4 py-3 text-sm font-medium text-gray-500 dark:text-gray-400 uppercase tracking-wide bg-gray-50 dark:bg-gray-900/50">
          Appearance
        </h2>
        <div className="divide-y divide-gray-200 dark:divide-gray-700">
          <div className="px-4 py-4 flex items-center justify-between">
            <label className="text-gray-900 dark:text-white">Theme</label>
            <select
              value={settings.theme}
              onChange={(e) => updateSetting('theme', e.target.value as Theme)}
              className="px-3 py-2 bg-gray-100 dark:bg-gray-700 border-0 rounded-lg text-gray-900 dark:text-white focus:ring-2 focus:ring-blue-500"
            >
              <option value="system">System</option>
              <option value="light">Light</option>
              <option value="dark">Dark</option>
            </select>
          </div>
        </div>
      </section>

      {/* Notification Defaults Section */}
      <section className="bg-white dark:bg-gray-800 rounded-xl border border-gray-200 dark:border-gray-700 overflow-hidden">
        <h2 className="px-4 py-3 text-sm font-medium text-gray-500 dark:text-gray-400 uppercase tracking-wide bg-gray-50 dark:bg-gray-900/50">
          Notification Defaults
        </h2>
        <div className="divide-y divide-gray-200 dark:divide-gray-700">
          {/* Notification Permission */}
          {isNotificationSupported() && (
            <div className="px-4 py-4 flex items-center justify-between">
              <div>
                <label className="text-gray-900 dark:text-white">Browser Notifications</label>
                <p className="text-sm text-gray-500">
                  {notificationPermission === 'granted' ? 'Enabled' :
                   notificationPermission === 'denied' ? 'Blocked in browser settings' : 'Not yet requested'}
                </p>
              </div>
              {notificationPermission !== 'granted' && notificationPermission !== 'denied' && (
                <button
                  onClick={handleRequestNotifications}
                  className="px-4 py-2 bg-blue-600 text-white rounded-lg hover:bg-blue-700"
                >
                  Enable
                </button>
              )}
              {notificationPermission === 'granted' && (
                <span className="px-3 py-1 bg-green-100 dark:bg-green-900/30 text-green-700 dark:text-green-400 rounded-full text-sm">
                  Enabled
                </span>
              )}
            </div>
          )}

          {/* Default Nag Level */}
          <div className="px-4 py-4 flex items-center justify-between">
            <label className="text-gray-900 dark:text-white">Default Nag Level</label>
            <select
              value={settings.defaultNagLevel}
              onChange={(e) => updateSetting('defaultNagLevel', e.target.value as NagLevel)}
              className="px-3 py-2 bg-gray-100 dark:bg-gray-700 border-0 rounded-lg text-gray-900 dark:text-white focus:ring-2 focus:ring-blue-500"
            >
              <option value="gentle">Gentle</option>
              <option value="moderate">Moderate</option>
              <option value="relentless">Relentless</option>
            </select>
          </div>

          {/* Default Snooze Interval */}
          <div className="px-4 py-4 flex items-center justify-between">
            <label className="text-gray-900 dark:text-white">Default Snooze</label>
            <select
              value={settings.defaultSnoozeInterval}
              onChange={(e) => updateSetting('defaultSnoozeInterval', Number(e.target.value) as SnoozeInterval)}
              className="px-3 py-2 bg-gray-100 dark:bg-gray-700 border-0 rounded-lg text-gray-900 dark:text-white focus:ring-2 focus:ring-blue-500"
            >
              <option value={1}>1 minute</option>
              <option value={5}>5 minutes</option>
              <option value={15}>15 minutes</option>
              <option value={30}>30 minutes</option>
              <option value={60}>1 hour</option>
            </select>
          </div>

          {/* Escalating Notifications */}
          <div className="px-4 py-4 flex items-center justify-between">
            <div>
              <label className="text-gray-900 dark:text-white">Escalating Notifications</label>
              <p className="text-sm text-gray-500">Increase frequency when ignored</p>
            </div>
            <button
              onClick={() => updateSetting('escalatingNotificationsEnabled', !settings.escalatingNotificationsEnabled)}
              className={`relative inline-flex h-6 w-11 items-center rounded-full transition-colors ${
                settings.escalatingNotificationsEnabled ? 'bg-blue-600' : 'bg-gray-300 dark:bg-gray-600'
              }`}
            >
              <span
                className={`inline-block h-4 w-4 transform rounded-full bg-white transition-transform ${
                  settings.escalatingNotificationsEnabled ? 'translate-x-6' : 'translate-x-1'
                }`}
              />
            </button>
          </div>

          {/* Alert Sound */}
          <div className="px-4 py-4 flex items-center justify-between">
            <label className="text-gray-900 dark:text-white">Alert Sound</label>
            <select
              value={settings.defaultAlertSound}
              onChange={(e) => updateSetting('defaultAlertSound', e.target.value as AlertSound)}
              className="px-3 py-2 bg-gray-100 dark:bg-gray-700 border-0 rounded-lg text-gray-900 dark:text-white focus:ring-2 focus:ring-blue-500"
            >
              <option value="default">Default</option>
              <option value="bell">Bell</option>
              <option value="chime">Chime</option>
              <option value="alarm">Alarm</option>
              <option value="loud">Loud</option>
            </select>
          </div>
        </div>
      </section>

      {/* Quiet Hours Section */}
      <section className="bg-white dark:bg-gray-800 rounded-xl border border-gray-200 dark:border-gray-700 overflow-hidden">
        <h2 className="px-4 py-3 text-sm font-medium text-gray-500 dark:text-gray-400 uppercase tracking-wide bg-gray-50 dark:bg-gray-900/50">
          Quiet Hours
        </h2>
        <div className="divide-y divide-gray-200 dark:divide-gray-700">
          <div className="px-4 py-4 flex items-center justify-between">
            <div>
              <label className="text-gray-900 dark:text-white">Enable Quiet Hours</label>
              <p className="text-sm text-gray-500">Pause notifications during set times</p>
            </div>
            <button
              onClick={() => updateSetting('quietHoursEnabled', !settings.quietHoursEnabled)}
              className={`relative inline-flex h-6 w-11 items-center rounded-full transition-colors ${
                settings.quietHoursEnabled ? 'bg-blue-600' : 'bg-gray-300 dark:bg-gray-600'
              }`}
            >
              <span
                className={`inline-block h-4 w-4 transform rounded-full bg-white transition-transform ${
                  settings.quietHoursEnabled ? 'translate-x-6' : 'translate-x-1'
                }`}
              />
            </button>
          </div>

          {settings.quietHoursEnabled && (
            <>
              <div className="px-4 py-4 flex items-center justify-between">
                <label className="text-gray-900 dark:text-white">Start Time</label>
                <input
                  type="time"
                  value={settings.quietHoursStart}
                  onChange={(e) => updateSetting('quietHoursStart', e.target.value)}
                  className="px-3 py-2 bg-gray-100 dark:bg-gray-700 border-0 rounded-lg text-gray-900 dark:text-white focus:ring-2 focus:ring-blue-500"
                />
              </div>
              <div className="px-4 py-4 flex items-center justify-between">
                <label className="text-gray-900 dark:text-white">End Time</label>
                <input
                  type="time"
                  value={settings.quietHoursEnd}
                  onChange={(e) => updateSetting('quietHoursEnd', e.target.value)}
                  className="px-3 py-2 bg-gray-100 dark:bg-gray-700 border-0 rounded-lg text-gray-900 dark:text-white focus:ring-2 focus:ring-blue-500"
                />
              </div>
            </>
          )}
        </div>
      </section>

      {/* Display Section */}
      <section className="bg-white dark:bg-gray-800 rounded-xl border border-gray-200 dark:border-gray-700 overflow-hidden">
        <h2 className="px-4 py-3 text-sm font-medium text-gray-500 dark:text-gray-400 uppercase tracking-wide bg-gray-50 dark:bg-gray-900/50">
          Display
        </h2>
        <div className="divide-y divide-gray-200 dark:divide-gray-700">
          <div className="px-4 py-4 flex items-center justify-between">
            <label className="text-gray-900 dark:text-white">Show Completed Tasks</label>
            <button
              onClick={() => updateSetting('showCompletedTasks', !settings.showCompletedTasks)}
              className={`relative inline-flex h-6 w-11 items-center rounded-full transition-colors ${
                settings.showCompletedTasks ? 'bg-blue-600' : 'bg-gray-300 dark:bg-gray-600'
              }`}
            >
              <span
                className={`inline-block h-4 w-4 transform rounded-full bg-white transition-transform ${
                  settings.showCompletedTasks ? 'translate-x-6' : 'translate-x-1'
                }`}
              />
            </button>
          </div>
        </div>
      </section>

      {/* Buckets Section */}
      <section className="bg-white dark:bg-gray-800 rounded-xl border border-gray-200 dark:border-gray-700 overflow-hidden">
        <h2 className="px-4 py-3 text-sm font-medium text-gray-500 dark:text-gray-400 uppercase tracking-wide bg-gray-50 dark:bg-gray-900/50">
          Buckets
        </h2>
        <BucketManager buckets={buckets} setBuckets={setBuckets} />
      </section>

      {/* About Section */}
      <section className="bg-white dark:bg-gray-800 rounded-xl border border-gray-200 dark:border-gray-700 overflow-hidden">
        <h2 className="px-4 py-3 text-sm font-medium text-gray-500 dark:text-gray-400 uppercase tracking-wide bg-gray-50 dark:bg-gray-900/50">
          About
        </h2>
        <div className="px-4 py-4">
          <p className="text-gray-900 dark:text-white font-medium">Contractor Must Do</p>
          <p className="text-sm text-gray-500 italic mb-4">&quot;It won&apos;t shut up until you do the work.&quot;</p>
          <p className="text-sm text-gray-500">Version 1.0.0</p>
        </div>
      </section>

      {/* Reset Button */}
      <button
        onClick={resetToDefaults}
        className="w-full py-3 text-red-600 dark:text-red-400 font-medium rounded-xl border border-red-200 dark:border-red-900 hover:bg-red-50 dark:hover:bg-red-900/20"
      >
        Reset to Defaults
      </button>
    </div>
  );
}
