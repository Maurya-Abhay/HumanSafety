// Response formatter middleware - standardizes all API responses
const formatResponse = (req, res, next) => {
  // Override res.json to standardize response format
  res.apiSuccess = (data = null, message = 'Success', statusCode = 200) => {
    return res.status(statusCode).json({
      success: true,
      message,
      data,
      requestId: req.requestId,
      timestamp: new Date().toISOString(),
    });
  };

  res.apiError = (message = 'Error', error = null, statusCode = 400, errorCode = null) => {
    return res.status(statusCode).json({
      success: false,
      message,
      error: {
        code: errorCode || 'UNKNOWN_ERROR',
        details: error?.message || null,
        stack: process.env.NODE_ENV === 'development' ? error?.stack : undefined,
      },
      requestId: req.requestId,
      timestamp: new Date().toISOString(),
    });
  };

  res.apiPaginated = (data = [], total = 0, limit = 20, skip = 0, message = 'Success') => {
    return res.status(200).json({
      success: true,
      message,
      data,
      pagination: {
        total,
        count: data.length,
        limit: parseInt(limit),
        skip: parseInt(skip),
        hasMore: skip + data.length < total,
      },
      requestId: req.requestId,
      timestamp: new Date().toISOString(),
    });
  };

  next();
};

module.exports = { formatResponse };
