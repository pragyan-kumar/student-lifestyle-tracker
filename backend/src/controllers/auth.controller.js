const jwt = require("jsonwebtoken");
const { admin, isFirebaseConfigured } = require("../config/firebase");
const User = require("../models/user.model");
const { logger } = require("../utils/logger");

const generateTokens = (userId) => {
  const accessToken = jwt.sign({ userId }, process.env.JWT_SECRET, {
    expiresIn: "7d",
  });
  const refreshToken = jwt.sign({ userId }, process.env.JWT_REFRESH_SECRET, {
    expiresIn: "30d",
  });
  return { accessToken, refreshToken };
};

// ── Register ─────────────────────────────────────────────────────────────────
exports.register = async (req, res) => {
  try {
    const { name, email, password } = req.body;

    const existing = await User.findOne({ email });
    if (existing)
      return res.status(409).json({ error: "Email already registered" });

    const user = await User.create({ name, email, passwordHash: password });
    const tokens = generateTokens(user._id);

    logger.info(`New user registered: ${email}`);
    res.status(201).json({ user, ...tokens });
  } catch (err) {
    logger.error("Register error:", err);
    res.status(500).json({ error: "Registration failed" });
  }
};

// ── Login ────────────────────────────────────────────────────────────────────
exports.login = async (req, res) => {
  try {
    const { email, password } = req.body;

    const user = await User.findOne({ email });
    if (!user || !(await user.comparePassword(password))) {
      return res.status(401).json({ error: "Invalid email or password" });
    }

    user.lastLoginAt = new Date();
    await user.save();

    const tokens = generateTokens(user._id);
    res.json({ user, ...tokens });
  } catch (err) {
    logger.error("Login error:", err);
    res.status(500).json({ error: "Login failed" });
  }
};

// ── Google OAuth2 via Firebase ID token ──────────────────────────────────────
exports.googleAuth = async (req, res) => {
  try {
    const { idToken } = req.body;
    if (!idToken) return res.status(400).json({ error: "idToken is required" });

    if (!isFirebaseConfigured || !admin) {
      return res.status(503).json({
        error:
          "Firebase Admin is not configured with valid service account credentials on this server",
      });
    }

    const decoded = await admin.auth().verifyIdToken(idToken);

    let user = await User.findOne({ firebaseUid: decoded.uid });
    if (!user) {
      user = await User.create({
        name: decoded.name || "Student",
        email: decoded.email,
        firebaseUid: decoded.uid,
        isVerified: decoded.email_verified,
      });
    }

    user.lastLoginAt = new Date();
    await user.save();

    const tokens = generateTokens(user._id);
    res.json({ user, ...tokens });
  } catch (err) {
    logger.error("Google auth error:", err);
    res.status(401).json({ error: "Google authentication failed" });
  }
};

// ── Refresh Token ─────────────────────────────────────────────────────────────
exports.refreshToken = async (req, res) => {
  try {
    const { refreshToken } = req.body;
    const decoded = jwt.verify(refreshToken, process.env.JWT_REFRESH_SECRET);
    const tokens = generateTokens(decoded.userId);
    res.json(tokens);
  } catch {
    res.status(401).json({ error: "Invalid or expired refresh token" });
  }
};

// ── Logout ────────────────────────────────────────────────────────────────────
exports.logout = async (req, res) => {
  // Token invalidation would be done via a Redis blocklist in production
  res.json({ message: "Logged out successfully" });
};

// ── Get current user ──────────────────────────────────────────────────────────
exports.getMe = async (req, res) => {
  res.json({ user: req.user });
};
