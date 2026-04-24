const express = require('express');
const { triggerPanic, getAlerts, dismissAlert } = require('../controllers/emergency.controller');
const { verifyToken } = require('../middleware/auth.middleware');
const { validatePanicAlert } = require('../middleware/validation.middleware');

const router = express.Router();

// POST /emergency/panic - Trigger emergency panic alert
router.post('/panic', verifyToken, validatePanicAlert, triggerPanic);

// GET /emergency/alerts - Get user's recent alerts
router.get('/alerts', verifyToken, getAlerts);

// PATCH /emergency/alerts/:alertId - Dismiss or update alert
router.patch('/alerts/:alertId', verifyToken, dismissAlert);

module.exports = router;
