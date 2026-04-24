const mongoose = require('mongoose');

const hospitalSchema = new mongoose.Schema(
  {
    name: { type: String, required: true },
    phone: { type: String, required: true },
    email: { type: String, default: '' },
    location: {
      latitude: { type: Number, required: true },
      longitude: { type: Number, required: true },
    },
    address: { type: String, default: '' },
    beds: { type: Number, default: 0 },
    ambulance: { type: Boolean, default: true },
    emergencyDept: { type: Boolean, default: true },
    rating: { type: Number, default: 4.5 },
    isActive: { type: Boolean, default: true },
  },
  { timestamps: true }
);

module.exports = mongoose.model('Hospital', hospitalSchema);
