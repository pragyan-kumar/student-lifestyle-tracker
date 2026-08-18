require('dotenv').config();
const express    = require('express');
const mongoose   = require('mongoose');
const cors       = require('cors');
const helmet     = require('helmet');
const morgan     = require('morgan');
const rateLimit  = require('express-rate-limit');

const authRoutes         = require('./routes/auth.routes');
const habitRoutes        = require('./routes/habit.routes');
const carbonRoutes       = require('./routes/carbon.routes');
const insightRoutes      = require('./routes/insight.routes');
const gamificationRoutes = require('./routes/gamification.routes');
const userRoutes         = require('./routes/user.routes');
const { logger }         = require('./utils/logger');

const app  = express();
const PORT = process.env.PORT || 5000;

// ── Security & Middleware ────────────────────────────────────────────────────
app.use(helmet());
app.use(cors({ origin: process.env.ALLOWED_ORIGINS?.split(',') || '*' }));
app.use(express.json({ limit: '10kb' }));
app.use(morgan('combined', { stream: { write: msg => logger.info(msg.trim()) } }));

// Global rate limiter: 100 req / 15 min per IP
app.use(rateLimit({ windowMs: 15 * 60 * 1000, max: 100, message: { error: 'Too many requests' } }));

// ── Routes ───────────────────────────────────────────────────────────────────
app.use('/api/v1/auth',         authRoutes);
app.use('/api/v1/habits',       habitRoutes);
app.use('/api/v1/carbon',       carbonRoutes);
app.use('/api/v1/insights',     insightRoutes);
app.use('/api/v1/gamification', gamificationRoutes);
app.use('/api/v1/users',        userRoutes);

// Health check
app.get('/health', (req, res) => res.json({ status: 'ok', timestamp: new Date().toISOString() }));

// 404 handler
app.use((req, res) => res.status(404).json({ error: 'Route not found' }));

// Global error handler
app.use((err, req, res, next) => {
  logger.error(err.stack);
  res.status(err.status || 500).json({ error: err.message || 'Internal server error' });
});

// ── Database connection ──────────────────────────────────────────────────────
mongoose.connect(process.env.MONGODB_URI, {
  useNewUrlParser: true,
  useUnifiedTopology: true,
}).then(() => {
  logger.info('✅ MongoDB connected');
  app.listen(PORT, () => logger.info(`🚀 Server running on port ${PORT}`));
}).catch(err => {
  logger.error('MongoDB connection error:', err);
  process.exit(1);
});

module.exports = app;
