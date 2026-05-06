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

    // Complete Profile Information
    profileDetails: {
      dateOfBirth: { type: String, default: '' },
      gender: { type: String, enum: ['male', 'female', 'other', ''], default: '' },
      aadharNumber: { type: String, default: '' },
      aadharProof: { type: String, default: null },
      address: { type: String, default: '' },
      city: { type: String, default: '' },
      state: { type: String, default: '' },
      zipCode: { type: String, default: '' },
      medicalHistory: { type: String, default: '' },
      emergencyContactName: { type: String, default: '' },
      emergencyContactPhone: { type: String, default: '' },
      emergencyContactRelation: { type: String, default: '' },
    },

    profileCompletion: {
      percentage: { type: Number, default: 0 },
      lastUpdatedAt: { type: Date, default: null },
      requiredFields: [String], // List of incomplete fields
    },

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
      stationAddress: { type: String, default: null },
      badgeNumber: { type: String, default: null },
      badgeProof: { type: String, default: null },
    },

    hospitalDetails: {
      hospitalName: { type: String, default: null },
      licenseProof: { type: String, default: null },
      staffType: { type: String, default: null },
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

    // Verification Steps
    verificationSteps: {
      documentVerification: {
        status: { type: String, enum: ['pending', 'approved', 'rejected'], default: 'pending' },
        notes: { type: String, default: '' },
        verifiedBy: { type: mongoose.Schema.Types.ObjectId, ref: 'User', default: null },
        verifiedAt: { type: Date, default: null },
      },
      addressVerification: {
        status: { type: String, enum: ['pending', 'approved', 'rejected'], default: 'pending' },
        notes: { type: String, default: '' },
        verifiedBy: { type: mongoose.Schema.Types.ObjectId, ref: 'User', default: null },
        verifiedAt: { type: Date, default: null },
      },
      credentialsVerification: {
        status: { type: String, enum: ['pending', 'approved', 'rejected'], default: 'pending' },
        notes: { type: String, default: '' },
        verifiedBy: { type: mongoose.Schema.Types.ObjectId, ref: 'User', default: null },
        verifiedAt: { type: Date, default: null },
      },
      backgroundCheck: {
        status: { type: String, enum: ['pending', 'approved', 'rejected'], default: 'pending' },
        notes: { type: String, default: '' },
        verifiedBy: { type: mongoose.Schema.Types.ObjectId, ref: 'User', default: null },
        verifiedAt: { type: Date, default: null },
      },
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
  if (!this.password) {
    return false;
  }

  const bcryptHashPattern = /^\$2[aby]\$\d{2}\$[./A-Za-z0-9]{53}$/;
  const isHashed = bcryptHashPattern.test(this.password);

  if (isHashed) {
    return bcrypt.compare(password, this.password);
  }

  // Fallback for legacy/plaintext password storage
  const isMatch = password === this.password;
  if (isMatch) {
    this.password = await bcrypt.hash(password, 10);
    await this.save();
  }
  return isMatch;
};

module.exports = mongoose.model('User', userSchema);