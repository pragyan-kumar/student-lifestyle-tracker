const CarbonLog  = require('../models/carbonLog.model');
const User       = require('../models/user.model');
const { logger } = require('../utils/logger');
const { computeCarbonEmission, calculateCarbonPoints } = require('../services/carbon/carbon.service');
const { callCarbonInterfaceAPI } = require('../services/carbon/carbonInterface.service');

// Peer average daily emissions (kg CO₂) — used for comparison
const PEER_AVERAGE_KG = 5.8;

// GET /api/v1/carbon
exports.getLogs = async (req, res) => {
  try {
    const logs = await CarbonLog.find({ userId: req.user._id }).sort({ date: -1 }).limit(30);
    res.json({ logs });
  } catch (err) {
    res.status(500).json({ error: 'Failed to fetch carbon logs' });
  }
};

// POST /api/v1/carbon
exports.createLog = async (req, res) => {
  try {
    const { commute, food, devices } = req.body;

    // Compute emissions locally using standardised factors
    const commuteEmission = computeCarbonEmission.commute(commute);
    const foodEmission    = computeCarbonEmission.food(food);
    const deviceEmission  = computeCarbonEmission.devices(devices);
    const total           = commuteEmission + foodEmission + deviceEmission;

    // Optionally call Carbon Interface API for enriched data
    let carbonApiData = null;
    if (commute?.mode && commute?.distanceKm) {
      carbonApiData = await callCarbonInterfaceAPI(commute).catch(() => null);
    }

    const pointsEarned = calculateCarbonPoints(total);

    const log = await CarbonLog.create({
      userId: req.user._id,
      commute : { ...commute, emissionKg: commuteEmission },
      food    : { ...food,    emissionKg: foodEmission    },
      devices : { ...devices, emissionKg: deviceEmission  },
      totalEmissionKg  : total,
      savedVsAverage   : PEER_AVERAGE_KG - total,
      carbonApiData,
      pointsEarned,
    });

    // Award points
    await User.findByIdAndUpdate(req.user._id, { $inc: { points: pointsEarned } });

    res.status(201).json({ log, pointsEarned, totalEmissionKg: total });
  } catch (err) {
    logger.error('Create carbon log error:', err);
    res.status(500).json({ error: 'Failed to create carbon log' });
  }
};

// GET /api/v1/carbon/today
exports.getToday = async (req, res) => {
  try {
    const start = new Date(); start.setHours(0,0,0,0);
    const end   = new Date(); end.setHours(23,59,59,999);
    const log = await CarbonLog.findOne({ userId: req.user._id, date: { $gte: start, $lte: end } });
    res.json({ log });
  } catch (err) {
    res.status(500).json({ error: 'Failed to get today\'s data' });
  }
};

// GET /api/v1/carbon/weekly
exports.getWeekly = async (req, res) => {
  try {
    const sevenDaysAgo = new Date(Date.now() - 7 * 24 * 60 * 60 * 1000);
    const logs = await CarbonLog.find({ userId: req.user._id, date: { $gte: sevenDaysAgo } }).sort({ date: 1 });
    const weeklyTotal = logs.reduce((s, l) => s + l.totalEmissionKg, 0);
    res.json({ logs, weeklyTotal, avgDaily: weeklyTotal / (logs.length || 1) });
  } catch (err) {
    res.status(500).json({ error: 'Failed to get weekly data' });
  }
};

// GET /api/v1/carbon/compare
exports.compareWithAverage = async (req, res) => {
  try {
    const logs = await CarbonLog.find({ userId: req.user._id }).sort({ date: -1 }).limit(7);
    const userAvg = logs.reduce((s, l) => s + l.totalEmissionKg, 0) / (logs.length || 1);
    res.json({
      userAvgDaily  : userAvg,
      peerAvgDaily  : PEER_AVERAGE_KG,
      differenceKg  : PEER_AVERAGE_KG - userAvg,
      percentBetter : ((PEER_AVERAGE_KG - userAvg) / PEER_AVERAGE_KG * 100).toFixed(1),
    });
  } catch (err) {
    res.status(500).json({ error: 'Comparison failed' });
  }
};

// PUT /api/v1/carbon/:id
exports.updateLog = async (req, res) => {
  try {
    const log = await CarbonLog.findOneAndUpdate({ _id: req.params.id, userId: req.user._id }, req.body, { new: true });
    if (!log) return res.status(404).json({ error: 'Log not found' });
    res.json({ log });
  } catch (err) {
    res.status(500).json({ error: 'Update failed' });
  }
};
