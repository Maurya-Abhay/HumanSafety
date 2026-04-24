const express = require('express');
const {
  assignCaseToPolice,
  acceptCase,
  rejectCase,
  updateCaseStatus,
  resolveCase,
  getAssignedCases,
  getPendingCases,
} = require('../controllers/case.controller');
const { verifyToken } = require('../middleware/auth.middleware');
const { requireRole, requireApproved } = require('../middleware/role.middleware');

const router = express.Router();

// All routes require authentication
router.use(verifyToken);

// Police endpoints
router.get('/assigned', requireRole('police'), requireApproved, getAssignedCases);
router.post('/:caseId/accept', requireRole('police'), requireApproved, acceptCase);
router.post('/:caseId/reject', requireRole('police'), requireApproved, rejectCase);
router.put('/:caseId/status', requireRole('police'), requireApproved, updateCaseStatus);

// Dispatcher/Admin endpoints
router.get('/pending', requireRole('admin'), getPendingCases);
router.post('/assign', requireRole('admin'), assignCaseToPolice);

// Shared endpoints (Police or Hospital can resolve)
router.post('/:caseId/resolve', resolveCase);

module.exports = router;
