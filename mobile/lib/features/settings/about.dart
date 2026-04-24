import 'package:flutter/material.dart';
import '../../shared/widgets.dart';
import '../../core/constants.dart';

class AboutScreen extends StatelessWidget {
  const AboutScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: const CustomAppBar(title: 'About'),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 20),
            Center(
              child: Column(
                children: [
                  Icon(
                    Icons.shield_outlined,
                    size: 80,
                    color: Theme.of(context).primaryColor,
                  ),
                  const SizedBox(height: 16),
                  const Text(
                    AppConstants.appName,
                    style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    'Version ${AppConstants.appVersion}',
                    style: TextStyle(color: Colors.grey),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 32),
            Text(
              'About Us',
              style: Theme.of(context).textTheme.headlineSmall,
            ),
            const SizedBox(height: 12),
            const Text(
              'HumanSafety is a comprehensive emergency response platform connecting users with emergency services, hospitals, and police departments for faster assistance and better safety.',
            ),
            const SizedBox(height: 24),
            Text(
              'Features',
              style: Theme.of(context).textTheme.headlineSmall,
            ),
            const SizedBox(height: 12),
            _buildFeatureItem('🚨', 'Emergency SOS Alerts'),
            _buildFeatureItem('📍', 'Real-time Location Tracking'),
            _buildFeatureItem('🏥', 'Hospital Integration'),
            _buildFeatureItem('👮', 'Police Coordination'),
            _buildFeatureItem('📊', 'Admin Dashboard'),
            const SizedBox(height: 24),
            Text(
              'Contact',
              style: Theme.of(context).textTheme.headlineSmall,
            ),
            const SizedBox(height: 12),
            CustomCard(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: const [
                  Text('Email: support@humansafety.com'),
                  SizedBox(height: 8),
                  Text('Phone: +1 (555) 123-4567'),
                  SizedBox(height: 8),
                  Text('Website: www.humansafety.com'),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFeatureItem(String emoji, String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        children: [
          Text(emoji, style: const TextStyle(fontSize: 20)),
          const SizedBox(width: 12),
          Text(text),
        ],
      ),
    );
  }
}

class HelpScreen extends StatelessWidget {
  const HelpScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final faqs = [
      {
        'q': 'How do I activate emergency SOS?',
        'a': 'Open the app, go to the SOS section, and tap the large SOS button. Help will be dispatched immediately.'
      },
      {
        'q': 'How do I add emergency contacts?',
        'a': 'Go to the Contacts section in the app and tap the + button to add new emergency contacts.'
      },
      {
        'q': 'Can I track my emergency responders?',
        'a': 'Yes, once an SOS is activated, you can see real-time location of responders in the app.'
      },
      {
        'q': 'Is my data secure?',
        'a': 'All data is encrypted end-to-end. We prioritize your privacy and security.'
      },
      {
        'q': 'How do I delete my account?',
        'a': 'Go to Settings > Privacy & Security > Delete Account. This action is permanent.'
      },
    ];

    return Scaffold(
      appBar: const CustomAppBar(title: 'Help & Support'),
      body: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: faqs.length,
        itemBuilder: (context, index) {
          final faq = faqs[index];
          return Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: CustomCard(
              child: ExpansionTile(
                title: Text(faq['q']!),
                children: [
                  Padding(
                    padding: const EdgeInsets.all(16),
                    child: Text(faq['a']!),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}
