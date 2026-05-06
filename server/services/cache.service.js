// In-Memory Caching Service with TTL support
// Simple but effective cache for frequently accessed data

const { getLogger } = require('./logger.service');

const logger = getLogger();

class CacheService {
  constructor() {
    this.cache = new Map(); // key -> {value, expiresAt}
    this.stats = {
      hits: 0,
      misses: 0,
      sets: 0,
      deletes: 0,
    };
  }

  /**
   * Set cache value with TTL
   * @param {string} key - Cache key
   * @param {any} value - Value to cache
   * @param {number} ttlSeconds - Time to live in seconds
   */
  set(key, value, ttlSeconds = 300) {
    const expiresAt = Date.now() + ttlSeconds * 1000;
    this.cache.set(key, { value, expiresAt });
    this.stats.sets++;

    logger.debug(`[Cache] SET ${key}`, {
      ttlSeconds,
      expiresAt: new Date(expiresAt).toISOString(),
    });
  }

  /**
   * Get cache value
   * @param {string} key - Cache key
   * @returns {any | null} Cached value or null if not found or expired
   */
  get(key) {
    const cached = this.cache.get(key);

    if (!cached) {
      this.stats.misses++;
      logger.debug(`[Cache] MISS ${key}`);
      return null;
    }

    // Check expiry
    if (cached.expiresAt < Date.now()) {
      this.cache.delete(key);
      this.stats.misses++;
      logger.debug(`[Cache] EXPIRED ${key}`);
      return null;
    }

    this.stats.hits++;
    logger.debug(`[Cache] HIT ${key}`);
    return cached.value;
  }

  /**
   * Check if key exists and not expired
   */
  has(key) {
    return this.get(key) !== null;
  }

  /**
   * Delete cache entry
   */
  delete(key) {
    const deleted = this.cache.delete(key);
    if (deleted) this.stats.deletes++;
    logger.debug(`[Cache] DELETE ${key}`);
    return deleted;
  }

  /**
   * Clear all cache
   */
  clear() {
    const size = this.cache.size;
    this.cache.clear();
    logger.info(`[Cache] Cleared ${size} entries`);
  }

  /**
   * Delete all keys matching pattern (regex)
   */
  deleteByPattern(pattern) {
    const regex = new RegExp(pattern);
    let deleted = 0;

    for (const [key] of this.cache) {
      if (regex.test(key)) {
        this.cache.delete(key);
        deleted++;
      }
    }

    this.stats.deletes += deleted;
    logger.debug(`[Cache] Deleted ${deleted} entries matching pattern: ${pattern}`);
    return deleted;
  }

  /**
   * Get or set (compute on miss)
   */
  async getOrCompute(key, computeFn, ttlSeconds = 300) {
    const cached = this.get(key);
    if (cached !== null) return cached;

    try {
      const value = await computeFn();
      this.set(key, value, ttlSeconds);
      return value;
    } catch (error) {
      logger.error('[Cache] Computation failed', error, { key });
      return null;
    }
  }

  /**
   * Get cache statistics
   */
  getStats() {
    const total = this.stats.hits + this.stats.misses;
    const hitRate = total > 0 ? ((this.stats.hits / total) * 100).toFixed(1) : 0;

    return {
      ...this.stats,
      totalRequests: total,
      hitRate: `${hitRate}%`,
      cacheSize: this.cache.size,
    };
  }

  /**
   * Clean up expired entries
   */
  cleanup() {
    const now = Date.now();
    let deleted = 0;

    for (const [key, entry] of this.cache) {
      if (entry.expiresAt < now) {
        this.cache.delete(key);
        deleted++;
      }
    }

    this.stats.deletes += deleted;

    if (deleted > 0) {
      logger.info(`[Cache] Cleanup: removed ${deleted} expired entries`);
    }

    return deleted;
  }

  /**
   * Start periodic cleanup
   */
  startPeriodicCleanup(intervalSeconds = 300) {
    setInterval(() => {
      this.cleanup();
    }, intervalSeconds * 1000);

    logger.info(`[Cache] Started periodic cleanup (every ${intervalSeconds}s)`);
  }
}

// Singleton instance
let cacheInstance = null;

const getCache = () => {
  if (!cacheInstance) {
    cacheInstance = new CacheService();
    // Start cleanup every 5 minutes
    cacheInstance.startPeriodicCleanup(300);
  }
  return cacheInstance;
};

// Cache key generators
const cacheKeys = {
  hospital(hospitalId) {
    return `hospital:${hospitalId}`;
  },

  hospitalsByLocation(lat, lon, radius) {
    return `hospitals:nearby:${lat}:${lon}:${radius}`;
  },

  userProfile(userId) {
    return `user:profile:${userId}`;
  },

  emergencyStats() {
    return `stats:emergency`;
  },

  policeStats(stationName) {
    return `stats:police:${stationName}`;
  },

  hospitalStats(hospitalId) {
    return `stats:hospital:${hospitalId}`;
  },

  ambulanceStatus(ambulanceId) {
    return `ambulance:status:${ambulanceId}`;
  },

  onlineAmbulances() {
    return `ambulances:online`;
  },

  caseDetails(caseId) {
    return `case:${caseId}`;
  },

  allPoliceOfficers() {
    return `police:all`;
  },

  allHospitals() {
    return `hospitals:all`;
  },
};

module.exports = {
  getCache,
  CacheService,
  cacheKeys,
};
