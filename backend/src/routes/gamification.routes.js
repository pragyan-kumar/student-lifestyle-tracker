const express       = require('express');
const router        = express.Router();
const gamCtrl       = require('../controllers/gamification.controller');
const { authenticate } = require('../middleware/auth.middleware');

router.use(authenticate);

// GET  /api/v1/gamification/wallet   — points balance + history
router.get('/wallet',          gamCtrl.getWallet);

// GET  /api/v1/gamification/badges   — all badges (earned + locked)
router.get('/badges',          gamCtrl.getBadges);

// GET  /api/v1/gamification/rewards  — redeemable rewards catalogue
router.get('/rewards',         gamCtrl.getRewards);

// POST /api/v1/gamification/redeem   — redeem a reward by ID
router.post('/redeem',         gamCtrl.redeemReward);

// GET  /api/v1/gamification/leaderboard
router.get('/leaderboard',     gamCtrl.getLeaderboard);

module.exports = router;
