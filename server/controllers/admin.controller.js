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

module.exports = {
  getDashboardStats,
  getAllUsers,
  getUserDetails,
  blockUser,
  unblockUser,
  getPendingRequests,
  getSystemAnalytics,
  addAdminNotes,
};
