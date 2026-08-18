const express      = require('express');
const router       = express.Router();
const insightCtrl  = require('../controllers/insight.controller');
const { authenticate } = require('../middleware/auth.middleware');

router.use(authenticate);

// GET /api/v1/insights          — get latest personalised insights from ML model
router.get('/',          insightCtrl.getInsights);

// POST /api/v1/insights/trigger — manually trigger ML re-analysis
router.post('/trigger',  insightCtrl.triggerAnalysis);

module.exports = router;
