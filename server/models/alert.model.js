const mongoose = require('mongoose');

const alertSchema = new mongoose.Schema(
  {
    userId: { type: mongoose.Schema.Types.ObjectId, ref: 'User', required: true },
    type: { type: String, enum: ['panic', 'accident', 'help'], required: true },
    location: {
      latitude: { type: Number, required: true },
      longitude: { type: Number, required: true },
    },
    title: { type: String, default: '' },
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
    
      // Attachments & Evidence
      attachments: [
        {
          url: { type: String },
          filename: { type: String },
          mimeType: { type: String },
          uploadedBy: { type: mongoose.Schema.Types.ObjectId, ref: 'User' },
          uploadedAt: { type: Date, default: Date.now },
          size: { type: Number, default: 0 },
        },
      ],
    
      evidence: [
        {
          type: { type: String, default: 'photo' },
          description: { type: String, default: '' },
          referenceId: { type: String, default: '' },
          chainOfCustody: [
            {
              actor: { type: mongoose.Schema.Types.ObjectId, ref: 'User' },
              action: String,
              timestamp: { type: Date, default: Date.now },
              notes: String,
            },
          ],
        },
      ],
    
      // Assignment & audit
      assignedAt: { type: Date, default: null },
      respondedAt: { type: Date, default: null },
      auditTrail: [
        {
          action: { type: String },
          actor: { type: mongoose.Schema.Types.ObjectId, ref: 'User' },
          timestamp: { type: Date, default: Date.now },
          details: { type: String, default: '' },
        },
      ],
      tags: [{ type: String }],
      severityScore: { type: Number, default: 0 },
  },
  { timestamps: true }
);

module.exports = mongoose.model('Alert', alertSchema);
