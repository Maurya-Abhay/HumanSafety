import 'dart:async';

// Local stub for hardware_buttons plugin so web/desktop builds compile.
// Replace with the actual plugin or platform-specific implementation
// when targeting Android/iOS devices and when the plugin is available.
class HardwareButtons {
  // Streams emit nothing by default; they exist so code referencing them compiles.
  static Stream<void> get volumeDownButton => const Stream<void>.empty();
  static Stream<void> get volumeUpButton => const Stream<void>.empty();
}
