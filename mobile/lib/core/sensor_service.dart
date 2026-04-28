import 'dart:async';
import 'dart:math';
import 'package:sensors_plus/sensors_plus.dart';
import 'package:geolocator/geolocator.dart';
import 'package:flutter/foundation.dart';
import 'api_service.dart';
import 'storage_service.dart';
import 'constants.dart';

class SensorService extends ChangeNotifier {
  static final SensorService _instance = SensorService._internal();
  factory SensorService() => _instance;
  SensorService._internal();

  // Sensor streams
  StreamSubscription<AccelerometerEvent>? _accelerometerSubscription;
  StreamSubscription<GyroscopeEvent>? _gyroscopeSubscription;
  StreamSubscription<Position>? _positionSubscription;

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
  AccelerometerEvent? get lastAccelerometer => _lastAccelerometer;
  Position? get lastPosition => _lastPosition;

  Future<void> initialize() async {
    await _loadSettings();
  }

  Future<void> _loadSettings() async {
    _autoSOS = await StorageService.getBool('enable_auto_sos') ?? true;
    _backgroundTracking = await StorageService.getBool('enable_background_tracking') ?? false;
    // _impactThreshold is final and set at declaration
  }

  Future<void> startMonitoring() async {
    if (_isMonitoring) return;

    try {
      // Check permissions
      final accelerometerGranted = await _checkAccelerometerPermission();
      final locationGranted = await _checkLocationPermission();

      if (!accelerometerGranted) {
        debugPrint('Accelerometer permission denied');
        return;
      }

      // Start accelerometer monitoring
      _accelerometerSubscription = accelerometerEvents.listen(
        _onAccelerometerEvent,
        onError: (error) => debugPrint('Accelerometer error: $error'),
      );

      // Start gyroscope monitoring
      _gyroscopeSubscription = gyroscopeEvents.listen(
        _onGyroscopeEvent,
        onError: (error) => debugPrint('Gyroscope error: $error'),
      );

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
    await _stopLocationTracking();

    _accelerometerSubscription = null;
    _gyroscopeSubscription = null;
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
    // Simple accident detection logic
    // In production, this would use the AI engine
    if (magnitude > _impactThreshold * 1.5) { // Severe impact
      if (_autoSOS) {
        _triggerAutoSOS(magnitude);
      }
      onAccidentDetected?.call();
    }
  }

  Future<void> _triggerAutoSOS(double magnitude) async {
    try {
      final token = await StorageService.getString(AppConstants.tokenKey);
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

  Future<bool> _checkLocationPermission() async {
    final permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      final result = await Geolocator.requestPermission();
      return result == LocationPermission.whileInUse ||
             result == LocationPermission.always;
    }
    return permission == LocationPermission.whileInUse ||
           permission == LocationPermission.always;
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
        'timestamp': _lastPosition!.timestamp.toIso8601String(),
      } : null,
      'is_user_inactive': isUserInactive(),
      'last_activity': _lastActivityTime?.toIso8601String(),
    };
  }

  @override
  void dispose() {
    stopMonitoring();
    super.dispose();
  }
}