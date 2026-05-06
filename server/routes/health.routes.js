const express = require('express');
const router = express.Router();
const mongoose = require('mongoose');
const { getCache } = require('../services/cache.service');
const { getAmbulanceOnlineService } = require('../services/ambulance_online.service');
const { getRealtimeService } = require('../services/realtime_event_service');

/**
 * GET /health
 * Basic health check - server is running
 */
router.get('/', (req, res) => {
  try {
    return res.apiSuccess(
      {
        status: 'ok',
        service: 'HumanSafety Backend v3',
        timestamp: new Date().toISOString(),
        uptime: process.uptime(),
      },
      'Server is healthy',
      200
    );
  } catch (error) {
    return res.apiError('Health check failed', error, 500, 'HEALTH_CHECK_FAILED');
  }
});

/**
 * GET /health/db
 * Check database connectivity and basic stats
 */
router.get('/db', async (req, res) => {
  try {
    const mongoState = mongoose.connection.readyState;
    const states = {
      0: 'disconnected',
      1: 'connected',
      2: 'connecting',
      3: 'disconnecting'
    };

    if (mongoState !== 1) {
      return res.apiError('Database disconnected', null, 503, 'DB_DISCONNECTED');
    }

    // Get basic stats
    const db = mongoose.connection.db;
    const adminDb = db.admin();
    const stats = await adminDb.serverStatus();

    return res.apiSuccess(
      {
        status: states[mongoState],
        connected: mongoState === 1,
        database: mongoose.connection.name,
        host: mongoose.connection.host,
        port: mongoose.connection.port,
        uptime: stats.uptime,
        connections: stats.connections,
        memory: stats.mem
      },
      'Database is healthy',
      200
    );
  } catch (error) {
    return res.apiError('Database health check failed', error, 503, 'DB_HEALTH_CHECK_FAILED');
  }
});

/**
 * GET /health/cache
 * Check cache service and statistics
 */
router.get('/cache', (req, res) => {
  try {
    const cache = getCache();
    const stats = cache.getStats();

    return res.apiSuccess(
      {
        status: 'ok',
        totalKeys: stats.totalKeys,
        hits: stats.hits,
        misses: stats.misses,
        hitRate: (stats.hitRate * 100).toFixed(2) + '%',
        expiredKeys: stats.expiredKeys,
        lastCleanup: stats.lastCleanup
      },
      'Cache is healthy',
      200
    );
  } catch (error) {
    return res.apiError('Cache health check failed', error, 500, 'CACHE_HEALTH_CHECK_FAILED');
  }
});

/**
 * GET /health/websocket
 * Check WebSocket connection stats and active clients
 */
router.get('/websocket', (req, res) => {
  try {
    const realtimeService = getRealtimeService();
    const stats = realtimeService.getConnectionStats();

    return res.apiSuccess(
      {
        status: 'ok',
        totalConnections: stats.totalConnections || 0,
        uniqueUsers: stats.uniqueUsers || 0,
        totalRooms: stats.totalRooms || 0,
        queuedEvents: stats.queuedEvents || 0,
        eventHistorySize: stats.eventHistorySize || 0
      },
      'WebSocket service is healthy',
      200
    );
  } catch (error) {
    return res.apiError('WebSocket health check failed', error, 500, 'WS_HEALTH_CHECK_FAILED');
  }
});

/**
 * GET /health/ambulances
 * Check ambulance online service and ambulance stats
 */
router.get('/ambulances', async (req, res) => {
  try {
    const ambulanceService = getAmbulanceOnlineService();
    const stats = ambulanceService.getStats();

    return res.apiSuccess(
      {
        status: 'ok',
        totalAmbulances: stats.totalAmbulances,
        onlineAmbulances: stats.onlineAmbulances,
        offlineAmbulances: stats.offlineAmbulances,
        lastHeartbeat: stats.lastHeartbeat,
        heartbeatTimeout: stats.heartbeatTimeout + ' ms'
      },
      'Ambulance service is healthy',
      200
    );
  } catch (error) {
    return res.apiError('Ambulance health check failed', error, 500, 'AMBULANCE_HEALTH_CHECK_FAILED');
  }
});

/**
 * GET /health/services
 * Comprehensive service status check
 */
router.get('/services', async (req, res) => {
  try {
    const mongoState = mongoose.connection.readyState;
    const cache = getCache();
    const realtimeService = getRealtimeService();
    const stats = realtimeService.getConnectionStats();
    const ambulanceService = getAmbulanceOnlineService();

    const healthStatus = {
      database: mongoState === 1 ? 'healthy' : 'unhealthy',
      cache: cache ? 'healthy' : 'unhealthy',
      websocket: (stats.totalConnections || 0) > 0 ? 'healthy' : 'dormant',
      ambulanceTracking: ambulanceService ? 'healthy' : 'unhealthy',
      server: 'healthy'
    };

    const allHealthy = Object.values(healthStatus).every(s => s !== 'unhealthy');

    return res.apiSuccess(
      {
        timestamp: new Date().toISOString(),
        uptime: process.uptime(),
        memory: {
          heapUsed: Math.round(process.memoryUsage().heapUsed / 1024 / 1024) + ' MB',
          heapTotal: Math.round(process.memoryUsage().heapTotal / 1024 / 1024) + ' MB',
          external: Math.round(process.memoryUsage().external / 1024 / 1024) + ' MB'
        },
        services: healthStatus,
        overallStatus: allHealthy ? 'healthy' : 'degraded'
      },
      allHealthy ? 'All services are healthy' : 'Some services may be degraded',
      allHealthy ? 200 : 503
    );
  } catch (error) {
    return res.apiError('Services health check failed', error, 503, 'SERVICES_HEALTH_CHECK_FAILED');
  }
});

/**
 * GET /health/ready
 * Readiness probe for Kubernetes/Docker orchestration
 * Returns 200 only if app is ready to accept traffic
 */
router.get('/ready', async (req, res) => {
  try {
    const mongoState = mongoose.connection.readyState;

    // App is ready if: DB connected AND server running
    if (mongoState === 1) {
      return res.apiSuccess(
        { ready: true },
        'Application is ready',
        200
      );
    } else {
      return res.apiError('Application not ready', null, 503, 'APP_NOT_READY');
    }
  } catch (error) {
    return res.apiError('Readiness check failed', error, 503, 'READINESS_CHECK_FAILED');
  }
});

/**
 * GET /health/alive
 * Liveness probe for Kubernetes/Docker orchestration
 * Returns 200 if process is alive (no crash)
 */
router.get('/alive', (req, res) => {
  try {
    return res.apiSuccess(
      { alive: true },
      'Process is alive',
      200
    );
  } catch (error) {
    return res.apiError('Liveness check failed', error, 503, 'LIVENESS_CHECK_FAILED');
  }
});

module.exports = router;
