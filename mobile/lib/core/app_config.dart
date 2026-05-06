// Production constants and configuration
class AppConfig {
  // Environment
  static const String appName = 'HumanSafety';
  static const String appVersion = '1.0.0';
  static const String appBuild = '1';

  // API Configuration
  static const String apiBaseUrl = 'http://localhost:5000/api/v1';
  static const String wsBaseUrl = 'ws://localhost:5000/ws';
  
  // Timeouts (in seconds)
  static const int apiTimeout = 10;
  static const int streamTimeout = 30;
  
  // Sensor Configuration
  static const int sensorSamplingRate = 100; // milliseconds
  static const int gpsUpdateInterval = 10000; // milliseconds
  static const int audioCheckInterval = 5000; // milliseconds
  
  // Performance Thresholds
  static const double impactThreshold = 20.0; // m/s²
  static const double speedDropThreshold = 30.0; // percentage
  static const double inactivityThreshold = 5000; // milliseconds
  
  // Feature Flags
  static const bool enableOfflineMode = true;
  static const bool enableSensorFusion = true;
  static const bool enableAudioAnalysis = true;
  static const bool enableBackgroundTracking = true;
  
  // Cache Configuration
  static const int maxCacheSize = 50 * 1024 * 1024; // 50MB
  static const int imageCacheSize = 100; // max 100 images
  static const Duration defaultCacheDuration = Duration(hours: 1);
  
  // Map & Location
  static const double defaultMapZoom = 15.0;
  static const int maxLocationHistory = 100;
  
  // Emergency Configuration
  static const int emergencyTimeout = 30; // seconds
  static const int maxEmergencyContacts = 5;
  static const double nearbyHospitalRadius = 15; // km
  
  // UI Configuration
  static const Duration animationDuration = Duration(milliseconds: 300);
  static const double borderRadiusStandard = 12.0;
  static const double cardElevation = 2.0;
}

// API Response Status Codes
class ApiStatusCodes {
  static const int success = 200;
  static const int created = 201;
  static const int badRequest = 400;
  static const int unauthorized = 401;
  static const int forbidden = 403;
  static const int notFound = 404;
  static const int serverError = 500;
}

// Emergency Types
class EmergencyTypes {
  static const String panic = 'panic';
  static const String accident = 'accident';
  static const String medical = 'medical';
  static const String fire = 'fire';
  static const String other = 'other';
}

// User Roles
class UserRoles {
  static const String user = 'user';
  static const String police = 'police';
  static const String hospital = 'hospital';
  static const String ambulance = 'ambulance';
  static const String admin = 'admin';
}

// Case Status
class CaseStatus {
  static const String pending = 'pending';
  static const String inProgress = 'in-progress';
  static const String accepted = 'accepted';
  static const String atLocation = 'at-location';
  static const String resolved = 'resolved';
  static const String closed = 'closed';
}

// Risk Levels
class RiskLevels {
  static const String low = 'low';
  static const String medium = 'medium';
  static const String high = 'high';
  static const String critical = 'critical';
}

// Storage Keys
class StorageKeys {
  static const String userToken = 'user_token';
  static const String userId = 'user_id';
  static const String userRole = 'user_role';
  static const String userPhone = 'user_phone';
  static const String userName = 'user_name';
  static const String isDarkMode = 'is_dark_mode';
  static const String emergencyContacts = 'emergency_contacts';
  static const String medicalHistory = 'medical_history';
  static const String lastLocation = 'last_location';
  static const String locationHistory = 'location_history';
}

// Error Messages
class ErrorMessages {
  static const String networkError = 'Network connection failed. Please check your internet.';
  static const String serverError = 'Server error. Please try again later.';
  static const String unauthorized = 'Unauthorized. Please login again.';
  static const String locationDenied = 'Location permission denied. Please enable location in settings.';
  static const String permissionDenied = 'Permission denied. Please enable in settings.';
  static const String emptyField = 'This field cannot be empty.';
  static const String invalidPhone = 'Invalid phone number.';
  static const String invalidEmail = 'Invalid email address.';
  static const String passwordTooShort = 'Password must be at least 8 characters.';
}

// Success Messages
class SuccessMessages {
  static const String emergencyTriggered = 'Emergency alert sent successfully!';
  static const String hospitalRequested = 'Hospital request sent. Ambulance on the way!';
  static const String caseAccepted = 'Case accepted. You will receive updates.';
  static const String profileUpdated = 'Profile updated successfully.';
  static const String contactAdded = 'Emergency contact added.';
}
