import 'dart:async';
import 'dart:math' as math;
import 'package:flutter/foundation.dart';
import 'package:noise_meter/noise_meter.dart';

/// Real audio crash detection using device microphone via `noise_meter`
class AudioCrashDetection {
  static final AudioCrashDetection _instance = AudioCrashDetection._internal();
  factory AudioCrashDetection() => _instance;
  AudioCrashDetection._internal();

  bool _isMonitoring = false;
  final NoiseMeter _noiseMeter = NoiseMeter();
  StreamSubscription<NoiseReading>? _noiseSubscription;
  final StreamController<double> _decibelStream = StreamController<double>.broadcast();
  final StreamController<CrashDetectionResult> _crashStream = StreamController<CrashDetectionResult>.broadcast();

  // Configuration
  final double _crashThresholdDb = 80.0; // dB threshold for crash detection
  final double _impactThresholdDb = 90.0; // Peak dB for severe impact
  final int _bufferSize = 50; // Number of samples to keep for analysis

  List<double> _decibelBuffer = [];

  bool get isMonitoring => _isMonitoring;
  Stream<CrashDetectionResult> get crashDetectionStream => _crashStream.stream;
  Stream<double> get decibelStream => _decibelStream.stream;

  Future<void> initialize() async {
    debugPrint('🎤 Audio crash detection initialized (noise_meter)');
  }

  Future<void> startMonitoring() async {
    if (_isMonitoring) return;
    _isMonitoring = true;
    try {
      _noiseSubscription = _noiseMeter.noise.listen((NoiseReading reading) {
        final double db = reading.meanDecibel ?? reading.maxDecibel ?? 0.0;
        _processAudioLevel(db);
      }, onError: (error) {
        debugPrint('NoiseMeter error: $error');
      });
      debugPrint('🎤 Audio monitoring started (noise_meter)');
    } catch (e) {
      debugPrint('Failed to start audio monitoring: $e');
    }
  }

  Future<void> stopMonitoring() async {
    _isMonitoring = false;
    await _noiseSubscription?.cancel();
    _decibelBuffer.clear();
    debugPrint('🎤 Audio monitoring stopped');
  }

  void _processAudioLevel(double decibelLevel) {
    _decibelStream.add(decibelLevel);

    _decibelBuffer.add(decibelLevel);
    if (_decibelBuffer.length > _bufferSize) {
      _decibelBuffer.removeAt(0);
    }

    // Analyze every 500ms worth of samples if buffer has enough
    if (_decibelBuffer.length >= 5) {
      _analyzeBuffer();
    }
  }

  void _analyzeBuffer() {
    if (_decibelBuffer.isEmpty) return;

    final avgDecibel = _decibelBuffer.reduce((a, b) => a + b) / _decibelBuffer.length;
    final maxDecibel = _decibelBuffer.reduce(math.max);
    final minDecibel = _decibelBuffer.reduce(math.min);
    final variance = _calculateVariance(_decibelBuffer);

    double crashConfidence = 0;
    String reason = '';

    if (maxDecibel > _impactThresholdDb) {
      final peakExcess = (maxDecibel - _impactThresholdDb) / 20;
      crashConfidence += 40 * peakExcess.clamp(0, 1);
      reason += 'Peak impact ${maxDecibel.toStringAsFixed(1)} dB. ';
    }

    if (avgDecibel > _crashThresholdDb) {
      final avgExcess = (avgDecibel - _crashThresholdDb) / 20;
      crashConfidence += 30 * avgExcess.clamp(0, 1);
      reason += 'Sustained noise ${avgDecibel.toStringAsFixed(1)} dB. ';
    }

    if (variance > 100) {
      final varianceScore = math.min(variance / 200, 1.0);
      crashConfidence += 20 * varianceScore;
      reason += 'Rapid acoustic changes. ';
    }

    if (variance > 50) {
      crashConfidence += 10;
      reason += 'Abnormal noise pattern. ';
    }

    final result = CrashDetectionResult(
      confidence: crashConfidence.clamp(0, 100),
      reason: reason.isEmpty ? 'Normal environment' : reason.trim(),
      avgDecibel: avgDecibel,
      maxDecibel: maxDecibel,
      minDecibel: minDecibel,
      variance: variance,
      timestamp: DateTime.now(),
    );

    _crashStream.add(result);

    if (crashConfidence > 50) {
      debugPrint('🎤 Potential crash detected! Confidence: ${crashConfidence.toStringAsFixed(1)}% (Max: ${maxDecibel.toStringAsFixed(1)}dB, Avg: ${avgDecibel.toStringAsFixed(1)}dB)');
    }
  }

  double _calculateVariance(List<double> values) {
    if (values.isEmpty) return 0;
    final mean = values.reduce((a, b) => a + b) / values.length;
    final squared = values.map((x) => math.pow(x - mean, 2));
    double sum = 0;
    for (var v in squared) sum += v as double;
    return sum / values.length;
  }

  Map<String, dynamic> getAudioStatus() {
    if (_decibelBuffer.isEmpty) {
      return {'isMonitoring': _isMonitoring, 'currentDb': 0, 'averageDb': 0, 'status': 'no_data'};
    }
    final avg = _decibelBuffer.reduce((a, b) => a + b) / _decibelBuffer.length;
    final max = _decibelBuffer.reduce(math.max);
    return {'isMonitoring': _isMonitoring, 'currentDb': _decibelBuffer.last, 'averageDb': avg, 'maxDb': max, 'status': max > _impactThresholdDb ? 'elevated' : 'normal'};
  }

  Future<void> dispose() async {
    await _noiseSubscription?.cancel();
    await _decibelStream.close();
    await _crashStream.close();
  }
}

class CrashDetectionResult {
  final double confidence; // 0-100
  final String reason;
  final double avgDecibel;
  final double maxDecibel;
  final double minDecibel;
  final double variance;
  final DateTime timestamp;

  CrashDetectionResult({required this.confidence, required this.reason, required this.avgDecibel, required this.maxDecibel, required this.minDecibel, required this.variance, required this.timestamp});

  bool get isCrash => confidence > 70;
  bool get isPotentialCrash => confidence > 50;

  @override
  String toString() => 'CrashDetection(confidence: $confidence, reason: $reason, avg: ${avgDecibel.toStringAsFixed(1)}dB)';
}
