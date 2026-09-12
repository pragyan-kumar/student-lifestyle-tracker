const mongoose = require("mongoose");
const bcrypt = require("bcryptjs");

const userSchema = new mongoose.Schema(
  {
    name: { type: String, required: true, trim: true },
    email: { type: String, required: true, unique: true, lowercase: true },
    passwordHash: { type: String }, // null for OAuth-only users
    firebaseUid: { type: String, unique: true, sparse: true },
    avatar: { type: String, default: "" }, // URL to profile picture

    // Gamification wallet
    points: { type: Number, default: 0 },
    badges: [{ type: String }], // badge IDs earned
    streakDays: { type: Number, default: 0 },
    lastActivityDate: { type: Date },

    // Unlocked in-app perks
    unlockedThemes: [{ type: String }],
    streakFreezes: { type: Number, default: 0 }, // remaining freeze passes
    skipPasses: { type: Number, default: 0 },

    // Profile metadata
    batch: { type: String },
    department: { type: String },

    isVerified: { type: Boolean, default: false },
    lastLoginAt: { type: Date },
  },
  { timestamps: true },
);

// Hash password before save
userSchema.pre("save", async function (next) {
  if (!this.isModified("passwordHash")) return next();
  this.passwordHash = await bcrypt.hash(this.passwordHash, 12);
  next();
});

// Compare password helper
userSchema.methods.comparePassword = function (plain) {
  return bcrypt.compare(plain, this.passwordHash);
};

// Exclude sensitive fields from JSON output
userSchema.methods.toJSON = function () {
  const obj = this.toObject();
  delete obj.passwordHash;
  delete obj.__v;
  return obj;
};

module.exports = mongoose.model("User", userSchema);
