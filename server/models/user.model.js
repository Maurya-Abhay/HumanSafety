const mongoose = require('mongoose');
const bcrypt = require('bcryptjs');

const userSchema = new mongoose.Schema(
  {
    phone: { 
      type: String, 
      required: true, 
      unique: true, 
      trim: true 
    },

    name: { type: String, default: '' },

    email: { 
      type: String, 
      trim: true,
      lowercase: true,
      default: '',
    },

    password: { 
      type: String,
      required: false,  // Optional for OTP-based login
      default: null,
      minlength: [8, 'Password must be at least 8 characters'],
      validate: {
        validator: function(v) {
          // If password exists, it should be at least 8 characters
          if (v && typeof v === 'string') {
            return v.length >= 8;
          }
          // If no password, it's OK (OTP users)
          return true;
        },
        message: 'Password must be at least 8 characters if provided'
      }
    },

    bloodType: { type: String, default: '' },
    allergies: { type: String, default: '' },

    emergencyContacts: [
      { type: mongoose.Schema.Types.ObjectId, ref: 'Contact' }
    ],

    currentLocation: {
      latitude: { type: Number, default: 0 },
      longitude: { type: Number, default: 0 },
      updatedAt: { type: Date, default: Date.now },
    },

    // ROLE
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

    policeDetails: {
      idProof: { type: String, default: null },
      stationName: { type: String, default: null },
      badgeNumber: { type: String, default: null },
      badgeProof: { type: String, default: null },
    },

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


// 🔐 HASH PASSWORD
userSchema.pre('save', async function (next) {
  if (!this.isModified('password')) return next();

  this.password = await bcrypt.hash(this.password, 10);
  next();
});


// 🔑 COMPARE PASSWORD
userSchema.methods.comparePassword = async function (password) {
  return bcrypt.compare(password, this.password);
};


module.exports = mongoose.model('User', userSchema);