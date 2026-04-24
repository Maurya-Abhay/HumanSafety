const express = require('express');
const { analyzeAccident } = require('../controllers/accident.controller');
const { verifyToken } = require('../middleware/auth.middleware');
const { validateAnalyzeAccident } = require('../middleware/validation.middleware');

const router = express.Router();

// POST /accident/analyze - Analyze sensor data for accident detection
router.post('/analyze', verifyToken, validateAnalyzeAccident, analyzeAccident);

module.exports = router;
