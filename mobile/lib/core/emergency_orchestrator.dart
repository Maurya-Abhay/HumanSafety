import 'package:battery_plus/battery_plus.dart';
import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

import '../shared/models.dart' show Contact;
import 'api_service.dart' hide Contact;
import 'storage_service.dart';
import 'audio_service.dart';
import 'env_config.dart';

enum EmergencyDecision { silent, confirmationNeeded, autoTrigger }

class EmergencyOrchestrator extends ChangeNotifier {
  static final EmergencyOrchestrator _instance = EmergencyOrchestrator._internal();
  factory EmergencyOrchestrator() => _instance;
  EmergencyOrchestrator._internal();

  static const String _pendingAlertsKey = 'pending_emergency_alerts';
  static const String _falseAlertsKey = 'false_alert_count';
  static const int _maxQueueSize = 50; // Maximum queued alerts to prevent storage overflow

  final Battery _battery = Battery();
  bool _isOnline = true;
  int _batteryLevel = 100;
  int _falseAlertCount = 0;
  bool _rideMode = false;
  bool _batterySaver = false;

  bool get isOnline => _isOnline;
  int get batteryLevel => _batteryLevel;
  bool get rideMode => _rideMode;
  bool get batterySaver => _batterySaver;
  int get falseAlertCount => _falseAlertCount;

  /// Initialize and flush any pending alerts from previous sessions
  Future<void> initialize() async {
    _falseAlertCount = await StorageService.getInt(_falseAlertsKey) ?? 0;
    await refreshDeviceState();
    
    // CRITICAL: Flush pending alerts from previous sessions
    EnvConfig.debugPrint('Flushing pending alerts from previous session');
    await flushPendingAlerts();
  }

  Future<void> refreshDeviceState() async {
    try {
      _batteryLevel = await _battery.batteryLevel;
      _batterySaver = _batteryLevel < 20;
      notifyListeners();
    } catch (_) {
      _batteryLevel = 100;
      _batterySaver = false;
      notifyListeners();
    }
  }

  /// Evaluate confidence score and decide on alert handling
  EmergencyDecision evaluateConfidence(int confidenceScore) {
    final adjustedScore = confidenceScore - (_falseAlertCount * 5);
    if (adjustedScore < 40) return EmergencyDecision.silent;
    if (adjustedScore < 60) return EmergencyDecision.confirmationNeeded;
    return EmergencyDecision.autoTrigger;
  }

  Future<void> setRideMode({required double speed, required bool isIdle}) async {
    _rideMode = speed > 25 || isIdle;
    notifyListeners();
  }

  Future<void> setBatterySaver(int batteryLevel) async {
    _batteryLevel = batteryLevel;
    _batterySaver = batteryLevel < 20;
    notifyListeners();
  }

  Future<void> recordFalseAlert() async {
    _falseAlertCount += 1;
    await StorageService.saveInt(_falseAlertsKey, _falseAlertCount);
    EnvConfig.debugPrint('False alert recorded. Count: $_falseAlertCount');
    notifyListeners();
  }

  Future<void> recordAlertCancel(DateTime startedAt) async {
    if (DateTime.now().difference(startedAt).inSeconds <= 5) {
      await recordFalseAlert();
    }
  }

  /// Validate coordinates are in valid ranges
  bool _isValidCoordinate(double? lat, double? lon) {
    if (lat == null || lon == null) return false;
    return lat >= -90 && lat <= 90 && lon >= -180 && lon <= 180;
  }

  /// Trigger emergency alert with fallback to SMS if offline
  Future<CaseResponse> triggerEmergency({
    required String token,
    required double latitude,
    required double longitude,
    required int confidenceScore,
    String? description,
    Map<String, dynamic>? sensorData,
    List<Contact> emergencyContacts = const [],
  }) async {
    // Validate coordinates before proceeding
    if (!_isValidCoordinate(latitude, longitude)) {
      EnvConfig.debugPrint('Invalid coordinates: lat=$latitude, lon=$longitude');
      throw Exception('Invalid emergency location coordinates');
    }

    final decision = evaluateConfidence(confidenceScore);
    if (decision == EmergencyDecision.silent) {
      EnvConfig.debugPrint('Emergency suppressed by confidence rules (score: $confidenceScore)');
      return CaseResponse(
        caseId: 'suppressed-${DateTime.now().millisecondsSinceEpoch}',
        riskLevel: 'low',
        riskScore: confidenceScore,
        message: 'Automatic alert suppressed by confidence rules',
      );
    }

    if (_batterySaver) {
      sensorData ??= <String, dynamic>{};
      sensorData['battery_saver_mode'] = true;
    }

    // Collect audio data if available
    final audioService = AudioService();
    if (audioService.isListening) {
      final audioStats = audioService.getAudioStats();
      sensorData ??= <String, dynamic>{};
      sensorData['audio'] = {
        'current_level': audioStats['current_level'],
        'peak_level': audioStats['peak_level'],
        'noise_floor': audioStats['noise_floor'],
        'adaptive_threshold': audioStats['adaptive_threshold'],
      };
    }

    try {
      final response = await ApiService.createPanicAlert(
        token,
        latitude: latitude,
        longitude: longitude,
        description: description,
        sensorData: sensorData,
      );

      await _clearPendingAlerts();
      _isOnline = true;
      notifyListeners();
      
      EnvConfig.debugPrint('Emergency alert sent successfully. Case ID: ${response.caseId}');
      return response;
    } catch (e) {
      _isOnline = false;
      notifyListeners();

      EnvConfig.debugPrint('Emergency alert failed (offline), queuing for retry: $e');

      // Queue the alert for retry when online
      await _queuePendingAlert({
        'token': token,
        'latitude': latitude,
        'longitude': longitude,
        'confidenceScore': confidenceScore,
        'description': description,
        'sensorData': sensorData,
        'timestamp': DateTime.now().toIso8601String(),
      });

      // Launch SMS as fallback
      final message = _buildSmsMessage(
        latitude: latitude,
        longitude: longitude,
        description: description,
        confidenceScore: confidenceScore,
      );

      await _launchSmsComposer(
        phoneNumber: emergencyContacts.isNotEmpty ? emergencyContacts.first.phone : '112',
        message: message,
      );

      return CaseResponse(
        caseId: 'sms-${DateTime.now().millisecondsSinceEpoch}',
        riskLevel: confidenceScore >= 60 ? 'critical' : 'high',
        riskScore: confidenceScore,
        message: 'Internet unavailable. SMS fallback launched.',
      );
    }
  }

  /// Flush all pending alerts from offline queue
  Future<void> flushPendingAlerts() async {
    try {
      final queued = await StorageService.getJsonList(_pendingAlertsKey) ?? [];
      
      if (queued.isEmpty) {
        EnvConfig.debugPrint('No pending alerts to flush');
        return;
      }

      EnvConfig.debugPrint('Flushing ${queued.length} pending alerts');

      final remaining = <Map<String, dynamic>>[];
      int successCount = 0;

      for (final item in queued) {
        if (item is! Map) {
          EnvConfig.debugPrint('Skipping invalid queue item');
          continue;
        }

        final data = Map<String, dynamic>.from(item as Map);
        
        // Validate required fields
        final token = data['token'] as String?;
        final latitude = (data['latitude'] as num?)?.toDouble();
        final longitude = (data['longitude'] as num?)?.toDouble();
        final timestamp = data['timestamp'] as String?;

        if (token == null || latitude == null || longitude == null) {
          EnvConfig.debugPrint('Skipping alert with missing required fields');
          continue;
        }

        // Validate coordinates
        if (!_isValidCoordinate(latitude, longitude)) {
          EnvConfig.debugPrint('Skipping alert with invalid coordinates: lat=$latitude, lon=$longitude');
          continue;
        }

        // Check if alert is too old (>24 hours) and discard
        if (timestamp != null) {
          try {
            final alertTime = DateTime.parse(timestamp);
            final ageHours = DateTime.now().difference(alertTime).inHours;
            if (ageHours > 24) {
              EnvConfig.debugPrint('Discarding alert older than 24 hours');
              continue;
            }
          } catch (_) {
            // Invalid timestamp, discard
            continue;
          }
        }

        try {
          await ApiService.createPanicAlert(
            token,
            latitude: latitude,
            longitude: longitude,
            description: data['description'] as String?,
            sensorData: data['sensorData'] as Map<String, dynamic>?,
          );
          successCount++;
          EnvConfig.debugPrint('Successfully flushed pending alert');
        } catch (e) {
          EnvConfig.debugPrint('Failed to flush pending alert, re-queuing: $e');
          remaining.add(data);
        }
      }

      // Update queue with remaining items
      await StorageService.saveJsonList(_pendingAlertsKey, remaining);
      EnvConfig.debugPrint('Flush complete. Success: $successCount, Remaining: ${remaining.length}');
    } catch (e) {
      EnvConfig.debugPrint('Error during alert flush: $e');
    }
  }

  /// Queue an alert for retry when offline
  Future<void> _queuePendingAlert(Map<String, dynamic> payload) async {
    try {
      final queued = await StorageService.getJsonList(_pendingAlertsKey) ?? [];
      final items = queued.whereType<Map>().map((item) => Map<String, dynamic>.from(item)).toList();

      // Prevent queue overflow
      if (items.length >= _maxQueueSize) {
        EnvConfig.debugPrint('Alert queue full ($_maxQueueSize items), removing oldest');
        items.removeAt(0);
      }

      items.add(payload);
      await StorageService.saveJsonList(_pendingAlertsKey, items);
      EnvConfig.debugPrint('Alert queued for retry. Queue size: ${items.length}');
    } catch (e) {
      EnvConfig.debugPrint('Error queuing pending alert: $e');
    }
  }

  Future<void> _clearPendingAlerts() async {
    try {
      await StorageService.saveJsonList(_pendingAlertsKey, []);
      EnvConfig.debugPrint('Pending alerts cleared');
    } catch (e) {
      EnvConfig.debugPrint('Error clearing pending alerts: $e');
    }
  }

  String _buildSmsMessage({
    required double latitude,
    required double longitude,
    required int confidenceScore,
    String? description,
  }) {
    final locationLink = 'https://maps.google.com/?q=$latitude,$longitude';
    final confidenceLabel = confidenceScore >= 60 ? 'CRITICAL' : 'HIGH';
    return 'HumanSafety $confidenceLabel alert. ${description ?? 'Emergency assistance needed.'} Location: $locationLink';
  }

  Future<void> _launchSmsComposer({required String phoneNumber, required String message}) async {
    try {
      final uri = Uri.parse('sms:$phoneNumber?body=${Uri.encodeComponent(message)}');
      await launchUrl(uri, mode: LaunchMode.externalApplication);
      EnvConfig.debugPrint('SMS composer launched to $phoneNumber');
    } catch (e) {
      EnvConfig.debugPrint('Error launching SMS: $e');
    }
  }

  /// Reset false alert counter (e.g., after manual alert dismissal)
  Future<void> resetFalseAlertCount() async {
    _falseAlertCount = 0;
    await StorageService.saveInt(_falseAlertsKey, 0);
    EnvConfig.debugPrint('False alert counter reset');
    notifyListeners();
  }
}