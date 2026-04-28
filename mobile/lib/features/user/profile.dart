import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../shared/widgets.dart';
import '../../shared/models.dart';
import '../../core/routes.dart';
import '../../core/theme.dart';
import '../../core/api_service.dart';
import '../../core/storage_service.dart';
import '../../core/constants.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  late TextEditingController nameController;
  late TextEditingController emailController;
  bool isEditing = false;
  bool isSaving = false;

  @override
  void initState() {
    super.initState();
    nameController = TextEditingController();
    emailController = TextEditingController();
  }

  Future<void> _updateProfile() async {
    try {
      setState(() => isSaving = true);
      final authProvider = context.read<AuthProvider>();
      final token = await StorageService.getString(AppConstants.tokenKey);
      
      if (token != null) {
        await ApiService.updateProfile(token, {
          'name': nameController.text,
          'email': emailController.text,
        });
        
        // Refresh user data
        await authProvider.fetchUserProfile();
        
        setState(() {
          isEditing = false;
          isSaving = false;
        });
        
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Profile updated successfully')),
          );
        }
      }
    } catch (e) {
      setState(() => isSaving = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: ${e.toString()}')),
        );
      }
    }
  }

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
            
            if (isEditing && (nameController.text.isEmpty || emailController.text.isEmpty)) {
              nameController.text = user.name;
              emailController.text = user.email;
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
                if (!isEditing)
                  Text(
                    user.name,
                    style: Theme.of(context).textTheme.headlineSmall,
                  )
                else
                  TextField(
                    controller: nameController,
                    decoration: const InputDecoration(
                      labelText: 'Name',
                      border: OutlineInputBorder(),
                    ),
                  ),
                const SizedBox(height: 4),
                if (!isEditing)
                  Text(user.email, style: const TextStyle(color: AppColors.grey))
                else
                  TextField(
                    controller: emailController,
                    decoration: const InputDecoration(
                      labelText: 'Email',
                      border: OutlineInputBorder(),
                    ),
                    keyboardType: TextInputType.emailAddress,
                  ),
                const SizedBox(height: 32),
                if (!isEditing) ...[
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
                  const SizedBox(height: 12),
                  CustomCard(
                    child: ListTile(
                      leading: const Icon(Icons.verified, color: AppColors.primary),
                      title: const Text('Role'),
                      subtitle: Text(user.role.toUpperCase()),
                    ),
                  ),
                ],
                const SizedBox(height: 32),
                if (isEditing)
                  Row(
                    children: [
                      Expanded(
                        child: SecondaryButton(
                          label: 'Cancel',
                          onPressed: () {
                            setState(() => isEditing = false);
                            nameController.clear();
                            emailController.clear();
                          },
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: PrimaryButton(
                          label: isSaving ? 'Saving...' : 'Save',
                          onPressed: isSaving ? () {} : () => _updateProfile(),
                        ),
                      ),
                    ],
                  )
                else
                  PrimaryButton(
                    label: 'Edit Profile',
                    onPressed: () => setState(() => isEditing = true),
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
      bottomNavigationBar: CustomBottomNav(
        currentIndex: 3,
        onTap: (index) {
          // Profile doesn't navigate
        },
        items: [
          BottomNavItem(icon: Icons.home, label: 'Home'),
          BottomNavItem(icon: Icons.warning, label: 'SOS'),
          BottomNavItem(icon: Icons.people, label: 'Contacts'),
          BottomNavItem(icon: Icons.person, label: 'Profile'),
        ],
      ),
    );
  }

  @override
  void dispose() {
    nameController.dispose();
    emailController.dispose();
    super.dispose();
  }
}
