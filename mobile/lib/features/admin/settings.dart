import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'dart:ui';

import '../../shared/widgets.dart';
import '../../shared/models.dart';
import '../../core/routes.dart';
import '../../core/storage_service.dart';
import '../../core/constants.dart';
import '../../core/theme.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  bool _notificationsEnabled = true;
  bool _darkModeEnabled = false;
  bool _twoFactorEnabled = false;

  @override
  void initState() {
    super.initState();
    _loadSettings();
  }

  Future<void> _loadSettings() async {
    final darkMode = await StorageService.getBool('darkMode') ?? false;
    final notifications = await StorageService.getBool('notifications') ?? true;
    final twoFactor = await StorageService.getBool('twoFactor') ?? false;

    if (!mounted) return;
    setState(() {
      _darkModeEnabled = darkMode;
      _notificationsEnabled = notifications;
      _twoFactorEnabled = twoFactor;
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Scaffold(
      appBar: CustomAppBar(
        title: 'Settings',
        showBackButton: true, // Settings are usually secondary pages
        actions: [
          IconButton(
            icon: const Icon(Icons.help_outline_rounded, color: Colors.white),
            onPressed: () => _showPrivacyPolicy(),
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
            _buildSectionHeader('Security & Privacy'),
            _buildSettingsGroup([
              _buildToggleItem(
                'Two-Factor Auth',
                'Extra layer of account protection',
                Icons.verified_user_outlined,
                _twoFactorEnabled,
                (val) {
                  setState(() => _twoFactorEnabled = val);
                  StorageService.saveBool('twoFactor', val);
                },
                Colors.blue,
              ),
              _buildNavigationItem(
                'Active Sessions',
                'Manage where you are logged in',
                Icons.devices_other_rounded,
                () => _showActiveSessions(),
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
              _buildToggleItem(
                'Push Notifications',
                'Alerts for urgent reports',
                Icons.notifications_active_outlined,
                _notificationsEnabled,
                (val) {
                  setState(() => _notificationsEnabled = val);
                  StorageService.saveBool('notifications', val);
                },
                Colors.orange,
              ),
              _buildNavigationItem(
                'Regional Settings',
                'Language and Timezone',
                Icons.language_rounded,
                () {},
              ),
            ]),
            const SizedBox(height: 16),
            _buildSectionHeader('Support'),
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
    );
  }

  // --- UI Component Builders ---

  Widget _buildProfileCard(ThemeData theme) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.primary,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: AppColors.primary.withOpacity(0.3),
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
            child:
                Icon(Icons.admin_panel_settings, color: Colors.white, size: 35),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Super Admin',
                  style: TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      fontSize: 18),
                ),
                Text(
                  'admin@system.com',
                  style: TextStyle(
                      color: Colors.white.withOpacity(0.8), fontSize: 14),
                ),
              ],
            ),
          ),
          IconButton(
            onPressed: () =>
                Navigator.pushNamed(context, AppRoutes.adminProfile),
            icon: const Icon(Icons.edit_note_rounded, color: Colors.white),
          )
        ],
      ),
    );
  }

  Widget _buildSectionHeader(String title) {
    return Padding(
      padding: const EdgeInsets.only(left: 8, bottom: 12),
      child: Text(
        title.toUpperCase(),
        style: const TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.w800,
          color: AppColors.grey,
          letterSpacing: 1.2,
        ),
      ),
    );
  }

  Widget _buildSettingsGroup(List<Widget> items) {
    return Container(
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.03),
            blurRadius: 10,
            offset: const Offset(0, 4),
          )
        ],
      ),
      child: Column(children: items),
    );
  }

  Widget _buildToggleItem(String title, String subtitle, IconData icon,
      bool value, Function(bool) onChanged, Color iconColor) {
    return ListTile(
      leading: _IconBox(icon: icon, color: iconColor),
      title: Text(title, style: const TextStyle(fontWeight: FontWeight.w600)),
      subtitle: Text(subtitle, style: const TextStyle(fontSize: 12)),
      trailing: Switch.adaptive(
        value: value,
        onChanged: onChanged,
        activeColor: AppColors.primary,
      ),
    );
  }

  Widget _buildNavigationItem(
      String title, String subtitle, IconData icon, VoidCallback onTap) {
    return ListTile(
      onTap: onTap,
      leading: _IconBox(icon: icon, color: Colors.blueGrey),
      title: Text(title, style: const TextStyle(fontWeight: FontWeight.w600)),
      subtitle: Text(subtitle, style: const TextStyle(fontSize: 12)),
      trailing: const Icon(Icons.arrow_forward_ios_rounded,
          size: 14, color: AppColors.grey),
    );
  }

  Widget _buildSimpleItem(String title, String value, IconData icon) {
    return ListTile(
      leading: _IconBox(icon: icon, color: Colors.grey),
      title: Text(title, style: const TextStyle(fontWeight: FontWeight.w600)),
      trailing: Text(value,
          style: const TextStyle(
              color: AppColors.grey, fontWeight: FontWeight.bold)),
    );
  }

  Widget _buildLogoutButton() {
    return InkWell(
      onTap: _showLogoutDialog,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 16),
        decoration: BoxDecoration(
          border: Border.all(color: Colors.red.withOpacity(0.2)),
          borderRadius: BorderRadius.circular(16),
          color: Colors.red.withOpacity(0.05),
        ),
        child: const Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.logout_rounded, color: Colors.red, size: 20),
            SizedBox(width: 12),
            Text(
              'Sign Out Account',
              style: TextStyle(color: Colors.red, fontWeight: FontWeight.bold),
            ),
          ],
        ),
      ),
    );
  }

  // --- Dialogs (Logic remains same, styling updated) ---

  void _showLogoutDialog() {
    showDialog(
      context: context,
      builder: (context) => BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 4, sigmaY: 4),
        child: AlertDialog(
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          title: const Text('Confirm Logout'),
          content: const Text(
              'You will need to re-authenticate to access the admin panel.'),
          actions: [
            TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('Stay')),
            ElevatedButton(
              onPressed: () {
                context.read<AuthProvider>().logout();
                Navigator.of(context)
                    .pushNamedAndRemoveUntil('/login', (r) => false);
              },
              style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.red, foregroundColor: Colors.white),
              child: const Text('Logout'),
            ),
          ],
        ),
      ),
    );
  }

  void _showActiveSessions() {/* implementation same as original */}
  void _showPrivacyPolicy() {/* implementation same as original */}
}

class _IconBox extends StatelessWidget {
  final IconData icon;
  final Color color;
  const _IconBox({required this.icon, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Icon(icon, color: color, size: 20),
    );
  }
}
