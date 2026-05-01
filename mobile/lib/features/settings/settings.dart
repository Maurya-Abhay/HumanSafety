import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../shared/widgets.dart';
import '../../shared/models.dart';
import '../../core/routes.dart';
import '../../core/storage_service.dart';
import '../../core/sensor_service.dart';
import '../../core/background_service.dart';
import '../../core/theme.dart';
import '../../core/button_listener_service.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  bool enableNotifications = true;
  bool enableLocationTracking = true;
  bool enableBackgroundTracking = false;
  bool enableAutoSOS = false;
  bool enableEmergencySharing = true;
  bool enableAnalytics = true;
  int sosActivationSeconds = 3;
  int locationUpdateIntervalSeconds = 10;

  @override
  void initState() {
    super.initState();
    _loadSettings();
    _initializeSensorService();
  }

  Future<void> _initializeSensorService() async {
    final sensorService = context.read<SensorService>();
    await sensorService.initialize();
  }

  Future<void> _loadSettings() async {
    final notifications = await StorageService.getBool('enable_notifications') ?? true;
    final locationTracking = await StorageService.getBool('enable_location_tracking') ?? true;
    final backgroundTracking = await StorageService.getBool('enable_background_tracking') ?? false;
    final autoSOS = await StorageService.getBool('enable_auto_sos') ?? false;
    final emergencySharing = await StorageService.getBool('enable_emergency_sharing') ?? true;
    final analytics = await StorageService.getBool('enable_analytics') ?? true;
    
    setState(() {
      enableNotifications = notifications;
      enableLocationTracking = locationTracking;
      enableBackgroundTracking = backgroundTracking;
      enableAutoSOS = autoSOS;
      enableEmergencySharing = emergencySharing;
      enableAnalytics = analytics;
    });
  }

  Future<void> _saveSetting(String key, dynamic value) async {
    if (value is bool) {
      await StorageService.saveBool(key, value);
    } else {
      await StorageService.saveString(key, value.toString());
    }
  }

  void _showSnackBar(String message, {Color? bgColor}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message, style: const TextStyle(fontWeight: FontWeight.w500)),
        backgroundColor: bgColor ?? AppColors.primary,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        duration: const Duration(seconds: 2),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bgColor = isDark ? const Color(0xFF121212) : const Color(0xFFF4F5F7);
    
    return Scaffold(
      backgroundColor: bgColor,
      extendBody: true,
      appBar: CustomAppBar(
        title: 'Settings',
        showBackButton: false,
        actions: [
          IconButton(
            icon: const Icon(Icons.notifications_outlined, color: Colors.white),
            onPressed: () => Navigator.pushNamed(context, AppRoutes.notifications),
          ),
        ],
      ),
      body: SingleChildScrollView(
        physics: const BouncingScrollPhysics(),
        padding: const EdgeInsets.fromLTRB(16, 20, 16, 100),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // USER ACCOUNT (Moved to top for better UX)
            _buildAccountCard(context),
            const SizedBox(height: 24),

            // APPEARANCE SECTION
            _buildSectionHeader('APPEARANCE', context),
            _buildSettingsGroup([
              _buildThemeItem(context),
              _buildBrightnessInfo(isDark),
            ]),

            const SizedBox(height: 24),

            // EMERGENCY & SAFETY FEATURES
            _buildSectionHeader('SAFETY & EMERGENCY', context),
            _buildSettingsGroup(_buildSafetySettingsItems()),

            const SizedBox(height: 24),

            // SENSOR & LOCATION
            _buildSectionHeader('SENSOR & TRACKING', context),
            _buildSettingsGroup(_buildSensorItems()),

            const SizedBox(height: 24),

            // NOTIFICATIONS & PRIVACY (Combined for cleaner look)
            _buildSectionHeader('PREFERENCES & PRIVACY', context),
            _buildSettingsGroup([
              ..._buildNotificationItems(),
              ..._buildPrivacyItems(),
            ]),

            const SizedBox(height: 24),

            // ABOUT & SUPPORT
            _buildSectionHeader('ABOUT & SUPPORT', context),
            _buildSettingsGroup(_buildAboutItems()),

            const SizedBox(height: 32),
          ],
        ),
      ),
      bottomNavigationBar: CustomBottomNav(
        currentIndex: 3,
        onTap: (index) {
          if (index == 0) Navigator.pushNamedAndRemoveUntil(context, AppRoutes.userHome, (route) => false);
          if (index == 1) Navigator.pushNamed(context, AppRoutes.sos);
          if (index == 2) Navigator.pushNamed(context, AppRoutes.contacts);
          if (index == 3) return; // Already on settings
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

  // --- Helper to create modern grouped settings cards ---
  Widget _buildSettingsGroup(List<Widget> items) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Container(
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1E1E1E) : Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          if (!isDark)
            BoxShadow(
              color: Colors.black.withOpacity(0.04),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
        ],
      ),
      child: Column(
        children: items.asMap().entries.map((entry) {
          int idx = entry.key;
          Widget item = entry.value;
          return Column(
            children: [
              item,
              if (idx != items.length - 1)
                Divider(
                  height: 1,
                  thickness: 1,
                  indent: 56, // Align divider with text, skip icon
                  color: isDark ? Colors.white10 : Colors.black.withOpacity(0.05),
                ),
            ],
          );
        }).toList(),
      ),
    );
  }

  Widget _buildSectionHeader(String title, BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(left: 16, bottom: 8),
      child: Text(
        title,
        style: TextStyle(
          color: AppColors.grey,
          fontWeight: FontWeight.w700,
          fontSize: 12,
          letterSpacing: 1.2,
        ),
      ),
    );
  }

  Widget _buildAccountCard(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Consumer<AuthProvider>(
      builder: (context, authProvider, _) {
        final user = authProvider.user;
        return InkWell(
          onTap: () => Navigator.pushNamed(context, AppRoutes.profile),
          borderRadius: BorderRadius.circular(16),
          child: Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: isDark 
                  ? [const Color(0xFF2C2C2C), const Color(0xFF1A1A1A)] 
                  : [Colors.white, const Color(0xFFF8F9FA)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(16),
              boxShadow: [
                if (!isDark)
                  BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10, offset: const Offset(0, 4)),
              ],
              border: Border.all(color: AppColors.primary.withOpacity(0.1)),
            ),
            child: Row(
              children: [
                Container(
                  width: 60,
                  height: 60,
                  decoration: const BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: LinearGradient(
                      colors: [AppColors.primary, Color(0xFF6A11CB)],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                  ),
                  child: Center(
                    child: Text(
                      user?.name.isNotEmpty == true ? user!.name[0].toUpperCase() : 'U',
                      style: const TextStyle(color: Colors.white, fontSize: 26, fontWeight: FontWeight.bold),
                    ),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        user?.name ?? 'My Profile',
                        style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        user?.email ?? 'Manage your account details',
                        style: TextStyle(color: AppColors.grey, fontSize: 13),
                      ),
                    ],
                  ),
                ),
                const Icon(Icons.arrow_forward_ios_rounded, size: 18, color: AppColors.grey),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildThemeItem(BuildContext context) {
    return Consumer<ThemeProvider>(
      builder: (context, themeProvider, _) {
        return ListTile(
          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
          leading: _buildIconBg(Icons.dark_mode, Colors.black87),
          title: const Text('Dark Mode', style: TextStyle(fontWeight: FontWeight.w500)),
          trailing: Switch.adaptive(
            activeColor: AppColors.primary,
            value: themeProvider.isDarkMode,
            onChanged: (_) async {
              await themeProvider.toggleTheme();
              _showSnackBar(themeProvider.isDarkMode ? '🌙 Dark Mode Enabled' : '☀️ Light Mode Enabled');
            },
          ),
        );
      },
    );
  }

  Widget _buildBrightnessInfo(bool isDark) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
      child: Row(
        children: [
          Icon(isDark ? Icons.nights_stay : Icons.wb_sunny, size: 16, color: AppColors.grey),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              isDark ? 'Dark mode reduces eye strain in low light environments.' : 'Light mode is optimized for daytime viewing.',
              style: TextStyle(fontSize: 12, color: AppColors.grey),
            ),
          ),
        ],
      ),
    );
  }

  List<Widget> _buildSafetySettingsItems() {
    return [
      Consumer<SensorService>(
        builder: (context, sensorService, child) {
          return ListTile(
            contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
            leading: _buildIconBg(Icons.car_crash_rounded, Colors.red),
            title: const Text('Auto SOS on Impact', style: TextStyle(fontWeight: FontWeight.w500)),
            subtitle: const Text('Detects crashes automatically', style: TextStyle(fontSize: 12)),
            trailing: Switch.adaptive(
              activeColor: Colors.red,
              value: sensorService.autoSOS,
              onChanged: (val) async {
                setState(() => enableAutoSOS = val);
                await _saveSetting('enable_auto_sos', val);
                await sensorService.initialize();
                _showSnackBar(val ? '✓ Auto SOS Enabled' : 'Auto SOS Disabled', bgColor: val ? Colors.red : null);
              },
            ),
          );
        },
      ),
      ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
        leading: _buildIconBg(Icons.share_location_rounded, Colors.orange),
        title: const Text('Emergency Contact Sharing', style: TextStyle(fontWeight: FontWeight.w500)),
        subtitle: const Text('Share details with responders', style: TextStyle(fontSize: 12)),
        trailing: Switch.adaptive(
          activeColor: Colors.orange,
          value: enableEmergencySharing,
          onChanged: (val) {
            setState(() => enableEmergencySharing = val);
            _saveSetting('enable_emergency_sharing', val);
          },
        ),
      ),
      ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
        leading: _buildIconBg(Icons.volume_up_rounded, Colors.green),
        title: const Text('Hardware Volume Button SOS', style: TextStyle(fontWeight: FontWeight.w500)),
        subtitle: const Text('Triple-press volume button to trigger SOS', style: TextStyle(fontSize: 12)),
        trailing: FutureBuilder<bool>(
          future: ButtonListenerService().isEnabled(),
          builder: (context, snapshot) {
            final enabled = snapshot.data ?? true;
            return Switch.adaptive(
              activeColor: Colors.green,
              value: enabled,
              onChanged: (val) async {
                setState(() {});
                await ButtonListenerService().setEnabled(val);
                _saveSetting('enable_hardware_sos', val);
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text(val ? 'Hardware SOS Enabled' : 'Hardware SOS Disabled')),
                );
              },
            );
          },
        ),
      ),
    ];
  }

  List<Widget> _buildSensorItems() {
    return [
      ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
        leading: _buildIconBg(Icons.my_location_rounded, Colors.blue),
        title: const Text('Location Tracking', style: TextStyle(fontWeight: FontWeight.w500)),
        trailing: Switch.adaptive(
          activeColor: Colors.blue,
          value: enableLocationTracking,
          onChanged: (val) {
            setState(() => enableLocationTracking = val);
            _saveSetting('enable_location_tracking', val);
          },
        ),
      ),
      ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
        leading: _buildIconBg(Icons.history_toggle_off_rounded, Colors.purple),
        title: const Text('Background Tracking', style: TextStyle(fontWeight: FontWeight.w500)),
        subtitle: const Text('Track when app is closed', style: TextStyle(fontSize: 12)),
        trailing: FutureBuilder<bool>(
          future: BackgroundService.isServiceRunning(),
          builder: (context, snapshot) {
            final isRunning = snapshot.data ?? enableBackgroundTracking;
            return Switch.adaptive(
              activeColor: Colors.purple,
              value: isRunning,
              onChanged: (val) async {
                final sensorService = context.read<SensorService>();
                setState(() => enableBackgroundTracking = val);
                await _saveSetting('enable_background_tracking', val);

                if (val) {
                  await BackgroundService.startLocationService();
                  await sensorService.startMonitoring();
                  _showSnackBar('✓ Background Tracking Started', bgColor: Colors.purple);
                } else {
                  await BackgroundService.stopLocationService();
                  await sensorService.stopMonitoring();
                  _showSnackBar('Background Tracking Stopped');
                }
              },
            );
          },
        ),
      ),
      Consumer<SensorService>(
        builder: (context, sensorService, child) {
          final status = sensorService.getSensorStatus();
          final isMonitoring = status['is_monitoring'] ?? false;
          return ListTile(
            contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
            leading: _buildIconBg(isMonitoring ? Icons.sensors : Icons.sensors_off, isMonitoring ? Colors.green : Colors.grey),
            title: const Text('Sensor Status', style: TextStyle(fontWeight: FontWeight.w500)),
            trailing: Text(
              isMonitoring ? 'Active' : 'Inactive',
              style: TextStyle(color: isMonitoring ? Colors.green : Colors.grey, fontWeight: FontWeight.bold),
            ),
          );
        },
      ),
    ];
  }

  List<Widget> _buildNotificationItems() {
    return [
      ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
        leading: _buildIconBg(Icons.notifications_active_rounded, Colors.amber.shade600),
        title: const Text('Emergency Notifications', style: TextStyle(fontWeight: FontWeight.w500)),
        trailing: Switch.adaptive(
          activeColor: Colors.amber.shade600,
          value: enableNotifications,
          onChanged: (val) {
            setState(() => enableNotifications = val);
            _saveSetting('enable_notifications', val);
          },
        ),
      ),
    ];
  }

  List<Widget> _buildPrivacyItems() {
    return [
      ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
        leading: _buildIconBg(Icons.analytics_rounded, Colors.cyan),
        title: const Text('Share Analytics', style: TextStyle(fontWeight: FontWeight.w500)),
        trailing: Switch.adaptive(
          activeColor: Colors.cyan,
          value: enableAnalytics,
          onChanged: (val) {
            setState(() => enableAnalytics = val);
            _saveSetting('enable_analytics', val);
          },
        ),
      ),
      ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
        leading: _buildIconBg(Icons.shield_rounded, AppColors.primary),
        title: const Text('Privacy Policy', style: TextStyle(fontWeight: FontWeight.w500)),
        trailing: const Icon(Icons.arrow_forward_ios_rounded, size: 16, color: Colors.grey),
        onTap: () => Navigator.pushNamed(context, AppRoutes.privacy),
      ),
      ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
        leading: _buildIconBg(Icons.delete_sweep_rounded, Colors.red),
        title: const Text('Clear App Data', style: TextStyle(fontWeight: FontWeight.w500)),
        onTap: _showClearDataDialog,
      ),
    ];
  }

  List<Widget> _buildAboutItems() {
    return [
      ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
        leading: _buildIconBg(Icons.info_outline_rounded, AppColors.primary),
        title: const Text('About App', style: TextStyle(fontWeight: FontWeight.w500)),
        trailing: const Icon(Icons.arrow_forward_ios_rounded, size: 16, color: Colors.grey),
        onTap: () => Navigator.pushNamed(context, AppRoutes.about),
      ),
      ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
        leading: _buildIconBg(Icons.help_outline_rounded, Colors.teal),
        title: const Text('Help & Support', style: TextStyle(fontWeight: FontWeight.w500)),
        trailing: const Icon(Icons.arrow_forward_ios_rounded, size: 16, color: Colors.grey),
        onTap: () => Navigator.pushNamed(context, AppRoutes.help),
      ),
      ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
        leading: _buildIconBg(Icons.verified_rounded, Colors.grey.shade600),
        title: const Text('App Version', style: TextStyle(fontWeight: FontWeight.w500)),
        trailing: Text('v1.0.0', style: TextStyle(color: Colors.grey.shade600, fontWeight: FontWeight.bold)),
      ),
    ];
  }

  Widget _buildIconBg(IconData icon, Color color) {
    return Container(
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: color.withOpacity(0.15),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Icon(icon, color: color, size: 20),
    );
  }

  void _showClearDataDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text('Clear App Data?', style: TextStyle(fontWeight: FontWeight.bold)),
        content: const Text(
          'This will remove all cached data and temporary files. Your account information will remain safe.',
          style: TextStyle(color: Colors.grey),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('Cancel', style: TextStyle(color: AppColors.grey)),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red.shade50,
              elevation: 0,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            ),
            onPressed: () {
              Navigator.pop(context);
              _showSnackBar('✓ App data cleared', bgColor: Colors.red);
            },
            child: const Text('Clear', style: TextStyle(color: Colors.red, fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }
}