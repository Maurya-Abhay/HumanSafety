class HardwareSosTrigger {
  final String source;
  final DateTime armedAt;

  const HardwareSosTrigger({
    required this.source,
    required this.armedAt,
  });
}

class HardwareSosController {
  static HardwareSosTrigger? _pendingTrigger;

  static void arm(String source) {
    _pendingTrigger = HardwareSosTrigger(
      source: source,
      armedAt: DateTime.now(),
    );
  }

  static HardwareSosTrigger? consumePendingTrigger() {
    final trigger = _pendingTrigger;
    _pendingTrigger = null;
    return trigger;
  }

  static bool get hasPendingTrigger => _pendingTrigger != null;

  static void clear() {
    _pendingTrigger = null;
  }
}