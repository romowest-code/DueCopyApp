'use client';

import { useState } from 'react';
import { v4 as uuidv4 } from 'uuid';
import { Bucket } from '@/types';
import { saveBuckets, deleteBucketAndReassignTasks } from '@/lib/storage';

interface BucketManagerProps {
  buckets: Bucket[];
  setBuckets: (buckets: Bucket[]) => void;
}

const PRESET_COLORS = [
  { name: 'Blue', hex: '#3B82F6' },
  { name: 'Green', hex: '#22C55E' },
  { name: 'Orange', hex: '#F97316' },
  { name: 'Purple', hex: '#A855F7' },
  { name: 'Pink', hex: '#EC4899' },
  { name: 'Teal', hex: '#14B8A6' },
  { name: 'Red', hex: '#EF4444' },
  { name: 'Yellow', hex: '#EAB308' },
];

export default function BucketManager({ buckets, setBuckets }: BucketManagerProps) {
  const [isAdding, setIsAdding] = useState(false);
  const [newBucketName, setNewBucketName] = useState('');
  const [selectedColor, setSelectedColor] = useState(PRESET_COLORS[0].hex);
  const [editingId, setEditingId] = useState<string | null>(null);
  const [editingName, setEditingName] = useState('');
  const [deleteConfirmId, setDeleteConfirmId] = useState<string | null>(null);

  const handleAddBucket = () => {
    if (!newBucketName.trim()) return;

    const newBucket: Bucket = {
      id: uuidv4(),
      name: newBucketName.trim(),
      color: selectedColor,
      createdDate: new Date().toISOString(),
    };

    const updated = [...buckets, newBucket];
    setBuckets(updated);
    saveBuckets(updated);

    setNewBucketName('');
    setSelectedColor(PRESET_COLORS[0].hex);
    setIsAdding(false);
  };

  const handleStartEdit = (bucket: Bucket) => {
    setEditingId(bucket.id);
    setEditingName(bucket.name);
  };

  const handleSaveEdit = (bucketId: string) => {
    if (!editingName.trim()) return;

    const updated = buckets.map(b =>
      b.id === bucketId ? { ...b, name: editingName.trim() } : b
    );
    setBuckets(updated);
    saveBuckets(updated);
    setEditingId(null);
    setEditingName('');
  };

  const handleDelete = (bucketId: string) => {
    deleteBucketAndReassignTasks(bucketId);
    setBuckets(buckets.filter(b => b.id !== bucketId));
    setDeleteConfirmId(null);
  };

  const handleColorChange = (bucketId: string, color: string) => {
    const updated = buckets.map(b =>
      b.id === bucketId ? { ...b, color } : b
    );
    setBuckets(updated);
    saveBuckets(updated);
  };

  return (
    <div className="divide-y divide-gray-200 dark:divide-gray-700">
      {/* Bucket List */}
      {buckets.map((bucket) => (
        <div key={bucket.id} className="px-4 py-3">
          {deleteConfirmId === bucket.id ? (
            // Delete confirmation
            <div className="flex items-center justify-between">
              <p className="text-sm text-gray-600 dark:text-gray-400">
                Delete &quot;{bucket.name}&quot;? Tasks will move to General.
              </p>
              <div className="flex gap-2">
                <button
                  onClick={() => setDeleteConfirmId(null)}
                  className="px-3 py-1 text-sm text-gray-600 dark:text-gray-400 hover:bg-gray-100 dark:hover:bg-gray-700 rounded"
                >
                  Cancel
                </button>
                <button
                  onClick={() => handleDelete(bucket.id)}
                  className="px-3 py-1 text-sm bg-red-600 text-white rounded hover:bg-red-700"
                >
                  Delete
                </button>
              </div>
            </div>
          ) : editingId === bucket.id ? (
            // Edit mode
            <div className="flex items-center gap-2">
              <input
                type="text"
                value={editingName}
                onChange={(e) => setEditingName(e.target.value)}
                onKeyDown={(e) => e.key === 'Enter' && handleSaveEdit(bucket.id)}
                className="flex-1 px-3 py-1 border border-gray-200 dark:border-gray-700 rounded bg-white dark:bg-gray-800 text-gray-900 dark:text-white"
                autoFocus
              />
              <button
                onClick={() => handleSaveEdit(bucket.id)}
                className="px-3 py-1 text-sm bg-blue-600 text-white rounded hover:bg-blue-700"
              >
                Save
              </button>
              <button
                onClick={() => setEditingId(null)}
                className="px-3 py-1 text-sm text-gray-600 dark:text-gray-400 hover:bg-gray-100 dark:hover:bg-gray-700 rounded"
              >
                Cancel
              </button>
            </div>
          ) : (
            // Normal view
            <div className="flex items-center justify-between">
              <div className="flex items-center gap-3">
                {/* Color selector */}
                <div className="relative group">
                  <div
                    className="w-4 h-4 rounded-full cursor-pointer ring-2 ring-offset-2 ring-offset-white dark:ring-offset-gray-800 ring-transparent hover:ring-gray-300"
                    style={{ backgroundColor: bucket.color }}
                  />
                  <div className="absolute left-0 top-6 hidden group-hover:flex gap-1 p-2 bg-white dark:bg-gray-800 border border-gray-200 dark:border-gray-700 rounded-lg shadow-lg z-10">
                    {PRESET_COLORS.map((color) => (
                      <button
                        key={color.hex}
                        onClick={() => handleColorChange(bucket.id, color.hex)}
                        className={`w-5 h-5 rounded-full ${bucket.color === color.hex ? 'ring-2 ring-offset-1 ring-gray-400' : ''}`}
                        style={{ backgroundColor: color.hex }}
                        title={color.name}
                      />
                    ))}
                  </div>
                </div>
                <span className="text-gray-900 dark:text-white">{bucket.name}</span>
              </div>
              <div className="flex gap-1">
                <button
                  onClick={() => handleStartEdit(bucket)}
                  className="p-2 text-gray-400 hover:text-gray-600 dark:hover:text-gray-300 rounded hover:bg-gray-100 dark:hover:bg-gray-700"
                >
                  <svg className="w-4 h-4" fill="none" stroke="currentColor" viewBox="0 0 24 24">
                    <path strokeLinecap="round" strokeLinejoin="round" strokeWidth={2} d="M15.232 5.232l3.536 3.536m-2.036-5.036a2.5 2.5 0 113.536 3.536L6.5 21.036H3v-3.572L16.732 3.732z" />
                  </svg>
                </button>
                <button
                  onClick={() => setDeleteConfirmId(bucket.id)}
                  className="p-2 text-gray-400 hover:text-red-600 dark:hover:text-red-400 rounded hover:bg-gray-100 dark:hover:bg-gray-700"
                >
                  <svg className="w-4 h-4" fill="none" stroke="currentColor" viewBox="0 0 24 24">
                    <path strokeLinecap="round" strokeLinejoin="round" strokeWidth={2} d="M19 7l-.867 12.142A2 2 0 0116.138 21H7.862a2 2 0 01-1.995-1.858L5 7m5 4v6m4-6v6m1-10V4a1 1 0 00-1-1h-4a1 1 0 00-1 1v3M4 7h16" />
                  </svg>
                </button>
              </div>
            </div>
          )}
        </div>
      ))}

      {/* Add Bucket Form */}
      {isAdding ? (
        <div className="px-4 py-3 space-y-3">
          <input
            type="text"
            value={newBucketName}
            onChange={(e) => setNewBucketName(e.target.value)}
            onKeyDown={(e) => e.key === 'Enter' && handleAddBucket()}
            placeholder="Bucket name"
            className="w-full px-3 py-2 border border-gray-200 dark:border-gray-700 rounded-lg bg-white dark:bg-gray-800 text-gray-900 dark:text-white placeholder-gray-400"
            autoFocus
          />
          <div className="flex items-center gap-2">
            <span className="text-sm text-gray-500">Color:</span>
            <div className="flex gap-1">
              {PRESET_COLORS.map((color) => (
                <button
                  key={color.hex}
                  onClick={() => setSelectedColor(color.hex)}
                  className={`w-6 h-6 rounded-full ${selectedColor === color.hex ? 'ring-2 ring-offset-2 ring-blue-500' : ''}`}
                  style={{ backgroundColor: color.hex }}
                  title={color.name}
                />
              ))}
            </div>
          </div>
          <div className="flex gap-2">
            <button
              onClick={handleAddBucket}
              disabled={!newBucketName.trim()}
              className="px-4 py-2 bg-blue-600 text-white rounded-lg hover:bg-blue-700 disabled:opacity-50 disabled:cursor-not-allowed"
            >
              Add Bucket
            </button>
            <button
              onClick={() => {
                setIsAdding(false);
                setNewBucketName('');
              }}
              className="px-4 py-2 text-gray-600 dark:text-gray-400 hover:bg-gray-100 dark:hover:bg-gray-700 rounded-lg"
            >
              Cancel
            </button>
          </div>
        </div>
      ) : (
        <div className="px-4 py-3">
          <button
            onClick={() => setIsAdding(true)}
            className="flex items-center gap-2 text-blue-600 dark:text-blue-400 hover:text-blue-700 dark:hover:text-blue-300"
          >
            <svg className="w-5 h-5" fill="none" stroke="currentColor" viewBox="0 0 24 24">
              <path strokeLinecap="round" strokeLinejoin="round" strokeWidth={2} d="M12 4v16m8-8H4" />
            </svg>
            Add Bucket
          </button>
        </div>
      )}

      {/* Empty state */}
      {buckets.length === 0 && !isAdding && (
        <div className="px-4 py-6 text-center text-gray-500 dark:text-gray-400">
          <p>No buckets yet</p>
          <p className="text-sm">Create buckets to organize your tasks</p>
        </div>
      )}
    </div>
  );
}
