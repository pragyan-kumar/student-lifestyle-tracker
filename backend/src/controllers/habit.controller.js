const HabitLog = require("../models/habitLog.model");
const User = require("../models/user.model");
const { logger } = require("../utils/logger");
const {
  calculateHabitPoints,
  detectFlags,
  calculateNewStreak,
} = require("../services/habit/habit.service");

// GET /api/v1/habits
exports.getLogs = async (req, res) => {
  try {
    const { date, from, to, limit = 30 } = req.query;
    let query = { userId: req.user._id };

    if (date) {
      const d = new Date(date);
      query.date = {
        $gte: new Date(d.setHours(0, 0, 0, 0)),
        $lt: new Date(d.setHours(23, 59, 59, 999)),
      };
    } else if (from && to) {
      query.date = { $gte: new Date(from), $lte: new Date(to) };
    }

    const logs = await HabitLog.find(query)
      .sort({ date: -1 })
      .limit(Number(limit));
    res.json({ logs, count: logs.length });
  } catch (err) {
    logger.error("Get habit logs error:", err);
    res.status(500).json({ error: "Failed to fetch habit logs" });
  }
};

const { syncHabitsToFirebase } = require("../services/firebaseSync.service");

function normalizeHabitKey(key) {
  if (!key || typeof key !== "string") return null;
  const k = key.replace(/–/g, "-").trim().toLowerCase();
  if (k.includes("sleep")) return "Sleep (6–9h)";
  if (k.includes("meal") || k.includes("diet")) return "Healthy Meal";
  if (k.includes("exercise")) return "Exercise (30 min)";
  if (k.includes("screen")) return "Screen Time < 4h";
  if (k.includes("water")) return "Water (8 glasses)";
  return key;
}

// GET /api/v1/habits/today
exports.getToday = async (req, res) => {
  try {
    const start = new Date();
    start.setHours(0, 0, 0, 0);
    const end = new Date();
    end.setHours(23, 59, 59, 999);

    const log = await HabitLog.findOne({
      userId: req.user._id,
      date: { $gte: start, $lte: end },
    }).sort({ createdAt: -1 });

    const checklist = {
      "Sleep (6–9h)": !!(
        log?.checklist?.["Sleep (6–9h)"] ??
        (log?.sleep?.hours >= 6 && log?.sleep?.hours <= 9)
      ),
      "Healthy Meal": !!(
        log?.checklist?.["Healthy Meal"] ??
        (log?.diet?.mealType && log?.diet?.mealType !== "meat_heavy")
      ),
      "Exercise (30 min)": !!(
        log?.checklist?.["Exercise (30 min)"] ??
        log?.exercise?.durationMins >= 30
      ),
      "Screen Time < 4h": !!(
        log?.checklist?.["Screen Time < 4h"] ??
        (log?.screenTime?.hours != null && log?.screenTime?.hours <= 4)
      ),
      "Water (8 glasses)": !!(
        log?.checklist?.["Water (8 glasses)"] ??
        (log?.diet?.waterGlasses || 0) >= 8
      ),
    };

    const completedCount = Object.values(checklist).filter(Boolean).length;
    const totalCount = 5;
    const percent = Math.round((completedCount / totalCount) * 100);

    res.json({
      hasLoggedToday: !!log,
      log,
      checklist,
      completedCount,
      totalCount,
      percent,
    });
  } catch (err) {
    logger.error("Get today habit error:", err);
    res.status(500).json({ error: "Failed to fetch today's habit log" });
  }
};

// POST /api/v1/habits/checklist/toggle
exports.toggleChecklist = async (req, res) => {
  try {
    const { habit, done } = req.body;
    if (!habit) {
      return res.status(400).json({ error: "Habit name is required" });
    }

    const canonicalKey = normalizeHabitKey(habit);
    if (!canonicalKey) {
      return res.status(400).json({ error: `Unknown habit: ${habit}` });
    }

    const start = new Date();
    start.setHours(0, 0, 0, 0);
    const end = new Date();
    end.setHours(23, 59, 59, 999);

    let log = await HabitLog.findOne({
      userId: req.user._id,
      date: { $gte: start, $lte: end },
    }).sort({ createdAt: -1 });

    if (!log) {
      log = new HabitLog({
        userId: req.user._id,
        date: new Date(),
        checklist: {
          "Sleep (6–9h)": false,
          "Healthy Meal": false,
          "Exercise (30 min)": false,
          "Screen Time < 4h": false,
          "Water (8 glasses)": false,
        },
      });
    }

    if (!log.checklist) {
      log.checklist = {};
    }

    const isDone =
      done === undefined ? !log.checklist[canonicalKey] : Boolean(done);
    log.checklist[canonicalKey] = isDone;

    // Sync corresponding field values
    if (canonicalKey === "Sleep (6–9h)") {
      log.sleep = isDone
        ? { hours: 8, quality: "good", bedtime: "23:00", wakeTime: "07:00" }
        : { hours: 0, quality: null };
    } else if (canonicalKey === "Healthy Meal") {
      log.diet = log.diet || {};
      log.diet.mealType = isDone ? "vegan" : null;
      log.diet.mealsLogged = isDone ? 1 : 0;
    } else if (canonicalKey === "Exercise (30 min)") {
      log.exercise = isDone
        ? { durationMins: 30, completed: true, type: "walk" }
        : { durationMins: 0, completed: false };
    } else if (canonicalKey === "Screen Time < 4h") {
      log.screenTime = isDone ? { hours: 3 } : { hours: null };
    } else if (canonicalKey === "Water (8 glasses)") {
      log.diet = log.diet || {};
      log.diet.waterGlasses = isDone ? 8 : 0;
    }

    // Recalculate flags
    log.flags = detectFlags({
      sleep: log.sleep,
      diet: log.diet,
      exercise: log.exercise,
      screenTime: log.screenTime,
    });

    // Recompute points
    const previousPoints = log.pointsEarned || 0;
    const newPoints = calculateHabitPoints({
      sleep: log.sleep,
      diet: log.diet,
      exercise: log.exercise,
      screenTime: log.screenTime,
      flags: log.flags,
    });
    log.pointsEarned = newPoints;
    const pointDelta = newPoints - previousPoints;

    log.markModified("checklist");
    log.markModified("sleep");
    log.markModified("diet");
    log.markModified("exercise");
    log.markModified("screenTime");
    await log.save();

    // Update user streak and points
    const user = await User.findById(req.user._id);
    if (user) {
      if (isDone) {
        const newStreak = calculateNewStreak(
          user.lastActivityDate,
          user.streakDays || 0,
        );
        user.streakDays = newStreak;
        user.lastActivityDate = new Date();
      }
      user.points = Math.max(0, (user.points || 0) + pointDelta);
      await user.save();
    }

    const currentChecklist = {
      "Sleep (6–9h)": Boolean(log.checklist?.["Sleep (6–9h)"]),
      "Healthy Meal": Boolean(log.checklist?.["Healthy Meal"]),
      "Exercise (30 min)": Boolean(log.checklist?.["Exercise (30 min)"]),
      "Screen Time < 4h": Boolean(log.checklist?.["Screen Time < 4h"]),
      "Water (8 glasses)": Boolean(log.checklist?.["Water (8 glasses)"]),
    };

    const completedCount =
      Object.values(currentChecklist).filter(Boolean).length;
    const totalCount = 5;
    const percent = Math.round((completedCount / totalCount) * 100);

    // Sync to Firebase RTDB in background
    syncHabitsToFirebase(req.user._id.toString(), {
      checklist: currentChecklist,
      habitLog: log,
      user,
    }).catch((err) =>
      logger.warn("Background Firebase RTDB sync failed:", err.message),
    );

    logger.info(
      `Toggled habit '${canonicalKey}' to ${isDone} for user ${req.user._id}`,
    );

    res.json({
      success: true,
      habit: canonicalKey,
      done: isDone,
      checklist: currentChecklist,
      completedCount,
      totalCount,
      percent,
      pointsEarned: log.pointsEarned,
      user: {
        points: user?.points || 0,
        streakDays: user?.streakDays || 0,
      },
    });
  } catch (err) {
    logger.error("Toggle checklist error:", err);
    res.status(500).json({ error: "Failed to toggle habit checklist" });
  }
};

// POST /api/v1/habits
exports.createLog = async (req, res) => {
  try {
    const { sleep, diet, exercise, screenTime } = req.body;

    // Compute flags
    const flags = detectFlags({ sleep, diet, exercise, screenTime });
    // Compute points earned
    const pointsEarned = calculateHabitPoints({
      sleep,
      diet,
      exercise,
      screenTime,
      flags,
    });

    const checklist = {
      "Sleep (6–9h)": !!(sleep?.hours >= 6 && sleep?.hours <= 9),
      "Healthy Meal": !!(diet?.mealType && diet?.mealType !== "meat_heavy"),
      "Exercise (30 min)": !!(exercise?.durationMins >= 30),
      "Screen Time < 4h": !!(
        screenTime?.hours != null && screenTime?.hours <= 4
      ),
      "Water (8 glasses)": !!((diet?.waterGlasses || 0) >= 8),
    };

    const log = await HabitLog.create({
      userId: req.user._id,
      sleep,
      diet,
      exercise,
      screenTime,
      flags,
      checklist,
      pointsEarned,
    });

    // Update streak and user points
    const user = await User.findById(req.user._id);
    if (user) {
      const newStreak = calculateNewStreak(
        user.lastActivityDate,
        user.streakDays || 0,
      );
      user.streakDays = newStreak;
      user.lastActivityDate = new Date();
      user.points = (user.points || 0) + pointsEarned;
      await user.save();
    }

    // Sync to Firebase RTDB
    syncHabitsToFirebase(req.user._id.toString(), {
      checklist,
      habitLog: log,
      user,
    }).catch((err) =>
      logger.warn("Background Firebase RTDB sync failed:", err.message),
    );

    logger.info(
      `Habit log created for user ${req.user._id}, +${pointsEarned} pts, streak: ${user?.streakDays || 1}`,
    );
    res
      .status(201)
      .json({
        log,
        checklist,
        pointsEarned,
        streakDays: user?.streakDays || 1,
      });
  } catch (err) {
    logger.error("Create habit log error:", err);
    res.status(500).json({ error: "Failed to create habit log" });
  }
};

// GET /api/v1/habits/streak
exports.getStreak = async (req, res) => {
  try {
    const user = await User.findById(req.user._id);
    res.json({
      streakDays: user?.streakDays || 0,
      lastActivityDate: user?.lastActivityDate,
    });
  } catch (err) {
    res.status(500).json({ error: "Failed to get streak" });
  }
};

// GET /api/v1/habits/summary
exports.getSummary = async (req, res) => {
  try {
    const sevenDaysAgo = new Date(Date.now() - 7 * 24 * 60 * 60 * 1000);
    const logs = await HabitLog.find({
      userId: req.user._id,
      date: { $gte: sevenDaysAgo },
    });

    const summary = {
      totalLogs: logs.length,
      avgSleep: parseFloat(
        (
          logs.reduce((s, l) => s + (l.sleep?.hours || 0), 0) /
          (logs.length || 1)
        ).toFixed(1),
      ),
      avgExercise: parseFloat(
        (
          logs.reduce((s, l) => s + (l.exercise?.durationMins || 0), 0) /
          (logs.length || 1)
        ).toFixed(1),
      ),
      totalPoints: logs.reduce((s, l) => s + (l.pointsEarned || 0), 0),
      flagCounts: {
        lowSleep: logs.filter((l) => l.flags?.lowSleep).length,
        noExercise: logs.filter((l) => l.flags?.noExercise).length,
        excessScreen: logs.filter((l) => l.flags?.excessScreen).length,
      },
    };

    res.json({ summary });
  } catch (err) {
    res.status(500).json({ error: "Failed to get summary" });
  }
};

// PUT /api/v1/habits/:id
exports.updateLog = async (req, res) => {
  try {
    const log = await HabitLog.findOneAndUpdate(
      { _id: req.params.id, userId: req.user._id },
      req.body,
      { new: true },
    );
    if (!log) return res.status(404).json({ error: "Log not found" });
    res.json({ log });
  } catch (err) {
    res.status(500).json({ error: "Failed to update log" });
  }
};

// DELETE /api/v1/habits/:id
exports.deleteLog = async (req, res) => {
  try {
    const log = await HabitLog.findOneAndDelete({
      _id: req.params.id,
      userId: req.user._id,
    });
    if (!log) return res.status(404).json({ error: "Log not found" });
    res.json({ message: "Deleted" });
  } catch (err) {
    res.status(500).json({ error: "Failed to delete log" });
  }
};
