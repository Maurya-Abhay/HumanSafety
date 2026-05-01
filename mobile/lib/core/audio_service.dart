import 'dart:async';
import 'dart:math';
import 'package:flutter/foundation.dart';

/// AudioService handles microphone monitoring for crash sound detection
/// Captures ambient sound levels and analyzes for crash signatures
class AudioService extends ChangeNotifier {
  static final AudioService _instance = AudioService._internal();
  factory AudioService() => _instance;
  AudioService._internal();

  // Audio monitoring state
  bool _isListening = false;
  double _currentAudioLevel = 0.0; // 0-100 dB scale approximation
  double _peakAudioLevel = 0.0;
  final List<double> _audioBuffer = [];
  final int _bufferSize = 50; // Rolling window for noise floor detection

  // Detection thresholds
  final double _crashSoundThreshold = 75.0; // dB threshold for crash detection
  final double _normalNoiseFloor = 40.0; // Expected ambient noise
  double _adaptiveThreshold = 75.0;

  // Timers
  Timer? _audioUpdateTimer;
  DateTime? _lastSoundPeak;

  // Callbacks
  Function(double level)? onAudioLevelChanged;
  Function(double peak, DateTime time)? onCrashSoundDetected;

  // Getters
  bool get isListening => _isListening;
  double get currentAudioLevel => _currentAudioLevel;
  double get peakAudioLevel => _peakAudioLevel;
  double get adaptiveThreshold => _adaptiveThreshold;

  /// Initialize audio service (check permissions, setup)
  Future<void> initialize() async {
    debugPrint('AudioService initialized');
    // In production, request microphone permission here
    // For now, using simulated audio levels
  }

  /// Start audio level monitoring
  Future<void> startListening() async {
    if (_isListening) return;

    try {
      _isListening = true;
      _audioUpdateTimer = Timer.periodic(
        Duration(milliseconds: 100),
        (_) => _simulateAudioCapture(),
      );
      notifyListeners();
      debugPrint('Audio listening started');
    } catch (e) {
      debugPrint('Failed to start audio listening: $e');
      _isListening = false;
    }
  }

  /// Stop audio monitoring
  Future<void> stopListening() async {
    if (!_isListening) return;

    _audioUpdateTimer?.cancel();
    _audioUpdateTimer = null;
    _isListening = false;
    _audioBuffer.clear();
    _peakAudioLevel = 0.0;
    notifyListeners();

    debugPrint('Audio listening stopped');
  }

  /// Simulate audio capture from microphone
  /// In production, this would use real microphone data via platform channel
  void _simulateAudioCapture() {
    // Generate realistic audio level simulation
    // Most of the time: ambient noise (40-60 dB)
    // Occasionally: spikes (70-90 dB)
    final baseNoise = _normalNoiseFloor + Random().nextDouble() * 10;
    final randomSpike = Random().nextDouble();

    double audioLevel;
    if (randomSpike > 0.95) {
      // 5% chance of spike (simulating sudden sound)
      audioLevel = _normalNoiseFloor + 30 + Random().nextDouble() * 20;
    } else {
      audioLevel = baseNoise;
    }

    _updateAudioLevel(audioLevel);
  }

  /// Update audio level and detect crashes
  void _updateAudioLevel(double level) {
    _currentAudioLevel = level.clamp(0, 100);

    // Add to rolling buffer for adaptive threshold calculation
    _audioBuffer.add(_currentAudioLevel);
    if (_audioBuffer.length > _bufferSize) {
      _audioBuffer.removeAt(0);
    }

    // Update peak
    if (_currentAudioLevel > _peakAudioLevel) {
      _peakAudioLevel = _currentAudioLevel;
      _lastSoundPeak = DateTime.now();
    }

    // Adaptive threshold: noise floor + margin
    if (_audioBuffer.isNotEmpty) {
      final avgNoise = _audioBuffer.reduce((a, b) => a + b) / _audioBuffer.length;
      _adaptiveThreshold = (avgNoise * 1.8).clamp(60, 85);
    }

    // Check for crash sound signature
    _detectCrashSound(_currentAudioLevel);

    onAudioLevelChanged?.call(_currentAudioLevel);
    notifyListeners();
  }

  /// Detect crash sound patterns
  void _detectCrashSound(double level) {
    if (level > _adaptiveThreshold) {
      // Potential crash sound detected
      onCrashSoundDetected?.call(level, DateTime.now());
      debugPrint('Crash sound detected: ${level.toStringAsFixed(1)} dB');
    }
  }

  /// Get current noise floor (average ambient noise)
  double getNoiseFloor() {
    if (_audioBuffer.isEmpty) return _normalNoiseFloor;
    return _audioBuffer.reduce((a, b) => a + b) / _audioBuffer.length;
  }

  /// Get audio statistics for emergency report
  Map<String, double> getAudioStats() {
    return {
      'current_level': _currentAudioLevel,
      'peak_level': _peakAudioLevel,
      'noise_floor': getNoiseFloor(),
      'adaptive_threshold': _adaptiveThreshold,
      'average_level': _audioBuffer.isNotEmpty
          ? _audioBuffer.reduce((a, b) => a + b) / _audioBuffer.length
          : 0.0,
    };
  }

  /// Record audio for crash detection (advanced feature)
  /// In production, would save audio buffer to file for later analysis
  Future<void> recordCrashAudio(int durationMs) async {
    debugPrint('Recording crash audio for ${durationMs}ms');
    // Audio recording would be implemented here
    // Save to assets/audio/crash_[timestamp].wav
  }

  @override
  void dispose() {
    _audioUpdateTimer?.cancel();
    super.dispose();
  }
}
