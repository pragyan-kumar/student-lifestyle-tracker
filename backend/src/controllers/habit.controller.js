const HabitLog = require("../models/habitLog.model");
const User = require("../models/user.model");
const { logger } = require("../utils/logger");
const {
  calculateHabitPoints,
  detectFlags,
  calculateNewStreak,
} = require("../services/habit/habit.service");
const { recordPoints } = require("../services/gamification/gamification.service");

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
      "Sleep (6–9h)": Boolean(
        log?.checklist?.["Sleep (6–9h)"] ||
        (log?.sleep?.hours != null && log?.sleep?.hours > 0)
      ),
      "Healthy Meal": Boolean(
        log?.checklist?.["Healthy Meal"] ||
        (log?.diet?.mealsLogged >= 1 || (log?.diet?.mealType && log?.diet?.mealType !== "meat_heavy"))
      ),
      "Exercise (30 min)": Boolean(
        log?.checklist?.["Exercise (30 min)"] ||
        (log?.exercise?.durationMins != null && log?.exercise?.durationMins > 0)
      ),
      "Screen Time < 4h": Boolean(
        log?.checklist?.["Screen Time < 4h"] ||
        (log?.screenTime?.hours != null && log?.screenTime?.hours >= 0)
      ),
      "Water (8 glasses)": Boolean(
        log?.checklist?.["Water (8 glasses)"] ||
        (log?.diet?.waterGlasses || 0) > 0
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

    // Sync corresponding field values without clobbering user-entered values
    if (canonicalKey === "Sleep (6–9h)") {
      if (!isDone) {
        log.sleep = { hours: 0, quality: null };
      } else if (!log.sleep?.hours || log.sleep.hours === 0) {
        log.sleep = { hours: 8, quality: "good", bedtime: "23:00", wakeTime: "07:00" };
      }
    } else if (canonicalKey === "Healthy Meal") {
      log.diet = log.diet || {};
      if (!isDone) {
        log.diet.mealType = null;
        log.diet.mealsLogged = 0;
      } else if (!log.diet.mealsLogged && !log.diet.mealType) {
        log.diet.mealType = "vegan";
        log.diet.mealsLogged = 1;
      }
    } else if (canonicalKey === "Exercise (30 min)") {
      if (!isDone) {
        log.exercise = { durationMins: 0, completed: false };
      } else if (!log.exercise?.durationMins) {
        log.exercise = { durationMins: 30, completed: true, type: "walk" };
      }
    } else if (canonicalKey === "Screen Time < 4h") {
      if (!isDone) {
        log.screenTime = { hours: null };
      } else if (log.screenTime?.hours == null) {
        log.screenTime = { hours: 3 };
      }
    } else if (canonicalKey === "Water (8 glasses)") {
      log.diet = log.diet || {};
      if (!isDone) {
        log.diet.waterGlasses = 0;
      } else if (!log.diet.waterGlasses) {
        log.diet.waterGlasses = 8;
      }
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

      // Record point history
      if (pointDelta !== 0) {
        recordPoints(req.user._id, {
          amount: pointDelta,
          type: 'habit',
          label: pointDelta > 0
            ? `✅ Habit completed: ${canonicalKey}`
            : `↩️ Habit unchecked: ${canonicalKey}`,
          refModel: 'HabitLog',
          refId: log._id,
        }).catch((err) => logger.warn('Point history record failed:', err.message));
      }
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
      log,
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
    // Extract all supported fields from the payload.
    // The Flutter client sends habit-specific fields:
    //   sleep: {hours: N}, diet: {meals: N, mealType: str}, exercise: {durationMins: N},
    //   screenTime: {hours: N}, water: {glasses: N}
    let { sleep, diet, exercise, screenTime, water } = req.body;

    // Normalise diet: merge water.glasses → diet.waterGlasses
    // and handle meals count sent by the slider (no mealType in that path)
    diet = diet || {};
    if (water?.glasses != null) {
      diet.waterGlasses = Number(water.glasses);
    }
    // If meals count is provided but mealType is missing, infer a healthy type
    if (diet.meals != null && diet.mealType == null) {
      diet.mealsLogged = Number(diet.meals);
      diet.mealType = diet.mealsLogged >= 2 ? 'mixed' : 'vegan';
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
        checklist: {},
      });
    }

    if (!log.checklist) {
      log.checklist = {};
    }

    // Merge incoming fields
    if (sleep) {
      const prevSleep = log.sleep ? (log.sleep.toObject ? log.sleep.toObject() : log.sleep) : {};
      log.sleep = { ...prevSleep, ...sleep };
    }
    if (diet && Object.keys(diet).length > 0) {
      const prevDiet = log.diet ? (log.diet.toObject ? log.diet.toObject() : log.diet) : {};
      log.diet = { ...prevDiet, ...diet };
    }
    if (exercise) {
      const prevEx = log.exercise ? (log.exercise.toObject ? log.exercise.toObject() : log.exercise) : {};
      log.exercise = { ...prevEx, ...exercise };
    }
    if (screenTime) {
      const prevScreen = log.screenTime ? (log.screenTime.toObject ? log.screenTime.toObject() : log.screenTime) : {};
      log.screenTime = { ...prevScreen, ...screenTime };
    }

    // Determine checklist completion:
    // A habit is marked done when the user explicitly logs a value (any value > 0)
    if (log.sleep?.hours != null && log.sleep.hours > 0) {
      log.checklist["Sleep (6–9h)"] = true;
    }
    if ((log.diet?.mealsLogged != null && log.diet.mealsLogged >= 1) || (log.diet?.mealType && log.diet.mealType !== 'meat_heavy')) {
      log.checklist["Healthy Meal"] = true;
    }
    if (log.exercise?.durationMins != null && log.exercise.durationMins > 0) {
      log.checklist["Exercise (30 min)"] = true;
    }
    if (log.screenTime?.hours != null && log.screenTime.hours >= 0) {
      log.checklist["Screen Time < 4h"] = true;
    }
    if ((log.diet?.waterGlasses || 0) > 0) {
      log.checklist["Water (8 glasses)"] = true;
    }

    // Compute flags
    log.flags = detectFlags({
      sleep: log.sleep,
      diet: log.diet,
      exercise: log.exercise,
      screenTime: log.screenTime,
    });

    // Compute points earned
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

    // Update streak and user points
    const user = await User.findById(req.user._id);
    if (user) {
      const newStreak = calculateNewStreak(
        user.lastActivityDate,
        user.streakDays || 0,
      );
      user.streakDays = newStreak;
      user.lastActivityDate = new Date();
      if (pointDelta > 0) {
        user.points = (user.points || 0) + pointDelta;
      }
      await user.save();

      // Record point history for the new log
      if (pointDelta > 0) {
        recordPoints(req.user._id, {
          amount: pointDelta,
          type: 'habit',
          label: '📝 Daily habit log recorded',
          refModel: 'HabitLog',
          refId: log._id,
        }).catch((err) => logger.warn('Point history record failed:', err.message));
      }
    }

    const currentChecklist = {
      "Sleep (6–9h)": Boolean(log.checklist?.["Sleep (6–9h)"]),
      "Healthy Meal": Boolean(log.checklist?.["Healthy Meal"]),
      "Exercise (30 min)": Boolean(log.checklist?.["Exercise (30 min)"]),
      "Screen Time < 4h": Boolean(log.checklist?.["Screen Time < 4h"]),
      "Water (8 glasses)": Boolean(log.checklist?.["Water (8 glasses)"]),
    };

    // Sync to Firebase RTDB
    syncHabitsToFirebase(req.user._id.toString(), {
      checklist: currentChecklist,
      habitLog: log,
      user,
    }).catch((err) =>
      logger.warn("Background Firebase RTDB sync failed:", err.message),
    );

    const completedCount = Object.values(currentChecklist).filter(Boolean).length;
    const totalCount = 5;
    const percent = Math.round((completedCount / totalCount) * 100);

    logger.info(
      `Habit log updated for user ${req.user._id}, +${pointDelta} pts, streak: ${user?.streakDays || 1}`,
    );
    res
      .status(200)
      .json({
        log,
        checklist: currentChecklist,
        completedCount,
        totalCount,
        percent,
        pointsEarned: log.pointsEarned,
        streakDays: user?.streakDays || 1,
        user: {
          points: user?.points || 0,
          streakDays: user?.streakDays || 1,
        },
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
