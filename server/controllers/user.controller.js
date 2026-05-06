const User = require('../models/user.model');

const getProfile = async (req, res) => {
  try {
    const userId = req.user._id || req.user.userId;
    const user = await User.findById(userId).populate('emergencyContacts');
    if (!user) return res.apiError('User not found', null, 404, 'USER_NOT_FOUND');
    
    const hasName = user.name && user.name.length > 0;
    const hasEmail = user.email && user.email.length > 0;
    const profileCompleted = hasName && hasEmail;
    const profileCompletionPercentage = profileCompleted ? 100 : 0;
    
    return res.apiSuccess({
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
    }, 'Profile retrieved successfully', 200);
  } catch (error) {
    return res.apiError('Failed to fetch profile', error, 500, 'PROFILE_FETCH_FAILED');
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
    
    if (!user) return res.apiError('User not found', null, 404, 'USER_NOT_FOUND');
    
    return res.apiSuccess({
      id: user._id,
      phone: user.phone,
      name: user.name,
      email: user.email,
      bloodType: user.bloodType,
      allergies: user.allergies,
    }, 'Profile updated successfully', 200);
  } catch (error) {
    return res.apiError('Failed to update profile', error, 500, 'PROFILE_UPDATE_FAILED');
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
    
    if (!user) return res.apiError('User not found', null, 404, 'USER_NOT_FOUND');
    
    return res.apiSuccess(
      { location: user.currentLocation },
      'Location updated successfully',
      200
    );
  } catch (error) {
    return res.apiError('Failed to update location', error, 500, 'LOCATION_UPDATE_FAILED');
  }
};

const getLocation = async (req, res) => {
  try {
    const userId = req.user._id || req.user.userId;
    const user = await User.findById(userId);
    if (!user) return res.apiError('User not found', null, 404, 'USER_NOT_FOUND');
    
    return res.apiSuccess(
      { location: user.currentLocation },
      'Location retrieved successfully',
      200
    );
  } catch (error) {
    return res.apiError('Failed to get location', error, 500, 'LOCATION_FETCH_FAILED');
  }
};

const applyRole = async (req, res) => {
  try {
    const { role, documents } = req.body;
    const userId = req.user._id || req.user.userId;
    
    if (!role || !['police', 'hospital', 'admin'].includes(role)) {
      return res.apiError('Invalid role. Must be police, hospital, or admin', null, 400, 'INVALID_ROLE');
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
    
    if (!user) return res.apiError('User not found', null, 404, 'USER_NOT_FOUND');
    
    return res.apiSuccess({
      roleStatus: user.roleStatus,
      appliedRole: user.pendingRole
    }, 'Role application submitted successfully', 200);
  } catch (error) {
    return res.apiError('Failed to apply for role', error, 500, 'ROLE_APPLICATION_FAILED');
  }
};

module.exports = { getProfile, updateProfile, updateLocation, getLocation, applyRole };
