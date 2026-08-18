const mongoose = require('mongoose');

const carbonLogSchema = new mongoose.Schema({
  userId : { type: mongoose.Schema.Types.ObjectId, ref: 'User', required: true, index: true },
  date   : { type: Date, required: true, default: Date.now },

  // ── Commute ─────────────────────────────────────────────────────────────
  commute: {
    mode        : { type: String, enum: ['walk', 'bicycle', 'metro', 'bus', 'auto', 'bike', 'car_petrol', 'car_diesel'] },
    distanceKm  : { type: Number, min: 0 },
    emissionKg  : { type: Number, default: 0 },  // computed: mode factor × distance
  },

  // ── Food ────────────────────────────────────────────────────────────────
  food: {
    mealType    : { type: String, enum: ['vegan', 'vegetarian', 'mixed', 'meat_heavy'] },
    emissionKg  : { type: Number, default: 0 },  // lookup from emission factors
  },

  // ── Device / Energy ──────────────────────────────────────────────────────
  devices: {
    screenHours    : { type: Number, min: 0, max: 24 },
    applianceHours : { type: Number, min: 0, max: 24 },
    emissionKg     : { type: Number, default: 0 },
  },

  // ── Totals ──────────────────────────────────────────────────────────────
  totalEmissionKg : { type: Number, default: 0 },  // sum of all above
  savedVsAverage  : { type: Number, default: 0 },  // positive = below avg

  // Carbon Interface API response cache
  carbonApiData   : { type: mongoose.Schema.Types.Mixed },

  pointsEarned    : { type: Number, default: 0 },
}, { timestamps: true });

carbonLogSchema.index({ userId: 1, date: -1 });

module.exports = mongoose.model('CarbonLog', carbonLogSchema);
