// Backend API - Complete Multi-Role System Implementation

const express = require('express');
const mongoose = require('mongoose');
const jwt = require('jsonwebtoken');
const cors = require('cors');
require('dotenv').config();

const app = express();

// Middleware
app.use(express.json());
app.use(cors());

// ============= DATABASE SCHEMAS =============

const userSchema = new mongoose.Schema({
  phone: { type: String, unique: true, required: true },
  email: { type: String, unique: true, required: true },
  name: String,
  role: { type: String, enum: ['user', 'police', 'hospital', 'admin'], required: true },
  
  // Police-specific
  badgeNumber: String,
  stationId: String,
  assignedZone: String,
  
  // Hospital-specific
  hospitalId: String,
  staffType: String,
  ambulanceId: String,
  
  // Admin
  permissions: [String],
  
  // Location
  location: {
    latitude: Number,
    longitude: Number,
    lastUpdated: Date,
    accuracy: Number
  },
  
  isActive: { type: Boolean, default: true },
  isBlocked: { type: Boolean, default: false },
  createdAt: { type: Date, default: Date.now },
  updatedAt: { type: Date, default: Date.now },
  lastLogin: Date
});

const caseSchema = new mongoose.Schema({
  caseId: { type: String, unique: true },
  userId: mongoose.Schema.Types.ObjectId,
  
  status: {
    type: String,
    enum: ['created', 'assigned', 'accepted', 'in-progress', 'resolved', 'closed', 'cancelled'],
    default: 'created'
  },
  type: { type: String, enum: ['panic', 'accident', 'custom'] },
  
  location: {
    latitude: Number,
    longitude: Number,
    address: String,
    zone: String
  },
  
  riskLevel: { type: String, enum: ['low', 'medium', 'high', 'critical'], default: 'medium' },
  riskScore: { type: Number, min: 0, max: 100, default: 50 },
  
  assignedPolice: mongoose.Schema.Types.ObjectId,
  assignedHospital: mongoose.Schema.Types.ObjectId,
  assignedAmbulance: mongoose.Schema.Types.ObjectId,
  
  description: String,
  attachments: [String],
  
  sensorData: {
    acceleration: Number,
    speed: Number,
    gyroscope: Number
  },
  
  timeline: [{
    action: String,
    actor: mongoose.Schema.Types.ObjectId,
    timestamp: Date,
    details: mongoose.Schema.Types.Mixed
  }],
  
  createdAt: { type: Date, default: Date.now },
  updatedAt: { type: Date, default: Date.now },
  resolvedAt: Date
});

const auditLogSchema = new mongoose.Schema({
  actor: mongoose.Schema.Types.ObjectId,
  action: String,
  resource: String,
  resourceId: mongoose.Schema.Types.ObjectId,
  
  changes: {
    before: mongoose.Schema.Types.Mixed,
    after: mongoose.Schema.Types.Mixed
  },
  
  ipAddress: String,
  deviceInfo: String,
  
  timestamp: { type: Date, default: Date.now }
});

// Role Application Schema
const roleApplicationSchema = new mongoose.Schema({
  userId: {
    type: mongoose.Schema.Types.ObjectId,
    ref: 'User',
    required: true
  },
  applicantName: String,
  applicantPhone: String,
  applicantEmail: String,
  
  requestedRole: {
    type: String,
    enum: ['police', 'hospital'],
    required: true
  },
  
  // For police
  badgeNumber: String,
  stationName: String,
  stationAddress: String,
  
  // For hospital
  hospitalName: String,
  hospitalAddress: String,
  staffType: { type: String, enum: ['doctor', 'nurse', 'paramedic', 'admin', 'other'] },
  
  // Documents
  documents: [{
    type: String, // file path/URL
    label: String // "ID Proof", "Badge", "Hospital Certificate", etc
  }],
  
  status: {
    type: String,
    enum: ['pending', 'approved', 'rejected'],
    default: 'pending'
  },
  
  adminNotes: String,
  verifiedBy: mongoose.Schema.Types.ObjectId,
  verificationDate: Date,
  
  createdAt: { type: Date, default: Date.now },
  updatedAt: { type: Date, default: Date.now }
});

// Models
const User = mongoose.model('User', userSchema);
const Case = mongoose.model('Case', caseSchema);
const AuditLog = mongoose.model('AuditLog', auditLogSchema);
const RoleApplication = mongoose.model('RoleApplication', roleApplicationSchema);

// ============= MIDDLEWARE =============

// JWT Auth Middleware
const verifyToken = (req, res, next) => {
  const token = req.headers.authorization?.split(' ')[1];
  
  if (!token) {
    return res.status(401).json({ message: 'No token provided' });
  }
  
  try {
    const decoded = jwt.verify(token, process.env.JWT_SECRET);
    req.userId = decoded.userId;
    req.userRole = decoded.role;
    next();
  } catch (error) {
    res.status(401).json({ message: 'Invalid token' });
  }
};

// Role-based Access Control
const requireRole = (...allowedRoles) => {
  return (req, res, next) => {
    if (!allowedRoles.includes(req.userRole)) {
      return res.status(403).json({ message: 'Access denied' });
    }
    next();
  };
};

// Audit Middleware
const auditLog = (action, resource) => {
  return async (req, res, next) => {
    const originalSend = res.send;
    
    res.send = function(data) {
      if (res.statusCode >= 200 && res.statusCode < 300) {
        AuditLog.create({
          actor: req.userId,
          action,
          resource,
          resourceId: req.params.id || req.body._id,
          ipAddress: req.ip,
          deviceInfo: req.headers['user-agent'],
          timestamp: new Date()
        }).catch(err => console.error('Audit log failed:', err));
      }
      
      originalSend.call(this, data);
    };
    
    next();
  };
};

// ============= AUTH ENDPOINTS =============

app.post('/api/v1/auth/send-otp', async (req, res) => {
  try {
    const { phone } = req.body;
    
    // Generate OTP (for demo: always 123456)
    const otp = '123456';
    
    // TODO: Send SMS via Twilio
    console.log(`OTP for ${phone}: ${otp}`);
    
    res.json({ message: 'OTP sent', success: true });
  } catch (error) {
    res.status(500).json({ message: error.message });
  }
});

app.post('/api/v1/auth/verify-otp', async (req, res) => {
  try {
    const { phone, otp } = req.body;
    
    // Verify OTP (for demo: accept 123456)
    if (otp !== '123456') {
      return res.status(400).json({ message: 'Invalid OTP' });
    }
    
    // Find or create user
    let user = await User.findOne({ phone });
    
    if (!user) {
      user = await User.create({
        phone,
        email: `${phone}@example.com`,
        name: `User ${phone}`,
        role: 'user'
      });
    }
    
    // Generate JWT with role
    const token = jwt.sign(
      { userId: user._id, role: user.role, phone: user.phone },
      process.env.JWT_SECRET,
      { expiresIn: '7d' }
    );
    
    res.json({
      message: 'Login successful',
      token,
      user: {
        id: user._id,
        phone: user.phone,
        name: user.name,
        email: user.email,
        role: user.role,
        isBlocked: user.isBlocked
      }
    });
  } catch (error) {
    res.status(500).json({ message: error.message });
  }
});

app.post('/api/v1/auth/logout', verifyToken, async (req, res) => {
  res.json({ message: 'Logged out successfully' });
});

// ============= USER ENDPOINTS =============

app.get('/api/v1/user/profile', verifyToken, async (req, res) => {
  try {
    const user = await User.findById(req.userId);
    res.json(user);
  } catch (error) {
    res.status(500).json({ message: error.message });
  }
});

app.put('/api/v1/user/profile', verifyToken, auditLog('UPDATE', 'user_profile'), async (req, res) => {
  try {
    const user = await User.findByIdAndUpdate(req.userId, req.body, { new: true });
    res.json(user);
  } catch (error) {
    res.status(500).json({ message: error.message });
  }
});

app.post('/api/v1/user/location', verifyToken, auditLog('UPDATE', 'location'), async (req, res) => {
  try {
    const { latitude, longitude, accuracy } = req.body;
    
    await User.findByIdAndUpdate(req.userId, {
      location: {
        latitude,
        longitude,
        accuracy,
        lastUpdated: new Date()
      }
    });
    
    res.json({ message: 'Location updated' });
  } catch (error) {
    res.status(500).json({ message: error.message });
  }
});

// ============= ROLE APPLICATION ENDPOINTS =============

// Submit role application
app.post('/api/v1/user/role-application', verifyToken, auditLog('CREATE', 'role_application'), async (req, res) => {
  try {
    const user = await User.findById(req.userId);
    if (!user) {
      return res.status(404).json({ message: 'User not found' });
    }
    
    // Check if user already has a pending application
    const existingApp = await RoleApplication.findOne({
      userId: req.userId,
      status: 'pending'
    });
    
    if (existingApp) {
      return res.status(400).json({ message: 'You already have a pending application' });
    }
    
    const {
      requestedRole,
      badgeNumber,
      stationName,
      stationAddress,
      hospitalName,
      hospitalAddress,
      staffType,
      documents
    } = req.body;
    
    const application = await RoleApplication.create({
      userId: req.userId,
      applicantName: user.name,
      applicantPhone: user.phone,
      applicantEmail: user.email,
      requestedRole,
      badgeNumber,
      stationName,
      stationAddress,
      hospitalName,
      hospitalAddress,
      staffType,
      documents: documents || [],
      status: 'pending'
    });
    
    res.json({
      message: 'Application submitted successfully',
      applicationId: application._id,
      status: 'pending'
    });
  } catch (error) {
    res.status(500).json({ message: error.message });
  }
});

// Get user's role application status
app.get('/api/v1/user/role-application', verifyToken, async (req, res) => {
  try {
    const application = await RoleApplication.findOne({ userId: req.userId });
    
    res.json({
      hasApplication: !!application,
      application: application || null
    });
  } catch (error) {
    res.status(500).json({ message: error.message });
  }
});

// ============= ADMIN ROLE APPLICATION ENDPOINTS =============

// Get all pending role applications
app.get('/api/v1/admin/role-applications', verifyToken, requireRole('admin'), async (req, res) => {
  try {
    const status = req.query.status || 'pending'; // 'pending', 'approved', 'rejected', 'all'
    const query = status === 'all' ? {} : { status };
    
    const applications = await RoleApplication.find(query)
      .populate('userId', 'name phone email')
      .sort({ createdAt: -1 });
    
    res.json(applications);
  } catch (error) {
    res.status(500).json({ message: error.message });
  }
});

// Get single application
app.get('/api/v1/admin/role-applications/:id', verifyToken, requireRole('admin'), async (req, res) => {
  try {
    const application = await RoleApplication.findById(req.params.id)
      .populate('userId', 'name phone email');
    
    if (!application) {
      return res.status(404).json({ message: 'Application not found' });
    }
    
    res.json(application);
  } catch (error) {
    res.status(500).json({ message: error.message });
  }
});

// Approve role application
app.put('/api/v1/admin/role-applications/:id/approve', verifyToken, requireRole('admin'), auditLog('APPROVE', 'role_application'), async (req, res) => {
  try {
    const application = await RoleApplication.findById(req.params.id);
    
    if (!application) {
      return res.status(404).json({ message: 'Application not found' });
    }
    
    // Update user role
    const user = await User.findByIdAndUpdate(
      application.userId,
      { role: application.requestedRole },
      { new: true }
    );
    
    // Update application
    application.status = 'approved';
    application.verifiedBy = req.userId;
    application.verificationDate = new Date();
    application.adminNotes = req.body.adminNotes || '';
    await application.save();
    
    res.json({
      message: 'Application approved and role updated',
      user: {
        id: user._id,
        name: user.name,
        role: user.role
      },
      application
    });
  } catch (error) {
    res.status(500).json({ message: error.message });
  }
});

// Reject role application
app.put('/api/v1/admin/role-applications/:id/reject', verifyToken, requireRole('admin'), auditLog('REJECT', 'role_application'), async (req, res) => {
  try {
    const application = await RoleApplication.findById(req.params.id);
    
    if (!application) {
      return res.status(404).json({ message: 'Application not found' });
    }
    
    application.status = 'rejected';
    application.verifiedBy = req.userId;
    application.verificationDate = new Date();
    application.adminNotes = req.body.adminNotes || '';
    await application.save();
    
    res.json({
      message: 'Application rejected',
      application
    });
  } catch (error) {
    res.status(500).json({ message: error.message });
  }
});

// ============= EMERGENCY/CASE ENDPOINTS =============

app.post('/api/v1/emergency/panic', verifyToken, auditLog('CREATE', 'emergency_panic'), async (req, res) => {
  try {
    const { latitude, longitude, description } = req.body;
    const user = await User.findById(req.userId);
    
    // Call AI Engine for risk assessment
    const aiResponse = await fetch(`${process.env.AI_ENGINE_URL}/analyze-accident`, {
      method: 'POST',
      headers: { 'Content-Type': 'application/json' },
      body: JSON.stringify({
        latitude,
        longitude,
        sensorData: req.body.sensorData,
        userId: req.userId
      })
    }).then(r => r.json());
    
    // Create case
    const caseId = `CASE-${Date.now()}`;
    const newCase = await Case.create({
      caseId,
      userId: req.userId,
      status: 'created',
      type: 'panic',
      location: { latitude, longitude, address: 'User Location' },
      riskLevel: aiResponse.riskLevel || 'high',
      riskScore: aiResponse.riskScore || 75,
      description
    });
    
    // Assign to nearby police
    const police = await User.findOne({
      role: 'police',
      isActive: true,
      isBlocked: false
    });
    
    if (police) {
      await Case.findByIdAndUpdate(newCase._id, { 
        assignedPolice: police._id,
        status: 'assigned'
      });
    }
    
    // Assign to nearest hospital
    const hospital = await User.findOne({
      role: 'hospital',
      isActive: true,
      isBlocked: false
    });
    
    if (hospital) {
      await Case.findByIdAndUpdate(newCase._id, { 
        assignedHospital: hospital._id
      });
    }
    
    res.json({
      message: 'Emergency case created',
      caseId: newCase.caseId,
      riskLevel: newCase.riskLevel,
      riskScore: newCase.riskScore
    });
  } catch (error) {
    res.status(500).json({ message: error.message });
  }
});

app.get('/api/v1/emergency/cases', verifyToken, async (req, res) => {
  try {
    const cases = await Case.find({ userId: req.userId }).sort({ createdAt: -1 });
    res.json(cases);
  } catch (error) {
    res.status(500).json({ message: error.message });
  }
});

app.get('/api/v1/emergency/cases/:id', verifyToken, async (req, res) => {
  try {
    const caseDoc = await Case.findById(req.params.id);
    res.json(caseDoc);
  } catch (error) {
    res.status(500).json({ message: error.message });
  }
});

// ============= POLICE ENDPOINTS =============

app.get('/api/v1/police/alerts', verifyToken, requireRole('police'), async (req, res) => {
  try {
    const cases = await Case.find({
      assignedPolice: req.userId,
      status: { $in: ['created', 'assigned', 'accepted'] }
    }).sort({ createdAt: -1 });
    
    res.json(cases);
  } catch (error) {
    res.status(500).json({ message: error.message });
  }
});

app.put('/api/v1/police/cases/:id/accept', verifyToken, requireRole('police'), auditLog('ACCEPT', 'case'), async (req, res) => {
  try {
    const caseDoc = await Case.findByIdAndUpdate(req.params.id, {
      status: 'accepted',
      updatedAt: new Date()
    }, { new: true });
    
    res.json({ message: 'Case accepted', case: caseDoc });
  } catch (error) {
    res.status(500).json({ message: error.message });
  }
});

app.put('/api/v1/police/cases/:id/update', verifyToken, requireRole('police'), auditLog('UPDATE', 'case_status'), async (req, res) => {
  try {
    const { status } = req.body;
    
    const caseDoc = await Case.findByIdAndUpdate(req.params.id, {
      status,
      updatedAt: new Date(),
      resolvedAt: status === 'resolved' ? new Date() : undefined
    }, { new: true });
    
    res.json({ message: 'Case updated', case: caseDoc });
  } catch (error) {
    res.status(500).json({ message: error.message });
  }
});

// ============= HOSPITAL ENDPOINTS =============

app.get('/api/v1/hospital/alerts', verifyToken, requireRole('hospital'), async (req, res) => {
  try {
    const cases = await Case.find({
      assignedHospital: req.userId,
      type: 'accident',
      status: { $in: ['created', 'assigned', 'accepted'] }
    }).sort({ riskScore: -1 });
    
    res.json(cases);
  } catch (error) {
    res.status(500).json({ message: error.message });
  }
});

app.put('/api/v1/hospital/alerts/:id/accept', verifyToken, requireRole('hospital'), auditLog('ACCEPT', 'emergency'), async (req, res) => {
  try {
    const caseDoc = await Case.findByIdAndUpdate(req.params.id, {
      status: 'accepted',
      updatedAt: new Date()
    }, { new: true });
    
    res.json({ message: 'Emergency accepted', case: caseDoc });
  } catch (error) {
    res.status(500).json({ message: error.message });
  }
});

// ============= ADMIN ENDPOINTS =============

app.get('/api/v1/admin/cases', verifyToken, requireRole('admin'), async (req, res) => {
  try {
    const cases = await Case.find().sort({ createdAt: -1 });
    res.json(cases);
  } catch (error) {
    res.status(500).json({ message: error.message });
  }
});

app.get('/api/v1/admin/users', verifyToken, requireRole('admin'), async (req, res) => {
  try {
    const users = await User.find();
    res.json(users);
  } catch (error) {
    res.status(500).json({ message: error.message });
  }
});

app.put('/api/v1/admin/users/:id/block', verifyToken, requireRole('admin'), auditLog('BLOCK', 'user'), async (req, res) => {
  try {
    const user = await User.findByIdAndUpdate(req.params.id, {
      isBlocked: true
    }, { new: true });
    
    res.json({ message: 'User blocked', user });
  } catch (error) {
    res.status(500).json({ message: error.message });
  }
});

app.get('/api/v1/admin/audit-logs', verifyToken, requireRole('admin'), async (req, res) => {
  try {
    const logs = await AuditLog.find().sort({ timestamp: -1 }).limit(100);
    res.json(logs);
  } catch (error) {
    res.status(500).json({ message: error.message });
  }
});

app.get('/api/v1/admin/analytics', verifyToken, requireRole('admin'), async (req, res) => {
  try {
    const totalCases = await Case.countDocuments();
    const resolvedCases = await Case.countDocuments({ status: 'resolved' });
    const totalUsers = await User.countDocuments();
    const avgResponseTime = 120; // seconds (todo: calculate)
    
    res.json({
      totalCases,
      resolvedCases,
      resolutionRate: ((resolvedCases / totalCases) * 100).toFixed(2),
      totalUsers,
      avgResponseTime
    });
  } catch (error) {
    res.status(500).json({ message: error.message });
  }
});

// ============= HEALTH CHECK =============

app.get('/health', (req, res) => {
  res.json({ status: 'Backend running' });
});

// ============= CONNECT DB & START =============

mongoose.connect(process.env.MONGODB_URI)
  .then(() => {
    console.log('MongoDB connected');
    app.listen(process.env.PORT || 5000, () => {
      console.log(`Backend running on port ${process.env.PORT || 5000}`);
    });
  })
  .catch(err => console.error('DB error:', err));

module.exports = app;
