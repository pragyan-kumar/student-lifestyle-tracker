const mongoose = require('mongoose');

const redemptionSchema = new mongoose.Schema({
  userId: {
    type: mongoose.Schema.Types.ObjectId,
    ref: 'User',
    required: true,
    index: true,
  },

  rewardId: { type: String, required: true },         // slug id of the reward
  rewardName: { type: String, required: true },
  cost: { type: Number, required: true },              // points spent
  perkType: {
    type: String,
    enum: ['streak_freeze', 'theme', 'skip_pass', 'badge_frame'],
    required: true,
  },

}, { timestamps: true });

redemptionSchema.index({ userId: 1, createdAt: -1 });

module.exports = mongoose.model('Redemption', redemptionSchema);
