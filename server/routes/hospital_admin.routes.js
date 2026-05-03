const express = require('express');
const {
  requestHospitalAccount,
  getPendingHospitalRequests,
  approveHospitalRequest,
  rejectHospitalRequest,
  getAllActiveHospitals,
  updateBedAvailability,
  updateHospitalProfile,
} = require('../controllers/hospital_admin.controller');
const { verifyToken } = require('../middleware/auth.middleware');
const { requireRole, requireApproved, requireNotBlocked } = require('../middleware/role.middleware');

const router = express.Router();

// Hospital registration request
router.post('/register', requestHospitalAccount);

// Get all active hospitals
router.get('/active', verifyToken, getAllActiveHospitals);

// Hospital updates its bed availability
router.post('/update-beds', verifyToken, requireRole('hospital'), requireApproved, requireNotBlocked, updateBedAvailability);

// Hospital updates its profile
router.put('/profile', verifyToken, requireRole('hospital'), requireApproved, requireNotBlocked, updateHospitalProfile);

// ============== ADMIN ONLY ==============
router.get('/pending', verifyToken, requireRole('admin'), getPendingHospitalRequests);
router.post('/approve/:hospitalId', verifyToken, requireRole('admin'), approveHospitalRequest);
router.post('/reject/:hospitalId', verifyToken, requireRole('admin'), rejectHospitalRequest);

module.exports = router;
