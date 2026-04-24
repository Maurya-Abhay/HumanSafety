import 'package:flutter/material.dart';
import '../../shared/widgets.dart';
import '../../core/theme.dart';

class ContactsScreen extends StatelessWidget {
  const ContactsScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final contacts = [
      {'name': 'Mom', 'phone': '+1234567890', 'relation': 'Mother'},
      {'name': 'Dad', 'phone': '+0987654321', 'relation': 'Father'},
      {'name': 'Doctor', 'phone': '+1122334455', 'relation': 'Doctor'},
    ];

    return Scaffold(
      appBar: const CustomAppBar(title: 'Emergency Contacts'),
      floatingActionButton: FloatingActionButton(
        onPressed: () {},
        child: const Icon(Icons.add),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            const SizedBox(height: 16),
            ListView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: contacts.length,
              itemBuilder: (context, index) {
                final contact = contacts[index];
                return Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: CustomCard(
                    child: ListTile(
                      leading: Container(
                        width: 48,
                        height: 48,
                        decoration: const BoxDecoration(
                          shape: BoxShape.circle,
                          color: AppColors.primary,
                        ),
                        child: Center(
                          child: Text(
                            contact['name']![0],
                            style: const TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                              fontSize: 20,
                            ),
                          ),
                        ),
                      ),
                      title: Text(contact['name']!),
                      subtitle: Text(contact['relation']!),
                      trailing: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          IconButton(
                            icon: const Icon(Icons.call, color: AppColors.success),
                            onPressed: () {},
                          ),
                          IconButton(
                            icon: const Icon(Icons.edit, color: AppColors.info),
                            onPressed: () {},
                          ),
                        ],
                      ),
                    ),
                  ),
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}
