const User = require("../models/user.model");
const HabitLog = require("../models/habitLog.model");
const CarbonLog = require("../models/carbonLog.model");
const { logger } = require("../utils/logger");

// GET /api/v1/dashboard/summary
exports.getSummary = async (req, res) => {
  try {
    const userId = req.user._id;

    const startOfToday = new Date();
    startOfToday.setHours(0, 0, 0, 0);
    const endOfToday = new Date();
    endOfToday.setHours(23, 59, 59, 999);
    const sevenDaysAgo = new Date(Date.now() - 7 * 24 * 60 * 60 * 1000);

    const [user, todayCarbon, todayHabit, weeklyCarbonLogs] = await Promise.all(
      [
        User.findById(userId),
        CarbonLog.findOne({
          userId,
          date: { $gte: startOfToday, $lte: endOfToday },
        }).sort({ createdAt: -1 }),
        HabitLog.findOne({
          userId,
          date: { $gte: startOfToday, $lte: endOfToday },
        }).sort({ createdAt: -1 }),
        CarbonLog.find({ userId, date: { $gte: sevenDaysAgo } }).sort({
          date: 1,
        }),
      ],
    );

    // Format habit checklist
    const checklist = {
      "Sleep (6–9h)": !!(
        todayHabit?.sleep?.hours >= 6 && todayHabit?.sleep?.hours <= 9
      ),
      "Healthy Meal": !!(
        todayHabit?.diet?.mealType &&
        todayHabit?.diet?.mealType !== "meat_heavy"
      ),
      "Exercise (30 min)": !!(todayHabit?.exercise?.durationMins >= 30),
      "Screen Time < 4h": !!(
        todayHabit?.screenTime?.hours != null &&
        todayHabit?.screenTime?.hours <= 4
      ),
      "Water (8 glasses)": !!((todayHabit?.diet?.waterGlasses || 0) >= 8),
    };

    const completedHabitsCount =
      Object.values(checklist).filter(Boolean).length;

    // Calculate 7-day daily carbon totals
    const dailyMap = {};
    for (let i = 6; i >= 0; i--) {
      const d = new Date(Date.now() - i * 24 * 60 * 60 * 1000);
      const key = d.toISOString().split("T")[0];
      dailyMap[key] = 0.0;
    }

    weeklyCarbonLogs.forEach((log) => {
      const key = new Date(log.date).toISOString().split("T")[0];
      if (dailyMap[key] !== undefined) {
        dailyMap[key] = parseFloat(
          (dailyMap[key] + log.totalEmissionKg).toFixed(2),
        );
      }
    });

    const weeklyValues = Object.values(dailyMap);
    const totalWeeklyKg = parseFloat(
      weeklyValues.reduce((s, v) => s + v, 0).toFixed(2),
    );
    const avgDailyKg = parseFloat((totalWeeklyKg / 7).toFixed(2));

    res.json({
      user: {
        name: user?.name || "Student",
        email: user?.email,
        points: user?.points || 0,
        streakDays: user?.streakDays || 0,
        badgesCount: user?.badges?.length || 0,
        unlockedThemes: user?.unlockedThemes || [],
      },
      todayCarbon: {
        hasLogged: !!todayCarbon,
        totalEmissionKg: todayCarbon?.totalEmissionKg || 0.0,
        savedVsAverage: todayCarbon?.savedVsAverage || 0.0,
        breakdown: {
          commute: todayCarbon?.commute?.emissionKg || 0.0,
          food: todayCarbon?.food?.emissionKg || 0.0,
          devices: todayCarbon?.devices?.emissionKg || 0.0,
        },
      },
      todayHabits: {
        hasLogged: !!todayHabit,
        completedCount: completedHabitsCount,
        totalCount: 5,
        percent: Math.round((completedHabitsCount / 5) * 100),
        checklist,
        progress: {
          sleep: {
            hours: todayHabit?.sleep?.hours || 0,
            status: todayHabit?.sleep?.hours
              ? `${todayHabit.sleep.hours}h`
              : "Not logged",
          },
          diet: {
            mealType: todayHabit?.diet?.mealType || null,
            status: todayHabit?.diet?.mealType || "Not logged",
          },
          exercise: {
            durationMins: todayHabit?.exercise?.durationMins || 0,
            status: todayHabit?.exercise?.durationMins
              ? `${todayHabit.exercise.durationMins}m`
              : "Not logged",
          },
          screen: {
            hours: todayHabit?.screenTime?.hours || 0,
            status:
              todayHabit?.screenTime?.hours != null
                ? `${todayHabit.screenTime.hours}h`
                : "Not logged",
          },
        },
      },
      weeklyCarbon: {
        dailyEmissions: weeklyValues,
        totalWeeklyKg,
        avgDailyKg,
      },
    });
  } catch (err) {
    logger.error("Get dashboard summary error:", err);
    res.status(500).json({ error: "Failed to generate dashboard summary" });
  }
};
