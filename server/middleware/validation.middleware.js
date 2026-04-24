const { body, param, validationResult } = require('express-validator');

// ============== VALIDATION MIDDLEWARE ==============

const validationErrorHandler = (req, res, next) => {
  const errors = validationResult(req);
  if (!errors.isEmpty()) {
    return res.status(400).json({
      success: false,
      message: 'Validation failed',
      errors: errors.array().map(err => ({
        field: err.param,
        message: err.msg
      }))
    });
  }
  next();
};

// ============== AUTH VALIDATORS ==============

const validateSendOTP = [
  body('phone')
    .trim()
    .matches(/^[0-9]{10,15}$/)
    .withMessage('Phone must be 10-15 digits'),
  validationErrorHandler
];

const validateVerifyOTP = [
  body('phone')
    .trim()
    .matches(/^[0-9]{10,15}$/)
    .withMessage('Phone must be 10-15 digits'),
  body('otp')
    .trim()
    .isLength({ min: 4, max: 6 })
    .withMessage('OTP must be 4-6 digits'),
  validationErrorHandler
];

// ============== USER VALIDATORS ==============

const validateUserUpdate = [
  body('name')
    .optional()
    .trim()
    .isLength({ min: 2, max: 50 })
    .withMessage('Name must be 2-50 characters'),
  body('email')
    .optional()
    .isEmail()
    .withMessage('Valid email required'),
  body('phone')
    .optional()
    .matches(/^[0-9]{10,15}$/)
    .withMessage('Phone must be 10-15 digits'),
  body('emergencyPhones')
    .optional()
    .isArray()
    .withMessage('Emergency phones must be an array'),
  validationErrorHandler
];

const validateLocationUpdate = [
  body('latitude')
    .isFloat({ min: -90, max: 90 })
    .withMessage('Latitude must be between -90 and 90'),
  body('longitude')
    .isFloat({ min: -180, max: 180 })
    .withMessage('Longitude must be between -180 and 180'),
  body('accuracy')
    .optional()
    .isFloat({ min: 0 })
    .withMessage('Accuracy must be positive'),
  validationErrorHandler
];

// ============== CONTACT VALIDATORS ==============

const validateAddContact = [
  body('name')
    .trim()
    .isLength({ min: 2, max: 50 })
    .withMessage('Name must be 2-50 characters'),
  body('phone')
    .trim()
    .matches(/^[0-9]{10,15}$/)
    .withMessage('Phone must be 10-15 digits'),
  body('relationship')
    .trim()
    .isLength({ min: 2, max: 20 })
    .withMessage('Relationship must be 2-20 characters'),
  validationErrorHandler
];

const validateRemoveContact = [
  param('contactId')
    .isMongoId()
    .withMessage('Invalid contact ID'),
  validationErrorHandler
];

// ============== EMERGENCY VALIDATORS ==============

const validatePanicAlert = [
  body('latitude')
    .isFloat({ min: -90, max: 90 })
    .withMessage('Latitude must be between -90 and 90'),
  body('longitude')
    .isFloat({ min: -180, max: 180 })
    .withMessage('Longitude must be between -180 and 180'),
  body('sensorData')
    .optional()
    .isObject()
    .withMessage('Sensor data must be an object'),
  validationErrorHandler
];

// ============== ACCIDENT VALIDATORS ==============

const validateAnalyzeAccident = [
  body('accelerometerData')
    .optional()
    .isObject()
    .withMessage('Accelerometer data must be an object'),
  body('gyroscopeData')
    .optional()
    .isObject()
    .withMessage('Gyroscope data must be an object'),
  body('speed')
    .optional()
    .isFloat({ min: 0 })
    .withMessage('Speed must be non-negative'),
  body('location')
    .optional()
    .isObject()
    .withMessage('Location must be an object'),
  validationErrorHandler
];

// ============== HELP VALIDATORS ==============

const validateRequestHelp = [
  body('type')
    .isIn(['medical', 'police', 'fire', 'general'])
    .withMessage('Invalid help type'),
  body('description')
    .trim()
    .isLength({ min: 5, max: 500 })
    .withMessage('Description must be 5-500 characters'),
  body('latitude')
    .isFloat({ min: -90, max: 90 })
    .withMessage('Latitude must be between -90 and 90'),
  body('longitude')
    .isFloat({ min: -180, max: 180 })
    .withMessage('Longitude must be between -180 and 180'),
  validationErrorHandler
];

const validateHelpResponse = [
  param('helpId')
    .isMongoId()
    .withMessage('Invalid help request ID'),
  body('status')
    .isIn(['accepted', 'rejected', 'completed'])
    .withMessage('Invalid status'),
  validationErrorHandler
];

// ============== HOSPITAL VALIDATORS ==============

const validateHospitalNearby = [
  body('latitude')
    .isFloat({ min: -90, max: 90 })
    .withMessage('Latitude must be between -90 and 90'),
  body('longitude')
    .isFloat({ min: -180, max: 180 })
    .withMessage('Longitude must be between -180 and 180'),
  body('radiusKm')
    .optional()
    .isFloat({ min: 0.1, max: 50 })
    .withMessage('Radius must be 0.1-50 km'),
  validationErrorHandler
];

// ============== SETTINGS VALIDATORS ==============

const validateSettingsUpdate = [
  body('emergencyContacts')
    .optional()
    .isArray()
    .withMessage('Emergency contacts must be an array'),
  body('shareLocation')
    .optional()
    .isBoolean()
    .withMessage('Share location must be boolean'),
  body('autoShare')
    .optional()
    .isBoolean()
    .withMessage('Auto share must be boolean'),
  body('notificationSound')
    .optional()
    .isBoolean()
    .withMessage('Notification sound must be boolean'),
  validationErrorHandler
];

module.exports = {
  validateSendOTP,
  validateVerifyOTP,
  validateUserUpdate,
  validateLocationUpdate,
  validateAddContact,
  validateRemoveContact,
  validatePanicAlert,
  validateAnalyzeAccident,
  validateRequestHelp,
  validateHelpResponse,
  validateHospitalNearby,
  validateSettingsUpdate
};
