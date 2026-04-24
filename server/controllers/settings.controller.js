const Settings = require('../models/settings.model');

const getSettings = async (req, res) => {
  try {
    let settings = await Settings.findOne({ userId: req.user.userId });
    if (!settings) {
      settings = await Settings.create({ userId: req.user.userId });
    }
    
    res.status(200).json({
      message: 'Settings retrieved',
      settings: {
        panicEnabled: settings.panicEnabled,
        autoDetection: settings.autoDetection,
        rideMode: settings.rideMode,
        nearbyHelpEnabled: settings.nearbyHelpEnabled,
        notificationsEnabled: settings.notificationsEnabled,
        soundEnabled: settings.soundEnabled,
        vibrationEnabled: settings.vibrationEnabled,
        locationTracking: settings.locationTracking,
        liveLocationSharing: settings.liveLocationSharing,
        autoSOSOnAccident: settings.autoSOSOnAccident,
        accidentSensitivity: settings.accidentSensitivity,
      },
    });
  } catch (error) {
    res.status(500).json({ message: 'Failed to get settings', error: error.message });
  }
};

const updateSettings = async (req, res) => {
  try {
    const settings = await Settings.findOneAndUpdate(
      { userId: req.user.userId },
      req.body,
      { new: true, upsert: true }
    );
    
    res.status(200).json({
      message: 'Settings updated',
      settings: {
        panicEnabled: settings.panicEnabled,
        autoDetection: settings.autoDetection,
        rideMode: settings.rideMode,
        nearbyHelpEnabled: settings.nearbyHelpEnabled,
        notificationsEnabled: settings.notificationsEnabled,
        autoSOSOnAccident: settings.autoSOSOnAccident,
        accidentSensitivity: settings.accidentSensitivity,
      },
    });
  } catch (error) {
    res.status(500).json({ message: 'Failed to update settings', error: error.message });
  }
};

module.exports = { getSettings, updateSettings };
