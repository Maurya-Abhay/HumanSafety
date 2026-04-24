import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../shared/widgets.dart';
import '../../shared/models.dart';
import '../../core/constants.dart';
import '../../core/routes.dart';

class RoleSelectScreen extends StatelessWidget {
  const RoleSelectScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: const CustomAppBar(title: 'Select Your Role', showBackButton: false),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            const SizedBox(height: 20),
            Text(
              'Choose Your Role',
              style: Theme.of(context).textTheme.headlineSmall,
            ),
            const SizedBox(height: 8),
            const Text('How would you like to use HumanSafety?'),
            const SizedBox(height: 40),
            ...UserRole.values.map((role) => _buildRoleCard(context, role)).toList(),
          ],
        ),
      ),
    );
  }

  Widget _buildRoleCard(BuildContext context, UserRole role) {
    final roleIcons = {
      UserRole.user: Icons.person_outline,
      UserRole.police: Icons.local_police_outlined,
      UserRole.hospital: Icons.local_hospital_outlined,
      UserRole.admin: Icons.admin_panel_settings_outlined,
    };

    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: CustomCard(
        onTap: () async {
          context.read<RoleProvider>().setRole(role);
          if (context.mounted) {
            final roleProvider = context.read<RoleProvider>();
            final authProvider = context.read<AuthProvider>();
            final home = switch (role) {
              UserRole.user => AppRoutes.userHome,
              UserRole.police => AppRoutes.policeDashboard,
              UserRole.hospital => AppRoutes.hospitalDashboard,
              UserRole.admin => AppRoutes.adminDashboard,
            };
            Navigator.pushNamedAndRemoveUntil(context, home, (route) => false);
          }
        },
        child: Row(
          children: [
            Icon(roleIcons[role], size: 48, color: Theme.of(context).primaryColor),
            const SizedBox(width: 20),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    role.displayName,
                    style: Theme.of(context).textTheme.headlineSmall,
                  ),
                  const SizedBox(height: 4),
                  Text(
                    _getRoleDescription(role),
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                ],
              ),
            ),
            Icon(Icons.arrow_forward_ios, color: Theme.of(context).primaryColor),
          ],
        ),
      ),
    );
  }

  String _getRoleDescription(UserRole role) {
    switch (role) {
      case UserRole.user:
        return 'Get emergency help quickly';
      case UserRole.police:
        return 'Respond to alerts and cases';
      case UserRole.hospital:
        return 'Manage emergency requests';
      case UserRole.admin:
        return 'Monitor system and users';
    }
  }
}
