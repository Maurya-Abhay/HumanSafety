const User = require('../models/user.model');

const getProfile = async (req, res) => {
  try {
    const user = await User.findById(req.user.userId);
    if (!user) return res.status(404).json({ message: 'User not found' });
    
    res.status(200).json({
      message: 'Profile retrieved',
      user: {
        id: user._id,
        phone: user.phone,
        name: user.name,
        email: user.email,
        bloodType: user.bloodType,
        allergies: user.allergies,
        location: user.currentLocation,
      },
    });
  } catch (error) {
    res.status(500).json({ message: 'Failed to fetch profile', error: error.message });
  }
};

const updateProfile = async (req, res) => {
  try {
    const { name, email, bloodType, allergies } = req.body;
    const user = await User.findByIdAndUpdate(
      req.user.userId,
      { name, email, bloodType, allergies },
      { new: true }
    );
    
    if (!user) return res.status(404).json({ message: 'User not found' });
    
    res.status(200).json({
      message: 'Profile updated',
      user: {
        id: user._id,
        phone: user.phone,
        name: user.name,
        email: user.email,
        bloodType: user.bloodType,
        allergies: user.allergies,
      },
    });
  } catch (error) {
    res.status(500).json({ message: 'Update failed', error: error.message });
  }
};

const updateLocation = async (req, res) => {
  try {
    const { latitude, longitude } = req.body;
    const user = await User.findByIdAndUpdate(
      req.user.userId,
      {
        'currentLocation.latitude': latitude,
        'currentLocation.longitude': longitude,
        'currentLocation.updatedAt': new Date(),
      },
      { new: true }
    );
    
    if (!user) return res.status(404).json({ message: 'User not found' });
    
    res.status(200).json({
      message: 'Location updated',
      location: user.currentLocation,
    });
  } catch (error) {
    res.status(500).json({ message: 'Location update failed', error: error.message });
  }
};

const getLocation = async (req, res) => {
  try {
    const user = await User.findById(req.user.userId);
    if (!user) return res.status(404).json({ message: 'User not found' });
    
    res.status(200).json({
      message: 'Location retrieved',
      location: user.currentLocation,
    });
  } catch (error) {
    res.status(500).json({ message: 'Failed to get location', error: error.message });
  }
};

module.exports = { getProfile, updateProfile, updateLocation, getLocation };
