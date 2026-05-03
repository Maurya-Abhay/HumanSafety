import 'dart:async';
import 'dart:convert';
import 'package:web_socket_channel/web_socket_channel.dart';
import 'package:web_socket_channel/status.dart' as status;
import 'geolocation_service.dart';

class AmbulanceTrackingService {
  static final AmbulanceTrackingService _instance = AmbulanceTrackingService._internal();

  factory AmbulanceTrackingService() {
    return _instance;
  }

  AmbulanceTrackingService._internal();

  WebSocketChannel? _channel;
  String? _userId;
  String? _token;
  bool _isConnected = false;
  late StreamController<AmbulanceLocationUpdate> locationUpdates;

  /// Initialize WebSocket connection
  Future<bool> connect(String wsUrl, String userId, String token) async {
    try {
      _userId = userId;
      _token = token;
      locationUpdates = StreamController<AmbulanceLocationUpdate>.broadcast();

      final fullUrl = '$wsUrl?userId=$userId&token=$token&role=hospital';
      _channel = WebSocketChannel.connect(Uri.parse(fullUrl));

      // Listen for messages
      _channel!.stream.listen(
        (dynamic message) => _handleMessage(message),
        onError: (error) => _handleError(error),
        onDone: () => _handleDone(),
      );

      _isConnected = true;
      print('✅ Ambulance tracking connected');
      return true;
    } catch (e) {
      print('❌ Failed to connect ambulance tracking: $e');
      return false;
    }
  }

  /// Send ambulance location update to server
  Future<void> sendLocationUpdate(
    String ambulanceId,
    double latitude,
    double longitude,
    double accuracy,
    String? eta,
    String? status,
  ) async {
    if (!_isConnected || _channel == null) return;

    try {
      _channel!.sink.add(jsonEncode({
        'type': 'ambulance_location_update',
        'ambulanceId': ambulanceId,
        'latitude': latitude,
        'longitude': longitude,
        'accuracy': accuracy,
        'eta': eta,
        'status': status,
        'timestamp': DateTime.now().toIso8601String(),
      }));
    } catch (e) {
      print('Error sending location update: $e');
    }
  }

  /// Subscribe to ambulance tracking channel
  Future<void> subscribeToAmbulanceTracking(String caseId) async {
    if (!_isConnected || _channel == null) return;

    try {
      _channel!.sink.add(jsonEncode({
        'type': 'subscribe',
        'channel': 'ambulance_$caseId',
      }));
    } catch (e) {
      print('Error subscribing to ambulance tracking: $e');
    }
  }

  /// Unsubscribe from ambulance tracking
  Future<void> unsubscribeFromAmbulanceTracking(String caseId) async {
    if (!_isConnected || _channel == null) return;

    try {
      _channel!.sink.add(jsonEncode({
        'type': 'unsubscribe',
        'channel': 'ambulance_$caseId',
      }));
    } catch (e) {
      print('Error unsubscribing from ambulance tracking: $e');
    }
  }

  /// Keep-alive ping
  Future<void> ping() async {
    if (!_isConnected || _channel == null) return;

    try {
      _channel!.sink.add(jsonEncode({'type': 'ping'}));
    } catch (e) {
      print('Error sending ping: $e');
    }
  }

  void _handleMessage(dynamic message) {
    try {
      final data = jsonDecode(message as String);
      final type = data['type'] as String?;

      if (type == 'AMBULANCE_LOCATION_UPDATE') {
        final location = AmbulanceLocationUpdate(
          ambulanceId: data['ambulanceId'] ?? '',
          latitude: (data['location']?['latitude'] ?? 0).toDouble(),
          longitude: (data['location']?['longitude'] ?? 0).toDouble(),
          accuracy: (data['location']?['accuracy'] ?? 0).toDouble(),
          eta: data['eta']?['estimatedMinutes'] ?? 0,
          status: data['status'] ?? 'unknown',
          timestamp: DateTime.parse(data['timestamp'] ?? DateTime.now().toIso8601String()),
        );
        locationUpdates.add(location);
      } else if (type == 'pong') {
        print('✓ Heartbeat acknowledged');
      } else if (type == 'ERROR') {
        print('⚠️ WebSocket error: ${data['message']}');
      }
    } catch (e) {
      print('Error handling WebSocket message: $e');
    }
  }

  void _handleError(dynamic error) {
    print('❌ WebSocket error: $error');
    _isConnected = false;
  }

  void _handleDone() {
    print('🔌 WebSocket connection closed');
    _isConnected = false;
  }

  /// Disconnect WebSocket
  Future<void> disconnect() async {
    try {
      await _channel?.sink.close(status.goingAway);
      await locationUpdates.close();
      _isConnected = false;
      print('Ambulance tracking disconnected');
    } catch (e) {
      print('Error disconnecting: $e');
    }
  }

  bool get isConnected => _isConnected;
  Stream<AmbulanceLocationUpdate> get locations => locationUpdates.stream;
}

class AmbulanceLocationUpdate {
  final String ambulanceId;
  final double latitude;
  final double longitude;
  final double accuracy;
  final int eta; // minutes
  final String status;
  final DateTime timestamp;

  AmbulanceLocationUpdate({
    required this.ambulanceId,
    required this.latitude,
    required this.longitude,
    required this.accuracy,
    required this.eta,
    required this.status,
    required this.timestamp,
  });

  double distanceTo(double lat, double lon) {
    return GeolocationService.calculateDistance(latitude, longitude, lat, lon);
  }
}
