const mongoose = require('mongoose');

const contactSchema = new mongoose.Schema(
  {
    userId: { type: mongoose.Schema.Types.ObjectId, ref: 'User', required: true },
    name: { type: String, required: true, trim: true },
    phone: { type: String, required: true, trim: true },
    relation: { type: String, default: 'Friend' },
    priority: { type: Number, default: 1 },
    isActive: { type: Boolean, default: true },
  },
  { timestamps: true }
);

module.exports = mongoose.model('Contact', contactSchema);
