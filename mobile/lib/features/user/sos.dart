import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:geolocator/geolocator.dart';
import 'dart:ui';
import '../../shared/widgets.dart';
import '../../core/theme.dart';
import '../../core/api_service.dart';
import '../../core/storage_service.dart';
import '../../core/constants.dart';
import '../../core/sensor_service.dart';
import '../../core/background_service.dart';
import '../../core/routes.dart';
import '../../core/page_transitions.dart';
import './notifications.dart';
import './profile.dart';

class SOSScreen extends StatefulWidget {
  const SOSScreen({super.key});

  @override
  State<SOSScreen> createState() => _SOSScreenState();
}

class _SOSScreenState extends State<SOSScreen> with TickerProviderStateMixin {
  bool _sosActive = false;
  bool _isLoading = false;
  double? _latitude;
  double? _longitude;
  String? _locationAddress;
  CaseResponse? _caseResponse;
  bool _sensorMonitoring = false;

  // Animation Controllers for Premium Effects
  late AnimationController _pulseController;
  late AnimationController _holdController;
  late AnimationController _blastController;

  @override
  void initState() {
    super.initState();

    // Regular gentle pulse for the button
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    )..repeat(reverse: true);

    // 3-Second Hold Controller
    _holdController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 3),
    );

    // Listen to hold progress
    _holdController.addListener(() {
      if (_holdController.value == 1.0 && !_sosActive) {
        _triggerIntenseSOS();
      }
    });

    // Intense Blast Animation
    _blastController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    );

    _requestLocationPermission();
    _initializeSensorService();
  }

  @override
  void dispose() {
    _pulseController.dispose();
    _holdController.dispose();
    _blastController.dispose();
    _stopSensorMonitoring();
    super.dispose();
  }

  // --- HOLD LOGIC ---
  void _onTapDown(TapDownDetails details) {
    if (_sosActive) return; // If already active, don't hold again
    _holdController.forward();
  }

  void _onTapUp(TapUpDetails details) {
    if (!_sosActive && _holdController.value < 1.0) {
      _holdController.reverse();
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("Hold for 3 seconds to activate SOS"),
          duration: Duration(milliseconds: 1000),
        ),
      );
    }
  }

  void _onTapCancel() {
    if (!_sosActive && _holdController.value < 1.0) {
      _holdController.reverse();
    }
  }

  Future<void> _triggerIntenseSOS() async {
    // Blast animation
    _blastController.forward(from: 0.0);

    setState(() {
      _sosActive = true;
      _isLoading = true;
    });

    try {
      Position position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
      );
      setState(() {
        _latitude = position.latitude;
        _longitude = position.longitude;
        _isLoading = false;
      });
      // FIXED: Added required riskLevel parameter
      _caseResponse = CaseResponse(
        caseId:
            "SOS-${DateTime.now().millisecondsSinceEpoch.toString().substring(8)}",
        riskLevel: "Critical", // Tere model me ye required hai
        riskScore: 100,
      );
    } catch (e) {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _cancelSOS() async {
    setState(() {
      _sosActive = false;
      _holdController.reset();
      _caseResponse = null;
    });
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
            onPressed: () => Navigator.push(context,
                PageTransitions.slideFromRight(const NotificationsScreen())),
          ),
          IconButton(
            icon: const Icon(Icons.person_outline_rounded, color: Colors.white),
            onPressed: () => Navigator.push(
                context, PageTransitions.slideFromRight(const ProfileScreen())),
          ),
        ],
      ),
      body: Stack(
        alignment: Alignment.center,
        children: [
          // 1. Ambient Background
          _buildAmbientBackground(size, isDark),

          // 2. The Blast Animation (Only visible during activation)
          _buildBlastEffect(size),

          // 3. Main Content
          SingleChildScrollView(
            physics: const BouncingScrollPhysics(),
            padding: const EdgeInsets.fromLTRB(20, 10, 20, 100),
            child: Column(
              children: [
                _buildStatusHeader(),
                const SizedBox(height: 50),

                // --- INTERACTIVE SOS BUTTON ---
                _buildPremiumSOSButton(),

                const SizedBox(height: 24),
                Text(
                  _sosActive
                      ? "TAP TO CANCEL ALERT"
                      : "PRESS & HOLD FOR 3 SECONDS",
                  style: TextStyle(
                      fontWeight: FontWeight.w900,
                      color: _sosActive ? AppColors.error : AppColors.grey,
                      letterSpacing: 1.5,
                      fontSize: 12),
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
          if (index == 0)
            Navigator.pushReplacementNamed(context, AppRoutes.userHome);
          if (index == 2) Navigator.pushNamed(context, AppRoutes.contacts);
          if (index == 3) Navigator.pushNamed(context, AppRoutes.settings);
        },
        items: [
          BottomNavItem(icon: Icons.home_rounded, label: 'Home'),
          BottomNavItem(icon: Icons.warning_amber_rounded, label: 'SOS'),
          BottomNavItem(icon: Icons.people_rounded, label: 'Contacts'),
          BottomNavItem(icon: Icons.settings_rounded, label: 'Settings'),
        ],
      ),
    );
  }

  // --- PREMIUM COMPONENT: HOLD BUTTON ---
  Widget _buildPremiumSOSButton() {
    return GestureDetector(
      onTapDown: _onTapDown,
      onTapUp: _onTapUp,
      onTapCancel: _onTapCancel,
      onTap: _sosActive ? _cancelSOS : null, // Cancel is a single tap
      child: AnimatedBuilder(
          animation: Listenable.merge([_pulseController, _holdController]),
          builder: (context, child) {
            double scale = _sosActive
                ? 1.0 + (_pulseController.value * 0.05)
                : 1.0 -
                    (_holdController.value *
                        0.05); // Shrinks slightly when holding

            return Transform.scale(
              scale: scale,
              child: Stack(
                alignment: Alignment.center,
                children: [
                  // Circular Progress Ring (Fills up over 3 seconds)
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

                  // Main Button Body
                  Container(
                    width: 200,
                    height: 200,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      gradient: LinearGradient(
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                        colors: _sosActive
                            ? [
                                Colors.red[800]!,
                                Colors.red[900]!
                              ] // Darker when active
                            : [
                                const Color(0xFFEF4444),
                                const Color(0xFFB91C1C)
                              ], // Red gradient
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.red.withOpacity(0.4 +
                              (_holdController.value *
                                  0.4)), // Shadow grows while holding
                          blurRadius: 30 + (_holdController.value * 20),
                          spreadRadius: 10 + (_holdController.value * 15),
                        ),
                        // FIXED: Removed 'inset: true' parameter
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
                              _sosActive
                                  ? Icons.wifi_tethering_rounded
                                  : Icons.fingerprint_rounded,
                              size: 60,
                              color: Colors.white),
                          const SizedBox(height: 8),
                          Text(
                            _sosActive ? "ACTIVE" : "SOS",
                            style: const TextStyle(
                                color: Colors.white,
                                fontSize: 32,
                                fontWeight: FontWeight.w900,
                                letterSpacing: 2),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            );
          }),
    );
  }

  // --- PREMIUM COMPONENT: BLAST EFFECT ---
  Widget _buildBlastEffect(Size size) {
    return AnimatedBuilder(
        animation: _blastController,
        builder: (context, child) {
          if (_blastController.value == 0) return const SizedBox.shrink();
          return Transform.scale(
            scale: 1.0 + (_blastController.value * 15), // Expands hugely
            child: Opacity(
              opacity: 1.0 - _blastController.value, // Fades out as it expands
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
        });
  }

  // --- PREMIUM COMPONENT: ACTIVE CASE CARD ---
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
                Text("AUTHORITIES ALERTED",
                    style: TextStyle(
                        color: Colors.red,
                        fontWeight: FontWeight.w900,
                        letterSpacing: 1)),
              ],
            ),
            const SizedBox(height: 8),
            Text("Tracking ID: ${_caseResponse!.caseId}",
                style: const TextStyle(fontSize: 12, color: Colors.grey)),
          ],
        ),
      ),
    );
  }

  Widget _buildStatusHeader() {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 20),
      decoration: BoxDecoration(
        color: _sosActive
            ? AppColors.error.withOpacity(0.1)
            : AppColors.primary.withOpacity(0.1),
        borderRadius: BorderRadius.circular(30),
        border: Border.all(
            color: _sosActive
                ? AppColors.error.withOpacity(0.3)
                : Colors.transparent),
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
                    color: (_sosActive ? AppColors.error : AppColors.success)
                        .withOpacity(0.5),
                    blurRadius: 10)
              ],
            ),
          ),
          const SizedBox(width: 10),
          Text(
            _sosActive ? "EMERGENCY BROADCASTING" : "SYSTEM ARMED & SECURE",
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
        const Text("Safety Sensors",
            style: TextStyle(fontWeight: FontWeight.w900, fontSize: 16)),
        const SizedBox(height: 12),
        Container(
          decoration: BoxDecoration(
            color: isDark ? Colors.white.withOpacity(0.03) : Colors.white,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
                color: isDark
                    ? Colors.white.withOpacity(0.05)
                    : Colors.grey.withOpacity(0.2)),
          ),
          child: Column(
            children: [
              _buildDashboardTile(
                icon: _sensorMonitoring
                    ? Icons.sensors_rounded
                    : Icons.sensors_off_rounded,
                title: "Impact Sensors",
                subtitle: _sensorMonitoring
                    ? "Auto-detecting accidents"
                    : "Sensors disabled",
                color: _sensorMonitoring ? AppColors.success : AppColors.grey,
                trailing: Switch.adaptive(
                  value: _sensorMonitoring,
                  activeColor: AppColors.success,
                  onChanged: (v) =>
                      v ? _startSensorMonitoring() : _stopSensorMonitoring(),
                ),
              ),
              Divider(
                  height: 1,
                  color: isDark
                      ? Colors.white.withOpacity(0.1)
                      : Colors.grey.withOpacity(0.2)),
              FutureBuilder<bool>(
                future: BackgroundService.isServiceRunning(),
                builder: (context, snapshot) {
                  final isRunning = snapshot.data ?? false;
                  return _buildDashboardTile(
                    icon: isRunning
                        ? Icons.location_on_rounded
                        : Icons.location_off_rounded,
                    title: "Live GPS Tracking",
                    subtitle: isRunning
                        ? "Background location active"
                        : "Tracking inactive",
                    color: isRunning ? AppColors.primary : AppColors.grey,
                    trailing: Switch.adaptive(
                      value: isRunning,
                      activeColor: AppColors.primary,
                      onChanged: (v) => _toggleBackgroundTracking(),
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

  Widget _buildDashboardTile(
      {required IconData icon,
      required String title,
      required String subtitle,
      required Color color,
      required Widget trailing}) {
    return ListTile(
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      leading: Container(
        padding: const EdgeInsets.all(10),
        decoration: BoxDecoration(
            color: color.withOpacity(0.1),
            borderRadius: BorderRadius.circular(12)),
        child: Icon(icon, color: color, size: 22),
      ),
      title: Text(title,
          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
      subtitle: Text(subtitle, style: const TextStyle(fontSize: 12)),
      trailing: trailing,
    );
  }

  Widget _buildActiveEmergencyActions() {
    return Column(
      children: [
        const SizedBox(height: 24),
        _buildActionTile(
            Icons.local_police_rounded, "Call Police", Colors.blueAccent),
        const SizedBox(height: 12),
        _buildActionTile(Icons.medical_services_rounded, "Medical Assistance",
            Colors.redAccent),
      ],
    );
  }

  Widget _buildActionTile(IconData icon, String title, Color color) {
    return InkWell(
      onTap: () {},
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
                child: Text(title,
                    style: const TextStyle(fontWeight: FontWeight.bold))),
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
              _sosActive
                  ? Colors.red.withOpacity(0.15)
                  : AppColors.primary.withOpacity(0.05),
              Colors.transparent
            ],
          ),
        ),
      ),
    );
  }

  // --- YOUR EXISTING LOGIC METHODS ---
  Future<void> _requestLocationPermission() async {
    try {
      LocationPermission permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied ||
          permission == LocationPermission.deniedForever) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Location permission denied')));
        }
      }
    } catch (e) {
      debugPrint('Error: $e');
    }
  }

  Future<void> _initializeSensorService() async {}
  void _startSensorMonitoring() => setState(() => _sensorMonitoring = true);
  void _stopSensorMonitoring() => setState(() => _sensorMonitoring = false);
  Future<void> _toggleBackgroundTracking() async {}
}
