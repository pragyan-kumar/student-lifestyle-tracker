const admin = require("firebase-admin");
const { logger } = require("../utils/logger");

let isFirebaseConfigured = false;
let rtdb = null;

const initFirebase = () => {
  if (admin.apps.length > 0) {
    isFirebaseConfigured = true;
    try {
      rtdb = admin.database();
    } catch (_) {}
    return admin;
  }

  const projectId = process.env.FIREBASE_PROJECT_ID;
  const clientEmail = process.env.FIREBASE_CLIENT_EMAIL;
  const rawKey = process.env.FIREBASE_PRIVATE_KEY;
  const databaseURL =
    process.env.FIREBASE_DATABASE_URL ||
    "https://student-lifestyle-tracker-default-rtdb.asia-southeast1.firebasedatabase.app";

  // Verify non-placeholder credentials exist
  const isPlaceholder =
    !projectId ||
    projectId === "your-firebase-project-id" ||
    !clientEmail ||
    clientEmail.includes("your-project.iam.gserviceaccount.com") ||
    !rawKey ||
    rawKey.includes(
      "-----BEGIN PRIVATE KEY-----\n...\n-----END PRIVATE KEY-----",
    );

  if (isPlaceholder) {
    logger.warn(
      "⚠️ Firebase Admin SDK: Placeholder or missing credentials in .env. Firebase auth features will run in mock/disabled mode.",
    );
    return null;
  }

  try {
    const privateKey = rawKey.replace(/\\n/g, "\n");
    admin.initializeApp({
      credential: admin.credential.cert({
        projectId,
        clientEmail,
        privateKey,
      }),
      databaseURL,
    });
    isFirebaseConfigured = true;
    try {
      rtdb = admin.database();
    } catch (dbErr) {
      logger.warn(
        "Could not initialize Firebase RTDB instance:",
        dbErr.message,
      );
    }
    logger.info("✅ Firebase Admin SDK & Realtime Database initialized");
    return admin;
  } catch (err) {
    logger.error("Failed to initialize Firebase Admin SDK:", err.message);
    return null;
  }
};

initFirebase();

module.exports = { admin, rtdb, isFirebaseConfigured };
