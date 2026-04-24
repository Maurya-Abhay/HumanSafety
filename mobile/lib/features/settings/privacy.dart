import 'package:flutter/material.dart';
import '../../shared/widgets.dart';

class PrivacyScreen extends StatefulWidget {
  const PrivacyScreen({Key? key}) : super(key: key);

  @override
  State<PrivacyScreen> createState() => _PrivacyScreenState();
}

class _PrivacyScreenState extends State<PrivacyScreen> {
  bool _locationTracking = true;
  bool _pushNotifications = true;
  bool _emailNotifications = false;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: const CustomAppBar(title: 'Privacy & Security'),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 12),
            Text(
              'Data Sharing',
              style: Theme.of(context).textTheme.headlineSmall,
            ),
            const SizedBox(height: 12),
            CustomCard(
              child: ListTile(
                title: const Text('Location Tracking'),
                subtitle: const Text('Allow app to access location'),
                trailing: Switch(
                  value: _locationTracking,
                  onChanged: (value) => setState(() => _locationTracking = value),
                ),
              ),
            ),
            const SizedBox(height: 24),
            Text(
              'Notifications',
              style: Theme.of(context).textTheme.headlineSmall,
            ),
            const SizedBox(height: 12),
            CustomCard(
              child: ListTile(
                title: const Text('Push Notifications'),
                trailing: Switch(
                  value: _pushNotifications,
                  onChanged: (value) => setState(() => _pushNotifications = value),
                ),
              ),
            ),
            const SizedBox(height: 12),
            CustomCard(
              child: ListTile(
                title: const Text('Email Notifications'),
                trailing: Switch(
                  value: _emailNotifications,
                  onChanged: (value) => setState(() => _emailNotifications = value),
                ),
              ),
            ),
            const SizedBox(height: 24),
            Text(
              'Account',
              style: Theme.of(context).textTheme.headlineSmall,
            ),
            const SizedBox(height: 12),
            CustomCard(
              child: ListTile(
                title: const Text('Change Password'),
                trailing: const Icon(Icons.arrow_forward_ios),
                onTap: () {},
              ),
            ),
            const SizedBox(height: 12),
            CustomCard(
              child: ListTile(
                title: const Text('Delete Account'),
                trailing: const Icon(Icons.arrow_forward_ios),
                onTap: () {},
              ),
            ),
          ],
        ),
      ),
    );
  }
}
