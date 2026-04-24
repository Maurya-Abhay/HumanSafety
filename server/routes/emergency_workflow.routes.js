const express = require('express');
const {
  triggerEmergency,
  confirmEmergency,
  acceptCase,
  updateCaseStatus,
  resolveCase,
  acceptHospitalRequest,
  rejectHospitalRequest,
  provideFeedback,
  getActiveEmergencies,
  getEmergencyDetails,
} = require('../controllers/emergency_workflow.controller');
const { verifyToken } = require('../middleware/auth.middleware');
const { requireRole, requireApproved } = require('../middleware/role.middleware');

const router = express.Router();

// ============================================================
// EMERGENCY TRIGGER
// ============================================================

// User triggers panic or AI detects accident
router.post(
  '/trigger',
  verifyToken,
  requireRole('user'),
  requireApproved,
  triggerEmergency
);

// Confirm emergency after AI asks
router.post(
  '/:emergencyId/confirm',
  verifyToken,
  requireRole('user'),
  confirmEmergency
);

// ============================================================
// POLICE WORKFLOW
// ============================================================

// Police accepts case (ATOMIC LOCK)
router.post(
  '/:emergencyId/accept',
  verifyToken,
  requireRole('police'),
  requireApproved,
  acceptCase
);

// Police updates status
router.put(
  '/:emergencyId/status',
  verifyToken,
  requireRole('police'),
  requireApproved,
  updateCaseStatus
);

// Police resolves case
router.post(
  '/:emergencyId/resolve',
  verifyToken,
  requireRole('police'),
  requireApproved,
  resolveCase
);

// ============================================================
// HOSPITAL WORKFLOW
// ============================================================

// Hospital accepts emergency request
router.post(
  '/:emergencyId/hospital-accept',
  verifyToken,
  requireRole('hospital'),
  requireApproved,
  acceptHospitalRequest
);

// Hospital rejects emergency request
router.post(
  '/:emergencyId/hospital-reject',
  verifyToken,
  requireRole('hospital'),
  requireApproved,
  rejectHospitalRequest
);

// ============================================================
// AI FEEDBACK
// ============================================================

// User provides feedback on AI accuracy
router.post(
  '/:emergencyId/feedback',
  verifyToken,
  requireRole('user'),
  provideFeedback
);

// ============================================================
// QUERIES
// ============================================================

// Get all active emergencies (admin/police/hospital)
router.get(
  '/list/active',
  verifyToken,
  getActiveEmergencies
);

// Get emergency details
router.get(
  '/:emergencyId/details',
  verifyToken,
  getEmergencyDetails
);

module.exports = router;
