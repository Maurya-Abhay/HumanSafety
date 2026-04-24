// Case assignment and management controller
const Alert = require('../models/alert.model');
const User = require('../models/user.model');

// Dispatcher assigns case to police
const assignCaseToPolice = async (req, res) => {
  try {
    const { emergencyId, policeId } = req.body;

    if (!emergencyId || !policeId) {
      return res.status(400).json({ message: 'Missing emergencyId or policeId' });
    }

    const emergency = await Alert.findById(emergencyId);
    if (!emergency) {
      return res.status(404).json({ message: 'Emergency not found' });
    }

    const police = await User.findById(policeId);
    if (!police || police.role !== 'police') {
      return res.status(404).json({ message: 'Police officer not found' });
    }

    emergency.assignedPolice = policeId;
    emergency.status = 'assigned'; // pending -> assigned
    await emergency.save();

    res.status(200).json({
      message: 'Case assigned to police officer',
      emergencyId: emergency._id,
      policeId,
      status: 'assigned',
    });
  } catch (error) {
    res.status(500).json({ message: 'Assignment failed', error: error.message });
  }
};

// Police officer accepts assigned case
const acceptCase = async (req, res) => {
  try {
    const { caseId } = req.params;
    const { eta } = req.body; // ETA in minutes

    const emergency = await Alert.findById(caseId);
    if (!emergency) {
      return res.status(404).json({ message: 'Case not found' });
    }

    if (emergency.assignedPolice.toString() !== req.user._id.toString()) {
      return res.status(403).json({ message: 'Case not assigned to you' });
    }

    emergency.status = 'in-progress';
    emergency.acceptedAt = new Date();
    emergency.eta = eta || 10; // Default 10 minutes
    await emergency.save();

    res.status(200).json({
      message: 'Case accepted',
      caseId: emergency._id,
      status: 'in-progress',
      eta,
    });
  } catch (error) {
    res.status(500).json({ message: 'Acceptance failed', error: error.message });
  }
};

// Police officer rejects assigned case
const rejectCase = async (req, res) => {
  try {
    const { caseId } = req.params;
    const { reason } = req.body;

    const emergency = await Alert.findById(caseId);
    if (!emergency) {
      return res.status(404).json({ message: 'Case not found' });
    }

    if (emergency.assignedPolice.toString() !== req.user._id.toString()) {
      return res.status(403).json({ message: 'Case not assigned to you' });
    }

    emergency.status = 'pending'; // Back to pending for reassignment
    emergency.assignedPolice = null;
    emergency.rejectionReason = reason || 'No reason provided';
    await emergency.save();

    res.status(200).json({
      message: 'Case rejected',
      caseId: emergency._id,
      status: 'pending',
    });
  } catch (error) {
    res.status(500).json({ message: 'Rejection failed', error: error.message });
  }
};

// Police updates case status with location
const updateCaseStatus = async (req, res) => {
  try {
    const { caseId } = req.params;
    const { status, latitude, longitude } = req.body;

    if (!['in-progress', 'at-location', 'providing-help'].includes(status)) {
      return res.status(400).json({ message: 'Invalid status' });
    }

    const emergency = await Alert.findById(caseId);
    if (!emergency) {
      return res.status(404).json({ message: 'Case not found' });
    }

    if (emergency.assignedPolice.toString() !== req.user._id.toString()) {
      return res.status(403).json({ message: 'Case not assigned to you' });
    }

    emergency.status = status;
    if (latitude && longitude) {
      emergency.policeLocation = {
        latitude,
        longitude,
      };
    }
    emergency.lastStatusUpdate = new Date();
    await emergency.save();

    res.status(200).json({
      message: 'Case status updated',
      caseId: emergency._id,
      status,
    });
  } catch (error) {
    res.status(500).json({ message: 'Status update failed', error: error.message });
  }
};

// Police or Hospital resolves case
const resolveCase = async (req, res) => {
  try {
    const { caseId } = req.params;
    const { resolution } = req.body;

    const emergency = await Alert.findById(caseId);
    if (!emergency) {
      return res.status(404).json({ message: 'Case not found' });
    }

    // Verify authorization
    const isPolice = emergency.assignedPolice?.toString() === req.user._id.toString();
    const isHospital = emergency.assignedHospital?.toString() === req.user._id.toString();

    if (!isPolice && !isHospital && req.user.role !== 'admin') {
      return res.status(403).json({ message: 'Not authorized to resolve this case' });
    }

    emergency.status = 'resolved';
    emergency.resolutionDetails = resolution || 'Case resolved';
    emergency.resolvedAt = new Date();
    await emergency.save();

    res.status(200).json({
      message: 'Case resolved',
      caseId: emergency._id,
      status: 'resolved',
    });
  } catch (error) {
    res.status(500).json({ message: 'Resolution failed', error: error.message });
  }
};

// Get all cases assigned to current police
const getAssignedCases = async (req, res) => {
  try {
    if (req.user.role !== 'police') {
      return res.status(403).json({ message: 'Only police can view assigned cases' });
    }

    const cases = await Alert.find({
      assignedPolice: req.user._id,
    }).sort({ createdAt: -1 });

    res.status(200).json({
      count: cases.length,
      cases,
    });
  } catch (error) {
    res.status(500).json({ message: 'Failed to fetch cases', error: error.message });
  }
};

// Get all pending cases (for dispatcher)
const getPendingCases = async (req, res) => {
  try {
    if (req.user.role !== 'admin' && req.user.role !== 'dispatcher') {
      return res.status(403).json({ message: 'Not authorized' });
    }

    const cases = await Alert.find({
      status: 'pending',
    }).sort({ createdAt: -1 });

    res.status(200).json({
      count: cases.length,
      cases,
    });
  } catch (error) {
    res.status(500).json({ message: 'Failed to fetch cases', error: error.message });
  }
};

module.exports = {
  assignCaseToPolice,
  acceptCase,
  rejectCase,
  updateCaseStatus,
  resolveCase,
  getAssignedCases,
  getPendingCases,
};
