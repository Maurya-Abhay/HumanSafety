const mongoose = require('mongoose');

const helpRequestSchema = new mongoose.Schema(
  {
    requesterId: { type: mongoose.Schema.Types.ObjectId, ref: 'User', required: true },
    helperId: { type: mongoose.Schema.Types.ObjectId, ref: 'User', default: null },
    location: {
      latitude: { type: Number, required: true },
      longitude: { type: Number, required: true },
    },
    radius: { type: Number, default: 5 },
    status: { type: String, enum: ['pending', 'accepted', 'rejected', 'completed'], default: 'pending' },
    description: { type: String, default: 'User needs help' },
    nearbyUsers: [{ userId: mongoose.Schema.Types.ObjectId, distance: Number }],
    expiresAt: { type: Date, required: true },
  },
  { timestamps: true }
);

module.exports = mongoose.model('HelpRequest', helpRequestSchema);
