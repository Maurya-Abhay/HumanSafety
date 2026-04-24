import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../shared/widgets.dart';
import '../../shared/models.dart';
import '../../core/routes.dart';
import '../../core/theme.dart';

class ProfileScreen extends StatelessWidget {
  const ProfileScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: const CustomAppBar(title: 'Profile', showBackButton: false),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Consumer<AuthProvider>(
          builder: (context, authProvider, _) {
            final user = authProvider.user;
            if (user == null) {
              return const Center(child: Text('Not logged in'));
            }
            return Column(
              children: [
                const SizedBox(height: 20),
                Container(
                  width: 100,
                  height: 100,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: Theme.of(context).primaryColor,
                  ),
                  child: Center(
                    child: Text(
                      user.name.isNotEmpty ? user.name[0].toUpperCase() : 'U',
                      style: const TextStyle(
                        fontSize: 48,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 20),
                Text(
                  user.name,
                  style: Theme.of(context).textTheme.headlineSmall,
                ),
                const SizedBox(height: 4),
                Text(user.email, style: const TextStyle(color: AppColors.grey)),
                const SizedBox(height: 32),
                CustomCard(
                  child: ListTile(
                    leading: const Icon(Icons.email, color: AppColors.primary),
                    title: const Text('Email'),
                    subtitle: Text(user.email),
                  ),
                ),
                const SizedBox(height: 12),
                CustomCard(
                  child: ListTile(
                    leading: const Icon(Icons.phone, color: AppColors.primary),
                    title: const Text('Phone'),
                    subtitle: Text(user.phone),
                  ),
                ),
                const SizedBox(height: 12),
                CustomCard(
                  child: ListTile(
                    leading: const Icon(Icons.calendar_today, color: AppColors.primary),
                    title: const Text('Member Since'),
                    subtitle: Text(user.createdAt.toString().split(' ')[0]),
                  ),
                ),
                const SizedBox(height: 32),
                PrimaryButton(
                  label: 'Edit Profile',
                  onPressed: () {},
                ),
                const SizedBox(height: 12),
                SecondaryButton(
                  label: 'Settings',
                  onPressed: () => Navigator.pushNamed(context, AppRoutes.settings),
                ),
                const SizedBox(height: 12),
                PrimaryButton(
                  label: 'Logout',
                  backgroundColor: AppColors.error,
                  onPressed: () async {
                    await authProvider.logout();
                    if (context.mounted) {
                      Navigator.pushNamedAndRemoveUntil(
                        context,
                        AppRoutes.login,
                        (route) => false,
                      );
                    }
                  },
                ),
                const SizedBox(height: 20),
              ],
            );
          },
        ),
      ),
    );
  }
}
