const express = require('express');
const {
  updateAmbulanceLocation,
  getAmbulanceLocation,
  getHospitalAmbulances,
  assignAmbulanceToCase,
  markAmbulanceArrived,
  markAmbulanceCompleted,
} = require('../controllers/ambulance.controller');
const { verifyToken } = require('../middleware/auth.middleware');
const { requireRole, requireApproved } = require('../middleware/role.middleware');

const router = express.Router();

// ============== AMBULANCE DRIVER ROUTES ==============

// Driver updates ambulance location (frequent - from GPS)
router.put(
  '/location',
  verifyToken,
  requireRole('hospital', 'ambulance'),
  updateAmbulanceLocation
);

// Driver marks as arrived at emergency location
router.put(
  '/:ambulanceId/arrived',
  verifyToken,
  requireRole('hospital', 'ambulance'),
  markAmbulanceArrived
);

// Driver marks case as completed
router.put(
  '/:ambulanceId/completed',
  verifyToken,
  requireRole('hospital', 'ambulance'),
  markAmbulanceCompleted
);

// ============== HOSPITAL ADMIN ROUTES ==============

// Get all hospital ambulances
router.get(
  '/',
  verifyToken,
  requireRole('hospital'),
  requireApproved,
  getHospitalAmbulances
);

// Get specific ambulance real-time location
router.get(
  '/:ambulanceId/location',
  verifyToken,
  getAmbulanceLocation
);

// Assign ambulance to emergency case
router.post(
  '/:ambulanceId/assign',
  verifyToken,
  requireRole('hospital'),
  requireApproved,
  assignAmbulanceToCase
);

module.exports = router;
