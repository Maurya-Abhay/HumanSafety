import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:geolocator/geolocator.dart';
import 'hardware_buttons.dart';
import 'storage_service.dart';
import 'api_service.dart';
import 'sensor_service.dart';

// Listens to hardware volume button and detects triple-press for SOS.
class ButtonListenerService {
  static final ButtonListenerService _instance = ButtonListenerService._internal();
  factory ButtonListenerService() => _instance;
  ButtonListenerService._internal();

  StreamSubscription? _volumeDownSub;
  StreamSubscription? _volumeUpSub;
  final List<int> _pressTimestamps = [];
  final int _sequenceWindowMs = 1500; // triple press within 1.5s
  final int _requiredPresses = 3;

  bool _enabled = true;

  Future<void> initialize() async {
    _enabled = await StorageService.getBool('enable_hardware_sos') ?? true;
    if (!_enabled) return;

    try {
      // Subscribe to volume down button events (common for SOS triggers)
      _volumeDownSub = HardwareButtons.volumeDownButton.listen((_) {
        _onButtonPressed();
      });
      
      debugPrint('ButtonListenerService: hardware volume button stream attached');
    } catch (e) {
      debugPrint('ButtonListenerService: failed to attach to hardware stream: $e');
    }
  }

  void _onButtonPressed() async {
    if (!_enabled) return;
    final now = DateTime.now().millisecondsSinceEpoch;
    _pressTimestamps.add(now);
    // Remove old timestamps
    _pressTimestamps.retainWhere((ts) => now - ts <= _sequenceWindowMs);
    if (_pressTimestamps.length >= _requiredPresses) {
      _pressTimestamps.clear();
      await _triggerSOS();
    }
  }

  Future<void> _triggerSOS() async {
    try {
      final token = await ApiService.getValidToken();
      if (token == null) {
        debugPrint('ButtonListenerService: no token available, skipping SOS');
        return;
      }

      // Try to get best recent position from SensorService, else fallback to Geolocator
      Position? pos = SensorService().lastPosition;
      if (pos == null) {
        try {
          pos = await Geolocator.getCurrentPosition(desiredAccuracy: LocationAccuracy.high).timeout(Duration(seconds: 5));
        } catch (e) {
          debugPrint('ButtonListenerService: failed to get location: $e');
        }
      }

      await ApiService.createPanicAlert(
        token,
        latitude: pos?.latitude ?? 0.0,
        longitude: pos?.longitude ?? 0.0,
        description: 'SOS triggered via hardware volume button',
        sensorData: {'trigger': 'hardware_volume_button'},
      );

      debugPrint('ButtonListenerService: SOS sent');
    } catch (e) {
      debugPrint('ButtonListenerService: failed to send SOS: $e');
    }
  }

  Future<void> setEnabled(bool enabled) async {
    _enabled = enabled;
    await StorageService.saveBool('enable_hardware_sos', enabled);
  }

  Future<bool> isEnabled() async {
    return _enabled;
  }

  Future<void> dispose() async {
    await _volumeDownSub?.cancel();
    await _volumeUpSub?.cancel();
  }
}
