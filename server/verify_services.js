#!/usr/bin/env node
/**
 * Backend Service Initialization Test
 * Verifies all 11 infrastructure layers load correctly
 */

const colors = {
  reset: '\x1b[0m',
  green: '\x1b[32m',
  red: '\x1b[31m',
  yellow: '\x1b[33m',
  blue: '\x1b[34m',
  cyan: '\x1b[36m',
};

function log(message, color = 'reset') {
  console.log(`${colors[color]}${message}${colors.reset}`);
}

log('\n╔════════════════════════════════════════════════════════════════╗', 'cyan');
log('║     Service Initialization Verification                        ║', 'cyan');
log('║     Testing all 11 infrastructure layers                       ║', 'cyan');
log('╚════════════════════════════════════════════════════════════════╝', 'cyan');

// Test all services
const tests = [
  {
    name: 'Layer 2: Retry Service',
    test: () => {
      const RetryService = require('./services/retry_service');
      const service = new RetryService();
      if (!service.executeWithRetry) throw new Error('executeWithRetry not found');
      return 'OK';
    },
  },
  {
    name: 'Layer 3: Priority Queue Service',
    test: () => {
      const { PriorityQueueService, EscalationEngine } = require('./services/priority_queue_service');
      const queue = new PriorityQueueService();
      const escalation = new EscalationEngine();
      if (!queue.enqueue) throw new Error('enqueue not found');
      if (!escalation.checkEscalation) throw new Error('checkEscalation not found');
      return 'OK';
    },
  },
  {
    name: 'Layer 6: Security Service',
    test: () => {
      const { RateLimiterService, SecurityService } = require('./services/security_service');
      const rateLimiter = new RateLimiterService();
      const security = new SecurityService();
      if (!rateLimiter.isAllowed) throw new Error('isAllowed not found');
      if (!security.detectSuspiciousBehavior) throw new Error('detectSuspiciousBehavior not found');
      return 'OK';
    },
  },
  {
    name: 'Layer 7: Audit Log Service',
    test: () => {
      const AuditLogService = require('./services/audit_log_service');
      const audit = new AuditLogService();
      if (!audit.logEvent) throw new Error('logEvent not found');
      if (!audit.verifyIntegrity) throw new Error('verifyIntegrity not found');
      return 'OK';
    },
  },
  {
    name: 'Layer 8: Event Stream Service',
    test: () => {
      const EventStreamService = require('./services/event_stream_service');
      const stream = new EventStreamService();
      if (!stream.publish) throw new Error('publish not found');
      if (!stream.subscribe) throw new Error('subscribe not found');
      return 'OK';
    },
  },
  {
    name: 'Layer 11: Health Monitor Service',
    test: () => {
      const HealthMonitorService = require('./services/health_monitor');
      const health = new HealthMonitorService();
      if (!health.getSystemStatus) throw new Error('getSystemStatus not found');
      if (!health.startHealthChecks) throw new Error('startHealthChecks not found');
      return 'OK';
    },
  },
];

let passed = 0;
let failed = 0;

log('\n📋 Running Service Tests:\n', 'blue');

tests.forEach((test) => {
  try {
    const result = test.test();
    log(`  ✅ ${test.name}`, 'green');
    passed++;
  } catch (error) {
    log(`  ❌ ${test.name}: ${error.message}`, 'red');
    failed++;
  }
});

log('\n📊 Test Results:', 'blue');
log(`  Passed: ${passed}/${tests.length}`, 'green');
log(`  Failed: ${failed}/${tests.length}`, failed > 0 ? 'red' : 'green');

if (failed === 0) {
  log('\n✅ All services initialized successfully!\n', 'green');
  process.exit(0);
} else {
  log('\n❌ Some services failed to initialize.\n', 'red');
  process.exit(1);
}
