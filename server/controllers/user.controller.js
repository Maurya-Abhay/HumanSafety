const User = require('../models/user.model');

const getProfile = async (req, res) => {
  try {
    const userId = req.user._id || req.user.userId;
    const user = await User.findById(userId).populate('emergencyContacts');
    if (!user) return res.status(404).json({ message: 'User not found' });
    
    // Calculate profile completion - only require name and email as basic details
    const hasName = user.name && user.name.length > 0;
    const hasEmail = user.email && user.email.length > 0;
    
    // Profile is 100% complete if name and email are filled
    const profileCompleted = hasName && hasEmail;
    const profileCompletionPercentage = profileCompleted ? 100 : 0;
    
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
        role: user.role,
        status: user.status,
        memberSince: user.createdAt,
        lastLogin: user.lastLogin,
        profileCompleted,
        profileCompletionPercentage,
        emergencyContactsCount: user.emergencyContacts ? user.emergencyContacts.length : 0,
        roleStatus: user.role === 'user' ? 'user' : 'verified'
      },
    });
  } catch (error) {
    res.status(500).json({ message: 'Failed to fetch profile', error: error.message });
  }
};

const updateProfile = async (req, res) => {
  try {
    const { name, email, bloodType, allergies } = req.body;
    const userId = req.user._id || req.user.userId;
    const user = await User.findByIdAndUpdate(
      userId,
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
    const userId = req.user._id || req.user.userId;
    const user = await User.findByIdAndUpdate(
      userId,
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
    const userId = req.user._id || req.user.userId;
    const user = await User.findById(userId);
    if (!user) return res.status(404).json({ message: 'User not found' });
    
    res.status(200).json({
      message: 'Location retrieved',
      location: user.currentLocation,
    });
  } catch (error) {
    res.status(500).json({ message: 'Failed to get location', error: error.message });
  }
};

const applyRole = async (req, res) => {
  try {
    const { role, documents } = req.body;
    const userId = req.user._id || req.user.userId;
    
    if (!role || !['police', 'hospital', 'admin'].includes(role)) {
      return res.status(400).json({ message: 'Invalid role' });
    }
    
    const user = await User.findByIdAndUpdate(
      userId,
      {
        pendingRole: role,
        pendingRoleDocuments: documents || [],
        roleApplicationDate: new Date(),
        roleStatus: 'pending'
      },
      { new: true }
    );
    
    if (!user) return res.status(404).json({ message: 'User not found' });
    
    res.status(200).json({
      message: 'Role application submitted',
      roleStatus: user.roleStatus,
      appliedRole: user.pendingRole
    });
  } catch (error) {
    res.status(500).json({ message: 'Role application failed', error: error.message });
  }
};

module.exports = { getProfile, updateProfile, updateLocation, getLocation, applyRole };
