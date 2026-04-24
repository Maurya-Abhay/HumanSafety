const mongoose = require('mongoose');

const emergencySchema = new mongoose.Schema(
  {
    // Primary Information
    userId: { type: mongoose.Schema.Types.ObjectId, ref: 'User', required: true },
    type: { 
      type: String, 
      enum: ['panic', 'accident', 'medical', 'fire', 'other'], 
      required: true 
    },
    location: {
      latitude: { type: Number, required: true },
      longitude: { type: Number, required: true },
      address: { type: String, default: '' },
      googlePlaceId: { type: String, default: '' },
    },

    // STATE MACHINE (CORE)
    state: {
      type: String,
      enum: [
        'CREATED',           // Just triggered
        'BROADCASTED',       // Sent to nearby units
        'ACCEPTED',          // Police/Hospital accepted
        'IN_PROGRESS',       // Handler en-route or on-scene
        'RESOLVED',          // Issue resolved
        'CLOSED',            // Archived

        // Failure states
        'NO_RESPONSE',       // No response from units
        'ESCALATED',         // Escalated to higher authority
        'REJECTED',          // Initial handler rejected
        'AUTO_ESCALATE',     // Auto-escalated due to timeout
      ],
      default: 'CREATED',
    },

    // Handler Information
    assignedPolice: { 
      type: mongoose.Schema.Types.ObjectId, 
      ref: 'User',
      default: null 
    },
    assignedHospital: { 
      type: mongoose.Schema.Types.ObjectId, 
      ref: 'User',
      default: null 
    },
    
    // Police Case Fields
    policeAcceptedAt: { type: Date, default: null },
    policeETA: { type: Number, default: null }, // minutes
    policeCurrentLocation: {
      latitude: { type: Number, default: null },
      longitude: { type: Number, default: null },
      timestamp: { type: Date, default: null },
    },
    policeStatus: {
      type: String,
      enum: ['ACCEPTED', 'ON_THE_WAY', 'ARRIVED', 'PROVIDING_HELP', 'RESOLVED'],
      default: null,
    },

    // Hospital Case Fields
    hospitalAcceptedAt: { type: Date, default: null },
    hospitalResponseTime: { type: Number, default: null }, // seconds
    patientIntakeStarted: { type: Boolean, default: false },
    patientAdmitted: { type: Boolean, default: false },
    hospitalStatus: {
      type: String,
      enum: ['ACCEPTED', 'PREPARING', 'READY', 'PATIENT_ARRIVED', 'ADMITTED', 'RESOLVED'],
      default: null,
    },

    // Escalation & Routing
    escalationCount: { type: Number, default: 0 },
    escalationReason: { type: String, default: '' },
    hospitalRoutingLog: [
      {
        hospitalId: mongoose.Schema.Types.ObjectId,
        sentAt: Date,
        respondedAt: { type: Date, default: null },
        status: { type: String, enum: ['SENT', 'ACCEPTED', 'REJECTED', 'TIMEOUT'] },
        responseTime: { type: Number, default: null }, // seconds
      },
    ],
    policeRoutingLog: [
      {
        policeId: mongoose.Schema.Types.ObjectId,
        sentAt: Date,
        respondedAt: { type: Date, default: null },
        status: { type: String, enum: ['SENT', 'ACCEPTED', 'REJECTED', 'TIMEOUT'] },
      },
    ],

    // Description & Details
    description: { type: String, default: '' },
    isAccident: { type: Boolean, default: false },
    accidentData: {
      accelerationMagnitude: { type: Number, default: null },
      confidenceScore: { type: Number, default: null }, // 0-100
      aiDecision: { type: String, enum: ['AUTO_ALERT', 'ASK_CONFIRMATION', 'IGNORE'] },
    },

    // Contacts & Communication
    emergencyContactNotified: { type: Boolean, default: false },
    contactsNotified: [String], // Phone numbers
    smsSent: { type: Boolean, default: false },
    smsTo: [String],

    // Timeline Tracking
    createdAt: { type: Date, default: Date.now, index: true },
    broadcastedAt: { type: Date, default: null },
    firstResponseAt: { type: Date, default: null },
    acceptedAt: { type: Date, default: null },
    resolvedAt: { type: Date, default: null },
    closedAt: { type: Date, default: null },

    // Timing Metrics
    timeToFirstResponse: { type: Number, default: null }, // milliseconds
    timeToAcceptance: { type: Number, default: null },
    totalResolutionTime: { type: Number, default: null },

    // Failure & Retry
    failureReason: { type: String, default: '' },
    retryCount: { type: Number, default: 0 },
    lastRetryAt: { type: Date, default: null },
    isInDeadLetterQueue: { type: Boolean, default: false },
    deadLetterReason: { type: String, default: '' },

    // Audit & Tracking
    resolution: { type: String, default: '' },
    notes: [
      {
        timestamp: { type: Date, default: Date.now },
        author: String,
        content: String,
      },
    ],
    isOfflineQueued: { type: Boolean, default: false },
    offlineQueueSync: { type: Boolean, default: false },

    // Risk & Analytics
    riskScore: { type: Number, default: 0 }, // 0-100
    priority: {
      type: String,
      enum: ['LOW', 'MEDIUM', 'HIGH', 'CRITICAL'],
      default: 'MEDIUM',
    },
    isSystemOverride: { type: Boolean, default: false },
    overriddenBy: { type: mongoose.Schema.Types.ObjectId, ref: 'User', default: null },

    // Location History (for tracking)
    locationHistory: [
      {
        latitude: Number,
        longitude: Number,
        timestamp: { type: Date, default: Date.now },
        source: { type: String, enum: ['USER', 'POLICE', 'AI'] }, // who provided location
      },
    ],
  },
  { timestamps: true }
);

// Indexes for performance
emergencySchema.index({ userId: 1, createdAt: -1 });
emergencySchema.index({ state: 1, createdAt: -1 });
emergencySchema.index({ assignedPolice: 1, state: 1 });
emergencySchema.index({ assignedHospital: 1, state: 1 });
emergencySchema.index({ 'location.latitude': 1, 'location.longitude': 1 });
emergencySchema.index({ isInDeadLetterQueue: 1 });
emergencySchema.index({ priority: 1, state: 1 });

module.exports = mongoose.model('Emergency', emergencySchema);
