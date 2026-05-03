const express = require('express');
const { 
  requestPoliceAccount, 
  getPendingPoliceRequests, 
  approvePolicRequest, 
  rejectPoliceRequest,
  getAllPoliceOfficers,
  getPoliceAlerts,
} = require('../controllers/police.controller');
const { verifyToken } = require('../middleware/auth.middleware');
const { requireRole, requireApproved, requireNotBlocked } = require('../middleware/role.middleware');

const router = express.Router();

// Police registration request
router.post('/register', requestPoliceAccount);

// Get all police officers (for case dispatch)
router.get('/officers', verifyToken, getAllPoliceOfficers);

// Get police alerts (assigned cases)
router.get('/alerts', verifyToken, requireRole('police'), requireApproved, getPoliceAlerts);

// Police case endpoints (aliases to case controller) to match mobile API paths
const { acceptCase, updateCaseStatus } = require('../controllers/case.controller');

// Accept a case (mobile expects PUT /api/v1/police/cases/:caseId/accept)
router.put('/cases/:caseId/accept', verifyToken, requireRole('police'), requireApproved, acceptCase);

// Update case status (mobile expects PUT /api/v1/police/cases/:caseId/update)
router.put('/cases/:caseId/update', verifyToken, requireRole('police'), requireApproved, updateCaseStatus);

// ============== ADMIN ONLY ==============
router.get('/pending', verifyToken, requireRole('admin'), getPendingPoliceRequests);
router.post('/approve/:userId', verifyToken, requireRole('admin'), approvePolicRequest);
router.post('/reject/:userId', verifyToken, requireRole('admin'), rejectPoliceRequest);

module.exports = router;
