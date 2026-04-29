import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../shared/widgets.dart';
import '../../shared/models.dart';
import '../../core/routes.dart';
import '../../core/storage_service.dart';
import '../../core/constants.dart';
import '../../core/theme.dart';

class PoliceSettingsScreen extends StatefulWidget {
  const PoliceSettingsScreen({super.key});

  @override
  State<PoliceSettingsScreen> createState() => _PoliceSettingsScreenState();
}

class _PoliceSettingsScreenState extends State<PoliceSettingsScreen> {
  bool _notificationsEnabled = true;
  bool _darkModeEnabled = false;
  bool _emergencyAlertsEnabled = true;

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

    if (!mounted) return;
    setState(() {
      _darkModeEnabled = darkMode;
      _notificationsEnabled = notifications;
      _emergencyAlertsEnabled = emergencyAlerts;
    });
  }

  void _showPrivacyPolicy() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Privacy Policy'),
        content: const Text(
            'Your data is securely stored and only used for emergency response purposes.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }

  void _showActiveSessions() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Active Sessions'),
        content: const Text('You are currently logged in on this device only.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('OK'),
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
        title: 'Police Settings',
        showBackButton: false,
        actions: [
          IconButton(
            icon: const Icon(Icons.notifications_none_rounded,
                color: Colors.white),
            onPressed: () =>
                Navigator.pushNamed(context, AppRoutes.policeNotifications),
          ),
          IconButton(
            icon: const Icon(Icons.person_outline_rounded, color: Colors.white),
            onPressed: () =>
                Navigator.pushNamed(context, AppRoutes.policeProfile),
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
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
          physics: const BouncingScrollPhysics(),
          children: [
            _buildProfileCard(theme),
            const SizedBox(height: 16),
            _buildSectionHeader('Emergency Settings'),
            _buildSettingsGroup([
              _buildToggleItem(
                'Emergency Alerts',
                'Receive critical incident notifications',
                Icons.emergency_outlined,
                _emergencyAlertsEnabled,
                (val) {
                  setState(() => _emergencyAlertsEnabled = val);
                  StorageService.saveBool('emergencyAlerts', val);
                },
                Colors.red,
              ),
              _buildToggleItem(
                'Push Notifications',
                'General alerts and updates',
                Icons.notifications_active_outlined,
                _notificationsEnabled,
                (val) {
                  setState(() => _notificationsEnabled = val);
                  StorageService.saveBool('notifications', val);
                },
                Colors.orange,
              ),
            ]),
            const SizedBox(height: 16),
            _buildSectionHeader('Preferences'),
            _buildSettingsGroup([
              _buildToggleItem(
                'Dark Mode',
                'Reduce eye strain at night',
                Icons.dark_mode_outlined,
                _darkModeEnabled,
                (val) {
                  setState(() => _darkModeEnabled = val);
                  StorageService.saveBool('darkMode', val);
                  context.read<ThemeProvider>().toggleTheme();
                },
                Colors.purple,
              ),
              _buildNavigationItem(
                'Active Sessions',
                'Manage where you are logged in',
                Icons.devices_other_rounded,
                () => _showActiveSessions(),
              ),
            ]),
            const SizedBox(height: 16),
            _buildSectionHeader('Account'),
            _buildSettingsGroup([
              _buildNavigationItem(
                'Profile',
                'Manage your officer profile',
                Icons.person_outline_rounded,
                () => Navigator.pushNamed(context, AppRoutes.policeProfile),
              ),
            ]),
            const SizedBox(height: 16),
            _buildSettingsGroup([
              _buildNavigationItem(
                'Help Center',
                'FAQs and troubleshooting',
                Icons.help_outline_rounded,
                () => Navigator.pushNamed(context, AppRoutes.help),
              ),
              _buildNavigationItem(
                'About HumanSafety',
                'App information and mission',
                Icons.info_outline_rounded,
                () => Navigator.pushNamed(context, AppRoutes.about),
              ),
              _buildNavigationItem(
                'Privacy & Security',
                'Data handling and account settings',
                Icons.privacy_tip_outlined,
                () => Navigator.pushNamed(context, AppRoutes.privacy),
              ),
              _buildSimpleItem(
                'App Version',
                'v1.0.0 (Build 42)',
                Icons.info_outline_rounded,
              ),
            ]),
            const SizedBox(height: 16),
            _buildLogoutButton(),
            const SizedBox(height: 24),
          ],
        ),
      ),
      bottomNavigationBar: CustomBottomNav(
        currentIndex: 3,
        onTap: (index) {
          if (index == 0)
            Navigator.pushNamed(context, AppRoutes.policeDashboard);
          if (index == 1) Navigator.pushNamed(context, AppRoutes.policeAlerts);
          if (index == 2) Navigator.pushNamed(context, AppRoutes.policeCases);
          if (index == 3) return;
        },
        items: const [
          BottomNavItem(icon: Icons.dashboard, label: 'Dashboard'),
          BottomNavItem(icon: Icons.warning, label: 'Alerts'),
          BottomNavItem(icon: Icons.description, label: 'Cases'),
          BottomNavItem(icon: Icons.settings, label: 'Settings'),
        ],
      ),
    );
  }

  Widget _buildProfileCard(ThemeData theme) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.primary,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: AppColors.primary.withValues(alpha: 0.3),
            blurRadius: 15,
            offset: const Offset(0, 8),
          )
        ],
      ),
      child: Row(
        children: [
          const CircleAvatar(
            radius: 30,
            backgroundColor: Colors.white24,
            child: Icon(Icons.local_police, color: Colors.white, size: 35),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Police Officer',
                  style: TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      fontSize: 18),
                ),
                Text(
                  'Badge #12345',
                  style: TextStyle(
                      color: Colors.white.withValues(alpha: 0.8), fontSize: 14),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSectionHeader(String title) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Text(
        title,
        style: TextStyle(
          fontSize: 18,
          fontWeight: FontWeight.bold,
          color: Theme.of(context).textTheme.headlineSmall?.color,
        ),
      ),
    );
  }

  Widget _buildSettingsGroup(List<Widget> children) {
    return Container(
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(children: children),
    );
  }

  Widget _buildToggleItem(String title, String subtitle, IconData icon,
      bool value, Function(bool) onChanged, Color color) {
    return ListTile(
      leading: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Icon(icon, color: color),
      ),
      title: Text(title, style: const TextStyle(fontWeight: FontWeight.w500)),
      subtitle: Text(subtitle, style: const TextStyle(fontSize: 13)),
      trailing: Switch(
        value: value,
        onChanged: onChanged,
        activeThumbColor: color,
      ),
    );
  }

  Widget _buildNavigationItem(
      String title, String subtitle, IconData icon, VoidCallback onTap) {
    return ListTile(
      leading: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: Colors.grey.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Icon(icon, color: Colors.grey[600]),
      ),
      title: Text(title, style: const TextStyle(fontWeight: FontWeight.w500)),
      subtitle: Text(subtitle, style: const TextStyle(fontSize: 13)),
      trailing: const Icon(Icons.chevron_right, color: Colors.grey),
      onTap: onTap,
    );
  }

  Widget _buildSimpleItem(String title, String subtitle, IconData icon) {
    return ListTile(
      leading: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: Colors.grey.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Icon(icon, color: Colors.grey[600]),
      ),
      title: Text(title, style: const TextStyle(fontWeight: FontWeight.w500)),
      subtitle: Text(subtitle, style: const TextStyle(fontSize: 13)),
    );
  }

  Widget _buildLogoutButton() {
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.symmetric(horizontal: 16),
      child: ElevatedButton.icon(
        onPressed: () async {
          await StorageService.delete(AppConstants.tokenKey);
          if (!mounted) return;
          Navigator.pushNamedAndRemoveUntil(
              context, AppRoutes.login, (route) => false);
        },
        icon: const Icon(Icons.logout, color: Colors.white),
        label: const Text('Logout', style: TextStyle(color: Colors.white)),
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.redAccent,
          padding: const EdgeInsets.symmetric(vertical: 16),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
      ),
    );
  }
}
