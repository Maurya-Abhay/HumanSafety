const express = require('express');
const { 
  requestHospital, 
  getNearbyHospitals,
  getHospitalAlerts,
  acceptAlert,
  rejectAlert,
  updateAlertStatus,
} = require('../controllers/hospital.controller');
const { verifyToken } = require('../middleware/auth.middleware');
const { requireRole, requireApproved } = require('../middleware/role.middleware');

const router = express.Router();

router.post('/request', verifyToken, requestHospital);
router.get('/nearby', verifyToken, getNearbyHospitals);

// Get hospital alerts (emergency cases)
router.get('/alerts', verifyToken, requireRole('hospital'), requireApproved, getHospitalAlerts);

// Hospital accepts an alert
router.put('/alerts/:alertId/accept', verifyToken, requireRole('hospital'), requireApproved, acceptAlert);

// Hospital rejects an alert
router.put('/alerts/:alertId/reject', verifyToken, requireRole('hospital'), requireApproved, rejectAlert);

// Hospital updates alert status
router.put('/alerts/:alertId/status', verifyToken, requireRole('hospital'), requireApproved, updateAlertStatus);

module.exports = router;
