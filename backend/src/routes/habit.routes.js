const express = require("express");
const router = express.Router();
const habitCtrl = require("../controllers/habit.controller");
const { authenticate } = require("../middleware/auth.middleware");

// All routes require authentication
router.use(authenticate);

// GET  /api/v1/habits           — list logs (with ?date=YYYY-MM-DD or ?from=&to=)
router.get("/", habitCtrl.getLogs);

// GET  /api/v1/habits/today     — today's logged checklist and completion
router.get("/today", habitCtrl.getToday);

// POST /api/v1/habits/checklist/toggle — toggle single habit in checklist
router.post("/checklist/toggle", habitCtrl.toggleChecklist);

// POST /api/v1/habits           — create today's habit log
router.post("/", habitCtrl.createLog);

// GET  /api/v1/habits/streak    — current streak info
router.get("/streak", habitCtrl.getStreak);

// GET  /api/v1/habits/summary   — weekly summary stats
router.get("/summary", habitCtrl.getSummary);

// PUT  /api/v1/habits/:id       — update an existing log
router.put("/:id", habitCtrl.updateLog);

// DELETE /api/v1/habits/:id
router.delete("/:id", habitCtrl.deleteLog);

module.exports = router;
