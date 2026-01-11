import { ParsedTask, RecurrenceType } from '@/types';

// Day name to number mapping (0 = Sunday)
const dayPatterns: Record<string, number> = {
  sunday: 0, sun: 0,
  monday: 1, mon: 1,
  tuesday: 2, tue: 2, tues: 2,
  wednesday: 3, wed: 3,
  thursday: 4, thu: 4, thurs: 4,
  friday: 5, fri: 5,
  saturday: 6, sat: 6,
};

// Named time patterns
const timePatterns: Record<string, { hour: number; minute: number }> = {
  morning: { hour: 9, minute: 0 },
  noon: { hour: 12, minute: 0 },
  afternoon: { hour: 14, minute: 0 },
  evening: { hour: 18, minute: 0 },
  night: { hour: 20, minute: 0 },
  'end of day': { hour: 17, minute: 0 },
  eod: { hour: 17, minute: 0 },
  cob: { hour: 17, minute: 0 },
};

export function parseNaturalLanguage(input: string): ParsedTask {
  const lowercased = input.toLowerCase();

  let dueDate: Date | null = null;
  let recurrence: ParsedTask['recurrence'] = null;

  // Extract recurrence
  recurrence = extractRecurrence(lowercased);

  // Extract date and time
  const extractedDate = extractDate(lowercased);
  const extractedTime = extractTime(lowercased);

  if (extractedDate || extractedTime) {
    dueDate = new Date();

    if (extractedDate) {
      dueDate = extractedDate;
    }

    if (extractedTime) {
      dueDate.setHours(extractedTime.hour, extractedTime.minute, 0, 0);
    } else {
      // Default to 9 AM
      dueDate.setHours(9, 0, 0, 0);
    }
  }

  // Extract title (remove date/time/recurrence phrases)
  const title = extractTitle(input, lowercased);

  return { title, dueDate, recurrence };
}

function extractRecurrence(input: string): ParsedTask['recurrence'] {
  // Check for "every day" / "daily"
  if (input.includes('every day') || input.includes('daily')) {
    return { type: 'daily', days: [], interval: 1 };
  }

  // Check for "every week" / "weekly"
  if (input.includes('every week') || input.includes('weekly')) {
    return { type: 'weekly', days: [], interval: 1 };
  }

  // Check for "every month" / "monthly"
  if (input.includes('every month') || input.includes('monthly')) {
    return { type: 'monthly', days: [], interval: 1 };
  }

  // Check for "every [day name]"
  const everyDayMatch = input.match(/every\s+((?:sun|mon|tue|wed|thu|fri|sat)[a-z]*(?:\s+and\s+(?:sun|mon|tue|wed|thu|fri|sat)[a-z]*)*)/i);
  if (everyDayMatch) {
    const daysStr = everyDayMatch[1];
    const days: number[] = [];

    for (const [dayName, dayNum] of Object.entries(dayPatterns)) {
      if (daysStr.includes(dayName)) {
        if (!days.includes(dayNum)) {
          days.push(dayNum);
        }
      }
    }

    if (days.length > 0) {
      return { type: 'weekly', days: days.sort(), interval: 1 };
    }
  }

  // Check for "every X days/weeks/months"
  const intervalMatch = input.match(/every\s+(\d+)\s+(day|week|month)s?/);
  if (intervalMatch) {
    const interval = parseInt(intervalMatch[1]);
    const unit = intervalMatch[2];

    let type: RecurrenceType = 'custom';
    if (unit === 'day') type = 'daily';
    else if (unit === 'week') type = 'weekly';
    else if (unit === 'month') type = 'monthly';

    return { type, days: [], interval };
  }

  return null;
}

function extractDate(input: string): Date | null {
  const now = new Date();

  if (input.includes('today')) {
    return now;
  }

  if (input.includes('tomorrow')) {
    const tomorrow = new Date(now);
    tomorrow.setDate(tomorrow.getDate() + 1);
    return tomorrow;
  }

  if (input.includes('next week')) {
    const nextWeek = new Date(now);
    nextWeek.setDate(nextWeek.getDate() + 7);
    return nextWeek;
  }

  // Check for day names (without "every")
  if (!input.includes('every')) {
    for (const [dayName, dayNum] of Object.entries(dayPatterns)) {
      if (input.includes(dayName)) {
        return getNextWeekday(dayNum);
      }
    }
  }

  return null;
}

function extractTime(input: string): { hour: number; minute: number } | null {
  // Check named times
  for (const [name, time] of Object.entries(timePatterns)) {
    if (input.includes(name)) {
      return time;
    }
  }

  // Check for time patterns like "at 9am", "at 2:30pm", "at 14:00"
  const timeMatch = input.match(/(?:at\s+)?(\d{1,2})(?::(\d{2}))?\s*(am|pm|a\.m\.|p\.m\.)?/i);
  if (timeMatch) {
    let hour = parseInt(timeMatch[1]);
    const minute = timeMatch[2] ? parseInt(timeMatch[2]) : 0;
    const ampm = timeMatch[3]?.toLowerCase();

    if (ampm) {
      if (ampm.startsWith('p') && hour < 12) {
        hour += 12;
      } else if (ampm.startsWith('a') && hour === 12) {
        hour = 0;
      }
    }

    return { hour, minute };
  }

  return null;
}

function extractTitle(original: string, lowercased: string): string {
  const patternsToRemove = [
    /every\s+\w+(\s+and\s+\w+)*/gi,
    /at\s+\d{1,2}(?::\d{2})?\s*(?:am|pm|a\.m\.|p\.m\.)?/gi,
    /\d{1,2}(?::\d{2})?\s*(?:am|pm)/gi,
    /\btoday\b/gi,
    /\btomorrow\b/gi,
    /\bnext\s+\w+\b/gi,
    /\bon\s+\w+\b/gi,
    /\bdaily\b/gi,
    /\bweekly\b/gi,
    /\bmonthly\b/gi,
    /\bmorning\b/gi,
    /\bafternoon\b/gi,
    /\bevening\b/gi,
    /\bnight\b/gi,
    /\bnoon\b/gi,
    /\beod\b/gi,
    /\bcob\b/gi,
    /\bend of day\b/gi,
  ];

  let title = original;
  for (const pattern of patternsToRemove) {
    title = title.replace(pattern, '');
  }

  // Clean up whitespace
  title = title.replace(/\s+/g, ' ').trim();

  // Capitalize first letter
  if (title.length > 0) {
    title = title.charAt(0).toUpperCase() + title.slice(1);
  }

  return title || original;
}

function getNextWeekday(targetDay: number): Date {
  const now = new Date();
  const currentDay = now.getDay();
  let daysToAdd = targetDay - currentDay;

  if (daysToAdd <= 0) {
    daysToAdd += 7;
  }

  const result = new Date(now);
  result.setDate(result.getDate() + daysToAdd);
  return result;
}
