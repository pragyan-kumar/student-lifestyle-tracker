require("dotenv").config();
const express = require("express");
const cors = require("cors");
const helmet = require("helmet");
const morgan = require("morgan");
const rateLimit = require("express-rate-limit");

const authRoutes = require("./routes/auth.routes");
const habitRoutes = require("./routes/habit.routes");
const carbonRoutes = require("./routes/carbon.routes");
const insightRoutes = require("./routes/insight.routes");
const gamificationRoutes = require("./routes/gamification.routes");
const userRoutes = require("./routes/user.routes");
const dashboardRoutes = require("./routes/dashboard.routes");
const { connectDB } = require("./config/db");
const { logger } = require("./utils/logger");

const app = express();
const PORT = process.env.PORT || 5000;

// ── Security & Middleware ────────────────────────────────────────────────────
app.use(helmet({ crossOriginResourcePolicy: false }));

const allowedOrigins = process.env.ALLOWED_ORIGINS
  ? process.env.ALLOWED_ORIGINS.split(",").map((o) => o.trim())
  : [];

app.use(
  cors({
    origin: (origin, callback) => {
      // Allow requests with no origin (mobile apps, curl, Postman)
      if (!origin) return callback(null, true);
      // In development, allow all localhost origins dynamically
      if (
        process.env.NODE_ENV === "development" &&
        /^http:\/\/(localhost|127\.0\.0\.1)(:\d+)?$/.test(origin)
      ) {
        return callback(null, true);
      }
      if (allowedOrigins.includes(origin)) return callback(null, true);
      return callback(new Error(`CORS: origin ${origin} not allowed`));
    },
    methods: ["GET", "POST", "PUT", "PATCH", "DELETE", "OPTIONS"],
    allowedHeaders: ["Content-Type", "Authorization", "X-Requested-With"],
    credentials: true,
    optionsSuccessStatus: 204,
  }),
);
// Ensure preflight OPTIONS requests are handled before other middleware
app.options("*", cors());
app.use(express.json({ limit: "10kb" }));
app.use(
  morgan("combined", { stream: { write: (msg) => logger.info(msg.trim()) } }),
);

// Global rate limiter: 100 req / 15 min per IP
app.use(
  rateLimit({
    windowMs: 15 * 60 * 1000,
    max: 100,
    message: { error: "Too many requests" },
  }),
);

// ── Routes ───────────────────────────────────────────────────────────────────
app.use("/api/v1/auth", authRoutes);
app.use("/api/v1/habits", habitRoutes);
app.use("/api/v1/carbon", carbonRoutes);
app.use("/api/v1/insights", insightRoutes);
app.use("/api/v1/gamification", gamificationRoutes);
app.use("/api/v1/users", userRoutes);
app.use("/api/v1/dashboard", dashboardRoutes);

// Welcome / Root API Info
app.get("/", (req, res) =>
  res.json({
    name: "Student Lifestyle Tracker & Carbon Footprint API",
    version: "1.0.0",
    status: "online",
    endpoints: {
      health: "/health",
      auth: "/api/v1/auth",
      habits: "/api/v1/habits",
      carbon: "/api/v1/carbon",
      dashboard: "/api/v1/dashboard",
      users: "/api/v1/users",
    },
  }),
);

// Health check
app.get("/health", (req, res) =>
  res.json({
    status: "ok",
    service: "student-lifestyle-tracker-backend",
    timestamp: new Date().toISOString(),
  }),
);

// 404 handler
app.use((req, res) => res.status(404).json({ error: "Route not found" }));

// Global error handler
app.use((err, req, res, next) => {
  logger.error(err.stack);
  res
    .status(err.status || 500)
    .json({ error: err.message || "Internal server error" });
});

// ── Database connection & Server start ───────────────────────────────────────
connectDB()
  .then(() => {
    app.listen(PORT, () => logger.info(`🚀 Server running on port ${PORT}`));
  })
  .catch((err) => {
    logger.error("Startup error:", err);
  });

module.exports = app;
