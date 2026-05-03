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

// Multer for file uploads
const multer = require('multer');
const fs = require('fs');
const path = require('path');
const uploadDir = path.join(__dirname, '..', 'uploads', 'case_attachments');
if (!fs.existsSync(uploadDir)) fs.mkdirSync(uploadDir, { recursive: true });
const storage = multer.diskStorage({
  destination: (req, file, cb) => cb(null, uploadDir),
  filename: (req, file, cb) => cb(null, `${Date.now()}-${file.originalname.replace(/\s+/g, '_')}`),
});
const upload = multer({ storage });

// Create & query individual cases
const { createCase, getCaseById } = require('../controllers/case.controller');

router.post('/', requireRole('admin'), createCase);
router.get('/:caseId', requireRole('admin'), getCaseById);

// Police endpoints
router.get('/assigned', requireRole('police'), requireApproved, getAssignedCases);
router.post('/:caseId/accept', requireRole('police'), requireApproved, acceptCase);
router.post('/:caseId/reject', requireRole('police'), requireApproved, rejectCase);
router.put('/:caseId/status', requireRole('police'), requireApproved, updateCaseStatus);

// Attachment & Evidence endpoints
const { addAttachment, addEvidence, deleteAttachment, deleteEvidence } = require('../controllers/case.controller');

router.post('/:caseId/attachments', requireApproved, upload.single('file'), addAttachment);
router.delete('/:caseId/attachments/:attachmentId', requireRole('admin'), deleteAttachment);
router.post('/:caseId/evidence', requireRole('police'), requireApproved, addEvidence);
router.delete('/:caseId/evidence/:evidenceId', requireRole('admin'), deleteEvidence);

// Dispatcher/Admin endpoints
router.get('/pending', requireRole('admin'), getPendingCases);
router.post('/assign', requireRole('admin'), assignCaseToPolice);

// Shared endpoints (Police or Hospital can resolve)
router.post('/:caseId/resolve', resolveCase);

module.exports = router;
