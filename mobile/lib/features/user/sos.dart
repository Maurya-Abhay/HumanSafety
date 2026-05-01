import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:geolocator/geolocator.dart';
import '../../shared/widgets.dart';
import '../../core/theme.dart';
import '../../core/api_service.dart';
import '../../core/emergency_orchestrator.dart';
import '../../core/sensor_service.dart';
import '../../core/audio_service.dart';
import '../../core/background_service.dart';
import '../../core/routes.dart';
import '../../core/page_transitions.dart';
import '../../shared/models.dart';
import './notifications.dart';
import './profile.dart';

class SOSScreen extends StatefulWidget {
  const SOSScreen({super.key});

  @override
  State<SOSScreen> createState() => _SOSScreenState();
}

class _SOSScreenState extends State<SOSScreen> with TickerProviderStateMixin {
  bool _sosActive = false;
  CaseResponse? _caseResponse;
  bool _sensorMonitoring = false;
  DateTime? _activationStartedAt;
  bool _smartConfirmationShown = false;

  // Animation Controllers for Premium Effects
  late AnimationController _pulseController;
  late AnimationController _holdController;
  late AnimationController _blastController;

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(
      duration: const Duration(milliseconds: 1500),
      vsync: this,
    )..repeat(reverse: true);

    _holdController = AnimationController(
      duration: const Duration(seconds: 3),
      vsync: this,
    );

    _blastController = AnimationController(
      duration: const Duration(milliseconds: 600),
      vsync: this,
    );

    _requestLocationPermission();
    _initializeSensorService();
  }

  @override
  void dispose() {
    _pulseController.dispose();
    _holdController.dispose();
    _blastController.dispose();
    super.dispose();
  }

  void _onTapDown(TapDownDetails details) {
    _holdController.forward();
  }

  void _onTapUp(TapUpDetails details) {
    if (_holdController.value >= 1.0) {
      _triggerIntenseSOS();
    } else {
      _holdController.reverse();
    }
  }

  void _onTapCancel() {
    _holdController.reverse();
  }

  Future<void> _triggerIntenseSOS() async {
    _blastController.forward(from: 0.0);
    _activationStartedAt = DateTime.now();

    if (!mounted) return;
    setState(() {
      _sosActive = true;
      _smartConfirmationShown = false;
    });

    try {
      final position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
      );
      if (!mounted) return;

      final authProvider = context.read<AuthProvider>();
      final token = authProvider.token;
      if (token == null) {
        throw Exception('Please login again before sending SOS');
      }

      final confidenceScore = context.read<SensorService>().isMonitoring ? 72 : 88;
      final orchestrator = context.read<EmergencyOrchestrator>();

      if (orchestrator.evaluateConfidence(confidenceScore) == EmergencyDecision.confirmationNeeded && !_smartConfirmationShown) {
        _smartConfirmationShown = true;
        final confirmed = await _showConfirmationDialog(
          'Smart Alert Check',
          'The system is not fully sure yet. Do you want to send the emergency alert now?',
        );

        if (!confirmed) {
          await orchestrator.recordFalseAlert();
          await _cancelSOS();
          return;
        }
      }

      final response = await orchestrator.triggerEmergency(
        token: token,
        latitude: position.latitude,
        longitude: position.longitude,
        confidenceScore: confidenceScore,
        description: 'Manual SOS activated from mobile app',
      );

      if (!mounted) return;
      setState(() {
        _caseResponse = response;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(response.message ?? 'Emergency alert sent'),
          backgroundColor: AppColors.error,
        ),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('SOS failed: $e')),
      );
    }
  }

  Future<void> _cancelSOS() async {
    final startedAt = _activationStartedAt;
    if (startedAt != null) {
      await context.read<EmergencyOrchestrator>().recordAlertCancel(startedAt);
    }

    if (!mounted) return;
    setState(() {
      _sosActive = false;
      _holdController.reset();
      _caseResponse = null;
      _smartConfirmationShown = false;
    });
  }

  Future<bool> _showConfirmationDialog(String title, String message) async {
    if (!mounted) return false;
    final result = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(title),
        content: Text(message),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Send'),
          ),
        ],
      ),
    );
    return result ?? false;
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final size = MediaQuery.of(context).size;

    return Scaffold(
      extendBody: true,
      appBar: CustomAppBar(
        title: 'Emergency Center',
        showBackButton: false,
        actions: [
          IconButton(
            icon: const Icon(Icons.notifications_outlined, color: Colors.white),
            onPressed: () => Navigator.push(
              context,
              PageTransitions.slideFromRight(const NotificationsScreen()),
            ),
          ),
          IconButton(
            icon: const Icon(Icons.person_outline_rounded, color: Colors.white),
            onPressed: () => Navigator.push(
              context,
              PageTransitions.slideFromRight(const ProfileScreen()),
            ),
          ),
        ],
      ),
      body: Stack(
        alignment: Alignment.center,
        children: [
          _buildAmbientBackground(size, isDark),
          _buildBlastEffect(size),
          SingleChildScrollView(
            physics: const BouncingScrollPhysics(),
            padding: const EdgeInsets.fromLTRB(20, 10, 20, 100),
            child: Column(
              children: [
                _buildStatusHeader(),
                const SizedBox(height: 50),
                _buildPremiumSOSButton(),
                const SizedBox(height: 24),
                Text(
                  _sosActive ? 'TAP TO CANCEL ALERT' : 'PRESS & HOLD FOR 3 SECONDS',
                  style: TextStyle(
                    fontWeight: FontWeight.w900,
                    color: _sosActive ? AppColors.error : AppColors.grey,
                    letterSpacing: 1.5,
                    fontSize: 12,
                  ),
                ),
                if (_sosActive && _caseResponse != null) _buildActiveCard(),
                const SizedBox(height: 50),
                _buildMonitoringDashboard(isDark),
                if (_sosActive) _buildActiveEmergencyActions(),
              ],
            ),
          ),
        ],
      ),
      bottomNavigationBar: CustomBottomNav(
        currentIndex: 1,
        onTap: (index) {
          if (index == 0) {
            Navigator.pushReplacementNamed(context, AppRoutes.userHome);
          }
          if (index == 2) Navigator.pushNamed(context, AppRoutes.contacts);
          if (index == 3) Navigator.pushNamed(context, AppRoutes.settings);
        },
        items: const [
          BottomNavItem(icon: Icons.home_rounded, label: 'Home'),
          BottomNavItem(icon: Icons.warning_amber_rounded, label: 'SOS'),
          BottomNavItem(icon: Icons.people_rounded, label: 'Contacts'),
          BottomNavItem(icon: Icons.settings_rounded, label: 'Settings'),
        ],
      ),
    );
  }

  Widget _buildPremiumSOSButton() {
    return GestureDetector(
      onTapDown: _onTapDown,
      onTapUp: _onTapUp,
      onTapCancel: _onTapCancel,
      onTap: _sosActive ? _cancelSOS : null,
      child: AnimatedBuilder(
        animation: Listenable.merge([_pulseController, _holdController]),
        builder: (context, child) {
          final scale = _sosActive
              ? 1.0 + (_pulseController.value * 0.05)
              : 1.0 - (_holdController.value * 0.05);

          return Transform.scale(
            scale: scale,
            child: Stack(
              alignment: Alignment.center,
              children: [
                SizedBox(
                  width: 240,
                  height: 240,
                  child: CircularProgressIndicator(
                    value: _sosActive ? 1.0 : _holdController.value,
                    strokeWidth: 8,
                    backgroundColor: Colors.transparent,
                    valueColor: AlwaysStoppedAnimation<Color>(
                      _sosActive ? Colors.redAccent : Colors.red,
                    ),
                  ),
                ),
                Container(
                  width: 200,
                  height: 200,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: _sosActive
                          ? [Colors.red.shade800, Colors.red.shade900]
                          : [const Color(0xFFEF4444), const Color(0xFFB91C1C)],
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.red.withOpacity(0.4 + (_holdController.value * 0.4)),
                        blurRadius: 30 + (_holdController.value * 20),
                        spreadRadius: 10 + (_holdController.value * 15),
                      ),
                      BoxShadow(
                        color: Colors.white.withOpacity(0.2),
                        blurRadius: 10,
                        spreadRadius: 2,
                      ),
                    ],
                  ),
                  child: Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          _sosActive ? Icons.wifi_tethering_rounded : Icons.fingerprint_rounded,
                          size: 60,
                          color: Colors.white,
                        ),
                        const SizedBox(height: 8),
                        Text(
                          _sosActive ? 'ACTIVE' : 'SOS',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 32,
                            fontWeight: FontWeight.w900,
                            letterSpacing: 2,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildBlastEffect(Size size) {
    return AnimatedBuilder(
      animation: _blastController,
      builder: (context, child) {
        if (_blastController.value == 0) return const SizedBox.shrink();
        return Transform.scale(
          scale: 1.0 + (_blastController.value * 15),
          child: Opacity(
            opacity: 1.0 - _blastController.value,
            child: Container(
              width: 100,
              height: 100,
              decoration: const BoxDecoration(
                shape: BoxShape.circle,
                color: Colors.redAccent,
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildActiveCard() {
    return Padding(
      padding: const EdgeInsets.only(top: 24),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.red.withOpacity(0.1),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: Colors.red.withOpacity(0.3)),
        ),
        child: Column(
          children: [
            const Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.local_police_rounded, color: Colors.red, size: 20),
                SizedBox(width: 8),
                Text(
                  'AUTHORITIES ALERTED',
                  style: TextStyle(
                    color: Colors.red,
                    fontWeight: FontWeight.w900,
                    letterSpacing: 1,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              'Tracking ID: ${_caseResponse!.caseId}',
              style: const TextStyle(fontSize: 12, color: Colors.grey),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatusHeader() {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 20),
      decoration: BoxDecoration(
        color: _sosActive ? AppColors.error.withOpacity(0.1) : AppColors.primary.withOpacity(0.1),
        borderRadius: BorderRadius.circular(30),
        border: Border.all(
          color: _sosActive ? AppColors.error.withOpacity(0.3) : Colors.transparent,
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 10,
            height: 10,
            decoration: BoxDecoration(
              color: _sosActive ? AppColors.error : AppColors.success,
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(
                  color: (_sosActive ? AppColors.error : AppColors.success).withOpacity(0.5),
                  blurRadius: 10,
                )
              ],
            ),
          ),
          const SizedBox(width: 10),
          Text(
            _sosActive ? 'EMERGENCY BROADCASTING' : 'SYSTEM ARMED & SECURE',
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.bold,
              letterSpacing: 1,
              color: _sosActive ? AppColors.error : AppColors.success,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMonitoringDashboard(bool isDark) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Safety Sensors',
          style: TextStyle(fontWeight: FontWeight.w900, fontSize: 16),
        ),
        const SizedBox(height: 12),
        Container(
          decoration: BoxDecoration(
            color: isDark ? Colors.white.withOpacity(0.03) : Colors.white,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: isDark ? Colors.white.withOpacity(0.05) : Colors.grey.withOpacity(0.2),
            ),
          ),
          child: Column(
            children: [
              _buildDashboardTile(
                icon: _sensorMonitoring ? Icons.sensors_rounded : Icons.sensors_off_rounded,
                title: 'Impact Sensors',
                subtitle: _sensorMonitoring ? 'Auto-detecting accidents' : 'Sensors disabled',
                color: _sensorMonitoring ? AppColors.success : AppColors.grey,
                trailing: Switch.adaptive(
                  value: _sensorMonitoring,
                  activeThumbColor: AppColors.success,
                  activeTrackColor: AppColors.success.withValues(alpha: 0.4),
                  onChanged: (v) => v ? _startSensorMonitoring() : _stopSensorMonitoring(),
                ),
              ),
              Divider(
                height: 1,
                color: isDark ? Colors.white.withOpacity(0.1) : Colors.grey.withOpacity(0.2),
              ),
              FutureBuilder<bool>(
                future: BackgroundService.isServiceRunning(),
                builder: (context, snapshot) {
                  final isRunning = snapshot.data ?? false;
                  return _buildDashboardTile(
                    icon: isRunning ? Icons.location_on_rounded : Icons.location_off_rounded,
                    title: 'Live GPS Tracking',
                    subtitle: isRunning ? 'Background location active' : 'Tracking inactive',
                    color: isRunning ? AppColors.primary : AppColors.grey,
                    trailing: Switch.adaptive(
                      value: isRunning,
                      activeThumbColor: AppColors.primary,
                      activeTrackColor: AppColors.primary.withValues(alpha: 0.4),
                      onChanged: (_) => _toggleBackgroundTracking(),
                    ),
                  );
                },
              ),
              Divider(
                height: 1,
                color: isDark ? Colors.white.withOpacity(0.1) : Colors.grey.withOpacity(0.2),
              ),
              Consumer<AudioService>(
                builder: (context, audioService, _) {
                  return _buildDashboardTile(
                    icon: audioService.isListening ? Icons.mic_rounded : Icons.mic_off_rounded,
                    title: 'Audio Monitoring',
                    subtitle: audioService.isListening
                        ? 'Level: ${audioService.currentAudioLevel.toStringAsFixed(0)} dB'
                        : 'Audio listening disabled',
                    color: audioService.isListening ? AppColors.warning : AppColors.grey,
                    trailing: Switch.adaptive(
                      value: audioService.isListening,
                      activeThumbColor: AppColors.warning,
                      activeTrackColor: AppColors.warning.withValues(alpha: 0.4),
                      onChanged: (v) =>
                          v ? _startAudioMonitoring() : _stopAudioMonitoring(),
                    ),
                  );
                },
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildDashboardTile({
    required IconData icon,
    required String title,
    required String subtitle,
    required Color color,
    required Widget trailing,
  }) {
    return ListTile(
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      leading: Container(
        padding: const EdgeInsets.all(10),
        decoration: BoxDecoration(
          color: color.withOpacity(0.1),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Icon(icon, color: color, size: 22),
      ),
      title: Text(title, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
      subtitle: Text(subtitle, style: const TextStyle(fontSize: 12)),
      trailing: trailing,
    );
  }

  Widget _buildActiveEmergencyActions() {
    return Column(
      children: [
        const SizedBox(height: 24),
        _buildActionTile(Icons.local_police_rounded, 'Call Police', Colors.blueAccent),
        const SizedBox(height: 12),
        _buildActionTile(Icons.medical_services_rounded, 'Medical Assistance', Colors.redAccent),
        const SizedBox(height: 12),
        _buildActionTile(
          Icons.group_add_rounded,
          'Request Nearby Help',
          Colors.orangeAccent,
          onTap: _requestNearbyHelp,
        ),
      ],
    );
  }

  Widget _buildActionTile(
    IconData icon,
    String title,
    Color color, {
    VoidCallback? onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: color.withOpacity(0.1),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: color.withOpacity(0.3)),
        ),
        child: Row(
          children: [
            Icon(icon, color: color),
            const SizedBox(width: 16),
            Expanded(
              child: Text(title, style: const TextStyle(fontWeight: FontWeight.bold)),
            ),
            const Icon(Icons.call, size: 20),
          ],
        ),
      ),
    );
  }

  Widget _buildAmbientBackground(Size size, bool isDark) {
    return Positioned(
      top: size.height * 0.1,
      child: Container(
        width: size.width,
        height: size.height * 0.5,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          gradient: RadialGradient(
            colors: [
              _sosActive ? Colors.red.withOpacity(0.15) : AppColors.primary.withOpacity(0.05),
              Colors.transparent,
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _requestLocationPermission() async {
    try {
      final permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied || permission == LocationPermission.deniedForever) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Location permission denied')),
          );
        }
      }
    } catch (e) {
      debugPrint('Error: $e');
    }
  }

  Future<void> _initializeSensorService() async {
    await context.read<SensorService>().initialize();
  }

  void _startSensorMonitoring() {
    setState(() => _sensorMonitoring = true);
    context.read<SensorService>().startMonitoring();
  }

  void _stopSensorMonitoring() {
    setState(() => _sensorMonitoring = false);
    context.read<SensorService>().stopMonitoring();
  }

  Future<void> _startAudioMonitoring() async {
    final audioService = context.read<AudioService>();
    await audioService.startListening();
  }

  Future<void> _stopAudioMonitoring() async {
    final audioService = context.read<AudioService>();
    await audioService.stopListening();
  }

  Future<void> _toggleBackgroundTracking() async {
    final isRunning = await BackgroundService.isServiceRunning();
    if (isRunning) {
      await BackgroundService.stopLocationService();
      _stopSensorMonitoring();
    } else {
      await BackgroundService.startLocationService();
      _startSensorMonitoring();
    }
    if (mounted) setState(() {});
  }

  Future<void> _requestNearbyHelp() async {
    try {
      final token = context.read<AuthProvider>().token;
      if (token == null) {
        throw Exception('Login required');
      }

      final position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
      );

      final response = await ApiService.requestHelp(
        token,
        latitude: position.latitude,
        longitude: position.longitude,
        description: 'Nearby help requested from SOS screen',
      );

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(response.message)),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Nearby help request failed: $e')),
        );
      }
    }
  }
}
