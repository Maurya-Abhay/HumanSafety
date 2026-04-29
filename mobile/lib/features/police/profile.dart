import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../shared/widgets.dart';
import '../../shared/models.dart';
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
  bool _isEditing = false;
  late TextEditingController _nameController;
  late TextEditingController _emailController;
  late TextEditingController _phoneController;
  late TextEditingController _badgeController;

  @override
  void initState() {
    super.initState();
    final user = context.read<AuthProvider>().user;
    _nameController = TextEditingController(text: user?.name ?? '');
    _emailController = TextEditingController(text: user?.email ?? '');
    _phoneController = TextEditingController(text: user?.phone ?? '');
    _badgeController = TextEditingController(text: 'P-88293'); // Mock badge
  }

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _phoneController.dispose();
    _badgeController.dispose();
    super.dispose();
  }

  Future<void> _saveProfile() async {
    try {
      final token = await StorageService.getString(AppConstants.tokenKey);
      // TODO: Call API to update profile
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Profile updated successfully'),
            behavior: SnackBarBehavior.floating,
            backgroundColor: AppColors.success,
          ),
        );
        setState(() => _isEditing = false);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e'), backgroundColor: Colors.redAccent),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: CustomAppBar(
        title: 'Officer Profile',
        showBackButton: true,
        actions: [
          if (!_isEditing)
            IconButton(
              icon: const Icon(Icons.mode_edit_outline_rounded, color: Colors.white),
              onPressed: () => setState(() => _isEditing = true),
            ),
        ],
      ),
      body: SingleChildScrollView(
        child: Consumer<AuthProvider>(
          builder: (context, authProvider, _) {
            final user = authProvider.user;
            return Column(
              children: [
                _buildHeader(user),
                Padding(
                  padding: const EdgeInsets.fromLTRB(20, 0, 20, 30),
                  child: _buildProfileForm(),
                ),
              ],
            );
          },
        ),
      ),
    );
  }

  Widget _buildHeader(User? user) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.only(bottom: 40),
      decoration: const BoxDecoration(
        color: AppColors.primary,
        borderRadius: BorderRadius.only(
          bottomLeft: Radius.circular(40),
          bottomRight: Radius.circular(40),
        ),
      ),
      child: Column(
        children: [
          const SizedBox(height: 10),
          Stack(
            children: [
              Container(
                padding: const EdgeInsets.all(4),
                decoration: const BoxDecoration(color: Colors.white, shape: BoxShape.circle),
                child: CircleAvatar(
                  radius: 55,
                  backgroundColor: Colors.blue.shade50,
                  child: Text(
                    (user?.name ?? 'P')[0].toUpperCase(),
                    style: const TextStyle(fontSize: 40, color: AppColors.primary, fontWeight: FontWeight.w900),
                  ),
                ),
              ),
              if (_isEditing)
                Positioned(
                  bottom: 0,
                  right: 0,
                  child: Container(
                    padding: const EdgeInsets.all(8),
                    decoration: const BoxDecoration(color: Colors.white, shape: BoxShape.circle),
                    child: const Icon(Icons.camera_alt_rounded, size: 20, color: AppColors.primary),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 16),
          Text(
            user?.name ?? 'Officer Name',
            style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: Colors.white),
          ),
          const SizedBox(height: 4),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
            decoration: BoxDecoration(color: Colors.white.withOpacity(0.2), borderRadius: BorderRadius.circular(20)),
            child: Text(
              user?.role?.toUpperCase() ?? 'POLICE OFFICER',
              style: const TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.bold, letterSpacing: 1),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildProfileForm() {
    if (_isEditing) {
      return Column(
        children: [
          const SizedBox(height: 30),
          _buildTextField(_nameController, 'Full Name', Icons.person_outline_rounded),
          const SizedBox(height: 16),
          _buildTextField(_emailController, 'Email Address', Icons.email_outlined, keyboardType: TextInputType.emailAddress),
          const SizedBox(height: 16),
          _buildTextField(_phoneController, 'Contact Number', Icons.phone_iphone_rounded, keyboardType: TextInputType.phone),
          const SizedBox(height: 16),
          _buildTextField(_badgeController, 'Badge ID', Icons.verified_user_outlined),
          const SizedBox(height: 30),
          Row(
            children: [
              Expanded(
                child: OutlinedButton(
                  style: OutlinedButton.styleFrom(
                    padding: const EdgeInsets.all(16),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
                  ),
                  onPressed: () => setState(() => _isEditing = false),
                  child: const Text('Cancel'),
                ),
              ),
              const SizedBox(width: 15),
              Expanded(
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.all(16),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
                    elevation: 0,
                  ),
                  onPressed: _saveProfile,
                  child: const Text('Save Changes', style: TextStyle(fontWeight: FontWeight.bold)),
                ),
              ),
            ],
          ),
        ],
      );
    } else {
      return Column(
        children: [
          const SizedBox(height: 30),
          _buildInfoCard('Account Information', [
            _buildInfoRow('Name', context.read<AuthProvider>().user?.name ?? '-'),
            _buildInfoRow('Email', context.read<AuthProvider>().user?.email ?? '-'),
            _buildInfoRow('Phone', context.read<AuthProvider>().user?.phone ?? '-'),
          ]),
          const SizedBox(height: 16),
          _buildInfoCard('Departmental Details', [
            _buildInfoRow('Badge Number', 'P-88293'),
            _buildInfoRow('Verified', context.read<AuthProvider>().user?.isVerified ?? false ? 'Yes' : 'No'),
            _buildInfoRow('Duty Status', 'On Duty'),
          ]),
        ],
      );
    }
  }

  Widget _buildTextField(TextEditingController controller, String label, IconData icon, {TextInputType? keyboardType}) {
    return TextFormField(
      controller: controller,
      keyboardType: keyboardType,
      decoration: InputDecoration(
        labelText: label,
        prefixIcon: Icon(icon, color: AppColors.primary, size: 22),
        filled: true,
        fillColor: Colors.white,
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(15), borderSide: BorderSide.none),
        contentPadding: const EdgeInsets.all(18),
      ),
    );
  }

  Widget _buildInfoCard(String sectionTitle, List<Widget> children) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(left: 8, bottom: 8),
          child: Text(sectionTitle, style: TextStyle(fontWeight: FontWeight.bold, color: Colors.grey.shade700, fontSize: 14)),
        ),
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(20),
            boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.03), blurRadius: 10, offset: const Offset(0, 4))],
          ),
          child: Column(children: children),
        ),
      ],
    );
  }

  Widget _buildInfoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: const TextStyle(color: Colors.grey, fontWeight: FontWeight.w500)),
          Text(value, style: const TextStyle(fontWeight: FontWeight.bold, color: Color(0xFF1E293B))),
        ],
      ),
    );
  }
}