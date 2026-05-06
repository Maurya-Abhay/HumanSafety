// Comprehensive logging service for all server events
const fs = require('fs');
const path = require('path');

class Logger {
  constructor() {
    this.logsDir = path.join(__dirname, '..', 'logs');
    this.ensureLogsDir();
    
    // Log levels: DEBUG, INFO, WARN, ERROR, CRITICAL
    this.levels = {
      DEBUG: { value: 0, color: '\x1b[36m' },    // Cyan
      INFO: { value: 1, color: '\x1b[32m' },     // Green
      WARN: { value: 2, color: '\x1b[33m' },     // Yellow
      ERROR: { value: 3, color: '\x1b[31m' },    // Red
      CRITICAL: { value: 4, color: '\x1b[35m' }, // Magenta
    };

    const logLevel = (process.env.LOG_LEVEL || 'INFO').toUpperCase();
    this.currentLevel = this.levels[logLevel] ? this.levels[logLevel].value : 1;
  }

  ensureLogsDir() {
    if (!fs.existsSync(this.logsDir)) {
      fs.mkdirSync(this.logsDir, { recursive: true });
    }
  }

  getTimestamp() {
    return new Date().toISOString();
  }

  formatLog(level, message, data = null) {
    const timestamp = this.getTimestamp();
    const color = this.levels[level].color;
    const reset = '\x1b[0m';

    let logMessage = `${color}[${timestamp}] [${level}]${reset} ${message}`;
    if (data) {
      logMessage += ` ${JSON.stringify(data, null, 2)}`;
    }

    return logMessage;
  }

  writeToFile(level, message, data = null) {
    const fileName = `${level.toLowerCase()}-${new Date().toISOString().split('T')[0]}.log`;
    const filePath = path.join(this.logsDir, fileName);

    const entry = {
      timestamp: this.getTimestamp(),
      level,
      message,
      data: data || null,
    };

    fs.appendFileSync(filePath, JSON.stringify(entry) + '\n');
  }

  log(level, message, data = null) {
    if (this.levels[level].value < this.currentLevel) return;

    const formattedLog = this.formatLog(level, message, data);
    console.log(formattedLog);

    // Only write ERROR and CRITICAL to file to save space
    if (level === 'ERROR' || level === 'CRITICAL') {
      this.writeToFile(level, message, data);
    }
  }

  debug(message, data = null) {
    this.log('DEBUG', message, data);
  }

  info(message, data = null) {
    this.log('INFO', message, data);
  }

  warn(message, data = null) {
    this.log('WARN', message, data);
  }

  error(message, error = null, data = null) {
    const errorDetails = {
      message: error?.message || error,
      stack: error?.stack,
      ...data,
    };
    this.log('ERROR', message, errorDetails);
  }

  critical(message, error = null, data = null) {
    const errorDetails = {
      message: error?.message || error,
      stack: error?.stack,
      ...data,
    };
    this.log('CRITICAL', message, errorDetails);
  }

  // Request/Response logging
  logRequest(req) {
    this.debug(`${req.method} ${req.path}`, {
      ip: req.ipAddress,
      userId: req.user?._id || 'anonymous',
      requestId: req.requestId,
    });
  }

  logResponse(req, statusCode, responseTime = 0) {
    this.debug(`Response: ${statusCode} (${responseTime}ms)`, {
      path: req.path,
      requestId: req.requestId,
    });
  }

  // Database logging
  logDatabase(operation, collection, details) {
    this.debug(`DB ${operation} on ${collection}`, details);
  }

  // API call logging
  logAPICall(service, endpoint, method, statusCode, responseTime = 0) {
    this.info(`[${service}] ${method} ${endpoint} - ${statusCode} (${responseTime}ms)`);
  }

  // Business logic logging
  logEvent(eventType, details) {
    this.info(`EVENT: ${eventType}`, details);
  }

  // Error events
  logEventError(eventType, error, details) {
    this.error(`EVENT FAILED: ${eventType}`, error, details);
  }

  // WebSocket logging
  logWebSocket(action, userId, data = null) {
    this.debug(`[WS] ${action} - ${userId}`, data);
  }
}

// Singleton instance
let loggerInstance = null;

const getLogger = () => {
  if (!loggerInstance) {
    loggerInstance = new Logger();
  }
  return loggerInstance;
};

module.exports = {
  Logger,
  getLogger,
};
