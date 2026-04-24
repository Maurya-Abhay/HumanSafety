// Backend Event Stream Service - Real-Time Processing
const EventEmitter = require('events');

class EventStreamService extends EventEmitter {
  constructor() {
    super();
    this.subscribers = new Map(); // Map<channel, Set<callbacks>>
    this.eventHistory = []; // Store recent events for replay
    this.maxHistorySize = 1000;
    this.eventStats = {
      totalEvents: 0,
      byType: {},
    };
  }

  /**
   * Subscribe to event stream channel
   */
  subscribe(channel, callback) {
    if (!this.subscribers.has(channel)) {
      this.subscribers.set(channel, new Set());
    }

    this.subscribers.get(channel).add(callback);

    // Return unsubscribe function
    return () => {
      const subscribers = this.subscribers.get(channel);
      if (subscribers) {
        subscribers.delete(callback);
      }
    };
  }

  /**
   * Publish event to subscribers
   */
  publish(channel, data) {
    const subscribers = this.subscribers.get(channel);

    const event = {
      channel,
      data,
      timestamp: Date.now(),
      id: `EVT-${Date.now()}-${Math.random().toString(36).substr(2, 9)}`,
    };

    // Store in history
    this.eventHistory.push(event);
    if (this.eventHistory.length > this.maxHistorySize) {
      this.eventHistory.shift();
    }

    // Update stats
    this.eventStats.totalEvents++;
    this.eventStats.byType[channel] = (this.eventStats.byType[channel] || 0) + 1;

    // Notify subscribers
    if (subscribers && subscribers.size > 0) {
      subscribers.forEach((callback) => {
        try {
          callback(event);
        } catch (error) {
          console.error(`Error in subscriber callback: ${error.message}`);
        }
      });
    }

    this.emit('published', event);
    return event;
  }

  /**
   * Get event replay from history
   */
  getEventHistory(channel, limit = 50) {
    let history = this.eventHistory;

    if (channel) {
      history = history.filter((e) => e.channel === channel);
    }

    return history.slice(-limit);
  }

  /**
   * Emergency-specific event channels
   */
  publishEmergencyCreated(emergency) {
    return this.publish('emergency:created', {
      emergencyId: emergency.id,
      type: emergency.type,
      location: emergency.location,
      riskLevel: emergency.riskLevel,
      timestamp: Date.now(),
    });
  }

  publishEmergencyAssigned(emergency, assignee) {
    return this.publish(`emergency:${emergency.id}:assigned`, {
      emergencyId: emergency.id,
      assigneeId: assignee.id,
      assigneeRole: assignee.role,
      timestamp: Date.now(),
    });
  }

  publishEmergencyStatusUpdate(emergency, newStatus) {
    return this.publish(`emergency:${emergency.id}:status`, {
      emergencyId: emergency.id,
      oldStatus: emergency.status,
      newStatus: newStatus,
      timestamp: Date.now(),
    });
  }

  publishLocationUpdate(userId, location) {
    return this.publish(`location:${userId}:updated`, {
      userId,
      latitude: location.latitude,
      longitude: location.longitude,
      accuracy: location.accuracy,
      timestamp: Date.now(),
    });
  }

  publishAlertCritical(alert) {
    return this.publish('alert:critical', {
      alertId: alert.id,
      message: alert.message,
      severity: 'critical',
      timestamp: Date.now(),
    });
  }

  /**
   * Get stats
   */
  getStats() {
    return {
      totalEvents: this.eventStats.totalEvents,
      activeChannels: this.subscribers.size,
      totalSubscribers: Array.from(this.subscribers.values()).reduce(
        (sum, set) => sum + set.size,
        0
      ),
      eventsByType: this.eventStats.byType,
      historySize: this.eventHistory.length,
    };
  }

  /**
   * Clear channel subscribers
   */
  clearChannel(channel) {
    this.subscribers.delete(channel);
  }

  /**
   * Get all active channels
   */
  getActiveChannels() {
    return Array.from(this.subscribers.keys());
  }
}

module.exports = EventStreamService;
