/// Singleton to track if app was launched due to SOS hardware trigger
/// This allows the app to navigate directly to SOS screen on startup
class SosLaunchController {
  static final SosLaunchController _instance = SosLaunchController._internal();
  factory SosLaunchController() => _instance;
  SosLaunchController._internal();

  String? _triggerSource;
  bool _shouldShowSosImmediately = false;

  void setSosTrigger(String source) {
    _triggerSource = source;
    _shouldShowSosImmediately = true;
  }

  bool get shouldShowSosImmediately => _shouldShowSosImmediately;
  String? get triggerSource => _triggerSource;

  void consumed() {
    _shouldShowSosImmediately = false;
    _triggerSource = null;
  }
}
