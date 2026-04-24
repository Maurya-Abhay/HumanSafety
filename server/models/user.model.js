const mongoose = require('mongoose');
const bcrypt = require('bcryptjs');

const userSchema = new mongoose.Schema(
  {
    phone: { type: String, required: true, unique: true, trim: true },
    name: { type: String, default: '' },
    email: { type: String, default: '' },
    password: { type: String, default: '' },
    bloodType: { type: String, default: '' },
    allergies: { type: String, default: '' },
    emergencyContacts: [{ type: mongoose.Schema.Types.ObjectId, ref: 'Contact' }],
    currentLocation: {
      latitude: { type: Number, default: 0 },
      longitude: { type: Number, default: 0 },
      updatedAt: { type: Date, default: Date.now },
    },
    // ============== ROLE-BASED FIELDS ==============
    role: { 
      type: String, 
      enum: ['user', 'police', 'hospital', 'admin'], 
      default: 'user' 
    },
    status: {
      type: String,
      enum: ['active', 'pending', 'rejected', 'blocked'],
      default: 'active'
    },
    // Police-specific fields
    policeDetails: {
      idProof: { type: String, default: null },
      stationName: { type: String, default: null },
      badgeNumber: { type: String, default: null },
      badgeProof: { type: String, default: null },
    },
    // Hospital-specific fields
    hospitalDetails: {
      hospitalName: { type: String, default: null },
      licenseProof: { type: String, default: null },
      location: {
        latitude: { type: Number, default: 0 },
        longitude: { type: Number, default: 0 },
        address: { type: String, default: null },
      },
      totalBeds: { type: Number, default: 0 },
      availableBeds: { type: Number, default: 0 },
      specializations: [{ type: String }],
      contactPerson: { type: String, default: null },
    },
    // Admin override field
    adminNotes: { type: String, default: '' },
    approvedBy: { type: mongoose.Schema.Types.ObjectId, ref: 'User', default: null },
    approvedAt: { type: Date, default: null },
    rejectionReason: { type: String, default: null },
    
    isActive: { type: Boolean, default: true },
    lastLogin: { type: Date, default: null },
    isBlocked: { type: Boolean, default: false },
    blockReason: { type: String, default: null },
  },
  { timestamps: true }
);

userSchema.pre('save', async function (next) {
  if (!this.isModified('password') || !this.password) return next();
  this.password = await bcrypt.hash(this.password, 10);
  next();
});

userSchema.methods.comparePassword = async function (password) {
  if (!this.password) return false;
  return await bcrypt.compare(password, this.password);
};

module.exports = mongoose.model('User', userSchema);
