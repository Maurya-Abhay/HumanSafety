const Ambulance = require('../models/ambulance.model');
const Alert = require('../models/alert.model');
const User = require('../models/user.model');
const { calculateDistance, calculateETA } = require('../services/location.service');

// Update ambulance location (real-time tracking)
const updateAmbulanceLocation = async (req, res) => {
  try {
    const { latitude, longitude, address } = req.body;
    const hospitalId = req.user._id;

    if (!latitude || !longitude) {
      return res.status(400).json({ success: false, message: 'Latitude and longitude required' });
    }

    let ambulance = await Ambulance.findOne({ hospitalId });

    if (!ambulance) {
      return res.status(404).json({ success: false, message: 'Ambulance not found' });
    }

    // Update location
    ambulance.currentLocation = {
      latitude,
      longitude,
      address: address || 'Unknown location',
      updatedAt: new Date(),
    };

    // Add to location history (keep last 100)
    ambulance.locationHistory.push({
      latitude,
      longitude,
      timestamp: new Date(),
    });
    if (ambulance.locationHistory.length > 100) {
      ambulance.locationHistory = ambulance.locationHistory.slice(-100);
    }

    // Update online status
    ambulance.lastHeartbeat = new Date();
    ambulance.isOnline = true;

    // Calculate ETA if destination is set
    if (ambulance.destination?.latitude && ambulance.destination?.longitude) {
      const distance = calculateDistance(
        latitude,
        longitude,
        ambulance.destination.latitude,
        ambulance.destination.longitude
      );
      ambulance.estimatedDistance = distance;
      ambulance.eta = {
        estimatedMinutes: calculateETA(distance, ambulance.averageSpeed || 40),
        calculatedAt: new Date(),
      };
    }

    await ambulance.save();

    res.status(200).json({
      success: true,
      message: 'Location updated',
      ambulance: {
        id: ambulance._id,
        currentLocation: ambulance.currentLocation,
        eta: ambulance.eta,
        status: ambulance.status,
      },
    });
  } catch (error) {
    res.status(500).json({ success: false, message: 'Location update failed', error: error.message });
  }
};

// Accept emergency assignment
const acceptEmergency = async (req, res) => {
  try {
    const { emergencyId } = req.params;
    const { eta } = req.body;
    const hospitalId = req.user._id;

    const ambulance = await Ambulance.findOne({ hospitalId });
    if (!ambulance) {
      return res.status(404).json({ success: false, message: 'Ambulance not found' });
    }

    const emergency = await Alert.findById(emergencyId);
    if (!emergency) {
      return res.status(404).json({ success: false, message: 'Emergency not found' });
    }

    // Assign case to ambulance
    ambulance.assignedCaseId = emergencyId;
    ambulance.status = 'in-transit';
    ambulance.destination = {
      latitude: emergency.location.latitude,
      longitude: emergency.location.longitude,
      address: emergency.location.address || 'Emergency location',
    };

    ambulance.activityLog = ambulance.activityLog || [];
    ambulance.activityLog.push({
      action: 'assigned',
      caseId: emergencyId,
      timestamp: new Date(),
      details: 'Case assigned by hospital',
    });

    await ambulance.save();

    // Update emergency with ambulance status
    emergency.status = 'in-progress';
    emergency.metadata = emergency.metadata || {};
    emergency.metadata.ambulanceAssigned = {
      ambulanceId: ambulance._id,
      hospitalId,
      assignedAt: new Date(),
      eta: eta || Math.ceil(calculateDistance(
        ambulance.currentLocation?.latitude || 0,
        ambulance.currentLocation?.longitude || 0,
        emergency.location.latitude,
        emergency.location.longitude
      ) / 40),
    };

    await emergency.save();

    res.status(200).json({
      success: true,
      message: 'Emergency accepted',
      ambulance: {
        id: ambulance._id,
        status: ambulance.status,
        destination: ambulance.destination,
        eta: ambulance.eta,
      },
    });
  } catch (error) {
    res.status(500).json({ success: false, message: 'Acceptance failed', error: error.message });
  }
};

// Mark ambulance arrived at scene
const markArrived = async (req, res) => {
  try {
    const { emergencyId } = req.params;
    const hospitalId = req.user._id;

    const ambulance = await Ambulance.findOne({ hospitalId });
    if (!ambulance) {
      return res.status(404).json({ success: false, message: 'Ambulance not found' });
    }

    ambulance.status = 'at-location';
    ambulance.activityLog = ambulance.activityLog || [];
    ambulance.activityLog.push({
      action: 'arrived',
      caseId: emergencyId,
      timestamp: new Date(),
      details: 'Ambulance arrived at scene',
    });

    await ambulance.save();

    res.status(200).json({
      success: true,
      message: 'Marked as arrived',
      status: ambulance.status,
    });
  } catch (error) {
    res.status(500).json({ success: false, message: 'Update failed', error: error.message });
  }
};

// Mark ambulance completed case
const completeEmergency = async (req, res) => {
  try {
    const { emergencyId } = req.params;
    const { patientCondition, treatmentGiven } = req.body;
    const hospitalId = req.user._id;

    const ambulance = await Ambulance.findOne({ hospitalId });
    if (!ambulance) {
      return res.status(404).json({ success: false, message: 'Ambulance not found' });
    }

    ambulance.status = 'available';
    ambulance.assignedCaseId = null;
    ambulance.destination = { latitude: null, longitude: null, address: '' };
    ambulance.eta = { estimatedMinutes: 0, calculatedAt: new Date() };

    ambulance.activityLog = ambulance.activityLog || [];
    ambulance.activityLog.push({
      action: 'completed',
      caseId: emergencyId,
      timestamp: new Date(),
      details: `${treatmentGiven || 'First aid provided'} - ${patientCondition || 'Stable'}`,
    });

    await ambulance.save();

    // Update emergency status
    const emergency = await Alert.findById(emergencyId);
    if (emergency) {
      emergency.status = 'resolved';
      emergency.metadata = emergency.metadata || {};
      emergency.metadata.resolution = {
        resolvedAt: new Date(),
        patientCondition,
        treatmentGiven,
      };
      await emergency.save();
    }

    res.status(200).json({
      success: true,
      message: 'Emergency completed',
      ambulance: {
        id: ambulance._id,
        status: ambulance.status,
      },
    });
  } catch (error) {
    res.status(500).json({ success: false, message: 'Completion failed', error: error.message });
  }
};

// Get ambulance current status
const getAmbulanceStatus = async (req, res) => {
  try {
    const hospitalId = req.user._id;

    const ambulance = await Ambulance.findOne({ hospitalId })
      .populate('assignedCaseId', 'location description');

    if (!ambulance) {
      return res.status(404).json({ success: false, message: 'Ambulance not found' });
    }

    res.status(200).json({
      success: true,
      ambulance: {
        id: ambulance._id,
        licenseNumber: ambulance.licenseNumber,
        driverName: ambulance.driverName,
        status: ambulance.status,
        currentLocation: ambulance.currentLocation,
        destination: ambulance.destination,
        eta: ambulance.eta,
        assignedCase: ambulance.assignedCaseId,
        isOnline: ambulance.isOnline,
        lastHeartbeat: ambulance.lastHeartbeat,
      },
    });
  } catch (error) {
    res.status(500).json({ success: false, message: 'Failed to fetch status', error: error.message });
  }
};

// Get location history
const getLocationHistory = async (req, res) => {
  try {
    const hospitalId = req.user._id;
    const { limit = 50 } = req.query;

    const ambulance = await Ambulance.findOne({ hospitalId })
      .select('locationHistory');

    if (!ambulance) {
      return res.status(404).json({ success: false, message: 'Ambulance not found' });
    }

    const history = ambulance.locationHistory.slice(-parseInt(limit));

    res.status(200).json({
      success: true,
      count: history.length,
      history,
    });
  } catch (error) {
    res.status(500).json({ success: false, message: 'History fetch failed', error: error.message });
  }
};

// Get ambulance activity log
const getActivityLog = async (req, res) => {
  try {
    const hospitalId = req.user._id;
    const { limit = 20 } = req.query;

    const ambulance = await Ambulance.findOne({ hospitalId });

    if (!ambulance) {
      return res.status(404).json({ success: false, message: 'Ambulance not found' });
    }

    const log = (ambulance.activityLog || []).slice(-parseInt(limit));

    res.status(200).json({
      success: true,
      count: log.length,
      activityLog: log,
    });
  } catch (error) {
    res.status(500).json({ success: false, message: 'Log fetch failed', error: error.message });
  }
};

const getAmbulanceLocation = async (req, res) => {
  try {
    const { ambulanceId } = req.params;

    const ambulance = await Ambulance.findById(ambulanceId)
      .select('currentLocation destination eta status driverName assignedPatientName locationHistory estimatedDistance');

    if (!ambulance) {
      return res.status(404).json({ message: 'Ambulance not found' });
    }

    res.status(200).json({
      id: ambulance._id,
      currentLocation: ambulance.currentLocation,
      destination: ambulance.destination,
      eta: ambulance.eta,
      status: ambulance.status,
      driverName: ambulance.driverName,
      assignedPatientName: ambulance.assignedPatientName,
      estimatedDistance: ambulance.estimatedDistance,
      recentPath: ambulance.locationHistory.slice(-10), // Last 10 points for map visualization
    });
  } catch (error) {
    res.status(500).json({ message: 'Failed to fetch ambulance location', error: error.message });
  }
};

// Get hospital's ambulances
const getHospitalAmbulances = async (req, res) => {
  try {
    const hospitalId = req.user._id;

    const ambulances = await Ambulance.find({ hospitalId })
      .select('licenseNumber driverName status currentLocation eta assignedPatientName isOnline');

    res.status(200).json({
      count: ambulances.length,
      ambulances: ambulances.map(a => ({
        id: a._id,
        licenseNumber: a.licenseNumber,
        driverName: a.driverName,
        status: a.status,
        location: a.currentLocation,
        eta: a.eta,
        assignedPatient: a.assignedPatientName,
        isOnline: a.isOnline,
      })),
    });
  } catch (error) {
    res.status(500).json({ message: 'Failed to fetch ambulances', error: error.message });
  }
};

// Assign ambulance to emergency case
const assignAmbulanceToCase = async (req, res) => {
  try {
    const { ambulanceId, emergencyId, patientName, destinationLat, destinationLng } = req.body;

    if (!ambulanceId || !emergencyId) {
      return res.status(400).json({ message: 'ambulanceId and emergencyId required' });
    }

    const ambulance = await Ambulance.findById(ambulanceId);
    if (!ambulance) {
      return res.status(404).json({ message: 'Ambulance not found' });
    }

    ambulance.assignedCaseId = emergencyId;
    ambulance.assignedPatientName = patientName || 'Patient';
    ambulance.status = 'in-transit';

    if (destinationLat && destinationLng) {
      ambulance.destination = {
        latitude: destinationLat,
        longitude: destinationLng,
        address: 'Emergency location',
      };
    }

    ambulance.activityLog.push({
      action: 'assigned',
      caseId: emergencyId,
      timestamp: new Date(),
      details: `Assigned to patient ${patientName}`,
    });

    await ambulance.save();

    res.status(200).json({
      message: 'Ambulance assigned',
      ambulance: {
        id: ambulance._id,
        status: ambulance.status,
        assignedTo: patientName,
      },
    });
  } catch (error) {
    res.status(500).json({ message: 'Failed to assign ambulance', error: error.message });
  }
};

// Mark ambulance as arrived at location
const markAmbulanceArrived = async (req, res) => {
  try {
    const { ambulanceId } = req.params;

    const ambulance = await Ambulance.findById(ambulanceId);
    if (!ambulance) {
      return res.status(404).json({ message: 'Ambulance not found' });
    }

    ambulance.status = 'at-location';
    ambulance.eta = {
      estimatedMinutes: 0,
      calculatedAt: new Date(),
    };

    ambulance.activityLog.push({
      action: 'arrived',
      caseId: ambulance.assignedCaseId,
      timestamp: new Date(),
      details: 'Arrived at emergency location',
    });

    await ambulance.save();

    res.status(200).json({
      message: 'Ambulance status updated',
      status: ambulance.status,
    });
  } catch (error) {
    res.status(500).json({ message: 'Failed to update ambulance status', error: error.message });
  }
};

// Mark ambulance as completed (returning to hospital)
const markAmbulanceCompleted = async (req, res) => {
  try {
    const { ambulanceId } = req.params;

    const ambulance = await Ambulance.findById(ambulanceId);
    if (!ambulance) {
      return res.status(404).json({ message: 'Ambulance not found' });
    }

    ambulance.status = 'available';
    ambulance.assignedCaseId = null;
    ambulance.assignedPatientName = '';
    ambulance.destination = { latitude: null, longitude: null, address: '' };

    ambulance.activityLog.push({
      action: 'completed',
      caseId: ambulance.assignedCaseId,
      timestamp: new Date(),
      details: 'Case completed, returning to available status',
    });

    await ambulance.save();

    res.status(200).json({
      message: 'Ambulance marked as completed',
      status: ambulance.status,
    });
  } catch (error) {
    res.status(500).json({ message: 'Failed to mark ambulance completed', error: error.message });
  }
};

module.exports = {
  updateAmbulanceLocation,
  getAmbulanceLocation,
  getHospitalAmbulances,
  assignAmbulanceToCase,
  markAmbulanceArrived,
  markAmbulanceCompleted,
};
