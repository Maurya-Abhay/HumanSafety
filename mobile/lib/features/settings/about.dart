import 'package:flutter/material.dart';
import '../../shared/widgets.dart';
import '../../core/constants.dart';

class AboutScreen extends StatelessWidget {
  const AboutScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: const CustomAppBar(title: 'About HumanSafety'),
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 10),
            Center(
              child: Column(
                children: [
                  // Premium Icon Container
                  Container(
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: Theme.of(context).primaryColor.withOpacity(0.1),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      Icons.shield_rounded,
                      size: 80,
                      color: Theme.of(context).primaryColor,
                    ),
                  ),
                  const SizedBox(height: 20),
                  const Text(
                    AppConstants.appName,
                    style: TextStyle(fontSize: 30, fontWeight: FontWeight.w900),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Version ${AppConstants.appVersion}',
                    style: const TextStyle(
                        color: Colors.grey, fontWeight: FontWeight.w500),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),
            Text(
              'Our Mission',
              style: Theme.of(context)
                  .textTheme
                  .headlineSmall
                  ?.copyWith(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 12),
            const Text(
              'HumanSafety is a next-generation emergency ecosystem. Our goal is to minimize response time during critical situations by creating a seamless bridge between citizens, medical professionals, and law enforcement.',
              style:
                  TextStyle(fontSize: 15, height: 1.5, color: Colors.black87),
            ),
            const SizedBox(height: 20),
            Text(
              'Advanced Features',
              style: Theme.of(context)
                  .textTheme
                  .headlineSmall
                  ?.copyWith(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            _buildFeatureItem('🚨', 'Smart SOS System',
                'Instant alerts to your inner circle.'),
            _buildFeatureItem('📍', 'Precise Location',
                'High-accuracy tracking for responders.'),
            _buildFeatureItem('🏥', 'Hospital Network',
                'One-tap connectivity to trauma centers.'),
            _buildFeatureItem('👮', 'Police Dispatch',
                'Direct coordination with local authorities.'),
            const SizedBox(height: 30),
            Text(
              'Contact Support',
              style: Theme.of(context)
                  .textTheme
                  .headlineSmall
                  ?.copyWith(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 12),
            const CustomCard(
              child: Padding(
                padding: EdgeInsets.all(12),
                child: Column(
                  children: [
                    _ContactRow(
                        icon: Icons.email_rounded,
                        label: 'support@humansafety.com'),
                    Divider(height: 24),
                    _ContactRow(
                        icon: Icons.phone_android_rounded,
                        label: '+1 (555) 123-4567'),
                    Divider(height: 24),
                    _ContactRow(
                        icon: Icons.public_rounded,
                        label: 'www.humansafety.com'),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFeatureItem(String emoji, String title, String desc) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: Colors.grey.withOpacity(0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Text(emoji, style: const TextStyle(fontSize: 24)),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title,
                    style: const TextStyle(
                        fontSize: 16, fontWeight: FontWeight.bold)),
                Text(desc,
                    style: const TextStyle(fontSize: 13, color: Colors.grey)),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _ContactRow extends StatelessWidget {
  final IconData icon;
  final String label;
  const _ContactRow({required this.icon, required this.label});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, size: 20, color: Theme.of(context).primaryColor),
        const SizedBox(width: 12),
        Text(label, style: const TextStyle(fontWeight: FontWeight.w500)),
      ],
    );
  }
}
