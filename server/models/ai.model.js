const mongoose = require('mongoose');

/**
 * AI User Profile - Stores learned behavior patterns and preferences
 */
const aiProfileSchema = new mongoose.Schema({
  userId: {
    type: mongoose.Schema.Types.ObjectId,
    ref: 'User',
    required: true,
    unique: true,
    index: true
  },
  averageSpeed: {
    type: Number,
    default: 50,
    description: 'Average driving speed in km/h'
  },
  averageAcceleration: {
    type: Number,
    default: 3.0,
    description: 'Average acceleration magnitude'
  },
  commonLocations: [{
    latitude: Number,
    longitude: Number,
    name: String,
    visitCount: { type: Number, default: 1 },
    lastVisit: Date
  }],
  drivingPatterns: {
    nightDriving: { type: Boolean, default: false },
    aggressiveDriving: { type: Boolean, default: false },
    defensiveDriving: { type: Boolean, default: false },
    frequentRoutes: [String]
  },
  riskProfile: {
    baselineRisk: { type: Number, default: 0.3, min: 0, max: 1 },
    speedSensitivity: { type: Number, default: 0.5 },
    locationSensitivity: { type: Number, default: 0.5 },
    timeSensitivity: { type: Number, default: 0.5 }
  },
  anomalyThresholds: {
    speedDeviation: { type: Number, default: 1.5 },
    accelerationDeviation: { type: Number, default: 1.5 },
    behaviorDeviation: { type: Number, default: 1.5 }
  },
  profileCompleteness: {
    type: Number,
    default: 0,
    min: 0,
    max: 100,
    description: 'Percentage of profile that is learned vs default'
  },
  recordCount: {
    type: Number,
    default: 0,
    description: 'Number of behavior records used for learning'
  },
  updatedAt: Date,
  createdAt: { type: Date, default: Date.now }
});

/**
 * Behavior History - Individual behavior records for learning
 */
const behaviorHistorySchema = new mongoose.Schema({
  userId: {
    type: mongoose.Schema.Types.ObjectId,
    ref: 'User',
    required: true,
    index: true
  },
  records: [{
    speed: Number,
    acceleration: Number,
    location: String,
    hour: Number,
    deviation: Number,
    status: String,
    anomalous: Boolean,
    timestamp: Date
  }],
  totalRecords: Number,
  averageDeviation: Number,
  anomalyCount: Number,
  timestamp: Date,
  createdAt: { type: Date, default: Date.now, expires: 2592000 } // TTL: 30 days
});

/**
 * AI Model State - Stores model parameters and state
 */
const aiModelStateSchema = new mongoose.Schema({
  modelName: {
    type: String,
    required: true,
    index: true,
    enum: ['fusion_engine', 'behavior_engine', 'risk_engine', 'accident_engine']
  },
  version: {
    type: String,
    default: '1.0.0'
  },
  state: mongoose.Schema.Types.Mixed,
  parameters: mongoose.Schema.Types.Mixed,
  accuracy: {
    type: Number,
    default: 0,
    min: 0,
    max: 1
  },
  lastTrained: Date,
  trainingRecords: Number,
  updatedAt: Date,
  createdAt: { type: Date, default: Date.now }
});

/**
 * AI Predictions - Store predictions for analytics
 */
const aiPredictionSchema = new mongoose.Schema({
  userId: {
    type: mongoose.Schema.Types.ObjectId,
    ref: 'User',
    required: true,
    index: true
  },
  emergencyId: {
    type: mongoose.Schema.Types.ObjectId,
    ref: 'Emergency'
  },
  predictionType: {
    type: String,
    enum: ['accident_probability', 'risk_score', 'behavior_anomaly'],
    required: true
  },
  score: {
    type: Number,
    min: 0,
    max: 1,
    required: true
  },
  factors: mongoose.Schema.Types.Mixed,
  confidence: {
    type: Number,
    min: 0,
    max: 1
  },
  actualOutcome: String,
  accuracy: Boolean,
  timestamp: Date,
  createdAt: { type: Date, default: Date.now, expires: 5184000 } // TTL: 60 days
});

module.exports = {
  AIProfile: mongoose.model('AIProfile', aiProfileSchema),
  BehaviorHistory: mongoose.model('BehaviorHistory', behaviorHistorySchema),
  AIModelState: mongoose.model('AIModelState', aiModelStateSchema),
  AIPrediction: mongoose.model('AIPrediction', aiPredictionSchema)
};
