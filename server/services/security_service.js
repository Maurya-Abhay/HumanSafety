// Backend Rate Limiter & Abuse Detection Service
const crypto = require('crypto');

class RateLimiterService {
  constructor(options = {}) {
    this.windowSize = options.windowSize || 60000; // 1 minute
    this.maxRequests = options.maxRequests || 100;
    this.requestBuckets = new Map(); // Map<identifier, { count, resetAt }>
    this.suspiciousActivity = new Map();
    this.blockedUsers = new Set();
  }

  /**
   * Check if request is allowed
   */
  isAllowed(identifier, customLimit = null) {
    const limit = customLimit || this.maxRequests;

    if (this.blockedUsers.has(identifier)) {
      return {
        allowed: false,
        reason: 'User blocked due to suspicious activity',
        blocked: true,
      };
    }

    const now = Date.now();
    let bucket = this.requestBuckets.get(identifier);

    if (!bucket || now > bucket.resetAt) {
      // New window
      bucket = {
        count: 1,
        resetAt: now + this.windowSize,
      };
      this.requestBuckets.set(identifier, bucket);
      return { allowed: true, remaining: limit - 1 };
    }

    bucket.count++;

    if (bucket.count > limit) {
      // Rate limit exceeded
      this.recordSuspiciousActivity(identifier, 'rate_limit_exceeded', {
        count: bucket.count,
        limit,
      });

      return {
        allowed: false,
        reason: 'Rate limit exceeded',
        retryAfter: Math.ceil((bucket.resetAt - now) / 1000),
      };
    }

    return { allowed: true, remaining: limit - bucket.count };
  }

  /**
   * Record suspicious activity
   */
  recordSuspiciousActivity(identifier, reason, details = {}) {
    if (!this.suspiciousActivity.has(identifier)) {
      this.suspiciousActivity.set(identifier, []);
    }

    const activities = this.suspiciousActivity.get(identifier);
    activities.push({
      reason,
      details,
      timestamp: Date.now(),
    });

    // Keep last 100 activities per user
    if (activities.length > 100) {
      activities.shift();
    }

    // Block if too many suspicious activities
    const recentCount = activities.filter(
      (a) => Date.now() - a.timestamp < 300000 // 5 minutes
    ).length;

    if (recentCount >= 5) {
      this.blockUser(identifier, 'Too much suspicious activity');
    }
  }

  /**
   * Block user
   */
  blockUser(identifier, reason = '') {
    this.blockedUsers.add(identifier);
    console.log(`User blocked: ${identifier} - ${reason}`);
  }

  /**
   * Unblock user
   */
  unblockUser(identifier) {
    this.blockedUsers.delete(identifier);
  }

  /**
   * Get suspicious activity report
   */
  getSuspiciousActivityReport(identifier) {
    return this.suspiciousActivity.get(identifier) || [];
  }

  /**
   * Get blocked users
   */
  getBlockedUsers() {
    return Array.from(this.blockedUsers);
  }

  /**
   * Reset rate limit for user (admin function)
   */
  resetUser(identifier) {
    this.requestBuckets.delete(identifier);
    this.suspiciousActivity.delete(identifier);
    this.unblockUser(identifier);
  }
}

/**
 * Security Service - Device Fingerprinting & Fake GPS Detection
 */
class SecurityService {
  constructor() {
    this.deviceFingerprints = new Map();
    this.suspiciousGPS = new Map();
    this.geoBlocklist = []; // Blocked regions/coordinates
  }

  /**
   * Generate device fingerprint
   */
  generateFingerprint(userAgent, acceptLanguage, ipAddress) {
    const fingerprintData = `${userAgent}|${acceptLanguage}|${ipAddress}`;
    return crypto.createHash('sha256').update(fingerprintData).digest('hex');
  }

  /**
   * Validate device fingerprint
   */
  validateDevice(userId, fingerprint, userAgent, acceptLanguage, ipAddress) {
    const expectedFingerprint = this.generateFingerprint(
      userAgent,
      acceptLanguage,
      ipAddress
    );

    if (fingerprint !== expectedFingerprint) {
      return {
        valid: false,
        reason: 'Device fingerprint mismatch',
        severity: 'high',
      };
    }

    return { valid: true };
  }

  /**
   * Detect fake GPS using movement analysis
   */
  detectFakeGPS(userId, previousLocation, currentLocation, timeDelta) {
    if (!previousLocation) {
      return { isFake: false };
    }

    // Calculate distance using Haversine formula
    const distance = this.haversineDistance(previousLocation, currentLocation);
    const maxSpeed = 300; // km/h max realistic speed
    const timeSeconds = timeDelta / 1000;
    const maxDistance = (maxSpeed * timeSeconds) / 3600; // km

    if (distance > maxDistance) {
      // Impossible movement
      this.recordSuspiciousGPS(userId, {
        distance,
        maxDistance,
        timeDelta,
        previousLocation,
        currentLocation,
      });

      return {
        isFake: true,
        reason: 'Impossible movement speed detected',
        distance,
        maxDistance,
        severity: 'critical',
      };
    }

    // Check for teleportation (>50km in <1 second)
    if (distance > 50 && timeSeconds < 1) {
      this.recordSuspiciousGPS(userId, {
        distance,
        timeDelta,
        reason: 'Teleportation detected',
      });

      return {
        isFake: true,
        reason: 'Teleportation detected',
        distance,
        severity: 'critical',
      };
    }

    // Check for zigzagging pattern
    return { isFake: false };
  }

  /**
   * Haversine formula for GPS distance
   */
  haversineDistance(loc1, loc2) {
    const R = 6371; // Earth radius in km
    const dLat = this.toRad(loc2.latitude - loc1.latitude);
    const dLon = this.toRad(loc2.longitude - loc1.longitude);
    const a =
      Math.sin(dLat / 2) * Math.sin(dLat / 2) +
      Math.cos(this.toRad(loc1.latitude)) *
        Math.cos(this.toRad(loc2.latitude)) *
        Math.sin(dLon / 2) *
        Math.sin(dLon / 2);
    const c = 2 * Math.atan2(Math.sqrt(a), Math.sqrt(1 - a));
    return R * c;
  }

  toRad(degrees) {
    return (degrees * Math.PI) / 180;
  }

  /**
   * Record suspicious GPS
   */
  recordSuspiciousGPS(userId, details) {
    if (!this.suspiciousGPS.has(userId)) {
      this.suspiciousGPS.set(userId, []);
    }

    this.suspiciousGPS.get(userId).push({
      ...details,
      timestamp: Date.now(),
    });
  }

  /**
   * Get suspicious GPS report
   */
  getSuspiciousGPSReport(userId) {
    return this.suspiciousGPS.get(userId) || [];
  }

  /**
   * Detect suspicious behavior patterns
   */
  detectSuspiciousBehavior(userId, action, context = {}) {
    const suspiciousSigns = [];

    // Multiple panic button presses in short time
    if (action === 'panic' && context.previousPanicTime) {
      const timeDelta = Date.now() - context.previousPanicTime;
      if (timeDelta < 60000) {
        // < 1 minute
        suspiciousSigns.push({
          sign: 'rapid_panic_presses',
          severity: 'medium',
        });
      }
    }

    // Accessing from multiple IPs simultaneously
    if (context.simultaneousIPs && context.simultaneousIPs.length > 2) {
      suspiciousSigns.push({
        sign: 'multiple_simultaneous_ips',
        severity: 'high',
      });
    }

    // Accessing from blocked regions
    if (
      context.location &&
      this.isLocationBlocked(context.location.longitude, context.location.latitude)
    ) {
      suspiciousSigns.push({
        sign: 'blocked_region_access',
        severity: 'critical',
      });
    }

    return {
      isSuspicious: suspiciousSigns.length > 0,
      signs: suspiciousSigns,
      riskScore: suspiciousSigns.reduce((sum, s) => {
        const scores = { low: 10, medium: 30, high: 60, critical: 100 };
        return sum + (scores[s.severity] || 0);
      }, 0),
    };
  }

  /**
   * Check if location is blocked
   */
  isLocationBlocked(longitude, latitude) {
    // Implement geo-blocking if needed
    return this.geoBlocklist.some(
      (blocked) =>
        Math.abs(blocked.longitude - longitude) < 0.1 &&
        Math.abs(blocked.latitude - latitude) < 0.1
    );
  }

  /**
   * Add location to blocklist
   */
  blockLocation(longitude, latitude, reason = '') {
    this.geoBlocklist.push({ longitude, latitude, reason, timestamp: Date.now() });
  }
}

module.exports = {
  RateLimiterService,
  SecurityService,
};
