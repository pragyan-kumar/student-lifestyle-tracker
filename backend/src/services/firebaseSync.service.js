const { rtdb, isFirebaseConfigured } = require("../config/firebase");
const { logger } = require("../utils/logger");

/**
 * Syncs user habit checklist & daily summary to Firebase Realtime Database.
 */
async function syncHabitsToFirebase(userId, { checklist, habitLog, user }) {
  if (!isFirebaseConfigured || !rtdb) return;

  try {
    const todayKey = new Date().toISOString().split("T")[0];
    const completedCount = Object.values(checklist || {}).filter(
      Boolean,
    ).length;
    const totalCount = Object.keys(checklist || {}).length || 5;
    const percent = Math.round((completedCount / totalCount) * 100);

    const habitPayload = {
      checklist: checklist || {},
      completedCount,
      totalCount,
      percent,
      points: user?.points || 0,
      streakDays: user?.streakDays || 0,
      updatedAt: new Date().toISOString(),
    };

    if (habitLog) {
      habitPayload.log = {
        sleep: habitLog.sleep || {},
        diet: habitLog.diet || {},
        exercise: habitLog.exercise || {},
        screenTime: habitLog.screenTime || {},
        pointsEarned: habitLog.pointsEarned || 0,
      };
    }

    const sanitizedPayload = JSON.parse(JSON.stringify(habitPayload));

    // Sync under user's node and global todayChecklist node
    await rtdb.ref(`users/${userId}/todayChecklist`).set(sanitizedPayload);
    await rtdb.ref(`users/${userId}/habits/${todayKey}`).set(sanitizedPayload);
    await rtdb.ref(`todayChecklist/${userId}`).set({
      userName: user?.name || "Student",
      email: user?.email || "",
      ...sanitizedPayload,
    });

    logger.debug(`Synced habit checklist to Firebase RTDB for user ${userId}`);
  } catch (err) {
    logger.warn("Failed to sync habits to Firebase RTDB:", err.message);
  }
}

/**
 * Syncs full dashboard state to Firebase Realtime Database.
 */
async function syncDashboardToFirebase(userId, dashboardData) {
  if (!isFirebaseConfigured || !rtdb) return;

  try {
    const sanitized = JSON.parse(
      JSON.stringify({
        ...dashboardData,
        updatedAt: new Date().toISOString(),
      }),
    );
    await rtdb.ref(`users/${userId}/dashboard`).set(sanitized);
    logger.debug(`Synced dashboard to Firebase RTDB for user ${userId}`);
  } catch (err) {
    logger.warn("Failed to sync dashboard to Firebase RTDB:", err.message);
  }
}

module.exports = {
  syncHabitsToFirebase,
  syncDashboardToFirebase,
};
