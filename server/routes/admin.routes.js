const express = require('express');
const {
  getDashboardStats,
  getAllUsers,
  getUserDetails,
  blockUser,
  unblockUser,
  getPendingRequests,
  getSystemAnalytics,
  addAdminNotes,
  getRoleApplications,
  approveRoleApplication,
  rejectRoleApplication,
} = require('../controllers/admin.controller');
const { verifyToken } = require('../middleware/auth.middleware');
const { requireRole } = require('../middleware/role.middleware');

const router = express.Router();

// All admin routes require admin role
router.use(verifyToken, requireRole('admin'));

// Dashboard
router.get('/dashboard', getDashboardStats);
router.get('/analytics', getSystemAnalytics);

// User management
router.get('/users', getAllUsers);
router.get('/users/:userId', getUserDetails);
router.post('/users/:userId/block', blockUser);
router.post('/users/:userId/unblock', unblockUser);
router.post('/users/:userId/notes', addAdminNotes);

// Approval requests
router.get('/requests', getPendingRequests);

// Role applications management
router.get('/role-applications', getRoleApplications);
router.post('/role-applications/:appId/approve', approveRoleApplication);
router.post('/role-applications/:appId/reject', rejectRoleApplication);

module.exports = router;
