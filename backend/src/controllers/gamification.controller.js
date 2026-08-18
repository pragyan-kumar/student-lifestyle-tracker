exports.getWallet = async (req, res) => res.json({ points: 0, history: [] });
exports.getBadges = async (req, res) => res.json({ badges: [] });
exports.getRewards = async (req, res) => res.json({ rewards: [] });
exports.redeemReward = async (req, res) => res.json({ message: 'Redeemed' });
exports.getLeaderboard = async (req, res) => res.json({ leaderboard: [] });
