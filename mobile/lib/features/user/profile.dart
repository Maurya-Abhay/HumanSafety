import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'dart:ui';
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
  final _formKey = GlobalKey<FormState>();
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
    if (!_formKey.currentState!.validate()) return;

    try {
      setState(() => isSaving = true);
      final authProvider = context.read<AuthProvider>();
      final token = await StorageService.getString(AppConstants.tokenKey);

      if (token != null) {
        await ApiService.updateProfile(token, {
          'name': nameController.text.trim(),
          'email': emailController.text.trim(),
        });

        await authProvider.fetchUserProfile();

        setState(() {
          isEditing = false;
          isSaving = false;
        });

        if (mounted) {
          _showSnackBar('Profile updated successfully', AppColors.success);
        }
      }
    } catch (e) {
      setState(() => isSaving = false);
      if (mounted) _showSnackBar('Update failed: $e', AppColors.error);
    }
  }

  void _showSnackBar(String msg, Color color) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
          content: Text(msg),
          backgroundColor: color,
          behavior: SnackBarBehavior.floating),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor:
          const Color(0xFFF8F9FD), // Ultra light grey/blue background
      appBar: CustomAppBar(
        title: 'My Profile',
        actions: [
          if (!isEditing)
            IconButton(
              icon: const Icon(Icons.settings_suggest_rounded,
                  color: Colors.white),
              onPressed: () => Navigator.pushNamed(context, AppRoutes.settings),
            ),
        ],
      ),
      body: Consumer<AuthProvider>(
        builder: (context, authProvider, _) {
          final user = authProvider.user;
          if (user == null)
            return const Center(
                child: LoadingWidget(message: "Fetching details..."));

          // Sync controllers only when starting edit
          if (isEditing && nameController.text.isEmpty) {
            nameController.text = user.name;
            emailController.text = user.email;
          }

          return SingleChildScrollView(
            physics: const BouncingScrollPhysics(),
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Form(
              key: _formKey,
              child: Column(
                children: [
                  const SizedBox(height: 20),
                  _buildAvatarSection(user),
                  const SizedBox(height: 30),
                  AnimatedSwitcher(
                    duration: const Duration(milliseconds: 300),
                    child:
                        isEditing ? _buildEditFields() : _buildInfoView(user),
                  ),
                  const SizedBox(height: 30),
                  _buildActionButtons(authProvider),
                  const SizedBox(height: 100),
                ],
              ),
            ),
          );
        },
      ),
      bottomNavigationBar: CustomBottomNav(
        currentIndex: 3,
        onTap: (index) {
          if (index == 0) Navigator.pushNamed(context, AppRoutes.userHome);
          if (index == 1) Navigator.pushNamed(context, AppRoutes.sos);
          if (index == 2) Navigator.pushNamed(context, AppRoutes.contacts);
          if (index == 3) Navigator.pushNamed(context, AppRoutes.settings);
        },
        items: const [
          BottomNavItem(icon: Icons.home_rounded, label: 'Home'),
          BottomNavItem(icon: Icons.warning_amber_rounded, label: 'SOS'),
          BottomNavItem(icon: Icons.people_rounded, label: 'Contacts'),
          BottomNavItem(icon: Icons.settings_rounded, label: 'Settings'),
        ],
      ),
    );
  }

  Widget _buildAvatarSection(User user) {
    return Column(
      children: [
        Stack(
          alignment: Alignment.bottomRight,
          children: [
            Container(
              padding: const EdgeInsets.all(4),
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(color: AppColors.primary, width: 2),
                boxShadow: [
                  BoxShadow(
                      color: AppColors.primary.withOpacity(0.2),
                      blurRadius: 15,
                      spreadRadius: 5)
                ],
              ),
              child: CircleAvatar(
                radius: 55,
                backgroundColor: AppColors.primary,
                child: Text(
                  user.name[0].toUpperCase(),
                  style: const TextStyle(
                      fontSize: 40,
                      fontWeight: FontWeight.bold,
                      color: Colors.white),
                ),
              ),
            ),
            GestureDetector(
              onTap: () {}, // Add Image Pick Logic
              child: Container(
                padding: const EdgeInsets.all(8),
                decoration: const BoxDecoration(
                    color: Colors.white,
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(blurRadius: 5, color: Colors.black12)
                    ]),
                child: const Icon(Icons.edit_rounded,
                    size: 20, color: AppColors.primary),
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
        Text(user.name,
            style: const TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.w900,
                letterSpacing: -0.5)),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
          margin: const EdgeInsets.only(top: 4),
          decoration: BoxDecoration(
              color: AppColors.primary.withOpacity(0.1),
              borderRadius: BorderRadius.circular(20)),
          child: Text(
            user.role.toUpperCase(),
            style: const TextStyle(
                color: AppColors.primary,
                fontWeight: FontWeight.bold,
                fontSize: 11,
                letterSpacing: 1.1),
          ),
        ),
      ],
    );
  }

  Widget _buildInfoView(User user) {
    return Column(
      children: [
        _buildSectionHeader("Personal Information"),
        CustomCard(
          padding: EdgeInsets.zero,
          child: Column(
            children: [
              _buildListTile(Icons.email_outlined, "Email Address", user.email),
              _buildDivider(),
              _buildListTile(
                  Icons.phone_android_rounded, "Phone Number", user.phone),
              _buildDivider(),
              _buildListTile(
                  Icons.bloodtype_outlined, "Blood Group", "O+ (Verified)"),
            ],
          ),
        ),
        const SizedBox(height: 24),
        _buildSectionHeader("Safety Statistics"),
        Row(
          children: [
            Expanded(child: _buildStatCard("SOS Sent", "12", Colors.orange)),
            const SizedBox(width: 12),
            Expanded(child: _buildStatCard("Score", "98%", Colors.green)),
          ],
        ),
      ],
    );
  }

  Widget _buildEditFields() {
    return CustomCard(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text("Edit Profile Details",
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
          const SizedBox(height: 20),
          CustomTextField(
            label: "Full Name",
            hint: "Enter your full name",
            controller: nameController,
            prefixIcon: Icons.person_outline_rounded,
            validator: (v) => v!.isEmpty ? "Name can't be empty" : null,
          ),
          const SizedBox(height: 16),
          CustomTextField(
            label: "Email Address",
            hint: "Enter your email address",
            controller: emailController,
            prefixIcon: Icons.alternate_email_rounded,
            inputType: TextInputType.emailAddress,
            validator: (v) => !v!.contains('@') ? "Enter a valid email" : null,
          ),
        ],
      ),
    );
  }

  Widget _buildSectionHeader(String title) {
    return Padding(
      padding: const EdgeInsets.only(left: 4, bottom: 12),
      child: Row(
        children: [
          Text(title,
              style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                  color: Colors.black87)),
        ],
      ),
    );
  }

  Widget _buildListTile(IconData icon, String title, String value) {
    return ListTile(
      leading: Icon(icon, color: AppColors.primary.withOpacity(0.7), size: 22),
      title: Text(title,
          style: const TextStyle(
              fontSize: 12, color: Colors.grey, fontWeight: FontWeight.w500)),
      subtitle: Text(value,
          style: const TextStyle(
              fontSize: 15, fontWeight: FontWeight.bold, color: Colors.black)),
    );
  }

  Widget _buildDivider() =>
      Divider(height: 1, indent: 55, color: Colors.grey.shade200);

  Widget _buildStatCard(String label, String value, Color color) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: color.withOpacity(0.05),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color.withOpacity(0.1)),
      ),
      child: Column(
        children: [
          Text(value,
              style: TextStyle(
                  fontSize: 22, fontWeight: FontWeight.w900, color: color)),
          Text(label,
              style: const TextStyle(
                  fontSize: 12,
                  color: Colors.grey,
                  fontWeight: FontWeight.bold)),
        ],
      ),
    );
  }

  Widget _buildActionButtons(AuthProvider authProvider) {
    return isEditing
        ? Row(
            children: [
              Expanded(
                child: SecondaryButton(
                  label: 'Discard',
                  onPressed: () => setState(() => isEditing = false),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: PrimaryButton(
                  label: 'Save Changes',
                  isLoading: isSaving,
                  onPressed: _updateProfile,
                ),
              ),
            ],
          )
        : Column(
            children: [
              PrimaryButton(
                label: 'Edit Profile',
                onPressed: () => setState(() => isEditing = true),
              ),
              const SizedBox(height: 12),
              TextButton(
                onPressed: () => _handleLogout(authProvider),
                child: const Text("Logout Account",
                    style: TextStyle(
                        color: AppColors.error, fontWeight: FontWeight.bold)),
              ),
            ],
          );
  }

  void _handleLogout(AuthProvider authProvider) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text("Logout?"),
        content: const Text("Are you sure you want to end your session?"),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: const Text("Cancel")),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.error,
                foregroundColor: Colors.white),
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text("Logout"),
          ),
        ],
      ),
    );

    if (confirm == true) {
      await authProvider.logout();
      if (mounted)
        Navigator.pushNamedAndRemoveUntil(
            context, AppRoutes.login, (route) => false);
    }
  }

  @override
  void dispose() {
    nameController.dispose();
    emailController.dispose();
    super.dispose();
  }
}
