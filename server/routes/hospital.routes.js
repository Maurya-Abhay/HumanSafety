const express = require('express');
const { 
  requestHospital, 
  getNearbyHospitals,
  getHospitalAlerts,
} = require('../controllers/hospital.controller');
const { verifyToken } = require('../middleware/auth.middleware');
const { requireRole, requireApproved } = require('../middleware/role.middleware');

const router = express.Router();

router.post('/request', verifyToken, requestHospital);
router.get('/nearby', verifyToken, getNearbyHospitals);

// Get hospital alerts (emergency cases)
router.get('/alerts', verifyToken, requireRole('hospital'), requireApproved, getHospitalAlerts);

module.exports = router;
