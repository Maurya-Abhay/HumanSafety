// Backend Priority Queue & Escalation Service
const EventEmitter = require('events');

class PriorityQueueService extends EventEmitter {
  constructor() {
    super();
    this.queues = {
      critical: [],
      high: [],
      medium: [],
      low: [],
    };
    this.processing = false;
    this.processedCount = 0;
    this.isProcessing = false;
  }

  /**
   * Enqueue an emergency with priority
   */
  enqueue(emergency) {
    const priority = this.calculatePriority(emergency);
    const queueEntry = {
      id: emergency.id || `EMG-${Date.now()}`,
      emergency,
      priority,
      enqueuedAt: Date.now(),
      processedAt: null,
      status: 'queued',
    };

    this.queues[priority].push(queueEntry);
    this.emit('enqueued', { id: queueEntry.id, priority });

    // Auto-process queue
    this.processQueue();

    return queueEntry.id;
  }

  /**
   * Calculate emergency priority based on risk level
   */
  calculatePriority(emergency) {
    const riskScore = emergency.riskScore || 50;
    const type = emergency.type || 'unknown';

    // Critical: risk > 85 OR panic call
    if (riskScore > 85 || type === 'panic') {
      return 'critical';
    }
    // High: risk > 65 OR accident
    if (riskScore > 65 || type === 'accident') {
      return 'high';
    }
    // Medium: risk > 40
    if (riskScore > 40) {
      return 'medium';
    }
    return 'low';
  }

  /**
   * Process queue in priority order
   */
  async processQueue() {
    if (this.isProcessing) return;

    this.isProcessing = true;

    try {
      // Process in priority order: critical → high → medium → low
      for (const priority of ['critical', 'high', 'medium', 'low']) {
        const queue = this.queues[priority];

        // Process first 10 items from each priority to avoid starvation
        const toProcess = queue.splice(0, Math.min(10, queue.length));

        for (const entry of toProcess) {
          entry.processedAt = Date.now();
          entry.status = 'processing';

          this.emit('processing', {
            id: entry.id,
            priority,
            queueWaitTime: entry.processedAt - entry.enqueuedAt,
          });

          // Yield to event loop
          await new Promise((resolve) => setImmediate(resolve));
        }
      }

      this.processedCount++;
    } finally {
      this.isProcessing = false;
    }
  }

  /**
   * Get next item by priority
   */
  dequeue() {
    for (const priority of ['critical', 'high', 'medium', 'low']) {
      if (this.queues[priority].length > 0) {
        return this.queues[priority].shift();
      }
    }
    return null;
  }

  /**
   * Get queue statistics
   */
  getStats() {
    return {
      critical: this.queues.critical.length,
      high: this.queues.high.length,
      medium: this.queues.medium.length,
      low: this.queues.low.length,
      totalQueued:
        this.queues.critical.length +
        this.queues.high.length +
        this.queues.medium.length +
        this.queues.low.length,
      processedCount: this.processedCount,
      avgProcessingTime: this.calculateAverageProcessingTime(),
    };
  }

  calculateAverageProcessingTime() {
    // Track average wait time in queue
    const allEntries = Object.values(this.queues).flat();
    if (allEntries.length === 0) return 0;

    const waitTimes = allEntries
      .filter((e) => e.processedAt)
      .map((e) => e.processedAt - e.enqueuedAt);

    return waitTimes.length > 0
      ? waitTimes.reduce((a, b) => a + b, 0) / waitTimes.length
      : 0;
  }
}

/**
 * Emergency Escalation Engine
 */
class EscalationEngine extends EventEmitter {
  constructor() {
    super();
    this.escalationChains = {
      // low: police_only
      // medium: police + hospital
      // high: police + hospital + admin
      // critical: all + escalate to government
    };
    this.escalationRules = [
      {
        condition: 'noResponseAfter',
        timeout: 300000, // 5 minutes
        action: 'escalateToHigher',
      },
      {
        condition: 'multipleEmergenciesSameLocation',
        threshold: 3,
        timeWindow: 600000, // 10 minutes
        action: 'escalateToCritical',
      },
      {
        condition: 'consecutiveFailures',
        threshold: 2,
        action: 'escalateToAdmin',
      },
    ];
    this.emergencyHistory = [];
    this.escalationLog = [];
  }

  /**
   * Check if emergency should be escalated
   */
  checkEscalation(emergency) {
    const escalations = [];

    // Rule 1: No response timeout
    if (emergency.status === 'assigned' && !emergency.assignedPolice) {
      const timeElapsed = Date.now() - emergency.createdAt;
      if (timeElapsed > this.escalationRules[0].timeout) {
        escalations.push({
          reason: 'noResponseTimeout',
          action: 'escalateToHigher',
          requiredLevel: 'admin',
        });
      }
    }

    // Rule 2: Multiple emergencies in same location
    const nearbyEmergencies = this.emergencyHistory.filter(
      (e) =>
        Math.abs(e.location.latitude - emergency.location.latitude) < 0.01 &&
        Math.abs(e.location.longitude - emergency.location.longitude) < 0.01 &&
        Date.now() - e.createdAt < this.escalationRules[1].timeWindow
    );

    if (nearbyEmergencies.length >= this.escalationRules[1].threshold) {
      escalations.push({
        reason: 'multipleEmergenciesDetected',
        action: 'escalateToCritical',
        nearbyCount: nearbyEmergencies.length,
      });
    }

    // Rule 3: Consecutive failures
    if (emergency.failureCount >= this.escalationRules[2].threshold) {
      escalations.push({
        reason: 'consecutiveFailures',
        action: 'escalateToAdmin',
        failureCount: emergency.failureCount,
      });
    }

    // Log escalations
    escalations.forEach((esc) => {
      this.escalationLog.push({
        emergencyId: emergency.id,
        ...esc,
        timestamp: Date.now(),
      });

      this.emit('escalation', {
        emergencyId: emergency.id,
        ...esc,
      });
    });

    return escalations;
  }

  /**
   * Get escalation history
   */
  getEscalationLog() {
    return this.escalationLog;
  }

  /**
   * Track emergency for escalation rules
   */
  trackEmergency(emergency) {
    this.emergencyHistory.push({
      ...emergency,
      createdAt: Date.now(),
    });

    // Keep only last 1000 emergencies
    if (this.emergencyHistory.length > 1000) {
      this.emergencyHistory = this.emergencyHistory.slice(-1000);
    }
  }
}

module.exports = {
  PriorityQueueService,
  EscalationEngine,
};
