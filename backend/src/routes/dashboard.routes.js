const express = require("express");
const router = express.Router();
const dashboardCtrl = require("../controllers/dashboard.controller");
const { authenticate } = require("../middleware/auth.middleware");

router.use(authenticate);

// GET /api/v1/dashboard/summary — unified dashboard metrics
router.get("/summary", dashboardCtrl.getSummary);

module.exports = router;
