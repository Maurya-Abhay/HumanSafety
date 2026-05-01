import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../shared/widgets.dart';
import '../../shared/models.dart';
import '../../core/routes.dart';
import '../../core/storage_service.dart';
// constants not required here
import '../../core/theme.dart';

class HospitalSettingsScreen extends StatefulWidget {
  const HospitalSettingsScreen({super.key});

  @override
  State<HospitalSettingsScreen> createState() => _HospitalSettingsScreenState();
}

class _HospitalSettingsScreenState extends State<HospitalSettingsScreen> {
  bool _notificationsEnabled = true;
  bool _darkModeEnabled = false;
  bool _emergencyAlertsEnabled = true;
  bool _ambulanceTrackingEnabled = true;

  @override
  void initState() {
    super.initState();
    _loadSettings();
  }

  Future<void> _loadSettings() async {
    final darkMode = await StorageService.getBool('darkMode') ?? false;
    final notifications = await StorageService.getBool('notifications') ?? true;
    final emergencyAlerts =
        await StorageService.getBool('emergencyAlerts') ?? true;
    final ambulanceTracking =
        await StorageService.getBool('ambulanceTracking') ?? true;

    if (!mounted) return;
    setState(() {
      _darkModeEnabled = darkMode;
      _notificationsEnabled = notifications;
      _emergencyAlertsEnabled = emergencyAlerts;
      _ambulanceTrackingEnabled = ambulanceTracking;
    });
  }

  void _showPrivacyPolicy() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Privacy Policy'),
        content: const Text(
            'Your data is securely stored and only used for emergency response and patient care purposes.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Scaffold(
      appBar: CustomAppBar(
        title: 'Hospital Settings',
        showBackButton: false,
        actions: [
          IconButton(
            icon: const Icon(Icons.notifications_none_rounded,
                color: Colors.white),
            onPressed: () =>
                Navigator.pushNamed(context, AppRoutes.hospitalNotifications),
          ),
          IconButton(
            icon: const Icon(Icons.person_outline_rounded, color: Colors.white),
            onPressed: () =>
                Navigator.pushNamed(context, AppRoutes.hospitalProfile),
          ),
        ],
      ),
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: isDark
                ? [const Color(0xFF121212), const Color(0xFF1E1E2E)]
                : [const Color(0xFFF8F9FA), Colors.white],
          ),
        ),
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            _buildSectionTitle('Emergency Settings'),
            const SizedBox(height: 8),
            _buildToggleItem(
              'Emergency Alerts',
              'Receive critical emergency notifications',
              _emergencyAlertsEnabled,
              (value) {
                setState(() => _emergencyAlertsEnabled = value);
                StorageService.saveBool('emergencyAlerts', value);
              },
              Icons.emergency_rounded,
            ),
            _buildToggleItem(
              'Ambulance Tracking',
              'Enable real-time ambulance location tracking',
              _ambulanceTrackingEnabled,
              (value) {
                setState(() => _ambulanceTrackingEnabled = value);
                StorageService.saveBool('ambulanceTracking', value);
              },
              Icons.directions_car_rounded,
            ),
            _buildToggleItem(
              'Push Notifications',
              'Receive notifications for new requests',
              _notificationsEnabled,
              (value) {
                setState(() => _notificationsEnabled = value);
                StorageService.saveBool('notifications', value);
              },
              Icons.notifications_rounded,
            ),
            const SizedBox(height: 24),
            _buildSectionTitle('Display Settings'),
            const SizedBox(height: 8),
            _buildToggleItem(
              'Dark Mode',
              'Switch to dark theme',
              _darkModeEnabled,
              (value) {
                setState(() => _darkModeEnabled = value);
                StorageService.saveBool('darkMode', value);
                // Update theme provider
                final themeProvider =
                    Provider.of<ThemeProvider>(context, listen: false);
                themeProvider.toggleTheme();
              },
              Icons.dark_mode_rounded,
            ),
            const SizedBox(height: 24),
            _buildSectionTitle('Account'),
            const SizedBox(height: 8),
            _buildNavigationItem(
              'Profile',
              'Manage your hospital profile',
              Icons.person_outline_rounded,
              () => Navigator.pushNamed(context, AppRoutes.hospitalProfile),
            ),
            const SizedBox(height: 24),
            _buildSectionTitle('Support'),
            const SizedBox(height: 8),
            _buildNavigationItem(
              'Privacy Policy',
              'Read our privacy policy',
              Icons.privacy_tip_rounded,
              _showPrivacyPolicy,
            ),
            _buildNavigationItem(
              'Help & Support',
              'Get help and contact support',
              Icons.help_outline_rounded,
              () {},
            ),
            const SizedBox(height: 32),
            Center(
              child: ElevatedButton.icon(
                onPressed: () async {
                  await StorageService.clear();
                  if (!mounted) return;
                  Navigator.pushNamedAndRemoveUntil(
                    context,
                    AppRoutes.login,
                    (route) => false,
                  );
                },
                icon: const Icon(Icons.logout_rounded),
                label: const Text('Logout'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.redAccent,
                  foregroundColor: Colors.white,
                  padding:
                      const EdgeInsets.symmetric(horizontal: 32, vertical: 12),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 16),
          ],
        ),
      ),
      bottomNavigationBar: CustomBottomNav(
        currentIndex: 3, // Settings tab
        onTap: (index) {
          if (index == 0)
            Navigator.pushReplacementNamed(
                context, AppRoutes.hospitalDashboard);
          if (index == 1)
            Navigator.pushReplacementNamed(context, AppRoutes.hospitalRequests);
          if (index == 2)
            Navigator.pushReplacementNamed(
                context, AppRoutes.hospitalAmbulance);
          if (index == 3) return; // Current page
        },
        items: const [
          BottomNavItem(icon: Icons.dashboard, label: 'Dashboard'),
          BottomNavItem(icon: Icons.emergency, label: 'Requests'),
          BottomNavItem(icon: Icons.directions_car, label: 'Ambulance'),
          BottomNavItem(icon: Icons.settings, label: 'Settings'),
        ],
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Text(
      title,
      style: const TextStyle(
        fontSize: 18,
        fontWeight: FontWeight.bold,
        color: AppColors.primary,
      ),
    );
  }

  Widget _buildToggleItem(
    String title,
    String subtitle,
    bool value,
    ValueChanged<bool> onChanged,
    IconData icon,
  ) {
    return CustomCard(
      child: SwitchListTile(
        title: Row(
          children: [
            Icon(icon, color: AppColors.primary),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title,
                      style: const TextStyle(fontWeight: FontWeight.w500)),
                  Text(
                    subtitle,
                    style: TextStyle(color: Colors.grey.shade600, fontSize: 12),
                  ),
                ],
              ),
            ),
          ],
        ),
        value: value,
        onChanged: onChanged,
        activeThumbColor: AppColors.primary,
      ),
    );
  }

  Widget _buildNavigationItem(
    String title,
    String subtitle,
    IconData icon,
    VoidCallback onTap,
  ) {
    return CustomCard(
      child: ListTile(
        leading: Icon(icon, color: AppColors.primary),
        title: Text(title, style: const TextStyle(fontWeight: FontWeight.w500)),
        subtitle: Text(subtitle,
            style: TextStyle(color: Colors.grey.shade600, fontSize: 12)),
        trailing: const Icon(Icons.arrow_forward_ios_rounded, size: 16),
        onTap: onTap,
      ),
    );
  }
}
