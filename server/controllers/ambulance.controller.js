const Ambulance = require('../models/ambulance.model');
const { calculateDistance, calculateETA } = require('../services/location.service');

// Update ambulance location (from driver)
const updateAmbulanceLocation = async (req, res) => {
  try {
    const { latitude, longitude, address } = req.body;
    const hospitalId = req.user._id;

    if (!latitude || !longitude) {
      return res.status(400).json({ message: 'Latitude and longitude required' });
    }

    // Find or create ambulance for driver (assume one ambulance per hospital for MVP)
    let ambulance = await Ambulance.findOne({ hospitalId });

    if (!ambulance) {
      return res.status(404).json({ message: 'Ambulance not found for this hospital' });
    }

    // Update location
    ambulance.currentLocation = {
      latitude,
      longitude,
      address: address || 'Unknown location',
      updatedAt: new Date(),
    };

    // Add to location history
    ambulance.locationHistory.push({
      latitude,
      longitude,
      timestamp: new Date(),
    });

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
      message: 'Location updated',
      ambulance: {
        id: ambulance._id,
        location: ambulance.currentLocation,
        eta: ambulance.eta,
        status: ambulance.status,
      },
    });
  } catch (error) {
    res.status(500).json({ message: 'Failed to update location', error: error.message });
  }
};

// Get ambulance tracking info (for real-time display)
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
