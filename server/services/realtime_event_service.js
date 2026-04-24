// Real-Time Event Streaming Service
// Uses WebSocket for native, polling for web, with Redis for scaling

const EventEmitter = require('events');

class RealtimeEventService extends EventEmitter {
  constructor() {
    super();
    this.wsClients = new Map(); // userId -> WebSocket connections
    this.redisConnections = new Map(); // For scaling (TODO: integrate Redis)
    this.eventQueue = [];
    this.MAX_QUEUE_SIZE = 10000;
  }

  // ============================================================
  // WEBSOCKET CONNECTION MANAGEMENT
  // ============================================================

  /**
   * Register WebSocket client
   */
  registerClient(userId, ws, role) {
    if (!this.wsClients.has(userId)) {
      this.wsClients.set(userId, []);
    }

    this.wsClients.get(userId).push({
      ws,
      role,
      connectedAt: new Date(),
      isAlive: true,
    });

    console.log(`✅ Client connected: ${userId} (${role})`);
    console.log(`   Total connections: ${this.getTotalConnections()}`);

    // Send acknowledgement
    this.sendToClient(userId, {
      type: 'CONNECTION_ESTABLISHED',
      data: {
        userId,
        connectedAt: new Date(),
        role,
      },
    });

    // Setup heart beat
    this.setupHeartbeat(userId, ws);
  }

  /**
   * Unregister WebSocket client
   */
  unregisterClient(userId, ws) {
    if (!this.wsClients.has(userId)) return;

    const clients = this.wsClients.get(userId);
    const index = clients.findIndex(c => c.ws === ws);

    if (index !== -1) {
      clients.splice(index, 1);
      console.log(`❌ Client disconnected: ${userId}`);
      console.log(`   Remaining connections: ${this.getTotalConnections()}`);
    }

    if (clients.length === 0) {
      this.wsClients.delete(userId);
    }
  }

  /**
   * Setup heart beat to detect dead connections
   */
  setupHeartbeat(userId, ws) {
    const interval = setInterval(() => {
      if (!this.wsClients.has(userId)) {
        clearInterval(interval);
        return;
      }

      const clients = this.wsClients.get(userId);
      const client = clients.find(c => c.ws === ws);

      if (!client) {
        clearInterval(interval);
        return;
      }

      if (!client.isAlive) {
        ws.terminate();
        this.unregisterClient(userId, ws);
        clearInterval(interval);
        return;
      }

      client.isAlive = false;
      ws.ping();
    }, 30000); // 30 seconds
  }

  /**
   * Get total active connections
   */
  getTotalConnections() {
    let total = 0;
    this.wsClients.forEach(clients => {
      total += clients.length;
    });
    return total;
  }

  // ============================================================
  // EVENT BROADCASTING
  // ============================================================

  /**
   * Send event to specific user
   */
  sendToClient(userId, event) {
    if (!this.wsClients.has(userId)) {
      // Queue event if client offline
      this.queueEvent(userId, event);
      return;
    }

    const clients = this.wsClients.get(userId);
    const payload = JSON.stringify(event);

    clients.forEach(client => {
      if (client.ws.readyState === 1) { // OPEN
        client.ws.send(payload);
      }
    });
  }

  /**
   * Send event to multiple users (broadcast by role)
   */
  broadcastByRole(role, event) {
    let count = 0;
    this.wsClients.forEach((clients, userId) => {
      const hasRole = clients.some(c => c.role === role);
      if (hasRole) {
        this.sendToClient(userId, event);
        count++;
      }
    });

    console.log(`📡 Broadcast to ${count} users with role '${role}'`);
  }

  /**
   * Send event to all connected clients
   */
  broadcastAll(event) {
    const payload = JSON.stringify(event);
    let count = 0;

    this.wsClients.forEach((clients, userId) => {
      clients.forEach(client => {
        if (client.ws.readyState === 1) {
          client.ws.send(payload);
          count++;
        }
      });
    });

    console.log(`📡 Broadcast to ${count} clients`);
  }

  // ============================================================
  // EMERGENCY EVENT STREAMING
  // ============================================================

  /**
   * Stream emergency created event
   */
  streamEmergencyCreated(emergency, nearbyOfficers) {
    this.broadcastByRole('police', {
      type: 'EMERGENCY_BROADCAST',
      data: {
        emergencyId: emergency._id,
        type: emergency.type,
        location: emergency.location,
        priority: emergency.priority,
        timestamp: new Date(),
        nearbyOfficersCount: nearbyOfficers,
      },
    });

    this.broadcastByRole('admin', {
      type: 'NEW_EMERGENCY_ALERT',
      data: {
        emergencyId: emergency._id,
        userId: emergency.userId,
        type: emergency.type,
        location: emergency.location,
        timestamp: new Date(),
      },
    });
  }

  /**
   * Stream case accepted event
   */
  streamCaseAccepted(emergency) {
    // Notify user
    this.sendToClient(emergency.userId.toString(), {
      type: 'CASE_ACCEPTED',
      data: {
        emergencyId: emergency._id,
        policeId: emergency.assignedPolice,
        policeETA: emergency.policeETA,
        timestamp: new Date(),
      },
    });

    // Notify admin
    this.broadcastByRole('admin', {
      type: 'CASE_ACCEPTED_ALERT',
      data: {
        emergencyId: emergency._id,
        policeId: emergency.assignedPolice,
        timestamp: new Date(),
      },
    });
  }

  /**
   * Stream location update (real-time tracking)
   */
  streamLocationUpdate(emergencyId, policeId, location) {
    const event = {
      type: 'LOCATION_UPDATE',
      data: {
        emergencyId,
        policeId,
        location,
        timestamp: new Date(),
      },
    };

    // Send to emergency creator
    // In real impl, get userId from emergency doc
    this.broadcastByRole('admin', event);
  }

  /**
   * Stream status update
   */
  streamStatusUpdate(emergency, newStatus) {
    const event = {
      type: 'STATUS_UPDATE',
      data: {
        emergencyId: emergency._id,
        status: newStatus,
        timestamp: new Date(),
        policeLocation: emergency.policeCurrentLocation,
      },
    };

    this.sendToClient(emergency.userId.toString(), event);
    this.broadcastByRole('admin', event);

    if (emergency.assignedHospital) {
      this.sendToClient(emergency.assignedHospital.toString(), event);
    }
  }

  /**
   * Stream resolution event
   */
  streamResolution(emergency) {
    const event = {
      type: 'EMERGENCY_RESOLVED',
      data: {
        emergencyId: emergency._id,
        resolutionTime: emergency.totalResolutionTime,
        timestamp: new Date(),
      },
    };

    this.sendToClient(emergency.userId.toString(), event);
    this.broadcastByRole('police', event);
    this.broadcastByRole('hospital', event);
    this.broadcastByRole('admin', event);
  }

  /**
   * Stream error/alert
   */
  streamAlert(title, message, severity = 'info') {
    this.broadcastAll({
      type: 'SYSTEM_ALERT',
      data: {
        title,
        message,
        severity, // 'info', 'warning', 'error', 'critical'
        timestamp: new Date(),
      },
    });
  }

  // ============================================================
  // EVENT QUEUEING (For offline clients)
  // ============================================================

  /**
   * Queue event for offline client
   */
  queueEvent(userId, event) {
    if (this.eventQueue.length >= this.MAX_QUEUE_SIZE) {
      console.warn('⚠️  Event queue full - dropping oldest event');
      this.eventQueue.shift();
    }

    this.eventQueue.push({
      userId,
      event,
      queuedAt: new Date(),
    });

    console.log(`📦 Event queued for offline user ${userId}`);
  }

  /**
   * Flush queued events when client reconnects
   */
  flushQueuedEvents(userId) {
    const userEvents = this.eventQueue.filter(e => e.userId === userId);

    userEvents.forEach(({ event }) => {
      this.sendToClient(userId, event);
    });

    // Remove from queue
    this.eventQueue = this.eventQueue.filter(e => e.userId !== userId);

    console.log(`📤 Flushed ${userEvents.length} events to ${userId}`);
  }

  // ============================================================
  // DASHBOARD UPDATES (For admin)
  // ============================================================

  /**
   * Stream dashboard stats
   */
  streamDashboardStats(stats) {
    this.broadcastByRole('admin', {
      type: 'DASHBOARD_UPDATE',
      data: {
        activeEmergencies: stats.activeEmergencies,
        totalResolved: stats.totalResolved,
        avgResponseTime: stats.avgResponseTime,
        systemHealth: stats.systemHealth,
        timestamp: new Date(),
      },
    });
  }

  /**
   * Stream heatmap data (high emergency areas)
   */
  streamHeatmapUpdate(heatmapData) {
    this.broadcastByRole('admin', {
      type: 'HEATMAP_UPDATE',
      data: {
        hotspots: heatmapData,
        timestamp: new Date(),
      },
    });
  }

  // ============================================================
  // MONITORING & METRICS
  // ============================================================

  /**
   * Get real-time metrics
   */
  getMetrics() {
    let totalClients = 0;
    let roleBreakdown = {};

    this.wsClients.forEach((clients) => {
      totalClients += clients.length;
      clients.forEach(client => {
        roleBreakdown[client.role] = (roleBreakdown[client.role] || 0) + 1;
      });
    });

    return {
      activeConnections: totalClients,
      uniqueUsers: this.wsClients.size,
      roleBreakdown,
      queuedEvents: this.eventQueue.length,
      timestamp: new Date(),
    };
  }

  /**
   * Stream metrics to admin dashboard
   */
  streamMetrics() {
    setInterval(() => {
      const metrics = this.getMetrics();
      this.broadcastByRole('admin', {
        type: 'SYSTEM_METRICS',
        data: metrics,
      });
    }, 5000); // Every 5 seconds
  }
}

// Singleton instance
let instance = null;

const getRealtimeService = () => {
  if (!instance) {
    instance = new RealtimeEventService();
  }
  return instance;
};

module.exports = {
  RealtimeEventService,
  getRealtimeService,
};
