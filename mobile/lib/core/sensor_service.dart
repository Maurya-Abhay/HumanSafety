import 'dart:async';
import 'dart:math';
import 'package:sensors_plus/sensors_plus.dart';
import 'package:geolocator/geolocator.dart';
import 'package:permission_handler/permission_handler.dart';
import 'dart:io' show Platform;
import 'package:flutter/foundation.dart';
import 'api_service.dart';
import 'emergency_orchestrator.dart';
import 'storage_service.dart';
import 'constants.dart';
import 'audio_crash_detection.dart';

class SensorService extends ChangeNotifier {
  static final SensorService _instance = SensorService._internal();
  factory SensorService() => _instance;
  SensorService._internal();

  // Sensor streams
  StreamSubscription<AccelerometerEvent>? _accelerometerSubscription;
  StreamSubscription<GyroscopeEvent>? _gyroscopeSubscription;
  StreamSubscription<Position>? _positionSubscription;
  StreamSubscription<CrashDetectionResult>? _crashDetectionSubscription;

  // Audio crash detection
  final AudioCrashDetection _audioCrashDetection = AudioCrashDetection();
  CrashDetectionResult? _lastAudioAnalysis;

  // Sensor data
  AccelerometerEvent? _lastAccelerometer;
  GyroscopeEvent? _lastGyroscope;
  Position? _lastPosition;

  // Accident detection
  bool _isMonitoring = false;
  bool _autoSOS = true;
  final double _impactThreshold = 15.0; // m/s²
  final int _inactivityThreshold = 30; // seconds
  DateTime? _lastActivityTime;
  bool _rideMode = false;
  bool _batterySaver = false;

  // Background tracking
  bool _backgroundTracking = false;
  Timer? _locationTimer;

  // Callbacks
  Function(double magnitude)? onImpactDetected;
  Function()? onAccidentDetected;
  Function(Position position)? onLocationUpdate;

  // Getters
  bool get isMonitoring => _isMonitoring;
  bool get autoSOS => _autoSOS;
  bool get backgroundTracking => _backgroundTracking;
  bool get rideMode => _rideMode;
  bool get batterySaver => _batterySaver;
  AccelerometerEvent? get lastAccelerometer => _lastAccelerometer;
  Position? get lastPosition => _lastPosition;

  Future<void> initialize() async {
    await _loadSettings();
    await _audioCrashDetection.initialize();
  }

  Future<void> _loadSettings() async {
    _autoSOS = await StorageService.getBool('enable_auto_sos') ?? true;
    _backgroundTracking = await StorageService.getBool('enable_background_tracking') ?? false;
    _rideMode = await StorageService.getBool('ride_mode_enabled') ?? false;
    _batterySaver = await StorageService.getBool('battery_saver_enabled') ?? false;
    // _impactThreshold is final and set at declaration
  }

  Future<void> startMonitoring() async {
    if (_isMonitoring) return;

    try {
      // Check permissions
      final accelerometerGranted = await _checkAccelerometerPermission();
      final locationGranted = await _checkLocationPermission();
      final microphoneGranted = await _checkMicrophonePermission();

      if (!accelerometerGranted) {
        debugPrint('Accelerometer permission denied');
        return;
      }

      if (!microphoneGranted) {
        debugPrint('Microphone permission denied');
        return;
      }

      // Start audio monitoring
      await _audioCrashDetection.startMonitoring();
      _crashDetectionSubscription = _audioCrashDetection.crashDetectionStream.listen(
        (result) {
          _lastAudioAnalysis = result;
          if (result.isCrash) {
            debugPrint('🔊 Audio crash detected! Confidence: ${result.confidence.toStringAsFixed(1)}%');
            _analyzeWithAudioAndSensors(result);
          }
        },
        onError: (error) => debugPrint('Audio analysis error: $error'),
      );

      // Start accelerometer monitoring
      _accelerometerSubscription = accelerometerEvents.listen(
        _onAccelerometerEvent,
        onError: (error) => debugPrint('Accelerometer error: $error'),
      );

      // Start gyroscope monitoring unless battery saver mode is active
      if (!_batterySaver) {
        _gyroscopeSubscription = gyroscopeEvents.listen(
          _onGyroscopeEvent,
          onError: (error) => debugPrint('Gyroscope error: $error'),
        );
      }

      // Start location monitoring if enabled
      if (_backgroundTracking && locationGranted) {
        await _startLocationTracking();
      }

      _isMonitoring = true;
      _lastActivityTime = DateTime.now();
      notifyListeners();

      debugPrint('Sensor monitoring started');
    } catch (e) {
      debugPrint('Failed to start monitoring: $e');
    }
  }

  Future<void> stopMonitoring() async {
    if (!_isMonitoring) return;

    await _accelerometerSubscription?.cancel();
    await _gyroscopeSubscription?.cancel();
    await _crashDetectionSubscription?.cancel();
    await _audioCrashDetection.stopMonitoring();
    await _stopLocationTracking();

    _accelerometerSubscription = null;
    _gyroscopeSubscription = null;
    _crashDetectionSubscription = null;
    _isMonitoring = false;
    notifyListeners();

    debugPrint('Sensor monitoring stopped');
  }

  void _onAccelerometerEvent(AccelerometerEvent event) {
    _lastAccelerometer = event;
    _lastActivityTime = DateTime.now();

    // Calculate magnitude
    final magnitude = sqrt(
      event.x * event.x +
      event.y * event.y +
      event.z * event.z
    );

    // Check for impact
    if (magnitude > _impactThreshold) {
      onImpactDetected?.call(magnitude);
      _detectAccident(magnitude);
    }

    notifyListeners();
  }

  void _onGyroscopeEvent(GyroscopeEvent event) {
    _lastGyroscope = event;
    _lastActivityTime = DateTime.now();
  }

  void _detectAccident(double magnitude) {
    // If high-confidence local detection, send to AI engine for analysis
    if (magnitude > _impactThreshold * 1.5) {
      _analyzeWithAIEngine(magnitude);
    } else {
      // Low confidence - local evaluation only
      final confidenceScore = ((magnitude / _impactThreshold) * 35).clamp(0, 100).round();
      final decision = EmergencyOrchestrator().evaluateConfidence(confidenceScore);

      if (decision != EmergencyDecision.silent) {
        onAccidentDetected?.call();
      }
    }
  }

  /// Send sensor data to AI engine for analysis
  Future<void> _analyzeWithAIEngine(double magnitude) async {
    try {
      final token = await ApiService.getValidToken();
      if (token == null) {
        debugPrint('No token - skipping AI analysis');
        return;
      }

      // Get current location
      Position? position;
      try {
        position = await Geolocator.getCurrentPosition(
          desiredAccuracy: LocationAccuracy.high,
        ).timeout(Duration(seconds: 5));
      } catch (e) {
        debugPrint('Failed to get location for AI analysis: $e');
        position = _lastPosition;
      }

      // Prepare sensor data
      final sensorPayload = {
        'sensorData': {
          'acceleration': {
            'x': _lastAccelerometer?.x ?? 0,
            'y': _lastAccelerometer?.y ?? 0,
            'z': _lastAccelerometer?.z ?? 0,
          },
          'impactMagnitude': magnitude,
          'timestamp': DateTime.now().toIso8601String(),
        },
        'location': {
          'latitude': position?.latitude ?? 0,
          'longitude': position?.longitude ?? 0,
        },
      };

      // Call AI engine via API
      try {
        final response = await ApiService.analyzeAccident(token, sensorPayload);

        if (response != null && response is Map) {
          final riskScore = (response['riskScore'] as num?)?.toDouble() ?? 0;
          final analysis = response['analysis'] as String? ?? '';

          debugPrint('AI Analysis - Risk: $riskScore, Analysis: $analysis');

          // Only trigger emergency if AI confirms high risk
          if (riskScore > 70) {
            if (_autoSOS) {
              _triggerAutoSOS(magnitude);
            }
            onAccidentDetected?.call();
          } else {
            debugPrint('Low risk score ($riskScore) - no emergency trigger');
          }
        }
      } catch (apiError) {
        debugPrint('AI analysis failed: $apiError');
        // Fallback: If AI unavailable but local detection is very strong
        if (magnitude > _impactThreshold * 2.0) {
          if (_autoSOS) {
            _triggerAutoSOS(magnitude);
          }
          onAccidentDetected?.call();
        }
      }
    } catch (e) {
      debugPrint('Error in AI analysis workflow: $e');
    }
  }

  /// Analyze with combined audio + sensor data
  Future<void> _analyzeWithAudioAndSensors(CrashDetectionResult audioResult) async {
    try {
      final token = await ApiService.getValidToken();
      if (token == null) {
        debugPrint('No token - skipping combined analysis');
        return;
      }

      // Get current location
      Position? position;
      try {
        position = await Geolocator.getCurrentPosition(
          desiredAccuracy: LocationAccuracy.high,
        ).timeout(Duration(seconds: 5));
      } catch (e) {
        debugPrint('Failed to get location for analysis: $e');
        position = _lastPosition;
      }

      // Combine audio + sensor data
      final sensorPayload = {
        'sensorData': {
          'acceleration': {
            'x': _lastAccelerometer?.x ?? 0,
            'y': _lastAccelerometer?.y ?? 0,
            'z': _lastAccelerometer?.z ?? 0,
          },
          'impactMagnitude': sqrt(
            (_lastAccelerometer?.x ?? 0) * (_lastAccelerometer?.x ?? 0) +
            (_lastAccelerometer?.y ?? 0) * (_lastAccelerometer?.y ?? 0) +
            (_lastAccelerometer?.z ?? 0) * (_lastAccelerometer?.z ?? 0)
          ),
          'audio': {
            'decibelLevel': audioResult.maxDecibel,
            'averageDecibel': audioResult.avgDecibel,
            'audioConfidence': audioResult.confidence,
          },
          'timestamp': DateTime.now().toIso8601String(),
        },
        'location': {
          'latitude': position?.latitude ?? 0,
          'longitude': position?.longitude ?? 0,
        },
      };

      // Call AI engine
      try {
        final response = await ApiService.analyzeAccident(token, sensorPayload);

        if (response != null && response is Map) {
          final riskScore = (response['riskScore'] as num?)?.toDouble() ?? 0;
          final analysis = response['analysis'] as String? ?? '';

          debugPrint('Combined Analysis - Risk: $riskScore%, Audio: ${audioResult.confidence.toStringAsFixed(1)}%');

          // If AI + audio confirm high risk
          if (riskScore > 70 && audioResult.confidence > 60) {
            if (_autoSOS) {
              _triggerAutoSOS(audioResult.maxDecibel);
            }
            onAccidentDetected?.call();
          } else {
            debugPrint('Risk too low for emergency: AI=$riskScore%, Audio=${audioResult.confidence.toStringAsFixed(1)}%');
          }
        }
      } catch (apiError) {
        debugPrint('AI analysis failed: $apiError');
        // Fallback: High audio + high acceleration
        if (audioResult.confidence > 80) {
          if (_autoSOS) {
            _triggerAutoSOS(audioResult.maxDecibel);
          }
          onAccidentDetected?.call();
        }
      }
    } catch (e) {
      debugPrint('Error in combined analysis: $e');
    }
  }

  Future<void> _triggerAutoSOS(double magnitude) async {
    try {
      final token = await ApiService.getValidToken();
      if (token == null) return;

      // Get current location
      Position? position;
      try {
        position = await Geolocator.getCurrentPosition(
          desiredAccuracy: LocationAccuracy.high,
        );
      } catch (e) {
        debugPrint('Failed to get location for auto-SOS: $e');
      }

      // Create panic alert with sensor data
      await ApiService.createPanicAlert(
        token,
        latitude: position?.latitude ?? 0.0,
        longitude: position?.longitude ?? 0.0,
        description: 'Auto-detected accident (impact: ${magnitude.toStringAsFixed(1)} m/s²)',
        sensorData: {
          'acceleration_magnitude': magnitude,
          'accelerometer_x': _lastAccelerometer?.x,
          'accelerometer_y': _lastAccelerometer?.y,
          'accelerometer_z': _lastAccelerometer?.z,
          'gyroscope_x': _lastGyroscope?.x,
          'gyroscope_y': _lastGyroscope?.y,
          'gyroscope_z': _lastGyroscope?.z,
          'auto_triggered': true,
        },
      );

      debugPrint('Auto-SOS triggered with impact magnitude: $magnitude');
    } catch (e) {
      debugPrint('Failed to trigger auto-SOS: $e');
    }
  }

  Future<void> _startLocationTracking() async {
    try {
      const locationSettings = LocationSettings(
        accuracy: LocationAccuracy.high,
        distanceFilter: 10, // Update every 10 meters
      );

      _positionSubscription = Geolocator.getPositionStream(
        locationSettings: locationSettings,
      ).listen(
        _onPositionEvent,
        onError: (error) => debugPrint('Location error: $error'),
      );

      debugPrint('Location tracking started');
    } catch (e) {
      debugPrint('Failed to start location tracking: $e');
    }
  }

  Future<void> _stopLocationTracking() async {
    _positionSubscription?.cancel();
    _positionSubscription = null;
    _locationTimer?.cancel();
    _locationTimer = null;
    debugPrint('Location tracking stopped');
  }

  void _onPositionEvent(Position position) {
    _lastPosition = position;
    onLocationUpdate?.call(position);
    notifyListeners();
  }

  Future<bool> _checkAccelerometerPermission() async {
    // Sensors don't require explicit permission on most platforms
    // But we can check if sensors are available
    try {
      await accelerometerEvents.first;
      return true;
    } catch (e) {
      return false;
    }
  }

  Future<bool> _checkMicrophonePermission() async {
    try {
      final status = await Permission.microphone.status;
      
      if (status.isDenied || status.isRestricted) {
        final result = await Permission.microphone.request();
        if (!result.isGranted) {
          debugPrint('Microphone permission denied');
          return false;
        }
      } else if (status.isPermanentlyDenied) {
        debugPrint('Microphone permission permanently denied. User must enable in Settings.');
        // UI will show dialog to open Settings
        return false;
      }

      // On Android, also ensure activity recognition permission for motion sensors if available
      if (Platform.isAndroid) {
        final ar = await Permission.activityRecognition.status;
        if (ar.isDenied) {
          await Permission.activityRecognition.request();
        } else if (ar.isPermanentlyDenied) {
          debugPrint('Activity recognition permanently denied');
        }
      }

      return true;
    } catch (e) {
      debugPrint('Microphone permission check failed: $e');
      return false;
    }
  }

  Future<bool> _checkLocationPermission() async {
    final permission = await Geolocator.checkPermission();
    
    if (permission == LocationPermission.denied) {
      final result = await Geolocator.requestPermission();
      if (result != LocationPermission.whileInUse && result != LocationPermission.always) {
        debugPrint('Location permission denied');
        return false;
      }
    } else if (permission == LocationPermission.deniedForever) {
      debugPrint('Location permission permanently denied. User must enable in Settings.');
      return false;
    }
    
    return permission == LocationPermission.whileInUse || permission == LocationPermission.always;
  }

  // Helper: Check if any critical permission is permanently denied
  Future<bool> hasPermissionIssues() async {
    try {
      final micStatus = await Permission.microphone.status;
      final locStatus = await Geolocator.checkPermission();
      
      return micStatus.isPermanentlyDenied || locStatus == LocationPermission.deniedForever;
    } catch (e) {
      return false;
    }
  }

  // Helper: Open app settings for user to manually enable permissions
  static Future<void> openAppSettings() async {
    try {
      await openAppSettings();
    } catch (e) {
      debugPrint('Failed to open app settings: $e');
    }
  }

  // Check for inactivity (could indicate unconsciousness)
  bool isUserInactive() {
    if (_lastActivityTime == null) return false;
    final inactiveDuration = DateTime.now().difference(_lastActivityTime!);
    return inactiveDuration.inSeconds > _inactivityThreshold;
  }

  // Get current sensor status
  Map<String, dynamic> getSensorStatus() {
    return {
      'is_monitoring': _isMonitoring,
      'auto_sos': _autoSOS,
      'background_tracking': _backgroundTracking,
      'last_accelerometer': _lastAccelerometer != null ? {
        'x': _lastAccelerometer!.x,
        'y': _lastAccelerometer!.y,
        'z': _lastAccelerometer!.z,
      } : null,
      'last_gyroscope': _lastGyroscope != null ? {
        'x': _lastGyroscope!.x,
        'y': _lastGyroscope!.y,
        'z': _lastGyroscope!.z,
      } : null,
      'last_position': _lastPosition != null ? {
        'latitude': _lastPosition!.latitude,
        'longitude': _lastPosition!.longitude,
        'accuracy': _lastPosition!.accuracy,
        'timestamp': (_lastPosition!.timestamp ?? DateTime.now()).toIso8601String(),
      } : null,
      'is_user_inactive': isUserInactive(),
      'last_activity': _lastActivityTime?.toIso8601String(),
    };
  }

  Future<void> applyAdaptiveProfile({
    required double speed,
    required int batteryLevel,
    bool isIdle = false,
  }) async {
    _rideMode = speed > 25 || isIdle;
    _batterySaver = batteryLevel < 20;
    await StorageService.saveBool('ride_mode_enabled', _rideMode);
    await StorageService.saveBool('battery_saver_enabled', _batterySaver);
    notifyListeners();
  }

  @override
  void dispose() {
    stopMonitoring();
    super.dispose();
  }
}