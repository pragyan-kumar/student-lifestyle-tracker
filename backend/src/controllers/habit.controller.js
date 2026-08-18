const HabitLog   = require('../models/habitLog.model');
const User       = require('../models/user.model');
const { logger } = require('../utils/logger');
const { calculateHabitPoints, detectFlags } = require('../services/habit/habit.service');

// GET /api/v1/habits
exports.getLogs = async (req, res) => {
  try {
    const { date, from, to, limit = 30 } = req.query;
    let query = { userId: req.user._id };

    if (date) {
      const d = new Date(date);
      query.date = { $gte: new Date(d.setHours(0,0,0,0)), $lt: new Date(d.setHours(23,59,59,999)) };
    } else if (from && to) {
      query.date = { $gte: new Date(from), $lte: new Date(to) };
    }

    const logs = await HabitLog.find(query).sort({ date: -1 }).limit(Number(limit));
    res.json({ logs, count: logs.length });
  } catch (err) {
    logger.error('Get habit logs error:', err);
    res.status(500).json({ error: 'Failed to fetch habit logs' });
  }
};

// POST /api/v1/habits
exports.createLog = async (req, res) => {
  try {
    const { sleep, diet, exercise, screenTime } = req.body;

    // Compute flags
    const flags = detectFlags({ sleep, diet, exercise, screenTime });
    // Compute points earned
    const pointsEarned = calculateHabitPoints({ sleep, diet, exercise, screenTime, flags });

    const log = await HabitLog.create({
      userId: req.user._id,
      sleep, diet, exercise, screenTime,
      flags, pointsEarned,
    });

    // Award points to user wallet
    await User.findByIdAndUpdate(req.user._id, { $inc: { points: pointsEarned } });

    logger.info(`Habit log created for user ${req.user._id}, +${pointsEarned} pts`);
    res.status(201).json({ log, pointsEarned });
  } catch (err) {
    logger.error('Create habit log error:', err);
    res.status(500).json({ error: 'Failed to create habit log' });
  }
};

// GET /api/v1/habits/streak
exports.getStreak = async (req, res) => {
  try {
    const user = await User.findById(req.user._id);
    res.json({ streakDays: user.streakDays, lastActivityDate: user.lastActivityDate });
  } catch (err) {
    res.status(500).json({ error: 'Failed to get streak' });
  }
};

// GET /api/v1/habits/summary
exports.getSummary = async (req, res) => {
  try {
    const sevenDaysAgo = new Date(Date.now() - 7 * 24 * 60 * 60 * 1000);
    const logs = await HabitLog.find({ userId: req.user._id, date: { $gte: sevenDaysAgo } });

    const summary = {
      totalLogs   : logs.length,
      avgSleep    : logs.reduce((s, l) => s + (l.sleep?.hours || 0), 0) / (logs.length || 1),
      avgExercise : logs.reduce((s, l) => s + (l.exercise?.durationMins || 0), 0) / (logs.length || 1),
      totalPoints : logs.reduce((s, l) => s + l.pointsEarned, 0),
      flagCounts  : {
        lowSleep      : logs.filter(l => l.flags?.lowSleep).length,
        noExercise    : logs.filter(l => l.flags?.noExercise).length,
        excessScreen  : logs.filter(l => l.flags?.excessScreen).length,
      },
    };

    res.json({ summary });
  } catch (err) {
    res.status(500).json({ error: 'Failed to get summary' });
  }
};

// PUT /api/v1/habits/:id
exports.updateLog = async (req, res) => {
  try {
    const log = await HabitLog.findOneAndUpdate({ _id: req.params.id, userId: req.user._id }, req.body, { new: true });
    if (!log) return res.status(404).json({ error: 'Log not found' });
    res.json({ log });
  } catch (err) {
    res.status(500).json({ error: 'Failed to update log' });
  }
};

// DELETE /api/v1/habits/:id
exports.deleteLog = async (req, res) => {
  try {
    const log = await HabitLog.findOneAndDelete({ _id: req.params.id, userId: req.user._id });
    if (!log) return res.status(404).json({ error: 'Log not found' });
    res.json({ message: 'Deleted' });
  } catch (err) {
    res.status(500).json({ error: 'Failed to delete log' });
  }
};
