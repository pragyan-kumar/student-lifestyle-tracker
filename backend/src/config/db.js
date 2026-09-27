const mongoose = require('mongoose');
const dns = require('dns');
const { logger } = require('../utils/logger');

// Set reliable public DNS servers for resolving MongoDB Atlas SRV records
try {
  dns.setServers(['8.8.8.8', '1.1.1.1', '8.8.4.4']);
} catch {
  // Ignore if not permitted
}

let isConnected = false;
let memoryServer = null; // holds MongoMemoryServer instance if used

const isPlaceholderUri = (uri) => {
  if (!uri) return true;
  return uri.includes('<username>') || uri.includes('<password>');
};

/** Spin up an in-memory MongoDB and return its URI */
const startMemoryServer = async () => {
  const { MongoMemoryServer } = require('mongodb-memory-server');
  memoryServer = await MongoMemoryServer.create();
  const uri = memoryServer.getUri();
  logger.info(`🧪 In-memory MongoDB started at ${uri}`);
  return uri;
};

const connectDB = async () => {
  const uri = process.env.MONGODB_URI;

  // ── Try Atlas first (if URI looks real) ────────────────────────────────────
  if (!isPlaceholderUri(uri)) {
    try {
      await mongoose.connect(uri, { serverSelectionTimeoutMS: 6000 });
      isConnected = true;
      logger.info('✅ MongoDB Atlas connected successfully');
      return;
    } catch (err) {
      logger.error(`MongoDB Atlas connection error: ${err.message}`);
      if (process.env.NODE_ENV === 'production') {
        logger.error('Fatal: Production server requires a valid MONGODB_URI.');
        process.exit(1);
      }
      logger.warn('⚠️ Atlas unavailable — falling back to in-memory MongoDB for development.');
    }
  } else {
    logger.warn('⚠️ MONGODB_URI has placeholder credentials — skipping Atlas.');
  }

  // ── Try local MongoDB ───────────────────────────────────────────────────────
  try {
    const localUri = 'mongodb://127.0.0.1:27017/lifestyle_tracker';
    logger.info('Trying local MongoDB at 127.0.0.1:27017...');
    await mongoose.connect(localUri, { serverSelectionTimeoutMS: 1500 });
    isConnected = true;
    logger.info('✅ Connected to local MongoDB');
    return;
  } catch {
    logger.warn('Local MongoDB not available.');
  }

  // ── Fall back to in-memory MongoDB (always works) ──────────────────────────
  try {
    const memUri = await startMemoryServer();
    await mongoose.connect(memUri);
    isConnected = true;
    logger.info('✅ Connected to in-memory MongoDB (data resets on server restart)');
  } catch (err) {
    logger.error(`Failed to start in-memory MongoDB: ${err.message}`);
    if (process.env.NODE_ENV === 'production') process.exit(1);
  }
};

/**
 * Middleware that guards routes requiring an active database connection.
 */
const dbGuard = (req, res, next) => {
  if (mongoose.connection.readyState !== 1) {
    return res.status(503).json({
      error: 'Database not connected. Please configure a valid MONGODB_URI in backend/.env',
    });
  }
  next();
};

module.exports = {
  connectDB,
  dbGuard,
  getIsConnected: () => mongoose.connection.readyState === 1,
};
