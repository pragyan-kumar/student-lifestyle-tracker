const mongoose = require('mongoose');

const pointHistorySchema = new mongoose.Schema({
  userId: {
    type: mongoose.Schema.Types.ObjectId,
    ref: 'User',
    required: true,
    index: true,
  },

  // Amount of points (positive = earned, negative = spent)
  amount: { type: Number, required: true },

  // Running balance after this transaction
  balance: { type: Number, required: true },

  // Category of the transaction
  type: {
    type: String,
    enum: ['habit', 'carbon', 'streak', 'badge', 'redeem'],
    required: true,
  },

  // Human-readable label for the UI
  label: { type: String, required: true },

  // Optional reference to the source document (habit log, carbon log, reward)
  refModel: { type: String, enum: ['HabitLog', 'CarbonLog', 'Reward', null] },
  refId: { type: mongoose.Schema.Types.ObjectId },

}, { timestamps: true });

pointHistorySchema.index({ userId: 1, createdAt: -1 });

module.exports = mongoose.model('PointHistory', pointHistorySchema);
