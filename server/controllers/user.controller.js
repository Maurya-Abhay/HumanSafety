const User = require('../models/user.model');

// Helper function to calculate profile completion
const calculateProfileCompletion = (user) => {
  const requiredFields = [
    'name', 'email', 'phone', 'bloodType', 
    'profileDetails.dateOfBirth',
    'profileDetails.gender',
    'profileDetails.aadharNumber',
    'profileDetails.address',
    'profileDetails.city',
    'profileDetails.state',
    'profileDetails.zipCode',
    'profileDetails.emergencyContactName',
    'profileDetails.emergencyContactPhone',
  ];

  let completedFields = 0;
  const incompleteFields = [];

  requiredFields.forEach(field => {
    const value = field.includes('.')
      ? user.profileDetails?.[field.split('.')[1]]
      : user[field];

    if (value && value.toString().trim().length > 0) {
      completedFields++;
    } else {
      incompleteFields.push(field);
    }
  });

  const percentage = Math.round((completedFields / requiredFields.length) * 100);
  
  return {
    percentage,
    completedFields,
    totalFields: requiredFields.length,
    requiredFields: incompleteFields,
  };
};

const getProfile = async (req, res) => {
  try {
    const userId = req.user._id || req.user.userId;
    const user = await User.findById(userId).populate('emergencyContacts');
    if (!user) return res.apiError('User not found', null, 404, 'USER_NOT_FOUND');
    
    const profileCompletion = calculateProfileCompletion(user);
    
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
      profileCompletion,
      emergencyContactsCount: user.emergencyContacts ? user.emergencyContacts.length : 0,
      profileDetails: user.profileDetails,
      canApplyForRole: profileCompletion.percentage === 100,
      roleApplicationStatus: user.role !== 'user' ? {
        role: user.role,
        status: user.status,
        appliedAt: user.createdAt,
        verificationSteps: user.verificationSteps,
      } : null,
    }, 'Profile retrieved successfully', 200);
  } catch (error) {
    return res.apiError('Failed to fetch profile', error, 500, 'PROFILE_FETCH_FAILED');
  }
};

const updateProfile = async (req, res) => {
  try {
    const { 
      name, email, bloodType, allergies,
      dateOfBirth, gender, aadharNumber, address, city, state, zipCode,
      medicalHistory, emergencyContactName, emergencyContactPhone, emergencyContactRelation
    } = req.body;

    const userId = req.user._id || req.user.userId;
    const user = await User.findById(userId);
    if (!user) return res.apiError('User not found', null, 404, 'USER_NOT_FOUND');

    // Update basic info
    if (name) user.name = name;
    if (email) user.email = email;
    if (bloodType) user.bloodType = bloodType;
    if (allergies) user.allergies = allergies;

    // Update profile details
    if (dateOfBirth) user.profileDetails.dateOfBirth = dateOfBirth;
    if (gender) user.profileDetails.gender = gender;
    if (aadharNumber) user.profileDetails.aadharNumber = aadharNumber;
    if (address) user.profileDetails.address = address;
    if (city) user.profileDetails.city = city;
    if (state) user.profileDetails.state = state;
    if (zipCode) user.profileDetails.zipCode = zipCode;
    if (medicalHistory) user.profileDetails.medicalHistory = medicalHistory;
    if (emergencyContactName) user.profileDetails.emergencyContactName = emergencyContactName;
    if (emergencyContactPhone) user.profileDetails.emergencyContactPhone = emergencyContactPhone;
    if (emergencyContactRelation) user.profileDetails.emergencyContactRelation = emergencyContactRelation;

    const profileCompletion = calculateProfileCompletion(user);
    user.profileCompletion = {
      percentage: profileCompletion.percentage,
      lastUpdatedAt: new Date(),
      requiredFields: profileCompletion.requiredFields,
    };

    await user.save();
    
    return res.apiSuccess({
      id: user._id,
      phone: user.phone,
      name: user.name,
      email: user.email,
      bloodType: user.bloodType,
      allergies: user.allergies,
      profileCompletion,
      profileDetails: user.profileDetails,
      canApplyForRole: profileCompletion.percentage === 100,
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

    // Check profile completion
    const profileCompletion = calculateProfileCompletion(user);
    if (profileCompletion.percentage < 100) {
      return res.apiError(
        `Profile must be 100% complete to apply for a role. Current: ${profileCompletion.percentage}%. Missing: ${profileCompletion.requiredFields.join(', ')}`,
        null,
        400,
        'INCOMPLETE_PROFILE'
      );
    }

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

const getApplicationDetails = async (req, res) => {
  try {
    const userId = req.user._id || req.user.userId;
    const user = await User.findById(userId);
    if (!user) return res.apiError('User not found', null, 404, 'USER_NOT_FOUND');

    if (user.role === 'user') {
      return res.apiError('User has not applied for any role', null, 404, 'NO_APPLICATION');
    }

    // Calculate which step is current
    const steps = [
      { name: 'documentVerification', label: 'Document Verification' },
      { name: 'addressVerification', label: 'Address Verification' },
      { name: 'credentialsVerification', label: 'Credentials Verification' },
      { name: 'backgroundCheck', label: 'Background Check' },
    ];

    const stepsStatus = steps.map(step => ({
      name: step.name,
      label: step.label,
      status: user.verificationSteps[step.name]?.status || 'pending',
      notes: user.verificationSteps[step.name]?.notes || '',
      verifiedAt: user.verificationSteps[step.name]?.verifiedAt,
    }));

    const currentStepIndex = stepsStatus.findIndex(s => s.status === 'pending');
    const currentStep = currentStepIndex !== -1 ? stepsStatus[currentStepIndex] : null;

    const applicationStatus = {
      applicationId: user._id,
      role: user.role,
      status: user.status,
      appliedAt: user.createdAt,
      steps: stepsStatus,
      currentStep,
      completedSteps: stepsStatus.filter(s => s.status === 'approved').length,
      totalSteps: stepsStatus.length,
      allApproved: user.status === 'active',
      rejectionReason: user.rejectionReason,
      adminNotes: user.adminNotes,
      approvedAt: user.approvedAt,
    };

    return res.apiSuccess(applicationStatus, 'Application details retrieved successfully', 200);
  } catch (error) {
    return res.apiError('Failed to fetch application details', error, 500, 'APPLICATION_DETAILS_FAILED');
  }
};

module.exports = { getProfile, updateProfile, updateLocation, getLocation, applyRole, getRoleApplicationStatus, getApplicationDetails };
