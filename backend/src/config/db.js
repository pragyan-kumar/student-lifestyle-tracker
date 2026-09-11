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

const isPlaceholderUri = (uri) => {
  if (!uri) return true;
  return uri.includes('<username>') || uri.includes('<password>');
};

const connectDB = async () => {
  const uri = process.env.MONGODB_URI;

  if (isPlaceholderUri(uri)) {
    logger.warn('⚠️ MONGODB_URI in backend/.env has placeholder credentials (<username>:<password>).');

    // Try local MongoDB on 127.0.0.1:27017 first
    try {
      const localUri = 'mongodb://127.0.0.1:27017/lifestyle_tracker';
      logger.info(`Attempting connection to local MongoDB at ${localUri}...`);
      await mongoose.connect(localUri, { serverSelectionTimeoutMS: 1500 });
      isConnected = true;
      logger.info('✅ Connected to local MongoDB');
      return;
    } catch {
      logger.warn('Local MongoDB on 127.0.0.1:27017 is not running.');
    }

    if (process.env.NODE_ENV === 'production') {
      logger.error('Fatal: Production server requires a valid MONGODB_URI.');
      process.exit(1);
    } else {
      logger.warn('⚠️ Server started in development mode without active MongoDB.');
      logger.warn('👉 Update MONGODB_URI in backend/.env with your MongoDB Atlas connection string.');
      return;
    }
  }

  try {
    await mongoose.connect(uri, { serverSelectionTimeoutMS: 6000 });
    isConnected = true;
    logger.info('✅ MongoDB Atlas connected successfully');
  } catch (err) {
    logger.error(`MongoDB connection error: ${err.message}`);
    if (process.env.NODE_ENV === 'production') {
      process.exit(1);
    } else {
      logger.warn('⚠️ Continuing in development mode with disconnected database.');
    }
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
