const { AIProfile, BehaviorHistory, AIModelState, AIPrediction } = require('../models/ai.model');
const logger = require('../services/logger.service');

/**
 * Save or update user AI profile
 */
exports.saveProfile = async (req, res) => {
  try {
    const { userId, averageSpeed, averageAcceleration, commonLocations, drivingPatterns, riskProfile, profileCompleteness } = req.body;

    if (!userId) {
      return res.apiError('User ID required', null, 400, 'VALIDATION_FAILED');
    }

    const profile = await AIProfile.findOneAndUpdate(
      { userId },
      {
        userId,
        averageSpeed: averageSpeed || 50,
        averageAcceleration: averageAcceleration || 3.0,
        commonLocations: commonLocations || [],
        drivingPatterns: drivingPatterns || {},
        riskProfile: riskProfile || {},
        profileCompleteness: profileCompleteness || 0,
        updatedAt: new Date()
      },
      { upsert: true, new: true }
    );

    logger.logEvent('AI_PROFILE_SAVED', { userId, profileCompleteness });

    return res.apiSuccess(profile, 'Profile saved successfully', 201);
  } catch (error) {
    logger.logError('Error saving AI profile', error);
    return res.apiError('Failed to save profile', error, 500, 'PROFILE_SAVE_FAILED');
  }
};

/**
 * Get user AI profile
 */
exports.getProfile = async (req, res) => {
  try {
    const { userId } = req.params;

    if (!userId) {
      return res.apiError('User ID required', null, 400, 'VALIDATION_FAILED');
    }

    let profile = await AIProfile.findOne({ userId });

    // If no profile exists, create default
    if (!profile) {
      profile = new AIProfile({
        userId,
        averageSpeed: 50,
        averageAcceleration: 3.0,
        profileCompleteness: 0
      });
      await profile.save();
    }

    return res.apiSuccess(profile, 'Profile retrieved', 200);
  } catch (error) {
    logger.logError('Error getting AI profile', error);
    return res.apiError('Failed to retrieve profile', error, 500, 'PROFILE_GET_FAILED');
  }
};

/**
 * Save behavior history for learning
 */
exports.saveBehaviorHistory = async (req, res) => {
  try {
    const { userId, records } = req.body;

    if (!userId || !records || !Array.isArray(records)) {
      return res.apiError('User ID and records array required', null, 400, 'VALIDATION_FAILED');
    }

    // Calculate statistics
    const totalRecords = records.length;
    const averageDeviation = records.reduce((sum, r) => sum + (r.deviation || 0), 0) / totalRecords;
    const anomalyCount = records.filter(r => r.anomalous).length;

    const history = new BehaviorHistory({
      userId,
      records,
      totalRecords,
      averageDeviation,
      anomalyCount,
      timestamp: new Date()
    });

    await history.save();

    // Update profile completeness
    const profile = await AIProfile.findOne({ userId });
    if (profile) {
      profile.recordCount = (profile.recordCount || 0) + totalRecords;
      profile.profileCompleteness = Math.min(100, Math.floor((profile.recordCount / 500) * 100));
      await profile.save();
    }

    logger.logEvent('BEHAVIOR_HISTORY_SAVED', { userId, recordCount: totalRecords });

    return res.apiSuccess(
      { recordsStored: totalRecords, anomalyCount, averageDeviation: Math.round(averageDeviation * 100) / 100 },
      'Behavior history saved',
      201
    );
  } catch (error) {
    logger.logError('Error saving behavior history', error);
    return res.apiError('Failed to save behavior history', error, 500, 'HISTORY_SAVE_FAILED');
  }
};

/**
 * Save AI model state
 */
exports.saveModelState = async (req, res) => {
  try {
    const { modelName, state, parameters, accuracy } = req.body;

    if (!modelName || !state) {
      return res.apiError('Model name and state required', null, 400, 'VALIDATION_FAILED');
    }

    const modelState = await AIModelState.findOneAndUpdate(
      { modelName },
      {
        modelName,
        state,
        parameters: parameters || {},
        accuracy: accuracy || 0,
        lastTrained: new Date(),
        updatedAt: new Date()
      },
      { upsert: true, new: true }
    );

    logger.logEvent('AI_MODEL_STATE_SAVED', { modelName, accuracy });

    return res.apiSuccess(modelState, 'Model state saved', 201);
  } catch (error) {
    logger.logError('Error saving model state', error);
    return res.apiError('Failed to save model state', error, 500, 'MODEL_SAVE_FAILED');
  }
};

/**
 * Get AI model state
 */
exports.getModelState = async (req, res) => {
  try {
    const { modelName } = req.params;

    if (!modelName) {
      return res.apiError('Model name required', null, 400, 'VALIDATION_FAILED');
    }

    const modelState = await AIModelState.findOne({ modelName });

    if (!modelState) {
      return res.apiError('Model not found', null, 404, 'NOT_FOUND');
    }

    return res.apiSuccess(modelState, 'Model state retrieved', 200);
  } catch (error) {
    logger.logError('Error getting model state', error);
    return res.apiError('Failed to retrieve model state', error, 500, 'MODEL_GET_FAILED');
  }
};

/**
 * Save AI prediction (for analytics)
 */
exports.savePrediction = async (req, res) => {
  try {
    const { userId, emergencyId, predictionType, score, factors, confidence } = req.body;

    if (!userId || !predictionType || score === undefined) {
      return res.apiError('User ID, prediction type, and score required', null, 400, 'VALIDATION_FAILED');
    }

    if (score < 0 || score > 1) {
      return res.apiError('Score must be between 0 and 1', null, 400, 'VALIDATION_FAILED');
    }

    const prediction = new AIPrediction({
      userId,
      emergencyId,
      predictionType,
      score,
      factors: factors || {},
      confidence: confidence || 0,
      timestamp: new Date()
    });

    await prediction.save();

    logger.logEvent('AI_PREDICTION_SAVED', { userId, predictionType, score });

    return res.apiSuccess(prediction, 'Prediction saved', 201);
  } catch (error) {
    logger.logError('Error saving prediction', error);
    return res.apiError('Failed to save prediction', error, 500, 'PREDICTION_SAVE_FAILED');
  }
};

/**
 * Get prediction history for analytics
 */
exports.getPredictionHistory = async (req, res) => {
  try {
    const { userId } = req.params;
    const { limit = 100, skip = 0 } = req.query;

    if (!userId) {
      return res.apiError('User ID required', null, 400, 'VALIDATION_FAILED');
    }

    const predictions = await AIPrediction.find({ userId })
      .sort({ createdAt: -1 })
      .limit(parseInt(limit))
      .skip(parseInt(skip));

    const total = await AIPrediction.countDocuments({ userId });

    return res.apiPaginated(
      predictions,
      total,
      parseInt(limit),
      parseInt(skip),
      'Prediction history retrieved'
    );
  } catch (error) {
    logger.logError('Error getting prediction history', error);
    return res.apiError('Failed to retrieve prediction history', error, 500, 'HISTORY_GET_FAILED');
  }
};

/**
 * Get AI analytics dashboard (admin only)
 */
exports.getAnalytics = async (req, res) => {
  try {
    const totalProfiles = await AIProfile.countDocuments();
    const averageProfileCompleteness = await AIProfile.aggregate([
      { $group: { _id: null, avg: { $avg: '$profileCompleteness' } } }
    ]);
    
    const totalPredictions = await AIPrediction.countDocuments();
    const accuratePredictions = await AIPrediction.countDocuments({ accuracy: true });
    const predictionAccuracy = totalPredictions > 0 ? (accuratePredictions / totalPredictions * 100).toFixed(2) : 0;

    const modelStates = await AIModelState.find();

    return res.apiSuccess(
      {
        profiles: {
          total: totalProfiles,
          averageCompleteness: averageProfileCompleteness[0]?.avg || 0
        },
        predictions: {
          total: totalPredictions,
          accurate: accuratePredictions,
          accuracy: `${predictionAccuracy}%`
        },
        models: modelStates.map(m => ({
          name: m.modelName,
          accuracy: m.accuracy,
          lastTrained: m.lastTrained
        }))
      },
      'AI Analytics retrieved',
      200
    );
  } catch (error) {
    logger.logError('Error getting AI analytics', error);
    return res.apiError('Failed to retrieve analytics', error, 500, 'ANALYTICS_FAILED');
  }
};

module.exports = exports;
