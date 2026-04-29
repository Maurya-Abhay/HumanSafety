import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../shared/widgets.dart';
import '../../shared/models.dart';
import '../../core/routes.dart';
import '../../core/constants.dart';
import '../../core/storage_service.dart';
import '../../core/api_service.dart';
import '../../core/theme.dart';

class AdminProfileScreen extends StatefulWidget {
  const AdminProfileScreen({super.key});

  @override
  State<AdminProfileScreen> createState() => _AdminProfileScreenState();
}

class _AdminProfileScreenState extends State<AdminProfileScreen> {
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _phoneController = TextEditingController();
  bool _isEditing = false;
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final admin = context.read<AuthProvider>().user;
      _nameController.text = admin?.name ?? 'Admin';
      _emailController.text = admin?.email ?? 'admin@humansafety.app';
      _phoneController.text = admin?.phone ?? '+91 0000000000';
    });
  }

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _phoneController.dispose();
    super.dispose();
  }

  Future<void> _saveProfile() async {
    setState(() => _isSaving = true);
    try {
      final token = await StorageService.getString(AppConstants.tokenKey);
      if (token != null) {
        await ApiService.updateProfile(token, {
          'name': _nameController.text.trim(),
          'email': _emailController.text.trim(),
          'phone': _phoneController.text.trim(),
        });
        await context.read<AuthProvider>().fetchUserProfile();
      }
      if (!mounted) return;
      setState(() {
        _isSaving = false;
        _isEditing = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('Profile updated successfully'),
          behavior: SnackBarBehavior.floating,
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
          backgroundColor: AppColors.success,
        ),
      );
    } catch (e) {
      if (!mounted) return;
      setState(() => _isSaving = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: $e'), backgroundColor: Colors.redAccent),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final admin = context.watch<AuthProvider>().user;
    final initial =
        (admin?.name.isNotEmpty ?? false) ? admin!.name[0].toUpperCase() : 'A';

    return Scaffold(
      appBar: CustomAppBar(
        title: 'Profile',
        showBackButton: true,
        actions: [
          IconButton(
            icon: const Icon(Icons.settings_outlined, color: Colors.white),
            onPressed: () =>
                Navigator.pushNamed(context, AppRoutes.adminSettings),
          ),
        ],
      ),
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: isDark
                ? [const Color(0xFF121212), const Color(0xFF1E1E2E)]
                : [const Color(0xFFF8F9FA), Colors.white],
          ),
        ),
        child: SingleChildScrollView(
          physics: const BouncingScrollPhysics(),
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 100),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildProfileHeader(initial, admin),
              const SizedBox(height: 16),
              _buildSectionTitle("Personal Information", theme),
              const SizedBox(height: 8),
              _buildInfoContainer(theme),
              const SizedBox(height: 16),
              if (_isEditing) ...[
                _buildSaveButton(),
                const SizedBox(height: 12),
              ],
              _buildSectionTitle("Account Actions", theme),
              const SizedBox(height: 12),
              _buildActionCard(
                title: 'Security Settings',
                subtitle: 'Change password and 2FA',
                icon: Icons.shield_outlined,
                color: Colors.blueAccent,
                onTap: () {},
              ),
              _buildActionCard(
                title: 'Logout',
                subtitle: 'Securely sign out of your session',
                icon: Icons.logout_rounded,
                color: Colors.redAccent,
                onTap: _showLogoutDialog,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildProfileHeader(String initial, User? admin) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        const SizedBox(height: 40),
        Container(
          padding: const EdgeInsets.all(4),
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            gradient: const LinearGradient(
              colors: [
                AppColors.primary,
                Colors.blueAccent,
                Colors.purpleAccent
              ],
            ),
          ),
          child: CircleAvatar(
            radius: 55,
            backgroundColor: Theme.of(context).scaffoldBackgroundColor,
            child: CircleAvatar(
              radius: 50,
              backgroundColor: AppColors.primary.withOpacity(0.1),
              child: Text(
                initial,
                style: const TextStyle(
                    fontSize: 40,
                    fontWeight: FontWeight.w900,
                    color: AppColors.primary),
              ),
            ),
          ),
        ),
        const SizedBox(height: 16),
        Text(
          admin?.name ?? 'Admin',
          style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
        ),
        Container(
          margin: const EdgeInsets.only(top: 6),
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
          decoration: BoxDecoration(
            color: AppColors.primary.withOpacity(0.1),
            borderRadius: BorderRadius.circular(20),
          ),
          child: Text(
            admin?.role.toUpperCase() ?? 'ADMIN',
            style: const TextStyle(
                color: AppColors.primary,
                fontSize: 12,
                fontWeight: FontWeight.w800,
                letterSpacing: 1),
          ),
        ),
      ],
    );
  }

  Widget _buildInfoContainer(ThemeData theme) {
    return Container(
      decoration: BoxDecoration(
        color: theme.cardColor,
        borderRadius: BorderRadius.circular(28),
        boxShadow: [
          BoxShadow(
              color: Colors.black.withOpacity(0.03),
              blurRadius: 20,
              offset: const Offset(0, 10))
        ],
      ),
      child: Column(
        children: [
          _buildEditTile(
              Icons.email_outlined, "Email", _emailController, !_isEditing),
          _buildDivider(),
          _buildEditTile(Icons.phone_android_rounded, "Phone", _phoneController,
              !_isEditing),
          _buildDivider(),
          _buildEditTile(Icons.badge_outlined, "Admin ID",
              TextEditingController(text: "UID-88291"), true),

          // Toggle Edit Button
          Padding(
            padding: const EdgeInsets.all(16),
            child: TextButton.icon(
              onPressed: () => setState(() => _isEditing = !_isEditing),
              icon: Icon(_isEditing ? Icons.close : Icons.edit_note_rounded),
              label: Text(_isEditing ? "Cancel Editing" : "Modify Profile"),
              style: TextButton.styleFrom(
                  foregroundColor: _isEditing ? Colors.red : AppColors.primary),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEditTile(IconData icon, String label,
      TextEditingController controller, bool readOnly) {
    return ListTile(
      contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
      leading: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
            color: AppColors.primary.withOpacity(0.1),
            borderRadius: BorderRadius.circular(12)),
        child: Icon(icon, color: AppColors.primary, size: 22),
      ),
      title: Text(label,
          style: const TextStyle(fontSize: 13, color: AppColors.grey)),
      subtitle: TextField(
        controller: controller,
        readOnly: readOnly,
        style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
        decoration: const InputDecoration(
            border: InputBorder.none,
            isDense: true,
            contentPadding: EdgeInsets.only(top: 4)),
      ),
    );
  }

  Widget _buildActionCard(
      {required String title,
      required String subtitle,
      required IconData icon,
      required Color color,
      required VoidCallback onTap}) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(20),
        child: Ink(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Theme.of(context).cardColor,
            borderRadius: BorderRadius.circular(20),
          ),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                    color: color.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(14)),
                child: Icon(icon, color: color),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(title,
                          style: const TextStyle(
                              fontWeight: FontWeight.bold, fontSize: 16)),
                      Text(subtitle,
                          style: const TextStyle(
                              color: AppColors.grey, fontSize: 12)),
                    ]),
              ),
              const Icon(Icons.arrow_forward_ios_rounded,
                  size: 16, color: AppColors.grey),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSaveButton() {
    return Container(
      width: double.infinity,
      height: 60,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(20),
        gradient: const LinearGradient(
            colors: [AppColors.primary, Color(0xFF6C63FF)]),
        boxShadow: [
          BoxShadow(
              color: AppColors.primary.withOpacity(0.3),
              blurRadius: 15,
              offset: const Offset(0, 8))
        ],
      ),
      child: ElevatedButton(
        onPressed: _isSaving ? null : _saveProfile,
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.transparent,
          shadowColor: Colors.transparent,
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        ),
        child: _isSaving
            ? const CircularProgressIndicator(color: Colors.white)
            : const Text("SAVE CHANGES",
                style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 1.2)),
      ),
    );
  }

  Widget _buildSectionTitle(String title, ThemeData theme) {
    return Text(title,
        style: theme.textTheme.titleMedium
            ?.copyWith(fontWeight: FontWeight.bold, color: AppColors.primary));
  }

  Widget _buildDivider() => const Divider(indent: 70, endIndent: 20, height: 1);

  // Consistency with Dashboard Nav
  Widget _buildPremiumNav(bool isDark) {
    return Container(
      margin: const EdgeInsets.fromLTRB(20, 0, 20, 25),
      height: 70,
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1E1E2E) : Colors.white,
        borderRadius: BorderRadius.circular(35),
        boxShadow: [
          BoxShadow(color: Colors.black.withOpacity(0.15), blurRadius: 30)
        ],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          _navIcon(Icons.dashboard_rounded, AppRoutes.adminDashboard),
          _navIcon(Icons.people_alt_rounded, AppRoutes.adminUsers),
          _navIcon(Icons.assignment_rounded, AppRoutes.adminReports),
          _navIcon(Icons.insights_rounded, AppRoutes.adminAnalytics),
        ],
      ),
    );
  }

  Widget _navIcon(IconData icon, String route) {
    return GestureDetector(
      onTap: () => Navigator.pushNamed(context, route),
      child: Icon(icon, color: AppColors.grey),
    );
  }

  void _showLogoutDialog() {
    showGeneralDialog(
      context: context,
      barrierDismissible: true,
      barrierLabel: '',
      transitionDuration: const Duration(milliseconds: 300),
      pageBuilder: (context, anim1, anim2) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        title: const Text('Logout?'),
        content:
            const Text('Do you want to sign out of the Pulse Admin panel?'),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel')),
          ElevatedButton(
            onPressed: () {
              context.read<AuthProvider>().logout();
              Navigator.of(context)
                  .pushNamedAndRemoveUntil('/login', (r) => false);
            },
            style: ElevatedButton.styleFrom(
                backgroundColor: Colors.redAccent,
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12))),
            child: const Text('Logout', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }
}

class _CircleBlob extends StatelessWidget {
  final Color color;
  final double size;
  const _CircleBlob({required this.color, required this.size});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
          shape: BoxShape.circle,
          gradient: RadialGradient(colors: [color, color.withOpacity(0)])),
    );
  }
}
