import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../shared/widgets.dart';
import '../../shared/models.dart';
import '../../core/theme.dart';
import '../../core/api_service.dart';
import '../../core/storage_service.dart';
import '../../core/constants.dart';

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
    
    setState(() {
      _darkModeEnabled = darkMode;
      _notificationsEnabled = notifications;
      _twoFactorEnabled = twoFactor;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: const CustomAppBar(title: 'Settings', showBackButton: true),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Profile Section
            _buildSectionTitle('Profile'),
            _buildSettingItem(
              'Edit Profile',
              'Update your personal information',
              Icons.person_outline,
              () => _showProfileBottomSheet(),
            ),
            _buildSettingItem(
              'Change Password',
              'Update your security password',
              Icons.lock_outline,
              () => _showChangePasswordDialog(),
            ),
            const SizedBox(height: 24),

            // Notifications Section
            _buildSectionTitle('Notifications'),
            _buildToggleSetting(
              'Enable Notifications',
              'Receive alerts and updates',
              Icons.notifications_outlined,
              _notificationsEnabled,
              (value) {
                setState(() => _notificationsEnabled = value);
                StorageService.saveBool('notifications', value);
              },
            ),
            _buildSettingItem(
              'Notification Preferences',
              'Configure notification types',
              Icons.tune_outlined,
              () => _showNotificationSettings(),
            ),
            const SizedBox(height: 24),

            // Display Section
            _buildSectionTitle('Display'),
            _buildToggleSetting(
              'Dark Mode',
              'Use dark theme for better visibility',
              Icons.dark_mode_outlined,
              _darkModeEnabled,
              (value) {
                setState(() => _darkModeEnabled = value);
                StorageService.saveBool('darkMode', value);
                context.read<ThemeProvider>().toggleDarkMode();
              },
            ),
            const SizedBox(height: 24),

            // Security Section
            _buildSectionTitle('Security'),
            _buildToggleSetting(
              'Two-Factor Authentication',
              'Add extra security to your account',
              Icons.security_outlined,
              _twoFactorEnabled,
              (value) {
                setState(() => _twoFactorEnabled = value);
                StorageService.saveBool('twoFactor', value);
              },
            ),
            _buildSettingItem(
              'Active Sessions',
              'Manage your login sessions',
              Icons.devices_outlined,
              () => _showActiveSessions(),
            ),
            const SizedBox(height: 24),

            // About Section
            _buildSectionTitle('About'),
            _buildSettingItem(
              'App Version',
              'v1.0.0 (Build 1)',
              Icons.info_outline,
              null,
            ),
            _buildSettingItem(
              'Feedback',
              'Send us your feedback',
              Icons.feedback_outlined,
              () => _showFeedbackDialog(),
            ),
            _buildSettingItem(
              'Privacy Policy',
              'Read our privacy policy',
              Icons.policy_outlined,
              () => _showPrivacyPolicy(),
            ),
            const SizedBox(height: 24),

            // Danger Zone
            _buildSectionTitle('Danger Zone'),
            Container(
              decoration: BoxDecoration(
                border: Border.all(color: Colors.red.withOpacity(0.5)),
                borderRadius: BorderRadius.circular(12),
              ),
              child: ListTile(
                leading: const Icon(Icons.logout, color: Colors.red),
                title: const Text('Logout', style: TextStyle(color: Colors.red)),
                subtitle: const Text('Sign out of your account'),
                onTap: _showLogoutDialog,
              ),
            ),
            const SizedBox(height: 32),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Text(
        title,
        style: Theme.of(context).textTheme.titleMedium?.copyWith(
          fontWeight: FontWeight.bold,
          color: AppColors.primary,
        ),
      ),
    );
  }

  Widget _buildSettingItem(
    String title,
    String subtitle,
    IconData icon,
    VoidCallback? onTap,
  ) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: CustomCard(
        child: ListTile(
          leading: Icon(icon, color: AppColors.primary),
          title: Text(title),
          subtitle: Text(subtitle, maxLines: 1, overflow: TextOverflow.ellipsis),
          trailing: onTap != null ? const Icon(Icons.arrow_forward_ios, size: 16) : null,
          onTap: onTap,
        ),
      ),
    );
  }

  Widget _buildToggleSetting(
    String title,
    String subtitle,
    IconData icon,
    bool value,
    Function(bool) onChanged,
  ) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: CustomCard(
        child: ListTile(
          leading: Icon(icon, color: AppColors.primary),
          title: Text(title),
          subtitle: Text(subtitle),
          trailing: Switch(
            value: value,
            onChanged: onChanged,
          ),
        ),
      ),
    );
  }

  void _showProfileBottomSheet() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (context) => Consumer<AuthProvider>(
        builder: (context, authProvider, _) {
          final user = authProvider.user;
          return SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text('Edit Profile', style: Theme.of(context).textTheme.headlineSmall),
                const SizedBox(height: 16),
                CircleAvatar(
                  radius: 50,
                  backgroundColor: AppColors.primary,
                  child: Text(
                    (user?.name ?? 'A')[0].toUpperCase(),
                    style: const TextStyle(fontSize: 36, color: Colors.white, fontWeight: FontWeight.bold),
                  ),
                ),
                const SizedBox(height: 16),
                TextField(
                  decoration: InputDecoration(
                    labelText: 'Name',
                    hintText: user?.name ?? 'Your name',
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                  ),
                ),
                const SizedBox(height: 12),
                TextField(
                  decoration: InputDecoration(
                    labelText: 'Email',
                    hintText: user?.email ?? 'your@email.com',
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                  ),
                ),
                const SizedBox(height: 12),
                TextField(
                  decoration: InputDecoration(
                    labelText: 'Phone',
                    hintText: user?.phone ?? '+91 XXXXXXXXXX',
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                  ),
                ),
                const SizedBox(height: 16),
                PrimaryButton(label: 'Save Changes', onPressed: () => Navigator.pop(context)),
              ],
            ),
          );
        },
      ),
    );
  }

  void _showChangePasswordDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Change Password'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              obscureText: true,
              decoration: InputDecoration(
                labelText: 'Current Password',
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              obscureText: true,
              decoration: InputDecoration(
                labelText: 'New Password',
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              obscureText: true,
              decoration: InputDecoration(
                labelText: 'Confirm Password',
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
          PrimaryButton(label: 'Update', onPressed: () => Navigator.pop(context)),
        ],
      ),
    );
  }

  void _showNotificationSettings() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Notification Preferences'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            CheckboxListTile(
              title: const Text('Emergency Alerts'),
              value: true,
              onChanged: (_) {},
            ),
            CheckboxListTile(
              title: const Text('System Updates'),
              value: true,
              onChanged: (_) {},
            ),
            CheckboxListTile(
              title: const Text('Weekly Reports'),
              value: false,
              onChanged: (_) {},
            ),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Done')),
        ],
      ),
    );
  }

  void _showActiveSessions() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Active Sessions'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              title: const Text('Current Device'),
              subtitle: const Text('Chrome on Windows'),
              trailing: const Chip(label: Text('Active')),
            ),
            const Divider(),
            const Text('No other active sessions'),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Close')),
        ],
      ),
    );
  }

  void _showFeedbackDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Send Feedback'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              maxLines: 4,
              decoration: InputDecoration(
                hintText: 'Tell us what you think...',
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
          PrimaryButton(label: 'Send', onPressed: () => Navigator.pop(context)),
        ],
      ),
    );
  }

  void _showPrivacyPolicy() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Privacy Policy'),
        content: SingleChildScrollView(
          child: Text(
            'Your privacy is important to us. This policy explains how we collect and use your data.\n\n'
            '1. Data Collection: We collect information you provide directly.\n'
            '2. Data Usage: Your data is used to provide and improve our services.\n'
            '3. Data Protection: We use industry-standard security measures.\n'
            '4. Your Rights: You can access, modify, or delete your data anytime.',
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Close')),
        ],
      ),
    );
  }

  void _showLogoutDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Logout?'),
        content: const Text('Are you sure you want to logout?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
          TextButton(
            onPressed: () {
              context.read<AuthProvider>().logout();
              Navigator.pop(context);
              Navigator.of(context).pushNamedAndRemoveUntil('/login', (r) => false);
            },
            child: const Text('Logout', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }
}
