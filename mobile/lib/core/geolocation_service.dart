import 'package:geolocator/geolocator.dart';
import 'dart:async';
import 'dart:math' as math;

class GeolocationService {
  static final GeolocationService _instance = GeolocationService._internal();

  factory GeolocationService() {
    return _instance;
  }

  GeolocationService._internal();

  StreamSubscription<Position>? _positionStream;
  final List<Function(Position)> _listeners = [];

  /// Check location permissions and request if needed
  static Future<bool> requestLocationPermission() async {
    try {
      LocationPermission permission = await Geolocator.checkPermission();

      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) {
          return false;
        }
      }

      if (permission == LocationPermission.deniedForever) {
        await Geolocator.openLocationSettings();
        return false;
      }

      return permission == LocationPermission.whileInUse ||
          permission == LocationPermission.always;
    } catch (e) {
      print('Error requesting location permission: $e');
      return false;
    }
  }

  /// Get current position once
  static Future<Position?> getCurrentLocation() async {
    try {
      final hasPermission = await requestLocationPermission();
      if (!hasPermission) return null;

      final position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.best,
        timeLimit: const Duration(seconds: 10),
      );
      return position;
    } catch (e) {
      print('Error getting location: $e');
      return null;
    }
  }

  /// Start continuous location updates
  void startTracking({
    required Function(Position) onLocationUpdate,
    LocationAccuracy accuracy = LocationAccuracy.best,
    int intervalMillis = 3000, // Update every 3 seconds
    int distanceFilterMeters = 10, // Only update if moved 10m+
  }) {
    _listeners.add(onLocationUpdate);

    if (_positionStream != null) {
      return; // Already tracking
    }

    _positionStream = Geolocator.getPositionStream(
      locationSettings: LocationSettings(
        accuracy: accuracy,
        distanceFilter: distanceFilterMeters,
      ),
    ).listen((Position position) {
      // Notify all listeners
      for (var listener in _listeners) {
        listener(position);
      }
    }, onError: (error) {
      print('Geolocation error: $error');
    });
  }

  /// Stop continuous tracking
  void stopTracking() {
    _positionStream?.cancel();
    _positionStream = null;
    _listeners.clear();
  }

  /// Calculate distance between two points (Haversine formula)
  static double calculateDistance(
    double lat1,
    double lon1,
    double lat2,
    double lon2,
  ) {
    const p = 0.017453292519943295; // Math.PI / 180
    final a = 0.5 -
        math.cos((lat2 - lat1) * p) / 2 +
        math.cos(lat1 * p) *
            math.cos(lat2 * p) *
            (1 - math.cos((lon2 - lon1) * p)) /
            2;
    return 12742 * math.asin(math.sqrt(a)); // 2 * R; R = 6371 km
  }

  /// Calculate ETA in minutes
  static int calculateETA(double distanceKm, {double speedKmh = 40}) {
    if (speedKmh <= 0) return 0;
    final hours = distanceKm / speedKmh;
    return (hours * 60).ceil();
  }
}
