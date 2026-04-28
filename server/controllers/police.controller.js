// Police registration and management controller
const User = require('../models/user.model');
const { sendSMS } = require('../services/sms.service');

// Police requests account (registration request)
const requestPoliceAccount = async (req, res) => {
  try {
    const { phone, name, stationName, badgeNumber, idProof, badgeProof } = req.body;

    if (!phone || !name || !stationName || !badgeNumber || !idProof) {
      return res.status(400).json({ 
        message: 'Missing required fields: phone, name, stationName, badgeNumber, idProof' 
      });
    }

    let user = await User.findOne({ phone });

    if (user && user.role !== 'user') {
      return res.status(400).json({ message: 'Account already registered with different role' });
    }

    if (!user) {
      user = await User.create({
        phone,
        name,
        role: 'police',
        status: 'pending',
        policeDetails: {
          stationName,
          badgeNumber,
          idProof,
          badgeProof: badgeProof || null,
        },
      });
    } else {
      user.name = name;
      user.role = 'police';
      user.status = 'pending';
      user.policeDetails = {
        stationName,
        badgeNumber,
        idProof,
        badgeProof: badgeProof || null,
      };
      await user.save();
    }

    res.status(201).json({
      message: 'Police registration request submitted. Awaiting admin approval.',
      userId: user._id,
      status: 'pending',
    });
  } catch (error) {
    res.status(500).json({ message: 'Failed to submit police request', error: error.message });
  }
};

// Get pending police requests (Admin only)
const getPendingPoliceRequests = async (req, res) => {
  try {
    const requests = await User.find({
      role: 'police',
      status: 'pending',
    }).select('-password');

    res.status(200).json({
      count: requests.length,
      requests,
    });
  } catch (error) {
    res.status(500).json({ message: 'Failed to fetch requests', error: error.message });
  }
};

// Admin approves police account
const approvePolicRequest = async (req, res) => {
  try {
    const { userId } = req.params;
    const { adminNotes } = req.body;

    const user = await User.findById(userId);
    if (!user || user.role !== 'police') {
      return res.status(404).json({ message: 'Police account not found' });
    }

    user.status = 'active';
    user.approvedBy = req.user._id;
    user.approvedAt = new Date();
    user.adminNotes = adminNotes || '';
    await user.save();

    // Send approval SMS
    await sendSMS(
      user.phone,
      `🚓 Your HumanSafety Police account has been APPROVED! Badge: ${user.policeDetails.badgeNumber}`
    );

    res.status(200).json({
      message: 'Police account approved',
      user: {
        id: user._id,
        phone: user.phone,
        name: user.name,
        badgeNumber: user.policeDetails.badgeNumber,
        status: 'active',
      },
    });
  } catch (error) {
    res.status(500).json({ message: 'Approval failed', error: error.message });
  }
};

// Admin rejects police account
const rejectPoliceRequest = async (req, res) => {
  try {
    const { userId } = req.params;
    const { rejectionReason } = req.body;

    if (!rejectionReason) {
      return res.status(400).json({ message: 'Rejection reason required' });
    }

    const user = await User.findById(userId);
    if (!user || user.role !== 'police') {
      return res.status(404).json({ message: 'Police account not found' });
    }

    user.status = 'rejected';
    user.rejectionReason = rejectionReason;
    await user.save();

    // Send rejection SMS
    await sendSMS(
      user.phone,
      `❌ Your Police registration request was rejected. Reason: ${rejectionReason}`
    );

    res.status(200).json({
      message: 'Police account rejected',
    });
  } catch (error) {
    res.status(500).json({ message: 'Rejection failed', error: error.message });
  }
};

// Get all police officers (for dispatcher/case assignment)
const getAllPoliceOfficers = async (req, res) => {
  try {
    const officers = await User.find({
      role: 'police',
      status: 'active',
      isBlocked: false,
    }).select('name phone currentLocation');

    res.status(200).json({
      count: officers.length,
      officers,
    });
  } catch (error) {
    res.status(500).json({ message: 'Failed to fetch officers', error: error.message });
  }
};

// Get police alerts (assigned cases)
const getPoliceAlerts = async (req, res) => {
  try {
    const { Emergency, Case } = require('../models');
    const userId = req.user._id;

    // Get cases assigned to this police officer that are pending or in progress
    const cases = await Case.find({
      assignedTo: userId,
      status: { $in: ['pending', 'in_progress'] }
    })
      .populate('userId', 'name phone')
      .sort({ createdAt: -1 })
      .limit(20);

    const alerts = cases.map(c => ({
      id: c._id,
      caseId: c._id,
      title: c.title || 'Emergency Case',
      description: c.description || 'Assigned case',
      status: c.status,
      priority: c.priority || 'high',
      location: c.location,
      userId: c.userId?._id,
      createdAt: c.createdAt,
      assignedAt: c.updatedAt,
    }));

    res.status(200).json(alerts);
  } catch (error) {
    res.status(500).json({ message: 'Failed to fetch alerts', error: error.message });
  }
};

module.exports = {
  requestPoliceAccount,
  getPendingPoliceRequests,
  approvePolicRequest,
  rejectPoliceRequest,
  getAllPoliceOfficers,
  getPoliceAlerts,
};
