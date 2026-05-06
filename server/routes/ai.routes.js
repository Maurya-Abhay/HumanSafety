const express = require('express');
const router = express.Router();
const aiController = require('../controllers/ai.controller');
const { verifyToken } = require('../middleware/auth.middleware');
const { requireRole } = require('../middleware/role.middleware');

/**
 * POST /api/v1/ai/profile
 * Save/update user AI profile (Called by AI Engine)
 */
router.post('/profile', aiController.saveProfile);

/**
 * GET /api/v1/ai/profile/:userId
 * Get user AI profile
 */
router.get('/profile/:userId', verifyToken, aiController.getProfile);

/**
 * POST /api/v1/ai/behavior-history
 * Save behavior history for learning (Called by AI Engine)
 */
router.post('/behavior-history', aiController.saveBehaviorHistory);

/**
 * POST /api/v1/ai/model-state
 * Save model state (Called by AI Engine)
 */
router.post('/model-state', aiController.saveModelState);

/**
 * GET /api/v1/ai/model-state/:modelName
 * Get model state (Called by AI Engine)
 */
router.get('/model-state/:modelName', aiController.getModelState);

/**
 * POST /api/v1/ai/prediction
 * Save AI prediction for analytics (Called by AI Engine)
 */
router.post('/prediction', aiController.savePrediction);

/**
 * GET /api/v1/ai/prediction-history/:userId
 * Get prediction history for analytics
 */
router.get('/prediction-history/:userId', verifyToken, aiController.getPredictionHistory);

/**
 * GET /api/v1/ai/analytics
 * Get AI analytics dashboard (Admin only)
 */
router.get('/analytics', verifyToken, requireRole('admin'), aiController.getAnalytics);

module.exports = router;
