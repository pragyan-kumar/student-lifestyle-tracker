const express = require("express");
const router = express.Router();
const carbonCtrl = require("../controllers/carbon.controller");
const { authenticate } = require("../middleware/auth.middleware");

router.use(authenticate);

// GET  /api/v1/carbon           — list logs
router.get("/", carbonCtrl.getLogs);

// POST /api/v1/carbon           — log today's carbon footprint
router.post("/", carbonCtrl.createLog);

// GET  /api/v1/carbon/today     — today's computed footprint
router.get("/today", carbonCtrl.getToday);

// GET  /api/v1/carbon/weekly    — 7-day carbon trend
router.get("/weekly", carbonCtrl.getWeekly);

// GET  /api/v1/carbon/compare   — user vs peer average
router.get("/compare", carbonCtrl.compareWithAverage);

// PUT  /api/v1/carbon/sync      — upsert today's running totals
router.put("/sync", carbonCtrl.syncToday);

// PUT  /api/v1/carbon/:id
router.put("/:id", carbonCtrl.updateLog);

module.exports = router;
