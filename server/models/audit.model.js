const mongoose = require('mongoose');

/**
 * Audit Log - Immutable record of all critical actions
 */
const auditLogSchema = new mongoose.Schema({
  userId: {
    type: mongoose.Schema.Types.ObjectId,
    ref: 'User',
    index: true
  },
  action: {
    type: String,
    required: true,
    enum: [
      'USER_LOGIN',
      'USER_LOGOUT',
      'USER_PROFILE_UPDATE',
      'EMERGENCY_CREATED',
      'EMERGENCY_ESCALATED',
      'EMERGENCY_ACCEPTED',
      'EMERGENCY_RESOLVED',
      'POLICE_REGISTERED',
      'HOSPITAL_REGISTERED',
      'AMBULANCE_DISPATCHED',
      'CASE_CREATED',
      'CASE_UPDATED',
      'USER_BLOCKED',
      'USER_UNBLOCKED',
      'ROLE_ASSIGNED',
      'ROLE_REVOKED',
      'ADMIN_ACTION',
      'SYSTEM_EVENT'
    ]
  },
  details: mongoose.Schema.Types.Mixed,
  resourceType: String,
  resourceId: mongoose.Schema.Types.ObjectId,
  ipAddress: String,
  userAgent: String,
  status: {
    type: String,
    enum: ['SUCCESS', 'FAILURE', 'WARNING'],
    default: 'SUCCESS'
  },
  timestamp: Date,
  hash: String,
  previousHash: String,
  createdAt: { type: Date, default: Date.now, index: true }
}, { collection: 'audit_logs' });

// Create index for integrity check
auditLogSchema.index({ createdAt: -1 });
auditLogSchema.index({ userId: 1, createdAt: -1 });
auditLogSchema.index({ action: 1, createdAt: -1 });

module.exports = mongoose.model('AuditLog', auditLogSchema);
