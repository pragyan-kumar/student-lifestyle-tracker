const gamService = require('../services/gamification/gamification.service');
const { logger }  = require('../utils/logger');

// GET /api/v1/gamification/wallet — points balance + history
exports.getWallet = async (req, res) => {
  try {
    const wallet = await gamService.getWallet(req.user._id);
    res.json(wallet);
  } catch (err) {
    logger.error('Get wallet error:', err);
    res.status(500).json({ error: 'Failed to fetch wallet' });
  }
};

// GET /api/v1/gamification/badges — all badges (earned + locked)
exports.getBadges = async (req, res) => {
  try {
    const result = await gamService.evaluateBadges(req.user._id);
    res.json(result);
  } catch (err) {
    logger.error('Get badges error:', err);
    res.status(500).json({ error: 'Failed to fetch badges' });
  }
};

// GET /api/v1/gamification/rewards — redeemable rewards catalogue
exports.getRewards = async (req, res) => {
  try {
    const catalogue = await gamService.getRewardsCatalogue(req.user._id);
    res.json(catalogue);
  } catch (err) {
    logger.error('Get rewards error:', err);
    res.status(500).json({ error: 'Failed to fetch rewards' });
  }
};

// POST /api/v1/gamification/redeem — redeem a reward by ID
exports.redeemReward = async (req, res) => {
  try {
    const { rewardId } = req.body;
    if (!rewardId) {
      return res.status(400).json({ error: 'rewardId is required' });
    }

    const result = await gamService.redeemReward(req.user._id, rewardId);
    logger.info(`User ${req.user._id} redeemed ${result.rewardName} for ${result.pointsSpent} pts`);
    res.json(result);
  } catch (err) {
    const status = err.status || 500;
    logger.error('Redeem error:', err);
    res.status(status).json({ error: err.message || 'Failed to redeem reward' });
  }
};

// GET /api/v1/gamification/leaderboard
exports.getLeaderboard = async (req, res) => {
  try {
    const limit = parseInt(req.query.limit) || 20;
    const leaderboard = await gamService.getLeaderboard(limit);
    res.json({ leaderboard });
  } catch (err) {
    logger.error('Get leaderboard error:', err);
    res.status(500).json({ error: 'Failed to fetch leaderboard' });
  }
};
