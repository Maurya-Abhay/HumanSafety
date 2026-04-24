// Backend Retry Service with Exponential Backoff
const EventEmitter = require('events');

class RetryService extends EventEmitter {
  constructor(options = {}) {
    super();
    this.maxRetries = options.maxRetries || 3;
    this.initialDelay = options.initialDelay || 1000; // 1 second
    this.maxDelay = options.maxDelay || 300000; // 5 minutes
    this.backoffMultiplier = options.backoffMultiplier || 2;
    this.retryMap = new Map(); // Track retry attempts
    this.deadLetterQueue = [];
  }

  /**
   * Execute function with automatic retry on failure
   */
  async executeWithRetry(
    fn,
    context = {},
    options = {}
  ) {
    const requestId = context.requestId || `REQ-${Date.now()}`;
    const maxRetries = options.maxRetries || this.maxRetries;
    let lastError;

    for (let attempt = 1; attempt <= maxRetries; attempt++) {
      try {
        this.emit('retry:attempt', { requestId, attempt, maxRetries });

        const result = await fn();

        if (attempt > 1) {
          this.emit('retry:success', { requestId, attempt, context });
        }

        return {
          success: true,
          data: result,
          attempts: attempt,
          requestId,
        };
      } catch (error) {
        lastError = error;

        if (attempt < maxRetries) {
          const delay = this.calculateBackoff(attempt);
          console.log(
            `Retry attempt ${attempt}/${maxRetries} in ${delay}ms for ${requestId}: ${error.message}`
          );

          this.emit('retry:failed', {
            requestId,
            attempt,
            error: error.message,
            nextRetryIn: delay,
          });

          await this.delay(delay);
        }
      }
    }

    // All retries exhausted
    const dlqEntry = {
      requestId,
      context,
      error: lastError.message,
      attempts: maxRetries,
      timestamp: Date.now(),
      stack: lastError.stack,
    };

    this.deadLetterQueue.push(dlqEntry);
    this.emit('retry:exhausted', dlqEntry);

    return {
      success: false,
      error: lastError.message,
      attempts: maxRetries,
      requestId,
      inDLQ: true,
    };
  }

  calculateBackoff(attempt) {
    const exponentialDelay =
      this.initialDelay * Math.pow(this.backoffMultiplier, attempt - 1);
    const cappedDelay = Math.min(exponentialDelay, this.maxDelay);
    const jitter = Math.random() * cappedDelay * 0.1; // 10% jitter
    return Math.floor(cappedDelay + jitter);
  }

  delay(ms) {
    return new Promise((resolve) => setTimeout(resolve, ms));
  }

  /**
   * Get DLQ entries
   */
  getDeadLetterQueue() {
    return this.deadLetterQueue;
  }

  /**
   * Retry a specific DLQ entry
   */
  async retryDLQEntry(requestId, fn) {
    const entry = this.deadLetterQueue.find((e) => e.requestId === requestId);
    if (!entry) {
      throw new Error(`DLQ entry not found: ${requestId}`);
    }

    const result = await this.executeWithRetry(fn, entry.context, {
      maxRetries: 1,
    });

    if (result.success) {
      this.deadLetterQueue = this.deadLetterQueue.filter(
        (e) => e.requestId !== requestId
      );
    }

    return result;
  }

  /**
   * Clear DLQ entry after manual resolution
   */
  resolveDLQEntry(requestId) {
    this.deadLetterQueue = this.deadLetterQueue.filter(
      (e) => e.requestId !== requestId
    );
  }

  /**
   * Get DLQ stats
   */
  getDLQStats() {
    return {
      totalDLQEntries: this.deadLetterQueue.length,
      oldestEntry: this.deadLetterQueue[0]?.timestamp,
      entries: this.deadLetterQueue,
    };
  }
}

module.exports = RetryService;
