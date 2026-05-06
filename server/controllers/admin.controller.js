// Admin dashboard and management controller
const User = require('../models/user.model');

// Admin dashboard - get system stats
const getDashboardStats = async (req, res) => {
  try {
    const totalUsers = await User.countDocuments({ role: 'user' });
    const totalPolice = await User.countDocuments({ role: 'police', status: 'active' });
    const totalHospitals = await User.countDocuments({ role: 'hospital', status: 'active' });
    const pendingRequests = await User.countDocuments({ status: 'pending' });
    const blockedAccounts = await User.countDocuments({ isBlocked: true });

    res.status(200).json({
      stats: {
        totalUsers,
        totalPolice,
        totalHospitals,
        pendingRequests,
        blockedAccounts,
        totalAccounts: totalUsers + totalPolice + totalHospitals,
      },
    });
  } catch (error) {
    res.status(500).json({ message: 'Failed to get stats', error: error.message });
  }
};

// Get all users with filtering
const getAllUsers = async (req, res) => {
  try {
    const { role, status, limit = 50, skip = 0 } = req.query;

    const filter = {};
    if (role) filter.role = role;
    if (status) filter.status = status;

    const users = await User.find(filter)
      .select('-password')
      .limit(parseInt(limit))
      .skip(parseInt(skip))
      .sort({ createdAt: -1 });

    const total = await User.countDocuments(filter);

    res.status(200).json({
      total,
      count: users.length,
      limit: parseInt(limit),
      skip: parseInt(skip),
      users,
    });
  } catch (error) {
    res.status(500).json({ message: 'Failed to fetch users', error: error.message });
  }
};

// Get user details (Admin view)
const getUserDetails = async (req, res) => {
  try {
    const { userId } = req.params;

    const user = await User.findById(userId).select('-password');
    if (!user) {
      return res.status(404).json({ message: 'User not found' });
    }

    res.status(200).json({
      user,
    });
  } catch (error) {
    res.status(500).json({ message: 'Failed to fetch user', error: error.message });
  }
};

// Admin blocks user account
const blockUser = async (req, res) => {
  try {
    const { userId } = req.params;
    const { blockReason } = req.body;

    if (!blockReason) {
      return res.status(400).json({ message: 'Block reason required' });
    }

    const user = await User.findById(userId);
    if (!user) {
      return res.status(404).json({ message: 'User not found' });
    }

    user.isBlocked = true;
    user.blockReason = blockReason;
    await user.save();

    res.status(200).json({
      message: 'User account blocked',
      userId: user._id,
      blockReason,
    });
  } catch (error) {
    res.status(500).json({ message: 'Block failed', error: error.message });
  }
};

// Admin unblocks user account
const unblockUser = async (req, res) => {
  try {
    const { userId } = req.params;

    const user = await User.findById(userId);
    if (!user) {
      return res.status(404).json({ message: 'User not found' });
    }

    user.isBlocked = false;
    user.blockReason = null;
    await user.save();

    res.status(200).json({
      message: 'User account unblocked',
      userId: user._id,
    });
  } catch (error) {
    res.status(500).json({ message: 'Unblock failed', error: error.message });
  }
};

// Get all pending requests (Police + Hospital)
const getPendingRequests = async (req, res) => {
  try {
    const pendingUsers = await User.find({
      status: 'pending',
    }).select('-password').sort({ createdAt: -1 });

    const policeRequests = pendingUsers.filter(u => u.role === 'police');
    const hospitalRequests = pendingUsers.filter(u => u.role === 'hospital');

    res.status(200).json({
      total: pendingUsers.length,
      policeRequests: {
        count: policeRequests.length,
        requests: policeRequests,
      },
      hospitalRequests: {
        count: hospitalRequests.length,
        requests: hospitalRequests,
      },
    });
  } catch (error) {
    res.status(500).json({ message: 'Failed to fetch requests', error: error.message });
  }
};

// Admin view - system analytics
const getSystemAnalytics = async (req, res) => {
  try {
    const activeUsers = await User.countDocuments({ role: 'user', isBlocked: false });
    const activePolice = await User.countDocuments({ role: 'police', status: 'active', isBlocked: false });
    const activeHospitals = await User.countDocuments({ role: 'hospital', status: 'active', isBlocked: false });

    const rejectedPolice = await User.countDocuments({ role: 'police', status: 'rejected' });
    const rejectedHospitals = await User.countDocuments({ role: 'hospital', status: 'rejected' });

    res.status(200).json({
      analytics: {
        active: {
          users: activeUsers,
          police: activePolice,
          hospitals: activeHospitals,
        },
        rejected: {
          police: rejectedPolice,
          hospitals: rejectedHospitals,
        },
        blocked: await User.countDocuments({ isBlocked: true }),
      },
    });
  } catch (error) {
    res.status(500).json({ message: 'Failed to fetch analytics', error: error.message });
  }
};

// Admin adds admin notes to user
const addAdminNotes = async (req, res) => {
  try {
    const { userId } = req.params;
    const { notes } = req.body;

    const user = await User.findById(userId);
    if (!user) {
      return res.status(404).json({ message: 'User not found' });
    }

    user.adminNotes = notes || '';
    await user.save();

    res.status(200).json({
      message: 'Admin notes updated',
      userId: user._id,
    });
  } catch (error) {
    res.status(500).json({ message: 'Failed to update notes', error: error.message });
  }
};

// Get role applications with filtering
const getRoleApplications = async (req, res) => {
  try {
    const { status } = req.query;
    
    const filter = {};
    // Map UI status labels to backend enum values
    const statusMap = {
      'pending': 'pending',
      'approved': 'active',
      'active': 'active',
      'rejected': 'rejected'
    };
    
    if (status && statusMap[status]) {
      filter.status = statusMap[status];
    }

    const applications = await User.find({
      role: { $in: ['police', 'hospital', 'admin'] },
      ...filter
    })
      .select('-password')
      .sort({ createdAt: -1 });

    res.status(200).json({
      count: applications.length,
      applications: applications.map(user => ({
        id: user._id,
        _id: user._id,
        userId: user._id,
        requestedRole: user.role,
        applicantName: user.name,
        applicantPhone: user.phone,
        applicantEmail: user.email,
        role: user.role,
        status: user.status,
        createdAt: user.createdAt,
        badgeNumber: user.policeDetails?.badgeNumber,
        stationName: user.policeDetails?.stationName,
        stationAddress: user.policeDetails?.stationAddress,
        hospitalName: user.hospitalDetails?.hospitalName,
        hospitalAddress: user.hospitalDetails?.location?.address,
        staffType: user.hospitalDetails?.staffType,
        adminNotes: user.adminNotes,
        rejectionReason: user.rejectionReason,
      }))
    });
  } catch (error) {
    res.status(500).json({ message: 'Failed to fetch role applications', error: error.message });
  }
};

// Approve role application
const approveRoleApplication = async (req, res) => {
  try {
    const { appId } = req.params;
    const { approvalNotes } = req.body;

    const user = await User.findById(appId);
    if (!user) {
      return res.status(404).json({ message: 'Application not found' });
    }

    if (!['police', 'hospital', 'admin'].includes(user.role)) {
      return res.status(400).json({ message: 'Only police, hospital, and admin applications can be approved' });
    }

    // Only approve if currently pending
    if (user.status !== 'pending') {
      return res.status(400).json({ message: `Cannot approve: application status is ${user.status}` });
    }

    user.status = 'active';
    user.approvedBy = req.user._id;
    user.approvedAt = new Date();
    user.adminNotes = approvalNotes || user.adminNotes;
    user.rejectionReason = null;  // Clear any rejection reason
    await user.save();

    res.status(200).json({
      message: 'Application approved successfully',
      applicationId: user._id,
      userId: user._id,
      role: user.role,
      status: user.status,
      updatedAt: user.approvedAt,
    });
  } catch (error) {
    res.status(500).json({ message: 'Approval failed', error: error.message });
  }
};

// Reject role application
const rejectRoleApplication = async (req, res) => {
  try {
    const { appId } = req.params;
    const { rejectionReason } = req.body;

    if (!rejectionReason) {
      return res.status(400).json({ message: 'Rejection reason required' });
    }

    const user = await User.findById(appId);
    if (!user) {
      return res.status(404).json({ message: 'Application not found' });
    }

    if (!['police', 'hospital', 'admin'].includes(user.role)) {
      return res.status(400).json({ message: 'Only police, hospital, and admin applications can be rejected' });
    }

    // Only reject if currently pending
    if (user.status !== 'pending') {
      return res.status(400).json({ message: `Cannot reject: application status is ${user.status}` });
    }

    user.status = 'rejected';
    user.rejectionReason = rejectionReason;
    user.adminNotes = `Rejected: ${rejectionReason}`;
    await user.save();

    res.status(200).json({
      message: 'Application rejected successfully',
      applicationId: user._id,
      userId: user._id,
      role: user.role,
      status: user.status,
      rejectionReason: user.rejectionReason,
    });
  } catch (error) {
    res.status(500).json({ message: 'Rejection failed', error: error.message });
  }
};

// Approve a specific verification step
const approveVerificationStep = async (req, res) => {
  try {
    const { appId, step } = req.params;
    const { notes } = req.body;

    const validSteps = ['documentVerification', 'addressVerification', 'credentialsVerification', 'backgroundCheck'];
    if (!validSteps.includes(step)) {
      return res.status(400).json({ message: 'Invalid verification step' });
    }

    const user = await User.findById(appId);
    if (!user) {
      return res.status(404).json({ message: 'Application not found' });
    }

    if (user.verificationSteps[step].status !== 'pending') {
      return res.status(400).json({ message: `Step ${step} is already ${user.verificationSteps[step].status}` });
    }

    user.verificationSteps[step].status = 'approved';
    user.verificationSteps[step].notes = notes || '';
    user.verificationSteps[step].verifiedBy = req.user._id;
    user.verificationSteps[step].verifiedAt = new Date();
    await user.save();

    // Check if all steps are approved
    const allStepsApproved = Object.values(user.verificationSteps).every(s => s.status === 'approved');
    if (allStepsApproved && user.status === 'pending') {
      user.status = 'active';
      user.approvedBy = req.user._id;
      user.approvedAt = new Date();
      await user.save();
    }

    res.status(200).json({
      message: 'Step approved successfully',
      step,
      allApproved: allStepsApproved,
      userStatus: user.status,
    });
  } catch (error) {
    res.status(500).json({ message: 'Failed to approve step', error: error.message });
  }
};

// Reject a specific verification step
const rejectVerificationStep = async (req, res) => {
  try {
    const { appId, step } = req.params;
    const { notes } = req.body;

    if (!notes) {
      return res.status(400).json({ message: 'Rejection reason required' });
    }

    const validSteps = ['documentVerification', 'addressVerification', 'credentialsVerification', 'backgroundCheck'];
    if (!validSteps.includes(step)) {
      return res.status(400).json({ message: 'Invalid verification step' });
    }

    const user = await User.findById(appId);
    if (!user) {
      return res.status(404).json({ message: 'Application not found' });
    }

    if (user.verificationSteps[step].status !== 'pending') {
      return res.status(400).json({ message: `Step ${step} is already ${user.verificationSteps[step].status}` });
    }

    user.verificationSteps[step].status = 'rejected';
    user.verificationSteps[step].notes = notes;
    user.verificationSteps[step].verifiedBy = req.user._id;
    user.verificationSteps[step].verifiedAt = new Date();
    
    // Mark overall status as rejected if any step fails
    user.status = 'rejected';
    user.rejectionReason = `Step ${step} rejected: ${notes}`;
    await user.save();

    res.status(200).json({
      message: 'Step rejected successfully',
      step,
      userStatus: user.status,
    });
  } catch (error) {
    res.status(500).json({ message: 'Failed to reject step', error: error.message });
  }
};

// Get verification details for a user
const getVerificationDetails = async (req, res) => {
  try {
    const { appId } = req.params;

    const user = await User.findById(appId);
    if (!user) {
      return res.status(404).json({ message: 'Application not found' });
    }

    const stepDetails = {
      id: user._id,
      name: user.name,
      phone: user.phone,
      email: user.email,
      role: user.role,
      status: user.status,
      createdAt: user.createdAt,
      steps: {
        documentVerification: {
          ...user.verificationSteps.documentVerification,
          description: user.role === 'police' ? 'ID Proof & Badge Verification' : 'Hospital License & Certificates',
          documents: user.role === 'police' 
            ? { idProof: user.policeDetails?.idProof, badgeProof: user.policeDetails?.badgeProof }
            : { licenseProof: user.hospitalDetails?.licenseProof }
        },
        addressVerification: {
          ...user.verificationSteps.addressVerification,
          description: user.role === 'police' ? 'Police Station Address' : 'Hospital Address',
          address: user.role === 'police'
            ? user.policeDetails?.stationAddress
            : user.hospitalDetails?.location?.address
        },
        credentialsVerification: {
          ...user.verificationSteps.credentialsVerification,
          description: user.role === 'police' ? 'Badge Number & Station Details' : 'Hospital Details & Staff Type',
          details: user.role === 'police'
            ? { badgeNumber: user.policeDetails?.badgeNumber, stationName: user.policeDetails?.stationName }
            : { hospitalName: user.hospitalDetails?.hospitalName, staffType: user.hospitalDetails?.staffType }
        },
        backgroundCheck: {
          ...user.verificationSteps.backgroundCheck,
          description: 'Background & Safety Check',
          status: 'pending'
        }
      }
    };

    res.status(200).json(stepDetails);
  } catch (error) {
    res.status(500).json({ message: 'Failed to fetch verification details', error: error.message });
  }
};

// Get all cases for admin review and reports
const getAdminCases = async (req, res) => {
  try {
    const { status, limit = 100, skip = 0 } = req.query;

    const filter = {};
    if (status && ['pending', 'assigned', 'in-progress', 'resolved'].includes(status)) {
      filter.status = status;
    }

    const Alert = require('../models/alert.model');
    const cases = await Alert.find(filter)
      .populate('userId', 'name phone email role')
      .populate('assignedPolice', 'name policeDetails')
      .populate('assignedHospital', 'name hospitalDetails')
      .limit(parseInt(limit))
      .skip(parseInt(skip))
      .sort({ createdAt: -1 });

    const total = await Alert.countDocuments(filter);
    const casePayload = cases.map((alert) => ({
      id: alert._id,
      _id: alert._id,
      type: alert.type,
      status: alert.status,
      title: alert.title,
      description: alert.description,
      priority: alert.priority || 'HIGH',
      location: alert.location,
      riskLevel: alert.metadata?.riskLevel || 'critical',
      severityScore: alert.metadata?.riskScore ?? alert.severityScore ?? 0,
      metadata: alert.metadata,
      reportedBy: alert.userId
        ? {
            id: alert.userId._id,
            name: alert.userId.name,
            phone: alert.userId.phone,
            email: alert.userId.email,
            role: alert.userId.role,
          }
        : null,
      assignedPolice: alert.assignedPolice
        ? {
            id: alert.assignedPolice._id,
            name: alert.assignedPolice.name,
            policeDetails: alert.assignedPolice.policeDetails,
          }
        : null,
      assignedHospital: alert.assignedHospital
        ? {
            id: alert.assignedHospital._id,
            name: alert.assignedHospital.name,
            hospitalDetails: alert.assignedHospital.hospitalDetails,
          }
        : null,
      timestamp: alert.createdAt,
      updatedAt: alert.updatedAt,
    }));

    return res.apiSuccess(
      {
        total,
        count: casePayload.length,
        limit: parseInt(limit),
        skip: parseInt(skip),
        cases: casePayload,
      },
      'Admin cases retrieved successfully',
      200
    );
  } catch (error) {
    res.status(500).json({ message: 'Failed to fetch cases', error: error.message });
  }
};

module.exports = {
  getDashboardStats,
  getAllUsers,
  getUserDetails,
  blockUser,
  unblockUser,
  getPendingRequests,
  getSystemAnalytics,
  addAdminNotes,
  getRoleApplications,
  approveRoleApplication,
  rejectRoleApplication,
  approveVerificationStep,
  rejectVerificationStep,
  getVerificationDetails,
  getAdminCases,
};
