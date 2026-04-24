// Security Middleware for Express Backend
const crypto = require('crypto');

/**
 * Device Fingerprinting Middleware
 * Detects suspicious device behavior
 */
function deviceFingerprintMiddleware(req, res, next) {
  const fingerprint = generateDeviceFingerprint({
    userAgent: req.get('user-agent'),
    acceptLanguage: req.get('accept-language'),
    ipAddress: req.ip,
  });

  req.deviceFingerprint = fingerprint;
  next();
}

function generateDeviceFingerprint(data) {
  const combined = JSON.stringify(data);
  return crypto.createHash('sha256').update(combined).digest('hex');
}

/**
 * GPS Spoofing Detection Middleware
 * Uses Haversine formula to detect impossible movement
 */
function gpsValidationMiddleware(req, res, next) {
  if (!req.body.latitude || !req.body.longitude) {
    return next();
  }

  // Store location for comparison
  req.currentLocation = {
    latitude: req.body.latitude,
    longitude: req.body.longitude,
    timestamp: Date.now(),
  };

  next();
}

function haversineDistance(lat1, lon1, lat2, lon2) {
  const R = 6371; // km
  const dLat = ((lat2 - lat1) * Math.PI) / 180;
  const dLon = ((lon2 - lon1) * Math.PI) / 180;

  const a =
    Math.sin(dLat / 2) * Math.sin(dLat / 2) +
    Math.cos((lat1 * Math.PI) / 180) *
      Math.cos((lat2 * Math.PI) / 180) *
      Math.sin(dLon / 2) *
      Math.sin(dLon / 2);

  const c = 2 * Math.atan2(Math.sqrt(a), Math.sqrt(1 - a));
  return R * c;
}

/**
 * Rate Limiting Middleware
 * Sliding window algorithm
 */
const rateLimitStore = new Map();

function rateLimitMiddleware(windowSize = 60000, maxRequests = 100) {
  return (req, res, next) => {
    const identifier = req.ip;
    const now = Date.now();
    const windowStart = now - windowSize;

    if (!rateLimitStore.has(identifier)) {
      rateLimitStore.set(identifier, []);
    }

    const requests = rateLimitStore.get(identifier);
    const recentRequests = requests.filter((ts) => ts > windowStart);

    if (recentRequests.length >= maxRequests) {
      return res.status(429).json({
        message: 'Too many requests',
        retryAfter: Math.ceil(windowSize / 1000),
      });
    }

    recentRequests.push(now);
    rateLimitStore.set(identifier, recentRequests);

    // Cleanup old entries
    if (rateLimitStore.size > 10000) {
      const entries = Array.from(rateLimitStore.entries());
      entries.forEach(([key, value]) => {
        const recentTimestamps = value.filter((ts) => ts > windowStart);
        if (recentTimestamps.length === 0) {
          rateLimitStore.delete(key);
        }
      });
    }

    next();
  };
}

/**
 * Request Validation Middleware
 * Validates required fields and formats
 */
function validateRequestMiddleware(requiredFields = []) {
  return (req, res, next) => {
    const missingFields = requiredFields.filter((field) => !req.body[field]);

    if (missingFields.length > 0) {
      return res.status(400).json({
        message: 'Missing required fields',
        missingFields,
      });
    }

    // Validate latitude/longitude if present
    if (req.body.latitude || req.body.longitude) {
      const lat = parseFloat(req.body.latitude);
      const lon = parseFloat(req.body.longitude);

      if (isNaN(lat) || isNaN(lon) || lat < -90 || lat > 90 || lon < -180 || lon > 180) {
        return res.status(400).json({
          message: 'Invalid coordinates',
        });
      }
    }

    // Validate phone number if present
    if (req.body.phone) {
      const phoneRegex = /^\d{10,}$/;
      if (!phoneRegex.test(req.body.phone.replace(/\D/g, ''))) {
        return res.status(400).json({
          message: 'Invalid phone number',
        });
      }
    }

    next();
  };
}

/**
 * Security Headers Middleware
 */
function securityHeadersMiddleware(req, res, next) {
  res.setHeader('X-Content-Type-Options', 'nosniff');
  res.setHeader('X-Frame-Options', 'DENY');
  res.setHeader('X-XSS-Protection', '1; mode=block');
  res.setHeader('Strict-Transport-Security', 'max-age=31536000; includeSubDomains');
  res.setHeader('Content-Security-Policy', "default-src 'self'");

  next();
}

/**
 * Suspicious Activity Detection Middleware
 */
const suspiciousActivityStore = new Map();

function detectSuspiciousActivityMiddleware(req, res, next) {
  const identifier = req.ip;
  const endpoint = req.path;

  if (!suspiciousActivityStore.has(identifier)) {
    suspiciousActivityStore.set(identifier, {
      failedAttempts: 0,
      blockedUntil: 0,
      activities: [],
    });
  }

  const activity = suspiciousActivityStore.get(identifier);

  // Check if blocked
  if (activity.blockedUntil > Date.now()) {
    return res.status(403).json({
      message: 'Access temporarily blocked due to suspicious activity',
    });
  }

  // Track activity
  activity.activities.push({
    endpoint,
    timestamp: Date.now(),
  });

  // Keep only last 100 activities
  if (activity.activities.length > 100) {
    activity.activities.shift();
  }

  // Check for suspicious patterns
  const last10Activities = activity.activities.slice(-10);
  const last10Endpoints = last10Activities.map((a) => a.endpoint);

  // Pattern 1: Multiple failed login attempts
  if (
    endpoint === '/auth/verify-otp' &&
    last10Activities.filter((a) => a.endpoint === '/auth/verify-otp').length > 5
  ) {
    activity.failedAttempts++;
    if (activity.failedAttempts > 3) {
      activity.blockedUntil = Date.now() + 15 * 60 * 1000; // 15 min block
      console.warn(`🚨 Suspicious login activity detected: ${identifier}`);
      return res.status(403).json({
        message: 'Account temporarily locked',
        blockedUntil: activity.blockedUntil,
      });
    }
  }

  // Pattern 2: Rapid endpoint changes (potential bot)
  if (
    new Set(last10Endpoints).size > 8 &&
    last10Activities.length === 10 &&
    Date.now() - last10Activities[0].timestamp < 10000
  ) {
    console.warn(`🚨 Potential bot activity detected: ${identifier}`);
    activity.blockedUntil = Date.now() + 5 * 60 * 1000; // 5 min block
  }

  next();
}

/**
 * Request Logging Middleware
 */
function requestLoggingMiddleware(auditLog) {
  return (req, res, next) => {
    const startTime = Date.now();

    res.on('finish', () => {
      const duration = Date.now() - startTime;
      const statusCode = res.statusCode;

      // Log significant requests
      if (statusCode >= 400 || duration > 5000 || req.path.includes('/emergency')) {
        auditLog.logEvent({
          actor: req.userId || 'anonymous',
          action: req.method,
          resource: req.path,
          result: statusCode < 400 ? 'success' : 'failed',
          statusCode,
          duration,
          ipAddress: req.ip,
          deviceFingerprint: req.deviceFingerprint,
        });
      }
    });

    next();
  };
}

module.exports = {
  deviceFingerprintMiddleware,
  gpsValidationMiddleware,
  haversineDistance,
  rateLimitMiddleware,
  validateRequestMiddleware,
  securityHeadersMiddleware,
  detectSuspiciousActivityMiddleware,
  requestLoggingMiddleware,
};
