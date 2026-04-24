const mongoose = require('mongoose');

const alertSchema = new mongoose.Schema(
  {
    userId: { type: mongoose.Schema.Types.ObjectId, ref: 'User', required: true },
    type: { type: String, enum: ['panic', 'accident', 'help'], required: true },
    location: {
      latitude: { type: Number, required: true },
      longitude: { type: Number, required: true },
    },
    description: { type: String, default: '' },
    contactsNotified: { type: Number, default: 0 },
    status: { type: String, enum: ['pending', 'assigned', 'in-progress', 'at-location', 'providing-help', 'resolved', 'dismissed'], default: 'pending' },
    metadata: mongoose.Schema.Types.Mixed,
    
    // Case assignment fields
    assignedPolice: { type: mongoose.Schema.Types.ObjectId, ref: 'User', default: null },
    assignedHospital: { type: mongoose.Schema.Types.ObjectId, ref: 'User', default: null },
    acceptedAt: { type: Date, default: null },
    eta: { type: Number, default: null }, // ETA in minutes
    policeLocation: {
      latitude: { type: Number, default: null },
      longitude: { type: Number, default: null },
    },
    rejectionReason: { type: String, default: '' },
    lastStatusUpdate: { type: Date, default: null },
    resolutionDetails: { type: String, default: '' },
    resolvedAt: { type: Date, default: null },
  },
  { timestamps: true }
);

module.exports = mongoose.model('Alert', alertSchema);
