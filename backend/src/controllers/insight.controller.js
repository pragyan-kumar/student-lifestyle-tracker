const HabitLog = require("../models/habitLog.model");
const CarbonLog = require("../models/carbonLog.model");
const User = require("../models/user.model");
const axios = require("axios");
const { logger } = require("../utils/logger");

const AI_URL =
  process.env.AI_URL || process.env.ML_SERVICE_URL || "http://localhost:8000";

/**
 * Aggregate the last 7 days of habit + carbon logs for a user
 * and return the feature vector expected by the ML service.
 */
async function buildFeatureVector(userId) {
  const sevenDaysAgo = new Date(Date.now() - 7 * 24 * 60 * 60 * 1000);

  const [habitLogs, carbonLogs, user] = await Promise.all([
    HabitLog.find({ userId, date: { $gte: sevenDaysAgo } }),
    CarbonLog.find({ userId, date: { $gte: sevenDaysAgo } }),
    User.findById(userId),
  ]);

  const n = habitLogs.length || 1; // avoid /0

  // ── Sleep ────────────────────────────────────────────────────────────────
  const totalSleep = habitLogs.reduce((s, l) => s + (l.sleep?.hours || 0), 0);
  const avg_sleep_hours = parseFloat((totalSleep / n).toFixed(2));

  // ── Exercise ─────────────────────────────────────────────────────────────
  const totalExercise = habitLogs.reduce(
    (s, l) => s + (l.exercise?.durationMins || 0),
    0,
  );
  const avg_exercise_mins = parseFloat((totalExercise / n).toFixed(2));

  // ── Screen time ──────────────────────────────────────────────────────────
  const totalScreen = habitLogs.reduce(
    (s, l) => s + (l.screenTime?.hours || 0),
    0,
  );
  const avg_screen_hours = parseFloat((totalScreen / n).toFixed(2));

  // ── Meal type (most common) ──────────────────────────────────────────────
  const mealCounts = {};
  habitLogs.forEach((l) => {
    const m = l.diet?.mealType;
    if (m) mealCounts[m] = (mealCounts[m] || 0) + 1;
  });
  const meal_type =
    Object.keys(mealCounts).sort((a, b) => mealCounts[b] - mealCounts[a])[0] ||
    "mixed";

  // ── Carbon ───────────────────────────────────────────────────────────────
  const nc = carbonLogs.length || 1;
  const totalCarbon = carbonLogs.reduce(
    (s, l) => s + (l.totalEmissionKg || 0),
    0,
  );
  const avg_carbon_kg = parseFloat((totalCarbon / nc).toFixed(2));

  // ── Streak ───────────────────────────────────────────────────────────────
  const streak_days = user?.streakDays || 0;

  return {
    avg_sleep_hours,
    avg_exercise_mins,
    avg_screen_hours,
    meal_type,
    avg_carbon_kg,
    streak_days,
    days_of_data: habitLogs.length,
  };
}

// GET /api/v1/insights
exports.getInsights = async (req, res) => {
  try {
    const features = await buildFeatureVector(req.user._id);
    logger.info(`[ML] Feature vector for ${req.user._id}:`, features);

    let insights = [];
    let source = "ml";

    try {
      // Call ML FastAPI service
      const { data } = await axios.post(`${AI_URL}/predict`, features, {
        timeout: 5000,
      });
      insights = data;
      logger.info(`[ML] Received ${insights.length} insights from ML service`);
    } catch (mlErr) {
      // ML service down — fall back to rule-based engine inline
      logger.warn(
        `[ML] Service unavailable (${mlErr.message}), using rule-based fallback`,
      );
      source = "rules";
      insights = generateRuleBasedInsights(features);
    }

    res.json({
      insights,
      source,
      features, // expose so Flutter can show "based on your last X days"
      generatedAt: new Date().toISOString(),
    });
  } catch (err) {
    logger.error("Get insights error:", err);
    res.status(500).json({ error: "Failed to generate insights" });
  }
};

// POST /api/v1/insights/trigger — manual re-analysis (same as GET but forces fresh data)
exports.triggerAnalysis = async (req, res) => {
  try {
    const features = await buildFeatureVector(req.user._id);
    let insights = [];
    let source = "ml";

    try {
      const { data } = await axios.post(`${AI_URL}/predict`, features, {
        timeout: 5000,
      });
      insights = data;
    } catch {
      source = "rules";
      insights = generateRuleBasedInsights(features);
    }

    res.json({
      insights,
      source,
      features,
      generatedAt: new Date().toISOString(),
      triggered: true,
    });
  } catch (err) {
    logger.error("Trigger analysis error:", err);
    res.status(500).json({ error: "Failed to trigger analysis" });
  }
};

// ── Rule-based fallback (mirrors the Python predictor logic) ──────────────────
function generateRuleBasedInsights(f) {
  const insights = [];
  const {
    avg_sleep_hours: sleep = 7,
    avg_exercise_mins: exercise = 30,
    avg_screen_hours: screen = 4,
    meal_type: meal = "mixed",
    avg_carbon_kg: carbon = 4,
    streak_days: streak = 0,
    days_of_data: days = 1,
  } = f || {};

  // 1. Lifestyle Profile & Eco Health estimation
  let persona = "Balanced Achiever";
  let ecoScore = 70;
  if (carbon < 3.2 && (meal === "vegan" || meal === "vegetarian")) {
    persona = "Eco Champion";
    ecoScore = 85;
  } else if (sleep < 6 && screen >= 6) {
    persona = "Digital Burnout";
    ecoScore = 40;
  } else if (sleep < 6) {
    persona = "Sleep Deprived Scholar";
    ecoScore = 50;
  } else if (exercise < 20 && carbon > 5) {
    persona = "Sedentary High-Emission";
    ecoScore = 35;
  }

  insights.push({
    category: "AI Persona",
    priority: 1,
    title: `Profile: ${persona} (Eco Score: ${ecoScore}/100)`,
    description: `Analyzed lifestyle habits over ${days} day(s) of records with an estimated Eco Index of ${ecoScore}/100.`,
    action: "Explore personalized recommendations",
  });

  // 2. Sleep
  if (sleep < 6) {
    insights.push({
      category: "Sleep",
      priority: 1,
      title: "Critical Sleep Deficit Detected",
      description: `Your average sleep is ${sleep.toFixed(1)}h — well below the 6–9h healthy range. This increases burnout and exam fatigue risk.`,
      action: "Set a sleep reminder for 10:30 PM",
    });
  } else if (sleep < 7) {
    insights.push({
      category: "Sleep",
      priority: 2,
      title: "Slightly Below Optimal Sleep",
      description: `You're averaging ${sleep.toFixed(1)}h. Aim for 7–8h during exam periods to maintain focus and memory retention.`,
      action: "Adjust bedtime by 30 min",
    });
  } else {
    insights.push({
      category: "Sleep",
      priority: 4,
      title: "Optimal Rest Zone (7–9h)",
      description: `Averaging ${sleep.toFixed(1)}h of rest. Consistent sleep hygiene boosts cognitive retention and mood stability.`,
      action: "Keep wake time consistent",
    });
  }

  // 3. Exercise
  if (exercise < 20) {
    insights.push({
      category: "Exercise",
      priority: 1,
      title: "Almost No Physical Activity",
      description: `Only ${Math.round(exercise)} mins/day on average. Even a 20-min walk boosts mood and academic focus significantly.`,
      action: "Log a 20-min walk today",
    });
  } else if (exercise < 30) {
    insights.push({
      category: "Exercise",
      priority: 3,
      title: "Just Below the 30-Min Target",
      description: `You're at ${Math.round(exercise)} min/day. Adding 10 more minutes earns 15 bonus EcoPoints.`,
      action: "Add 10-min stretch",
    });
  } else {
    insights.push({
      category: "Exercise",
      priority: 4,
      title: "Active Target Achieved! (>30 min/day)",
      description: `Averaging ${Math.round(exercise)} active minutes daily! Regular activity lowers exam stress and elevates focus.`,
      action: "Maintain daily activity streak",
    });
  }

  // 4. Carbon & Diet
  if (carbon > 5) {
    const savings = ((carbon - 2) * 0.3).toFixed(1);
    insights.push({
      category: "Carbon",
      priority: 1,
      title: "High Carbon Footprint This Week",
      description: `Daily average: ${carbon.toFixed(1)} kg CO₂. Switching 2 auto rides to metro could save ~${savings} kg CO₂/week.`,
      action: "Plan metro commute",
    });
  } else if (carbon > 0) {
    insights.push({
      category: "Carbon",
      priority: 4,
      title: "Low Campus Carbon Footprint",
      description: `Emitting ${carbon.toFixed(1)} kg CO₂/day places you among the greenest student percentiles.`,
      action: "Check campus leaderboard ranking",
    });
  }

  if (meal === "meat_heavy") {
    insights.push({
      category: "Diet",
      priority: 2,
      title: "High-Emission Diet Pattern",
      description:
        "Meat-heavy meals contribute ~7.2 kg CO₂/day. 2 vegetarian days/week saves ~9.4 kg CO₂ monthly.",
      action: "Try vegetarian tomorrow",
    });
  } else if (meal === "vegan" || meal === "vegetarian") {
    insights.push({
      category: "Diet",
      priority: 4,
      title: "Eco-Friendly Plant-Forward Diet",
      description: `Your ${meal} meal choice saves ~3.5 kg CO₂ daily compared to meat-heavy student diets.`,
      action: "Pair with 8 glasses of water",
    });
  } else {
    insights.push({
      category: "Diet",
      priority: 3,
      title: "Try 2 Vegetarian Days",
      description: `Your mixed diet emits ~4.5 kg CO₂/day. Going vegetarian 2 days saves ~4 kg CO₂ weekly.`,
      action: "Explore vegetarian meals",
    });
  }

  // 5. Screen Time
  if (screen > 6) {
    insights.push({
      category: "Screen Time",
      priority: 2,
      title: "Excess Screen Time Alert",
      description: `Averaging ${screen.toFixed(1)}h/day of screen time — high usage correlates with poor sleep onset.`,
      action: "Enable screen-off reminder",
    });
  }

  // 6. Streak
  if (streak === 0) {
    insights.push({
      category: "Rewards",
      priority: 2,
      title: "Start Your Streak Today!",
      description: "Log today's habits to ignite your Day 1 streak and claim 20 bonus EcoPoints.",
      action: "View today's checklist",
    });
  } else if (streak >= 5 && streak < 7) {
    insights.push({
      category: "Rewards",
      priority: 2,
      title: `${7 - streak} Days Away from a 7-Day Badge!`,
      description: `You're on a ${streak}-day streak! Keep going to unlock the 7-Day Streak badge and earn 50 bonus points.`,
      action: "View today's checklist",
    });
  }

  insights.sort((a, b) => a.priority - b.priority);
  return insights.slice(0, 4);
}
