const express = require('express');
const { 
  requestPoliceAccount, 
  getPendingPoliceRequests, 
  approvePolicRequest, 
  rejectPoliceRequest,
  getAllPoliceOfficers,
} = require('../controllers/police.controller');
const { verifyToken } = require('../middleware/auth.middleware');
const { requireRole, requireApproved, requireNotBlocked } = require('../middleware/role.middleware');

const router = express.Router();

// Police registration request
router.post('/register', requestPoliceAccount);

// Get all police officers (for case dispatch)
router.get('/officers', verifyToken, getAllPoliceOfficers);

// ============== ADMIN ONLY ==============
router.get('/pending', verifyToken, requireRole('admin'), getPendingPoliceRequests);
router.post('/approve/:userId', verifyToken, requireRole('admin'), approvePolicRequest);
router.post('/reject/:userId', verifyToken, requireRole('admin'), rejectPoliceRequest);

module.exports = router;
