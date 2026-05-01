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
  bool _emailNotifications = true;
  bool _criticalAlertsOnly = false;
  bool _soundEnabled = true;
  bool _dataCollectionEnabled = true;

  @override
  void initState() {
    super.initState();
    _loadSettings();
  }

  Future<void> _loadSettings() async {
    final darkMode = await StorageService.getBool('darkMode') ?? false;
    final notifications = await StorageService.getBool('notifications') ?? true;
    final twoFactor = await StorageService.getBool('twoFactor') ?? false;
    final email = await StorageService.getBool('emailNotifications') ?? true;
    final critical = await StorageService.getBool('criticalAlertsOnly') ?? false;
    final sound = await StorageService.getBool('soundEnabled') ?? true;
    final dataCollection = await StorageService.getBool('dataCollection') ?? true;

    if (!mounted) return;
    setState(() {
      _darkModeEnabled = darkMode;
      _notificationsEnabled = notifications;
      _twoFactorEnabled = twoFactor;
      _emailNotifications = email;
      _criticalAlertsOnly = critical;
      _soundEnabled = sound;
      _dataCollectionEnabled = dataCollection;
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Scaffold(
      appBar: CustomAppBar(
        title: 'Settings',
        showBackButton: true,
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
            const SizedBox(height: 20),
            
            // Account Security
            _buildSectionHeader('Account Security'),
            _buildSettingsGroup([
              _buildToggleItem(
                'Two-Factor Authentication',
                'Extra layer of account protection',
                Icons.verified_user_outlined,
                _twoFactorEnabled,
                (val) {
                  setState(() => _twoFactorEnabled = val);
                  StorageService.saveBool('twoFactor', val);
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text(val ? '2FA enabled' : '2FA disabled')),
                  );
                },
                Colors.blue,
              ),
              _buildNavigationItem(
                'Change Password',
                'Update your account password',
                Icons.lock_outline_rounded,
                () => _showChangePasswordDialog(),
              ),
              _buildNavigationItem(
                'Active Sessions',
                'Manage where you are logged in',
                Icons.devices_other_rounded,
                () => _showActiveSessions(),
              ),
            ]),
            const SizedBox(height: 20),

            // Notification Preferences
            _buildSectionHeader('Notifications'),
            _buildSettingsGroup([
              _buildToggleItem(
                'Push Notifications',
                'Receive emergency alerts on device',
                Icons.notifications_active_outlined,
                _notificationsEnabled,
                (val) {
                  setState(() => _notificationsEnabled = val);
                  StorageService.saveBool('notifications', val);
                },
                Colors.orange,
              ),
              _buildToggleItem(
                'Email Notifications',
                'Receive updates via email',
                Icons.mail_outline_rounded,
                _emailNotifications,
                (val) {
                  setState(() => _emailNotifications = val);
                  StorageService.saveBool('emailNotifications', val);
                },
                Colors.amber,
              ),
              _buildToggleItem(
                'Critical Alerts Only',
                'Reduce notification frequency',
                Icons.priority_high_rounded,
                _criticalAlertsOnly,
                (val) {
                  setState(() => _criticalAlertsOnly = val);
                  StorageService.saveBool('criticalAlertsOnly', val);
                },
                Colors.red,
              ),
              _buildToggleItem(
                'Sound Notifications',
                'Play sound on alert arrival',
                Icons.volume_up_outlined,
                _soundEnabled,
                (val) {
                  setState(() => _soundEnabled = val);
                  StorageService.saveBool('soundEnabled', val);
                },
                Colors.green,
              ),
            ]),
            const SizedBox(height: 20),

            // Appearance
            _buildSectionHeader('Appearance'),
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
                'Theme Color',
                'Customize accent color',
                Icons.palette_outlined,
                () => _showThemeColorPicker(),
              ),
              _buildNavigationItem(
                'Regional Settings',
                'Language and Timezone',
                Icons.language_rounded,
                () => _showRegionalSettings(),
              ),
            ]),
            const SizedBox(height: 20),

            // System Management
            _buildSectionHeader('System Management'),
            _buildSettingsGroup([
              _buildNavigationItem(
                'User Roles & Permissions',
                'Manage admin access levels',
                Icons.security_outlined,
                () => _showRolesManagement(),
              ),
              _buildNavigationItem(
                'System Logs',
                'View activity logs',
                Icons.description_outlined,
                () => _showSystemLogs(),
              ),
              _buildNavigationItem(
                'Database Backup',
                'Export and backup data',
                Icons.backup_outlined,
                () => _showBackupOptions(),
              ),
              _buildNavigationItem(
                'API Keys',
                'Developer API configuration',
                Icons.vpn_key_outlined,
                () => _showApiKeys(),
              ),
            ]),
            const SizedBox(height: 20),

            // Data & Privacy
            _buildSectionHeader('Data & Privacy'),
            _buildSettingsGroup([
              _buildToggleItem(
                'Data Collection',
                'Help improve the app with usage data',
                Icons.analytics_outlined,
                _dataCollectionEnabled,
                (val) {
                  setState(() => _dataCollectionEnabled = val);
                  StorageService.saveBool('dataCollection', val);
                },
                Colors.teal,
              ),
              _buildNavigationItem(
                'Privacy Policy',
                'Read our privacy terms',
                Icons.privacy_tip_outlined,
                () => Navigator.pushNamed(context, AppRoutes.privacy),
              ),
              _buildNavigationItem(
                'Terms of Service',
                'Usage terms and conditions',
                Icons.description_outlined,
                () => _showTermsOfService(),
              ),
              _buildNavigationItem(
                'Data Export',
                'Download your data',
                Icons.download_outlined,
                () => _showDataExportOptions(),
              ),
            ]),
            const SizedBox(height: 20),

            // Support & Help
            _buildSectionHeader('Support & Help'),
            _buildSettingsGroup([
              _buildNavigationItem(
                'Help Center',
                'FAQs and troubleshooting',
                Icons.help_outline_rounded,
                () => Navigator.pushNamed(context, AppRoutes.help),
              ),
              _buildNavigationItem(
                'Report Issue',
                'Submit a bug or suggestion',
                Icons.bug_report_outlined,
                () => _showReportIssueDialog(),
              ),
              _buildNavigationItem(
                'Contact Support',
                'Get help from our team',
                Icons.support_agent_rounded,
                () => _showContactSupport(),
              ),
              _buildNavigationItem(
                'About HumanSafety',
                'App version and information',
                Icons.info_outline_rounded,
                () => _showAboutApp(),
              ),
            ]),
            const SizedBox(height: 20),

            _buildLogoutButton(),
            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }

  Widget _buildProfileCard(ThemeData theme) {
    final admin = context.watch<AuthProvider>().user;
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [AppColors.primary, Color(0xFF6C63FF)],
        ),
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
          Container(
            padding: const EdgeInsets.all(2),
            decoration: const BoxDecoration(
              shape: BoxShape.circle,
              color: Colors.white24,
            ),
            child: const CircleAvatar(
              radius: 30,
              backgroundColor: Colors.white24,
              child: Icon(Icons.admin_panel_settings, color: Colors.white, size: 35),
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  admin?.name ?? 'Super Admin',
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: 18,
                  ),
                ),
                Text(
                  admin?.email ?? 'admin@system.com',
                  style: TextStyle(
                    color: Colors.white.withValues(alpha: 0.8),
                    fontSize: 14,
                  ),
                ),
              ],
            ),
          ),
          IconButton(
            onPressed: () => Navigator.pushNamed(context, AppRoutes.adminProfile),
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
            color: Colors.black.withValues(alpha: 0.03),
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

  Widget _buildLogoutButton() {
    return InkWell(
      onTap: _showLogoutDialog,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 16),
        decoration: BoxDecoration(
          border: Border.all(color: Colors.red.withValues(alpha: 0.2)),
          borderRadius: BorderRadius.circular(16),
          color: Colors.red.withValues(alpha: 0.05),
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

  // Dialog Methods
  void _showLogoutDialog() {
    showDialog(
      context: context,
      builder: (context) => BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 4, sigmaY: 4),
        child: AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          title: const Text('Confirm Logout'),
          content: const Text('You will need to re-authenticate to access the admin panel.'),
          actions: [
            TextButton(onPressed: () => Navigator.pop(context), child: const Text('Stay')),
            ElevatedButton(
              onPressed: () {
                context.read<AuthProvider>().logout();
                Navigator.of(context).pushNamedAndRemoveUntil('/login', (r) => false);
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.red,
                foregroundColor: Colors.white,
              ),
              child: const Text('Logout'),
            ),
          ],
        ),
      ),
    );
  }

  void _showChangePasswordDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text('Change Password'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              obscureText: true,
              decoration: InputDecoration(
                hintText: 'Current Password',
                filled: true,
                fillColor: AppColors.grey.withValues(alpha: 0.1),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              obscureText: true,
              decoration: InputDecoration(
                hintText: 'New Password',
                filled: true,
                fillColor: AppColors.grey.withValues(alpha: 0.1),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              obscureText: true,
              decoration: InputDecoration(
                hintText: 'Confirm Password',
                filled: true,
                fillColor: AppColors.grey.withValues(alpha: 0.1),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Password updated successfully')),
              );
            },
            child: const Text('Update'),
          ),
        ],
      ),
    );
  }

  void _showActiveSessions() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text('Active Sessions'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            _buildSessionItem('This Device', 'Active now', Icons.check_circle, Colors.green),
            _buildSessionItem('Phone', 'Last active 2h ago', Icons.phone_android, Colors.grey),
            _buildSessionItem('Tablet', 'Last active 5d ago', Icons.tablet, Colors.grey),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Close')),
        ],
      ),
    );
  }

  Widget _buildSessionItem(String device, String status, IconData icon, Color color) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        children: [
          Icon(icon, color: color),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(device, style: const TextStyle(fontWeight: FontWeight.w600)),
                Text(status, style: const TextStyle(fontSize: 12, color: AppColors.grey)),
              ],
            ),
          ),
        ],
      ),
    );
  }

  void _showThemeColorPicker() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text('Choose Theme Color'),
        content: Wrap(
          spacing: 12,
          children: [Colors.blue, Colors.purple, Colors.red, Colors.green, Colors.orange]
              .map((color) => GestureDetector(
                onTap: () => Navigator.pop(context),
                child: CircleAvatar(radius: 24, backgroundColor: color),
              ))
              .toList(),
        ),
      ),
    );
  }

  void _showRegionalSettings() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text('Regional Settings'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            DropdownButtonFormField(
              decoration: InputDecoration(
                labelText: 'Language',
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
              ),
              items: const [
                DropdownMenuItem(value: 'en', child: Text('English')),
                DropdownMenuItem(value: 'hi', child: Text('Hindi')),
              ],
              onChanged: (val) {},
            ),
            const SizedBox(height: 12),
            DropdownButtonFormField(
              decoration: InputDecoration(
                labelText: 'Timezone',
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
              ),
              items: const [
                DropdownMenuItem(value: 'ist', child: Text('IST (India)')),
                DropdownMenuItem(value: 'utc', child: Text('UTC')),
              ],
              onChanged: (val) {},
            ),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
          ElevatedButton(onPressed: () => Navigator.pop(context), child: const Text('Save')),
        ],
      ),
    );
  }

  void _showRolesManagement() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text('User Roles & Permissions'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            _buildRoleItem('Super Admin', 'Full system access', Colors.red),
            _buildRoleItem('Admin', 'Manage users and cases', Colors.orange),
            _buildRoleItem('Dispatcher', 'Assign cases to police', Colors.blue),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Close')),
        ],
      ),
    );
  }

  Widget _buildRoleItem(String role, String permissions, Color color) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: color.withValues(alpha: 0.3)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(role, style: TextStyle(fontWeight: FontWeight.bold, color: color)),
            Text(permissions, style: const TextStyle(fontSize: 12, color: AppColors.grey)),
          ],
        ),
      ),
    );
  }

  void _showSystemLogs() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text('System Logs'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              _buildLogEntry('User Login', 'Admin logged in', '10:30 AM'),
              _buildLogEntry('Case Created', 'New emergency case #12345', '10:15 AM'),
              _buildLogEntry('User Updated', 'User profile changed', '09:45 AM'),
            ],
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Close')),
        ],
      ),
    );
  }

  Widget _buildLogEntry(String action, String description, String time) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(action, style: const TextStyle(fontWeight: FontWeight.w600)),
                Text(description, style: const TextStyle(fontSize: 12, color: AppColors.grey)),
              ],
            ),
          ),
          Text(time, style: const TextStyle(fontSize: 12, color: AppColors.grey)),
        ],
      ),
    );
  }

  void _showBackupOptions() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text('Database Backup'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            _buildBackupOption('Manual Backup', 'Create backup now', Icons.cloud_download),
            const SizedBox(height: 12),
            _buildBackupOption('Auto Backup', 'Enable daily backups', Icons.schedule),
            const SizedBox(height: 12),
            _buildBackupOption('Restore', 'Restore from backup', Icons.restore),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Close')),
        ],
      ),
    );
  }

  Widget _buildBackupOption(String title, String subtitle, IconData icon) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        border: Border.all(color: AppColors.grey.withValues(alpha: 0.2)),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          Icon(icon, color: AppColors.primary),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: const TextStyle(fontWeight: FontWeight.w600)),
                Text(subtitle, style: const TextStyle(fontSize: 12, color: AppColors.grey)),
              ],
            ),
          ),
        ],
      ),
    );
  }

  void _showApiKeys() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text('API Keys'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            _buildApiKeyItem('Production', 'sk_live_abc123...', Colors.green),
            const SizedBox(height: 12),
            _buildApiKeyItem('Sandbox', 'sk_test_xyz789...', Colors.orange),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Close')),
          ElevatedButton(onPressed: () => Navigator.pop(context), child: const Text('Generate New')),
        ],
      ),
    );
  }

  Widget _buildApiKeyItem(String env, String key, Color color) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withValues(alpha: 0.3)),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(env, style: TextStyle(fontWeight: FontWeight.w600, color: color)),
              Text(key, style: const TextStyle(fontSize: 12, color: AppColors.grey, fontFamily: 'monospace')),
            ],
          ),
          IconButton(
            icon: const Icon(Icons.content_copy),
            onPressed: () {
              ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Copied!')));
            },
          ),
        ],
      ),
    );
  }

  void _showDataExportOptions() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text('Data Export'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            _buildExportOption('CSV', 'Export as spreadsheet', Icons.table_chart),
            const SizedBox(height: 12),
            _buildExportOption('JSON', 'Export as JSON file', Icons.code),
            const SizedBox(height: 12),
            _buildExportOption('PDF Report', 'Generate PDF report', Icons.picture_as_pdf),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
        ],
      ),
    );
  }

  Widget _buildExportOption(String format, String description, IconData icon) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        border: Border.all(color: AppColors.grey.withValues(alpha: 0.2)),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          Icon(icon, color: AppColors.primary),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(format, style: const TextStyle(fontWeight: FontWeight.w600)),
                Text(description, style: const TextStyle(fontSize: 12, color: AppColors.grey)),
              ],
            ),
          ),
          const Icon(Icons.download, size: 20),
        ],
      ),
    );
  }

  void _showReportIssueDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text('Report Issue'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              decoration: InputDecoration(
                hintText: 'Issue title',
                filled: true,
                fillColor: AppColors.grey.withValues(alpha: 0.1),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              maxLines: 4,
              decoration: InputDecoration(
                hintText: 'Describe the issue...',
                filled: true,
                fillColor: AppColors.grey.withValues(alpha: 0.1),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Issue reported successfully')),
              );
            },
            child: const Text('Submit'),
          ),
        ],
      ),
    );
  }

  void _showContactSupport() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text('Contact Support'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            _buildContactOption('Email', 'support@humansafety.app', Icons.mail),
            const SizedBox(height: 12),
            _buildContactOption('Phone', '+91 1234567890', Icons.phone),
            const SizedBox(height: 12),
            _buildContactOption('Live Chat', 'Available 9 AM - 6 PM', Icons.chat),
          ],
        ),
      ),
    );
  }

  Widget _buildContactOption(String method, String info, IconData icon) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        border: Border.all(color: AppColors.grey.withValues(alpha: 0.2)),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          Icon(icon, color: AppColors.primary),
          const SizedBox(width: 12),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(method, style: const TextStyle(fontWeight: FontWeight.w600)),
              Text(info, style: const TextStyle(fontSize: 12, color: AppColors.grey)),
            ],
          ),
        ],
      ),
    );
  }

  void _showAboutApp() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text('About HumanSafety'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.shield_rounded, size: 48, color: AppColors.primary),
            const SizedBox(height: 16),
            const Text('HumanSafety Admin Portal', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            const Text('v1.0.0 (Build 42)', style: TextStyle(color: AppColors.grey)),
            const SizedBox(height: 16),
            const Text(
              'A comprehensive emergency management system designed to coordinate responders and save lives.',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 13),
            ),
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: BoxDecoration(
                color: AppColors.primary.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Text('© 2026 HumanSafety. All rights reserved.', style: TextStyle(fontSize: 12)),
            ),
          ],
        ),
      ),
    );
  }

  void _showTermsOfService() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text('Terms of Service'),
        content: const SingleChildScrollView(
          child: Text('Terms and conditions content here...'),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Close')),
        ],
      ),
    );
  }

  void _showPrivacyPolicy() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text('Privacy Policy'),
        content: const SingleChildScrollView(
          child: Text('Privacy policy content here...'),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Close')),
        ],
      ),
    );
  }
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
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Icon(icon, color: color, size: 20),
    );
  }
}
