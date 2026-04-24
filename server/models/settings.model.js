const mongoose = require('mongoose');

const settingsSchema = new mongoose.Schema(
  {
    userId: { type: mongoose.Schema.Types.ObjectId, ref: 'User', required: true, unique: true },
    panicEnabled: { type: Boolean, default: true },
    autoDetection: { type: Boolean, default: true },
    rideMode: { type: Boolean, default: false },
    nearbyHelpEnabled: { type: Boolean, default: true },
    notificationsEnabled: { type: Boolean, default: true },
    soundEnabled: { type: Boolean, default: true },
    vibrationEnabled: { type: Boolean, default: true },
    locationTracking: { type: Boolean, default: true },
    liveLocationSharing: { type: Boolean, default: false },
    autoSOSOnAccident: { type: Boolean, default: true },
    accidentSensitivity: { type: Number, default: 60 },
  },
  { timestamps: true }
);

module.exports = mongoose.model('Settings', settingsSchema);
