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

// Generate FIR for case (Police)
const generateFIR = async (req, res) => {
  try {
    const { caseId } = req.params;
    const { firstInformationReport, witnessNames, vehicleNumbers } = req.body;

    const caseDoc = await Alert.findById(caseId);
    if (!caseDoc) {
      return res.status(404).json({ message: 'Case not found' });
    }

    if (caseDoc.assignedPolice?.toString() !== req.user._id.toString() && req.user.role !== 'admin') {
      return res.status(403).json({ message: 'Not authorized to generate FIR' });
    }

    const fir = {
      generatedBy: req.user._id,
      generatedAt: new Date(),
      firNumber: `FIR-${Date.now()}-${Math.random().toString(36).slice(2, 7).toUpperCase()}`,
      description: firstInformationReport || '',
      witnessNames: witnessNames || [],
      vehicleNumbers: vehicleNumbers || [],
      caseId: caseId,
      status: 'active',
    };

    caseDoc.firDetails = fir;
    caseDoc.auditTrail = caseDoc.auditTrail || [];
    caseDoc.auditTrail.push({ 
      action: 'FIR_GENERATED', 
      actor: req.user._id, 
      timestamp: new Date(), 
      details: fir.firNumber 
    });
    await caseDoc.save();

    res.status(201).json({
      message: 'FIR generated successfully',
      fir,
      caseId: caseDoc._id,
    });
  } catch (error) {
    res.status(500).json({ message: 'FIR generation failed', error: error.message });
  }
};

// Search cases with filters (Police/Admin)
const searchCases = async (req, res) => {
  try {
    const { status, location, type, startDate, endDate, assignedPolice } = req.query;
    const filters = {};

    if (status) filters.status = status;
    if (type) filters.type = type;
    if (assignedPolice) filters.assignedPolice = assignedPolice;

    if (startDate || endDate) {
      filters.createdAt = {};
      if (startDate) filters.createdAt.$gte = new Date(startDate);
      if (endDate) filters.createdAt.$lte = new Date(endDate);
    }

    // Location-based search (simple distance check - you'd use geospatial for production)
    let cases = await Alert.find(filters)
      .populate('userId', 'name phone')
      .populate('assignedPolice', 'name phone policeDetails')
      .sort({ createdAt: -1 })
      .limit(100);

    if (location) {
      const { latitude, longitude, radius = 5 } = location; // radius in km
      cases = cases.filter(c => {
        const distance = Math.sqrt(
          Math.pow(c.location.latitude - latitude, 2) +
          Math.pow(c.location.longitude - longitude, 2)
        ) * 111; // rough km conversion
        return distance <= radius;
      });
    }

    res.status(200).json({
      count: cases.length,
      cases,
    });
  } catch (error) {
    res.status(500).json({ message: 'Search failed', error: error.message });
  }
};

// Get case statistics (Admin/Police)
const getCaseStatistics = async (req, res) => {
  try {
    const { startDate, endDate } = req.query;

    let dateFilter = {};
    if (startDate || endDate) {
      dateFilter.createdAt = {};
      if (startDate) dateFilter.createdAt.$gte = new Date(startDate);
      if (endDate) dateFilter.createdAt.$lte = new Date(endDate);
    }

    const totalCases = await Alert.countDocuments(dateFilter);
    const resolvedCases = await Alert.countDocuments({
      ...dateFilter,
      status: 'resolved',
    });
    const pendingCases = await Alert.countDocuments({
      ...dateFilter,
      status: 'pending',
    });
    const inProgressCases = await Alert.countDocuments({
      ...dateFilter,
      status: 'in-progress',
    });

    const avgResolutionTime = await Alert.aggregate([
      { $match: { ...dateFilter, status: 'resolved' } },
      {
        $group: {
          _id: null,
          avgTime: {
            $avg: {
              $subtract: ['$resolvedAt', '$createdAt'],
            },
          },
        },
      },
    ]);

    res.status(200).json({
      statistics: {
        totalCases,
        resolvedCases,
        resolutionRate: totalCases > 0 ? ((resolvedCases / totalCases) * 100).toFixed(2) : 0,
        pendingCases,
        inProgressCases,
        avgResolutionTimeMs:
          avgResolutionTime.length > 0
            ? Math.round(avgResolutionTime[0].avgTime)
            : 0,
      },
    });
  } catch (error) {
    res.status(500).json({ message: 'Statistics failed', error: error.message });
  }
};

// Update witness details
const updateWitnesses = async (req, res) => {
  try {
    const { caseId } = req.params;
    const { witnesses } = req.body;

    if (!Array.isArray(witnesses)) {
      return res.status(400).json({ message: 'Witnesses must be an array' });
    }

    const caseDoc = await Alert.findById(caseId);
    if (!caseDoc) {
      return res.status(404).json({ message: 'Case not found' });
    }

    caseDoc.witnesses = witnesses;
    caseDoc.auditTrail = caseDoc.auditTrail || [];
    caseDoc.auditTrail.push({
      action: 'WITNESSES_UPDATED',
      actor: req.user._id,
      timestamp: new Date(),
      details: `${witnesses.length} witnesses added`,
    });
    await caseDoc.save();

    res.status(200).json({
      message: 'Witnesses updated',
      witnesses: caseDoc.witnesses,
    });
  } catch (error) {
    res.status(500).json({ message: 'Update failed', error: error.message });
  }
};

// Close/archive case (Admin only)
const closeCase = async (req, res) => {
  try {
    const { caseId } = req.params;
    const { closureReason } = req.body;

    if (req.user.role !== 'admin') {
      return res.status(403).json({ message: 'Only admin can close cases' });
    }

    const caseDoc = await Alert.findById(caseId);
    if (!caseDoc) {
      return res.status(404).json({ message: 'Case not found' });
    }

    caseDoc.status = 'closed';
    caseDoc.closedAt = new Date();
    caseDoc.closureReason = closureReason || 'Case closed';
    caseDoc.auditTrail = caseDoc.auditTrail || [];
    caseDoc.auditTrail.push({
      action: 'CASE_CLOSED',
      actor: req.user._id,
      timestamp: new Date(),
      details: closureReason,
    });
    await caseDoc.save();

    res.status(200).json({
      message: 'Case closed successfully',
      caseId: caseDoc._id,
    });
  } catch (error) {
    res.status(500).json({ message: 'Case closure failed', error: error.message });
  }
};

// Add audio/video evidence
const addMediaEvidence = async (req, res) => {
  try {
    const { caseId } = req.params;
    if (!req.file) {
      return res.status(400).json({ message: 'No file uploaded' });
    }

    const caseDoc = await Alert.findById(caseId);
    if (!caseDoc) {
      return res.status(404).json({ message: 'Case not found' });
    }

    const mediaEvidence = {
      type: 'media',
      mediaType: req.file.mimetype,
      url: `/uploads/case_attachments/${req.file.filename}`,
      filename: req.file.originalname,
      size: req.file.size,
      uploadedBy: req.user._id,
      uploadedAt: new Date(),
      chainOfCustody: [
        {
          actor: req.user._id,
          action: 'UPLOADED',
          timestamp: new Date(),
          notes: 'Initial upload',
        },
      ],
    };

    caseDoc.evidence = caseDoc.evidence || [];
    caseDoc.evidence.push(mediaEvidence);
    caseDoc.auditTrail = caseDoc.auditTrail || [];
    caseDoc.auditTrail.push({
      action: 'MEDIA_EVIDENCE_ADDED',
      actor: req.user._id,
      timestamp: new Date(),
      details: req.file.originalname,
    });
    await caseDoc.save();

    res.status(201).json({
      message: 'Media evidence uploaded',
      mediaEvidence,
    });
  } catch (error) {
    res.status(500).json({ message: 'Media upload failed', error: error.message });
  }
};

// Track evidence chain of custody
const updateEvidenceChain = async (req, res) => {
  try {
    const { caseId, evidenceId } = req.params;
    const { action, notes } = req.body;

    const caseDoc = await Alert.findById(caseId);
    if (!caseDoc) {
      return res.status(404).json({ message: 'Case not found' });
    }

    const evidence = caseDoc.evidence?.find(
      e => e._id?.toString() === evidenceId || e.referenceId === evidenceId
    );
    if (!evidence) {
      return res.status(404).json({ message: 'Evidence not found' });
    }

    evidence.chainOfCustody = evidence.chainOfCustody || [];
    evidence.chainOfCustody.push({
      actor: req.user._id,
      action: action || 'HANDLED',
      timestamp: new Date(),
      notes: notes || '',
    });

    await caseDoc.save();

    res.status(200).json({
      message: 'Chain of custody updated',
      chainOfCustody: evidence.chainOfCustody,
    });
  } catch (error) {
    res.status(500).json({ message: 'Update failed', error: error.message });
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
  addAttachment,
  deleteAttachment,
  addEvidence,
  deleteEvidence,
  generateFIR,
  searchCases,
  getCaseStatistics,
  updateWitnesses,
  closeCase,
  addMediaEvidence,
  updateEvidenceChain,
};
