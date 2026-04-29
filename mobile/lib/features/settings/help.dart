import 'package:flutter/material.dart';

import '../../shared/widgets.dart';

class HelpScreen extends StatelessWidget {
  const HelpScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final faqs = [
      {
        'q': 'How do I activate emergency SOS?',
        'a':
            'Simply tap and hold the SOS button for 3 seconds. The app will immediately send your location and alert status to your emergency contacts and the nearest command center.',
        'icon': Icons.touch_app_rounded,
      },
      {
        'q': 'How do I add emergency contacts?',
        'a':
            'Go to the Contacts tab on the home screen, tap the floating + button, and select trusted people from your phonebook.',
        'icon': Icons.person_add_rounded,
      },
      {
        'q': 'Can I track my emergency responders?',
        'a':
            'Yes. Once a responder accepts your request, their live location will appear on your map in real time.',
        'icon': Icons.map_rounded,
      },
      {
        'q': 'Is my data secure?',
        'a':
            'Absolutely. HumanSafety uses encrypted storage and only shares location data during an active SOS event.',
        'icon': Icons.lock_outline_rounded,
      },
      {
        'q': 'How do I delete my account?',
        'a':
            'Navigate to Settings > Privacy > Account Management. Please note that your saved data will be removed.',
        'icon': Icons.delete_forever_rounded,
      },
    ];

    return Scaffold(
      appBar: const CustomAppBar(title: 'Help Center'),
      body: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: faqs.length,
        itemBuilder: (context, index) {
          final faq = faqs[index];
          return Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: Container(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: Colors.grey.withOpacity(0.2)),
              ),
              child: ExpansionTile(
                leading: Icon(faq['icon'] as IconData,
                    color: Theme.of(context).primaryColor),
                title: Text(
                  faq['q'] as String,
                  style: const TextStyle(
                      fontWeight: FontWeight.bold, fontSize: 15),
                ),
                shape: const RoundedRectangleBorder(side: BorderSide.none),
                children: [
                  Padding(
                    padding:
                        const EdgeInsets.only(left: 16, right: 16, bottom: 20),
                    child: Text(
                      faq['a'] as String,
                      style: TextStyle(color: Colors.grey[700], height: 1.5),
                    ),
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
