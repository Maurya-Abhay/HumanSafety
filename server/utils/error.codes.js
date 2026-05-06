// Standardized error codes for API responses
const ERROR_CODES = {
  // Authentication Errors (401-403)
  NO_TOKEN: { code: 'NO_TOKEN', message: 'No authentication token provided', status: 401 },
  INVALID_TOKEN: { code: 'INVALID_TOKEN', message: 'Token is invalid or expired', status: 401 },
  USER_NOT_FOUND: { code: 'USER_NOT_FOUND', message: 'User account not found', status: 404 },
  USER_BLOCKED: { code: 'USER_BLOCKED', message: 'User account is blocked', status: 403 },
  UNAUTHORIZED: { code: 'UNAUTHORIZED', message: 'You do not have permission to access this resource', status: 403 },

  // Validation Errors (400)
  VALIDATION_FAILED: { code: 'VALIDATION_FAILED', message: 'Input validation failed', status: 400 },
  INVALID_LOCATION: { code: 'INVALID_LOCATION', message: 'Invalid location coordinates', status: 400 },
  INVALID_PHONE: { code: 'INVALID_PHONE', message: 'Invalid phone number format', status: 400 },
  INVALID_EMAIL: { code: 'INVALID_EMAIL', message: 'Invalid email format', status: 400 },
  INVALID_ROLE: { code: 'INVALID_ROLE', message: 'Invalid user role', status: 400 },
  MISSING_REQUIRED_FIELD: { code: 'MISSING_REQUIRED_FIELD', message: 'Missing required field', status: 400 },

  // Business Logic Errors (400-409)
  DUPLICATE_ENTRY: { code: 'DUPLICATE_ENTRY', message: 'Entry already exists', status: 409 },
  INVALID_STATUS_TRANSITION: { code: 'INVALID_STATUS_TRANSITION', message: 'Invalid status transition', status: 400 },
  CASE_NOT_FOUND: { code: 'CASE_NOT_FOUND', message: 'Case not found', status: 404 },
  EMERGENCY_NOT_FOUND: { code: 'EMERGENCY_NOT_FOUND', message: 'Emergency not found', status: 404 },
  HOSPITAL_NOT_FOUND: { code: 'HOSPITAL_NOT_FOUND', message: 'Hospital not found', status: 404 },
  AMBULANCE_NOT_FOUND: { code: 'AMBULANCE_NOT_FOUND', message: 'Ambulance not found', status: 404 },
  POLICE_NOT_FOUND: { code: 'POLICE_NOT_FOUND', message: 'Police officer not found', status: 404 },
  CONTACT_NOT_FOUND: { code: 'CONTACT_NOT_FOUND', message: 'Contact not found', status: 404 },
  ACCOUNT_PENDING: { code: 'ACCOUNT_PENDING', message: 'Account is pending approval', status: 403 },
  ACCOUNT_REJECTED: { code: 'ACCOUNT_REJECTED', message: 'Account was rejected', status: 403 },

  // Not Found (404)
  RESOURCE_NOT_FOUND: { code: 'RESOURCE_NOT_FOUND', message: 'Resource not found', status: 404 },
  ENDPOINT_NOT_FOUND: { code: 'ENDPOINT_NOT_FOUND', message: 'Endpoint not found', status: 404 },

  // Server Errors (500)
  INTERNAL_ERROR: { code: 'INTERNAL_ERROR', message: 'Internal server error', status: 500 },
  DATABASE_ERROR: { code: 'DATABASE_ERROR', message: 'Database operation failed', status: 500 },
  OPERATION_FAILED: { code: 'OPERATION_FAILED', message: 'Operation failed', status: 500 },
  FILE_UPLOAD_FAILED: { code: 'FILE_UPLOAD_FAILED', message: 'File upload failed', status: 500 },

  // External Service Errors (502-503)
  AI_ENGINE_ERROR: { code: 'AI_ENGINE_ERROR', message: 'AI Engine service unavailable', status: 502 },
  SMS_SERVICE_ERROR: { code: 'SMS_SERVICE_ERROR', message: 'SMS service failed', status: 502 },
  NOTIFICATION_SERVICE_ERROR: { code: 'NOTIFICATION_SERVICE_ERROR', message: 'Notification service failed', status: 502 },
};

// Helper function to get error by code
const getErrorByCode = (code) => {
  return ERROR_CODES[code] || ERROR_CODES.INTERNAL_ERROR;
};

// Helper function to throw standardized error
class APIError extends Error {
  constructor(errorCode, message = null) {
    const errorInfo = getErrorByCode(errorCode);
    super(message || errorInfo.message);
    this.code = errorCode;
    this.message = message || errorInfo.message;
    this.status = errorInfo.status;
  }
}

module.exports = {
  ERROR_CODES,
  getErrorByCode,
  APIError,
};
