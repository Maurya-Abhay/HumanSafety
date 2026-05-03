// Case assignment and management controller
const Alert = require('../models/alert.model');
const User = require('../models/user.model');

// Create a new case (used by admin/dispatcher or automated systems)
const createCase = async (req, res) => {
  try {
    const { type, location, description, metadata, attachments, tags } = req.body;
    if (!location || !location.latitude || !location.longitude) {
      return res.status(400).json({ message: 'Valid location required' });
    }

    const caseDoc = await Alert.create({
      userId: req.user?._id || null,
      type: type || 'help',
      location,
      description: description || '',
      metadata: metadata || {},
      attachments: attachments || [],
      tags: tags || [],
      status: 'pending',
    });

    return res.status(201).json({ message: 'Case created', caseId: caseDoc._id });
  } catch (error) {
    return res.status(500).json({ message: 'Case creation failed', error: error.message });
  }
};

// Get case details
const getCaseById = async (req, res) => {
  try {
    const { caseId } = req.params;
    const caseDoc = await Alert.findById(caseId)
      .populate('userId', 'name phone')
      .populate('assignedPolice', 'name phone policeDetails')
      .populate('assignedHospital', 'hospitalDetails');

    if (!caseDoc) return res.status(404).json({ message: 'Case not found' });
    return res.status(200).json(caseDoc);
  } catch (error) {
    return res.status(500).json({ message: 'Failed to fetch case', error: error.message });
  }
};

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

// Add file attachment to a case (expects multipart/form-data with field 'file')
const addAttachment = async (req, res) => {
  try {
    const { caseId } = req.params;
    if (!req.file) return res.status(400).json({ message: 'No file uploaded' });

    const caseDoc = await Alert.findById(caseId);
    if (!caseDoc) return res.status(404).json({ message: 'Case not found' });

    const file = req.file;
    const attachment = {
      url: `/uploads/case_attachments/${file.filename}`,
      filename: file.originalname,
      mimeType: file.mimetype,
      uploadedBy: req.user?._id || null,
      uploadedAt: new Date(),
      size: file.size,
    };

    caseDoc.attachments = caseDoc.attachments || [];
    caseDoc.attachments.push(attachment);
    caseDoc.auditTrail = caseDoc.auditTrail || [];
    caseDoc.auditTrail.push({ action: 'ATTACHMENT_ADDED', actor: req.user?._id, timestamp: new Date(), details: attachment.filename });
    await caseDoc.save();

    return res.status(201).json({ message: 'Attachment added', attachment });
  } catch (error) {
    return res.status(500).json({ message: 'Attachment upload failed', error: error.message });
  }
};

// Add evidence metadata to a case
const addEvidence = async (req, res) => {
  try {
    const { caseId } = req.params;
    const { type, description, referenceId } = req.body;

    const caseDoc = await Alert.findById(caseId);
    if (!caseDoc) return res.status(404).json({ message: 'Case not found' });

    const evidence = {
      type: type || 'photo',
      description: description || '',
      referenceId: referenceId || '',
      chainOfCustody: [ { actor: req.user?._id || null, action: 'COLLECTED', timestamp: new Date(), notes: '' } ],
    };

    caseDoc.evidence = caseDoc.evidence || [];
    caseDoc.evidence.push(evidence);
    caseDoc.auditTrail = caseDoc.auditTrail || [];
    caseDoc.auditTrail.push({ action: 'EVIDENCE_ADDED', actor: req.user?._id, timestamp: new Date(), details: evidence.type });
    await caseDoc.save();

    return res.status(201).json({ message: 'Evidence added', evidence });
  } catch (error) {
    return res.status(500).json({ message: 'Adding evidence failed', error: error.message });
  }
};

// Delete attachment by filename
const deleteAttachment = async (req, res) => {
  try {
    const { caseId, attachmentId } = req.params; // attachmentId holds filename in our simple scheme
    const caseDoc = await Alert.findById(caseId);
    if (!caseDoc) return res.status(404).json({ message: 'Case not found' });

    const idx = caseDoc.attachments.findIndex(a => a.filename === attachmentId || a._id?.toString() === attachmentId);
    if (idx === -1) return res.status(404).json({ message: 'Attachment not found' });

    const removed = caseDoc.attachments.splice(idx, 1)[0];
    caseDoc.auditTrail = caseDoc.auditTrail || [];
    caseDoc.auditTrail.push({ action: 'ATTACHMENT_REMOVED', actor: req.user?._id, timestamp: new Date(), details: removed.filename });
    await caseDoc.save();

    return res.status(200).json({ message: 'Attachment removed', removed });
  } catch (error) {
    return res.status(500).json({ message: 'Deleting attachment failed', error: error.message });
  }
};

// Delete evidence by index or referenceId
const deleteEvidence = async (req, res) => {
  try {
    const { caseId, evidenceId } = req.params; // evidenceId may be index or referenceId
    const caseDoc = await Alert.findById(caseId);
    if (!caseDoc) return res.status(404).json({ message: 'Case not found' });

    let idx = -1;
    if (/^\d+$/.test(evidenceId)) {
      idx = parseInt(evidenceId, 10);
    } else {
      idx = caseDoc.evidence.findIndex(e => e.referenceId === evidenceId);
    }

    if (idx < 0 || idx >= (caseDoc.evidence || []).length) return res.status(404).json({ message: 'Evidence not found' });

    const removed = caseDoc.evidence.splice(idx, 1)[0];
    caseDoc.auditTrail = caseDoc.auditTrail || [];
    caseDoc.auditTrail.push({ action: 'EVIDENCE_REMOVED', actor: req.user?._id, timestamp: new Date(), details: removed.referenceId || removed.type });
    await caseDoc.save();

    return res.status(200).json({ message: 'Evidence removed', removed });
  } catch (error) {
    return res.status(500).json({ message: 'Deleting evidence failed', error: error.message });
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
  createCase,
  getCaseById,
  // deleteCase handled below
};
