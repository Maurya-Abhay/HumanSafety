import 'dart:async';
import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart' as geo;
import 'api_service.dart';
import 'storage_service.dart';
import 'constants.dart';
import 'env_config.dart';

class BackgroundService {
  static Timer? _locationTimer;
  static bool _isRunning = false;
  static const String _pendingLocationKey = 'pending_location_updates';
  static int _consecutiveErrors = 0;
  static const int _maxConsecutiveErrors = 5;

  static Future<void> initialize() async {
    // Basic initialization
  }

  static Future<bool> isServiceRunning() async {
    return _isRunning;
  }

  static Future<void> startLocationService() async {
    if (_isRunning) return;

    _isRunning = true;
    _consecutiveErrors = 0;

    // Start periodic location updates (10 seconds - from EnvConfig)
    final updateInterval = Duration(milliseconds: EnvConfig.locationUpdateInterval);
    
    _locationTimer = Timer.periodic(updateInterval, (timer) async {
      try {
        await _updateLocation();
        // Reset error counter on success
        _consecutiveErrors = 0;
      } catch (e) {
        _consecutiveErrors++;
        EnvConfig.debugPrint('Background location update error ($_consecutiveErrors/$_maxConsecutiveErrors): $e');
        
        // Stop service if too many consecutive errors
        if (_consecutiveErrors >= _maxConsecutiveErrors) {
          EnvConfig.debugPrint('Stopping location service due to too many errors');
          await stopLocationService();
        }
      }
    });

    EnvConfig.debugPrint('Background location service started (interval: ${updateInterval.inSeconds}s)');
  }

  static Future<void> stopLocationService() async {
    _locationTimer?.cancel();
    _locationTimer = null;
    _isRunning = false;
    _consecutiveErrors = 0;
    EnvConfig.debugPrint('Background location service stopped');
  }

  static Future<void> updateNotification(String title, String message) async {
    EnvConfig.debugPrint('Notification update: $title - $message');
  }

  static Future<void> _updateLocation() async {
    try {
      // Flush pending updates first
      await _flushPendingLocationUpdates();

      // Get current position with timeout
      final position = await geo.Geolocator.getCurrentPosition(
        desiredAccuracy: geo.LocationAccuracy.high,
        timeLimit: Duration(seconds: 10),
      ).timeout(
        Duration(seconds: 15),
        onTimeout: () => throw TimeoutException('Location acquisition timeout'),
      );

      // Validate coordinates
      if (!_isValidCoordinate(position.latitude, position.longitude)) {
        throw FormatException('Invalid coordinates: lat=${position.latitude}, lon=${position.longitude}');
      }

      // Send location update to backend
      await _sendLocationUpdate(position);

      // Check for emergency conditions
      await _checkEmergencyConditions(position);
    } catch (e) {
      EnvConfig.debugPrint('Location update error: $e');
      rethrow;
    }
  }

  /// Validate latitude and longitude ranges
  static bool _isValidCoordinate(double latitude, double longitude) {
    return latitude >= -90 && latitude <= 90 && longitude >= -180 && longitude <= 180;
  }

  static Future<void> _sendLocationUpdate(geo.Position position) async {
    try {
      final token = await StorageService.getString(AppConstants.tokenKey);
      if (token == null) {
        throw Exception('No authentication token available');
      }

      // Ensure accuracy is non-negative
      final accuracy = position.accuracy >= 0 ? position.accuracy : 0.0;

      await ApiService.updateLocation(
        token,
        position.latitude,
        position.longitude,
        accuracy,
      );

      EnvConfig.debugPrint('Location updated: lat=${position.latitude}, lon=${position.longitude}, accuracy=$accuracy');
    } catch (e) {
      EnvConfig.debugPrint('Failed to send location update: $e');
      await _queueLocationUpdate(position);
      rethrow;
    }
  }

  static Future<void> _queueLocationUpdate(geo.Position position) async {
    try {
      // Validate before queuing
      if (!_isValidCoordinate(position.latitude, position.longitude)) {
        EnvConfig.debugPrint('Discarding invalid coordinates from queue');
        return;
      }

      final queued = await StorageService.getJsonList(_pendingLocationKey) ?? [];
      final items = queued.whereType<Map>().map((item) => Map<String, dynamic>.from(item)).toList();
      
      items.add({
        'latitude': position.latitude,
        'longitude': position.longitude,
        'accuracy': position.accuracy >= 0 ? position.accuracy : 0.0,
        'timestamp': (position.timestamp ?? DateTime.now()).toIso8601String(),
      });

      // Limit queue size to prevent storage overflow
      if (items.length > 100) {
        EnvConfig.debugPrint('Location queue exceeded 100 items, removing oldest');
        items.removeAt(0);
      }

      await StorageService.saveJsonList(_pendingLocationKey, items);
      EnvConfig.debugPrint('Location queued for retry. Queue size: ${items.length}');
    } catch (e) {
      EnvConfig.debugPrint('Failed to queue location update: $e');
    }
  }

  static Future<void> _flushPendingLocationUpdates() async {
    try {
      final token = await StorageService.getString(AppConstants.tokenKey);
      final queued = await StorageService.getJsonList(_pendingLocationKey) ?? [];
      
      if (token == null || queued.isEmpty) {
        return;
      }

      final remaining = <Map<String, dynamic>>[];
      int successCount = 0;

      for (final item in queued) {
        if (item is! Map) continue;
        final data = Map<String, dynamic>.from(item as Map);
        
        final latitude = (data['latitude'] as num?)?.toDouble();
        final longitude = (data['longitude'] as num?)?.toDouble();
        final accuracy = (data['accuracy'] as num?)?.toDouble() ?? 0.0;
        
        // Validate coordinates
        if (latitude == null || longitude == null || !_isValidCoordinate(latitude, longitude)) {
          EnvConfig.debugPrint('Skipping invalid queued location: lat=$latitude, lon=$longitude');
          continue;
        }

        try {
          await ApiService.updateLocation(token, latitude, longitude, accuracy);
          successCount++;
        } catch (e) {
          EnvConfig.debugPrint('Failed to flush queued location, re-queuing: $e');
          remaining.add(data);
        }
      }

      // Update queue with remaining items
      await StorageService.saveJsonList(_pendingLocationKey, remaining);
      
      if (successCount > 0) {
        EnvConfig.debugPrint('Flushed $successCount pending locations. Remaining: ${remaining.length}');
      }
    } catch (e) {
      EnvConfig.debugPrint('Error flushing pending location updates: $e');
    }
  }

  static Future<void> _checkEmergencyConditions(geo.Position position) async {
    try {
      final lastPosition = await _getLastKnownPosition();
      if (lastPosition != null) {
        final distance = geo.Geolocator.distanceBetween(
          lastPosition.latitude,
          lastPosition.longitude,
          position.latitude,
          position.longitude,
        );

        // Check inactivity (vehicle not moving)
        if (distance < 5.0) {
          await _checkInactivityEmergency(position);
        }
      }

      await _storePosition(position);
    } catch (e) {
      EnvConfig.debugPrint('Emergency check error: $e');
    }
  }

  static Future<void> _checkInactivityEmergency(geo.Position position) async {
    try {
      final lastActivity = await StorageService.getString('last_activity_time');
      if (lastActivity != null) {
        final lastActivityTime = DateTime.tryParse(lastActivity);
        if (lastActivityTime != null) {
          final inactiveDuration = DateTime.now().difference(lastActivityTime);
          final inactiveMinutes = inactiveDuration.inMinutes;

          if (inactiveMinutes > EnvConfig.inactivityThreshold) {
            await _sendInactivityAlert(position, inactiveMinutes);
          }
        }
      }
    } catch (e) {
      EnvConfig.debugPrint('Inactivity check error: $e');
    }
  }

  static Future<void> _sendInactivityAlert(geo.Position position, int minutes) async {
    try {
      final token = await StorageService.getString(AppConstants.tokenKey);
      if (token == null) return;

      await ApiService.createPanicAlert(
        token,
        latitude: position.latitude,
        longitude: position.longitude,
        description: 'Inactivity alert: No movement detected for $minutes minutes',
        sensorData: {
          'inactivity_minutes': minutes,
          'background_triggered': true,
        },
      );

      EnvConfig.debugPrint('Inactivity alert sent after $minutes minutes');
    } catch (e) {
      EnvConfig.debugPrint('Failed to send inactivity alert: $e');
    }
  }

  static Future<geo.Position?> _getLastKnownPosition() async {
    try {
      final latStr = await StorageService.getString('last_latitude');
      final lngStr = await StorageService.getString('last_longitude');
      final timeStr = await StorageService.getString('last_position_time');

      if (latStr != null && lngStr != null && timeStr != null) {
        final lat = double.tryParse(latStr);
        final lng = double.tryParse(lngStr);
        final time = DateTime.tryParse(timeStr);

        if (lat != null && lng != null && time != null && _isValidCoordinate(lat, lng)) {
          return geo.Position(
            latitude: lat,
            longitude: lng,
            timestamp: time,
            accuracy: 0,
            altitude: 0,
            heading: 0,
            speed: 0,
            speedAccuracy: 0,
            altitudeAccuracy: 0,
            headingAccuracy: 0,
          );
        }
      }
    } catch (e) {
      EnvConfig.debugPrint('Failed to get last position: $e');
    }
    return null;
  }

  static Future<void> _storePosition(geo.Position position) async {
    try {
      await StorageService.saveString('last_latitude', position.latitude.toString());
      await StorageService.saveString('last_longitude', position.longitude.toString());
      await StorageService.saveString('last_position_time', (position.timestamp ?? DateTime.now()).toIso8601String());
    } catch (e) {
      EnvConfig.debugPrint('Failed to store position: $e');
    }
  }
}

class BackgroundServiceCallback {
  static Future<void> initCallback(Map<dynamic, dynamic> params) async {
    EnvConfig.debugPrint('Background service initialized');
  }

  static Future<void> disposeCallback() async {
    EnvConfig.debugPrint('Background service disposed');
  }

  static Future<void> callback(dynamic locationDto) async {
    EnvConfig.debugPrint('Background callback received');
  }
}
