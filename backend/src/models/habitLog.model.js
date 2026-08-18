const mongoose = require('mongoose');

const habitLogSchema = new mongoose.Schema({
  userId : { type: mongoose.Schema.Types.ObjectId, ref: 'User', required: true, index: true },
  date   : { type: Date, required: true, default: Date.now },

  // ── Sleep ──────────────────────────────────────────────────────────────
  sleep: {
    hours       : { type: Number, min: 0, max: 24 },
    quality     : { type: String, enum: ['poor', 'fair', 'good', 'excellent'] },
    bedtime     : { type: String },   // HH:mm format
    wakeTime    : { type: String },
  },

  // ── Diet ───────────────────────────────────────────────────────────────
  diet: {
    mealType    : { type: String, enum: ['vegan', 'vegetarian', 'mixed', 'meat_heavy'] },
    mealsLogged : { type: Number, min: 0, max: 6 },
    waterGlasses: { type: Number, min: 0, max: 20 },
    notes       : { type: String, maxlength: 200 },
  },

  // ── Exercise ───────────────────────────────────────────────────────────
  exercise: {
    durationMins: { type: Number, min: 0, max: 300 },
    type        : { type: String, enum: ['walk', 'run', 'gym', 'yoga', 'sport', 'other'] },
    completed   : { type: Boolean, default: false },
  },

  // ── Screen Time ────────────────────────────────────────────────────────
  screenTime: {
    hours: { type: Number, min: 0, max: 24 },
  },

  // ── Computed flags ────────────────────────────────────────────────────
  flags: {
    lowSleep      : { type: Boolean, default: false },  // < 6h
    unhealthyMeal : { type: Boolean, default: false },
    noExercise    : { type: Boolean, default: false },
    excessScreen  : { type: Boolean, default: false },  // > 4h
  },

  pointsEarned : { type: Number, default: 0 },
}, { timestamps: true });

// Compound index for fast per-user date queries
habitLogSchema.index({ userId: 1, date: -1 });

module.exports = mongoose.model('HabitLog', habitLogSchema);
