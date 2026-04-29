import 'package:flutter/material.dart';
import '../../shared/widgets.dart';

class PrivacyScreen extends StatefulWidget {
  const PrivacyScreen({super.key});

  @override
  State<PrivacyScreen> createState() => _PrivacyScreenState();
}

class _PrivacyScreenState extends State<PrivacyScreen> {
  bool _locationTracking = true;
  bool _pushNotifications = true;
  bool _emailNotifications = false;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      appBar: const CustomAppBar(title: 'Privacy & Security'),
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // --- Security Header ---
            _buildSecurityHeader(isDark),
            const SizedBox(height: 32),

            // --- Data Sharing Section ---
            _buildSectionHeader(
                context, 'Data & Privacy', Icons.security_rounded),
            const SizedBox(height: 12),
            CustomCard(
              child: ListTile(
                leading:
                    _buildIconContainer(Icons.location_on_rounded, Colors.blue),
                title: const Text('Live Tracking',
                    style: TextStyle(fontWeight: FontWeight.bold)),
                subtitle: const Text('Share location during active SOS events'),
                trailing: Switch.adaptive(
                  value: _locationTracking,
                  activeColor: Theme.of(context).primaryColor,
                  onChanged: (value) =>
                      setState(() => _locationTracking = value),
                ),
              ),
            ),

            const SizedBox(height: 24),

            // --- Notifications Section ---
            _buildSectionHeader(context, 'Alert Preferences',
                Icons.notifications_active_rounded),
            const SizedBox(height: 12),
            CustomCard(
              child: Column(
                children: [
                  ListTile(
                    leading: _buildIconContainer(
                        Icons.notifications_rounded, Colors.orange),
                    title: const Text('Push Notifications'),
                    subtitle: const Text('Critical safety alerts & updates'),
                    trailing: Switch.adaptive(
                      value: _pushNotifications,
                      onChanged: (value) =>
                          setState(() => _pushNotifications = value),
                    ),
                  ),
                  const Divider(indent: 70),
                  ListTile(
                    leading: _buildIconContainer(
                        Icons.alternate_email_rounded, Colors.green),
                    title: const Text('Email Reports'),
                    subtitle: const Text('Monthly safety & activity logs'),
                    trailing: Switch.adaptive(
                      value: _emailNotifications,
                      onChanged: (value) =>
                          setState(() => _emailNotifications = value),
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 24),

            // --- Account Section ---
            _buildSectionHeader(
                context, 'Account Management', Icons.manage_accounts_rounded),
            const SizedBox(height: 12),
            CustomCard(
              child: Column(
                children: [
                  _buildActionTile(
                    context,
                    icon: Icons.lock_reset_rounded,
                    title: 'Update Password',
                    color: Colors.purple,
                    onTap: () {},
                  ),
                  const Divider(indent: 70),
                  _buildActionTile(
                    context,
                    icon: Icons.delete_forever_rounded,
                    title: 'Delete Account',
                    color: Colors.red,
                    isDestructive: true,
                    onTap: () {},
                  ),
                ],
              ),
            ),
            const SizedBox(height: 40),
          ],
        ),
      ),
    );
  }

  // --- Helper Widgets for Cleaner Code ---

  Widget _buildSecurityHeader(bool isDark) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.green.withOpacity(0.1),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.green.withOpacity(0.3)),
      ),
      child: Row(
        children: [
          const Icon(Icons.verified_user_rounded,
              color: Colors.green, size: 30),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('Your Data is Encrypted',
                    style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                        color: Colors.green)),
                Text(
                    'We use AES-256 bit encryption to keep your safety data private.',
                    style: TextStyle(fontSize: 12, color: Colors.green[700])),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSectionHeader(
      BuildContext context, String title, IconData icon) {
    return Row(
      children: [
        Icon(icon, size: 20, color: Theme.of(context).primaryColor),
        const SizedBox(width: 8),
        Text(
          title,
          style: const TextStyle(
              fontSize: 18, fontWeight: FontWeight.w800, letterSpacing: 0.5),
        ),
      ],
    );
  }

  Widget _buildIconContainer(IconData icon, Color color) {
    return Container(
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Icon(icon, color: color, size: 22),
    );
  }

  Widget _buildActionTile(BuildContext context,
      {required IconData icon,
      required String title,
      required Color color,
      required VoidCallback onTap,
      bool isDestructive = false}) {
    return ListTile(
      onTap: onTap,
      leading: _buildIconContainer(icon, color),
      title: Text(title,
          style: TextStyle(
              fontWeight: FontWeight.w600,
              color: isDestructive ? Colors.red : null)),
      trailing: const Icon(Icons.arrow_forward_ios_rounded,
          size: 16, color: Colors.grey),
    );
  }
}
