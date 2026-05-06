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
    const {
      role,
      requestedRole,
      documents,
      applicantName,
      applicantPhone,
      applicantEmail,
      badgeNumber,
      stationName,
      stationAddress,
      hospitalName,
      hospitalAddress,
      staffType,
    } = req.body;

    const selectedRole = (role || requestedRole || '').toString().toLowerCase();
    if (!selectedRole || !['police', 'hospital', 'admin'].includes(selectedRole)) {
      return res.apiError('Invalid role. Must be police, hospital, or admin', null, 400, 'INVALID_ROLE');
    }

    const userId = req.user._id || req.user.userId;
    const user = await User.findById(userId);
    if (!user) return res.apiError('User not found', null, 404, 'USER_NOT_FOUND');

    user.role = selectedRole;
    user.status = 'pending';
    user.rejectionReason = null;
    user.adminNotes = '';

    if (applicantName) user.name = applicantName;
    if (applicantPhone) user.phone = applicantPhone;
    if (applicantEmail) user.email = applicantEmail;

    if (selectedRole === 'police') {
      user.policeDetails = {
        idProof: user.policeDetails?.idProof || null,
        stationName: stationName || user.policeDetails?.stationName || null,
        stationAddress: stationAddress || user.policeDetails?.stationAddress || null,
        badgeNumber: badgeNumber || user.policeDetails?.badgeNumber || null,
        badgeProof: user.policeDetails?.badgeProof || null,
      };

      user.hospitalDetails = {
        hospitalName: null,
        licenseProof: null,
        staffType: null,
        location: { latitude: 0, longitude: 0, address: null },
        totalBeds: 0,
        availableBeds: 0,
        specializations: [],
        contactPerson: null,
      };
    } else if (selectedRole === 'hospital') {
      user.hospitalDetails = {
        hospitalName: hospitalName || user.hospitalDetails?.hospitalName || null,
        licenseProof: user.hospitalDetails?.licenseProof || null,
        staffType: staffType || user.hospitalDetails?.staffType || null,
        location: {
          latitude: user.hospitalDetails?.location?.latitude || 0,
          longitude: user.hospitalDetails?.location?.longitude || 0,
          address: hospitalAddress || user.hospitalDetails?.location?.address || null,
        },
        totalBeds: user.hospitalDetails?.totalBeds || 0,
        availableBeds: user.hospitalDetails?.availableBeds || 0,
        specializations: user.hospitalDetails?.specializations || [],
        contactPerson: applicantName || user.hospitalDetails?.contactPerson || user.name || null,
      };

      user.policeDetails = {
        idProof: null,
        stationName: null,
        stationAddress: null,
        badgeNumber: null,
        badgeProof: null,
      };
    }

    await user.save();

    return res.apiSuccess(
      {
        applicationId: user._id,
        requestedRole: user.role,
        status: user.status,
        applicantName: user.name,
        applicantPhone: user.phone,
        applicantEmail: user.email,
        badgeNumber: user.policeDetails?.badgeNumber,
        stationName: user.policeDetails?.stationName,
        stationAddress: user.policeDetails?.stationAddress,
        hospitalName: user.hospitalDetails?.hospitalName,
        hospitalAddress: user.hospitalDetails?.location?.address,
        staffType: user.hospitalDetails?.staffType,
      },
      'Role application submitted successfully',
      200
    );
  } catch (error) {
    return res.apiError('Failed to apply for role', error, 500, 'ROLE_APPLICATION_FAILED');
  }
};

const getRoleApplicationStatus = async (req, res) => {
  try {
    const userId = req.user._id || req.user.userId;
    const user = await User.findById(userId);
    if (!user) return res.apiError('User not found', null, 404, 'USER_NOT_FOUND');

    const hasApplication = user.role !== 'user' || user.status === 'pending' || user.status === 'rejected';
    const application = hasApplication
      ? {
          requestedRole: user.role,
          status: user.status,
          applicantName: user.name,
          applicantPhone: user.phone,
          applicantEmail: user.email,
          badgeNumber: user.policeDetails?.badgeNumber,
          stationName: user.policeDetails?.stationName,
          stationAddress: user.policeDetails?.stationAddress,
          hospitalName: user.hospitalDetails?.hospitalName,
          hospitalAddress: user.hospitalDetails?.location?.address,
          staffType: user.hospitalDetails?.staffType,
          rejectionReason: user.rejectionReason,
          adminNotes: user.adminNotes,
        }
      : null;

    return res.apiSuccess(
      { hasApplication, application },
      'Role application status retrieved successfully',
      200
    );
  } catch (error) {
    return res.apiError('Failed to fetch role application status', error, 500, 'ROLE_APPLICATION_STATUS_FAILED');
  }
};

module.exports = { getProfile, updateProfile, updateLocation, getLocation, applyRole, getRoleApplicationStatus };
