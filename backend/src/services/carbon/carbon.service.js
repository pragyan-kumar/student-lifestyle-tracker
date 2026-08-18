/**
 * Carbon emission computation service.
 * Uses standardised emission factors aligned with Carbon Interface API defaults.
 */

// kg CO₂ per km
const COMMUTE_FACTORS = {
  walk       : 0.000,
  bicycle    : 0.000,
  metro      : 0.041,
  bus        : 0.089,
  auto       : 0.143,
  bike       : 0.113,
  car_petrol : 0.192,
  car_diesel : 0.171,
};

// kg CO₂ per day from food
const FOOD_FACTORS = {
  vegan      : 1.5,
  vegetarian : 2.5,
  mixed      : 4.5,
  meat_heavy : 7.2,
};

// kg CO₂ per screen/device hour
const DEVICE_FACTOR = 0.06;   // ~60g per hour (laptop + charger + misc)

const computeCarbonEmission = {
  commute({ mode, distanceKm } = {}) {
    if (!mode || !distanceKm) return 0;
    const factor = COMMUTE_FACTORS[mode] ?? 0;
    return parseFloat((factor * distanceKm).toFixed(3));
  },

  food({ mealType } = {}) {
    if (!mealType) return 0;
    return FOOD_FACTORS[mealType] ?? 0;
  },

  devices({ screenHours = 0, applianceHours = 0 } = {}) {
    return parseFloat(((screenHours + applianceHours) * DEVICE_FACTOR).toFixed(3));
  },
};

/**
 * Awards more points for lower daily carbon totals.
 * < 2 kg  → 30 pts   "Carbon Hero"
 * 2–4 kg  → 20 pts   "Good job"
 * 4–6 kg  → 10 pts   "Average"
 * > 6 kg  →  0 pts   "Exceeded"
 */
const calculateCarbonPoints = (totalKg) => {
  if (totalKg < 2)  return 30;
  if (totalKg < 4)  return 20;
  if (totalKg < 6)  return 10;
  return 0;
};

module.exports = { computeCarbonEmission, calculateCarbonPoints, COMMUTE_FACTORS, FOOD_FACTORS };
