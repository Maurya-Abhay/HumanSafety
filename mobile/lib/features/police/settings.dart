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
    final emergencyAlerts = await StorageService.getBool('emergencyAlerts') ?? true;

    if (!mounted) return;
    setState(() {
      _darkModeEnabled = darkMode;
      _notificationsEnabled = notifications;
      _emergencyAlertsEnabled = emergencyAlerts;
    });
  }

  void _showActiveSessions() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Row(
          children: [
            Icon(Icons.devices_other_rounded, color: AppColors.primary),
            SizedBox(width: 10),
            Text('Active Sessions'),
          ],
        ),
        content: const Text('You are currently logged in on this Samsung Galaxy S24 device only.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Dismiss', style: TextStyle(color: Colors.grey)),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context),
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.primary),
            child: const Text('Confirm', style: TextStyle(color: Colors.white)),
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
      backgroundColor: isDark ? const Color(0xFF0F172A) : const Color(0xFFF8FAFC),
      appBar: CustomAppBar(
        title: 'Settings',
        showBackButton: false,
        actions: [
          _buildActionCircle(Icons.notifications_none_rounded, AppRoutes.policeNotifications),
          _buildActionCircle(Icons.person_outline_rounded, AppRoutes.policeProfile),
          const SizedBox(width: 8),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(20, 20, 20, 30),
        physics: const BouncingScrollPhysics(),
        children: [
          _buildProfileHeader(isDark),
          const SizedBox(height: 24),
          _buildSectionHeader('Priority Alerts'),
          _buildSettingsContainer([
            _buildToggleItem(
              'Critical Alerts',
              'Override silent mode for emergencies',
              Icons.emergency_rounded,
              _emergencyAlertsEnabled,
              (val) {
                setState(() => _emergencyAlertsEnabled = val);
                StorageService.saveBool('emergencyAlerts', val);
              },
              Colors.redAccent,
            ),
            _buildToggleItem(
              'Push Notifications',
              'Update on case assignments',
              Icons.notifications_active_rounded,
              _notificationsEnabled,
              (val) {
                setState(() => _notificationsEnabled = val);
                StorageService.saveBool('notifications', val);
              },
              Colors.blueAccent,
            ),
          ]),
          const SizedBox(height: 24),
          _buildSectionHeader('Appearance & Security'),
          _buildSettingsContainer([
            _buildToggleItem(
              'Dark Interface',
              'Optimal for night patrolling',
              Icons.nightlight_round_sharp,
              _darkModeEnabled,
              (val) {
                setState(() => _darkModeEnabled = val);
                StorageService.saveBool('darkMode', val);
                context.read<ThemeProvider>().toggleTheme();
              },
              Colors.indigoAccent,
            ),
            _buildNavigationItem(
              'Security Key',
              'Manage 2FA and active devices',
              Icons.security_rounded,
              () => _showActiveSessions(),
            ),
          ]),
          const SizedBox(height: 24),
          _buildSectionHeader('Support'),
          _buildSettingsContainer([
            _buildNavigationItem(
              'Help Center',
              'Manuals and SOPs',
              Icons.help_center_rounded,
              () => Navigator.pushNamed(context, AppRoutes.help),
            ),
            _buildNavigationItem(
              'About System',
              'Version 2.4.0-Stable',
              Icons.info_rounded,
              () => Navigator.pushNamed(context, AppRoutes.about),
            ),
          ]),
          const SizedBox(height: 32),
          _buildLogoutButton(),
        ],
      ),
      bottomNavigationBar: _buildBottomNav(context, 3),
    );
  }

  Widget _buildActionCircle(IconData icon, String route) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 4),
      decoration: BoxDecoration(color: Colors.white.withOpacity(0.15), shape: BoxShape.circle),
      child: IconButton(
        icon: Icon(icon, color: Colors.white, size: 22),
        onPressed: () => Navigator.pushNamed(context, route),
      ),
    );
  }

  Widget _buildProfileHeader(bool isDark) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [AppColors.primary, Color(0xFF2563EB)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: AppColors.primary.withOpacity(0.3),
            blurRadius: 20,
            offset: const Offset(0, 10),
          )
        ],
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(4),
            decoration: const BoxDecoration(color: Colors.white24, shape: BoxShape.circle),
            child: const CircleAvatar(
              radius: 28,
              backgroundColor: Colors.white,
              child: Icon(Icons.local_police_rounded, color: AppColors.primary, size: 30),
            ),
          ),
          const SizedBox(width: 16),
          const Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Officer John Doe',
                  style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 18),
                ),
                Text(
                  'Badge ID: #882-934',
                  style: TextStyle(color: Colors.white70, fontSize: 13),
                ),
              ],
            ),
          ),
          IconButton(
            onPressed: () => Navigator.pushNamed(context, AppRoutes.policeProfile),
            icon: const Icon(Icons.arrow_forward_ios_rounded, color: Colors.white, size: 18),
          )
        ],
      ),
    );
  }

  Widget _buildSectionHeader(String title) {
    return Padding(
      padding: const EdgeInsets.only(left: 4, bottom: 12),
      child: Text(
        title.toUpperCase(),
        style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w800, color: Colors.blueGrey, letterSpacing: 1.2),
      ),
    );
  }

  Widget _buildSettingsContainer(List<Widget> children) {
    return Container(
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: Colors.black.withOpacity(0.05)),
      ),
      child: Column(children: children),
    );
  }

  Widget _buildToggleItem(String title, String subtitle, IconData icon, bool value, Function(bool) onChanged, Color color) {
    return ListTile(
      leading: Container(
        padding: const EdgeInsets.all(10),
        decoration: BoxDecoration(color: color.withOpacity(0.1), borderRadius: BorderRadius.circular(12)),
        child: Icon(icon, color: color, size: 22),
      ),
      title: Text(title, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
      subtitle: Text(subtitle, style: const TextStyle(fontSize: 12, color: Colors.grey)),
      trailing: Switch.adaptive(
        value: value,
        onChanged: onChanged,
        activeColor: color,
      ),
    );
  }

  Widget _buildNavigationItem(String title, String subtitle, IconData icon, VoidCallback onTap) {
    return ListTile(
      onTap: onTap,
      leading: Container(
        padding: const EdgeInsets.all(10),
        decoration: BoxDecoration(color: Colors.grey.withOpacity(0.1), borderRadius: BorderRadius.circular(12)),
        child: Icon(icon, color: Colors.grey.shade600, size: 22),
      ),
      title: Text(title, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
      subtitle: Text(subtitle, style: const TextStyle(fontSize: 12, color: Colors.grey)),
      trailing: const Icon(Icons.chevron_right_rounded, color: Colors.grey),
    );
  }

  Widget _buildLogoutButton() {
    return Container(
      width: double.infinity,
      child: TextButton.icon(
        onPressed: () async {
          await StorageService.delete(AppConstants.tokenKey);
          if (!mounted) return;
          Navigator.pushNamedAndRemoveUntil(context, AppRoutes.login, (route) => false);
        },
        icon: const Icon(Icons.logout_rounded, color: Colors.redAccent),
        label: const Text('Sign Out Account', style: TextStyle(color: Colors.redAccent, fontWeight: FontWeight.bold)),
        style: TextButton.styleFrom(
          padding: const EdgeInsets.symmetric(vertical: 16),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
            side: const BorderSide(color: Colors.redAccent, width: 1.5),
          ),
        ),
      ),
    );
  }

  Widget _buildBottomNav(BuildContext context, int index) {
    return CustomBottomNav(
      currentIndex: index,
      onTap: (i) {
        if (i == index) return;
        if (i == 0) Navigator.pushReplacementNamed(context, AppRoutes.policeDashboard);
        if (i == 1) Navigator.pushReplacementNamed(context, AppRoutes.policeAlerts);
        if (i == 2) Navigator.pushReplacementNamed(context, AppRoutes.policeCases);
        if (i == 3) return;
      },
      items: const [
        BottomNavItem(icon: Icons.dashboard_rounded, label: 'Home'),
        BottomNavItem(icon: Icons.bolt_rounded, label: 'Alerts'),
        BottomNavItem(icon: Icons.assignment_rounded, label: 'Cases'),
        BottomNavItem(icon: Icons.settings_rounded, label: 'Settings'),
      ],
    );
  }
}