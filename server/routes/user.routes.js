const express = require('express');
const { getProfile, updateProfile, updateLocation, getLocation, applyRole } = require('../controllers/user.controller');
const { verifyToken } = require('../middleware/auth.middleware');
const { validateUserUpdate, validateLocationUpdate } = require('../middleware/validation.middleware');

const router = express.Router();

// GET /user/profile - Get user profile
router.get('/profile', verifyToken, getProfile);

// PUT /user/profile - Update user profile (or /user/update for compatibility)
router.put('/profile', verifyToken, validateUserUpdate, updateProfile);
router.put('/update', verifyToken, validateUserUpdate, updateProfile);

// POST /user/location - Update user location
router.post('/location', verifyToken, validateLocationUpdate, updateLocation);

// GET /user/location - Get user location
router.get('/location', verifyToken, getLocation);

// POST /user/role-application - Apply for a role
router.post('/role-application', verifyToken, applyRole);

module.exports = router;
