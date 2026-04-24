// Backend Immutable Audit Log Service
const crypto = require('crypto');

class AuditLogService {
  constructor(options = {}) {
    this.logs = [];
    this.chainHash = null;
    this.maxLogsInMemory = options.maxLogs || 5000;
  }

  /**
   * Log an event immutably (blockchain-style hash chain)
   */
  logEvent(event) {
    const logEntry = {
      id: `AUDIT-${Date.now()}-${Math.random().toString(36).substr(2, 9)}`,
      timestamp: Date.now(),
      actor: event.actor,
      action: event.action,
      resource: event.resource,
      resourceId: event.resourceId,
      changes: event.changes || {},
      ipAddress: event.ipAddress,
      deviceFingerprint: event.deviceFingerprint,
      result: event.result || 'success',
      errorMessage: event.errorMessage || null,
      severity: this.calculateSeverity(event.action),
      // Blockchain-style chaining
      previousHash: this.chainHash,
      hash: null,
    };

    // Calculate hash for this entry
    logEntry.hash = this.calculateHash(logEntry);

    // Update chain
    this.chainHash = logEntry.hash;

    // Add to logs
    this.logs.push(logEntry);

    // Maintain size limit
    if (this.logs.length > this.maxLogsInMemory) {
      this.archiveOldLogs();
    }

    return logEntry;
  }

  /**
   * Calculate SHA256 hash for immutability
   */
  calculateHash(logEntry) {
    const data = JSON.stringify({
      timestamp: logEntry.timestamp,
      actor: logEntry.actor,
      action: logEntry.action,
      resource: logEntry.resource,
      changes: logEntry.changes,
      previousHash: logEntry.previousHash,
    });

    return crypto.createHash('sha256').update(data).digest('hex');
  }

  /**
   * Verify integrity of audit log
   */
  verifyIntegrity(fromIndex = 0) {
    let previousHash = fromIndex === 0 ? null : this.logs[fromIndex - 1].hash;
    let isValid = true;
    const tamperedIndices = [];

    for (let i = fromIndex; i < this.logs.length; i++) {
      const log = this.logs[i];
      const calculatedHash = this.calculateHash({
        ...log,
        previousHash,
      });

      if (calculatedHash !== log.hash) {
        isValid = false;
        tamperedIndices.push(i);
      }

      previousHash = log.hash;
    }

    return {
      isValid,
      tamperedIndices,
      lastVerified: Date.now(),
    };
  }

  /**
   * Calculate severity level for audit action
   */
  calculateSeverity(action) {
    const severities = {
      BLOCK: 'critical',
      DELETE: 'high',
      UPDATE: 'medium',
      CREATE: 'low',
      READ: 'low',
    };

    return severities[action] || 'low';
  }

  /**
   * Get audit logs with filtering
   */
  getLogs(filter = {}) {
    let filtered = this.logs;

    if (filter.actor) {
      filtered = filtered.filter((l) => l.actor === filter.actor);
    }

    if (filter.action) {
      filtered = filtered.filter((l) => l.action === filter.action);
    }

    if (filter.resource) {
      filtered = filtered.filter((l) => l.resource === filter.resource);
    }

    if (filter.severity) {
      filtered = filtered.filter((l) => l.severity === filter.severity);
    }

    if (filter.startTime && filter.endTime) {
      filtered = filtered.filter(
        (l) => l.timestamp >= filter.startTime && l.timestamp <= filter.endTime
      );
    }

    // Return in reverse chronological order
    return filtered.reverse().slice(0, filter.limit || 100);
  }

  /**
   * Get audit trail for a resource
   */
  getResourceAuditTrail(resourceId) {
    return this.logs
      .filter((l) => l.resourceId === resourceId)
      .sort((a, b) => a.timestamp - b.timestamp);
  }

  /**
   * Get high-severity events
   */
  getCriticalEvents(hoursAgo = 24) {
    const cutoff = Date.now() - hoursAgo * 3600000;

    return this.logs
      .filter((l) => l.severity === 'critical' && l.timestamp > cutoff)
      .sort((a, b) => b.timestamp - a.timestamp);
  }

  /**
   * Detect suspicious patterns
   */
  detectSuspiciousPatterns() {
    const patterns = [];

    // Pattern 1: Multiple failed attempts from same user
    const recentLogs = this.logs.slice(-1000);
    const userFailures = {};

    recentLogs.forEach((log) => {
      if (log.result === 'failed') {
        userFailures[log.actor] = (userFailures[log.actor] || 0) + 1;
      }
    });

    Object.entries(userFailures).forEach(([actor, count]) => {
      if (count > 5) {
        patterns.push({
          type: 'multiple_failed_attempts',
          actor,
          count,
          severity: 'high',
        });
      }
    });

    // Pattern 2: Bulk delete operations
    const deleteOps = recentLogs.filter((l) => l.action === 'DELETE');
    if (deleteOps.length > 10) {
      patterns.push({
        type: 'bulk_delete_operations',
        count: deleteOps.length,
        severity: 'critical',
      });
    }

    // Pattern 3: Privilege escalation attempts
    const privOps = recentLogs.filter(
      (l) => l.action === 'UPDATE' && l.resource === 'user_permissions'
    );
    if (privOps.length > 3) {
      patterns.push({
        type: 'privilege_escalation_attempts',
        count: privOps.length,
        severity: 'critical',
      });
    }

    return patterns;
  }

  /**
   * Archive old logs (in production, would archive to cold storage)
   */
  archiveOldLogs() {
    const cutoff = Date.now() - 7 * 24 * 3600000; // 7 days
    const toArchive = this.logs.filter((l) => l.timestamp < cutoff);

    // In production: send to S3, archive database, etc.
    console.log(`Archiving ${toArchive.length} old audit logs`);

    // Keep recent logs in memory
    this.logs = this.logs.filter((l) => l.timestamp >= cutoff);
  }

  /**
   * Get audit statistics
   */
  getStatistics() {
    const now = Date.now();
    const last24h = now - 24 * 3600000;

    const recentLogs = this.logs.filter((l) => l.timestamp > last24h);

    return {
      totalLogs: this.logs.length,
      last24hLogs: recentLogs.length,
      byAction: this.groupBy(recentLogs, 'action'),
      bySeverity: this.groupBy(recentLogs, 'severity'),
      byResult: this.groupBy(recentLogs, 'result'),
      chainValid: this.verifyIntegrity().isValid,
    };
  }

  /**
   * Helper: Group logs by property
   */
  groupBy(logs, property) {
    return logs.reduce((acc, log) => {
      acc[log[property]] = (acc[log[property]] || 0) + 1;
      return acc;
    }, {});
  }

  /**
   * Export audit logs (for compliance)
   */
  exportLogs(format = 'json') {
    const data = {
      exportDate: Date.now(),
      chainValid: this.verifyIntegrity().isValid,
      logs: this.logs,
    };

    if (format === 'json') {
      return JSON.stringify(data, null, 2);
    } else if (format === 'csv') {
      return this.logsToCSV(this.logs);
    }

    return data;
  }

  /**
   * Convert logs to CSV
   */
  logsToCSV(logs) {
    const headers = [
      'id',
      'timestamp',
      'actor',
      'action',
      'resource',
      'severity',
      'result',
    ];

    const rows = logs.map((log) => [
      log.id,
      new Date(log.timestamp).toISOString(),
      log.actor,
      log.action,
      log.resource,
      log.severity,
      log.result,
    ]);

    return [headers, ...rows].map((row) => row.join(',')).join('\n');
  }
}

module.exports = AuditLogService;
