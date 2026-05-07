const express = require('express');
const {
  updateAmbulanceLocation,
  getAmbulanceLocation,
  getHospitalAmbulances,
  assignAmbulanceToCase,
  markAmbulanceArrived,
  markAmbulanceCompleted,
  getAmbulanceAssignments,
  getAmbulanceStats,
  updateAmbulanceStatus,
} = require('../controllers/ambulance.controller');
const { verifyToken } = require('../middleware/auth.middleware');
const { requireRole, requireApproved } = require('../middleware/role.middleware');

const router = express.Router();

// ============== AMBULANCE DRIVER ROUTES ==============

// Driver fetches their assignments
router.get(
  '/assignments',
  verifyToken,
  requireRole('ambulance'),
  getAmbulanceAssignments
);

// Driver fetches their stats
router.get(
  '/stats',
  verifyToken,
  requireRole('ambulance'),
  getAmbulanceStats
);

// Driver updates their online status
router.put(
  '/status',
  verifyToken,
  requireRole('ambulance'),
  updateAmbulanceStatus
);

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
