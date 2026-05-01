import 'package:flutter_dotenv/flutter_dotenv.dart';

class EnvConfig {
  static late final String apiProtocol;
  static late final String apiHost;
  static late final String apiPort;
  static late final String wsProtocol;
  static late final String wsHost;
  static late final String wsPort;
  static late final String aiEngineUrl;
  
  static late final bool enableDebugLogs;
  static late final bool enableAudioCrashDetection;
  static late final bool enableBackgroundLocationTracking;
  
  static late final int locationUpdateInterval;
  static late final int accelerometerUpdateInterval;
  static late final int sensorTimeout;
  
  static late final double impactThreshold;
  static late final int inactivityThreshold;
  static late final int batterySaverModeThreshold;

  /// Initialize environment configuration from .env file
  /// Call this in main() before creating the app
  static Future<void> initialize() async {
    await dotenv.load();
    
    // API Configuration
    apiProtocol = dotenv.get('API_PROTOCOL', fallback: 'http');
    apiHost = dotenv.get('API_HOST', fallback: 'localhost');
    apiPort = dotenv.get('API_PORT', fallback: '5000');
    wsProtocol = dotenv.get('WS_PROTOCOL', fallback: 'ws');
    wsHost = dotenv.get('WS_HOST', fallback: 'localhost');
    wsPort = dotenv.get('WS_PORT', fallback: '5000');
    aiEngineUrl = dotenv.get('AI_ENGINE_URL', fallback: 'http://localhost:8000');
    
    // Feature Flags
    enableDebugLogs = dotenv.get('ENABLE_DEBUG_LOGS', fallback: 'true').toLowerCase() == 'true';
    enableAudioCrashDetection = dotenv.get('ENABLE_AUDIO_CRASH_DETECTION', fallback: 'true').toLowerCase() == 'true';
    enableBackgroundLocationTracking = dotenv.get('ENABLE_BACKGROUND_LOCATION_TRACKING', fallback: 'true').toLowerCase() == 'true';
    
    // Intervals (milliseconds)
    locationUpdateInterval = int.parse(dotenv.get('LOCATION_UPDATE_INTERVAL', fallback: '10000'));
    accelerometerUpdateInterval = int.parse(dotenv.get('ACCELEROMETER_UPDATE_INTERVAL', fallback: '100'));
    sensorTimeout = int.parse(dotenv.get('SENSOR_TIMEOUT', fallback: '5000'));
    
    // Risk Assessment Parameters
    impactThreshold = double.parse(dotenv.get('IMPACT_THRESHOLD', fallback: '15.0'));
    inactivityThreshold = int.parse(dotenv.get('INACTIVITY_THRESHOLD', fallback: '30'));
    batterySaverModeThreshold = int.parse(dotenv.get('BATTERY_SAVER_MODE_THRESHOLD', fallback: '15'));
  }

  /// Get full API base URL
  static String get apiBaseUrl {
    final port = apiPort.isEmpty ? '' : ':$apiPort';
    return '$apiProtocol://$apiHost$port';
  }

  /// Get full WebSocket URL
  static String get wsBaseUrl {
    final port = wsPort.isEmpty ? '' : ':$wsPort';
    return '$wsProtocol://$wsHost$port';
  }

  /// Debug print with feature flag
  static void debugPrint(String message) {
    if (enableDebugLogs) {
      print('[HumanSafety] $message');
    }
  }
}
