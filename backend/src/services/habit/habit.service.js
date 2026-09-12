const APP_CONSTANTS = {
  SLEEP_MIN : 6,
  SLEEP_MAX : 9,
  SCREEN_MAX: 4,
  EXERCISE_MIN: 30,
};

const POINTS = {
  SLEEP_LOG    : 10,
  DIET_LOG     : 10,
  EXERCISE_LOG : 15,
  SCREEN_GOOD  : 5,
};

/**
 * Detects unhealthy streaks / flags from a habit log entry.
 */
const detectFlags = ({ sleep, diet, exercise, screenTime } = {}) => ({
  lowSleep      : sleep?.hours != null && sleep.hours < APP_CONSTANTS.SLEEP_MIN,
  unhealthyMeal : diet?.mealType === 'meat_heavy',
  noExercise    : exercise?.durationMins != null && exercise.durationMins < APP_CONSTANTS.EXERCISE_MIN,
  excessScreen  : screenTime?.hours != null && screenTime.hours > APP_CONSTANTS.SCREEN_MAX,
});

/**
 * Awards points for completed healthy habits.
 */
const calculateHabitPoints = ({ sleep, diet, exercise, screenTime, flags = {} } = {}) => {
  let pts = 0;
  if (sleep?.hours    != null) pts += POINTS.SLEEP_LOG;
  if (diet?.mealType  != null) pts += POINTS.DIET_LOG;
  if (exercise?.durationMins >= APP_CONSTANTS.EXERCISE_MIN) pts += POINTS.EXERCISE_LOG;
  if (screenTime?.hours != null && screenTime.hours <= APP_CONSTANTS.SCREEN_MAX) pts += POINTS.SCREEN_GOOD;
  return pts;
};

/**
 * Date helper functions for calendar streaks.
 */
const isSameCalendarDay = (d1, d2) => {
  if (!d1 || !d2) return false;
  const a = new Date(d1);
  const b = new Date(d2);
  return (
    a.getFullYear() === b.getFullYear() &&
    a.getMonth() === b.getMonth() &&
    a.getDate() === b.getDate()
  );
};

const isYesterday = (d1, d2) => {
  if (!d1 || !d2) return false;
  const yesterday = new Date(d2);
  yesterday.setDate(yesterday.getDate() - 1);
  return isSameCalendarDay(d1, yesterday);
};

/**
 * Determines updated streak count based on last activity timestamp.
 */
const calculateNewStreak = (lastActivityDate, currentStreak = 0, now = new Date()) => {
  if (!lastActivityDate) {
    return 1;
  }
  if (isSameCalendarDay(lastActivityDate, now)) {
    return Math.max(1, currentStreak);
  }
  if (isYesterday(lastActivityDate, now)) {
    return currentStreak + 1;
  }
  // Missed more than a day
  return 1;
};

module.exports = {
  detectFlags,
  calculateHabitPoints,
  isSameCalendarDay,
  isYesterday,
  calculateNewStreak,
  APP_CONSTANTS,
  POINTS,
};
