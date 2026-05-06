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
    if (status && ['pending', 'approved', 'rejected'].includes(status)) {
      filter.status = status;
    }

    const applications = await User.find({
      role: { $in: ['police', 'hospital'] },
      ...filter
    })
      .select('-password')
      .sort({ createdAt: -1 });

    res.status(200).json({
      count: applications.length,
      applications: applications.map(user => ({
        id: user._id,
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

    if (!['police', 'hospital'].includes(user.role)) {
      return res.status(400).json({ message: 'Only police and hospital applications can be approved' });
    }

    user.status = 'active';
    user.approvedBy = req.user._id;
    user.approvedAt = new Date();
    user.adminNotes = approvalNotes || user.adminNotes;
    await user.save();

    res.status(200).json({
      message: 'Application approved',
      applicationId: user._id,
      status: user.status,
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

    if (!['police', 'hospital'].includes(user.role)) {
      return res.status(400).json({ message: 'Only police and hospital applications can be rejected' });
    }

    user.status = 'rejected';
    user.rejectionReason = rejectionReason;
    user.adminNotes = `Rejected: ${rejectionReason}`;
    await user.save();

    res.status(200).json({
      message: 'Application rejected',
      applicationId: user._id,
      status: user.status,
    });
  } catch (error) {
    res.status(500).json({ message: 'Rejection failed', error: error.message });
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

    res.status(200).json({
      total,
      count: cases.length,
      limit: parseInt(limit),
      skip: parseInt(skip),
      cases,
    });
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
  getAdminCases,
};
