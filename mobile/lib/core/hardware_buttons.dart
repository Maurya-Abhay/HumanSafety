import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

// Android bridge for hardware volume button events.
// On non-Android targets it intentionally stays empty so the app still runs.
class HardwareButtons {
  static const EventChannel _channel = EventChannel('humansafety/hardware_buttons');

  static Stream<dynamic>? _sharedEvents;

  static bool get _isAndroid => !kIsWeb && defaultTargetPlatform == TargetPlatform.android;

  static Stream<dynamic> get _events {
    if (!_isAndroid) {
      return const Stream<dynamic>.empty();
    }

    return _sharedEvents ??= _channel.receiveBroadcastStream().asBroadcastStream();
  }

  static Stream<void> get volumeDownButton => _events
      .where((event) => event is Map && event['key'] == 'volume_down')
      .map<void>((_) {});

  static Stream<void> get volumeUpButton => _events
      .where((event) => event is Map && event['key'] == 'volume_up')
      .map<void>((_) {});
}
