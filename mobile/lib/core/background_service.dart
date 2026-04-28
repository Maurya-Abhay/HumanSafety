import 'dart:async';
import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart' as geo;
import 'api_service.dart';
import 'storage_service.dart';
import 'constants.dart';

class BackgroundService {
  static Timer? _locationTimer;
  static bool _isRunning = false;

  static Future<void> initialize() async {
    // Basic initialization
  }

  static Future<bool> isServiceRunning() async {
    return _isRunning;
  }

  static Future<void> startLocationService() async {
    if (_isRunning) return;

    _isRunning = true;

    // Start periodic location updates (every 5 minutes)
    _locationTimer = Timer.periodic(const Duration(minutes: 5), (timer) async {
      try {
        await _updateLocation();
      } catch (e) {
        debugPrint('Background location update error: $e');
      }
    });

    debugPrint('Background location service started');
  }

  static Future<void> stopLocationService() async {
    _locationTimer?.cancel();
    _locationTimer = null;
    _isRunning = false;
    debugPrint('Background location service stopped');
  }

  static Future<void> updateNotification(String title, String message) async {
    debugPrint('Notification update: $title - $message');
  }

  static Future<void> _updateLocation() async {
    try {
      final position = await geo.Geolocator.getCurrentPosition(
        desiredAccuracy: geo.LocationAccuracy.high,
      );

      // Send location update to backend
      await _sendLocationUpdate(position);

      // Check for emergency conditions
      await _checkEmergencyConditions(position);

    } catch (e) {
      debugPrint('Location update error: $e');
    }
  }

  static Future<void> _sendLocationUpdate(geo.Position position) async {
    try {
      final token = await StorageService.getString(AppConstants.tokenKey);
      if (token == null) return;

      await ApiService.updateLocation(
        token,
        position.latitude,
        position.longitude,
        position.accuracy,
      );
    } catch (e) {
      debugPrint('Failed to send location update: $e');
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

        if (distance < 5.0) {
          await _checkInactivityEmergency(position);
        }
      }

      await _storePosition(position);

    } catch (e) {
      debugPrint('Emergency check error: $e');
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

          if (inactiveMinutes > 30) {
            await _sendInactivityAlert(position, inactiveMinutes);
          }
        }
      }
    } catch (e) {
      debugPrint('Inactivity check error: $e');
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

      debugPrint('Inactivity alert sent after $minutes minutes');
    } catch (e) {
      debugPrint('Failed to send inactivity alert: $e');
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

        if (lat != null && lng != null && time != null) {
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
      debugPrint('Failed to get last position: $e');
    }
    return null;
  }

  static Future<void> _storePosition(geo.Position position) async {
    try {
      await StorageService.saveString('last_latitude', position.latitude.toString());
      await StorageService.saveString('last_longitude', position.longitude.toString());
      await StorageService.saveString('last_position_time', position.timestamp.toIso8601String());
    } catch (e) {
      debugPrint('Failed to store position: $e');
    }
  }
}

class BackgroundServiceCallback {
  static Future<void> initCallback(Map<dynamic, dynamic> params) async {
    debugPrint('Background service initialized');
  }

  static Future<void> disposeCallback() async {
    debugPrint('Background service disposed');
  }

  static Future<void> callback(dynamic locationDto) async {
    debugPrint('Background callback received');
  }
}