import 'package:flutter/foundation.dart';
import 'package:audioplayers/audioplayers.dart';

class PortalSoundService extends ChangeNotifier {
  static final PortalSoundService _instance = PortalSoundService._internal();
  factory PortalSoundService() => _instance;
  PortalSoundService._internal();

  final AudioPlayer _player = AudioPlayer();
  bool _isMuted = false;
  String? _lastPlayed;

  bool get isMuted => _isMuted;
  String? get lastPlayed => _lastPlayed;

  Future<void> initialize() async {
    await _player.setReleaseMode(ReleaseMode.stop);
  }

  Future<void> setMuted(bool muted) async {
    _isMuted = muted;
    notifyListeners();
  }

  Future<void> playNotification() => _playAsset('notification_ping.mp3');
  Future<void> playAlert() => _playAsset('short_alert_beep.mp3');
  Future<void> playSiren({bool loop = true}) => _playAsset('siren_alarm.mp3', loop: loop);
  Future<void> playCrash() => _playAsset('car_crash_impact.mp3');
  Future<void> playVehicleCollision() => _playAsset('vehicle_collision.mp3');

  Future<void> playForPortal(String portal, {bool urgent = false}) async {
    final normalized = portal.toLowerCase();
    if (urgent) {
      await playSiren();
      return;
    }

    switch (normalized) {
      case 'police':
      case 'hospital':
        await playAlert();
        break;
      case 'admin':
        await playNotification();
        break;
      case 'user':
      default:
        await playNotification();
        break;
    }
  }

  Future<void> _playAsset(String assetName, {bool loop = false}) async {
    if (_isMuted) return;

    try {
      _lastPlayed = assetName;
      notifyListeners();
      await _player.stop();
      await _player.setReleaseMode(loop ? ReleaseMode.loop : ReleaseMode.stop);
      await _player.play(AssetSource('audio/$assetName'));
    } catch (e) {
      debugPrint('PortalSoundService error: $e');
    }
  }

  Future<void> stop() async {
    await _player.stop();
  }

  @override
  void dispose() {
    _player.dispose();
    super.dispose();
  }
}
