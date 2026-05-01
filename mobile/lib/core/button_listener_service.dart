import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'hardware_buttons.dart';
import 'storage_service.dart';
import 'hardware_sos_controller.dart';
import 'navigation_service.dart';
import 'routes.dart';

// Listens to hardware volume button and detects triple-press for SOS.
// Also listens to sos_triggered events from native AccessibilityKeyService.
class ButtonListenerService {
  static final ButtonListenerService _instance = ButtonListenerService._internal();
  factory ButtonListenerService() => _instance;
  ButtonListenerService._internal();

  StreamSubscription? _volumeDownSub;
  StreamSubscription? _volumeUpSub;
  StreamSubscription? _sosTriggeredSub;

  bool _enabled = true;

  Future<void> initialize() async {
    _enabled = await StorageService.getBool('enable_hardware_sos') ?? true;
    if (!_enabled) return;

    try {
      // Listen for sos_triggered events from native AccessibilityKeyService
      const platform = EventChannel('humansafety/hardware_buttons');
      _sosTriggeredSub = platform.receiveBroadcastStream().listen((event) {
        if (event is Map && event['key'] == 'sos_triggered') {
          _onSosTriggered(event['source'] ?? 'volume_down');
        }
      });

      debugPrint('ButtonListenerService: listening for hardware SOS triggers');
    } catch (e) {
      debugPrint('ButtonListenerService: failed to attach to hardware stream: $e');
    }
  }

  Future<void> _onSosTriggered(String source) async {
    if (!_enabled) return;
    
    try {
      HardwareSosController.arm(source);
      final pushed = AppNavigationService.navigatorKey.currentState?.pushNamed(AppRoutes.sos);
      if (pushed == null) {
        // App is backgrounded or navigator not ready — ask native Android to bring app to foreground
        try {
          const platform = MethodChannel('humansafety/hardware_actions');
          await platform.invokeMethod('bringToForeground', {'source': source});
        } catch (e) {
          debugPrint('ButtonListenerService: failed to call native bringToForeground: $e');
        }
      }

      debugPrint('ButtonListenerService: armed hardware SOS from $source');
    } catch (e) {
      debugPrint('ButtonListenerService: failed to arm SOS: $e');
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
    await _sosTriggeredSub?.cancel();
  }
}
