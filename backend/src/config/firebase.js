const admin = require('firebase-admin');
const { logger } = require('../utils/logger');

let isFirebaseConfigured = false;

const initFirebase = () => {
  if (admin.apps.length > 0) {
    isFirebaseConfigured = true;
    return admin;
  }

  const projectId = process.env.FIREBASE_PROJECT_ID;
  const clientEmail = process.env.FIREBASE_CLIENT_EMAIL;
  const rawKey = process.env.FIREBASE_PRIVATE_KEY;

  // Verify non-placeholder credentials exist
  const isPlaceholder = !projectId ||
    projectId === 'your-firebase-project-id' ||
    !clientEmail ||
    clientEmail.includes('your-project.iam.gserviceaccount.com') ||
    !rawKey ||
    rawKey.includes('-----BEGIN PRIVATE KEY-----\n...\n-----END PRIVATE KEY-----');

  if (isPlaceholder) {
    logger.warn('⚠️ Firebase Admin SDK: Placeholder or missing credentials in .env. Firebase auth features will run in mock/disabled mode.');
    return null;
  }

  try {
    const privateKey = rawKey.replace(/\\n/g, '\n');
    admin.initializeApp({
      credential: admin.credential.cert({
        projectId,
        clientEmail,
        privateKey,
      }),
    });
    isFirebaseConfigured = true;
    logger.info('✅ Firebase Admin SDK initialized');
    return admin;
  } catch (err) {
    logger.error('Failed to initialize Firebase Admin SDK:', err.message);
    return null;
  }
};

initFirebase();

module.exports = { admin, isFirebaseConfigured };
