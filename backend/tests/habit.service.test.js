const {
  detectFlags,
  calculateHabitPoints,
  calculateNewStreak,
  isSameCalendarDay,
  isYesterday,
} = require("../src/services/habit/habit.service");

describe("Habit Service", () => {
  describe("detectFlags", () => {
    it("should flag low sleep when sleep is under 6 hours", () => {
      const flags = detectFlags({ sleep: { hours: 5.5 } });
      expect(flags.lowSleep).toBe(true);
    });

    it("should not flag sleep when between 6 and 9 hours", () => {
      const flags = detectFlags({ sleep: { hours: 7.5 } });
      expect(flags.lowSleep).toBe(false);
    });

    it("should flag excess screen time when over 4 hours", () => {
      const flags = detectFlags({ screenTime: { hours: 5 } });
      expect(flags.excessScreen).toBe(true);
    });

    it("should flag no exercise when duration is under 30 minutes", () => {
      const flags = detectFlags({ exercise: { durationMins: 20 } });
      expect(flags.noExercise).toBe(true);
    });

    it("should flag unhealthy meal when meat_heavy", () => {
      const flags = detectFlags({ diet: { mealType: "meat_heavy" } });
      expect(flags.unhealthyMeal).toBe(true);
    });
  });

  describe("calculateHabitPoints", () => {
    it("should award correct points for all positive habits", () => {
      const points = calculateHabitPoints({
        sleep: { hours: 8 },
        diet: { mealType: "vegan" },
        exercise: { durationMins: 45 },
        screenTime: { hours: 3 },
      });
      // 10 (sleep) + 10 (diet) + 15 (exercise >= 30m) + 5 (screen <= 4h) = 40
      expect(points).toBe(40);
    });

    it("should award 0 points when empty entry is submitted", () => {
      const points = calculateHabitPoints({});
      expect(points).toBe(0);
    });
  });

  describe("Streak Calculation", () => {
    const today = new Date("2026-09-11T12:00:00Z");

    it("should initialize streak to 1 for first time activity", () => {
      expect(calculateNewStreak(null, 0, today)).toBe(1);
    });

    it("should maintain streak if already logged today", () => {
      const sameDayEarlier = new Date("2026-09-11T08:00:00Z");
      expect(calculateNewStreak(sameDayEarlier, 5, today)).toBe(5);
    });

    it("should increment streak by 1 if logged yesterday", () => {
      const yesterday = new Date("2026-09-10T18:00:00Z");
      expect(calculateNewStreak(yesterday, 4, today)).toBe(5);
    });

    it("should reset streak to 1 if user missed yesterday", () => {
      const twoDaysAgo = new Date("2026-09-09T18:00:00Z");
      expect(calculateNewStreak(twoDaysAgo, 10, today)).toBe(1);
    });
  });
});
