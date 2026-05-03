const mongoose = require('mongoose');

const ambulanceSchema = new mongoose.Schema(
  {
    // Ambulance Identification
    hospitalId: {
      type: mongoose.Schema.Types.ObjectId,
      ref: 'User',
      required: true,
    },
    licenseNumber: {
      type: String,
      required: true,
      unique: true,
    },
    driverName: {
      type: String,
      required: true,
    },
    driverPhone: {
      type: String,
      required: true,
    },

    // Status
    status: {
      type: String,
      enum: ['available', 'on-duty', 'in-transit', 'at-location', 'unavailable'],
      default: 'available',
    },

    // Current Assignment
    assignedCaseId: {
      type: mongoose.Schema.Types.ObjectId,
      ref: 'Emergency',
      default: null,
    },
    assignedPatientName: {
      type: String,
      default: '',
    },

    // Current Location (Real-time)
    currentLocation: {
      latitude: { type: Number, default: null },
      longitude: { type: Number, default: null },
      address: { type: String, default: '' },
      updatedAt: { type: Date, default: null },
    },

    // Destination
    destination: {
      latitude: { type: Number, default: null },
      longitude: { type: Number, default: null },
      address: { type: String, default: '' },
    },

    // ETA Calculation
    eta: {
      estimatedMinutes: { type: Number, default: 0 },
      calculatedAt: { type: Date, default: null },
    },

    // Location History (last 50 points)
    locationHistory: [
      {
        latitude: { type: Number },
        longitude: { type: Number },
        timestamp: { type: Date, default: Date.now },
      },
    ],

    // Speed & Distance
    averageSpeed: { type: Number, default: 0 }, // km/h
    totalDistance: { type: Number, default: 0 }, // km
    estimatedDistance: { type: Number, default: 0 }, // km to destination

    // WebSocket Connection
    lastHeartbeat: { type: Date, default: null },
    isOnline: { type: Boolean, default: false },

    // Activity Log
    activityLog: [
      {
        action: String, // 'assigned', 'departed', 'arrived', 'completed'
        caseId: mongoose.Schema.Types.ObjectId,
        timestamp: { type: Date, default: Date.now },
        details: String,
      },
    ],
  },
  { timestamps: true }
);

// Index for faster queries
ambulanceSchema.index({ hospitalId: 1, status: 1 });
ambulanceSchema.index({ assignedCaseId: 1 });
ambulanceSchema.index({ lastHeartbeat: 1 });

// Auto-remove old location history entries (keep only last 50)
ambulanceSchema.pre('save', function (next) {
  if (this.locationHistory.length > 50) {
    this.locationHistory = this.locationHistory.slice(-50);
  }
  next();
});

// Mark as offline if no heartbeat in 5 minutes
ambulanceSchema.pre('save', function (next) {
  if (this.lastHeartbeat) {
    const fiveMinutesAgo = new Date(Date.now() - 5 * 60 * 1000);
    if (this.lastHeartbeat < fiveMinutesAgo) {
      this.isOnline = false;
    }
  }
  next();
});

module.exports = mongoose.model('Ambulance', ambulanceSchema);
