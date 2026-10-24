const User         = require('../../models/user.model');
const PointHistory = require('../../models/pointHistory.model');
const Redemption   = require('../../models/redemption.model');
const HabitLog     = require('../../models/habitLog.model');
const CarbonLog    = require('../../models/carbonLog.model');
const { logger }   = require('../../utils/logger');

// ── Badge definitions ────────────────────────────────────────────────────────
const BADGE_DEFS = [
  {
    id: 'eco_starter',
    emoji: '🌱',
    name: 'Eco Starter',
    description: 'Logged first zero-emission commute',
    check: async (userId) => {
      const log = await CarbonLog.findOne({
        userId,
        'commute.mode': { $in: ['walk', 'bicycle'] },
      });
      return !!log;
    },
  },
  {
    id: 'streak_7',
    emoji: '🔥',
    name: '7-Day Streak',
    description: 'Completed all habits for 7 days straight',
    check: async (userId) => {
      const user = await User.findById(userId);
      return (user?.streakDays || 0) >= 7;
    },
  },
  {
    id: 'metro_hero',
    emoji: '🚇',
    name: 'Metro Hero',
    description: 'Used metro 10 times',
    check: async (userId) => {
      const count = await CarbonLog.countDocuments({
        userId,
        'commute.mode': 'metro',
      });
      return count >= 10;
    },
  },
  {
    id: 'green_eater',
    emoji: '🥗',
    name: 'Green Eater',
    description: 'Logged 5 vegetarian days',
    check: async (userId) => {
      const count = await HabitLog.countDocuments({
        userId,
        'diet.mealType': { $in: ['vegan', 'vegetarian'] },
      });
      return count >= 5;
    },
  },
  {
    id: 'sleep_champion',
    emoji: '😴',
    name: 'Sleep Champion',
    description: 'Slept 8h for 5 consecutive days',
    check: async (userId) => {
      const logs = await HabitLog.find({
        userId,
        'sleep.hours': { $gte: 8 },
      }).sort({ date: -1 }).limit(5);
      return logs.length >= 5;
    },
  },
  {
    id: 'carbon_cutter',
    emoji: '🌍',
    name: 'Carbon Cutter',
    description: 'Cut CO₂ below 2 kg for 3 days',
    check: async (userId) => {
      const logs = await CarbonLog.find({
        userId,
        totalEmissionKg: { $lt: 2 },
      }).sort({ date: -1 }).limit(3);
      return logs.length >= 3;
    },
  },
  {
    id: 'eco_legend',
    emoji: '🏆',
    name: 'Eco Legend',
    description: 'Earn 5,000 EcoPoints',
    check: async (userId) => {
      const user = await User.findById(userId);
      return (user?.points || 0) >= 5000;
    },
  },
];

// ── Reward catalogue ─────────────────────────────────────────────────────────
const REWARDS_CATALOGUE = [
  {
    id: 'streak_freeze',
    emoji: '❄️',
    name: 'Streak Freeze',
    description: 'Skip one day without losing your streak',
    cost: 30,
    perkType: 'streak_freeze',
    repeatable: true,
  },
  {
    id: 'dark_neon_theme',
    emoji: '🎨',
    name: 'Dark Neon Theme',
    description: 'Unlock an exclusive neon app theme',
    cost: 200,
    perkType: 'theme',
    repeatable: false,
  },
  {
    id: 'skip_a_habit',
    emoji: '⏭️',
    name: 'Skip-a-Habit',
    description: 'Skip one logged task for the day',
    cost: 50,
    perkType: 'skip_pass',
    repeatable: true,
  },
  {
    id: 'gold_badge_frame',
    emoji: '🌟',
    name: 'Gold Badge Frame',
    description: 'Premium badge frame for your profile',
    cost: 500,
    perkType: 'badge_frame',
    repeatable: false,
  },
];

// ── Service functions ────────────────────────────────────────────────────────

/**
 * Returns the user's wallet: total points + recent history entries.
 */
async function getWallet(userId) {
  const user = await User.findById(userId);
  const points = user?.points || 0;

  const history = await PointHistory.find({ userId })
    .sort({ createdAt: -1 })
    .limit(50);

  return {
    points,
    streakDays: user?.streakDays || 0,
    history: history.map((h) => ({
      id: h._id,
      label: h.label,
      amount: h.amount,
      balance: h.balance,
      type: h.type,
      date: h.createdAt,
    })),
  };
}

/**
 * Evaluates every badge definition against the user's data.
 * Returns all badges with earned/locked status.
 * Automatically awards newly-earned badges and grants bonus points.
 */
async function evaluateBadges(userId) {
  const user = await User.findById(userId);
  const earnedBadgeIds = user?.badges || [];

  const results = [];
  const newlyEarned = [];

  for (const badge of BADGE_DEFS) {
    const alreadyEarned = earnedBadgeIds.includes(badge.id);
    let earned = alreadyEarned;

    if (!alreadyEarned) {
      try {
        earned = await badge.check(userId);
      } catch (err) {
        logger.error(`Badge check failed for ${badge.id}:`, err);
        earned = false;
      }
    }

    if (earned && !alreadyEarned) {
      newlyEarned.push(badge);
    }

    results.push({
      id: badge.id,
      emoji: badge.emoji,
      name: badge.name,
      description: badge.description,
      earned,
    });
  }

  // Award newly-earned badges
  if (newlyEarned.length > 0) {
    const newBadgeIds = newlyEarned.map((b) => b.id);
    const bonusPoints = newlyEarned.length * 25; // 25 pts per badge

    await User.findByIdAndUpdate(userId, {
      $addToSet: { badges: { $each: newBadgeIds } },
      $inc: { points: bonusPoints },
    });

    // Record point history for each badge
    const currentUser = await User.findById(userId);
    let runningBalance = currentUser.points;
    for (const badge of newlyEarned) {
      await PointHistory.create({
        userId,
        amount: 25,
        balance: runningBalance,
        type: 'badge',
        label: `🏅 Badge earned: ${badge.name}`,
      });
    }
  }

  return { badges: results, newlyEarned: newlyEarned.map((b) => b.name) };
}

/**
 * Returns the rewards catalogue with availability info for the user.
 */
async function getRewardsCatalogue(userId) {
  const user = await User.findById(userId);
  const userPoints = user?.points || 0;

  const userRedemptions = await Redemption.find({ userId });
  const redeemedIds = new Set(userRedemptions.map((r) => r.rewardId));

  const rewards = REWARDS_CATALOGUE.map((r) => {
    const alreadyRedeemed = redeemedIds.has(r.id);
    const canAfford = userPoints >= r.cost;
    const available = r.repeatable ? canAfford : (canAfford && !alreadyRedeemed);

    return {
      id: r.id,
      emoji: r.emoji,
      name: r.name,
      description: r.description,
      cost: r.cost,
      perkType: r.perkType,
      canAfford,
      alreadyRedeemed: !r.repeatable && alreadyRedeemed,
      available,
    };
  });

  return { rewards, userPoints };
}

/**
 * Redeems a reward — deducts points, grants perk, records history.
 */
async function redeemReward(userId, rewardId) {
  const rewardDef = REWARDS_CATALOGUE.find((r) => r.id === rewardId);
  if (!rewardDef) {
    throw Object.assign(new Error('Reward not found'), { status: 404 });
  }

  const user = await User.findById(userId);
  if (!user) {
    throw Object.assign(new Error('User not found'), { status: 404 });
  }

  if ((user.points || 0) < rewardDef.cost) {
    throw Object.assign(new Error('Insufficient points'), { status: 400 });
  }

  // Check if non-repeatable reward already redeemed
  if (!rewardDef.repeatable) {
    const existing = await Redemption.findOne({ userId, rewardId });
    if (existing) {
      throw Object.assign(new Error('Reward already redeemed'), { status: 400 });
    }
  }

  // Deduct points
  user.points = (user.points || 0) - rewardDef.cost;

  // Apply perk
  switch (rewardDef.perkType) {
    case 'streak_freeze':
      user.streakFreezes = (user.streakFreezes || 0) + 1;
      break;
    case 'theme':
      if (!user.unlockedThemes) user.unlockedThemes = [];
      if (!user.unlockedThemes.includes(rewardId)) {
        user.unlockedThemes.push(rewardId);
      }
      break;
    case 'skip_pass':
      user.skipPasses = (user.skipPasses || 0) + 1;
      break;
    case 'badge_frame':
      if (!user.unlockedThemes) user.unlockedThemes = [];
      if (!user.unlockedThemes.includes(rewardId)) {
        user.unlockedThemes.push(rewardId);
      }
      break;
  }

  await user.save();

  // Record redemption
  await Redemption.create({
    userId,
    rewardId,
    rewardName: rewardDef.name,
    cost: rewardDef.cost,
    perkType: rewardDef.perkType,
  });

  // Record point history
  await PointHistory.create({
    userId,
    amount: -rewardDef.cost,
    balance: user.points,
    type: 'redeem',
    label: `🎁 Redeemed: ${rewardDef.name}`,
  });

  return {
    success: true,
    rewardName: rewardDef.name,
    pointsSpent: rewardDef.cost,
    remainingPoints: user.points,
    perkType: rewardDef.perkType,
  };
}

/**
 * Returns a simple points-based leaderboard.
 */
async function getLeaderboard(limit = 20) {
  const users = await User.find({})
    .select('name points streakDays badges avatar')
    .sort({ points: -1 })
    .limit(limit);

  return users.map((u, i) => ({
    rank: i + 1,
    name: u.name,
    points: u.points || 0,
    streakDays: u.streakDays || 0,
    badgesCount: u.badges?.length || 0,
    avatar: u.avatar || '',
  }));
}

/**
 * Records a point history entry (used by habit & carbon controllers).
 */
async function recordPoints(userId, { amount, type, label, refModel, refId }) {
  const user = await User.findById(userId);
  const balance = (user?.points || 0);
  await PointHistory.create({
    userId,
    amount,
    balance,
    type,
    label,
    refModel: refModel || null,
    refId: refId || null,
  });
}

module.exports = {
  getWallet,
  evaluateBadges,
  getRewardsCatalogue,
  redeemReward,
  getLeaderboard,
  recordPoints,
  BADGE_DEFS,
  REWARDS_CATALOGUE,
};
