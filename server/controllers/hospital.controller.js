const Alert = require('../models/alert.model');
const User = require('../models/user.model');
const { findNearestHospitals, requestAmbulance } = require('../services/hospital.service');
const { validateLocation } = require('../services/location.service');

const requestHospital = async (req, res) => {
  try {
    const { latitude, longitude, emergency } = req.body;
    
    const locCheck = validateLocation(latitude, longitude);
    if (!locCheck.valid) return res.status(400).json({ message: locCheck.message });
    
    const userId = req.user._id || req.user.userId;
    const user = await User.findById(userId);
    if (!user) return res.status(404).json({ message: 'User not found' });
    
    const hospitals = await findNearestHospitals(latitude, longitude, 10);
    if (hospitals.length === 0) {
      return res.status(404).json({ message: 'No hospitals found nearby' });
    }
    
    const alert = await Alert.create({
      userId,
      type: 'hospital',
      location: { latitude, longitude },
      status: 'pending',
      description: 'Hospital request',
      metadata: {
        emergency: emergency || false,
        hospitalCount: hospitals.length,
      },
    });
    
    let successCount = 0;
    for (let i = 0; i < Math.min(hospitals.length, 3); i++) {
      const result = await requestAmbulance(hospitals[i], { latitude, longitude }, user.name);
      if (result.success) successCount++;
    }
    
    res.status(200).json({
      message: 'Hospital request sent',
      hospitals: hospitals.slice(0, 3).map(h => ({
        name: h.name,
        phone: h.phone,
        distance: h.distance.toFixed(1),
      })),
      requestsSent: successCount,
    });
  } catch (error) {
    res.status(500).json({ message: 'Hospital request failed', error: error.message });
  }
};

const getNearbyHospitals = async (req, res) => {
  try {
    const { latitude, longitude } = req.query;
    
    const locCheck = validateLocation(parseFloat(latitude), parseFloat(longitude));
    if (!locCheck.valid) return res.status(400).json({ message: locCheck.message });
    
    const hospitals = await findNearestHospitals(parseFloat(latitude), parseFloat(longitude), 15);
    
    res.status(200).json({
      message: 'Hospitals retrieved',
      count: hospitals.length,
      hospitals: hospitals.map(h => ({
        id: h._id,
        name: h.name,
        phone: h.phone,
        distance: h.distance.toFixed(1),
        ambulance: h.ambulance,
        rating: h.rating,
      })),
    });
  } catch (error) {
    res.status(500).json({ message: 'Failed to get hospitals', error: error.message });
  }
};

// Get hospital alerts (emergency cases)
const mongoose = require('mongoose');

const getHospitalAlerts = async (req, res) => {
  try {
    const userId = req.user && (req.user._id || req.user.userId);
    if (!userId) return res.status(401).json({ message: 'Unauthorized: missing user' });

    // Support metadata.hospitalId stored as either ObjectId or string
    const orClause = [{ 'metadata.hospitalId': userId }];
    if (mongoose.Types.ObjectId.isValid(String(userId))) {
      orClause.push({ 'metadata.hospitalId': mongoose.Types.ObjectId(String(userId)) });
    }

    // Get alerts assigned to this hospital
    const alerts = await Alert.find({
      type: 'hospital',
      status: { $in: ['pending', 'active'] },
      $or: orClause,
    })
      .populate('userId', 'name phone')
      .sort({ createdAt: -1 })
      .limit(20);

    const hospitalAlerts = (alerts || []).map(a => ({
      id: a._id?.toString(),
      caseId: a._id?.toString(),
      title: 'Emergency Case',
      description: a.description || 'Hospital alert',
      status: a.status || 'pending',
      priority: 'high',
      location: a.location || {},
      userId: a.userId?._id?.toString(),
      createdAt: a.createdAt ? a.createdAt.toISOString() : new Date().toISOString(),
    }));

    return res.status(200).json(hospitalAlerts);
  } catch (error) {
    console.error('getHospitalAlerts error:', error);
    return res.status(500).json({ message: 'Failed to fetch alerts', error: String(error) });
  }
};

// Hospital accepts an emergency alert
const acceptAlert = async (req, res) => {
  try {
    const { alertId } = req.params;
    const hospitalId = req.user._id;

    const alert = await Alert.findById(alertId);
    if (!alert) {
      return res.status(404).json({ message: 'Alert not found' });
    }

    if (alert.metadata?.hospitalId?.toString() !== hospitalId.toString()) {
      return res.status(403).json({ message: 'Not authorized to accept this alert' });
    }

    alert.status = 'active';
    alert.metadata = alert.metadata || {};
    alert.metadata.acceptedAt = new Date();
    alert.metadata.acceptedBy = hospitalId;
    await alert.save();

    res.status(200).json({
      message: 'Emergency accepted',
      alert: {
        id: alert._id,
        status: alert.status,
        acceptedAt: alert.metadata.acceptedAt,
      },
    });
  } catch (error) {
    res.status(500).json({ message: 'Failed to accept alert', error: error.message });
  }
};

// Hospital rejects an emergency alert
const rejectAlert = async (req, res) => {
  try {
    const { alertId } = req.params;
    const { reason } = req.body;
    const hospitalId = req.user._id;

    const alert = await Alert.findById(alertId);
    if (!alert) {
      return res.status(404).json({ message: 'Alert not found' });
    }

    if (alert.metadata?.hospitalId?.toString() !== hospitalId.toString()) {
      return res.status(403).json({ message: 'Not authorized to reject this alert' });
    }

    alert.status = 'rejected';
    alert.metadata = alert.metadata || {};
    alert.metadata.rejectionReason = reason || 'No reason provided';
    alert.metadata.rejectedAt = new Date();
    alert.metadata.rejectedBy = hospitalId;
    await alert.save();

    res.status(200).json({
      message: 'Emergency rejected',
      alert: { id: alert._id, status: alert.status },
    });
  } catch (error) {
    res.status(500).json({ message: 'Failed to reject alert', error: error.message });
  }
};

// Hospital updates emergency status
const updateAlertStatus = async (req, res) => {
  try {
    const { alertId } = req.params;
    const { status } = req.body;
    const hospitalId = req.user._id;

    const validStatuses = ['in-progress', 'resolved', 'transferred', 'discharged'];
    if (!validStatuses.includes(status)) {
      return res.status(400).json({
        message: 'Invalid status. Must be one of: ' + validStatuses.join(', '),
      });
    }

    const alert = await Alert.findById(alertId);
    if (!alert) {
      return res.status(404).json({ message: 'Alert not found' });
    }

    if (alert.metadata?.hospitalId?.toString() !== hospitalId.toString()) {
      return res.status(403).json({ message: 'Not authorized to update this alert' });
    }

    alert.status = status;
    alert.metadata = alert.metadata || {};
    alert.metadata.lastStatusUpdate = new Date();
    alert.metadata.lastUpdatedBy = hospitalId;
    alert.metadata.statusHistory = alert.metadata.statusHistory || [];
    alert.metadata.statusHistory.push({
      status,
      updatedAt: new Date(),
      updatedBy: hospitalId,
    });

    await alert.save();

    res.status(200).json({
      message: 'Alert status updated',
      alert: {
        id: alert._id,
        status: alert.status,
        updatedAt: alert.metadata.lastStatusUpdate,
      },
    });
  } catch (error) {
    res.status(500).json({ message: 'Failed to update alert status', error: error.message });
  }
};

module.exports = { requestHospital, getNearbyHospitals, getHospitalAlerts, acceptAlert, rejectAlert, updateAlertStatus };
