// Backend Health Monitor & System Status Service
const axios = require('axios');

class HealthMonitorService {
  constructor(config = {}) {
    this.services = {
      backend: {
        url: 'http://localhost:5000/health',
        status: 'unknown',
        lastCheck: null,
        responseTime: 0,
        errors: 0,
      },
      ai_engine: {
        url: config.aiEngineUrl || 'http://localhost:8000/health',
        status: 'unknown',
        lastCheck: null,
        responseTime: 0,
        errors: 0,
      },
      database: {
        status: 'unknown',
        lastCheck: null,
        responseTime: 0,
        errors: 0,
        connection: null,
      },
    };

    this.alerts = [];
    this.healthCheckInterval = config.checkInterval || 30000; // 30 seconds
    this.fallbackMode = false;
    this.maxConsecutiveErrors = config.maxErrors || 3;

    this.startHealthChecks();
  }

  /**
   * Start periodic health checks
   */
  startHealthChecks() {
    setInterval(async () => {
      await this.checkAllServices();
    }, this.healthCheckInterval);

    // Initial check
    this.checkAllServices();
  }

  /**
   * Check all services
   */
  async checkAllServices() {
    const results = await Promise.allSettled([
      this.checkBackend(),
      this.checkAIEngine(),
      this.checkDatabase(),
    ]);

    // Determine if fallback mode should be activated
    const healthyServices = Object.values(this.services).filter(
      (s) => s.status === 'healthy'
    ).length;

    if (healthyServices < 2) {
      this.activateFallbackMode();
    } else {
      this.deactivateFallbackMode();
    }
  }

  /**
   * Check backend health
   */
  async checkBackend() {
    try {
      const startTime = Date.now();
      const response = await axios.get(this.services.backend.url, {
        timeout: 5000,
      });

      const responseTime = Date.now() - startTime;

      if (response.status === 200) {
        this.services.backend.status = 'healthy';
        this.services.backend.responseTime = responseTime;
        this.services.backend.errors = 0;
        this.services.backend.lastCheck = Date.now();
      } else {
        this.recordServiceError('backend');
      }
    } catch (error) {
      this.recordServiceError('backend', error);
    }
  }

  /**
   * Check AI engine health
   */
  async checkAIEngine() {
    try {
      const startTime = Date.now();
      const response = await axios.get(this.services.ai_engine.url, {
        timeout: 5000,
      });

      const responseTime = Date.now() - startTime;

      if (response.status === 200) {
        this.services.ai_engine.status = 'healthy';
        this.services.ai_engine.responseTime = responseTime;
        this.services.ai_engine.errors = 0;
        this.services.ai_engine.lastCheck = Date.now();
      } else {
        this.recordServiceError('ai_engine');
      }
    } catch (error) {
      this.recordServiceError('ai_engine', error);
    }
  }

  /**
   * Check database health
   */
  async checkDatabase() {
    try {
      // Attempt a simple query
      const startTime = Date.now();

      // This would be called on the DB connection object in real implementation
      // For now, assuming DB connection check
      if (this.services.database.connection) {
        const responseTime = Date.now() - startTime;
        this.services.database.status = 'healthy';
        this.services.database.responseTime = responseTime;
        this.services.database.errors = 0;
        this.services.database.lastCheck = Date.now();
      }
    } catch (error) {
      this.recordServiceError('database', error);
    }
  }

  /**
   * Record service error
   */
  recordServiceError(serviceName, error = null) {
    const service = this.services[serviceName];
    service.errors++;
    service.lastCheck = Date.now();

    if (service.errors >= this.maxConsecutiveErrors) {
      service.status = 'unhealthy';

      this.alerts.push({
        severity: 'critical',
        service: serviceName,
        message: `${serviceName} has been unhealthy for ${service.errors} checks`,
        timestamp: Date.now(),
        error: error?.message || 'Unknown error',
      });

      console.error(`⚠️ Service degradation: ${serviceName} is unhealthy`);
    } else {
      service.status = 'degraded';
    }
  }

  /**
   * Activate fallback mode
   */
  activateFallbackMode() {
    if (!this.fallbackMode) {
      this.fallbackMode = true;
      console.warn('🚨 FALLBACK MODE ACTIVATED - Limited functionality enabled');

      this.alerts.push({
        severity: 'critical',
        service: 'system',
        message: 'System entered fallback mode due to service failures',
        timestamp: Date.now(),
      });
    }
  }

  /**
   * Deactivate fallback mode
   */
  deactivateFallbackMode() {
    if (this.fallbackMode) {
      this.fallbackMode = false;
      console.log('✅ FALLBACK MODE DEACTIVATED - All services recovered');
    }
  }

  /**
   * Get system health status
   */
  getSystemStatus() {
    const serviceStatuses = {};
    let overallStatus = 'healthy';

    Object.entries(this.services).forEach(([name, service]) => {
      serviceStatuses[name] = {
        status: service.status,
        responseTime: service.responseTime,
        lastCheck: service.lastCheck,
        errors: service.errors,
      };

      if (service.status === 'unhealthy') {
        overallStatus = 'unhealthy';
      } else if (service.status === 'degraded' && overallStatus === 'healthy') {
        overallStatus = 'degraded';
      }
    });

    return {
      overallStatus,
      fallbackMode: this.fallbackMode,
      services: serviceStatuses,
      alerts: this.alerts.slice(-10), // Last 10 alerts
      timestamp: Date.now(),
    };
  }

  /**
   * Get recent alerts
   */
  getAlerts(limit = 20) {
    return this.alerts.slice(-limit);
  }

  /**
   * Clear old alerts
   */
  clearOldAlerts(olderThan = 3600000) {
    const cutoff = Date.now() - olderThan;
    this.alerts = this.alerts.filter((a) => a.timestamp > cutoff);
  }

  /**
   * Get service-specific status
   */
  getServiceStatus(serviceName) {
    const service = this.services[serviceName];
    if (!service) {
      return { error: 'Service not found' };
    }

    return {
      name: serviceName,
      ...service,
      uptime: service.status === 'healthy' ? '100%' : 'degraded',
    };
  }
}

module.exports = HealthMonitorService;
