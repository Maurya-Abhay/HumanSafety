// Global error handling middleware
const errorHandler = (err, req, res, next) => {
  const status = err.status || err.statusCode || 500;
  const message = err.message || 'Internal Server Error';
  
  // Log error
  console.error(`[ERROR] ${req.method} ${req.path} - ${status}: ${message}`);
  
  // Send response
  res.status(status).json({
    success: false,
    error: {
      status,
      message,
      timestamp: new Date().toISOString(),
      requestId: req.requestId,
      path: req.path,
    },
    ...(process.env.NODE_ENV === 'development' && { stack: err.stack }),
  });
};

// Not Found handler
const notFoundHandler = (req, res) => {
  res.status(404).json({
    success: false,
    error: {
      status: 404,
      message: 'Route not found',
      path: req.path,
      method: req.method,
      requestId: req.requestId,
    },
  });
};

// Async error wrapper
const asyncHandler = (fn) => (req, res, next) => {
  Promise.resolve(fn(req, res, next)).catch(next);
};

module.exports = {
  errorHandler,
  notFoundHandler,
  asyncHandler,
};
