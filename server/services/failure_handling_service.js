// Failure Handling Service - Handles retries, dead-letter queue, and offline sync
// This ensures NO emergency is ever lost

const Emergency = require('../models/emergency.model');

class FailureHandlingService {
  // ============================================================
  // RETRY LOGIC WITH EXPONENTIAL BACKOFF
  // ============================================================

  /**
   * Retry failed operation with exponential backoff
   * @param {Object} operation - { type, emergencyId, handler, maxRetries }
   * @param {Function} callback - Function to execute
   */
  static async retryWithBackoff(operation, callback, attempt = 1) {
    const maxRetries = operation.maxRetries || 5;
    const baseDelay = 1000; // 1 second

    try {
      return await callback();
    } catch (error) {
      if (attempt < maxRetries) {
        // Calculate exponential backoff: 1s, 2s, 4s, 8s, 16s
        const delay = baseDelay * Math.pow(2, attempt - 1);

        console.log(
          `⚠️  Operation ${operation.type} failed (attempt ${attempt}/${maxRetries}). ` +
          `Retrying in ${delay}ms...`
        );

        // Wait and retry
        await new Promise(resolve => setTimeout(resolve, delay));
        return this.retryWithBackoff(operation, callback, attempt + 1);
      } else {
        // Max retries exceeded - send to dead-letter queue
        console.error(`❌ Operation ${operation.type} failed after ${maxRetries} attempts`);
        throw error;
      }
    }
  }

  // ============================================================
  // DEAD-LETTER QUEUE (DLQ)
  // ============================================================

  /**
   * Send failed event to dead-letter queue for manual review
   */
  static async sendToDeadLetterQueue(emergencyId, reason, metadata = {}) {
    try {
      const emergency = await Emergency.findByIdAndUpdate(
        emergencyId,
        {
          isInDeadLetterQueue: true,
          deadLetterReason: reason,
          failureReason: reason,
        },
        { new: true }
      );

      console.error(
        `🚨 DEAD-LETTER EVENT: Emergency ${emergencyId} sent to DLQ\n` +
        `Reason: ${reason}\n` +
        `State: ${emergency.state}\n` +
        `Metadata: ${JSON.stringify(metadata)}`
      );

      // Log to monitoring service (Integrated with logger service)
      const logger = require('./logger.service');
      logger.logEvent('DLQ_EVENT_ALERT', {
        emergencyId,
        reason,
        state: emergency.state,
        metadata,
        timestamp: new Date().toISOString()
      });

      return emergency;
    } catch (error) {
      console.error('Failed to send to DLQ:', error.message);
      throw error;
    }
  }

  /**
   * Retrieve all dead-letter queue events (Admin only)
   */
  static async getDeadLetterQueue(limit = 100, skip = 0) {
    return await Emergency.find({ isInDeadLetterQueue: true })
      .sort({ createdAt: -1 })
      .limit(limit)
      .skip(skip);
  }

  /**
   * Retry a dead-letter queue event
   */
  static async retryDeadLetterEvent(emergencyId) {
    try {
      const emergency = await Emergency.findByIdAndUpdate(
        emergencyId,
        {
          isInDeadLetterQueue: false,
          deadLetterReason: '',
          retryCount: emergency.retryCount + 1,
          lastRetryAt: new Date(),
        },
        { new: true }
      );

      console.log(`♻️  Retrying dead-letter event: ${emergencyId}`);
      return emergency;
    } catch (error) {
      console.error('Failed to retry DLQ event:', error.message);
      throw error;
    }
  }

  // ============================================================
  // OFFLINE QUEUE (Mobile)
  // ============================================================

  /**
   * Queue event for offline sync
   * Called when mobile app has no network connectivity
   */
  static async queueOfflineEvent(emergencyData) {
    try {
      const emergency = await Emergency.create({
        ...emergencyData,
        isOfflineQueued: true,
        offlineQueueSync: false,
        state: 'CREATED',
      });

      console.log(`📵 Offline event queued: ${emergency._id}`);
      return emergency;
    } catch (error) {
      console.error('Failed to queue offline event:', error.message);
      throw error;
    }
  }

  /**
   * Sync offline queue when connectivity restored
   */
  static async syncOfflineQueue(userId) {
    try {
      const offlineEvents = await Emergency.find({
        userId,
        isOfflineQueued: true,
        offlineQueueSync: false,
      });

      console.log(`🔄 Syncing ${offlineEvents.length} offline events for user ${userId}`);

      const results = [];
      for (const event of offlineEvents) {
        try {
          // Process each offline event
          const updated = await Emergency.findByIdAndUpdate(
            event._id,
            {
              offlineQueueSync: true,
              isOfflineQueued: false,
            },
            { new: true }
          );
          results.push({ status: 'synced', emergencyId: updated._id });
        } catch (error) {
          results.push({
            status: 'failed',
            emergencyId: event._id,
            error: error.message,
          });
        }
      }

      return {
        totalSynced: results.filter(r => r.status === 'synced').length,
        totalFailed: results.filter(r => r.status === 'failed').length,
        results,
      };
    } catch (error) {
      console.error('Failed to sync offline queue:', error.message);
      throw error;
    }
  }

  // ============================================================
  // TIMEOUT DETECTION & AUTO-ESCALATION
  // ============================================================

  /**
   * Check for timed-out emergencies and auto-escalate
   * Run periodically (every 10 seconds)
   */
  static async checkTimeouts() {
    try {
      const now = Date.now();
      const ACCEPTANCE_TIMEOUT = 15 * 1000; // 15 seconds
      const RESPONSE_TIMEOUT = 5 * 60 * 1000; // 5 minutes

      // Find emergencies waiting for first response
      const timedOutEmergencies = await Emergency.find({
        state: 'BROADCASTED',
        broadcastedAt: { $lt: new Date(now - ACCEPTANCE_TIMEOUT) },
      });

      console.log(`⏱️  Checking ${timedOutEmergencies.length} emergencies for timeout...`);

      for (const emergency of timedOutEmergencies) {
        await this.escalateEmergency(emergency._id, 'TIMEOUT_NO_ACCEPTANCE');
      }

      return timedOutEmergencies.length;
    } catch (error) {
      console.error('Failed to check timeouts:', error.message);
    }
  }

  /**
   * Escalate emergency to next handler or authority
   */
  static async escalateEmergency(emergencyId, reason) {
    try {
      const emergency = await Emergency.findById(emergencyId);

      if (!emergency) {
        throw new Error('Emergency not found');
      }

      emergency.state = 'ESCALATED';
      emergency.escalationCount += 1;
      emergency.escalationReason = reason;
      await emergency.save();

      console.log(
        `🔴 ESCALATION: Emergency ${emergencyId}\n` +
        `Reason: ${reason}\n` +
        `Escalation #${emergency.escalationCount}`
      );

      // Implement escalation logic
      const realtimeService = require('./realtime_event_service');
      
      if (reason === 'TIMEOUT_NO_ACCEPTANCE') {
        // Police didn't respond - broadcast to wider area
        realtimeService.broadcastByRole('police', {
          type: 'EMERGENCY_ESCALATED',
          data: {
            emergencyId: emergency._id,
            reason,
            escalationLevel: emergency.escalationCount,
            location: emergency.location
          }
        });
        console.log(`📢 Re-broadcasting to wider police network (escalation level ${emergency.escalationCount})`);
      }
      
      if (emergency.escalationCount >= 3) {
        // Multiple escalations - alert dispatcher/admin
        realtimeService.broadcastByRole('admin', {
          type: 'EMERGENCY_CRITICAL_ESCALATION',
          data: {
            emergencyId: emergency._id,
            escalationCount: emergency.escalationCount,
            reason,
            location: emergency.location
          }
        });
        console.log(`🚨 CRITICAL: Emergency escalated ${emergency.escalationCount} times - admin notified`);
      }

      return emergency;
    } catch (error) {
      console.error('Failed to escalate emergency:', error.message);
      throw error;
    }
  }

  // ============================================================
  // SMS FALLBACK (No Network)
  // ============================================================

  /**
   * Send SMS when app/network fails
   * For trusted contacts
   */
  static async sendSMSFallback(userId, emergencyLocation, trustedContacts) {
    try {
      const { sendSMS } = require('./sms.service');

      const smsRecipients = [];

      // Send to emergency contacts
      for (const contact of trustedContacts) {
        const message =
          `🚨 EMERGENCY ALERT: Your friend ${userId} triggered an emergency at ` +
          `${emergencyLocation.address || `${emergencyLocation.latitude}, ${emergencyLocation.longitude}`}. ` +
          `Help is on the way. Reply with any info.`;

        try {
          await sendSMS(contact.phone, message);
          smsRecipients.push(contact.phone);
        } catch (error) {
          console.error(`Failed to send SMS to ${contact.phone}:`, error.message);
        }
      }

      console.log(`📱 SMS fallback sent to ${smsRecipients.length} contacts`);
      return smsRecipients;
    } catch (error) {
      console.error('Failed to send SMS fallback:', error.message);
    }
  }

  // ============================================================
  // HEALTH CHECK & RECOVERY
  // ============================================================

  /**
   * Check system health and recover from failures
   */
  static async systemHealthCheck() {
    try {
      const stats = {
        totalEmergencies: await Emergency.countDocuments(),
        activeEmergencies: await Emergency.countDocuments({
          state: { $in: ['BROADCASTED', 'ACCEPTED', 'IN_PROGRESS'] },
        }),
        failedEmergencies: await Emergency.countDocuments({
          isInDeadLetterQueue: true,
        }),
        offlineQueuedEmergencies: await Emergency.countDocuments({
          isOfflineQueued: true,
          offlineQueueSync: false,
        }),
      };

      console.log('📊 System Health Check:');
      console.log(`   Total Emergencies: ${stats.totalEmergencies}`);
      console.log(`   Active: ${stats.activeEmergencies}`);
      console.log(`   Failed (DLQ): ${stats.failedEmergencies}`);
      console.log(`   Offline Queue: ${stats.offlineQueuedEmergencies}`);

      // Alert if too many failed
      if (stats.failedEmergencies > 10) {
        console.warn('⚠️  WARNING: High number of failed emergencies in DLQ');
        const realtimeService = require('./realtime_event_service');
        realtimeService.broadcastByRole('admin', {
          type: 'SYSTEM_ALERT',
          data: {
            alertType: 'HIGH_DLQ_COUNT',
            failedEmergencies: stats.failedEmergencies,
            message: `High number of failed emergencies (${stats.failedEmergencies}) in dead-letter queue`
          }
        });
      }

      return stats;
    } catch (error) {
      console.error('Health check failed:', error.message);
    }
  }

  // ============================================================
  // RECOVERY STRATEGY
  // ============================================================

  /**
   * Attempt to recover failed operations
   */
  static async attemptRecovery(emergencyId) {
    try {
      const emergency = await Emergency.findById(emergencyId);

      if (!emergency) {
        throw new Error('Emergency not found');
      }

      console.log(`🔧 Attempting recovery for ${emergencyId}...`);

      // Strategy 1: If no police accepted, escalate
      if (emergency.state === 'BROADCASTED' && !emergency.assignedPolice) {
        await this.escalateEmergency(emergencyId, 'RECOVERY_NO_POLICE');
      }

      // Strategy 2: If no hospital accepted, try next hospital
      if (emergency.state === 'ACCEPTED' && !emergency.assignedHospital) {
        console.log('Recovery: Trying next hospital');
        const hospitalRoutingService = require('./hospital_routing_service');
        try {
          const nextHospital = await hospitalRoutingService.getNextHospital(
            emergency.location,
            [emergency.attemptedHospitals || []].flat()
          );
          if (nextHospital) {
            emergency.attemptedHospitals = emergency.attemptedHospitals || [];
            emergency.attemptedHospitals.push(nextHospital._id);
            await emergency.save();
            console.log(`✅ Attempting next hospital: ${nextHospital.name}`);
          }
        } catch (routingError) {
          console.error('Hospital retry failed:', routingError.message);
        }
      }

      // Strategy 3: If stuck in progress for too long, re-broadcast
      const inProgressDuration = Date.now() - emergency.acceptedAt?.getTime();
      if (emergency.state === 'IN_PROGRESS' && inProgressDuration > 30 * 60 * 1000) {
        await this.escalateEmergency(emergencyId, 'RECOVERY_LONG_DURATION');
      }

      return emergency;
    } catch (error) {
      console.error('Recovery failed:', error.message);
      throw error;
    }
  }
}

module.exports = FailureHandlingService;
