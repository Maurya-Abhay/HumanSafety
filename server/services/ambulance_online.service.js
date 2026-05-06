// Ambulance Online Detection Service
// Tracks ambulance heartbeat and auto-detects offline status

const Ambulance = require('../models/ambulance.model');
const { getRealtimeService } = require('./realtime_event_service');
const { getLogger } = require('./logger.service');

const logger = getLogger();

class AmbulanceOnlineService {
  constructor() {
    this.heartbeatTimeout = 5 * 60 * 1000; // 5 minutes
    this.heartbeatCheckInterval = 60 * 1000; // Check every 1 minute
    this.offlineCheckRunning = false;
    this.heartbeatTimers = new Map(); // ambulanceId -> timeout
  }

  /**
   * Register heartbeat for ambulance (call when location updates)
   */
  async recordHeartbeat(ambulanceId) {
    try {
      const ambulance = await Ambulance.findById(ambulanceId);
      if (!ambulance) return;

      const now = new Date();
      ambulance.lastHeartbeat = now;
      ambulance.isOnline = true;

      await ambulance.save();

      // Clear any pending offline timer
      if (this.heartbeatTimers.has(ambulanceId)) {
        clearTimeout(this.heartbeatTimers.get(ambulanceId));
        this.heartbeatTimers.delete(ambulanceId);
      }

      // Set new offline timer
      const timeoutId = setTimeout(() => {
        this.markOffline(ambulanceId);
      }, this.heartbeatTimeout);

      this.heartbeatTimers.set(ambulanceId, timeoutId);

      logger.debug(`[AmbulanceOnline] Heartbeat recorded`, {
        ambulanceId,
        timestamp: now.toISOString(),
      });
    } catch (error) {
      logger.error('[AmbulanceOnline] Failed to record heartbeat', error, {
        ambulanceId,
      });
    }
  }

  /**
   * Mark ambulance as offline
   */
  async markOffline(ambulanceId) {
    try {
      const ambulance = await Ambulance.findById(ambulanceId);
      if (!ambulance || !ambulance.isOnline) return;

      ambulance.isOnline = false;
      ambulance.status = 'unavailable';
      await ambulance.save();

      const realtimeService = getRealtimeService();

      // Notify admin
      realtimeService.broadcastByRole('admin', {
        type: 'AMBULANCE_OFFLINE',
        data: {
          ambulanceId,
          licenseNumber: ambulance.licenseNumber,
          driverName: ambulance.driverName,
          lastHeartbeat: ambulance.lastHeartbeat,
          timestamp: new Date(),
        },
      });

      logger.warn('[AmbulanceOnline] Ambulance marked offline', {
        ambulanceId,
        licenseNumber: ambulance.licenseNumber,
        lastHeartbeat: ambulance.lastHeartbeat?.toISOString(),
      });
    } catch (error) {
      logger.error('[AmbulanceOnline] Failed to mark ambulance offline', error, {
        ambulanceId,
      });
    }
  }

  /**
   * Mark ambulance as online
   */
  async markOnline(ambulanceId) {
    try {
      const ambulance = await Ambulance.findById(ambulanceId);
      if (!ambulance) return;

      if (!ambulance.isOnline) {
        ambulance.isOnline = true;
        ambulance.lastHeartbeat = new Date();
        await ambulance.save();

        const realtimeService = getRealtimeService();
        realtimeService.broadcastByRole('admin', {
          type: 'AMBULANCE_ONLINE',
          data: {
            ambulanceId,
            licenseNumber: ambulance.licenseNumber,
            driverName: ambulance.driverName,
            currentLocation: ambulance.currentLocation,
            timestamp: new Date(),
          },
        });

        logger.info('[AmbulanceOnline] Ambulance marked online', {
          ambulanceId,
          licenseNumber: ambulance.licenseNumber,
        });
      }
    } catch (error) {
      logger.error('[AmbulanceOnline] Failed to mark ambulance online', error, {
        ambulanceId,
      });
    }
  }

  /**
   * Start periodic offline check
   */
  startOfflineDetection() {
    if (this.offlineCheckRunning) return;

    this.offlineCheckRunning = true;
    logger.info('[AmbulanceOnline] Started offline detection');

    setInterval(() => {
      this.checkOfflineAmbulances();
    }, this.heartbeatCheckInterval);
  }

  /**
   * Check and mark all offline ambulances
   */
  async checkOfflineAmbulances() {
    try {
      const timeoutThreshold = new Date(Date.now() - this.heartbeatTimeout);

      const offlineAmbulances = await Ambulance.find({
        isOnline: true,
        lastHeartbeat: { $lt: timeoutThreshold },
      });

      for (const ambulance of offlineAmbulances) {
        await this.markOffline(ambulance._id);
      }

      if (offlineAmbulances.length > 0) {
        logger.warn('[AmbulanceOnline] Detected offline ambulances', {
          count: offlineAmbulances.length,
          ambulances: offlineAmbulances.map(a => a.licenseNumber),
        });
      }
    } catch (error) {
      logger.error('[AmbulanceOnline] Offline detection failed', error);
    }
  }

  /**
   * Get ambulance online status
   */
  async getStatus(ambulanceId) {
    try {
      const ambulance = await Ambulance.findById(ambulanceId);
      if (!ambulance) return null;

      const timeSinceHeartbeat = ambulance.lastHeartbeat
        ? Date.now() - ambulance.lastHeartbeat.getTime()
        : null;

      return {
        ambulanceId,
        licenseNumber: ambulance.licenseNumber,
        driverName: ambulance.driverName,
        isOnline: ambulance.isOnline,
        status: ambulance.status,
        lastHeartbeat: ambulance.lastHeartbeat,
        timeSinceHeartbeatMs: timeSinceHeartbeat,
        currentLocation: ambulance.currentLocation,
        assignedCaseId: ambulance.assignedCaseId,
      };
    } catch (error) {
      logger.error('[AmbulanceOnline] Failed to get status', error, {
        ambulanceId,
      });
      return null;
    }
  }

  /**
   * Get all online ambulances
   */
  async getOnlineAmbulances() {
    try {
      return await Ambulance.find({ isOnline: true })
        .select('licenseNumber driverName status currentLocation assignedCaseId')
        .lean();
    } catch (error) {
      logger.error('[AmbulanceOnline] Failed to get online ambulances', error);
      return [];
    }
  }

  /**
   * Get all offline ambulances
   */
  async getOfflineAmbulances() {
    try {
      return await Ambulance.find({ isOnline: false })
        .select('licenseNumber driverName lastHeartbeat currentLocation')
        .lean();
    } catch (error) {
      logger.error('[AmbulanceOnline] Failed to get offline ambulances', error);
      return [];
    }
  }

  /**
   * Get ambulance online statistics
   */
  async getStats() {
    try {
      const total = await Ambulance.countDocuments();
      const online = await Ambulance.countDocuments({ isOnline: true });
      const offline = await Ambulance.countDocuments({ isOnline: false });

      return {
        total,
        online,
        offline,
        onlinePercentage: total > 0 ? ((online / total) * 100).toFixed(1) : 0,
      };
    } catch (error) {
      logger.error('[AmbulanceOnline] Failed to get stats', error);
      return { total: 0, online: 0, offline: 0, onlinePercentage: 0 };
    }
  }

  /**
   * Clean up timers (call on server shutdown)
   */
  cleanup() {
    logger.info('[AmbulanceOnline] Cleaning up timers');
    this.heartbeatTimers.forEach(timeoutId => {
      clearTimeout(timeoutId);
    });
    this.heartbeatTimers.clear();
  }
}

// Singleton instance
let ambulanceOnlineService = null;

const getAmbulanceOnlineService = () => {
  if (!ambulanceOnlineService) {
    ambulanceOnlineService = new AmbulanceOnlineService();
  }
  return ambulanceOnlineService;
};

module.exports = {
  getAmbulanceOnlineService,
  AmbulanceOnlineService,
};
