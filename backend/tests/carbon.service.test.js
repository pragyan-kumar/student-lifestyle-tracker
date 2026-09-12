const {
  computeCarbonEmission,
  calculateCarbonPoints,
  COMMUTE_FACTORS,
  FOOD_FACTORS,
} = require('../src/services/carbon/carbon.service');

describe('Carbon Service', () => {
  describe('computeCarbonEmission.commute', () => {
    it('should calculate zero emissions for walking or cycling', () => {
      expect(computeCarbonEmission.commute({ mode: 'walk', distanceKm: 5 })).toBe(0);
      expect(computeCarbonEmission.commute({ mode: 'bicycle', distanceKm: 10 })).toBe(0);
    });

    it('should accurately calculate metro emissions (0.041 kg/km)', () => {
      const emission = computeCarbonEmission.commute({ mode: 'metro', distanceKm: 20 });
      expect(emission).toBeCloseTo(0.82, 2);
    });

    it('should calculate bus emissions (0.089 kg/km)', () => {
      const emission = computeCarbonEmission.commute({ mode: 'bus', distanceKm: 15 });
      expect(emission).toBeCloseTo(1.335, 3);
    });
  });

  describe('computeCarbonEmission.food', () => {
    it('should return correct standard food factors', () => {
      expect(computeCarbonEmission.food({ mealType: 'vegan' })).toBe(FOOD_FACTORS.vegan);
      expect(computeCarbonEmission.food({ mealType: 'vegetarian' })).toBe(FOOD_FACTORS.vegetarian);
      expect(computeCarbonEmission.food({ mealType: 'meat_heavy' })).toBe(FOOD_FACTORS.meat_heavy);
    });
  });

  describe('calculateCarbonPoints', () => {
    it('should award 30 points for low emissions (< 2 kg)', () => {
      expect(calculateCarbonPoints(1.5)).toBe(30);
    });

    it('should award 20 points for moderate emissions (2 - 4 kg)', () => {
      expect(calculateCarbonPoints(3.2)).toBe(20);
    });

    it('should award 10 points for average emissions (4 - 6 kg)', () => {
      expect(calculateCarbonPoints(5.0)).toBe(10);
    });

    it('should award 0 points for excessive emissions (> 6 kg)', () => {
      expect(calculateCarbonPoints(7.5)).toBe(0);
    });
  });
});
