import 'package:flutter/material.dart';
import '../../shared/widgets.dart';

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: const CustomAppBar(title: 'Settings'),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 16),
            Text(
              'System Settings',
              style: Theme.of(context).textTheme.headlineSmall,
            ),
            const SizedBox(height: 12),
            _buildSettingItem('API Configuration', 'Manage API endpoints'),
            _buildSettingItem('Database', 'Database settings'),
            _buildSettingItem('Notifications', 'Configure notifications'),
            _buildSettingItem('Security', 'Security policies'),
            _buildSettingItem('Logs', 'View system logs'),
          ],
        ),
      ),
    );
  }

  Widget _buildSettingItem(String title, String subtitle) {
    return CustomCard(
      child: ListTile(
        title: Text(title),
        subtitle: Text(subtitle),
        trailing: const Icon(Icons.arrow_forward_ios),
        onTap: () {},
      ),
    );
  }
}
