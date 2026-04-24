import 'package:flutter/material.dart';
import '../../shared/widgets.dart';
import '../../core/theme.dart';

class AdminUsersScreen extends StatelessWidget {
  const AdminUsersScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final users = [
      {'id': '1', 'name': 'Alice', 'role': 'user', 'status': 'active'},
      {'id': '2', 'name': 'Bob', 'role': 'police', 'status': 'active'},
      {'id': '3', 'name': 'Charlie', 'role': 'hospital', 'status': 'inactive'},
      {'id': '4', 'name': 'Diana', 'role': 'user', 'status': 'active'},
    ];

    return Scaffold(
      appBar: const CustomAppBar(title: 'Manage Users'),
      body: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: users.length,
        itemBuilder: (context, index) {
          final user = users[index];
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
                      user['name']![0],
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        fontSize: 20,
                      ),
                    ),
                  ),
                ),
                title: Text(user['name']!),
                subtitle: Text(user['role']!),
                trailing: Chip(
                  label: Text(user['status']!),
                  backgroundColor: user['status'] == 'active' ? AppColors.success : AppColors.grey,
                  labelStyle: const TextStyle(color: Colors.white),
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}
