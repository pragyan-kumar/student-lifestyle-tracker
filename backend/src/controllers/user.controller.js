const User       = require('../models/user.model');
const HabitLog   = require('../models/habitLog.model');
const CarbonLog  = require('../models/carbonLog.model');
const { logger } = require('../utils/logger');

// GET /api/v1/users/profile
exports.getProfile = async (req, res) => {
  try {
    const user = await User.findById(req.user._id);
    if (!user) return res.status(404).json({ error: 'User not found' });

    // Aggregate stats for user profile
    const [totalHabitLogs, carbonStats] = await Promise.all([
      HabitLog.countDocuments({ userId: req.user._id }),
      CarbonLog.aggregate([
        { $match: { userId: user._id } },
        {
          $group: {
            _id: null,
            totalLogs: { $sum: 1 },
            totalEmission: { $sum: '$totalEmissionKg' },
            totalSaved: { $sum: '$savedVsAverage' },
          },
        },
      ]),
    ]);

    const stats = {
      totalHabitLogs,
      totalCarbonLogs: carbonStats[0]?.totalLogs || 0,
      totalCarbonKg: parseFloat((carbonStats[0]?.totalEmission || 0).toFixed(2)),
      totalSavedKg: parseFloat(Math.max(0, carbonStats[0]?.totalSaved || 0).toFixed(2)),
      streakDays: user.streakDays || 0,
      points: user.points || 0,
      badgesCount: user.badges?.length || 0,
    };

    res.json({ profile: user, stats });
  } catch (err) {
    logger.error('Get profile error:', err);
    res.status(500).json({ error: 'Failed to fetch profile' });
  }
};

// PUT /api/v1/users/profile
exports.updateProfile = async (req, res) => {
  try {
    const allowedUpdates = ['name', 'collegeName', 'department', 'batch', 'avatar'];
    const updates = {};

    for (const key of allowedUpdates) {
      if (req.body[key] !== undefined) {
        updates[key] = req.body[key];
      }
    }

    const updatedUser = await User.findByIdAndUpdate(
      req.user._id,
      { $set: updates },
      { new: true, runValidators: true }
    );

    if (!updatedUser) return res.status(404).json({ error: 'User not found' });

    logger.info(`Profile updated for user: ${req.user._id}`);
    res.json({ profile: updatedUser });
  } catch (err) {
    logger.error('Update profile error:', err);
    res.status(500).json({ error: 'Failed to update profile' });
  }
};

// DELETE /api/v1/users/account
exports.deleteAccount = async (req, res) => {
  try {
    const userId = req.user._id;

    // Cascade delete user habit logs and carbon logs
    await Promise.all([
      HabitLog.deleteMany({ userId }),
      CarbonLog.deleteMany({ userId }),
      User.findByIdAndDelete(userId),
    ]);

    logger.info(`Account and related data deleted for user: ${userId}`);
    res.json({ message: 'Account and associated data deleted successfully' });
  } catch (err) {
    logger.error('Delete account error:', err);
    res.status(500).json({ error: 'Failed to delete account' });
  }
};
