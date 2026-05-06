// Audit Logging Service - Immutable audit trail
// Critical for compliance and forensics

const crypto = require('crypto');
const fs = require('fs').promises;
const path = require('path');

class AuditLoggingService {
  // In-memory ledger (can be backed by MongoDB + file system)
  static auditLedger = [];

  /**
   * Create immutable hash chain
   */
  static generateHash(data) {
    return crypto.createHash('sha256').update(JSON.stringify(data)).digest('hex');
  }

  /**
   * Log action with hash chain for immutability
   */
  static async logAction(action, metadata = {}) {
    try {
      const previousHash = this.auditLedger.length > 0
        ? this.auditLedger[this.auditLedger.length - 1].hash
        : '0';

      const entry = {
        id: crypto.randomUUID(),
        timestamp: new Date(),
        action,
        metadata,
        userId: metadata.userId || 'SYSTEM',
        previousHash,
      };

      // Calculate hash of this entry
      const entryData = {
        action: entry.action,
        metadata: entry.metadata,
        userId: entry.userId,
        timestamp: entry.timestamp,
        previousHash: entry.previousHash,
      };

      entry.hash = this.generateHash(entryData);

      // Add to ledger
      this.auditLedger.push(entry);

      // Log to console
      console.log(
        `📋 AUDIT LOG: ${action}\n` +
        `   User: ${entry.userId}\n` +
        `   Timestamp: ${entry.timestamp}\n` +
        `   Hash: ${entry.hash.substring(0, 16)}...`
      );

      // Persist to database
      try {
        const AuditLog = require('../models/audit.model');
        await AuditLog.create({
          userId: entry.userId,
          action: action,
          details: entry.details,
          resourceType: entry.resourceType,
          resourceId: entry.resourceId,
          ipAddress: entry.ipAddress,
          timestamp: entry.timestamp,
          hash: entry.hash
        }).catch(err => console.warn('Audit persist warning:', err.message));
      } catch (persistErr) {
        console.warn('Audit logging not fully configured:', persistErr.message);
      }

      return entry;
    } catch (error) {
      console.error('Failed to log action:', error.message);
    }
  }

  /**
   * Critical events that MUST be logged
   */
  static async logEmergencyEvent(action, emergencyId, metadata = {}) {
    return this.logAction(`EMERGENCY_${action}`, {
      emergencyId,
      ...metadata,
    });
  }

  static async logAuthEvent(action, userId, metadata = {}) {
    return this.logAction(`AUTH_${action}`, {
      userId,
      ...metadata,
    });
  }

  static async logAdminEvent(action, adminId, targetUserId, metadata = {}) {
    return this.logAction(`ADMIN_${action}`, {
      adminId,
      targetUserId,
      ...metadata,
    });
  }

  static async logApprovalEvent(action, approverId, targetUserId, role, metadata = {}) {
    return this.logAction(`APPROVAL_${action}`, {
      approverId,
      targetUserId,
      role,
      ...metadata,
    });
  }

  /**
   * Verify audit trail integrity
   */
  static verifyIntegrity() {
    console.log('\n🔐 Verifying audit trail integrity...');

    let isValid = true;
    let previousHash = '0';

    for (let i = 0; i < this.auditLedger.length; i++) {
      const entry = this.auditLedger[i];

      // Check hash chain
      if (entry.previousHash !== previousHash) {
        console.error(`❌ Hash chain broken at entry ${i}`);
        isValid = false;
        break;
      }

      // Verify entry hash
      const recalculatedHash = this.generateHash({
        action: entry.action,
        metadata: entry.metadata,
        userId: entry.userId,
        timestamp: entry.timestamp,
        previousHash: entry.previousHash,
      });

      if (entry.hash !== recalculatedHash) {
        console.error(`❌ Entry hash mismatch at entry ${i}`);
        isValid = false;
        break;
      }

      previousHash = entry.hash;
    }

    if (isValid) {
      console.log(`✅ Audit trail integrity verified (${this.auditLedger.length} entries)`);
    }

    return isValid;
  }

  /**
   * Get audit logs with filtering
   */
  static async getLogs(filters = {}) {
    let logs = this.auditLedger;

    // Filter by action
    if (filters.action) {
      logs = logs.filter(l => l.action.includes(filters.action));
    }

    // Filter by userId
    if (filters.userId) {
      logs = logs.filter(l => l.userId === filters.userId);
    }

    // Filter by date range
    if (filters.startDate || filters.endDate) {
      logs = logs.filter(l => {
        const logDate = new Date(l.timestamp);
        if (filters.startDate && logDate < new Date(filters.startDate)) return false;
        if (filters.endDate && logDate > new Date(filters.endDate)) return false;
        return true;
      });
    }

    // Sort
    logs.sort((a, b) => new Date(b.timestamp) - new Date(a.timestamp));

    // Paginate
    const limit = filters.limit || 100;
    const skip = filters.skip || 0;

    return {
      total: logs.length,
      count: Math.min(limit, logs.length - skip),
      logs: logs.slice(skip, skip + limit),
    };
  }

  /**
   * Get audit summary
   */
  static async getSummary() {
    const actionCounts = {};
    const userCounts = {};

    this.auditLedger.forEach(entry => {
      actionCounts[entry.action] = (actionCounts[entry.action] || 0) + 1;
      userCounts[entry.userId] = (userCounts[entry.userId] || 0) + 1;
    });

    return {
      totalEntries: this.auditLedger.length,
      actionCounts,
      userCounts,
      integrityVerified: this.verifyIntegrity(),
    };
  }

  /**
   * Detect suspicious activity
   */
  static async detectFraud() {
    const suspicious = [];

    // Rule 1: Multiple failed login attempts
    const authLogs = this.auditLedger.filter(l => l.action.includes('AUTH'));
    const failedLogins = authLogs.filter(l => l.action === 'AUTH_FAILED');

    const loginCounts = {};
    failedLogins.forEach(log => {
      const userId = log.metadata.userId;
      loginCounts[userId] = (loginCounts[userId] || 0) + 1;
    });

    Object.entries(loginCounts).forEach(([userId, count]) => {
      if (count > 5) {
        suspicious.push({
          type: 'MULTIPLE_FAILED_LOGINS',
          userId,
          count,
          severity: 'HIGH',
        });
      }
    });

    // Rule 2: Rapid emergency triggers
    const emergencyLogs = this.auditLedger.filter(l => l.action === 'EMERGENCY_CREATED');
    const emergencyCounts = {};
    emergencyLogs.forEach(log => {
      const userId = log.metadata.userId;
      emergencyCounts[userId] = (emergencyCounts[userId] || 0) + 1;
    });

    Object.entries(emergencyCounts).forEach(([userId, count]) => {
      if (count > 10) {
        suspicious.push({
          type: 'RAPID_EMERGENCY_TRIGGERS',
          userId,
          count,
          severity: 'CRITICAL',
        });
      }
    });

    // Rule 3: GPS spoofing detection
    const locationLogs = this.auditLedger.filter(
      l => l.metadata.location && l.metadata.previousLocation
    );

    locationLogs.forEach(log => {
      const distance = this.calculateDistance(
        log.metadata.location,
        log.metadata.previousLocation
      );
      const timeDiff = Date.now() - new Date(log.timestamp); // ms

      // If traveled >100km in < 1 minute, likely spoofing
      if (distance > 100 && timeDiff < 60000) {
        suspicious.push({
          type: 'GPS_SPOOFING_DETECTED',
          userId: log.userId,
          distance: distance.toFixed(1) + 'km',
          severity: 'CRITICAL',
        });
      }
    });

    return suspicious;
  }

  /**
   * Generate compliance report
   */
  static async generateComplianceReport() {
    const summary = await this.getSummary();
    const fraud = await this.detectFraud();

    return {
      reportDate: new Date(),
      totalAuditEntries: summary.totalEntries,
      integrityVerified: summary.integrityVerified,
      suspiciousActivities: fraud.length,
      suspiciousDetails: fraud,
      actionSummary: summary.actionCounts,
      userSummary: summary.userCounts,
    };
  }

  static calculateDistance(loc1, loc2) {
    // Simplified distance calculation
    const lat = (loc2.latitude - loc1.latitude) * 111; // km per degree
    const lon = (loc2.longitude - loc1.longitude) * 111 * Math.cos(loc1.latitude * Math.PI / 180);
    return Math.sqrt(lat * lat + lon * lon);
  }

  /**
   * Export audit logs to file
   */
  static async exportLogs(filename = 'audit_export.json') {
    try {
      const filePath = path.join(__dirname, '..', '..', 'logs', filename);
      const logsData = {
        exportDate: new Date(),
        totalEntries: this.auditLedger.length,
        logs: this.auditLedger,
        integrityVerified: this.verifyIntegrity(),
      };

      await fs.writeFile(filePath, JSON.stringify(logsData, null, 2));
      console.log(`📁 Audit logs exported to ${filePath}`);
      return filePath;
    } catch (error) {
      console.error('Failed to export logs:', error.message);
      throw error;
    }
  }
}

module.exports = AuditLoggingService;
